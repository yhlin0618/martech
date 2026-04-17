---
id: "P25"
title: "Authentic Context Testing"
type: "principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "P24": "Deployment Patterns"
  - "MP23": "Data Source Hierarchy"
influences:
  - "P07": "App Construction Principles"
  - "R16": "Bottom-Up Construction Guide"
---

# Authentic Context Testing Principle

This principle establishes the importance of testing components in their authentic execution context rather than in isolation or example environments.

## Core Concept

Components should be tested in the exact environment where they will ultimately run, with the same directory structure, dependencies, and operational conditions they will encounter in actual use.

## Rationale

Testing in authentic contexts reveals issues that may not be apparent in simplified or isolated testing environments:

1. **Path Resolution**: Relative paths may work differently in example folders versus the root directory
2. **Dependency Loading**: The sequence and availability of dependencies may differ in real environments
3. **Configuration Access**: Configuration files and environment variables may be accessed differently
4. **Permission Boundaries**: File system and data access permissions may vary between environments
5. **Initialization States**: The global state after initialization may differ in real environments

## Implementation Guidelines

### 1. Root Directory Testing

Test scripts should be executed from the project root directory to ensure accurate path resolution:

```r
# Correct - running test from root directory
shiny::runApp("update_scripts/global_scripts/98_debug/rshinyapp/test_db_permission_app.R")

# Incorrect - running test from an example directory
setwd("update_scripts/global_scripts/10_rshinyapp_components/examples")
shiny::runApp("app_complete_template.R")  # Different path context!
```

### 2. Initialization Validation

Tests should use the actual initialization sequence that will be used in production:

```r
# Correct - using real initialization script
source("update_scripts/global_scripts/00_principles/sc_initialization_app_mode.R")

# Incorrect - manually setting up partial environment
OPERATION_MODE <- "APP_MODE"  # Missing complete initialization!
```

### 3. Environmental Parity

Development, testing, and production environments should maintain parity in structure:

1. **Directory Structure**: Same hierarchy and naming conventions
2. **File Locations**: Same relative positions of files
3. **Dependency Versions**: Same versions of libraries and dependencies
4. **Configuration Format**: Same configuration file formats and locations

### 4. Application Directory as Root Context

All operations should reference paths relative to the application root directory:

```r
# Correct - paths relative to application root
data_file <- file.path("app_data", "customer_segments.csv")

# Incorrect - assuming current working directory
data_file <- "customer_segments.csv"  # Where is this file?
```

### 5. Working Directory Management

Tests should explicitly set the working directory to the application root if needed:

```r
# If not already at application root
initial_dir <- getwd()
setwd("/path/to/precision_marketing_app")  # Set to application root

# Run tests...

# Restore original directory when done
setwd(initial_dir)
```

## Relationship to Other Principles

This principle works in conjunction with:

1. **Deployment Patterns Principle**: Ensures testing corresponds to deployment reality
2. **Working Directory Guide**: Maintains consistent directory references
3. **Data Source Hierarchy Principle**: Validates correct data access patterns
4. **Operation Modes Principle**: Tests behavior across different operation contexts

## Testing Examples vs. Real Context

Example directories serve different purposes than authentic context testing:

- **Examples**: Demonstrate isolated functionality with minimal dependencies
- **Authentic Tests**: Validate real-world behavior in complete environment

Both have value, but final validation should always occur in authentic contexts.

## Special Case: Portable Applications

For portable applications designed to run in varying environments:

1. Test in all target environments
2. Use absolute paths or environment-aware path resolution
3. Include environment detection and adaptation logic
4. Document environment requirements explicitly

## Test Script Organization

While test scripts should be organized in the debug directory for clarity, they should be executed from the application root:

```r
# Organization: Placed in debug directory
# /update_scripts/global_scripts/98_debug/test_db_utilities.R

# Execution: Run from application root
Rscript update_scripts/global_scripts/98_debug/test_db_utilities.R
```

## Conclusion

By testing in authentic contexts, we ensure that components function correctly in their real operating environment. This principle helps identify integration issues, path resolution problems, and environment-specific behaviors that might otherwise go undetected until deployment.