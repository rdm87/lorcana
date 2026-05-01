import itertools
import json
from datetime import datetime, timezone
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
from .models import Match, Registration, Tournament, User
from .schemas import (
    MatchOut, MatchPlayerOut, RegistrationCreate, RegistrationOut, ResultPropose,
    StandingEntry, TournamentCreate, TournamentDetailOut, TournamentOut, UserOut,
)

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


def _utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)


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
        status=t.status,
    )


def _serialize_match(m: Match) -> MatchOut:
    return MatchOut(
        id=m.id,
        tournament_id=m.tournament_id,
        reg1_id=m.reg1_id,
        reg2_id=m.reg2_id,
        reg1=MatchPlayerOut(id=m.reg1.id, first_name=m.reg1.first_name, last_name=m.reg1.last_name),
        reg2=MatchPlayerOut(id=m.reg2.id, first_name=m.reg2.first_name, last_name=m.reg2.last_name),
        games_reg1=m.games_reg1,
        games_reg2=m.games_reg2,
        proposed_by_reg_id=m.proposed_by_reg_id,
        result_status=m.result_status,
    )


def _generate_schedule(tournament: Tournament, db: Session) -> None:
    regs = sorted(tournament.registrations, key=lambda r: r.id)
    for r1, r2 in itertools.combinations(regs, 2):
        m = Match(
            tournament_id=tournament.id,
            reg1_id=r1.id,
            reg2_id=r2.id,
        )
        db.add(m)


def _start_tournament(tournament: Tournament, db: Session) -> None:
    tournament.status = "ongoing"
    _generate_schedule(tournament, db)
    db.commit()


def _check_autostart(tournament: Tournament, db: Session) -> None:
    if tournament.status != "registration":
        return
    now = _utcnow()
    if now < tournament.start_date:
        return
    regs = tournament.registrations
    if not regs:
        return
    if all(r.paid for r in regs):
        _start_tournament(tournament, db)


def _calc_standings(tournament: Tournament) -> list[StandingEntry]:
    stats: dict[int, dict] = {}
    for reg in tournament.registrations:
        stats[reg.id] = {
            "reg_id": reg.id,
            "first_name": reg.first_name,
            "last_name": reg.last_name,
            "played": 0, "wins": 0, "draws": 0, "losses": 0, "points": 0,
        }

    for m in tournament.matches:
        if m.result_status != "confirmed":
            continue
        g1, g2 = m.games_reg1, m.games_reg2
        if g1 is None or g2 is None:
            continue
        s1 = stats.get(m.reg1_id)
        s2 = stats.get(m.reg2_id)
        if not s1 or not s2:
            continue
        s1["played"] += 1
        s2["played"] += 1
        if g1 > g2:
            s1["wins"] += 1; s1["points"] += 3
            s2["losses"] += 1
        elif g2 > g1:
            s2["wins"] += 1; s2["points"] += 3
            s1["losses"] += 1
        else:
            s1["draws"] += 1; s1["points"] += 1
            s2["draws"] += 1; s2["points"] += 1

    return sorted(
        [StandingEntry(**v) for v in stats.values()],
        key=lambda e: (-e.points, -e.wins, e.losses),
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
    return RedirectResponse(f"{settings.frontend_url}/auth/callback?token={jwt_token}")


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user


@router.get("/tournaments", response_model=list[TournamentOut])
def list_tournaments(db: Session = Depends(get_db)):
    tournaments = db.query(Tournament).order_by(Tournament.start_date.desc()).all()
    for t in tournaments:
        _check_autostart(t, db)
    return [serialize_tournament(t) for t in tournaments]


@router.get("/tournaments/{tournament_id}", response_model=TournamentDetailOut)
def get_tournament(
    tournament_id: int,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_optional_user),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    _check_autostart(t, db)
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


@router.post("/tournaments/{tournament_id}/start", response_model=TournamentOut)
def start_tournament(
    tournament_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    if t.status != "registration":
        raise HTTPException(status_code=409, detail="Il torneo non è in fase di iscrizione")
    if len(t.registrations) < 2:
        raise HTTPException(status_code=409, detail="Servono almeno 2 iscritti per avviare il torneo")
    _start_tournament(t, db)
    db.refresh(t)
    return serialize_tournament(t)


@router.get("/tournaments/{tournament_id}/matches", response_model=list[MatchOut])
def get_matches(
    tournament_id: int,
    db: Session = Depends(get_db),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    return [_serialize_match(m) for m in sorted(t.matches, key=lambda m: m.id)]


@router.get("/tournaments/{tournament_id}/standings", response_model=list[StandingEntry])
def get_standings(
    tournament_id: int,
    db: Session = Depends(get_db),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    return _calc_standings(t)


@router.post("/matches/{match_id}/result", response_model=MatchOut)
def propose_result(
    match_id: int,
    payload: ResultPropose,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    m = db.get(Match, match_id)
    if not m:
        raise HTTPException(status_code=404, detail="Partita non trovata")
    if m.result_status == "confirmed":
        raise HTTPException(status_code=409, detail="Risultato già confermato")

    # find which registration this user belongs to in this match
    reg1 = db.get(Registration, m.reg1_id)
    reg2 = db.get(Registration, m.reg2_id)
    my_reg_id: int | None = None
    if reg1 and reg1.user_id == user.id:
        my_reg_id = reg1.id
    elif reg2 and reg2.user_id == user.id:
        my_reg_id = reg2.id
    elif user.is_admin:
        my_reg_id = reg1.id  # admin can propose on behalf of reg1

    if my_reg_id is None:
        raise HTTPException(status_code=403, detail="Non sei un partecipante di questa partita")

    if m.result_status == "pending" and m.games_reg1 is None:
        # first proposal
        m.games_reg1 = payload.games_reg1
        m.games_reg2 = payload.games_reg2
        m.proposed_by_reg_id = my_reg_id
        m.result_status = "proposed"
    else:
        # second player confirms or overrides
        if my_reg_id == m.proposed_by_reg_id and not user.is_admin:
            raise HTTPException(status_code=409, detail="Attendi la conferma dell'avversario")
        m.games_reg1 = payload.games_reg1
        m.games_reg2 = payload.games_reg2
        m.result_status = "confirmed"

    db.commit()
    db.refresh(m)
    return _serialize_match(m)


@router.post("/matches/{match_id}/confirm", response_model=MatchOut)
def confirm_result(
    match_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    m = db.get(Match, match_id)
    if not m:
        raise HTTPException(status_code=404, detail="Partita non trovata")
    if m.result_status != "proposed":
        raise HTTPException(status_code=409, detail="Nessun risultato in attesa di conferma")

    reg1 = db.get(Registration, m.reg1_id)
    reg2 = db.get(Registration, m.reg2_id)
    my_reg_id: int | None = None
    if reg1 and reg1.user_id == user.id:
        my_reg_id = reg1.id
    elif reg2 and reg2.user_id == user.id:
        my_reg_id = reg2.id

    if not user.is_admin and my_reg_id == m.proposed_by_reg_id:
        raise HTTPException(status_code=403, detail="Non puoi confermare il tuo stesso risultato")
    if not user.is_admin and my_reg_id is None:
        raise HTTPException(status_code=403, detail="Non sei un partecipante di questa partita")

    m.result_status = "confirmed"
    db.commit()
    db.refresh(m)
    return _serialize_match(m)


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
    if t.status != "registration":
        raise HTTPException(status_code=409, detail="Le iscrizioni per questo torneo sono chiuse")
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
    # check if this payment completes the conditions for autostart
    t = db.get(Tournament, reg.tournament_id)
    if t:
        _check_autostart(t, db)
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
