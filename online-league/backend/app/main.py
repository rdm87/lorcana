import json
from urllib.parse import urlencode
import httpx
from fastapi import APIRouter, Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from .auth import create_access_token, get_current_user, get_optional_user, require_admin
from .config import get_settings
from .db import Base, engine, get_db
from .models import Registration, Tournament, User
from .schemas import RegistrationCreate, RegistrationOut, TournamentCreate, TournamentDetailOut, TournamentOut, UserOut

Base.metadata.create_all(bind=engine)
settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

router = APIRouter(prefix="/api")

DISCORD_AUTH_URL = "https://discord.com/oauth2/authorize"
DISCORD_TOKEN_URL = "https://discord.com/api/oauth2/token"
DISCORD_USER_URL = "https://discord.com/api/users/@me"


def serialize_tournament(t: Tournament) -> TournamentOut:
    return TournamentOut(
        id=t.id,
        title=t.title,
        cap=t.cap,
        entry_fee_eur=t.entry_fee_eur,
        paypal_link=t.paypal_link,
        start_date=t.start_date,
        end_date=t.end_date,
        rules_description=t.rules_description,
        prize_players_count=t.prize_players_count,
        prize_distribution=json.loads(t.prize_distribution),
        registered_count=len(t.registrations),
    )


@router.get("/health")
def health():
    return {"status": "ok"}


@router.get("/auth/discord/login")
def discord_login():
    qs = urlencode({
        "client_id": settings.discord_client_id,
        "redirect_uri": settings.discord_redirect_uri,
        "response_type": "code",
        "scope": "identify",
    })
    return RedirectResponse(f"{DISCORD_AUTH_URL}?{qs}")


@router.get("/auth/discord/callback")
async def discord_callback(code: str, db: Session = Depends(get_db)):
    data = {
        "client_id": settings.discord_client_id,
        "client_secret": settings.discord_client_secret,
        "grant_type": "authorization_code",
        "code": code,
        "redirect_uri": settings.discord_redirect_uri,
    }
    async with httpx.AsyncClient(timeout=20) as client:
        token_resp = await client.post(
            DISCORD_TOKEN_URL, data=data,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        if token_resp.status_code >= 400:
            raise HTTPException(status_code=400, detail="OAuth Discord non riuscito")
        access_token = token_resp.json()["access_token"]
        user_resp = await client.get(DISCORD_USER_URL, headers={"Authorization": f"Bearer {access_token}"})
        user_resp.raise_for_status()
        discord_user = user_resp.json()

    discord_id = discord_user["id"]
    avatar = discord_user.get("avatar")
    avatar_url = f"https://cdn.discordapp.com/avatars/{discord_id}/{avatar}.png" if avatar else None
    user = db.query(User).filter(User.discord_id == discord_id).first()
    if not user:
        user = User(
            discord_id=discord_id,
            username=discord_user.get("global_name") or discord_user.get("username", "Discord User"),
        )
        db.add(user)
    user.username = discord_user.get("global_name") or discord_user.get("username", user.username)
    user.avatar_url = avatar_url
    user.is_admin = discord_id in settings.admin_ids
    db.commit()
    db.refresh(user)
    jwt_token = create_access_token(user)
    # Path-based routing: no hash fragment needed
    return RedirectResponse(f"{settings.frontend_url}/auth/callback?token={jwt_token}")


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user


@router.get("/tournaments", response_model=list[TournamentOut])
def list_tournaments(db: Session = Depends(get_db)):
    return [serialize_tournament(t) for t in db.query(Tournament).order_by(Tournament.start_date.desc()).all()]


@router.get("/tournaments/{tournament_id}", response_model=TournamentDetailOut)
def get_tournament(
    tournament_id: int,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_optional_user),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    data = serialize_tournament(t).model_dump()
    sorted_regs = sorted(t.registrations, key=lambda r: r.created_at)
    data["registrations"] = sorted_regs
    data["my_registration"] = None
    data["admin_registrations"] = None
    if user:
        data["my_registration"] = next((r for r in t.registrations if r.user_id == user.id), None)
        if user.is_admin:
            data["admin_registrations"] = sorted_regs
    return data


@router.post("/tournaments", response_model=TournamentOut)
def create_tournament(
    payload: TournamentCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    t = Tournament(
        title=payload.title,
        cap=payload.cap,
        entry_fee_eur=payload.entry_fee_eur,
        paypal_link=str(payload.paypal_link),
        start_date=payload.start_date,
        end_date=payload.end_date,
        rules_description=payload.rules_description,
        prize_players_count=payload.prize_players_count,
        prize_distribution=json.dumps([p.model_dump() for p in payload.prize_distribution]),
        created_by_id=admin.id,
    )
    db.add(t)
    db.commit()
    db.refresh(t)
    return serialize_tournament(t)


@router.post("/tournaments/{tournament_id}/register", response_model=RegistrationOut)
def register(
    tournament_id: int,
    payload: RegistrationCreate,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    if len(t.registrations) >= t.cap:
        raise HTTPException(status_code=409, detail="CAP raggiunto: il torneo è al completo")
    reg = Registration(
        tournament_id=tournament_id,
        user_id=user.id,
        discord_account=payload.discord_account.strip(),
        first_name=payload.first_name.strip(),
        last_name=payload.last_name.strip(),
    )
    db.add(reg)
    try:
        db.commit()
        db.refresh(reg)
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Sei già iscritto a questo torneo")
    return reg


@router.post("/registrations/{registration_id}/paid", response_model=RegistrationOut)
def mark_paid(
    registration_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    reg = db.get(Registration, registration_id)
    if not reg:
        raise HTTPException(status_code=404, detail="Iscrizione non trovata")
    reg.paid = True
    db.commit()
    db.refresh(reg)
    return reg


@router.delete("/registrations/{registration_id}/paid", response_model=RegistrationOut)
def unmark_paid(
    registration_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    reg = db.get(Registration, registration_id)
    if not reg:
        raise HTTPException(status_code=404, detail="Iscrizione non trovata")
    reg.paid = False
    db.commit()
    db.refresh(reg)
    return reg


@router.delete("/registrations/{registration_id}")
def delete_registration(
    registration_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    reg = db.get(Registration, registration_id)
    if not reg:
        raise HTTPException(status_code=404, detail="Iscrizione non trovata")
    db.delete(reg)
    db.commit()
    return {"status": "deleted"}


@router.post("/tournaments/{tournament_id}/admin/register", response_model=RegistrationOut)
def admin_register(
    tournament_id: int,
    payload: RegistrationCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    if len(t.registrations) >= t.cap:
        raise HTTPException(status_code=409, detail="CAP raggiunto: il torneo è al completo")
    reg = Registration(
        tournament_id=tournament_id,
        user_id=None,
        discord_account=payload.discord_account.strip(),
        first_name=payload.first_name.strip(),
        last_name=payload.last_name.strip(),
    )
    db.add(reg)
    db.commit()
    db.refresh(reg)
    return reg


@router.delete("/tournaments/{tournament_id}/registration/me")
def cancel_my_registration(
    tournament_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    reg = db.query(Registration).filter(
        Registration.tournament_id == tournament_id,
        Registration.user_id == user.id,
    ).first()
    if not reg:
        raise HTTPException(status_code=404, detail="Iscrizione non trovata")
    db.delete(reg)
    db.commit()
    return {"status": "deleted"}


app.include_router(router)
