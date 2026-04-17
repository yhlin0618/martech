---
name: republish
description: |
  Republish Posit Connect app to apply configuration changes.
  PREREQUISITE: Must be logged in first (use login skill).
  Use: /posit-connect-cloud:republish <app-name>
trigger:
  - republish
  - redeploy
  - 重新部署
  - apply changes
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Republish Posit Connect App

## Prerequisites

**Must be logged in first!** Use `/posit-connect-cloud:login` if not already logged in.

## Workflow

### Step 1: Navigate to Home

```bash
HOME_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'link "Home"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$HOME_REF
sleep 1
```

### Step 2: Find and Click App

```bash
APP_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'link "{app-name}"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$APP_REF
sleep 1
```

### Step 3: Click Republish

```bash
REPUBLISH_REF=$(agent-browser snapshot -i 2>/dev/null | grep -E 'tab "Republish"|button "Republish"' | grep -o 'ref=e[0-9]*' | head -1 | cut -d= -f2)
agent-browser click @$REPUBLISH_REF
echo "Republishing..."
sleep 3
```

## Notes

- Republish is required after adding/changing environment variables
- Deployment takes 60-120 seconds
- You can start the next app's republish without waiting
