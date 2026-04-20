#!/bin/bash
# DOC_R009 Principle Triple-Layer Synchronization Hook
# Triggered after Edit/Write on principle-related files
#
# Detects modifications to ANY of the three principle layers and reminds
# about updating the other two:
#   Layer 1: .qmd (source of truth) — docs/en/part1_principles/
#   Layer 2: llm/*.yaml (AI-optimized index)
#   Layer 3: .claude/rules/*.md (auto-loaded quick reference)
#
# This hook REPLACES the old sync-llm-reminder.sh (which only covered L1→L2).
#
# Related: DOC_R009 (Principle Triple-Layer Synchronization)

set -e

INPUT=$(cat /dev/stdin)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file_path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- Helper: map chapter directory to llm/ YAML filename ---
get_llm_yaml() {
  local path="$1"
  if echo "$path" | grep -q "CH00_fundamental\|CH00_meta"; then
    echo "CH00_meta.yaml"
  elif echo "$path" | grep -q "CH01_structure"; then
    echo "CH01_structure.yaml"
  elif echo "$path" | grep -q "CH02_data"; then
    echo "CH02_data.yaml"
  elif echo "$path" | grep -q "CH03_development"; then
    echo "CH03_development.yaml"
  elif echo "$path" | grep -q "CH04_ui"; then
    echo "CH04_ui.yaml"
  elif echo "$path" | grep -q "CH05_testing"; then
    echo "CH05_testing.yaml"
  elif echo "$path" | grep -q "CH06_"; then
    echo "CH06_ic.yaml"
  elif echo "$path" | grep -q "CH07_"; then
    echo ""  # CH07_security/ — no dedicated security yaml
  elif echo "$path" | grep -q "CH08_"; then
    echo "CH07_ux.yaml"  # CH08_user_experience/ → UX principles
  elif echo "$path" | grep -q "CH09_"; then
    echo "CH11_etl.yaml"  # CH09_etl_pipelines/ → ETL principles
  elif echo "$path" | grep -q "CH10_"; then
    echo "CH08_data_presentation.yaml"  # CH10_data_presentation/ → DP principles
  elif echo "$path" | grep -q "CH11_"; then
    echo "CH11_etl.yaml"
  elif echo "$path" | grep -q "CH12_"; then
    echo "CH12_derivations.yaml"
  elif echo "$path" | grep -q "CH13_"; then
    echo "CH13_modules.yaml"
  elif echo "$path" | grep -q "CH14_"; then
    echo "CH14_functions.yaml"
  elif echo "$path" | grep -q "CH15_"; then
    echo "CH15_apis.yaml"
  elif echo "$path" | grep -q "CH16_"; then
    echo "CH16_connections.yaml"
  elif echo "$path" | grep -q "CH17_"; then
    echo "CH17_templates.yaml"
  elif echo "$path" | grep -q "CH18_"; then
    echo "CH18_solutions.yaml"
  elif echo "$path" | grep -q "CH19_"; then
    echo "CH19_documentation.yaml"
  fi
}

# --- Helper: map chapter to likely .claude/rules/*.md file ---
get_rules_md() {
  local path="$1"
  if echo "$path" | grep -q "CH00_fundamental\|CH00_meta"; then
    echo "01-always.md"
  elif echo "$path" | grep -q "CH01_structure"; then
    echo "07-directory-governance.md"
  elif echo "$path" | grep -q "CH02_data"; then
    echo "02-coding.md or 03-data-queries.md"
  elif echo "$path" | grep -q "CH03_development"; then
    echo "02-coding.md"
  elif echo "$path" | grep -q "CH04_ui"; then
    echo "10-ui-layout.md"
  elif echo "$path" | grep -q "CH05_testing"; then
    echo "08-shiny-testing.md and 06-running-app.md"
  elif echo "$path" | grep -q "CH06_"; then
    echo "01-always.md"
  elif echo "$path" | grep -q "CH07_"; then
    echo ""  # CH07_security/ — no dedicated security rules file
  elif echo "$path" | grep -q "CH08_"; then
    echo "10-ui-layout.md"  # CH08_user_experience/ → UX rules
  elif echo "$path" | grep -q "CH09_"; then
    echo "04-pipeline.md"  # CH09_etl_pipelines/ → pipeline rules
  elif echo "$path" | grep -q "CH10_"; then
    echo "01-always.md"  # CH10_data_presentation/ → DP rules (MP153, DP_R001, DP_R002)
  elif echo "$path" | grep -q "CH11_\|CH12_"; then
    echo "04-pipeline.md"
  elif echo "$path" | grep -q "CH13_\|CH14_"; then
    echo "02-coding.md"
  elif echo "$path" | grep -q "CH15_"; then
    echo "09-openai-integration.md"
  elif echo "$path" | grep -q "CH16_\|CH17_\|CH18_"; then
    echo "02-coding.md"
  elif echo "$path" | grep -q "CH19_"; then
    echo "05-documentation.md"
  fi
}

