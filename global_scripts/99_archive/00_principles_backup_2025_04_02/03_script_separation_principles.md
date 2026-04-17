# Script Separation Principles

This document outlines the principles that govern the separation of responsibilities between the main update scripts and the global_scripts library. Following these principles ensures maintainability, reusability, and clarity across all project components.

## Core Principles

### 1. Clear Separation of Concerns

- **Update Scripts**: Orchestration and workflow management
- **Global Scripts**: Core functionality and reusable components 

### 2. Simplicity in Update Scripts

Update scripts in the update_scripts directory should:

- Be as simple and concise as possible
- Focus on "what" to do, not "how" to do it
- Contain minimal logic and complexity
- Call functions from global_scripts for actual implementation
- Follow a clear, linear flow that's easy to understand

### 3. Complexity Encapsulation in Global Scripts

Global scripts in the update_scripts/global_scripts directory should:

- Encapsulate all complex logic and functionality
- Be designed for reusability across multiple projects
- Handle their own error checking and validation
- Document their behavior comprehensively
- Be stable and well-tested

## Benefits of This Approach

- **Maintenance**: Changes to functionality happen in one location (global_scripts)
- **Consistency**: All projects using the same global_scripts behave the same way
- **Readability**: Update scripts clearly communicate workflow intent without complex details
- **Testability**: Global functions can be tested independently
- **Scalability**: New update scripts can be created quickly by reusing global functions

## Implementation Guidelines

### For Update Scripts

The ideal update script should:

1. Source the initialization file
2. Set any required parameters or configurations
3. Call global functions to perform the actual work
4. Source the deinitialization file

Example of an ideal update script:

```r
# Initialize the environment
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))

# Connect to databases
# Using functions from fn_database_connect.R
raw_data <- dbConnect_from_list("raw_data", read_only = FALSE)
cleansed_data <- dbConnect_from_list("cleansed_data", read_only = FALSE)

# Define parameters
main_folder <- file.path(raw_data_folder, "amazon_sales")

# Call functions from global_scripts to do the actual work
# These functions are defined in fn_amazon_sales.R
create_or_replace_amazon_sales_dta(raw_data, example_location = file.path(main_folder, "example.xlsx"))
import_amazon_sales(main_folder, raw_data)

# Clean up resources and close connections
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_deinitialization_update_mode.R"))
```

### For Global Scripts Functions

Global scripts functions should:

1. Accept clearly defined parameters
2. Validate all inputs
3. Handle errors gracefully
4. Document behavior comprehensively with roxygen comments
5. Return appropriate results or modified objects

Example of a well-designed global function:

```r
#' Import Amazon Sales Data from Excel Files
#'
#' @param folder_path Character string. Path to the folder containing files.
#' @param connection DBI connection object. Database connection.
#' @param clean_columns Logical. Whether to clean column names. Default TRUE.
#'
#' @return The database connection for chaining.
#' 
#' @examples
#' import_amazon_sales_dta("path/to/files", connection)
import_amazon_sales_dta <- function(folder_path, connection, clean_columns = TRUE) {
  # Input validation
  if (!dir.exists(folder_path)) {
    stop("Folder path does not exist: ", folder_path)
  }
  
  # Function implementation...
  
  # Return result
  return(connection)
}
```

## Anti-Patterns to Avoid

### In Update Scripts

- **Complex Logic**: If you need conditional logic, consider moving it to a global function
- **Duplicate Code**: If similar code appears in multiple update scripts, move it to global_scripts
- **Direct SQL**: Use database utility functions from global_scripts instead
- **Error Handling Logic**: Let global functions handle their own errors appropriately

### In Global Scripts

- **Environment Dependencies**: Don't rely on global variables; accept all needed data as parameters
- **Side Effects**: Be explicit about what the function modifies
- **Hardcoded Paths**: Use parameters instead
- **Missing Documentation**: All global functions must be well documented

## Terminology Glossary

To ensure clarity in discussions about code organization, we define the following terms:

- **Function Library**: A file containing a single exportable function with optional helper functions
- **Execution Script**: A script that executes a specific workflow or process
- **App Section**: A major functional area of a Shiny application (e.g., macro overview, micro customer)
- **Component**: A self-contained, reusable UI-server pair that implements a specific feature
- **Module**: In the context of module mapping, refers to a conceptual group of related functionality
- **Shiny Module**: The technical mechanism in Shiny for creating namespaced UI-server pairs
- **Shiny Component Directory**: The `10_rshinyapp_components` directory that contains all Shiny UI and server components

## Script Naming Conventions

### Update Scripts Naming Convention

Update scripts should follow a structured naming convention that combines execution order with module mapping:

```
AABB_C_D_E_description.R
```

