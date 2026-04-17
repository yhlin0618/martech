---
id: "MP18"
title: "Operating Modes"
type: "meta-principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "MP00": "Axiomatization System"
  - "MP01": "Primitive Terms and Definitions"
influences:
  - "MP19": "Mode Hierarchy"
  - "MP23": "Data Source Hierarchy"
  - "P24": "Deployment Patterns"
---

# Operating Modes

## Core Concept

The Precision Marketing system operates in different modes that control access to data sources, function availability, and operational behavior. These modes create clear boundaries for different types of operations and enhance security by limiting access based on the operational context.

## Mode Definitions

### APP_MODE

**Purpose**: Run the Shiny application in a production-like environment

**Characteristics**:
- Read-only access to app_data and Data.duckdb
- No access to raw_data, cleansed_data, or processed_data
- Limited subset of global_scripts are loaded
- Minimal dependencies
- Security-first approach

### UPDATE_MODE

**Purpose**: Process data, update app data sources, and develop app components

**Characteristics**:
- Read-write access to app_data and Data.duckdb
- Read-write access to raw_data, cleansed_data, and processed_data
- Full access to 01_db through 14_sql_utils directories
- Loads more extensive set of utilities
- Focus on data processing functionality

### GLOBAL_MODE

**Purpose**: Manage global resources and cross-project utilities

**Characteristics**:
- Full access to all data sources
- Administrative capabilities for global resources
- Access to 30_global_data directory for cross-project data
- Loads extended development utilities
- Intended for system maintenance

## Mode Selection

The operating mode is controlled by the `OPERATION_MODE` environment variable, which should be set at the beginning of execution:

```r
# Set operation mode explicitly
OPERATION_MODE <- "APP_MODE"  # or "UPDATE_MODE" or "GLOBAL_MODE"

# Source the appropriate initialization script
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_app_mode.R"))
```

Each mode has a corresponding initialization script:

1. `sc_initialization_app_mode.R` for APP_MODE
2. `sc_initialization_update_mode.R` for UPDATE_MODE
3. `sc_initialization_global_mode.R` for GLOBAL_MODE

## Mode-Specific Initialization

Each initialization script loads a specific set of dependencies:

### APP_MODE Initialization

```r
# sc_initialization_app_mode.R (simplified)
OPERATION_MODE <- "APP_MODE"

# Load only what's needed for the Shiny app
source_directory(file.path("update_scripts", "global_scripts", "02_db_utils"))
source_directory(file.path("update_scripts", "global_scripts", "04_utils"))
source_directory(file.path("update_scripts", "global_scripts", "03_config"))
source_directory(file.path("update_scripts", "global_scripts", "10_rshinyapp_components"))
source_directory(file.path("update_scripts", "global_scripts", "11_rshinyapp_utils"))

# Enforce read-only access
read_only_db_access <- TRUE

# Restrict access to data directories
allow_raw_data_access <- FALSE
allow_processed_data_access <- FALSE
```

### UPDATE_MODE Initialization

```r
# sc_initialization_update_mode.R (simplified)
OPERATION_MODE <- "UPDATE_MODE"

# Load all data processing utilities
source_directory(file.path("update_scripts", "global_scripts", "01_db"))
source_directory(file.path("update_scripts", "global_scripts", "02_db_utils"))
source_directory(file.path("update_scripts", "global_scripts", "03_config"))
source_directory(file.path("update_scripts", "global_scripts", "04_utils"))
source_directory(file.path("update_scripts", "global_scripts", "05_import"))
# ... additional directories

# Allow data modifications
read_only_db_access <- FALSE

# Allow access to processing data
allow_raw_data_access <- TRUE
allow_processed_data_access <- TRUE
```

### GLOBAL_MODE Initialization

