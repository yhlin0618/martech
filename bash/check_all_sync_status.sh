#!/bin/bash

##############################################################################
# Global Scripts Sync Status Checker
##############################################################################
# Purpose: Check synchronization status of all app instances
# Usage: Run manually to audit sync state across all apps
# Author: Principle-Explorer
# Date: 2025-10-03
# Per: MP001_axiomatization_system
##############################################################################

# Configuration
MARTECH_ROOT="/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

##############################################################################
# START
##############################################################################

echo -e "${BLUE}=== Global Scripts Sync Status ===${NC}"
echo -e "Date: $(date)"
echo -e "Master: $MARTECH_ROOT/global_scripts"
echo ""

# Get master commit
cd "$MARTECH_ROOT/global_scripts"
MASTER_COMMIT=$(git rev-parse HEAD)
MASTER_SHORT=${MASTER_COMMIT:0:8}

echo -e "${GREEN}Master Repository:${NC}"
echo -e "  Commit: $MASTER_SHORT"
echo -e "  Branch: $(git branch --show-current)"
echo ""

# Function to auto-detect all companies across all tiers
find_all_companies() {
    local companies=()

    # Find all directories with .gitrepo files
    while IFS= read -r gitrepo_path; do
        # Extract tier/company path relative to MARTECH_ROOT
        local relative_path=$(echo "$gitrepo_path" | sed "s|$MARTECH_ROOT/||" | sed 's|/scripts/global_scripts/.gitrepo||')
        companies+=("$relative_path")
    done < <(find "$MARTECH_ROOT" -path "*/scripts/global_scripts/.gitrepo" -type f 2>/dev/null | grep -v "/archive/" | grep -v "/template/")

    echo "${companies[@]}"
}

# Auto-detect all companies
echo -e "${YELLOW}Auto-detecting companies with subrepos...${NC}"
APPS=($(find_all_companies))
echo -e "${GREEN}✓ Found ${#APPS[@]} companies${NC}"
echo -e "${GREEN}  (VitalSigns, MAMBA, WISER, kitchenMAMA, InsightForge, etc.)${NC}"
echo ""

# Group apps by tier for better readability
echo -e "${GREEN}Application Status (by tier):${NC}"
echo ""

# Counters
SYNCED=0
OUT_OF_SYNC=0
NO_SUBREPO=0
ERROR=0

# Track current tier for grouping
CURRENT_TIER=""

# Check each app
for app in "${APPS[@]}"; do
    # Extract tier from path
    TIER=$(echo "$app" | cut -d'/' -f1)

    # Print tier header if changed
    if [ "$TIER" != "$CURRENT_TIER" ]; then
        if [ -n "$CURRENT_TIER" ]; then
            echo ""
        fi
        echo -e "${BLUE}Tier: $TIER${NC}"
        CURRENT_TIER="$TIER"
    fi
    APP_PATH="$MARTECH_ROOT/$app"

    # Check directory exists
    if [ ! -d "$APP_PATH" ]; then
        printf "%-60s ${RED}✗ DIRECTORY NOT FOUND${NC}\n" "$app"
        ERROR=$((ERROR + 1))
        continue
    fi

    cd "$APP_PATH"

    # Check git repo exists
    if [ ! -d .git ]; then
        printf "%-60s ${RED}✗ NOT A GIT REPO${NC}\n" "$app"
        NO_SUBREPO=$((NO_SUBREPO + 1))
        continue
    fi

    # Check subrepo exists
    if [ ! -f scripts/global_scripts/.gitrepo ]; then
        printf "%-60s ${RED}✗ NO SUBREPO${NC}\n" "$app"
        NO_SUBREPO=$((NO_SUBREPO + 1))
        continue
    fi

    # Get subrepo commit
    SUBREPO_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}')
    SUBREPO_SHORT=${SUBREPO_COMMIT:0:8}

    # Compare commits
    if [ "$SUBREPO_COMMIT" == "$MASTER_COMMIT" ]; then
        printf "%-60s ${GREEN}✓ SYNCED${NC} ($SUBREPO_SHORT)\n" "$app"
        SYNCED=$((SYNCED + 1))
    else
        printf "%-60s ${YELLOW}⚠ OUT OF SYNC${NC} ($SUBREPO_SHORT ≠ $MASTER_SHORT)\n" "$app"
        OUT_OF_SYNC=$((OUT_OF_SYNC + 1))
    fi
done

##############################################################################
# Summary
##############################################################################

echo ""
echo -e "${BLUE}=== Summary ===${NC}"
echo ""

TOTAL=${#APPS[@]}

echo -e "  Total applications: $TOTAL"
echo -e "  ${GREEN}✓ Synced:          $SYNCED${NC}"
echo -e "  ${YELLOW}⚠ Out of sync:     $OUT_OF_SYNC${NC}"
echo -e "  ${RED}✗ No subrepo:      $NO_SUBREPO${NC}"
echo -e "  ${RED}✗ Errors:          $ERROR${NC}"

echo ""

# Recommendations
if [ $OUT_OF_SYNC -gt 0 ]; then
    echo -e "${YELLOW}Recommendation:${NC} Run sync_all_global_scripts.sh to update out-of-sync apps"
    echo ""
fi

# Exit code
if [ $OUT_OF_SYNC -eq 0 ] && [ $ERROR -eq 0 ]; then
    echo -e "${GREEN}All apps are in sync!${NC}"
    exit 0
else
    exit 1
fi
