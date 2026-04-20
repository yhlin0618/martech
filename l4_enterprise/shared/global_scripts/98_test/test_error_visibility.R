# Test script to reproduce hidden error issue
# This script intentionally contains errors to test error visibility

# Script metadata
script_start_time <- Sys.time()
script_name <- "test_error_visibility"

# Following MAMBA pattern - source autoinit if not available
if (!exists("autoinit", mode = "function")) {
  source(file.path("scripts", "global_scripts", "22_initializations", "sc_Rprofile.R"))
}

# Initialize
cat("=== TESTING ERROR VISIBILITY ===\n")
cat("1. Testing autoinit()...\n")
autoinit()

cat("2. Testing intentional R error...\n")
# This should cause an error
intentional_error <- function() {
  nonexistent_variable + 123
}

cat("3. Calling function that will error...\n")
result <- intentional_error()

cat("4. This line should not be reached if error occurred\n")

# Clean up
autodeinit()