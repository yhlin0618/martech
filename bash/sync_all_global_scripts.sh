#!/bin/bash

##############################################################################
# Global Scripts Synchronization Script
##############################################################################
# Purpose: Sync all application instances with master global_scripts
# Schedule: Run weekly (Monday mornings) or manually as needed
# Author: Principle-Explorer
# Date: 2025-10-03
# Per: MP001_axiomatization_system, MP030_archive_immutability
##############################################################################

set -e  # Exit on error

# Configuration
MARTECH_ROOT="/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech"
LOG_FILE="$MARTECH_ROOT/bash/logs/sync_global_scripts_$(date +%Y%m%d_%H%M%S).log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create log directory if needed
mkdir -p "$MARTECH_ROOT/bash/logs"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handler
error_handler() {
    log "❌ ERROR: Script failed at line $1"
    exit 1
}

trap 'error_handler $LINENO' ERR

##############################################################################
# START
##############################################################################

echo -e "${GREEN}=== Global Scripts Synchronization ===${NC}"
log "=== Global Scripts Synchronization ==="
log "Date: $(date)"
log "User: $(whoami)"
log "Script: $0"

##############################################################################
# Step 1: Update master global_scripts from GitHub
##############################################################################

echo ""
echo -e "${YELLOW}Step 1: Updating master global_scripts from GitHub...${NC}"
log "Step 1: Updating master global_scripts from GitHub"

cd "$MARTECH_ROOT/global_scripts"

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    log "⚠️  WARNING: Uncommitted changes in master global_scripts"
    echo -e "${RED}WARNING: Uncommitted changes detected in master global_scripts${NC}"
    echo "Please commit or stash changes before syncing."
    exit 1
fi

# Pull latest changes
log "Pulling from origin main..."
git pull origin main

MASTER_COMMIT=$(git rev-parse HEAD)
log "Master global_scripts now at commit: $MASTER_COMMIT"
echo -e "${GREEN}✓ Master updated to commit: ${MASTER_COMMIT:0:8}${NC}"

##############################################################################
# Step 2: Auto-detect all applications with subrepos
##############################################################################

echo ""
echo -e "${YELLOW}Step 2: Auto-detecting applications with subrepos...${NC}"
log "Step 2: Auto-detecting applications with subrepos"

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
log "Scanning for companies with subrepo configurations..."
APPS=($(find_all_companies))

log "Auto-detected ${#APPS[@]} companies across all tiers:"
for app in "${APPS[@]}"; do
    log "  - $app"
done

echo -e "${GREEN}✓ ${#APPS[@]} companies auto-detected${NC}"
echo -e "${GREEN}  (VitalSigns, MAMBA, WISER, kitchenMAMA, InsightForge, etc.)${NC}"

##############################################################################
# Step 3: Sync each application
##############################################################################

echo ""
echo -e "${YELLOW}Step 3: Syncing applications...${NC}"
log "Step 3: Syncing applications"

SUCCESS_COUNT=0
SKIP_COUNT=0
FAIL_COUNT=0

for app in "${APPS[@]}"; do
    echo ""
    echo -e "${YELLOW}Processing: $app${NC}"
    log "Processing: $app"

    APP_PATH="$MARTECH_ROOT/$app"

    # Check if app directory exists
    if [ ! -d "$APP_PATH" ]; then
        log "⚠️  SKIP: Directory does not exist: $APP_PATH"
        echo -e "${RED}✗ Directory not found${NC}"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    cd "$APP_PATH"

    # Check if app has git repository
    if [ ! -d .git ]; then
        log "⚠️  SKIP: Not a git repository: $app"
        echo -e "${RED}✗ Not a git repository${NC}"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    # Check if subrepo exists
    if [ ! -f scripts/global_scripts/.gitrepo ]; then
        log "⚠️  SKIP: No .gitrepo file found: $app"
        echo -e "${RED}✗ No subrepo configuration${NC}"
        SKIP_COUNT=$((SKIP_COUNT + 1))
        continue
    fi

    # Get current subrepo commit
    CURRENT_COMMIT=$(grep "commit =" scripts/global_scripts/.gitrepo | awk '{print $3}')
    log "Current subrepo commit: $CURRENT_COMMIT"

    # Check if already up to date
    if [ "$CURRENT_COMMIT" == "$MASTER_COMMIT" ]; then
        log "✓ Already up to date: $app"
        echo -e "${GREEN}✓ Already synced (${CURRENT_COMMIT:0:8})${NC}"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        continue
    fi

    # Pull subrepo updates
    log "Pulling subrepo updates..."
    if git subrepo pull scripts/global_scripts; then
        log "✓ Subrepo pulled successfully"

        # Commit the sync
        COMMIT_MSG="Weekly sync: global_scripts $(date +%Y-%m-%d)

Updated global_scripts from ${CURRENT_COMMIT:0:8} to ${MASTER_COMMIT:0:8}

Per MP001_axiomatization_system"

        if git commit -m "$COMMIT_MSG" 2>/dev/null; then
            log "✓ Sync committed"

            # Push to app's GitHub repo
            if git push origin main 2>/dev/null; then
                log "✓ Pushed to GitHub: $app"
                echo -e "${GREEN}✓ Synced and pushed (${CURRENT_COMMIT:0:8} → ${MASTER_COMMIT:0:8})${NC}"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            else
                log "⚠️  WARNING: Could not push to GitHub: $app"
                echo -e "${YELLOW}⚠ Synced locally but push failed${NC}"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            fi
        else
            log "ℹ No changes to commit (already synced): $app"
            echo -e "${GREEN}✓ Already synced (no changes)${NC}"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    else
        log "❌ FAILED: Could not pull subrepo: $app"
        echo -e "${RED}✗ Subrepo pull failed${NC}"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi
done

##############################################################################
# Step 4: Summary
##############################################################################

echo ""
echo -e "${GREEN}=== Synchronization Complete ===${NC}"
log "=== Synchronization Complete ==="
log "Success: $SUCCESS_COUNT"
log "Skipped: $SKIP_COUNT"
log "Failed: $FAIL_COUNT"
log "Total: ${#APPS[@]}"

echo ""
echo -e "Summary:"
echo -e "  ${GREEN}✓ Success: $SUCCESS_COUNT${NC}"
echo -e "  ${YELLOW}⊘ Skipped: $SKIP_COUNT${NC}"
echo -e "  ${RED}✗ Failed: $FAIL_COUNT${NC}"
echo -e "  Total: ${#APPS[@]}"

echo ""
echo -e "Log file: ${LOG_FILE}"
echo ""

# Exit with error if any failures
if [ $FAIL_COUNT -gt 0 ]; then
    log "Exiting with error code 1 due to failures"
    exit 1
fi

log "Script completed successfully"
exit 0
