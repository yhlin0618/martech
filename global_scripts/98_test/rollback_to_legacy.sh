#!/bin/bash
# rollback_to_legacy.sh
#
# Emergency rollback script for MAMBA ETL+DRV migration
# Reverts to legacy D04 system if critical issues detected
#
# ⚠️ CRITICAL NOTE: Legacy D04 precision marketing was BROKEN
# This script documents the rollback procedure, but there is NO functional legacy to rollback to
# for precision marketing features. Rollback would mean DISABLING precision marketing temporarily.
#
# Usage:
#   ./rollback_to_legacy.sh --check    # Check rollback readiness (dry run)
#   ./rollback_to_legacy.sh --execute  # Execute rollback (requires confirmation)
#   ./rollback_to_legacy.sh --status   # Check current system status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Paths
NEW_DB_DIR="$PROJECT_ROOT/data"
BACKUP_DIR="$PROJECT_ROOT/backup_before_rollback_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$PROJECT_ROOT/rollback_$(date +%Y%m%d_%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Check if running in dry-run mode
DRY_RUN=false
if [ "$1" == "--check" ]; then
    DRY_RUN=true
    log "=== ROLLBACK DRY RUN MODE ==="
else
    log "=== ROLLBACK EXECUTION MODE ==="
fi

# Check current system status
check_system_status() {
    log "Checking current system status..."

    # Check new databases exist
    NEW_DBS=(
        "$NEW_DB_DIR/raw_data.duckdb"
        "$NEW_DB_DIR/staged_data.duckdb"
        "$NEW_DB_DIR/transformed_data.duckdb"
        "$NEW_DB_DIR/processed_data.duckdb"
    )

    NEW_DB_COUNT=0
    for db in "${NEW_DBS[@]}"; do
        if [ -f "$db" ]; then
            NEW_DB_COUNT=$((NEW_DB_COUNT + 1))
            SIZE=$(du -h "$db" | cut -f1)
            log "  Found: $(basename $db) ($SIZE)"
        fi
    done

    log "New system databases: $NEW_DB_COUNT/4"

    # Check legacy database
    LEGACY_DB="$NEW_DB_DIR/data.duckdb"
    if [ -f "$LEGACY_DB" ]; then
        SIZE=$(du -h "$LEGACY_DB" | cut -f1)
        log "  Found legacy: data.duckdb ($SIZE)"
    else
        warning "Legacy database not found at $LEGACY_DB"
    fi

    # Check if we're actually running new system
    if [ -f "$NEW_DB_DIR/processed_data.duckdb" ]; then
        log "Current state: NEW SYSTEM (MAMBA ETL+DRV)"
    elif [ -f "$LEGACY_DB" ]; then
        log "Current state: LEGACY SYSTEM (D04)"
    else
        error "Cannot determine current system state"
        return 1
    fi

    return 0
}

# Create backup before rollback
create_backup() {
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Would create backup at: $BACKUP_DIR"
        return 0
    fi

    log "Creating backup before rollback..."

    mkdir -p "$BACKUP_DIR"

    # Backup new system databases
    for db in "${NEW_DBS[@]}"; do
        if [ -f "$db" ]; then
            log "  Backing up: $(basename $db)"
            cp "$db" "$BACKUP_DIR/"
        fi
    done

    # Backup validation results
    if [ -d "$PROJECT_ROOT/validation" ]; then
        log "  Backing up validation results"
        cp -r "$PROJECT_ROOT/validation" "$BACKUP_DIR/"
    fi

    # Create backup manifest
    cat > "$BACKUP_DIR/MANIFEST.txt" <<EOF
MAMBA ETL+DRV Rollback Backup
Created: $(date)
Reason: Rollback to legacy system

Files backed up:
EOF

    ls -lh "$BACKUP_DIR" >> "$BACKUP_DIR/MANIFEST.txt"

    success "Backup created at: $BACKUP_DIR"
    return 0
}

