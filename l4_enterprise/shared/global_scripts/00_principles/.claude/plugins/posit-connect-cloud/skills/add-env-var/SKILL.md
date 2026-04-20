---
name: add-env-var
description: |
  Add environment variable to Posit Connect app.
  PREREQUISITE: Must be logged in first (use login skill).
  Use: /posit-connect-cloud:add-env-var <app-name> <VAR_NAME> <value>
trigger:
  - add environment variable
  - add env var
  - 新增環境變數
  - set variable
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Add Environment Variable to Posit Connect

## Prerequisites

**Must be logged in first!** Use `/posit-connect-cloud:login` if not already logged in.

## App Inventory

| App Type | Instances | Example |
|----------|-----------|---------|
| BrandEdge | sandbox_brandedge00 - 04 | sandbox_brandedge02 |
| InsightForge | sandbox_insightforge00 - 04 | sandbox_insightforge01 |
| TagPilot | sandbox_tagpilot00 - 05 | sandbox_tagpilot03 |
| VitalSigns | sandbox_vitalsigns00 - 04 | sandbox_vitalsigns00 |

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

### Step 3: Click Edit Settings

```bash
SETTINGS_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'Edit settings' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$SETTINGS_REF
sleep 0.5
```

### Step 4: Click Variables Tab

```bash
VAR_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'link "Variables"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$VAR_REF
sleep 0.5
```

### Step 5: Add Variable

```bash
# Click "Add variable" button
ADD_REF=$(agent-browser snapshot -i 2>/dev/null | grep '"Add variable"' | grep -o 'ref=e[0-9]*' | head -1 | cut -d= -f2)
agent-browser click @$ADD_REF
sleep 0.3

# Get form field references
SNAPSHOT=$(agent-browser snapshot -i 2>/dev/null)
NAME_REF=$(echo "$SNAPSHOT" | grep 'textbox "Name"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
VALUE_REF=$(echo "$SNAPSHOT" | grep 'textbox "Value"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
SAVE_REF=$(echo "$SNAPSHOT" | grep 'button "Save"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)

# Fill and save
agent-browser fill @$NAME_REF "{VAR_NAME}"
agent-browser fill @$VALUE_REF "{value}"
agent-browser click @$SAVE_REF
sleep 0.5

echo "{VAR_NAME}: Added"
```

### Step 6: Republish

```bash
REPUBLISH_REF=$(agent-browser snapshot -i 2>/dev/null | grep 'button "Republish"' | grep -o 'ref=e[0-9]*' | cut -d= -f2)
agent-browser click @$REPUBLISH_REF
echo "Republishing..."
sleep 3
```

## Notes

- Variable values are masked in UI after saving
- Multiple variables can be added in sequence without closing browser
