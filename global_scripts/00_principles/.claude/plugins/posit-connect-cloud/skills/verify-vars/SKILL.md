---
name: verify-vars
description: |
  Verify environment variables are correctly set in Posit Connect app.
  PREREQUISITE: Must be logged in first (use login skill).
  Use: /posit-connect-cloud:verify-vars <app-name>
trigger:
  - verify variables
  - check env
  - 檢查環境變數
  - list variables
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Verify Environment Variables

## Prerequisites

**Must be logged in first!** Use `/posit-connect-cloud:login` if not already logged in.

## Required Variables

All sandbox apps should have these variables:

### Database Connection (REQUIRED)

| Variable | Expected Value |
|----------|----------------|
| `SUPABASE_DB_HOST` | `db.oziernubrqgqthjksbii.supabase.co` |
| `SUPABASE_DB_PORT` | `5432` |
| `SUPABASE_DB_NAME` | `postgres` |
| `SUPABASE_DB_USER` | `postgres` |
| `SUPABASE_DB_PASSWORD` | (masked) |

### Legacy Variables (CAN BE REMOVED)

These old PG* variables are no longer used:
- `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`, `PGSSLMODE`

## Workflow

### Step 1: Navigate to App's Variables

```bash
# Navigate Home → App → Settings → Variables
HOME_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'link "Home"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$HOME_REF
sleep 1

APP_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'link "{app-name}"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$APP_REF
sleep 1

SETTINGS_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'Edit settings' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$SETTINGS_REF
sleep 0.5

VAR_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'link "Variables"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$VAR_REF
sleep 0.5
```

### Step 2: Check Variable List

```bash
agent-browser snapshot -i 2>/dev/null
```

Look for "Edit variable" buttons - each indicates an existing variable.

## Notes

- Variable values are masked in the UI
- To verify actual values work, use `/posit-connect-cloud:test-app`
- Missing SUPABASE_DB_* variables will cause database connection errors
