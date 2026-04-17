#!/bin/bash
# Script to exclude .git directories from Dropbox sync

echo "Setting up Dropbox exclusions for Git repositories..."

# Get the current directory
CURRENT_DIR=$(pwd)

# Function to exclude a path from Dropbox
exclude_from_dropbox() {
    local path="$1"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        xattr -w com.dropbox.ignored 1 "$path" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✓ Excluded from Dropbox: $path"
        else
            echo "✗ Failed to exclude: $path"
        fi
    else
        # Linux/Other
        attr -s com.dropbox.ignored -V 1 "$path" 2>/dev/null
        if [ $? -eq 0 ]; then
            echo "✓ Excluded from Dropbox: $path"
        else
            echo "✗ Failed to exclude: $path"
        fi
    fi
}

# Exclude .git in current directory
if [ -d ".git" ]; then
    exclude_from_dropbox ".git"
fi

# Find and exclude all .git directories in subdirectories
find . -type d -name ".git" -not -path "./.git" | while read gitdir; do
    exclude_from_dropbox "$gitdir"
done

echo "Done! To verify exclusions, check Dropbox selective sync settings."
echo ""
echo "Note: New .git directories created in the future will need to be excluded manually"
echo "or by running this script again."
