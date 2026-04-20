#!/bin/bash
# Plan-to-Report Lifecycle Hook
# Triggered automatically on ExitPlanMode
#
# This script archives plan mode outputs to changelog/reports/ for:
# - Git tracking and version control
# - ADR (Architecture Decision Record) preservation
# - Team knowledge sharing
#
# Usage:
#   Automatic: PostToolUse hook on ExitPlanMode
#   Manual:    bash .claude/hooks/archive-plan.sh [plan_file_path]

set -e

# Configuration
REPORT_DIR="scripts/global_scripts/00_principles/changelog/reports"
PLAN_SOURCE_DIR="$HOME/.claude/plans"

# Find the plan file
if [ -n "$1" ]; then
    PLAN_FILE="$1"
elif [ -n "$CLAUDE_PLAN_FILE" ]; then
    PLAN_FILE="$CLAUDE_PLAN_FILE"
else
    # Find the most recently modified plan file
    PLAN_FILE=$(find "$PLAN_SOURCE_DIR" -name "*.md" -type f 2>/dev/null | head -1)
fi

# Validate plan file exists
if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
    echo "No plan file found to archive"
    exit 0
fi

# Check for NO_ARCHIVE flag
if grep -q "<!-- NO_ARCHIVE -->" "$PLAN_FILE" 2>/dev/null; then
    echo "Plan marked as NO_ARCHIVE, skipping..."
    exit 0
fi

# Check if reports directory exists (we're in project root)
if [ ! -d "$REPORT_DIR" ]; then
    # Try from current working directory or project root
    PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    REPORT_DIR="$PROJECT_ROOT/scripts/global_scripts/00_principles/changelog/reports"

    if [ ! -d "$REPORT_DIR" ]; then
        echo "Warning: Reports directory not found: $REPORT_DIR"
        echo "Attempting to create..."
        mkdir -p "$REPORT_DIR" || exit 1
    fi
fi

# Extract title from first H1 (remove "# " and "Plan: " prefixes)
TITLE=$(grep -m1 "^# " "$PLAN_FILE" | sed 's/^# //' | sed 's/^Plan: //')

if [ -z "$TITLE" ]; then
    TITLE="untitled_plan"
fi

# Convert to snake_case topic
# - Convert to lowercase
# - Replace spaces with underscores
# - Remove non-alphanumeric characters except underscores
TOPIC=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_')

# Truncate if too long
TOPIC=$(echo "$TOPIC" | cut -c1-60)

# Generate filename with PLAN_ prefix
DATE=$(date +%Y-%m-%d)
REPORT_FILE="${REPORT_DIR}/${DATE}_PLAN_${TOPIC}.md"

# Avoid overwriting existing files
COUNTER=1
while [ -f "$REPORT_FILE" ]; do
    REPORT_FILE="${REPORT_DIR}/${DATE}_PLAN_${TOPIC}_${COUNTER}.md"
    COUNTER=$((COUNTER + 1))
done

# Copy plan to reports with metadata header
{
    echo "---"
    echo "archived_from: claude_plan_mode"
    echo "archived_at: $(date -Iseconds)"
    echo "status: planned"
    echo "original_file: $(basename "$PLAN_FILE")"
    echo "---"
    echo ""
    cat "$PLAN_FILE"
} > "$REPORT_FILE"

echo "Plan archived to: $REPORT_FILE"
