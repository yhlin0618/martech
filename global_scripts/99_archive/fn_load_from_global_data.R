#' Load Data from Global Shared Data Directory
#'
#' This function loads data from the shared 30_global_data directory, which contains
#' resources shared across multiple projects. Following the Data Source Hierarchy Principle,
#' this should be used only when app-specific data is not sufficient or when standardization
#' across projects is required.
#'
#' Access permissions are enforced based on the current operating mode:
#' - APP_MODE: Read-only access
#' - UPDATE_MODE: Read-only access
#' - GLOBAL_MODE: Read-write access
#'
#' @param file_name The name of the file to read
#' @param version Version of the data to read (defaults to "current")
#' @param required Whether the file is required. If TRUE and the file doesn't exist, throws an error
#' @param default Default data to return if the file doesn't exist and required is FALSE
#' @param write_mode Whether to open the file in write mode (only allowed in GLOBAL_MODE)
#'
#' @return The data read from the file, with appropriate type based on file extension
#' @export
#'
#' @examples
#' # EXCEPTION: Using 30_global_data shared resource because this
#' # reference data is maintained centrally for all projects
#' industry_codes <- load_from_global_data("industry_codes.rds")
#'
#' # Load a specific version
#' historical_mappings <- load_from_global_data("country_codes.csv", version = "2024-03")
#'
#' # Provide a default if file might not exist
#' optional_rules <- load_from_global_data("business_rules.yaml", required = FALSE,
#'                                          default = list(rules = list()))
load_from_global_data <- function(file_name, version = "current", required = TRUE, default = NULL, write_mode = FALSE) {
  # Check if access is allowed based on the Data Source Hierarchy Principle
  access_type <- if (write_mode) "write" else "read"
  
  # Construct the path for access checking
  base_path <- file.path("update_scripts", "global_scripts", "30_global_data")
  path <- if (version == "current") {
    file.path(base_path, file_name)
  } else {
    file.path(base_path, version, file_name)
  }
  
  # Check access permissions
  if (!check_data_access("global", access_type, path)) {
    stop(access_type, " access to 30_global_data not allowed in current operating mode")
  }
  # Construct the full path - adjust the base path as needed for your project structure
  base_path <- file.path("update_scripts", "global_scripts", "30_global_data")
  
  path <- if (version == "current") {
    file.path(base_path, file_name)
  } else {
    file.path(base_path, version, file_name)
  }
  
  # Add documentation note about using shared resources
  if (interactive()) {
    message("EXCEPTION NOTE: Accessing shared 30_global_data resource: ", file_name)
  }
  
  # Check if file exists
  if (!file.exists(path)) {
    if (required) {
      stop("Required shared file not found: ", path)
    } else {
      message("Optional shared file not found, using default: ", path)
      return(default)
    }
  }
  
  # Read the file based on extension
  tryCatch({
    if (endsWith(tolower(file_name), ".csv")) {
      data <- read.csv(path, stringsAsFactors = FALSE)
    } else if (endsWith(tolower(file_name), ".rds")) {
      data <- readRDS(path)
    } else if (endsWith(tolower(file_name), ".json")) {
      data <- jsonlite::fromJSON(path)
    } else if (endsWith(tolower(file_name), ".yaml") || 
               endsWith(tolower(file_name), ".yml")) {
      # You'll need the yaml package: install.packages("yaml")
      if (requireNamespace("yaml", quietly = TRUE)) {
        data <- yaml::read_yaml(path)
      } else {
        stop("The yaml package is required to read YAML files")
      }
    } else if (endsWith(tolower(file_name), ".xlsx") || 
               endsWith(tolower(file_name), ".xls")) {
      if (requireNamespace("readxl", quietly = TRUE)) {
        data <- readxl::read_excel(path)
      } else {
        stop("The readxl package is required to read Excel files")
      }
    } else {
      # For other file types, try a basic file read
      warning("File type not explicitly supported, using readLines: ", file_name)
      data <- readLines(path)
    }
    
    return(data)
  }, error = function(e) {
    if (required) {
      stop("Error reading shared file ", path, ": ", e$message)
    } else {
      message("Error reading optional shared file, using default: ", path, " - ", e$message)
      return(default)
    }
  })
}