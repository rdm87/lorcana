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
