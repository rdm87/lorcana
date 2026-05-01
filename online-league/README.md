# Lorcana Tournament Manager

Sito web per organizzare tornei Disney Lorcana con login Discord, area admin, gestione cap utenti, quota iscrizione, link PayPal, periodo del torneo, descrizione regole e distribuzione percentuale del montepremi.

## Stack

- Frontend: Flutter Web
- Backend: FastAPI + SQLite
- Login: Discord OAuth2 `identify`
- Auth interna: JWT Bearer

Discord usa OAuth2 per generare token utente con scope autorizzati; qui viene richiesto solo `identify` per leggere l'identità base dell'utente.

## Avvio backend

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# modifica .env con client id/secret Discord e lista ADMIN_DISCORD_IDS
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Nel portale Discord Developer devi configurare il redirect URI:

```text
http://localhost:8000/auth/discord/callback
```

## Avvio frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://localhost:8000
```

## Build frontend produzione

```bash
cd frontend
flutter build web --release --dart-define=API_BASE_URL=https://api.tuo-dominio.it
```

Output in:

```text
frontend/build/web
```

## Configurazione admin

Nel file `backend/.env` valorizza:

```text
ADMIN_DISCORD_IDS=123456789012345678,987654321098765432
```

Solo questi utenti potranno creare tornei e marcare iscrizioni come pagate.

## API principali

- `GET /auth/discord/login`
- `GET /auth/discord/callback`
- `GET /me`
- `GET /tournaments`
- `POST /tournaments` admin only
- `POST /tournaments/{id}/register`
- `POST /registrations/{id}/paid` admin only

## Note implementative

Il link PayPal viene salvato come URL e mostrato all'utente. La conferma automatica del pagamento non è ancora integrata: per produzione va aggiunta integrazione PayPal Checkout/Webhook per marcare `paid=true` in modo automatico.

## Aggiornamento funzionale richiesto

Questa versione modifica il flusso utente:

- La home mostra sempre la lista dei tornei attivi, sia per utenti admin sia per utenti standard.
- Ogni torneo è cliccabile e apre una pagina dettaglio.
- Dalla pagina dettaglio è possibile iscriversi.
- Il campo `Account Discord` viene precompilato con il nome utente recuperato dalla login Discord.
- In iscrizione vengono richiesti anche `Nome` e `Cognome`.
- Nella pagina dettaglio torneo è visibile la lista pubblica degli iscritti, limitata a `Nome` e `Cognome`.
- La grafica è stata resa più snella, con palette viola/oro e richiami leggeri al mondo Disney/Lorcana.

### Nota database SQLite

Se stai usando il database SQLite locale già creato dalla versione precedente, elimina il file prima di riavviare il backend, perché sono state aggiunte nuove colonne alla tabella `registrations`:

```bash
cd backend
rm -f lorcana.db
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Su Windows CMD:

```cmd
cd backend
del lorcana.db
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Aggiornamenti v3

- Link Home in alto a sinistra nelle pagine interne.
- Creazione torneo con selezione date tramite calendario e orario, non più input ISO testuale.
- Pagina dettaglio torneo con refresh automatico ogni minuto e pulsante refresh manuale.
- Se l'utente autenticato è già iscritto al torneo, il form di iscrizione viene nascosto e compare il pulsante "Cancella iscrizione".
- Nuovo endpoint backend: `DELETE /tournaments/{tournament_id}/registration/me`.

Dopo l'aggiornamento riavvia backend e frontend. Se hai già un database vecchio e vuoi ripartire pulito:

```bash
cd backend
rm -f lorcana.db
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
