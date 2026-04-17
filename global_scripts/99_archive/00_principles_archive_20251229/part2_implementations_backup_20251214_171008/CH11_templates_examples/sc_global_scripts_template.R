# =============================================================================
# Script Template for Global Scripts
# Purpose: Standard template for creating new scripts in global_scripts
# Usage: Copy this template and modify for your specific needs
# =============================================================================

# --- Script Metadata ---
# Script Name: sc_[descriptive_name].R
# Author: [Your Name]
# Date Created: [YYYY-MM-DD]
# Date Modified: [YYYY-MM-DD]
# Dependencies: List required packages and scripts
# Related Principles: List relevant MP/P/R principles

# --- Initialization ---
# For update scripts that need full environment
# autoinit()

# For scripts that only need specific connections
# dbConnect_from_list("app_data")
# dbConnect_from_list("raw_data")

# --- Load Required Libraries ---
# Only load what you need
# library(data.table)
# library(cli)

# --- Source Required Functions ---
# Use source_directory for entire folders (after autoinit())
# source_directory(file.path(GLOBAL_DIR, "04_utils"))

# Or source specific functions (after autoinit())
# source(file.path(GLOBAL_DIR, "04_utils", "fn_specific_function.R"))

# --- Configuration ---
# Define any configuration variables
# config <- list(
#   param1 = "value1",
#   param2 = 100
# )

# --- Main Functions ---
# Define your main functions here
# Follow R21: One Function One File for utility functions
# Follow R69: Function File Naming (fn_function_name.R)

fn_example_function <- function(data, param1 = "default") {
  # Function documentation
  # @param data: Input data (data.table/data.frame)
  # @param param1: Parameter description
  # @return: Processed data
  
  # Validate inputs
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame or data.table")
  }
  
  # Process data
  result <- data
  
  # Return result
  return(result)
}

# --- Main Execution ---
# Wrap main execution in tryCatch for error handling
tryCatch({
  
  # Step 1: Description
  cli::cli_h2("Step 1: Loading Data")
  cli::cli_alert_info("Loading data from source...")
  
  # Your code here
  
  # Step 2: Description
  cli::cli_h2("Step 2: Processing Data")
  cli::cli_alert_info("Processing data...")
  
  # Your code here
  
  # Step 3: Description
  cli::cli_h2("Step 3: Saving Results")
  cli::cli_alert_success("Results saved successfully")
  
}, error = function(e) {
  cli::cli_alert_danger("Error: {e$message}")
  # Log error or additional handling
  stop("Script execution failed")
})

# --- Cleanup ---
# Remove temporary objects
# rm(list = ls(pattern = "^temp_"))

# Close database connections if opened manually
# if (exists("conn")) dbDisconnect(conn)

# --- Deinitialization ---
# If using autoinit(), always close with autodeinit()
# autodeinit()

# =============================================================================
# Script Guidelines and Best Practices
# =============================================================================

# 1. File Naming Conventions:
#    - sc_*.R for executable scripts
#    - fn_*.R for function files
#    - Use descriptive names with underscores

# 2. Principle Compliance:
#    - MP47: Functional Programming - Use functions over imperative code
#    - R21: One Function One File - Utility functions in separate files
#    - R69: Function File Naming - Prefix with fn_
#    - MP81: Explicit Parameter Specification - Use named parameters
#    - R49: Apply Over Loops - Use vectorized operations

# 3. Error Handling:
#    - Always use tryCatch for main execution
#    - Provide informative error messages
#    - Clean up resources in error cases

# 4. Documentation:
#    - Include script metadata at the top
#    - Document function parameters and returns
#    - Add inline comments for complex logic

# 5. Database Operations:
#    - Use dbConnect_from_list() for standard connections
#    - Always close connections when done
#    - Use transactions for multiple write operations

# 6. Progress Reporting:
#    - Use cli package for consistent messaging
#    - cli::cli_h1/h2/h3 for section headers
#    - cli::cli_alert_* for status messages
#    - cli::cli_progress_bar for long operations

# 7. Security:
#    - Never hardcode credentials
#    - Use Sys.getenv() for sensitive data
#    - Clear sensitive variables after use

# 8. Performance:
#    - Use data.table for large datasets
#    - Vectorize operations when possible
#    - Profile code for bottlenecks

# 9. Testing:
#    - Include basic validation checks
#    - Test edge cases
#    - Consider creating test scripts

# 10. Version Control:
#     - Make atomic commits
#     - Write clear commit messages
#     - Reference related issues/principles