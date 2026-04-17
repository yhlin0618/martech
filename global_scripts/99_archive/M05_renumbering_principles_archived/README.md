---
id: "M05"
title: "Renumbering Principles Module"
type: "module"
date_created: "2025-04-04"
date_modified: "2025-04-04"
author: "Claude"
implements:
  - "R05": "Renaming Methods"
related_to:
  - "MP16": "Modularity"
  - "MP17": "Separation of Concerns"
  - "P05": "Naming Principles"
  - "R32": "Archiving Standard"
---

# M05 Renumbering Principles Module

This module provides the implementation of principle renumbering and renaming methods as described in R05 (Renaming Methods Rule). It contains a set of functions for safely renumbering principles, rules, and other sequenced resources in the precision marketing system.

## Purpose

The renaming module ensures that renaming operations:
- Maintain system integrity
- Prevent duplicate identifiers
- Update all references consistently
- Follow atomic transaction principles
- Can be verified for correctness

## Module Structure

```
M05_renaming/
├── README.md                 # This file
├── M05_fn_rename.R           # Main module function
├── functions/                # Individual function implementations
│   ├── verify_unique.R       # Verify name uniqueness
│   ├── scan_references.R     # Scan for references to resources
│   ├── dependency_check.R    # Check dependencies
│   ├── rename_resource.R     # Perform actual renaming
│   ├── update_references.R   # Update references after renaming
│   ├── resolve_conflicts.R   # Resolve naming conflicts
│   ├── renumber_resource.R   # Specifically for sequenced resources
│   └── verify_consistency.R  # Verify naming consistency
└── tests/                    # Tests for renaming functions
    ├── test_verify.R         # Test verification functions
    ├── test_rename.R         # Test renaming functions
    └── test_renumber.R       # Test renumbering functions
```

## Main Functions

### verify_unique(new_name)
Verifies that a proposed name is not already in use.

```r
# Check if a name is available
verify_unique("P05_new_name.md")
# Returns TRUE if available, FALSE if already in use
```

### scan_references(resource_name)
Scans the codebase for all references to a given resource.

```r
# Find all references to a resource
references <- scan_references("P05_naming_principles")
# Returns a data frame with file paths and line numbers
```

### rename_resource(old_name, new_name, update_refs = TRUE)
Performs a safe, atomic rename operation.

```r
# Rename a file
rename_resource("P04_old_name.md", "P07_new_name.md")
# Returns success status and details of the operation
```

### renumber_resource(old_id, new_id, name)
Specifically for renumbering sequenced resources (MP, P, R).

```r
# Renumber a principle
renumber_resource("P16", "P07", "app_bottom_up_construction")
# Returns success status and details of the operation
```

### batch_renumber(mapping_table)
Performs batch renumbering operations based on a mapping table.

```r
# Define a mapping table
principle_mapping <- tibble(
  old_id = c("P16", "P04", "P08"),
  new_id = c("P07", "P12", "P05"),
  name = c("app_bottom_up_construction", "app_construction", "naming_principles")
)

# Perform batch renumbering
batch_renumber(principle_mapping)
# Returns summary of operations
```

### verify_consistency()
Verifies naming consistency across the system.

```r
# Verify naming consistency
issues <- verify_consistency()
# Returns a list of issues found or NULL if consistent
```

## Usage Examples

### Simple Rename

```r
# Load the module
source("00_principles/M05_renaming/M05_fn_rename.R")

# Simple rename
M05_renaming::rename_resource("old_filename.md", "new_filename.md")
```

### Principle Renumbering

```r
# Renumber a principle
M05_renaming::renumber_resource("P16", "P07", "app_bottom_up_construction")
```

### Batch Renumbering

```r
# Batch renumber multiple principles
principle_mapping <- tibble(
  old_id = c("P16", "P04", "P08"),
  new_id = c("P07", "P12", "P05"),
  name = c("app_bottom_up_construction", "app_construction", "naming_principles")
)

M05_renaming::batch_renumber(principle_mapping)
```

### Consistency Verification

```r
# Verify system consistency after renaming
issues <- M05_renaming::verify_consistency()
if (!is.null(issues)) {
  print("Consistency issues found:")
  print(issues)
} else {
  print("System is consistent.")
}
```

## Implementation Notes

1. **Atomicity**: All operations attempt to be atomic - either fully complete or rolled back completely
2. **Backups**: Automatic backups are created before any renaming operation
3. **Validation**: Thorough validation is performed before executing rename operations
4. **Error Handling**: Comprehensive error handling with detailed error messages
5. **Logging**: All operations are logged for audit and troubleshooting purposes

## Relationship to Other Components

- Implements the renaming methods described in R05
- Supports the naming principles defined in P05
- Follows the modularity principles in MP16
- Aligns with the separation of concerns principle in MP17

## Dependencies

- R base package
- stringr (for string manipulation)
- fs (for file system operations)
- dplyr (for data manipulation)

## Future Enhancements

1. Integration with version control systems
2. Support for more complex renaming patterns
3. GUI interface for renaming operations
4. Enhanced conflict resolution strategies
5. Automated dependency analysis