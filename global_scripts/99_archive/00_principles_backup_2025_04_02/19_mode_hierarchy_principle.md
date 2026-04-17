# Mode Hierarchy and Utility Sharing Principle

This document defines the hierarchical relationship between operating modes and establishes principles for sharing utility functions across modes.

## Core Concept

The precision marketing system operates in three modes (APP_MODE, UPDATE_MODE, and GLOBAL_MODE) with a hierarchical relationship between them. This hierarchy dictates how resources, utilities, and functionality are shared and accessed.

## Mode Hierarchy

The operating modes follow this hierarchical relationship:

```
GLOBAL_MODE  
    │  
    ▼  
UPDATE_MODE  
    │  
    ▼  
APP_MODE  
```

This hierarchy implies that:

1. **APP_MODE is a subset of UPDATE_MODE**: Everything accessible in APP_MODE must be accessible in UPDATE_MODE.

2. **UPDATE_MODE is a subset of GLOBAL_MODE**: Everything accessible in UPDATE_MODE must be accessible in GLOBAL_MODE.

3. **Progressive Functionality**: As you move up the hierarchy, more functionality becomes available, but all core functionality must be available to lower modes.

## Utility Sharing Implementation

### 1. DRY Principle for Utility Functions

Utility functions should follow the Don't Repeat Yourself (DRY) principle:

- Utility functions must be defined only once in the codebase
- Functions needed across multiple modes should be placed in `11_rshinyapp_utils`
- Mode-specific utility functions should be clearly marked as such

### 2. Function Placement Rules

| Function Type | Placement |
|---------------|-----------|
| Functions used in all modes | `11_rshinyapp_utils` |
| Functions used only in UPDATE_MODE and GLOBAL_MODE | UPDATE_MODE initialization |
| Functions used only in GLOBAL_MODE | GLOBAL_MODE initialization |

### 3. Initialization Loading Order

1. All initialization scripts must first load utility functions from `11_rshinyapp_utils`
2. Higher-mode initialization scripts should include all utilities needed by lower modes
3. Initialization scripts should have fallback definitions for critical utilities

## Implementation Guidelines

### Early Loading of Core Utilities

Core utilities should be loaded early in the initialization process:

```r
# First, look for the utility in rshinyapp_utils
utils_path <- file.path("update_scripts", "global_scripts", "11_rshinyapp_utils", "fn_utility_name.R")
if (file.exists(utils_path)) {
  source_with_verbose(utils_path)
} else {
  # Fallback definition if the file doesn't exist yet
  utility_function <- function(...) {
    # Fallback implementation
  }
  
  message("Warning: fn_utility_name.R not found. Using fallback definition.")
}
```

### Avoiding Redefinition

To prevent redefinition of utility functions:

```r
# Only define the function if it doesn't already exist
if (!exists("utility_function")) {
  utility_function <- function(...) {
    # Implementation
  }
}
```

### Recursive Component Loading

Functions for recursive directory scanning should be in the utils directory:

```r
# In 11_rshinyapp_utils/fn_get_r_files_recursive.R
get_r_files_recursive <- function(dir_path, pattern = "\\.R$") {
  # Get files in current directory
  files <- dir(dir_path, pattern = pattern, full.names = TRUE)
  
  # Get subdirectories and recursively search them
  subdirs <- list.dirs(dir_path, recursive = FALSE)
  for (subdir in subdirs) {
    subdir_files <- get_r_files_recursive(subdir, pattern)
    files <- c(files, subdir_files)
  }
  
  return(files)
}
```

## Best Practices

### 1. Migration Path

- When a utility function is needed in a lower mode:
  1. Move it from the mode-specific initialization to `11_rshinyapp_utils`
  2. Add a fallback definition in case the file is not yet available
  3. Update all usages to reference the centralized version

### 2. Documentation

- Document the operating modes each function supports
- Note any mode-specific variations in behavior
- Use Roxygen `@export` tags to indicate public interfaces

### 3. Testing

- Test utilities in all modes they're designed to support
- Verify that initialization scripts can handle missing utility files
- Ensure fallback implementations provide essential functionality

## Conclusion

The Mode Hierarchy and Utility Sharing Principle ensures that our codebase remains DRY and that each operating mode has access to all the functionality it requires. By following a clear hierarchy and established rules for sharing utilities, we maintain a clean and maintainable architecture while supporting the specific needs of each operating mode.