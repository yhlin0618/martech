---
name: batch-update
description: |
  Batch update environment variables across all sandbox apps (21 total).
  PREREQUISITE: Must be logged in first (use login skill).
  Use: /posit-connect-cloud:batch-update
trigger:
  - batch update
  - update all apps
  - 批次更新
  - sync variables
  - add supabase vars
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Batch Update Environment Variables

## Prerequisites

**Must be logged in first!** Use `/posit-connect-cloud:login` if not already logged in.

## Target Apps (21 Total)

| App Type | Instances | Count |
|----------|-----------|-------|
| BrandEdge | sandbox_brandedge00 - 04 | 5 |
| InsightForge | sandbox_insightforge00 - 04 | 5 |
| TagPilot | sandbox_tagpilot00 - 05 | 6 |
| VitalSigns | sandbox_vitalsigns00 - 04 | 5 |

## Standard Variables

### Supabase Database Connection (REQUIRED)

```bash
SUPABASE_DB_HOST=db.oziernubrqgqthjksbii.supabase.co
SUPABASE_DB_PORT=5432
SUPABASE_DB_NAME=postgres
SUPABASE_DB_USER=postgres
SUPABASE_DB_PASSWORD=nuvpa6-dufqUq-pichez
```

## Workflow

### Step 1: Confirm Operation

Ask user:
```
將為 21 個 sandbox apps 批次新增以下環境變數：
- SUPABASE_DB_HOST
- SUPABASE_DB_PORT
- SUPABASE_DB_NAME
- SUPABASE_DB_USER
- SUPABASE_DB_PASSWORD

這會花費約 10-15 分鐘。確定要繼續嗎？
```

### Step 2: Process Each App

```bash
process_app() {
    local APP_NAME=$1
    echo "Processing: $APP_NAME"

    # Navigate to Home
    HOME_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'link "Home"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
    agent-browser click @$HOME_REF
    sleep 1

    # Find and click app
    APP_REF=$(agent-browser snapshot -i 2>/dev/null | grep "link \"$APP_NAME\"" | grep -o 'ref=e[0-9]*' | cut -d= -f2)
    if [ -z "$APP_REF" ]; then
        echo "  ERROR: Could not find $APP_NAME"
        return 1
    fi
    agent-browser click @$APP_REF
    sleep 1

    # Click Edit settings
    SETTINGS_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'Edit settings' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
    agent-browser click @$SETTINGS_REF
    sleep 0.5

    # Click Variables
    VAR_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'link "Variables"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
    agent-browser click @$VAR_REF
    sleep 0.5

    # Add each variable
    for var in "SUPABASE_DB_HOST:db.oziernubrqgqthjksbii.supabase.co" \
               "SUPABASE_DB_PORT:5432" \
               "SUPABASE_DB_NAME:postgres" \
               "SUPABASE_DB_USER:postgres" \
               "SUPABASE_DB_PASSWORD:nuvpa6-dufqUq-pichez"; do
        VAR_NAME="${var%%:*}"
        VAR_VALUE="${var#*:}"

        ADD_REF=$(agent-browser snapshot -i 2>/dev/null | grep '"Add variable"' | grep -o 'ref=e[0-9]*' | head -1 | cut -d= -f2)
        agent-browser click @$ADD_REF
        sleep 0.3

        SNAPSHOT=$(agent-browser snapshot -i 2>/dev/null)
        NAME_REF=$(echo "$SNAPSHOT" | grep 'textbox "Name"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
        VALUE_REF=$(echo "$SNAPSHOT" | grep 'textbox "Value"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
        SAVE_REF=$(echo "$SNAPSHOT" | grep 'button "Save"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)

        agent-browser fill @$NAME_REF "$VAR_NAME"
        agent-browser fill @$VALUE_REF "$VAR_VALUE"
        agent-browser click @$SAVE_REF
        sleep 0.3
    done

    # Click Republish
    REPUBLISH_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'button "Republish"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
    agent-browser click @$REPUBLISH_REF
    echo "  $APP_NAME: Done"
    sleep 2
}
```

### Step 3: Execute Batch

```bash
# BrandEdge (5 apps)
for i in 00 01 02 03 04; do
    process_app "sandbox_brandedge$i"
done

# InsightForge (5 apps)
for i in 00 01 02 03 04; do
    process_app "sandbox_insightforge$i"
done

# TagPilot (6 apps)
for i in 00 01 02 03 04 05; do
    process_app "sandbox_tagpilot$i"
done

# VitalSigns (5 apps)
for i in 00 01 02 03 04; do
    process_app "sandbox_vitalsigns$i"
done
```

## Troubleshooting

### App Not Found

If an app is not visible on the Home page:
1. The page might need scrolling - take another snapshot
2. The app name might be different - check exact spelling
3. Try navigating away and back to Home

## Notes

- Each app takes ~30-45 seconds to process
- Total batch time: 10-15 minutes for 21 apps
- All apps are republished automatically after adding variables
