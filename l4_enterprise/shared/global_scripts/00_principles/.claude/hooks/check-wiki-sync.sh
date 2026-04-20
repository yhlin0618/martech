#!/bin/bash
# DOC_R006 Wiki Synchronization Trigger Hook
# Triggered after Edit/Write on wiki-sensitive files
#
# When a dashboard component, formula function, or terminology file is modified,
# this hook reminds Claude to update the corresponding Wiki pages.
#
# Wiki is the customer-facing documentation that explains what the dashboard does.
# If the dashboard changes but the Wiki doesn't, clients get confused.
#
# Related: DOC_R006 (Wiki Synchronization Trigger)

set -e

INPUT=$(cat /dev/stdin)

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Skip if no file_path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# --- Wiki-sensitive path detection ---

WIKI_PAGES=""
REASON=""

# 1. TagPilot components → TagPilot.md
if echo "$FILE_PATH" | grep -q '10_rshinyapp_components/tagpilot/'; then
  WIKI_PAGES="TagPilot.md"
  REASON="TagPilot dashboard component modified"
fi

# 2. VitalSigns components → VitalSigns.md
if echo "$FILE_PATH" | grep -q '10_rshinyapp_components/vitalsigns/'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }VitalSigns.md"
  REASON="${REASON:+$REASON; }VitalSigns dashboard component modified"
fi

# 3. BrandEdge components (directory: position/) → BrandEdge.md
if echo "$FILE_PATH" | grep -q '10_rshinyapp_components/position/'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }BrandEdge.md"
  REASON="${REASON:+$REASON; }BrandEdge dashboard component modified"
fi

# 4. InsightForge components (directory: poisson/) → InsightForge.md
if echo "$FILE_PATH" | grep -q '10_rshinyapp_components/poisson/'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }InsightForge.md"
  REASON="${REASON:+$REASON; }InsightForge dashboard component modified"
fi

# 5. ReportCenter components (directory: report/) → ReportCenter.md
if echo "$FILE_PATH" | grep -q '10_rshinyapp_components/report/'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }ReportCenter.md"
  REASON="${REASON:+$REASON; }ReportCenter dashboard component modified"
fi

# 6. DNA analysis functions → Term-RFM, Term-NES, Term-CAI, Term-PCV, Term-CRI, Term-CLV, Term-IPT
if echo "$FILE_PATH" | grep -q '04_utils/fn_analysis_dna\.R'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }Term-RFM.md, Term-NES.md, Term-CAI.md, Term-PCV.md, Term-CRI.md, Term-CLV.md, Term-IPT.md, Glossary.md"
  REASON="${REASON:+$REASON; }DNA formula file modified — check if formulas in Wiki still match"
fi

# 7. BTYD analysis functions → Term-P-alive
if echo "$FILE_PATH" | grep -q '04_utils/fn_analysis_btyd\.R'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }Term-P-alive.md, Glossary.md"
  REASON="${REASON:+$REASON; }BTYD formula file modified — check P(alive) formula in Wiki"
fi

# 8. RSV classification → Term-RSV
if echo "$FILE_PATH" | grep -q 'fn_rsv_classification\.R'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }Term-RSV.md, Glossary.md"
  REASON="${REASON:+$REASON; }RSV classification logic modified"
fi

# 9. DRV D01 core (DNA segments) → Term-RFM
if echo "$FILE_PATH" | grep -q 'fn_D01_02_core\.R'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }Term-RFM.md"
  REASON="${REASON:+$REASON; }DNA segment derivation modified"
fi

# 10. Marketing strategies → Term-Marketing-Strategies
if echo "$FILE_PATH" | grep -q 'marketing_strategies\.yaml'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }Term-Marketing-Strategies.md"
  REASON="${REASON:+$REASON; }Marketing strategies config modified"
fi

# 11. UI terminology → Glossary
if echo "$FILE_PATH" | grep -q 'ui_terminology\.csv'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }Glossary.md"
  REASON="${REASON:+$REASON; }UI terminology changed — check if new terms need Wiki pages"
fi

# 12. Union production (main app assembly) → Home.md, _Sidebar.md
if echo "$FILE_PATH" | grep -q 'unions/union_production'; then
  WIKI_PAGES="${WIKI_PAGES:+$WIKI_PAGES, }Home.md, _Sidebar.md"
  REASON="${REASON:+$REASON; }Main app assembly modified — check if module list changed"
fi

# --- Output reminder if any wiki-sensitive path matched ---

if [ -n "$WIKI_PAGES" ]; then
  MSG="[DOC_R006 Wiki Sync] ${REASON}. Potentially affected Wiki pages: ${WIKI_PAGES}. Wiki location: 00_principles/docs/wiki/. Remember to update Wiki if dashboard behavior, formulas, or visible UI changed."

  jq -n --arg msg "$MSG" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $msg
    }
  }'
else
  exit 0
fi
