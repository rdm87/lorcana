# Lorcana Online League — Development Guidelines

## Project Overview
Tournament manager for Lorcana card game. FastAPI (Python) backend + Flutter Web frontend.
Discord OAuth2 login. SQLite in dev. Deployed as static Flutter build + uvicorn API.

## Tech Stack
- **Backend**: FastAPI + SQLAlchemy ORM (SQLite dev) — `backend/app/`
- **Frontend**: Flutter Web (dart:html for localStorage/window.location) — `frontend/lib/`
- **Auth**: Discord OAuth2 → JWT stored in `localStorage['lorcana_token']`
- **Router**: GoRouter (Flutter) — routes defined in `frontend/lib/main.dart`

## Responsive Design (REQUIRED FOR ALL SCREENS)

Every screen must work correctly at these breakpoints:
- **Mobile**: < 600px — single column, compact layouts
- **Tablet**: 600–900px — intermediate
- **Desktop**: > 900px — multi-column, full layout

### Rules
- Use `LayoutBuilder` to switch between `Row` (wide) and `Column` (narrow) layouts
- Use `MediaQuery.sizeOf(context).width` for global breakpoints (AppBar, etc.)
- Dialogs: use `SizedBox(width: double.maxFinite)` for content width — never a fixed px width
- Tables with fixed-width columns: wrap in `SingleChildScrollView(scrollDirection: Axis.horizontal)` on narrow screens via `LayoutBuilder`
- Prefer `Wrap` over `Row` for button groups that may overflow
- Avoid hardcoded widths on containers that hold user-visible content; use `ConstrainedBox(maxWidth: N)` for max-width caps
- All screens already use `ConstrainedBox(maxWidth: N)` as desktop caps — keep this pattern

### Existing Responsive Breakpoints (already implemented)
- `home_screen.dart`: 480px (hero layout), 600px (AppBar), 760px (tournament grid)
- `tournament_detail_screen.dart`: 850px (register/players panels), standings table uses `LayoutBuilder` for scroll
- `availability_screen.dart`: dialog uses `double.maxFinite` for content width
- `create_tournament_screen.dart`: 400px (cap/fee row, dates row switch to Column)

## Design System
- **Primary**: `#5D2EA6` (purple)
- **Secondary**: `#FFD66B` (yellow)
- **Dark heading**: `#2D145C`
- **Background gradient**: `LinearGradient([Color(0xFFF3EEFF), Color(0xFFFFF8E7)], topLeft→bottomRight)`
- **Cards**: `elevation: 0`, `BorderRadius.circular(16–28)`, white background
- **Errors**: `SnackBar` with `backgroundColor: Colors.red.shade700`
- **Success snackbar**: default (no background override)

## File Structure
```
backend/
  app/
    main.py       — FastAPI app, all API endpoints
    models.py     — SQLAlchemy ORM models
    schemas.py    — Pydantic request/response schemas
    auth.py       — Discord OAuth2 + JWT

frontend/lib/
  main.dart                        — App entry, GoRouter routes, theme
  src/
    config.dart                    — AppConfig.apiBaseUrl
    models/tournament.dart         — Tournament, TournamentDetail, MatchResult, etc.
    models/user.dart               — AppUser
    services/api_client.dart       — All HTTP calls (token via localStorage)
    services/session.dart          — Session ChangeNotifier (Provider)
    screens/
      home_screen.dart             — Tournament list, admin AppBar actions
      tournament_detail_screen.dart — Detail, registration, matches, standings
      availability_screen.dart     — Availability time slots
      create_tournament_screen.dart — Create/edit tournament form
      bot_config_screen.dart       — Discord bot configuration
      auth_callback_screen.dart    — OAuth2 callback handler
```

## Code Patterns
- Admin check: `context.watch<Session>().isAdmin`
- Async in `initState`: `WidgetsBinding.instance.addPostFrameCallback((_) async { ... })`
- API errors: `throw Exception(ApiClient._parseError(r))`
- No shared widgets folder — all widgets are defined inline in each screen file
- Availability time slots: 12 two-hour bands covering 00:00–24:00 (defined in `_kSlots`)

## Discord Bot Integration

The bot token is stored in `BotConfig` (DB, singleton row id=1). All Discord calls are best-effort background tasks — failures are silently swallowed.

### DMs sent automatically
1. **Availability overlap**: when a player saves availability, opponents who share a slot get a DM with common slots + link to the tournament (`_collect_dm_payloads` → `_send_dms_background`).
2. **Result proposed**: when a player submits a result and status becomes `"proposed"`, the opponent gets a DM with the score and two action links (`_build_result_dm_payload` → `_send_dms_background`).

### Discord confirm/reject endpoints (no login required)
- `GET /api/matches/{id}/discord-confirm?token=...` — validates signed JWT, sets `result_status = "confirmed"`, returns styled HTML + meta-refresh to the tournament page.
- `GET /api/matches/{id}/discord-reject?token=...` — validates signed JWT, resets match to `"pending"`, DMs all admins with dispute info, returns styled HTML + meta-refresh.
- Tokens are signed with the JWT secret (`sub = "match_discord"`, 7-day expiry). Helper functions: `create_match_action_token` / `decode_match_action_token` in `auth.py`.
- The proposer cannot confirm their own result via Discord (same rule as the site).
- Token target URL uses `settings.backend_url`; redirect target uses `settings.frontend_url`.

### Availability screen — day toggle
Tapping the date label in "Le mie disponibilità" (and admin edit dialog) toggles all 12 slots for that day: select all if not all are selected, deselect all otherwise. Implemented via `_toggleDay(dateKey)` in `_AvailabilityScreenState` and `_AdminEditDialogState`.
