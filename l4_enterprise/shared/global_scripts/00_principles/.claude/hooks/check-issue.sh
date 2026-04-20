#!/bin/bash
# IC_R009 Issue Tracking Enforcement Hook
# Triggered BEFORE Edit/Write tool calls
#
# Checks if a GitHub Issue has been associated with the current session.
# If not, returns additionalContext reminding Claude to create one first.
#
# State file: $CLAUDE_PROJECT_DIR/.claude/.current_issue
#   - Created by Claude after `gh issue create` (writes issue number)
#   - Each new session starts fresh (no state file = no issue yet)
#
# Related: IC_R009 (Bidirectional Traceability)

set -e

INPUT=$(cat /dev/stdin)

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only check for Edit and Write tools (code modifications)
case "$TOOL_NAME" in
  Edit|Write) ;;
  *) exit 0 ;;
esac

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file_path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Skip non-code files (allow editing config, settings, memory, etc.)
# Only enforce for actual project code files (.R, .yaml in code dirs, .qmd, etc.)
SKIP=false

# Skip .claude/ internal files (settings, hooks, memory)
if echo "$FILE_PATH" | grep -q '\.claude/'; then
  SKIP=true
fi

# Skip memory files
if echo "$FILE_PATH" | grep -q '/memory/'; then
  SKIP=true
fi

# Skip changelog/reports (these ARE the documentation of issue work)
if echo "$FILE_PATH" | grep -q 'changelog/'; then
  SKIP=true
fi

# Skip plan files
if echo "$FILE_PATH" | grep -q '\.claude/plans/'; then
  SKIP=true
fi

if [ "$SKIP" = true ]; then
  exit 0
fi

# Check for state file
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
STATE_FILE="${PROJECT_DIR}/.claude/.current_issue"

if [ -f "$STATE_FILE" ]; then
  # Issue already associated — allow edit
  exit 0
fi

# No issue found — return reminder (non-blocking)
MSG="[IC_R009] No GitHub Issue associated with this session yet. Before modifying code, please:
1. Create a GitHub Issue: gh issue create --repo kiki830621/ai_martech_global_scripts --title \"...\" --label \"...\"
2. Write the issue number to the state file: echo \"#NNN\" > ${STATE_FILE}
Or if an existing issue applies, just write its number to the state file.
This ensures bidirectional traceability (IC_R009): every commit references an issue."

jq -n --arg msg "$MSG" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $msg
  }
}'
