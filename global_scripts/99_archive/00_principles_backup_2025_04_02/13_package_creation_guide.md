# Creating an R Package from Global Scripts

This guide outlines how to turn the global scripts into a proper R package, which would enable proper documentation, dependency management, and easier distribution.

## Why Create a Package?

1. **Documentation** - Generate proper help files from roxygen2 comments
2. **Dependency Management** - Clearly specify and manage package dependencies
3. **Testing Framework** - Implement formal testing
4. **Version Control** - Better manage versions and updates
5. **Distribution** - Easier installation across computers or team members

## Step-by-Step Package Creation

### 1. Install Required Tools

```r
install.packages(c("devtools", "roxygen2", "testthat", "usethis"))
library(devtools)
```

### 2. Initialize Package Structure

```r
# Navigate to a temporary directory
setwd("/path/to/temp/directory")

# Create package skeleton
usethis::create_package("precisionMarketing")
```

### 3. Copy Scripts to Appropriate Locations

The package structure will include:

- `R/` directory for R code
- `man/` directory for documentation (automatically generated)
- `tests/` directory for tests
- `DESCRIPTION` file for package metadata

Organize the global scripts:

```r
# Example: Create subdirectories in R/ to mirror current structure
dir.create("R/db_utils", recursive = TRUE)
dir.create("R/data_processing", recursive = TRUE)
# ... other directories as needed

# Copy scripts (manual process or with a script)
# Make sure to copy only the function definitions, not the script execution parts
```

### 4. Update DESCRIPTION File

Edit the DESCRIPTION file to include:

```
Package: precisionMarketing
Title: Precision Marketing Analysis Tools
Version: 0.1.0
Authors@R: 
    person("Your Name", "Your Role", email = "your.email@example.com", role = c("aut", "cre"))
Description: Tools for precision marketing analysis, including data import,
    processing, and visualization functions.
License: MIT + file LICENSE
Encoding: UTF-8
Roxygen: list(markdown = TRUE)
RoxygenNote: 7.2.3
Imports:
    dplyr,
    duckdb,
    tidyverse,
    openxlsx,
    readxl,
    readr,
    arrow,
    stringr,
    glue,
    dotenv
Suggests:
    testthat (>= 3.0.0)
Config/testthat/edition: 3
```

### 5. Generate Documentation from Roxygen Comments

```r
# Generate documentation from roxygen comments
devtools::document()

# Build the package
devtools::build()

# Install the package locally for testing
devtools::install()
```

### 6. Create Tests

```r
# Set up testing infrastructure
usethis::use_testthat()

# Create tests for functions
usethis::use_test("db_utils")
```

Write tests in the created file (`tests/testthat/test-db_utils.R`):

```r
test_that("dbConnect_from_list connects to database", {
  # Test code here
  # Use temporary test databases
})
```

### 7. Check Package

```r
# Run comprehensive checks on the package
devtools::check()
```

### 8. Using the Packaged Version

After creating the package, functions can be properly documented and used like any R package:

```r
library(precisionMarketing)

# Access help documentation
?dbConnect_from_list

# Use functions
raw_data <- dbConnect_from_list("raw_data")
```

## Integration with Existing Workflow

### Gradual Migration Approach

1. **Start with core utilities** - Convert the most stable, widely-used functions first
2. **Create separate utility packages** - Group related functions (db_utils, data_processing, etc.)
3. **Maintain backward compatibility** - Ensure package functions work with existing scripts
4. **Update workflow scripts** - Gradually update to use the packaged versions

### Package Development Workflow

1. Make changes to package source
2. Run `devtools::document()` to update documentation
3. Run `devtools::load_all()` to load the package in the current session
4. Test changes
5. Run `devtools::check()` to validate the package
6. Install the updated package: `devtools::install()`

## Benefits for the Precision Marketing Project

1. **Clearer function documentation** - All documentation accessible via R's help system
2. **Better function discoverability** - Functions organized by topic in package namespace
3. **Code quality enforcement** - Package checks enforce good practices
4. **Easier onboarding** - New team members can quickly understand available functionality
5. **Reduced environment setup time** - Package dependencies automatically managed