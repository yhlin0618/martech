# =============================================================================
# Function: fn_[function_name]
# Purpose: [Brief description of what this function does]
# Author: [Your Name]
# Date Created: [YYYY-MM-DD]
# Related Principles: R21, R69, MP47, MP81
# =============================================================================

#' [Function Title]
#'
#' [Detailed description of what the function does, when to use it,
#' and any important considerations]
#'
#' @param data Primary input data (data.table/data.frame/other)
#' @param param1 Description of parameter 1 (default: value)
#' @param param2 Description of parameter 2 (default: NULL)
#' @param verbose Show progress messages (default: TRUE)
#' @param ... Additional parameters passed to subfunctions
#'
#' @return [Description of what the function returns]
#'
#' @examples
#' \dontrun{
#' # Example 1: Basic usage
#' result <- fn_function_name(data = my_data, param1 = "value")
#' 
#' # Example 2: With optional parameters
#' result <- fn_function_name(
#'   data = my_data,
#'   param1 = "value",
#'   param2 = 100,
#'   verbose = FALSE
#' )
#' }
#'
#' @export
fn_function_name <- function(data, 
                           param1 = "default_value",
                           param2 = NULL,
                           verbose = TRUE,
                           ...) {
  
  # --- Input Validation ---
  if (!is.data.frame(data)) {
    stop("Input 'data' must be a data.frame or data.table")
  }
  
  if (nrow(data) == 0) {
    warning("Input data is empty, returning empty result")
    return(data.table())
  }
  
  # Validate param1
  if (!is.character(param1) || length(param1) != 1) {
    stop("param1 must be a single character string")
  }
  
  # Validate param2 if provided
  if (!is.null(param2) && !is.numeric(param2)) {
    stop("param2 must be numeric or NULL")
  }
  
  # --- Setup ---
  # Convert to data.table for efficient processing
  if (!is.data.table(data)) {
    data <- as.data.table(data)
  }
  
  # Create a copy to avoid modifying input
  dt <- copy(data)
  
  # --- Main Processing ---
  if (verbose) {
    cli::cli_h3("Processing {nrow(dt)} records")
  }
  
  # Step 1: [Description]
  if (verbose) cli::cli_alert_info("Step 1: [What this step does]")
  
  # Example: Add calculated column
  dt[, new_column := some_calculation]
  
  # Step 2: [Description]
  if (verbose) cli::cli_alert_info("Step 2: [What this step does]")
  
  # Example: Filter based on condition
  if (!is.null(param2)) {
    dt <- dt[value > param2]
    if (verbose) {
      cli::cli_alert_success("Filtered to {nrow(dt)} records")
    }
  }
  
  # Step 3: [Description]
  if (verbose) cli::cli_alert_info("Step 3: [What this step does]")
  
  # Example: Group and summarize
  result <- dt[, .(
    count = .N,
    total = sum(value, na.rm = TRUE),
    avg = mean(value, na.rm = TRUE)
  ), by = .(category = param1)]
  
  # --- Error Handling for Complex Operations ---
  # tryCatch({
  #   # Complex operation that might fail
  #   result <- complex_operation(dt)
  # }, error = function(e) {
  #   cli::cli_alert_danger("Error in complex operation: {e$message}")
  #   # Return safe default or rethrow
  #   stop("Failed to process data: ", e$message)
  # })
  
  # --- Final Validation ---
  if (nrow(result) == 0) {
    warning("Processing resulted in empty dataset")
  }
  
  # --- Return ---
  if (verbose) {
    cli::cli_alert_success("Function completed successfully")
  }
  
  return(result)
}

# =============================================================================
# Helper Functions (if needed)
# =============================================================================

# Note: Following R21, helper functions should be in separate files
# Only include here if they are truly internal and not reusable

.internal_helper <- function(x) {
  # Internal helper function (note the . prefix)
  # Not exported, only used within this file
  return(x * 2)
}

# =============================================================================
# Function Guidelines
# =============================================================================

# 1. Naming (R69):
#    - File: fn_descriptive_name.R
#    - Function: fn_descriptive_name()
#    - Use snake_case, be descriptive

# 2. Parameters (MP81):
#    - Always use explicit parameter names
#    - Provide sensible defaults
#    - Document all parameters

# 3. Error Handling:
#    - Validate inputs early
#    - Provide informative error messages
#    - Handle edge cases gracefully

# 4. Performance:
#    - Use data.table for large datasets
#    - Avoid unnecessary copies
#    - Vectorize operations

# 5. Documentation:
#    - Use roxygen2 format
#    - Include examples
#    - Document return value

# 6. Testing:
#    - Consider edge cases
#    - Test with various input types
#    - Create separate test file if needed

# 7. Dependencies:
#    - Minimize external dependencies
#    - Use :: for external functions if used sparingly
#    - Load packages at script level, not function level