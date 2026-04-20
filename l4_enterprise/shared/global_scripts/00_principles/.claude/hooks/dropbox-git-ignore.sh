#!/bin/bash
# Dropbox Git Ignore Hook
# Ensures .git directories are excluded from Dropbox sync
# Prevents .git/index corruption caused by Dropbox overwriting git internals
#
# Trigger: SessionStart (runs at the beginning of every Claude Code session)
# Context: Shared via global_scripts subrepo, applies to all company projects
#
# See: changelog/reports/2026-02-11_dropbox_git_index_corruption_incident.md

set -e

# Get project root from hook input or git
if command -v jq &>/dev/null; then
  PROJECT_DIR=$(jq -r '.cwd // empty' 2>/dev/null < /dev/stdin || true)
fi
if [ -z "$PROJECT_DIR" ]; then
  PROJECT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
fi

# Check if project is inside a Dropbox directory
if [[ "$PROJECT_DIR" != *"Dropbox"* && "$PROJECT_DIR" != *"CloudStorage"* ]]; then
  exit 0
fi

# Find and protect all .git directories
fixed=0
already=0

while IFS= read -r gitdir; do
  current=$(xattr -p com.dropbox.ignored "$gitdir" 2>/dev/null || echo "")
  if [ "$current" = "1" ]; then
    already=$((already + 1))
  else
    xattr -w com.dropbox.ignored 1 "$gitdir" 2>/dev/null && fixed=$((fixed + 1))
  fi
done < <(find "$PROJECT_DIR" -name ".git" -type d -maxdepth 5 2>/dev/null)

# Report results (stdout becomes Claude context for SessionStart hooks)
if [ "$fixed" -gt 0 ]; then
  echo "Dropbox protection: excluded $fixed .git directories from sync ($already already protected)"
elif [ "$already" -gt 0 ]; then
  # Silent when everything is already protected
  exit 0
fi

exit 0
