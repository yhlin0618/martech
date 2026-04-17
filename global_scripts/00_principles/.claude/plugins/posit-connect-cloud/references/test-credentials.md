# Test Credentials

## App Login Credentials

For testing deployed Shiny apps:

### Standard Test Account

| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `618112` |

### Password-Only Mode

Some apps only require password:

| Field | Value |
|-------|-------|
| Password | `VIBE` |

## Posit Connect Cloud Access

**IMPORTANT:** Posit Connect Cloud uses OAuth authentication.

### OAuth Limitations

- **Headless browsers DO NOT WORK** - OAuth blocks automated login
- **Must use headed mode** - Run `agent-browser open "https://connect.posit.cloud" --headed`
- User must manually complete OAuth login in the visible browser window

### Login Flow

1. Open `https://connect.posit.cloud` with `--headed` flag
2. User clicks "Log in" button
3. User enters email and password
4. OAuth completes authentication
5. Browser session remains authenticated

## Database Credentials

### Current Standard: SUPABASE_DB_* Variables

| Variable | Value |
|----------|-------|
| `SUPABASE_DB_HOST` | `db.oziernubrqgqthjksbii.supabase.co` |
| `SUPABASE_DB_PORT` | `5432` |
| `SUPABASE_DB_NAME` | `postgres` |
| `SUPABASE_DB_USER` | `postgres` |
| `SUPABASE_DB_PASSWORD` | `nuvpa6-dufqUq-pichez` |

### Legacy (DEPRECATED)

These PG* variables are no longer used:
- `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD`, `PGDATABASE`, `PGSSLMODE`

## API Keys

| Service | Environment Variable |
|---------|---------------------|
| OpenAI | `OPENAI_API_KEY` |
