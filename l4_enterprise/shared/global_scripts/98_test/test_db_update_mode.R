#!/usr/bin/env Rscript

# Script to test dbConnect_from_list function in UPDATE_MODE
# This script properly initializes the update environment and tests database connections

# Initialize the update environment
source(file.path("update_scripts", "global_scripts", "000g_initialization_update_mode.R"))

# Set operation mode if not already set
if(!exists("OPERATION_MODE")) {
  OPERATION_MODE <- "UPDATE_MODE"
  cat("OPERATION_MODE was not set, manually set to:", OPERATION_MODE, "\n")
} else {
  cat("Operation mode:", OPERATION_MODE, "\n")
}
cat("\n")

# Check if dbConnect_from_list exists and its argument names
cat("Checking dbConnect_from_list function...\n")
if(exists("dbConnect_from_list")) {
  cat("dbConnect_from_list function exists\n")
  # Check function arguments
  args <- formals(dbConnect_from_list)
  cat("Function parameters:", paste(names(args), collapse=", "), "\n")
  
  # Check if read_only is a valid parameter
  has_read_only <- "read_only" %in% names(args)
  cat("Has read_only parameter:", has_read_only, "\n\n")
} else {
  cat("dbConnect_from_list function not found\n\n")
}

# Check if db_path_list exists
cat("Checking db_path_list...\n")
if(exists("db_path_list")) {
  cat("db_path_list exists with paths:\n")
  print(db_path_list)
} else {
  cat("db_path_list not found, creating it...\n")
  db_path_list <- list(
    "raw_data" = file.path("data", "raw_data.duckdb"),
    "app_data" = file.path("data", "app_data.duckdb"),
    "processed_data" = file.path("data", "processed_data.duckdb")
  )
  print(db_path_list)
}
cat("\n")

# Test connection with appropriate arguments
cat("=== Testing dbConnect_from_list with appropriate arguments ===\n")
tryCatch({
  # Determine which arguments to use based on function definition
  if(has_read_only) {
    cat("Using read_only parameter...\n")
    con <- dbConnect_from_list("raw_data", read_only = FALSE)
  } else {
    cat("Using without read_only parameter...\n")
    con <- dbConnect_from_list("raw_data")
  }
  
  # Check connection properties
  cat("Connection successful\n")
  if(inherits(con, "DBIConnection")) {
    is_readonly <- tryCatch({
      DBI::dbIsReadOnly(con)
    }, error = function(e) {
      cat("Error checking read-only status:", e$message, "\n")
      return(NA)
    })
    
    cat("Is read-only:", is_readonly, "\n")
    
    tables <- tryCatch({
      DBI::dbListTables(con)
    }, error = function(e) {
      cat("Error listing tables:", e$message, "\n")
      return(character(0))
    })
    
    cat("Tables:", paste(tables, collapse=", "), ifelse(length(tables) == 0, "none", ""), "\n")
    
    # Try to write to test write access
    cat("Testing write access...\n")
    write_result <- tryCatch({
      DBI::dbExecute(con, "CREATE TABLE IF NOT EXISTS test_write_access (id INTEGER, value TEXT)")
      DBI::dbExecute(con, "INSERT INTO test_write_access VALUES (1, 'test')")
      DBI::dbExecute(con, "DROP TABLE IF EXISTS test_write_access")
      TRUE
    }, error = function(e) {
      cat("Write test failed:", e$message, "\n")
      FALSE
    })
    
    cat("Write access test:", ifelse(write_result, "Successful", "Failed"), "\n")
  } else {
    cat("Connection object is not a DBIConnection\n")
  }
}, error = function(e) {
  cat("Error connecting to database:", e$message, "\n")
})

# Close all connections
if(exists("dbDisconnect_all")) {
  dbDisconnect_all()
} else {
  # Close individual connections
  if(exists("con1") && inherits(con1, "DBIConnection")) DBI::dbDisconnect(con1)
  if(exists("con2") && inherits(con2, "DBIConnection")) DBI::dbDisconnect(con2)  
  if(exists("con3") && inherits(con3, "DBIConnection")) DBI::dbDisconnect(con3)
}

# Clean up the environment
source(file.path("update_scripts", "global_scripts", "001g_deinitialization_update_mode.R"))

cat("\nTest script completed\n")