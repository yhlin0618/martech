# Test Scripts

This directory contains scripts used for testing and debugging various components of the system following the P16 (Component-wise Testing) principle. These scripts provide isolated testing of individual components to verify functionality without needing to run the entire application.

**Note**: Remember that the git repository is set up in the global_scripts directory, not at the project root. All git commands should be run from the global_scripts directory.

## Available Test Scripts

### Database Utilities
- `test_db_utilities.R`: Tests database connection and disconnection functionality
  - Verifies custom database path configuration
  - Tests connection establishment
  - Creates and queries sample tables
  - Tests proper disconnection and cleanup

### Data Import and Processing
- `test_amazon_sales_import.R`: Tests Amazon sales data import and processing
  - Tests the complete workflow from file import to database storage
  - Demonstrates table creation, data import, and processing
  - Shows connection chaining and proper cleanup

### Database Connection Testing
- `test_dbConnect.R`: Tests database connection handling 
  - Validates connection types and error handling
  - Tests Universal Data Access Pattern (R91) compatibility
  - Verifies connection parameters and options

### Database Conventions
- `test_db_conventions.R`: Tests adherence to database naming conventions
  - Validates table and column naming standards
  - Checks data type consistency
  - Verifies primary key configurations

### Database Update Mode
- `test_db_update_mode.R`: Tests database update mode functionality
  - Verifies proper transaction handling
  - Tests data insertion, updating, and deletion
  - Validates rollback mechanisms

### Initialization Testing
- `test_initialization.R`: Tests the initialization sequence for different operation modes
  - Verifies loading of components in different modes
  - Tests operation mode detection and behavior
  - Validates configuration and environment setup

### Shiny Application Testing
- `rshinyapp/test_db_permission_app.R`: Interactive Shiny app for testing the data access permission system
  - Tests database connections across all three operation modes
  - Validates read/write permissions based on the Data Source Hierarchy Principle
  - Demonstrates permission enforcement for different database types
  - Provides diagnostics for the permission checking system

## Usage

To run a test script:

1. Make sure you're in the project root directory
2. Run the script using Rscript, for example:

```r
Rscript update_scripts/global_scripts/98_test/test_db_utilities.R
```

Or source it directly in R:

```r
# Navigate to project root
setwd("/path/to/precision_marketing_app")

# Run a test script
source("update_scripts/global_scripts/98_test/test_db_utilities.R")
```

## Testing Principles

These test scripts implement the following principles:

- **P16 Component-wise Testing**: Tests individual components in isolation
- **R74 Shiny Test Data**: Uses structured test data with metadata
- **R75 Test Script Initialization**: Follows proper initialization patterns
- **R91 Universal Data Access Pattern**: Tests multiple connection types where applicable

## Notes

- Test scripts are intended for development and testing purposes only
- They create temporary databases and files that are cleaned up after running
- They should not be used in production environments
- Most scripts contain verbose output to help understand what's happening