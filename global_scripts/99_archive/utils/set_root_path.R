# Set Root Path for Precision Marketing Projects
# This script sets up the appropriate root paths for all scripts

# Source the root path configuration
script_path <- dirname(sys.frame(1)$ofile)
source(file.path(script_path, "../config/root_path_config.R"))

# Function to set up all paths needed for the project
setup_project_paths <- function(company_name) {
  # Get the company path
  company_path <- get_company_path(company_name)
  
  # Define all the standard paths
  paths <- list(
    root_path = ROOT_PATH,
    company_path = company_path,
    app_path = file.path(company_path, "precision_marketing_app"),
    data_path = file.path(company_path, "precision_marketing_app", "data"),
    scripts_path = file.path(company_path, "precision_marketing_app", "update_scripts"),
    global_scripts_path = file.path(company_path, "precision_marketing_app", "update_scripts", "global_scripts")
  )
  
  # Create a function to check and create directories if they don't exist
  check_and_create_dir <- function(path) {
    if (!dir.exists(path)) {
      dir.create(path, recursive = TRUE)
      message("Created directory: ", path)
    }
    return(path)
  }
  
  # Check and create all directories
  lapply(paths, check_and_create_dir)
  
  # Return all paths
  return(paths)
}

# Usage example:
# paths <- setup_project_paths("WISER")
# data_dir <- paths$data_path