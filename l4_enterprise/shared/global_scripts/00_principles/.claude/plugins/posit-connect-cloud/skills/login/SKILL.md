---
name: login
description: |
  Login to Posit Connect Cloud management console.
  REQUIRED before any other operations - OAuth requires headed mode.
  Use: /posit-connect-cloud:login
trigger:
  - login posit
  - connect cloud login
  - 登入 posit
  - open posit connect
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

# Login to Posit Connect Cloud

## 🚨 CRITICAL: OAuth Requires Headed Mode

**Headless mode DOES NOT work with Posit Connect Cloud!**

Posit Connect uses OAuth authentication which blocks headless browsers with:
```
Invalid request
```

**MUST use `--headed` flag** to show browser window for manual login.

## Workflow

### Step 1: Open Browser in Headed Mode

```bash
agent-browser open "https://connect.posit.cloud" --headed
```

This opens a visible browser window. The user will see the Posit Connect login page.

### Step 2: Wait for User Login

**Tell the user:**
```
瀏覽器已開啟。請手動登入 Posit Connect Cloud。
登入完成後請告訴我。
```

The user needs to:
1. Click "Log in" button
2. Enter email and password
3. Complete OAuth flow

### Step 3: Verify Login Success

After user confirms login:

```bash
sleep 2
agent-browser snapshot -i | head -30
```

**Success indicators:**
- Shows "Home" link
- Shows "Publish" link
- Shows user avatar button (e.g., "Kyle Lin's avatar Kyle Lin")

**Failure indicators:**
- Still showing login form
- OAuth error message
- "Invalid request" message

### Step 4: Navigate to Home

If already logged in, ensure we're on the Home page:

```bash
# Look for Home link and click it
agent-browser snapshot -i | grep -E 'link "Home"'
# If found, click it
agent-browser click @e{home_ref}
```

## After Login

Once logged in, the browser session remains authenticated. You can:
- Navigate to apps from Home page
- Edit settings and variables
- Republish apps

**DO NOT close the browser** between operations - you'll need to login again.

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| "Invalid request" | Headless mode | Use `--headed` flag |
| OAuth redirect loop | Session issue | Close browser, try again |
| Login page not loading | Network | Check internet connection |

## Notes

- Browser session persists until `agent-browser close`
- All apps share the same login session
- Timeout after ~30 minutes of inactivity
