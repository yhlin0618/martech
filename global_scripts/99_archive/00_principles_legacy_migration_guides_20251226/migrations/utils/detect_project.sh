#!/bin/bash
#
# detect_project.sh - Auto-detect project context by finding project_config.yaml
#
# This script walks up the directory tree from the current working directory
# to find project_config.yaml, then extracts project information and exports
# it as environment variables.
#
# Usage:
#   source detect_project.sh
#   # OR
#   eval "$(bash detect_project.sh)"
#
# Exports:
#   PROJECT_ROOT           - Absolute path to project root
#   PROJECT_NAME           - Project name from config
#   PROJECT_TYPE           - Project type (r_shiny, r_analysis, python, mixed)
#   PROJECT_OWNER          - Project owner
#   PRINCIPLES_CORE        - Absolute path to core principles
#   PRINCIPLES_LOCAL       - Absolute path to local principles
#   PROJECT_CONFIG_PATH    - Absolute path to project_config.yaml
#
# Exit codes:
#   0 - Success
#   1 - No project_config.yaml found
#   2 - Invalid configuration file

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

# Function to find project root by looking for project_config.yaml
find_project_root() {
    local current_dir="$PWD"
    local max_depth=10
    local depth=0

    while [[ "$current_dir" != "/" && $depth -lt $max_depth ]]; do
        if [[ -f "$current_dir/project_config.yaml" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
        ((depth++))
    done

    log_error "No project_config.yaml found in parent directories (searched $depth levels)"
    log_error "Current directory: $PWD"
    log_error "Make sure you are within a project directory"
    return 1
}

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to extract YAML value using various methods
extract_yaml_value() {
    local file="$1"
    local key="$2"
    local default="${3:-}"

    # Try yq first (most reliable)
    if command_exists yq; then
        local value
        value=$(yq eval "$key" "$file" 2>/dev/null || echo "$default")
        if [[ "$value" != "null" && -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi

    # Fallback to Python (if available)
    if command_exists python3; then
        local value
        value=$(python3 -c "
import yaml
import sys
try:
    with open('$file') as f:
        data = yaml.safe_load(f)
    keys = '$key'.strip('.').split('.')
    result = data
    for k in keys:
        result = result.get(k, {})
    print(result if result != {} else '$default')
except:
    print('$default')
" 2>/dev/null || echo "$default")
        if [[ -n "$value" ]]; then
            echo "$value"
            return 0
        fi
    fi

    # Last resort: simple grep/sed (unreliable but better than nothing)
    local simple_key="${key##*.}"  # Get last part of key
    local value
    value=$(grep -A 1 "^[[:space:]]*${simple_key}:" "$file" 2>/dev/null | tail -1 | sed 's/.*: *"\?\([^"]*\)"\?.*/\1/' || echo "$default")

    if [[ -n "$value" ]]; then
        echo "$value"
    else
        echo "$default"
    fi
}

# Function to resolve environment variables in paths
resolve_env_vars() {
    local path="$1"

    # Replace ${VAR} with value
    while [[ "$path" =~ \$\{([^}]+)\} ]]; do
        local var_name="${BASH_REMATCH[1]}"
        local var_value="${!var_name:-}"

        if [[ -z "$var_value" ]]; then
            log_warn "Environment variable \${$var_name} not set, using empty string"
        fi

        path="${path//\$\{$var_name\}/$var_value}"
    done

    echo "$path"
}

# Function to get project info from config
get_project_info() {
    local project_root="$1"
    local config_file="$project_root/project_config.yaml"

    # Validate config file exists
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 2
    fi

    log_info "Reading configuration from: $config_file"

    # Extract project information
    local project_name
    local project_type
    local project_owner
    local principles_core_rel
    local principles_local_rel

    project_name=$(extract_yaml_value "$config_file" ".project.name" "unknown")
    project_type=$(extract_yaml_value "$config_file" ".project.type" "unknown")
    project_owner=$(extract_yaml_value "$config_file" ".project.owner" "unknown")
    principles_core_rel=$(extract_yaml_value "$config_file" ".project.principles.core_path" "global_scripts/00_principles")
    principles_local_rel=$(extract_yaml_value "$config_file" ".project.principles.local_path" "global_scripts/00_principles_local")

    # Validate required fields
    if [[ "$project_name" == "unknown" || "$project_name" == "null" ]]; then
        log_error "Invalid configuration: project.name is not set"
        return 2
    fi

    # Resolve relative paths to absolute
    local principles_core_abs="$project_root/$principles_core_rel"
    local principles_local_abs="$project_root/$principles_local_rel"

    # Export environment variables
    export PROJECT_ROOT="$project_root"
    export PROJECT_NAME="$project_name"
    export PROJECT_TYPE="$project_type"
    export PROJECT_OWNER="$project_owner"
    export PRINCIPLES_CORE="$principles_core_abs"
    export PRINCIPLES_LOCAL="$principles_local_abs"
    export PROJECT_CONFIG_PATH="$config_file"

    # Verify principles directories exist
    if [[ ! -d "$PRINCIPLES_CORE" ]]; then
        log_warn "Core principles directory not found: $PRINCIPLES_CORE"
        log_warn "You may need to run: git subrepo pull $principles_core_rel"
    fi

    if [[ ! -d "$PRINCIPLES_LOCAL" ]]; then
        log_warn "Local principles directory not found: $PRINCIPLES_LOCAL"
        log_warn "Creating directory: $PRINCIPLES_LOCAL"
        mkdir -p "$PRINCIPLES_LOCAL"
    fi

    return 0
}

# Function to display project info
display_project_info() {
    log_info "Project detected successfully!"
    echo ""
    echo "  Project Name:      $PROJECT_NAME"
    echo "  Project Type:      $PROJECT_TYPE"
    echo "  Project Owner:     $PROJECT_OWNER"
    echo "  Project Root:      $PROJECT_ROOT"
    echo "  Core Principles:   $PRINCIPLES_CORE"
    echo "  Local Principles:  $PRINCIPLES_LOCAL"
    echo ""
}

# Function to check for required tools
check_dependencies() {
    local missing_tools=()

    if ! command_exists yq && ! command_exists python3; then
        missing_tools+=("yq or python3")
    fi

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warn "Missing recommended tools: ${missing_tools[*]}"
        log_warn "Install yq for better YAML parsing: brew install yq"
        log_warn "Falling back to basic grep/sed parsing"
    fi
}

# Main execution
main() {
    # Check dependencies
    check_dependencies

    # Find project root
    local project_root
    project_root=$(find_project_root)

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Get project information
    if ! get_project_info "$project_root"; then
        return 2
    fi

    # Display information (only if not being sourced for export)
    if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
        display_project_info

        # Output export commands for eval
        echo "# To export these variables, run:"
        echo "# eval \"\$(bash $0)\""
        echo ""
        echo "export PROJECT_ROOT='$PROJECT_ROOT'"
        echo "export PROJECT_NAME='$PROJECT_NAME'"
        echo "export PROJECT_TYPE='$PROJECT_TYPE'"
        echo "export PROJECT_OWNER='$PROJECT_OWNER'"
        echo "export PRINCIPLES_CORE='$PRINCIPLES_CORE'"
        echo "export PRINCIPLES_LOCAL='$PRINCIPLES_LOCAL'"
        echo "export PROJECT_CONFIG_PATH='$PROJECT_CONFIG_PATH'"
    fi

    return 0
}

# Run main function
main "$@"