```r
# sc_initialization_global_mode.R (simplified)
OPERATION_MODE <- "GLOBAL_MODE"

# Load everything including global resource utilities
source_directory(file.path("update_scripts", "global_scripts", "01_db"))
source_directory(file.path("update_scripts", "global_scripts", "02_db_utils"))
# ... all directories
source_directory(file.path("update_scripts", "global_scripts", "99_development"))

# Full access
read_only_db_access <- FALSE
allow_raw_data_access <- TRUE
allow_processed_data_access <- TRUE
allow_global_data_modification <- TRUE
```

## Mode-Based Security Controls

The operating mode enforces security controls:

### Database Access Controls

```r
# Example from dbConnect_from_list.R
dbConnect_from_list <- function(db_name, read_only = NULL) {
  # Default to mode-specific setting if not specified
  if (is.null(read_only)) {
    read_only <- read_only_db_access
  }
  
  # APP_MODE forces read-only for app_data
  if (OPERATION_MODE == "APP_MODE" && db_name == "app_data") {
    read_only <- TRUE
  }
  
  # Prevent raw data access in APP_MODE
  if (OPERATION_MODE == "APP_MODE" && 
      db_name %in% c("raw_data", "cleansed_data", "processed_data")) {
    stop("Access to ", db_name, " is not allowed in APP_MODE")
  }
  
  # Connect with appropriate permissions
  duckdb::dbConnect(duckdb::duckdb(), db_path, read_only = read_only)
}
```

### File System Controls

```r
# Example file access checking
check_file_access <- function(file_path) {
  # Prevent access to raw data in APP_MODE
  if (OPERATION_MODE == "APP_MODE" && 
      grepl("raw_data|cleansed_data|processed_data", file_path)) {
    stop("Access to ", file_path, " is not allowed in APP_MODE")
  }
  
  # Restrict global data modifications
  if (OPERATION_MODE != "GLOBAL_MODE" && 
      grepl("30_global_data", file_path) && 
      file.access(file_path, 2) == 0) {  # Check write permission
    stop("Modification of global data is only allowed in GLOBAL_MODE")
  }
  
  # Allow access if checks pass
  return(TRUE)
}
```

## Best Practices

### 1. Explicit Mode Declaration

Always explicitly set and verify the operation mode:

```r
# At the start of every script
OPERATION_MODE <- "UPDATE_MODE"  # Choose appropriate mode

# Verify initialization completed
if (!exists("INITIALIZATION_COMPLETED") || !INITIALIZATION_COMPLETED) {
  source(file.path("update_scripts", "global_scripts", "00_principles", 
                    paste0("sc_initialization_", tolower(OPERATION_MODE), ".R")))
}
```

### 2. Mode-Appropriate Operations

Respect mode boundaries and only perform operations appropriate to the current mode:

```r
# Good practice - check mode before operation
if (OPERATION_MODE == "APP_MODE") {
  # Read-only operations
  display_data(read_app_data())
} else if (OPERATION_MODE %in% c("UPDATE_MODE", "GLOBAL_MODE")) {
  # Data modification operations
  update_app_data()
}
```

### 3. Mode Testing

Test components in all relevant modes:

```r
# Test function across modes
test_component_in_all_modes <- function(component_name) {
  # Save current mode
  original_mode <- OPERATION_MODE
  
  # Test in APP_MODE
  OPERATION_MODE <- "APP_MODE"
  source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_app_mode.R"))
  test_result_app <- test_component(component_name)
  
  # Test in UPDATE_MODE
  OPERATION_MODE <- "UPDATE_MODE"
  source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))
  test_result_update <- test_component(component_name)
  
  # Restore original mode
  OPERATION_MODE <- original_mode
  source(file.path("update_scripts", "global_scripts", "00_principles", 
                    paste0("sc_initialization_", tolower(OPERATION_MODE), ".R")))
  
  # Return test results
  list(app_mode = test_result_app, update_mode = test_result_update)
}
```

## Conclusion

The Operating Modes principle establishes a clear separation between different execution contexts, enhancing security, maintainability, and functionality of the precision marketing system. By respecting mode boundaries, we ensure that applications run with appropriate access controls and optimized dependencies for their specific purpose.