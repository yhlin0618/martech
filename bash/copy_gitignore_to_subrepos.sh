#!/bin/bash

# copy_gitignore_to_subrepos.sh
# Purpose: Copy .gitignore file to all git subrepo directories

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check if .gitignore exists
GITIGNORE_SOURCE="${PROJECT_ROOT}/.gitignore"
if [ ! -f "$GITIGNORE_SOURCE" ]; then
    print_error ".gitignore not found at: $GITIGNORE_SOURCE"
    exit 1
fi

print_info "Source .gitignore found at: $GITIGNORE_SOURCE"

# Counter for tracking
copied_count=0
skipped_count=0
error_count=0

# Function to check if a directory is a git subrepo
is_git_subrepo() {
    local dir="$1"
    [ -f "$dir/.gitrepo" ]
}

# Function to copy .gitignore to a directory
copy_gitignore() {
    local target_dir="$1"
    local target_file="$target_dir/.gitignore"
    
    if cp "$GITIGNORE_SOURCE" "$target_file" 2>/dev/null; then
        print_success "Copied to: $target_file"
        ((copied_count++))
        return 0
    else
        print_error "Failed to copy to: $target_file"
        ((error_count++))
        return 1
    fi
}

print_info "Searching for git subrepos..."
echo

# Find all directories with .gitrepo files
while IFS= read -r -d '' gitrepo_file; do
    subrepo_dir="$(dirname "$gitrepo_file")"
    relative_path="${subrepo_dir#$PROJECT_ROOT/}"
    
    print_info "Found subrepo: $relative_path"
    
    # Check if it's the current directory (skip)
    if [ "$subrepo_dir" = "$PROJECT_ROOT" ]; then
        print_warning "Skipping root directory"
        ((skipped_count++))
        continue
    fi
    
    # Copy .gitignore
    copy_gitignore "$subrepo_dir"
    echo
    
done < <(find "$PROJECT_ROOT" -name ".gitrepo" -type f -print0 2>/dev/null)

# Summary
echo
echo "========================================"
echo "Summary:"
echo "========================================"
print_success "Copied: $copied_count"
print_warning "Skipped: $skipped_count"
if [ $error_count -gt 0 ]; then
    print_error "Errors: $error_count"
fi
echo "========================================"

# Exit with appropriate code
if [ $error_count -gt 0 ]; then
    exit 1
else
    exit 0
fi