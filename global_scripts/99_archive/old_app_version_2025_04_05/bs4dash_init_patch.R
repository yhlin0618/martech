# Patch script to add bs4Dash package to initialization
# Following R10_package_consistency_naming and R13_initialization_sourcing principles

# This script should be executed once to update the initialization script
# After executing this script, it should be committed to the repository

# Find the initialization script
init_script_path <- file.path("update_scripts", "global_scripts", "00_principles", 
                            "sc_initialization_app_mode.R")

# Check if the file exists
if (!file.exists(init_script_path)) {
  stop("Initialization script not found at: ", init_script_path)
}

# Read the content of the initialization script
init_script <- readLines(init_script_path)

# Define where to insert the bs4Dash library
# We want to add it after the other Shiny-related packages
shiny_packages_end_line <- grep("library2\\(\"fontawesome\"\\)", init_script)

if (length(shiny_packages_end_line) == 0) {
  stop("Could not find the Shiny packages section in the initialization script")
}

# Define the new library line
bs4dash_line <- "library2(\"bs4Dash\")     # BS4 Dashboard UI components"

# Insert the new line
updated_script <- c(
  init_script[1:shiny_packages_end_line],
  bs4dash_line,
  init_script[(shiny_packages_end_line+1):length(init_script)]
)

# Write the updated script
writeLines(updated_script, init_script_path)

message("Successfully added bs4Dash package to the initialization script at: ", init_script_path)
message("Don't forget to commit this change to the repository.")