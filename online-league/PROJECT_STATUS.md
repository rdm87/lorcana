# Lorcana Online League — Project Status

> Last updated: 2026-05-01

## Overview

Tournament manager for Disney Lorcana TCG. Players login via Discord OAuth2, browse tournaments, and register. Admins create tournaments and manage registrations.

**Stack:** FastAPI (Python) + Flutter Web  
**Auth:** Discord OAuth2 → JWT Bearer  
**DB:** SQLite (dev) → PostgreSQL (prod)  
**Deploy:** Single server — nginx + gunicorn + postgres via Docker Compose  
**CI/CD:** GitHub Actions → rsync build + git pull + docker compose up

---

## Architecture

```
Discord OAuth2
    ↓
Backend: FastAPI + SQLAlchemy + PostgreSQL
    ↓ REST JSON + Bearer Token
Frontend: Flutter Web + Go Router + Provider
    ↑
nginx (porta 8080) — proxy /api/ → backend:9000, serve Flutter web da /home/ansible/lorcana-web
```

### Backend (`backend/`)

| File | Responsabilità |
|------|----------------|
| `app/main.py` | Endpoint FastAPI, CORS, APIRouter prefisso `/api` |
| `app/models.py` | ORM: User, Tournament, Registration |
| `app/schemas.py` | Pydantic I/O + validazione business rules |
| `app/auth.py` | JWT creation/validation, dipendenze auth |
| `app/db.py` | SQLAlchemy engine + session factory |
| `app/config.py` | Settings da `.env` (singleton cached) |

### Frontend (`frontend/lib/`)

| File | Responsabilità |
|------|----------------|
| `main.dart` | App entry, routing (go_router), tema viola/oro |
| `src/services/api_client.dart` | HTTP client, token storage (localStorage) |
| `src/services/session.dart` | State management (ChangeNotifier), login/logout |
| `src/models/tournament.dart` | Tournament, TournamentDetail, FullRegistration, PublicRegistration |
| `src/models/user.dart` | AppUser model |
| `src/screens/home_screen.dart` | Lista tornei, responsive (2col > 760px, AppBar compatta < 600px) |
| `src/screens/tournament_detail_screen.dart` | Dettaglio, form iscrizione, admin panel, auto-refresh 1min |
| `src/screens/create_tournament_screen.dart` | Form creazione torneo (admin only) |
| `src/screens/auth_callback_screen.dart` | Gestione callback Discord OAuth2 |
| `src/config.dart` | `apiBaseUrl` (default `localhost:9000`, override via `--dart-define`) |

---

## API Endpoints

| Method | Path | Auth | Descrizione |
|--------|------|------|-------------|
| GET | `/api/health` | — | Health check |
| GET | `/api/auth/discord/login` | — | Redirect a Discord OAuth2 |
| GET | `/api/auth/discord/callback` | — | Callback, crea user, genera JWT |
| GET | `/api/me` | user | Profilo utente corrente |
| GET | `/api/tournaments` | — | Lista tornei (pubblica) |
| GET | `/api/tournaments/{id}` | optional | Dettaglio + iscritti (admin: dati completi) |
| POST | `/api/tournaments` | admin | Crea torneo |
| POST | `/api/tournaments/{id}/register` | user | Iscrive al torneo |
| DELETE | `/api/tournaments/{id}/registration/me` | user | Cancella propria iscrizione |
| POST | `/api/tournaments/{id}/admin/register` | admin | Aggiunge iscrizione manuale (senza Discord) |
| POST | `/api/registrations/{id}/paid` | admin | Marca iscrizione come pagata |
| DELETE | `/api/registrations/{id}/paid` | admin | Rimuove flag pagamento |
| DELETE | `/api/registrations/{id}` | admin | Elimina qualsiasi iscrizione |

---

## Data Models

### Tournament
- `title`, `cap`, `entry_fee_eur`, `paypal_link`
- `start_date`, `end_date`, `rules_description`
- `prize_players_count`, `prize_distribution` (JSON string)
- `created_by_id` (FK → User)

### Registration
- `tournament_id`, `user_id` (nullable — null per iscrizioni admin manuali)
- `discord_account`, `first_name`, `last_name`
- `paid` (bool, default=false)

### Match
- `tournament_id`, `reg1_id`, `reg2_id` (FK → Registration)
- `games_reg1`, `games_reg2` (nullable — null finché il risultato non è inserito)
- `proposed_by_reg_id` (nullable — chi ha proposto il risultato)
- `result_status`: `pending` | `proposed` | `confirmed`

### StandingEntry (calcolata, non persistita)
- `played`, `wins`, `draws`, `losses`, `points` (V=3pt, P=1pt, S=0pt)
- `games_won`, `games_lost` — game vinti/subiti sommati su tutte le partite confermate
- Ordine: punti ↓, vittorie ↓, differenza game ↓, sconfitte ↑

---

## Implemented Features

