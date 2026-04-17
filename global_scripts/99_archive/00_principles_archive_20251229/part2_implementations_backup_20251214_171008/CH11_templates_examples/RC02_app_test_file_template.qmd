---
id: "RC02"
title: "App Test File Template"
type: "rule-composite"
date_created: "2025-04-10"
date_modified: "2025-04-10"
author: "Development Team"
extends:
  - "MP31": "Initialization First"
  - "P16": "Component Testing"
  - "R75": "Test Script Initialization"
  - "R91": "Universal Data Access Pattern"
dependencies:
  - "P15": "Debug Efficiency Exception"
aliases:
  - Test File Structure
  - Component Test Template
key_terms:
  - test initialization
  - APP_MODE testing
  - component validation
---

# RC02: App Test File Template

## Core Statement

All test files for app components must follow a standardized template that ensures proper initialization in APP_MODE, follows universal data access patterns, and implements comprehensive validation procedures.

## Rationale

Standardizing test file structure ensures that all components are tested consistently in an environment that mimics production, reduces errors due to improper initialization, and provides a clear path for validating component functionality across different contexts.

## Implementation Rules

### 1. Basic File Structure

All test files must include:

1. A standardized roxygen-style header with proper principles documentation
2. Explicit APP_MODE initialization section 
3. Clear separation between initialization, data generation, and app definition
4. Comprehensive testing function(s) with both UI and server components
5. Multiple test scenarios covering common use cases

### 2. Mandatory Initialization in APP_MODE

All component tests must:

1. Set `OPERATION_MODE <- "APP_MODE"` at the beginning of the file
2. Handle initialization flags properly (`INITIALIZATION_COMPLETED`, `INITIALIZATION_IN_PROGRESS`)
3. Source the component file being tested after setting the mode
4. Complete initialization with `INITIALIZATION_COMPLETED <- TRUE`
5. Not rely on any state from global environment or other sources

### 3. Universal Data Access Implementation

All test data connections must:

1. Follow R91 (Universal Data Access Pattern)
2. Implement reactive data sources using a consistent pattern
3. Provide sample data that exercises all component features
4. Include edge cases for data validation (empty, partial, malformed)
5. Document data requirements in comments

### 4. Test Scenarios

Each test file must include explicit test scenarios for:

1. Basic functionality with valid data
2. Handling of edge cases and invalid data
3. UI interactivity and reactivity
4. Performance considerations for larger datasets
5. Integration with related components (when applicable)

## Template Structure

```r
#' @title Test Script for [Component] Module
#' @description This script provides a Shiny app to test the [Component] module
#' @principle MP31 Initialization First
#' @principle P16 Component Testing
#' @principle R75 Test Script Initialization
#' @principle R91 Universal Data Access Pattern
#' @principle [Other Relevant Principles]

# === Initialization Section ===
# Initialize in APP_MODE using the standard initialization script
init_script_path <- file.path("update_scripts", "global_scripts", "00_principles", 
                            "sc_initialization_app_mode.R")
source(init_script_path)

# Add any additional required packages not loaded by initialization script
# These should be minimal as most packages should come from the initialization script

# Source the module - follows MP31 (Initialization First)
source("[ComponentName].R")

# === Sample Data Generation Section ===
generate_sample_data <- function() {
  # Generate realistic test data
  # Include edge cases and a variety of scenarios
  
  return(sample_data)
}

# === Test App Function ===
test_app <- function() {
  # Verify APP_MODE is set (should already be set by initialization script)
  if (!exists("OPERATION_MODE") || OPERATION_MODE != "APP_MODE") {
    message("OPERATION_MODE not set to APP_MODE. Re-initializing...")
    init_script_path <- file.path("update_scripts", "global_scripts", "00_principles", 
                              "sc_initialization_app_mode.R")
    source(init_script_path)
  }
  
  # Generate sample data
  sample_data <- generate_sample_data()
  
  # Create a reactive data connection (R91 Universal Data Access Pattern)
  data_connection <- reactive({
    list(
      [data_name] = sample_data
    )
  })
  
  # Define UI
  ui <- bs4Dash::dashboardPage(
    # UI definition with test controls
    # Include filter controls and display areas
  )
  
  # Define server
  server <- function(input, output, session) {
    # Initialize and run the module
    result <- [ComponentName]Server("test_module", data_connection)
    
    # Validation logic and observers
    # Testing-specific behavior
  }
  
  # Initialization should already be complete from the initialization script
  # No need to set INITIALIZATION_COMPLETED manually
  
  # Return the Shiny app
  shinyApp(ui, server)
}

# === Test Scenarios Section ===
# Document test scenarios here
# 1. Basic functionality test
# 2. Edge case tests
# 3. Integration tests

# === Run Application ===
if (interactive()) {
  # Enable verbose mode for debugging
  VERBOSE_INITIALIZATION <- TRUE
  message("Starting [ComponentName] test application in APP_MODE...")
  test_app()
}
```

## Integration with Existing Rules

This Rule Composite (RC02) builds upon:

- **MP31 (Initialization First)**: By ensuring proper initialization sequencing in test files
- **P16 (Component Testing)**: By standardizing the component testing approach
- **R75 (Test Script Initialization)**: By defining specific initialization requirements for test scripts
- **R91 (Universal Data Access Pattern)**: By enforcing consistent data access patterns in test files

## Related Rule Revisions

The following rules should be updated to ensure consistency with this template:

1. **R75 (Test Script Initialization)**: Add explicit requirement for APP_MODE initialization
2. **P16 (Component Testing)**: Add reference to standardized test template
3. **MP31 (Initialization First)**: Add specific section on test file initialization

## Benefits

Implementing this standardized test file template:

1. Ensures consistent testing across all components
2. Reduces initialization-related bugs and inconsistencies
3. Makes tests more maintainable and easier to understand
4. Provides a clear path for new developers to create component tests
5. Ensures tests run in an environment that matches production

## Examples

### Basic Test File Implementation

See the following implementations for reference:
- `/update_scripts/global_scripts/10_rshinyapp_components/macro/macroTrend/macroTrend_test.R`
- `/update_scripts/global_scripts/10_rshinyapp_components/micro/microCustomer/microCustomer_test.R`