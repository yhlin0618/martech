#!/bin/bash
#
# generate_doc.sh - Generate documentation from templates
#
# Following principles:
# - SO_R032: Documentation Template System
# - R069: Function file naming conventions
#
# Usage:
#   ./generate_doc.sh --type implementation --topic feature_name
#   ./generate_doc.sh --type debug --topic api_timeout --title "API Timeout Investigation"
#   ./generate_doc.sh --type fix --topic memory_leak --open
#   ./generate_doc.sh --list
#
# Creates: scripts/global_scripts/00_principles/CHANGELOG/YYYY-MM-DD_topic_type.md
#

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAMBA_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Default values
TYPE=""
TOPIC=""
TITLE=""
AUTHOR=""
OPEN_FILE="FALSE"
LIST_TEMPLATES="FALSE"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Help message
show_help() {
    cat << EOF
generate_doc.sh - Generate documentation from templates

USAGE:
    ./generate_doc.sh [OPTIONS]

OPTIONS:
    --type TYPE       Template type: implementation, debug, fix, test, strategy
    --topic TOPIC     Brief topic name (used in filename, use snake_case)
    --title TITLE     Full title for the document (optional)
    --author AUTHOR   Author name (default: current user)
    --open            Open the file after creation
    --list            List available templates
    -h, --help        Show this help message

EXAMPLES:
    # Create implementation report
    ./generate_doc.sh --type implementation --topic user_auth

    # Create debug report with custom title
    ./generate_doc.sh --type debug --topic api_timeout --title "API Timeout Issue"

    # Create and open fix report
    ./generate_doc.sh --type fix --topic memory_leak --open

    # List available templates
    ./generate_doc.sh --list

OUTPUT:
    Creates file: CHANGELOG/YYYY-MM-DD_topic_type.md

EOF
}

# List templates
list_templates() {
    echo -e "${GREEN}Available Documentation Templates:${NC}"
    echo ""
    echo "  Type            Description"
    echo "  --------------  --------------------------------------------------"
    echo "  implementation  Implementation report for new features or changes"
    echo "  debug           Debug report for investigating issues"
    echo "  fix             Fix report documenting bug fixes"
    echo "  test            Test report for testing activities"
    echo "  strategy        Strategy document for planning and decisions"
    echo ""
    echo "Use: ./generate_doc.sh --type <type> --topic <topic>"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --type)
            TYPE="$2"
            shift 2
            ;;
        --topic)
            TOPIC="$2"
            shift 2
            ;;
        --title)
            TITLE="$2"
            shift 2
            ;;
        --author)
            AUTHOR="$2"
            shift 2
            ;;
        --open)
            OPEN_FILE="TRUE"
            shift
            ;;
        --list)
            LIST_TEMPLATES="TRUE"
            shift
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

# Handle --list
if [[ "$LIST_TEMPLATES" == "TRUE" ]]; then
    list_templates
    exit 0
fi

# Validate required arguments
if [[ -z "$TYPE" ]]; then
    echo -e "${RED}Error: --type is required${NC}"
    echo "Use --list to see available types"
    exit 1
fi

if [[ -z "$TOPIC" ]]; then
    echo -e "${RED}Error: --topic is required${NC}"
    exit 1
fi

# Validate type
case $TYPE in
    implementation|debug|fix|test|strategy)
        ;;
    *)
        echo -e "${RED}Error: Invalid type: $TYPE${NC}"
        echo "Valid types: implementation, debug, fix, test, strategy"
        exit 1
        ;;
esac

# Check if R is available
if ! command -v Rscript &> /dev/null; then
    echo -e "${RED}Error: Rscript not found. Please install R.${NC}"
    exit 1
fi

# Build R command
R_CMD="
# Source the function
source('${MAMBA_ROOT}/scripts/global_scripts/04_utils/fn_generate_doc.R')

# Generate document
result <- fn_generate_doc(
  type = '${TYPE}',
  topic = '${TOPIC}'
"

# Add optional arguments
if [[ -n "$TITLE" ]]; then
    R_CMD="${R_CMD},
  title = '${TITLE}'"
fi

if [[ -n "$AUTHOR" ]]; then
    R_CMD="${R_CMD},
  author = '${AUTHOR}'"
fi

R_CMD="${R_CMD},
  open = ${OPEN_FILE}
)

# Print result
if (!is.null(result)) {
  cat('SUCCESS:', result, '\n')
} else {
  cat('FAILED: Could not create document\n')
  quit(status = 1)
}
"

# Run R script
echo -e "${YELLOW}Generating ${TYPE} document for: ${TOPIC}${NC}"
cd "${MAMBA_ROOT}"
Rscript -e "${R_CMD}"

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}Document created successfully!${NC}"
else
    echo -e "${RED}Failed to create document${NC}"
    exit 1
fi