# Execute rollback
execute_rollback() {
    if [ "$DRY_RUN" = true ]; then
        log "[DRY RUN] Rollback steps:"
        log "  1. Create backup of new system databases"
        log "  2. Disable new ETL+DRV scripts"
        log "  3. Revert application configuration to use legacy database"
        log "  4. Document precision marketing as DISABLED (legacy was broken)"
        log "  5. Notify stakeholders"
        return 0
    fi

    error "⚠️ CRITICAL WARNING ⚠️"
    error "Legacy D04 precision marketing was BROKEN"
    error "Rollback will DISABLE precision marketing features, not restore them"
    echo ""
    echo -e "${YELLOW}Are you sure you want to proceed? (yes/no)${NC}"
    read -r CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        log "Rollback cancelled by user"
        return 1
    fi

    log "Executing rollback..."

    # Step 1: Backup
    create_backup || return 1

    # Step 2: Rename new databases to .disabled
    log "Disabling new system databases..."
    for db in "${NEW_DBS[@]}"; do
        if [ -f "$db" ]; then
            DISABLED="${db}.disabled_$(date +%Y%m%d_%H%M%S)"
            log "  Renaming: $(basename $db) -> $(basename $DISABLED)"
            mv "$db" "$DISABLED"
        fi
    done

    # Step 3: Create rollback documentation
    ROLLBACK_DOC="$PROJECT_ROOT/ROLLBACK_EXECUTED_$(date +%Y%m%d_%H%M%S).md"
    cat > "$ROLLBACK_DOC" <<EOF
# Rollback Executed

**Date**: $(date)
**Executed By**: $USER
**Log File**: $LOG_FILE
**Backup Location**: $BACKUP_DIR

## Reason for Rollback

[DOCUMENT REASON HERE]

## Actions Taken

1. ✅ Backed up new system databases to: $BACKUP_DIR
2. ✅ Disabled new ETL+DRV databases (renamed to .disabled)
3. ⚠️ Precision marketing features DISABLED (legacy was broken)

## Current State

- **ETL+DRV Pipeline**: Disabled
- **Precision Marketing**: DISABLED (no functional fallback)
- **Legacy D04**: May be present but precision marketing was broken

## Impact

- ❌ drv_precision_features: NOT AVAILABLE
- ❌ drv_precision_time_series: NOT AVAILABLE
- ❌ drv_precision_poisson_analysis: NOT AVAILABLE
- ❌ R116/R117/R118 compliance: NOT AVAILABLE

## Next Steps

1. Investigate root cause of rollback
2. Fix issues in new system
3. Plan re-migration
4. Communicate to stakeholders

## Rollback Details

\`\`\`
$(cat "$LOG_FILE")
\`\`\`

---

*Generated by rollback_to_legacy.sh*
EOF

    success "Rollback documentation created: $ROLLBACK_DOC"

    # Step 4: Create status marker
    touch "$PROJECT_ROOT/.ROLLBACK_ACTIVE"

    success "Rollback completed"
    warning "Precision marketing features are now DISABLED"
    log "Review rollback documentation at: $ROLLBACK_DOC"

    return 0
}

# Check rollback readiness
check_rollback_readiness() {
    log "Checking rollback readiness..."

    READY=true

    # Check disk space for backup
    AVAILABLE_SPACE=$(df -h "$PROJECT_ROOT" | awk 'NR==2 {print $4}')
    log "  Available disk space: $AVAILABLE_SPACE"

    # Check if backup directory can be created
    if [ -w "$PROJECT_ROOT" ]; then
        log "  ✓ Can create backup directory"
    else
        error "  ✗ Cannot write to project root"
        READY=false
    fi

    # Check if new databases exist
    NEW_DB_EXISTS=false
    for db in "${NEW_DBS[@]}"; do
        if [ -f "$db" ]; then
            NEW_DB_EXISTS=true
            break
        fi
    done

    if [ "$NEW_DB_EXISTS" = true ]; then
        log "  ✓ New system databases found"
    else
        warning "  ⚠ No new system databases found"
    fi

    # Summary
    if [ "$READY" = true ]; then
        success "Rollback readiness: READY"
        log ""
        log "⚠️ IMPORTANT NOTES:"
        log "  - Legacy D04 precision marketing was BROKEN"
        log "  - Rollback will DISABLE precision marketing, not restore it"
        log "  - Backup will be created at: $BACKUP_DIR"
        log "  - Execute with: $0 --execute"
        return 0
    else
        error "Rollback readiness: NOT READY"
        return 1
    fi
}

# Show current status
show_status() {
    echo "=== MAMBA ETL+DRV System Status ==="
    echo ""

    check_system_status

    echo ""
    echo "Rollback Status:"
    if [ -f "$PROJECT_ROOT/.ROLLBACK_ACTIVE" ]; then
        echo -e "  ${RED}ROLLBACK ACTIVE${NC}"
        echo "  System is in rollback state"
    else
        echo -e "  ${GREEN}NORMAL OPERATION${NC}"
        echo "  New system is active"
    fi

    echo ""
    echo "Backups:"
    BACKUP_COUNT=$(ls -d "$PROJECT_ROOT"/backup_before_rollback_* 2>/dev/null | wc -l | tr -d ' ')
    echo "  Total backups: $BACKUP_COUNT"

    if [ "$BACKUP_COUNT" -gt 0 ]; then
        echo "  Recent backups:"
        ls -dt "$PROJECT_ROOT"/backup_before_rollback_* 2>/dev/null | head -n 3 | while read dir; do
            echo "    - $(basename $dir)"
        done
    fi

    echo ""
}

# Main execution
case "${1:-}" in
    --check)
        check_system_status
        echo ""
        check_rollback_readiness
        ;;
    --execute)
        check_system_status
        echo ""
        execute_rollback
        ;;
    --status)
        show_status
        ;;
    --help)
        echo "Usage: $0 [--check|--execute|--status|--help]"
        echo ""
        echo "Options:"
        echo "  --check    Check rollback readiness (dry run)"
        echo "  --execute  Execute rollback (requires confirmation)"
        echo "  --status   Show current system status"
        echo "  --help     Show this help message"
        echo ""
        echo "⚠️ WARNING: Legacy D04 precision marketing was BROKEN"
        echo "Rollback will DISABLE precision marketing features, not restore them"
        ;;
    *)
        echo "Usage: $0 [--check|--execute|--status|--help]"
        echo "Run with --help for more information"
        exit 1
        ;;
esac

exit 0
