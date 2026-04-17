# Utility Functions

This directory contains utility functions used throughout the Precision Marketing KitchenMAMA project. Each file contains a single utility function with thorough documentation.

## Structure

- One function per file
- File names match function names
- Each file includes roxygen-style documentation

## Usage

You can either source individual utility functions:

```r
source("./scripts/global_scripts/utils/make_names.R")
source("./scripts/global_scripts/utils/clean_column_names.R")
```

Or load all utilities at once using the index file:

```r
source("./scripts/global_scripts/utils/utils.R")
```

## Available Utilities

The following utility functions are available:

### Data Cleaning

- `make_names.R` - Clean column names for R compatibility
- `clean_column_names.R` - Clean column names with specific rules
- `remove_na_strings.R` - Remove NA strings from vectors
- `remove_na_columns.R` - Remove columns with all NA values
- `remove_na_rows_in_columns.R` - Remove rows with NA in specific columns
- `remove_novariation.R` - Remove columns with no variation

### String Manipulation

- `string_to_numeric.R` - Convert strings to numeric values
- `replace_spaces.R` - Replace spaces in strings
- `replace_non_numeric.R` - Replace non-numeric characters
- `caesar_cipher.R` - Simple text encryption

### File Operations

- `safe_get.R` - Safely load RDS files
- `multiplesheets.R` - Handle Excel files with multiple sheets

### Data Analysis

- `generate_dummy_matrix.R` - Generate dummy variable matrices
- `confusin_matrix.R` - Create and analyze confusion matrices
- `find_number_or_nan.R` - Identify numeric vs. NA values

## Naming Conventions

All function names follow the `lower_case_with_underscores` convention to maintain consistency across the project.

## Adding New Functions

When adding a new utility function:

1. Create a new file named after the function
2. Include thorough roxygen documentation
3. Keep functions small and focused on a single task
4. Add tests if possible
5. Update this README to include the new function