- [x] Discord OAuth2 login + JWT (7 giorni)
- [x] Admin role via `ADMIN_IDS` env var (lista Discord ID separati da virgola)
- [x] Lista tornei pubblica con status badge e progress bar iscritti/cap
- [x] Dettaglio torneo con auto-refresh ogni minuto
- [x] Iscrizione con nome, cognome, account Discord
- [x] Cancellazione iscrizione utente
- [x] Creazione torneo (admin): date picker, percentuali premi live preview
- [x] Validazione premi: somma = 100%, posizioni = `prize_players_count`
- [x] Validazione cap: blocca iscrizione se torneo pieno
- [x] Vista pubblica iscritti (nome/cognome)
- [x] **Admin panel** — lista completa con Discord, toggle pagato/non pagato, eliminazione, aggiunta manuale
- [x] UI responsive — 2 colonne su > 760px, AppBar compatta su < 600px, hero card verticale su < 480px
- [x] Tema branding viola (`#5D2EA6`) / oro (`#FFD66B`)
- [x] Docker Compose: postgres + gunicorn (4 worker) + nginx, porta 8080
- [x] CI/CD: GitHub Actions build Flutter web + rsync + git pull + docker compose up
- [x] **Tournament lifecycle** — status `registration` → `ongoing` → `completed`
- [x] **Home screen** — sezioni "Tornei in corso" / "Prossimi tornei" / "Tornei conclusi"
- [x] **Admin start** — pulsante avvia torneo + auto-start (data passata + tutti pagati)
- [x] **Round-robin schedule** — generazione automatica calendario all-vs-all
- [x] **Match results** — proposta risultato + conferma avversario (o admin)
- [x] **Standings** — classifica live: V=3pt, P=1pt, S=0pt; colonne game vinti (GV) e game subiti (GS)
- [x] **Dettaglio torneo** — tab Informazioni / Calendario / Classifica (tornei in corso)
- [x] **Calendario giocatore** — vista a due livelli: griglia giocatori → partite del giocatore selezionato
- [x] **Admin** — inserimento/conferma risultato diretto su qualsiasi partita; modifica torneo (stato registrazione)
- [x] **Test tournament** — generatore torneo con N giocatori finti (tutti pagati) per testing rapido
- [x] **Anonimizzazione** — nomi giocatori nascosti per utenti non loggati ("Giocatore 1", "Giocatore 2"...)

---

## Infrastruttura di Deploy

| Componente | Dettaglio |
|---|---|
| Server | Singolo VPS |
| Porta esposta | `8080` |
| nginx | Proxy `/api/` → `backend:9000`, serve Flutter web da `/home/ansible/lorcana-web` |
| Backend | gunicorn 4 worker uvicorn, porta `9000` interna |
| Database | PostgreSQL 16 (container), dati in volume `pgdata` |
| Deploy path | `/opt/git/lorcana/online-league` |
| Flutter web build | rsync CI → `/home/ansible/lorcana-web/` |
| Secrets server | `/opt/git/lorcana/online-league/.env` e `backend/.env` (mai nel repo) |
| SSH user CI | `ansible` |

---

## Pending / To Do

### Alta priorità

- [ ] **PayPal integration** — webhook per auto-mark `paid=true`
- [ ] **Tournament status** — stati `draft` / `active` / `concluded` con transizioni
- [ ] **HTTPS** — certificato SSL (Let's Encrypt + nginx)

### Media priorità

- [ ] **Notifiche** — email conferma iscrizione, alert admin su nuovi iscritti
- [ ] **Bracket / match management** — fasi torneo, risultati, classifica
- [ ] **Refresh token** — rotazione JWT, revoca sessioni
- [ ] **Rate limiting** — throttling su endpoint auth e registrazione
- [ ] **Admin: delete tournament** — endpoint + UI per eliminare tornei
- [ ] **Dark mode** — tema alternativo

### Bassa priorità

- [ ] **Alembic migrations** — gestione schema DB in produzione
- [ ] **i18n** — switch IT/EN
- [ ] **Export CSV** — lista iscritti scaricabile dall'admin

---

## Known Issues

| Issue | Impatto | Note |
|-------|---------|------|
| Pagamenti solo manuali | Admin deve marcare `paid` a mano | Blocca automazione |
| `prize_distribution` come stringa JSON | Fragile | Tech debt, meglio tabella separata |
| JWT senza refresh | Logout forzato dopo 7 giorni | UX subottimale |
| `create_all` SQLAlchemy non migra schema | Su DB esistente le modifiche colonne non vengono applicate | Richiede Alembic in prod |

---

## Environment Setup (locale)

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
# Creare backend/.env con le variabili sotto
uvicorn app.main:app --reload --port 9000
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:9000
```

### Variabili d'ambiente richieste (`backend/.env`)

```
APP_NAME=Lorcana Online League
SECRET_KEY=<chiave-jwt-lunga-e-casuale>
DISCORD_CLIENT_ID=<discord-app-id>
DISCORD_CLIENT_SECRET=<discord-app-secret>
DISCORD_REDIRECT_URI=http://localhost:9000/api/auth/discord/callback
FRONTEND_URL=http://localhost:8080
ADMIN_IDS=<discord-user-id>
ALLOWED_ORIGINS=http://localhost:8080,http://localhost:3000
DATABASE_URL=sqlite:///./lorcana.db   # oppure postgresql://... in prod
DB_PASSWORD=<solo-in-prod>
```

### Variabili d'ambiente produzione (`.env` nella root del progetto)

```
DB_PASSWORD=<password-postgres>
```

---

## GitHub Actions Secrets / Variables

| Nome | Tipo | Valore |
|------|------|--------|
| `SERVER_HOST` | Secret | IP/hostname del server |
| `SERVER_SSH_KEY` | Secret | Chiave SSH privata (RSA, senza CRLF) |
| `SERVER_USER` | Variable | `ansible` (o utente SSH) |

`DEPLOY_PATH` è hardcoded nel workflow: `/opt/git/lorcana/online-league`
