---
name: test-app
description: |
  Test deployed Posit Connect Shiny app functionality.
  Opens the app URL directly (no Posit Connect login needed).
  Use: /posit-connect-cloud:test-app <app-name>
trigger:
  - test app
  - test login
  - verify app
  - 測試 app
  - check app
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Test Posit Connect Shiny App

## Overview

This skill tests the deployed Shiny app by:
1. Opening the public app URL
2. Logging in with test credentials
3. Verifying the dashboard loads correctly

**Note:** This tests the app itself, NOT the Posit Connect management console.

## App URLs

| App | URL Pattern |
|-----|-------------|
| BrandEdge | `https://kyleyhl-sandbox-brandedge{NN}.share.connect.posit.cloud/` |
| InsightForge | `https://kyleyhl-sandbox-insightforge{NN}.share.connect.posit.cloud/` |
| TagPilot | `https://kyleyhl-sandbox-tagpilot{NN}.share.connect.posit.cloud/` |
| VitalSigns | `https://kyleyhl-sandbox-vitalsigns{NN}.share.connect.posit.cloud/` |

Where `{NN}` is the instance number (00-05).

## Test Credentials

| Field | Value |
|-------|-------|
| Username | `admin` |
| Password | `618112` |

## Workflow

### Step 1: Open App URL

```bash
# Construct URL from app name
# sandbox_brandedge00 → https://kyleyhl-sandbox-brandedge00.share.connect.posit.cloud/
APP_NAME="{app-name}"
URL="https://kyleyhl-${APP_NAME//_/-}.share.connect.posit.cloud/"

agent-browser open "$URL"
sleep 10  # App cold start can take time
agent-browser snapshot -i
```

**Note:** Headless mode works for app testing (no OAuth).

### Step 2: Fill Login Form

```bash
SNAPSHOT=$(agent-browser snapshot -i 2>/dev/null)
USERNAME_REF=$(echo "$SNAPSHOT" | grep -i 'textbox.*user\|textbox.*帳號' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
PASSWORD_REF=$(echo "$SNAPSHOT" | grep -i 'textbox.*pass\|textbox.*密碼' | grep -o 'ref=e[0-9]*' | cut -d= -f2)

agent-browser fill @$USERNAME_REF "admin"
agent-browser fill @$PASSWORD_REF "618112"
```

### Step 3: Submit Login

```bash
LOGIN_REF=$(agent-browser snapshot -i 2>/dev/null | grep -i 'button.*login\|button.*登入' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$LOGIN_REF
sleep 5
agent-browser snapshot -i
```

### Step 4: Verify Dashboard

**Success indicators:**
- Sidebar menu visible
- Header with app name
- No R error messages

**Failure indicators:**
- Login form still visible
- "Error" or "錯誤" message
- Blank page

## Notes

- Cold start takes 60-90 seconds after app has been idle
- Each app instance has its own URL
- Test credentials are the same for all apps
