import itertools
import json
from datetime import datetime, timezone
from urllib.parse import urlencode
import httpx
from fastapi import APIRouter, BackgroundTasks, Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import RedirectResponse
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from .auth import create_access_token, get_current_user, get_optional_user, require_admin
from .config import get_settings
from .db import Base, engine, get_db
from .models import Availability, BotConfig, Match, Registration, Tournament, User
from .schemas import (
    AvailabilitySlotOut, AvailabilityUpdate, BotConfigIn, BotConfigOut, PlayerAvailabilityOut,
    MatchOut, MatchPlayerOut, RegistrationCreate, RegistrationOut, ResultPropose,
    StandingEntry, TestTournamentCreate, TournamentCreate, TournamentDetailOut, TournamentOut, UserOut,
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
            "games_won": 0, "games_lost": 0,
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
        s1["games_won"] += g1; s1["games_lost"] += g2
        s2["games_won"] += g2; s2["games_lost"] += g1
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
        key=lambda e: (-e.points, -e.wins, -(e.games_won - e.games_lost), e.losses),
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
        "scope": "identify guilds",
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
        guilds_resp = await client.get(
            "https://discord.com/api/users/@me/guilds",
            headers={"Authorization": f"Bearer {access_token}"},
        )
        user_guilds = guilds_resp.json() if guilds_resp.status_code == 200 else []

    discord_id = discord_user["id"]
    avatar = discord_user.get("avatar")
    avatar_url = f"https://cdn.discordapp.com/avatars/{discord_id}/{avatar}.png" if avatar else None

    bot_config = db.get(BotConfig, 1)
    in_server = False
    if bot_config and bot_config.guild_id:
        in_server = any(str(g.get("id")) == bot_config.guild_id for g in user_guilds if isinstance(g, dict))

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
    user.in_server = in_server
    db.commit()
    db.refresh(user)
    jwt_token = create_access_token(user)
    return RedirectResponse(f"{settings.frontend_url}/auth/callback?token={jwt_token}")


@router.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)):
    return user


def _bot_config_out(cfg: BotConfig | None) -> BotConfigOut:
    if cfg is None:
        return BotConfigOut(guild_id=None, invite_channel_id=None, invite_url=None, has_token=False)
    return BotConfigOut(
        guild_id=cfg.guild_id,
        invite_channel_id=cfg.invite_channel_id,
        invite_url=cfg.invite_url,
        has_token=bool(cfg.bot_token),
    )


@router.get("/discord/invite")
async def discord_invite(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    cfg = db.get(BotConfig, 1)
    if not cfg:
        raise HTTPException(status_code=404, detail="Bot non configurato")

    # Real-time membership check via bot (updates stored in_server if changed)
    in_server = user.in_server
    if cfg.bot_token and cfg.guild_id:
        async with httpx.AsyncClient(timeout=5) as client:
            member_resp = await client.get(
                f"https://discord.com/api/v10/guilds/{cfg.guild_id}/members/{user.discord_id}",
                headers={"Authorization": f"Bot {cfg.bot_token}"},
            )
        in_server = member_resp.status_code == 200
        if in_server != user.in_server:
            user.in_server = in_server
            db.commit()

    base = {"guild_id": cfg.guild_id, "in_server": in_server}

    if cfg.invite_url:
        return {**base, "invite_url": cfg.invite_url}
    if not cfg.bot_token or not cfg.invite_channel_id:
        return {**base, "invite_url": None}
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            f"https://discord.com/api/v10/channels/{cfg.invite_channel_id}/invites",
            headers={"Authorization": f"Bot {cfg.bot_token}"},
            json={"max_age": 0, "max_uses": 0},
        )
    if resp.status_code not in (200, 201):
        return {**base, "invite_url": None}
    url = f"https://discord.gg/{resp.json().get('code')}"
    cfg.invite_url = url
    db.commit()
    return {**base, "invite_url": url}


@router.get("/admin/bot-config", response_model=BotConfigOut)
def get_bot_config(db: Session = Depends(get_db), _: User = Depends(require_admin)):
    return _bot_config_out(db.get(BotConfig, 1))


