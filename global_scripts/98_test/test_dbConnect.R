#!/usr/bin/env Rscript

# Script to test dbConnect_from_list function
# This script attempts to connect to the raw_data database
# and reports the results

# Determine APP_DIR
set_app_dir <- function() {
  # Start with current directory
  current_path <- getwd()
  
  # Check if we're in update_scripts or some subdirectory
  if(grepl("update_scripts", current_path)) {
    # Extract path up to precision_marketing_app
    app_dir <- sub("(.*precision_marketing_app).*", "\\1", current_path)
    if(app_dir != current_path) {
      return(app_dir)
    }
  }
  
  # If we're already in precision_marketing_app directory
  if(basename(current_path) == "precision_marketing_app") {
    return(current_path)
  }
  
  # If we couldn't determine APP_DIR, return current directory with warning
  warning("Could not determine APP_DIR, using current directory")
  return(current_path)
}

# Set working directory to APP_DIR
APP_DIR <- set_app_dir()
setwd(APP_DIR)
cat("Working directory set to:", getwd(), "\n")

# Source database utilities
db_utils_path <- file.path("update_scripts", "global_scripts", "02_db_utils", "db_utils.R")
if(file.exists(db_utils_path)) {
  cat("Sourcing database utilities from:", db_utils_path, "\n")
  source(db_utils_path)
  
  # Check if dbConnect_from_list function is now available
  if(exists("dbConnect_from_list")) {
    cat("dbConnect_from_list function is available\n")
    
    # Test the function with different parameters
    cat("\n=== TEST 1: Default parameters ===\n")
    tryCatch({
      con <- dbConnect_from_list("raw_data")
      cat("Connection successful with default parameters\n")
      # Display connection properties
      cat("Is read-only:", DBI::dbIsReadOnly(con), "\n")
      cat("Tables:", paste(DBI::dbListTables(con), collapse=", "), "\n")
      DBI::dbDisconnect(con)
      cat("Connection closed\n")
    }, error = function(e) {
      cat("Error connecting with default parameters:", e$message, "\n")
    })
    
    cat("\n=== TEST 2: Explicit read_only=TRUE ===\n")
    tryCatch({
      con <- dbConnect_from_list("raw_data", read_only = TRUE)
      cat("Connection successful with read_only=TRUE\n")
      # Display connection properties
      cat("Is read-only:", DBI::dbIsReadOnly(con), "\n")
      cat("Tables:", paste(DBI::dbListTables(con), collapse=", "), "\n")
      DBI::dbDisconnect(con)
      cat("Connection closed\n")
    }, error = function(e) {
      cat("Error connecting with read_only=TRUE:", e$message, "\n")
    })
    
    cat("\n=== TEST 3: Explicit read_only=FALSE ===\n")
    tryCatch({
      con <- dbConnect_from_list("raw_data", read_only = FALSE)
      cat("Connection successful with read_only=FALSE\n")
      # Display connection properties
      cat("Is read-only:", DBI::dbIsReadOnly(con), "\n")
      cat("Tables:", paste(DBI::dbListTables(con), collapse=", "), "\n")
      # Try to create a test table to verify write access
      tryCatch({
        DBI::dbExecute(con, "CREATE TABLE IF NOT EXISTS test_write_access (id INTEGER, value TEXT)")
        cat("Successfully created test table - write access confirmed\n")
        # Clean up test table
        DBI::dbExecute(con, "DROP TABLE IF EXISTS test_write_access")
      }, error = function(e) {
        cat("Error creating test table:", e$message, "\n")
      })
      DBI::dbDisconnect(con)
      cat("Connection closed\n")
    }, error = function(e) {
      cat("Error connecting with read_only=FALSE:", e$message, "\n")
    })
    
  } else {
    cat("ERROR: dbConnect_from_list function not found after sourcing db_utils.R\n")
  }
} else {
  cat("ERROR: Database utilities file not found at", db_utils_path, "\n")
}

cat("\nTest script completed\n")