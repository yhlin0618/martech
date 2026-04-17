# Utility Functions Index
#
# This file sources all utility functions in the utils directory.
# Source this file to load all utility functions at once.

# Get the directory of this script
utils_dir <- dirname(normalizePath(sys.frame(1)$ofile))

# List all R files in the directory except this one
r_files <- list.files(
  path = utils_dir, 
  pattern = "\\.R$", 
  full.names = TRUE
)

# Remove this file from the list
r_files <- r_files[!grepl("utils\\.R$", r_files)]

# Source each file
for (file in r_files) {
  source(file)
}

# Print a message indicating success
message("Loaded ", length(r_files), " utility functions.")