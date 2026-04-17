#!/bin/bash
#
# check_root.sh - Check and optionally clean root directory violations
#
# Following principles:
# - SO_R033: Test Script Location Standard
# - SO_R034: Debug Script Management and Archival
# - SO_R035: Temporary File and Log Management
# - SO_R031: Backup File Management
#
# Usage:
#   ./check_root.sh              # Check only, exit with status
#   ./check_root.sh --verbose    # Detailed output
#   ./check_root.sh --fix        # Auto-archive violations (dry run)
#   ./check_root.sh --fix --execute  # Actually archive violations
#   ./check_root.sh --ci         # CI mode: fail on violations
#
# Exit codes:
#   0 - Root is clean
#   1 - Violations found (in CI mode)
#   2 - Error (R not installed, etc.)
#

set -e

# Script directory and MAMBA root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAMBA_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
VERBOSE="FALSE"
FIX_MODE="FALSE"
EXECUTE="FALSE"
CI_MODE="FALSE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Icons
ICON_CHECK="\xE2\x9C\x93"
ICON_CROSS="\xE2\x9C\x97"
ICON_WARN="\xE2\x9A\xA0"

# Help message
show_help() {
    cat << 'EOF'
check_root.sh - Check and clean MAMBA root directory violations

USAGE:
    ./check_root.sh [OPTIONS]

OPTIONS:
    --verbose       Show detailed information about violations
    --fix           Propose automatic archiving of violations (dry run)
    --execute       Actually perform archiving (requires --fix)
    --ci            CI mode: exit with error code if violations found
    -h, --help      Show this help message

EXAMPLES:
    # Quick check - is root clean?
    ./check_root.sh

    # Detailed check with file listings
    ./check_root.sh --verbose

    # See what would be archived
    ./check_root.sh --fix

    # Actually archive violations
    ./check_root.sh --fix --execute

    # Use in CI/CD pipeline
    ./check_root.sh --ci

VIOLATION TYPES CHECKED:
    - test_*.R, validate_*.R, verify_*.R, check_*.R  (SO_R033)
    - debug_*.R                                       (SO_R034)
    - *.log, *.rds                                    (SO_R035)
    - *.backup_*, *.bak                               (SO_R031)
    - *REPORT*.md, *DEBUG*.md, *FIX*.md               (SO_R030)

DESTINATION DIRECTORIES:
    - Test scripts      -> scripts/global_scripts/98_test/
    - Debug scripts     -> ISSUE_TRACKER/archive/debugging/
    - Log files         -> logs/archive/
    - Temp data         -> data/temp/archive/
    - Backup files      -> data/backups/archive/
    - Report docs       -> docs/reports/

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose)
            VERBOSE="TRUE"
            shift
            ;;
        --fix)
            FIX_MODE="TRUE"
            shift
            ;;
        --execute)
            EXECUTE="TRUE"
            shift
            ;;
        --ci)
            CI_MODE="TRUE"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            show_help
            exit 2
            ;;
    esac
done

# Check if R is available
if ! command -v Rscript &> /dev/null; then
    echo -e "${RED}Error: Rscript not found. Please install R.${NC}"
    exit 2
fi

# Verify utility functions exist
CHECK_FUNC="${MAMBA_ROOT}/scripts/global_scripts/04_utils/fn_check_root_cleanliness.R"
ARCHIVE_FUNC="${MAMBA_ROOT}/scripts/global_scripts/04_utils/fn_archive_root_files.R"

if [[ ! -f "$CHECK_FUNC" ]]; then
    echo -e "${RED}Error: fn_check_root_cleanliness.R not found${NC}"
    echo "Expected at: $CHECK_FUNC"
    exit 2
fi

# Header
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  MAMBA Root Directory Cleanliness Check${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "  Root: ${CYAN}${MAMBA_ROOT}${NC}"
echo -e "  Mode: $([ "$CI_MODE" == "TRUE" ] && echo "CI" || echo "Interactive")"
echo ""

# Run check
if [[ "$FIX_MODE" == "TRUE" ]]; then
    # Fix mode - run archive function
    if [[ ! -f "$ARCHIVE_FUNC" ]]; then
        echo -e "${RED}Error: fn_archive_root_files.R not found${NC}"
        echo "Expected at: $ARCHIVE_FUNC"
        exit 2
    fi

    DRY_RUN=$([ "$EXECUTE" == "TRUE" ] && echo "FALSE" || echo "TRUE")

    if [[ "$EXECUTE" == "TRUE" ]]; then
        echo -e "${YELLOW}${ICON_WARN} EXECUTE MODE - Files will be moved${NC}"
    else
        echo -e "${CYAN}DRY RUN - No files will be modified${NC}"
    fi
    echo ""

    R_CMD="
# Source functions
source('${CHECK_FUNC}')
source('${ARCHIVE_FUNC}')

# Run archive
result <- fn_archive_root_files(
  root_dir = '${MAMBA_ROOT}',
  dry_run = ${DRY_RUN},
  verbose = TRUE,
  create_readme = TRUE
)

# Get summary
summary <- attr(result, 'summary')

# Exit with appropriate code
if (summary\$total_processed == 0) {
  cat('\n')
  cat('\033[0;32m', '${ICON_CHECK}', ' Root directory is CLEAN\033[0m\n')
  quit(status = 0)
} else {
  if (${DRY_RUN}) {
    cat('\n')
    cat('\033[1;33m', '${ICON_WARN}', ' ', summary\$total_processed, ' files would be processed\033[0m\n')
    cat('Run with --execute to perform archiving\n')
  } else {
    cat('\n')
    if (summary\$failed > 0) {
      cat('\033[0;31m', '${ICON_CROSS}', ' ', summary\$failed, ' files failed to archive\033[0m\n')
      quit(status = 1)
    } else {
      cat('\033[0;32m', '${ICON_CHECK}', ' ', summary\$completed, ' files archived successfully\033[0m\n')
    }
  }
  quit(status = 0)
}
"

    cd "${MAMBA_ROOT}"
    Rscript -e "${R_CMD}"
    exit_code=$?

else
    # Check mode only
    R_CMD="
# Source check function
source('${CHECK_FUNC}')

# Run check
result <- fn_check_root_cleanliness(
  root_dir = '${MAMBA_ROOT}',
  verbose = ${VERBOSE}
)

# Output based on verbosity
if (${VERBOSE} == TRUE) {
  if (!result\$is_clean) {
    cat('\n')
    cat(fn_format_root_check_summary(result))
    cat('\n')
  }
}

# Summary output
cat('\n')
if (result\$is_clean) {
  cat('\033[0;32m${ICON_CHECK} Root directory is CLEAN - no violations found\033[0m\n')
  quit(status = 0)
} else {
  cat('\033[0;31m${ICON_CROSS} Found ', result\$summary\$violations, ' violations\033[0m\n')
  cat('\n')

  # Show category breakdown
  for (cat in names(result\$summary\$by_category)) {
    count <- result\$summary\$by_category[[cat]]
    cat('  ', gsub('_', ' ', cat), ': ', count, ' files\n')
  }

  cat('\n')
  cat('Run with --verbose for details or --fix to archive\n')

  # Exit code depends on CI mode
  if (${CI_MODE} == TRUE) {
    quit(status = 1)
  } else {
    quit(status = 0)
  }
}
"

    cd "${MAMBA_ROOT}"
    Rscript -e "${R_CMD}"
    exit_code=$?
fi

echo ""
exit $exit_code
