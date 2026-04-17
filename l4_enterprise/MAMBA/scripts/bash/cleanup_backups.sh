#!/bin/bash
#
# cleanup_backups.sh - Clean up backup files in the MAMBA project
#
# Following principles:
# - SO_R031: Backup File Management
# - R069: Function file naming conventions
#
# Usage:
#   ./cleanup_backups.sh                    # Dry run with defaults
#   ./cleanup_backups.sh --days 7           # Dry run, 7-day retention
#   ./cleanup_backups.sh --execute          # Actually perform cleanup
#   ./cleanup_backups.sh --stats            # Show backup statistics only
#
# This script manages .backup files by:
# 1. Keeping files newer than --days (default: 7)
# 2. Archiving files older than --days to data/backups/archive/
# 3. Deleting archived files older than --archive-days (default: 30)
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAMBA_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
DAYS_TO_KEEP=7
ARCHIVE_DAYS=30
DRY_RUN="TRUE"
SHOW_STATS="FALSE"
LOG_FILE=""
SEARCH_DIR=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Help message
show_help() {
    cat << EOF
cleanup_backups.sh - Clean up backup files in the MAMBA project

USAGE:
    ./cleanup_backups.sh [OPTIONS]

OPTIONS:
    --days N          Days to keep backups in original location (default: 7)
    --archive-days N  Days to keep in archive before deletion (default: 30)
    --dir PATH        Directory to search (default: MAMBA root)
    --execute         Actually perform cleanup (default is dry run)
    --dry-run         Show what would be done without making changes (default)
    --stats           Show backup statistics only
    --log FILE        Log actions to file
    -h, --help        Show this help message

EXAMPLES:
    # Dry run - see what would be cleaned up
    ./cleanup_backups.sh

    # Dry run with 14-day retention
    ./cleanup_backups.sh --days 14

    # Actually clean up with 7-day retention
    ./cleanup_backups.sh --execute --days 7

    # Show statistics only
    ./cleanup_backups.sh --stats

    # Clean up specific directory
    ./cleanup_backups.sh --dir /path/to/project --execute

BEHAVIOR:
    1. Files younger than --days: KEPT in place
    2. Files between --days and --archive-days: MOVED to archive
    3. Files older than --archive-days: DELETED

PATTERNS MATCHED:
    - *.backup_*
    - *.bak
    - *_backup.*
    - *~

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --days)
            DAYS_TO_KEEP="$2"
            shift 2
            ;;
        --archive-days)
            ARCHIVE_DAYS="$2"
            shift 2
            ;;
        --dir)
            SEARCH_DIR="$2"
            shift 2
            ;;
        --execute)
            DRY_RUN="FALSE"
            shift
            ;;
        --dry-run)
            DRY_RUN="TRUE"
            shift
            ;;
        --stats)
            SHOW_STATS="TRUE"
            shift
            ;;
        --log)
            LOG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Check if R is available
if ! command -v Rscript &> /dev/null; then
    echo -e "${RED}Error: Rscript not found. Please install R.${NC}"
    exit 1
fi

# Handle --stats
if [[ "$SHOW_STATS" == "TRUE" ]]; then
    echo -e "${BLUE}=== Backup File Statistics ===${NC}"
    echo ""

    R_CMD="
# Source the function
source('${MAMBA_ROOT}/scripts/global_scripts/04_utils/fn_cleanup_backups.R')

# Get statistics
stats <- fn_get_backup_stats()

cat('Total backup files:', stats\$total_files, '\n')
cat('Total size:', stats\$total_size_mb, 'MB\n')
cat('\n')

if (stats\$total_files > 0) {
  cat('Oldest file:', basename(stats\$oldest_file), '\n')
  cat('  Age:', stats\$oldest_age_days, 'days\n')
  cat('  Path:', stats\$oldest_file, '\n\n')

  cat('Newest file:', basename(stats\$newest_file), '\n')
  cat('  Age:', stats\$newest_age_days, 'days\n')
  cat('  Path:', stats\$newest_file, '\n\n')

  cat('Age Distribution:\n')
  for (name in names(stats\$age_distribution)) {
    cat('  ', name, ':', stats\$age_distribution[[name]], 'files\n')
  }
}
"
    cd "${MAMBA_ROOT}"
    Rscript -e "${R_CMD}"
    exit 0
fi

# Show configuration
echo -e "${BLUE}=== Backup Cleanup Configuration ===${NC}"
echo ""
echo "  Search directory: ${SEARCH_DIR:-$MAMBA_ROOT}"
echo "  Days to keep:     ${DAYS_TO_KEEP}"
echo "  Archive days:     ${ARCHIVE_DAYS}"
echo "  Dry run:          ${DRY_RUN}"
if [[ -n "$LOG_FILE" ]]; then
    echo "  Log file:         ${LOG_FILE}"
fi
echo ""

if [[ "$DRY_RUN" == "TRUE" ]]; then
    echo -e "${YELLOW}*** DRY RUN - No changes will be made ***${NC}"
    echo ""
fi

# Build R command
R_CMD="
# Source the function
source('${MAMBA_ROOT}/scripts/global_scripts/04_utils/fn_cleanup_backups.R')

# Run cleanup
result <- fn_cleanup_backups(
  days_to_keep = ${DAYS_TO_KEEP},
  archive_days = ${ARCHIVE_DAYS},
  dry_run = ${DRY_RUN}
"

if [[ -n "$SEARCH_DIR" ]]; then
    R_CMD="${R_CMD},
  search_dir = '${SEARCH_DIR}'"
fi

if [[ -n "$LOG_FILE" ]]; then
    R_CMD="${R_CMD},
  log_file = '${LOG_FILE}'"
fi

R_CMD="${R_CMD}
)

# Print detailed results for files that will be acted upon
if (nrow(result) > 0) {
  actions <- result[result\$action != 'keep', ]
  if (nrow(actions) > 0) {
    cat('\n=== Files to be processed ===\n\n')
    for (i in seq_len(nrow(actions))) {
      f <- actions[i, ]
      action_color <- switch(f\$action,
        'archive' = '\033[0;33m',  # Yellow
        'delete' = '\033[0;31m',   # Red
        '\033[0m')
      cat(sprintf('%s[%s]\033[0m %s (%.1f days old)\n',
          action_color, toupper(f\$action), basename(f\$file), f\$age_days))
    }
  }
}

# Get summary
summary <- attr(result, 'summary')
cat('\n=== Summary ===\n')
cat('Actions planned/taken:\n')
cat('  Keep:', summary\$kept, '\n')
cat('  Archive:', summary\$archived, '\n')
cat('  Delete:', summary\$deleted, '\n')
"

# Run R script
cd "${MAMBA_ROOT}"
Rscript -e "${R_CMD}"

echo ""
if [[ "$DRY_RUN" == "TRUE" ]]; then
    echo -e "${YELLOW}To execute these changes, run with --execute flag${NC}"
else
    echo -e "${GREEN}Cleanup completed!${NC}"
fi
