---
id: "MP19"
title: "Mode Hierarchy"
type: "meta-principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "MP18": "Operating Modes"
  - "MP00": "Axiomatization System"
influences:
  - "MP23": "Data Source Hierarchy"
  - "P24": "Deployment Patterns"
---

# Mode Hierarchy Principle

## Core Concept

The Mode Hierarchy Principle establishes a formal relationship between the system's operating modes, creating a nested hierarchy of capabilities and access privileges. This hierarchy ensures that higher-level modes encompass all the capabilities of lower-level modes, allowing for consistent behavior across mode transitions.

## Mode Hierarchy Structure

The modes are organized in a strict hierarchy where each higher mode encompasses all the capabilities of the modes below it:

```
GLOBAL_MODE
    ↑
    ├── UPDATE_MODE
    │       ↑
    │       └── APP_MODE
    └───────────────────
```

This hierarchy means:
1. GLOBAL_MODE can do everything UPDATE_MODE can do, plus global resource management
2. UPDATE_MODE can do everything APP_MODE can do, plus data processing and updates
3. APP_MODE has the most restricted set of capabilities

## Hierarchical Access Pattern

The hierarchical relationship ensures consistent capabilities across modes:

| Capability | APP_MODE | UPDATE_MODE | GLOBAL_MODE |
|------------|----------|-------------|-------------|
| Run Shiny application | ✓ | ✓ | ✓ |
| Read app data | ✓ (read-only) | ✓ (read-write) | ✓ (read-write) |
| Process raw data | ✗ | ✓ | ✓ |
| Update app data | ✗ | ✓ | ✓ |
| Manage global resources | ✗ | ✗ | ✓ |
| Cross-project operations | ✗ | ✗ | ✓ |

## Implementation

### 1. Nested Function Availability

Functions available in a lower mode must also be available in all higher modes:

```r
# Example of mode-based function loading
load_mode_functions <- function(mode) {
  # Base functions needed in all modes
  source_directory("update_scripts/global_scripts/02_db_utils")
  source_directory("update_scripts/global_scripts/04_utils")
  
  # Functions for UPDATE_MODE and above
  if (mode %in% c("UPDATE_MODE", "GLOBAL_MODE")) {
    source_directory("update_scripts/global_scripts/05_import")
    source_directory("update_scripts/global_scripts/06_process")
  }
  
  # Functions only for GLOBAL_MODE
  if (mode == "GLOBAL_MODE") {
    source_directory("update_scripts/global_scripts/15_global_utils")
  }
}
```

### 2. Consistent Feature Detection

Higher modes must recognize and use features from lower modes:

```r
# Mode-aware feature detection
is_feature_available <- function(feature_name) {
  feature_modes <- list(
    "read_app_data" = c("APP_MODE", "UPDATE_MODE", "GLOBAL_MODE"),
    "update_app_data" = c("UPDATE_MODE", "GLOBAL_MODE"),
    "manage_global_resources" = c("GLOBAL_MODE")
  )
  
  current_mode <- OPERATION_MODE
  return(current_mode %in% feature_modes[[feature_name]])
}
```

### 3. Progressive Access Controls

Access controls follow the hierarchy, with progressive permissions at higher levels:

```r
# Progressive access control
get_access_level <- function(resource_type) {
  access_matrix <- list(
    "app_data" = list(
      "APP_MODE" = "read",
      "UPDATE_MODE" = "write",
      "GLOBAL_MODE" = "admin"
    ),
    "raw_data" = list(
      "APP_MODE" = "none",
      "UPDATE_MODE" = "write",
      "GLOBAL_MODE" = "admin"
    ),
    "30_global_data" = list(
      "APP_MODE" = "read",
      "UPDATE_MODE" = "read",
      "GLOBAL_MODE" = "admin"
    )
  )
  
  return(access_matrix[[resource_type]][[OPERATION_MODE]])
}
```

## Mode Transition Rules

Since modes form a hierarchy, transitions between modes must follow specific rules:

### 1. Ascending Transitions (to higher mode)