@router.put("/admin/bot-config", response_model=BotConfigOut)
def save_bot_config(
    payload: BotConfigIn,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    cfg = db.get(BotConfig, 1)
    if not cfg:
        cfg = BotConfig(id=1)
        db.add(cfg)
    if payload.guild_id is not None:
        cfg.guild_id = payload.guild_id or None
    if payload.bot_token is not None:
        cfg.bot_token = payload.bot_token or None
    if payload.invite_channel_id is not None:
        cfg.invite_channel_id = payload.invite_channel_id or None
    if payload.invite_url is not None:
        cfg.invite_url = payload.invite_url or None
    db.commit()
    db.refresh(cfg)
    return _bot_config_out(cfg)


@router.get("/admin/bot-config/bot-oauth-url")
async def get_bot_oauth_url(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    cfg = db.get(BotConfig, 1)
    if not cfg or not cfg.bot_token:
        raise HTTPException(status_code=400, detail="Configura il token bot prima")
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.get(
            "https://discord.com/api/v10/users/@me",
            headers={"Authorization": f"Bot {cfg.bot_token}"},
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=503, detail=f"Impossibile leggere info bot: {resp.text}")
    bot_id = resp.json()["id"]
    # Permission bit 1 = CREATE_INSTANT_INVITE
    oauth_url = (
        f"https://discord.com/oauth2/authorize"
        f"?client_id={bot_id}&scope=bot&permissions=1"
    )
    if cfg.guild_id:
        oauth_url += f"&guild_id={cfg.guild_id}"
    return {"url": oauth_url}


@router.post("/admin/bot-config/generate-invite")
async def generate_invite(
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    cfg = db.get(BotConfig, 1)
    if not cfg or not cfg.bot_token or not cfg.invite_channel_id:
        raise HTTPException(status_code=400, detail="Configura token bot e ID canale prima di generare il link")
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            f"https://discord.com/api/v10/channels/{cfg.invite_channel_id}/invites",
            headers={"Authorization": f"Bot {cfg.bot_token}"},
            json={"max_age": 0, "max_uses": 0},
        )
    if resp.status_code not in (200, 201):
        raise HTTPException(status_code=503, detail=f"Discord API error: {resp.text}")
    url = f"https://discord.gg/{resp.json().get('code')}"
    cfg.invite_url = url
    db.commit()
    return {"invite_url": url}


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
        paypal_link=str(payload.paypal_link) if payload.paypal_link else '',
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


@router.delete("/tournaments/{tournament_id}", status_code=204)
def delete_tournament(
    tournament_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    db.query(Availability).filter(Availability.tournament_id == tournament_id).delete()
    for m in list(t.matches):
        db.delete(m)
    for r in list(t.registrations):
        db.delete(r)
    db.delete(t)
    db.commit()


@router.put("/tournaments/{tournament_id}", response_model=TournamentOut)
def update_tournament(
    tournament_id: int,
    payload: TournamentCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    if t.status != "registration":
        raise HTTPException(status_code=409, detail="Impossibile modificare un torneo già avviato")
    t.title = payload.title
    t.cap = payload.cap
    t.entry_fee_eur = payload.entry_fee_eur
    t.paypal_link = str(payload.paypal_link)
    t.start_date = payload.start_date
    t.end_date = payload.end_date
    t.rules_description = payload.rules_description
    t.prize_players_count = payload.prize_players_count
    t.prize_distribution = json.dumps([p.model_dump() for p in payload.prize_distribution])
    db.commit()
    db.refresh(t)
    return serialize_tournament(t)


@router.post("/admin/test-tournament", response_model=TournamentOut)
def create_test_tournament(
    payload: TestTournamentCreate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    import random
    from datetime import timedelta
    now = _utcnow()
    t = Tournament(
        title=f"Torneo Test {now.strftime('%d/%m %H:%M')}",
        cap=payload.player_count,
        entry_fee_eur=payload.entry_fee_eur,
        paypal_link="https://paypal.me/test",
        start_date=now + timedelta(hours=1),
        end_date=now + timedelta(days=30),
        rules_description="Torneo di test generato automaticamente. Tutti contro tutti, BO3.",
        prize_players_count=3,
        prize_distribution=json.dumps([
            {"position": 1, "percentage": 50},
            {"position": 2, "percentage": 30},
            {"position": 3, "percentage": 20},
        ]),
        created_by_id=admin.id,
        status="registration",
    )
    db.add(t)
    db.flush()
    fake_names = [
        ("Marco", "Rossi"), ("Luca", "Ferrari"), ("Sara", "Bianchi"),
        ("Giulia", "Romano"), ("Andrea", "Colombo"), ("Elena", "Ricci"),
        ("Matteo", "Esposito"), ("Chiara", "Bruno"), ("Davide", "De Luca"),
        ("Francesca", "Moretti"), ("Alessandro", "Gallo"), ("Valentina", "Costa"),
        ("Simone", "Fontana"), ("Laura", "Conti"), ("Riccardo", "Russo"),
        ("Martina", "Leone"), ("Fabio", "Marini"), ("Alice", "Barbieri"),
        ("Stefano", "Greco"), ("Silvia", "Serra"), ("Giorgio", "Martini"),
        ("Beatrice", "Pellegrini"), ("Lorenzo", "Caruso"), ("Irene", "Ferrara"),
        ("Nicolò", "Mancini"),
    ]
    for i in range(payload.player_count):
        fn, ln = fake_names[i % len(fake_names)]
        suffix = f"{(i // len(fake_names)) + 1}" if i >= len(fake_names) else ""
        reg = Registration(
            tournament_id=t.id,
            user_id=None,
            discord_account=f"{fn.lower()}{suffix}#{random.randint(1000, 9999)}",
            first_name=fn + suffix,
            last_name=ln,
            paid=True,
        )
        db.add(reg)
    db.commit()
    db.refresh(t)
    return serialize_tournament(t)


def _update_player_availability(
    tournament_id: int, reg_id: int, slots: list, tournament: Tournament, db: Session
) -> list[AvailabilitySlotOut]:
    t_start = tournament.start_date.date()
    t_end = tournament.end_date.date()
    for s in slots:
        if not (t_start <= s.slot_date <= t_end):
            raise HTTPException(
                status_code=400,
                detail=f"Data {s.slot_date} fuori dal periodo del torneo ({t_start} – {t_end})",
            )
    db.query(Availability).filter(
        Availability.tournament_id == tournament_id,
        Availability.reg_id == reg_id,
    ).delete()
    new_slots = []
    for s in slots:
        av = Availability(
            tournament_id=tournament_id,
            reg_id=reg_id,
            slot_date=s.slot_date,
            time_start=s.time_start,
            time_end=s.time_end,
        )
        db.add(av)
        new_slots.append(av)
    db.commit()
    for av in new_slots:
        db.refresh(av)
    return [AvailabilitySlotOut(id=av.id, slot_date=av.slot_date, time_start=av.time_start, time_end=av.time_end) for av in new_slots]


@router.get("/tournaments/{tournament_id}/availability", response_model=list[PlayerAvailabilityOut])
def get_availability(
    tournament_id: int,
    db: Session = Depends(get_db),
    user: User | None = Depends(get_optional_user),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    is_registered = user and any(r.user_id == user.id for r in t.registrations)
    if not (user and (user.is_admin or is_registered)):
        raise HTTPException(status_code=403, detail="Devi essere iscritto per consultare le disponibilità")
    result = []
    for reg in sorted(t.registrations, key=lambda r: r.created_at):
        slots = (
            db.query(Availability)
            .filter(Availability.tournament_id == tournament_id, Availability.reg_id == reg.id)
            .order_by(Availability.slot_date, Availability.time_start)
            .all()
        )
        result.append(PlayerAvailabilityOut(
            reg_id=reg.id,
            first_name=reg.first_name,
            last_name=reg.last_name,
            slots=[AvailabilitySlotOut(id=s.id, slot_date=s.slot_date, time_start=s.time_start, time_end=s.time_end) for s in slots],
        ))
    return result


@router.put("/tournaments/{tournament_id}/availability/me", response_model=list[AvailabilitySlotOut])
def update_my_availability(
    tournament_id: int,
    payload: AvailabilityUpdate,
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    reg = next((r for r in t.registrations if r.user_id == user.id), None)
    if not reg:
        raise HTTPException(status_code=403, detail="Non sei iscritto a questo torneo")
    result = _update_player_availability(tournament_id, reg.id, payload.slots, t, db)
    dm_payloads = _collect_dm_payloads(tournament_id, reg.id, db)
    if dm_payloads:
        background_tasks.add_task(_send_dms_background, dm_payloads)
    return result


@router.put("/tournaments/{tournament_id}/availability/{reg_id}", response_model=list[AvailabilitySlotOut])
def update_availability_for_player(
    tournament_id: int,
    reg_id: int,
    payload: AvailabilityUpdate,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    t = db.get(Tournament, tournament_id)
    if not t:
        raise HTTPException(status_code=404, detail="Torneo non trovato")
    reg = db.get(Registration, reg_id)
    if not reg or reg.tournament_id != tournament_id:
        raise HTTPException(status_code=404, detail="Iscrizione non trovata")
    return _update_player_availability(tournament_id, reg_id, payload.slots, t, db)


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
    if m.result_status == "confirmed" and not user.is_admin:
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
        m.games_reg1 = payload.games_reg1
        m.games_reg2 = payload.games_reg2
        m.proposed_by_reg_id = my_reg_id
        # admin inserts → directly confirmed; player inserts → awaits confirmation
        m.result_status = "confirmed" if user.is_admin else "proposed"
    else:
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


@router.delete("/matches/{match_id}/result", response_model=MatchOut)
def reset_result(
    match_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
):
    m = db.get(Match, match_id)
    if not m:
        raise HTTPException(status_code=404, detail="Partita non trovata")
    m.games_reg1 = None
    m.games_reg2 = None
    m.proposed_by_reg_id = None
    m.result_status = "pending"
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


_DAYS_IT = ["Lun", "Mar", "Mer", "Gio", "Ven", "Sab", "Dom"]


def _collect_dm_payloads(tournament_id: int, updated_reg_id: int, db: Session) -> list[dict]:
    """Build DM payloads for all opponents with common availability. Called while the DB session is open."""
    cfg = db.get(BotConfig, 1)
    if not cfg or not cfg.bot_token:
        return []
    site_url = get_settings().frontend_url.rstrip("/")

    t = db.get(Tournament, tournament_id)
    if not t:
        return []

    my_slots = (
        db.query(Availability)
        .filter(Availability.tournament_id == tournament_id, Availability.reg_id == updated_reg_id)
        .all()
    )
    if not my_slots:
        return []

    updated_reg = db.get(Registration, updated_reg_id)
    if not updated_reg:
        return []

    my_slot_map: dict[tuple, str] = {(s.slot_date, s.time_start): s.time_end for s in my_slots}

    updated_user = db.get(User, updated_reg.user_id) if updated_reg.user_id else None
    my_mention = (
        f"<@{updated_user.discord_id}>" if updated_user
        else f"{updated_reg.first_name} {updated_reg.last_name}"
    )

    def _fmt_date(d) -> str:
        return f"{_DAYS_IT[d.weekday()]} {d.day:02d}/{d.month:02d}"

    def _fmt_time(ts: str, te: str) -> str:
        return f"{ts[:2]}–{te[:2]}" if te else ts[:2]

    payloads: list[dict] = []
    bot_token = cfg.bot_token

    for other_reg in t.registrations:
        if other_reg.id == updated_reg_id or not other_reg.user_id:
            continue
        other_user = db.get(User, other_reg.user_id)
        if not other_user or not other_user.discord_id:
            continue

        other_slots = (
            db.query(Availability)
            .filter(Availability.tournament_id == tournament_id, Availability.reg_id == other_reg.id)
            .all()
        )
        other_slot_keys = {(s.slot_date, s.time_start) for s in other_slots}
        common = set(my_slot_map.keys()) & other_slot_keys
        if not common:
            continue

        by_date: dict = {}
        for slot_date, time_start in sorted(common):
            by_date.setdefault(slot_date, []).append((time_start, my_slot_map[(slot_date, time_start)]))

        other_mention = f"<@{other_user.discord_id}>"
        lines = [
            f"📅 **Disponibilità in comune – {t.title}**",
            f"👥 {my_mention} vs {other_mention}",
        ]
        for d, slots in sorted(by_date.items()):
            slots_fmt = " · ".join(_fmt_time(ts, te) for ts, te in sorted(slots))
            lines.append(f"📆 {_fmt_date(d)}: {slots_fmt}")
        lines.append(f"🔗 Inserisci il risultato: {site_url}/tournaments/{tournament_id}")

        message = "\n".join(lines)
        payloads.append({
            "recipient_discord_id": other_user.discord_id,
            "message": message,
            "bot_token": bot_token,
        })
        if updated_user and updated_user.discord_id:
            payloads.append({
                "recipient_discord_id": updated_user.discord_id,
                "message": message,
                "bot_token": bot_token,
            })

    return payloads


def _send_dms_background(payloads: list[dict]) -> None:
    """Background task: open DM channels and send messages. Best-effort, never raises."""
    try:
        with httpx.Client(timeout=10) as client:
            for p in payloads:
                try:
                    dm = client.post(
                        "https://discord.com/api/v10/users/@me/channels",
                        headers={"Authorization": f"Bot {p['bot_token']}"},
                        json={"recipient_id": p["recipient_discord_id"]},
                    )
                    if dm.status_code not in (200, 201):
                        continue
                    channel_id = dm.json()["id"]
                    client.post(
                        f"https://discord.com/api/v10/channels/{channel_id}/messages",
                        headers={"Authorization": f"Bot {p['bot_token']}"},
                        json={"content": p["message"]},
                    )
                except Exception:
                    pass
    except Exception:
        pass


app.include_router(router)
