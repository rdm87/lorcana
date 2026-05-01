# Lorcana Online League — Project Status

> Last updated: 2026-04-30

## Overview

Tournament manager for Disney Lorcana TCG. Players login via Discord OAuth2, browse tournaments, and register. Admins create tournaments and manage registrations.

**Stack:** FastAPI (Python) + Flutter Web  
**Auth:** Discord OAuth2 → JWT Bearer  
**DB:** SQLite (dev) → PostgreSQL (prod target)

---

## Architecture

```
Discord OAuth2
    ↓
Backend: FastAPI + SQLAlchemy + SQLite
    ↓ REST JSON + Bearer Token
Frontend: Flutter Web + Go Router + Provider
```

### Backend (`backend/`)

| File | Responsabilità |
|------|----------------|
| `app/main.py` | Endpoint FastAPI, CORS config |
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
| `src/models/tournament.dart` | Tournament, TournamentDetail, Registration models |
| `src/models/user.dart` | AppUser model |
| `src/screens/home_screen.dart` | Lista tornei, responsive (2 col > 760px) |
| `src/screens/tournament_detail_screen.dart` | Dettaglio, form iscrizione, auto-refresh 1min |
| `src/screens/create_tournament_screen.dart` | Form creazione torneo (admin only) |
| `src/screens/auth_callback_screen.dart` | Gestione callback Discord OAuth2 |
| `src/config.dart` | `apiBaseUrl` (override via `--dart-define`) |

---

## API Endpoints

| Method | Path | Auth | Descrizione |
|--------|------|------|-------------|
| GET | `/health` | — | Health check |
| GET | `/auth/discord/login` | — | Redirect a Discord OAuth2 |
| GET | `/auth/discord/callback` | — | Callback, crea user, genera JWT |
| GET | `/me` | user | Profilo utente corrente |
| GET | `/tournaments` | — | Lista tornei (pubblica) |
| GET | `/tournaments/{id}` | optional | Dettaglio torneo + iscritti |
| POST | `/tournaments` | admin | Crea torneo |
| POST | `/tournaments/{id}/register` | user | Iscrive al torneo |
| DELETE | `/tournaments/{id}/registration/me` | user | Cancella propria iscrizione |
| POST | `/registrations/{id}/paid` | admin | Marca iscrizione come pagata |

---

## Data Models

### Tournament
- `title`, `cap`, `entry_fee_eur`, `paypal_link`
- `start_date`, `end_date`, `rules_description`
- `prize_players_count`, `prize_distribution` (JSON string)
- `created_by_id` (FK → User)

### Registration
- `tournament_id`, `user_id` (unique insieme)
- `discord_account`, `first_name`, `last_name`
- `paid` (bool, default=false — marcato manualmente dall'admin)

---

## Implemented Features

- [x] Discord OAuth2 login + JWT (7 giorni)
- [x] Admin role via `ADMIN_DISCORD_IDS` env var
- [x] Lista tornei pubblica con progress bar iscritti/cap
- [x] Dettaglio torneo con auto-refresh ogni minuto
- [x] Iscrizione con nome, cognome, account Discord
- [x] Cancellazione iscrizione
- [x] Creazione torneo (admin): date picker, percentuali premi
- [x] Validazione premi: somma = 100%, posizioni = `prize_players_count`
- [x] Validazione cap: blocca iscrizione se torneo pieno
- [x] Vista pubblica iscritti (nome/cognome)
- [x] UI responsive (2 colonne su > 760px)
- [x] Tema branding viola (`#5D2EA6`) / oro (`#FFD66B`)

---

## Pending / To Do

### Alta priorità

- [ ] **Admin panel** — dashboard con lista iscritti, bulk mark paid, export CSV
- [ ] **PayPal integration** — webhook per auto-mark `paid=true` + IPN validation
- [ ] **Tournament status** — stati `draft` / `active` / `concluded` con transizioni

### Media priorità

- [ ] **Notifiche** — email conferma iscrizione, alert admin su nuovi iscritti
- [ ] **Bracket / match management** — fasi torneo, risultati, classifica
- [ ] **Refresh token** — rotazione JWT, revoca sessioni
- [ ] **Rate limiting** — throttling su endpoint auth e registrazione
- [ ] **Admin: delete tournament** — endpoint + UI per eliminare tornei

### Bassa priorità / Prod readiness

- [ ] **PostgreSQL** — migrazione da SQLite per produzione
- [ ] **Docker** — Dockerfile + docker-compose per deploy
- [ ] **CI/CD** — pipeline build/test/deploy
- [ ] **Dark mode** — tema alternativo
- [ ] **i18n** — switch IT/EN

---

## Known Issues

| Issue | Impatto | Note |
|-------|---------|------|
| Pagamenti solo manuali | Admin deve marcare `paid` a mano | Blocca automazione |
| SQLite in dev | Non scalabile, no concorrenza write | OK per alpha |
| `prize_distribution` come stringa JSON | Fragile, meglio tabella separata | Tech debt |
| JWT senza refresh | Logout forzato dopo 7 giorni | UX subottimale |
| `.env` con secret Discord in chiaro | Rischio se committato per errore | Aggiungere a `.gitignore` |

---

## Environment Setup

### Backend

```bash
cd backend
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
cp .env.example .env      # Poi configurare Discord credentials
uvicorn app.main:app --reload --port 8000
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

### Variabili d'ambiente richieste (`.env`)

```
DATABASE_URL=sqlite:///./lorcana.db
JWT_SECRET=<long-random-secret>
DISCORD_CLIENT_ID=<discord-app-id>
DISCORD_CLIENT_SECRET=<discord-app-secret>
DISCORD_REDIRECT_URI=http://localhost:8000/auth/discord/callback
FRONTEND_URL=http://localhost:8080
BACKEND_URL=http://localhost:8000
ADMIN_DISCORD_IDS=<discord-user-id>
```

---

## Git Status (2026-04-30)

**Branch:** `main`  
**Ultimi commit:** `6080148 first commit`, `7ddfe5c Initial commit`

File modificati rispetto all'ultimo commit:
- `backend/app/auth.py`, `main.py`, `models.py`, `schemas.py`
- `frontend/lib/main.dart`, `tournament.dart`, `create_tournament_screen.dart`, `home_screen.dart`, `api_client.dart`
- `README.md`

File nuovi non ancora tracciati:
- `frontend/lib/src/screens/tournament_detail_screen.dart` ← **da committare**
- `backend/.env` ← non committare (secret!)
- `backend/lorcana.db` ← aggiungere a `.gitignore`
- `frontend/pubspec.lock` ← valutare se committare

---

## .gitignore Raccomandato (da aggiornare)

```
# Backend
backend/.env
backend/lorcana.db
backend/venv/
backend/app/__pycache__/

# Frontend
frontend/build/
frontend/.dart_tool/
frontend/.flutter-plugins-dependencies
```
