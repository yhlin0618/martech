#!/bin/bash
# DM_R023 tbl2 Compliance Advisory Hook
# Triggered as PreToolUse on Edit/Write invocations
#
# Detects raw SQL read patterns and dbGetQuerySafe usage in .R files and
# emits an advisory message pointing to tbl2() + dplyr as the replacement.
#
# This hook is NON-BLOCKING — it only surfaces guidance, never aborts.
# Related:
#   DM_R023 v1.2 (Universal DBI Approach Rule)
#   Issue #369 (unify-cross-driver-query-layer)
#   Issue #365 (MAMBA Posit Connect PostgreSQL failure)

set -e

INPUT=$(cat /dev/stdin)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only inspect writes to .R files
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

case "$FILE_PATH" in
  *.R|*.r) : ;;
  *) exit 0 ;;
esac

# Skip the transitional wrapper file itself (it is allowed to reference
# dbGetQuery) and archive locations.
case "$FILE_PATH" in
  *fn_db_get_query_safe.R) exit 0 ;;
  */99_archive/*) exit 0 ;;
  */02_db_utils/tbl2/test_*.R) exit 0 ;;  # test files that intentionally show patterns
esac

# Extract content being written depending on the tool
CONTENT=""
if [ "$TOOL_NAME" = "Write" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
elif [ "$TOOL_NAME" = "Edit" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
elif [ "$TOOL_NAME" = "MultiEdit" ]; then
  CONTENT=$(echo "$INPUT" | jq -r '[.tool_input.edits[].new_string] | join("\n")')
fi

if [ -z "$CONTENT" ]; then
  exit 0
fi

MSG=""

# --- Check 1: dbGetQuery with SELECT (raw SQL read — forbidden by DM_R023) ---
if echo "$CONTENT" | grep -qE 'DBI::dbGetQuery\([^)]*SELECT|dbGetQuery\([^)]*SELECT'; then
  MSG="[DM_R023 tbl2 compliance] 偵測到 raw SQL SELECT via dbGetQuery() 在 ${FILE_PATH}. 請改用 tbl2(): 例如 tbl2(con, 'table') %>% filter(...) %>% collect(). 詳見 00_principles/docs/en/part1_principles/CH02_data_management/rules/DM_R023_universal_dbi_approach.qmd"
fi

# --- Check 2: ? positional placeholder with params = list ---
# This is the exact pattern that broke MAMBA #365 on PostgreSQL.
if echo "$CONTENT" | grep -qE 'dbGetQuery\([^)]*\?.*params\s*=\s*list'; then
  if [ -n "$MSG" ]; then
    MSG="${MSG} "
  fi
  MSG="${MSG}[CRITICAL] 偵測到 ? positional placeholder + params=list() pattern. 這在 PostgreSQL 上會觸發 syntax error(MAMBA #365 根因). 改用 tbl2() + dplyr filter(),由 dbplyr 自動處理跨 driver 翻譯."
fi

# --- Check 3: dbGetQuerySafe usage (deprecated 2026-04-13) ---
if echo "$CONTENT" | grep -qE 'dbGetQuerySafe\('; then
  if [ -n "$MSG" ]; then
    MSG="${MSG} "
  fi
  MSG="${MSG}[Deprecated] dbGetQuerySafe() 已於 2026-04-13 標記 deprecated(目標移除 2026-07-13). 請改用 tbl2() %>% filter() %>% collect(). 見 DM_R023 Section 6.3."
fi

# --- Output advisory if any check triggered (non-blocking) ---
if [ -n "$MSG" ]; then
  jq -n --arg msg "$MSG" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      additionalContext: $msg
    }
  }'
else
  exit 0
fi