Where:
- **AA**: Bundle group identifier (00-99) - groups related scripts together
- **BB**: Serial number within the bundle (00-99) - defines execution order within a bundle
- **C**: Sub-script identifier (0-9) - allows decomposition of a script into multiple components
- **D_E**: Module reference (e.g., 2_1) - connects script to its corresponding module in documentation
- **description**: Brief descriptive text explaining the script's purpose

#### Examples:

- `0000_0_2_1_import_amazon_sales.R` - First script (00) in bundle 00, main script (0), related to module 2.1
- `0100_0_3_2_generate_reports.R` - First script (00) in bundle 01, main script (0), related to module 3.2
- `0100_1_3_2_generate_quarterly_reports.R` - Second script (01) in bundle 01, main script (0), related to module 3.2
- `0100_0_1_3_2_generate_monthly_reports.R` - First script (00) in bundle 01, first sub-script (1), related to module 3.2

#### Benefits:

- **Execution Order**: Scripts sort correctly in file explorers and execution sequences
- **Module Traceability**: Clear connection to module documentation for context
- **Decomposition Support**: Allows breaking complex processes into sequential sub-scripts
- **Bundle Organization**: Groups related scripts together for better organization
- **Self-Documentation**: Naming structure indicates the script's role and relationship to other components

### Global Scripts Naming Convention

Global scripts should use simple, descriptive names with prefixes that distinguish between function libraries, execution scripts, and Shiny app components:

```
[prefix]_[name].R
```

Where:
- `fn_` - Function libraries that contain reusable functions
- `sc_` - Scripts that execute processes or workflows
- `ui_` - Shiny UI components
- `server_` - Shiny server components

#### Function Library Rules

Function libraries (`fn_` files) should follow the "one function per file" principle:

1. Each file should export exactly one primary function
2. The filename should match the primary exported function name
3. Helper functions can be included but should be internal (not exported)

```
fn_[function_name].R  # Contains function_name() as its primary export
```

This ensures clarity and a one-to-one mapping between files and functions. For example:
- `fn_dbConnect_from_list.R` should contain the `dbConnect_from_list()` function
- `fn_process_customer_time.R` should contain the `process_customer_time()` function

Benefits of this approach:
- Makes dependencies clear and explicit
- Simplifies testing and documentation
- Allows precise importing of only needed functions
- Follows R package development best practices

#### Shiny Component Naming Rules

For Shiny components, split UI and server parts into separate files using a hierarchical naming convention:

```
ui_[section]_[component].R    # Contains the UI component function
server_[section]_[component].R   # Contains the server component function
```

Where:
- **section**: Main app section or module (e.g., "macro", "micro", "model")
- **component**: Specific functionality (e.g., "overview", "customer_profile", "sales_chart")

Each file should expose a single function that follows the standard Shiny module naming convention. This is an implementation of the Package Consistency Principle (see 20_package_consistency_principle.md), where we use camelCase with UI/Server suffixes to maintain consistency with Shiny conventions:

- `ui_micro_customer_profile.R` would export `microCustomerProfileUI()` function
- `server_micro_customer_profile.R` would export `microCustomerProfileServer()` function

Note that while the file name uses snake_case (`ui_micro_customer.R`), the function uses camelCase with suffixes (`microCustomerUI`) to align with Shiny conventions.

#### Examples:

Function libraries:
- `fn_dbConnect_from_list.R` instead of `100g_dbConnect_from_list.R` (contains the `dbConnect_from_list()` function)
- `fn_dbCopyTable.R` instead of `102g_dbCopyTable.R` (contains the `dbCopyTable()` function)
- `fn_customer_dna.R` instead of `DNA_Function_dplyr.R` (contains customer DNA calculation functions)

Execution scripts:
- `sc_process_amazon_sales.R` instead of `205g_process_amazon_sales.R`
- `sc_import_website_sales.R` instead of `300g_import_website_km_sales.R`
- `sc_analyze_reviews.R` instead of `203g_process_amazon_review.R`

Shiny components:
- `ui_micro_customer_profile.R` and `server_micro_customer_profile.R` instead of `micro_customer.R`
- `ui_marketing_sales_dashboard.R` and `server_marketing_sales_dashboard.R` instead of `sales_analysis.R`
- `ui_macro_overview.R` and `server_macro_overview.R` instead of `macro_overview.R`

#### Benefits:

- **Type Distinction**: Clear visual indicator of file purpose
- **Clarity**: Names directly describe the function's purpose
- **Maintainability**: Easier to understand and refactor
- **Organization**: Maintains domain-based directory structure while clarifying file types
- **Consistency**: Aligns with standard R package development practices
- **Progressive Migration**: Can be implemented without restructuring directories

## Conclusion

By maintaining a clear separation between simple update scripts and robust global functions, we create a system that is easier to maintain, understand, and extend. This approach allows new team members to quickly grasp workflow processes while encapsulating complexity in well-defined, reusable components.