When transitioning to a higher mode, operations must:
- Close and reopen resources with appropriate permissions
- Initialize additional capabilities
- Maintain existing data consistency

```r
# Example of ascending mode transition
transition_to_higher_mode <- function(target_mode) {
  # Validate transition direction
  mode_levels <- c("APP_MODE" = 1, "UPDATE_MODE" = 2, "GLOBAL_MODE" = 3)
  current_level <- mode_levels[OPERATION_MODE]
  target_level <- mode_levels[target_mode]
  
  if (target_level <= current_level) {
    stop("Cannot transition to same or lower mode using this function")
  }
  
  # Close existing connections with current permissions
  dbDisconnect_all()
  
  # Set new mode
  OPERATION_MODE <- target_mode
  
  # Initialize with expanded capabilities
  source(file.path("update_scripts", "global_scripts", "00_principles", 
                   paste0("sc_initialization_", tolower(target_mode), ".R")))
  
  # Reopen connections with new permissions
  # Additional initialization specific to the new mode
}
```

### 2. Descending Transitions (to lower mode)

When transitioning to a lower mode, operations must:
- Verify that no write operations are pending
- Close all resources that won't be accessible in the lower mode
- Reinitialize with restricted capabilities

```r
# Example of descending mode transition
transition_to_lower_mode <- function(target_mode) {
  # Validate transition direction
  mode_levels <- c("APP_MODE" = 1, "UPDATE_MODE" = 2, "GLOBAL_MODE" = 3)
  current_level <- mode_levels[OPERATION_MODE]
  target_level <- mode_levels[target_mode]
  
  if (target_level >= current_level) {
    stop("Cannot transition to same or higher mode using this function")
  }
  
  # Check for pending write operations
  if (has_pending_writes()) {
    stop("Cannot transition to lower mode with pending write operations")
  }
  
  # Close all connections
  dbDisconnect_all()
  
  # Set new mode
  OPERATION_MODE <- target_mode
  
  # Initialize with restricted capabilities
  source(file.path("update_scripts", "global_scripts", "00_principles", 
                   paste0("sc_initialization_", tolower(target_mode), ".R")))
}
```

## Mode Verification

All operations should verify they're running in an appropriate mode:

```r
# Verify operation is allowed in current mode
require_mode <- function(required_modes) {
  if (!(OPERATION_MODE %in% required_modes)) {
    stop("This operation requires one of these modes: ", 
         paste(required_modes, collapse = ", "), 
         ". Current mode: ", OPERATION_MODE)
  }
  return(TRUE)
}

# Example usage
update_global_reference_data <- function() {
  require_mode("GLOBAL_MODE")
  # Proceed with update...
}
```

## Implications for Development

The Mode Hierarchy Principle has specific implications for development practices:

1. **Feature Testing**: All features must be tested in every mode where they should be available
2. **Function Design**: Functions should check for appropriate mode before executing
3. **Resource Management**: Resources should be opened with mode-appropriate permissions
4. **Documentation**: Function documentation should specify the required mode(s)
5. **Error Handling**: Error messages should indicate mode-related issues clearly

## Exception Handling

When operations violate mode hierarchy constraints, clear error messages should be provided:

```r
# Example mode constraint error handling
tryCatch({
  if (OPERATION_MODE == "APP_MODE") {
    update_app_data()  # Not allowed in APP_MODE
  }
}, error = function(e) {
  message("Operation failed due to mode constraint: ", e$message)
  message("Current mode: ", OPERATION_MODE)
  message("Required mode: UPDATE_MODE or GLOBAL_MODE")
  message("Use transition_to_higher_mode() to change modes if needed.")
})
```

## Conclusion

The Mode Hierarchy Principle ensures consistent, predictable behavior across different operational contexts by establishing a clear relationship between modes. This hierarchical approach simplifies reasoning about capabilities, permissions, and operational constraints, leading to more maintainable and secure code.

When implementing new features or modifying existing ones, developers should always consider how these features interact with the mode hierarchy, ensuring they respect the constraints and capabilities of each mode.