MSG=""

# ============================================================
# Case 1: .qmd principle file modified (Layer 1 — source of truth)
# → Remind to update Layer 2 (llm/*.yaml) and Layer 3 (.claude/rules/*.md)
# ============================================================
if echo "$FILE_PATH" | grep -q '00_principles/docs/.*part1_principles.*\.qmd$'; then
  BASENAME=$(basename "$FILE_PATH" .qmd)
  PRINCIPLE_ID=$(echo "$BASENAME" | grep -oE '^[A-Z_]+[0-9]+' || echo "")

  LLM_YAML=$(get_llm_yaml "$FILE_PATH")
  RULES_MD=$(get_rules_md "$FILE_PATH")

  MSG="[DOC_R009 三層同步] Layer 1 (.qmd) 已修改: ${BASENAME}.qmd"
  if [ -n "$PRINCIPLE_ID" ]; then
    MSG="${MSG} (${PRINCIPLE_ID})"
  fi
  MSG="${MSG}. 請確認同步更新:"
  if [ -n "$LLM_YAML" ]; then
    MSG="${MSG} Layer 2: llm/${LLM_YAML}"
  else
    MSG="${MSG} Layer 2: 對應的 llm/*.yaml"
  fi
  if [ -n "$RULES_MD" ]; then
    MSG="${MSG} + Layer 3: .claude/rules/${RULES_MD}"
  else
    MSG="${MSG} + Layer 3: 對應的 .claude/rules/*.md"
  fi
  MSG="${MSG}. 順序: .qmd → llm/ → rules/ (不可顛倒)"

# ============================================================
# Case 2: llm/*.yaml modified (Layer 2)
# → Remind to verify Layer 1 (.qmd) is the source, and update Layer 3
# ============================================================
elif echo "$FILE_PATH" | grep -q '00_principles/llm/CH[0-9].*\.yaml$'; then
  YAML_NAME=$(basename "$FILE_PATH")

  MSG="[DOC_R009 三層同步] Layer 2 (llm/) 已修改: ${YAML_NAME}."
  MSG="${MSG} 請確認: (1) Layer 1 (.qmd) 已先更新（.qmd 是權威來源）"
  MSG="${MSG} (2) Layer 3 (.claude/rules/*.md) 也需同步更新"
  MSG="${MSG} (3) principle_count 和 hierarchy 區塊已正確更新"

# ============================================================
# Case 3: .claude/rules/*.md modified (Layer 3)
# → Remind to verify Layer 1 and Layer 2 are already updated
# ============================================================
elif echo "$FILE_PATH" | grep -q '00_principles/\.claude/rules/.*\.md$'; then
  RULES_NAME=$(basename "$FILE_PATH")

  MSG="[DOC_R009 三層同步] Layer 3 (.claude/rules/) 已修改: ${RULES_NAME}."
  MSG="${MSG} 請確認 Layer 1 (.qmd 權威來源) 和 Layer 2 (llm/*.yaml) 已先更新。"
  MSG="${MSG} 如果這是新原則的最後一步，三層同步已完成。"

fi

# --- Output reminder if any principle-related path matched ---
if [ -n "$MSG" ]; then
  jq -n --arg msg "$MSG" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $msg
    }
  }'
else
  exit 0
fi
