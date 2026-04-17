#!/bin/bash
# Principle-to-LLM Sync Reminder Hook
# Triggered after Edit/Write on principle .qmd files
#
# When a principle file under 00_principles/docs/ is modified,
# this hook reminds Claude to also update the corresponding llm/ YAML entry.
#
# Related: MP151 (No-Fallback), MP146 (Canonical Variable Naming)

set -e

INPUT=$(cat /dev/stdin)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file_path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only trigger for .qmd files under 00_principles/docs/
if echo "$FILE_PATH" | grep -q '00_principles/docs/.*\.qmd$'; then
  # Extract principle ID from filename (e.g., MP151_no_fallback_principle.qmd -> MP151)
  BASENAME=$(basename "$FILE_PATH" .qmd)
  PRINCIPLE_ID=$(echo "$BASENAME" | grep -oE '^[A-Z_]+[0-9]+' || echo "")

  # Determine which chapter YAML to update based on path
  CHAPTER=""
  if echo "$FILE_PATH" | grep -q "CH00_fundamental"; then
    CHAPTER="CH00_meta.yaml"
  elif echo "$FILE_PATH" | grep -q "CH01_structure"; then
    CHAPTER="CH01_structure.yaml"
  elif echo "$FILE_PATH" | grep -q "CH02_data"; then
    CHAPTER="CH02_data.yaml"
  elif echo "$FILE_PATH" | grep -q "CH03_development"; then
    CHAPTER="CH03_development.yaml"
  elif echo "$FILE_PATH" | grep -q "CH04_ui"; then
    CHAPTER="CH04_ui.yaml"
  elif echo "$FILE_PATH" | grep -q "CH05_testing"; then
    CHAPTER="CH05_testing.yaml"
  elif echo "$FILE_PATH" | grep -q "CH06_"; then
    CHAPTER="CH06_ic.yaml"
  elif echo "$FILE_PATH" | grep -q "CH09_"; then
    CHAPTER="CH09_database.yaml"
  fi

  MSG="Principle file modified: ${BASENAME}.qmd"
  if [ -n "$PRINCIPLE_ID" ]; then
    MSG="${MSG} (${PRINCIPLE_ID})"
  fi
  if [ -n "$CHAPTER" ]; then
    MSG="${MSG}. Check if llm/${CHAPTER} needs a corresponding update."
  else
    MSG="${MSG}. Check if the llm/ YAML system needs a corresponding update."
  fi

  # Output reminder as additionalContext (non-blocking)
  jq -n --arg msg "$MSG" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $msg
    }
  }'
else
  exit 0
fi
