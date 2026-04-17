#' Universal Data Accessor S4 Patch (Deprecated)
#' 
#' This file is now deprecated as the S4 connection handling has been integrated
#' directly into the main fn_universal_data_accessor.R file.
#'
#' This file is kept for reference and backward compatibility.
#'
#' @implements R91 Universal Data Access Pattern
#' @implements R92 Universal DBI Approach
#' @implements R93 Function Location Rule

# Point users to the main file
cat("NOTE: The universal_data_accessor function patch has been integrated into the main function.\n")
cat("      Please source 'fn_universal_data_accessor.R' directly instead of this patch file.\n")

# Source the main file
main_file_path <- "./update_scripts/global_scripts/02_db_utils/fn_universal_data_accessor.R"
relative_file_path <- "fn_universal_data_accessor.R"

# Try both absolute and relative paths
if (file.exists(main_file_path)) {
  cat("Sourcing the main universal_data_accessor file...\n")
  source(main_file_path)
} else if (file.exists(relative_file_path)) {
  cat("Sourcing the main universal_data_accessor file (relative path)...\n")
  source(relative_file_path)
} else {
  warning("Could not find the main universal_data_accessor file. Please ensure it's in the correct directory.")
}