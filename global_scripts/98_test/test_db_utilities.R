#' Test script for database utilities
#'
#' This script demonstrates the use of improved database utility functions
#' for connecting to and managing DuckDB databases.
#'
#' The script performs the following:
#' 1. Sets up custom database paths
#' 2. Tests connection to multiple databases
#' 3. Creates tables and inserts sample data
#' 4. Tests disconnection utilities
#'
#' @author Precision Marketing Team
#' @date 2025-03-26

# Enable verbose initialization for detailed loading logs
VERBOSE_INITIALIZATION <- TRUE

# Source the initialization script
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))

message("Testing database utilities...")

# Function to create a temporary directory for testing
create_test_dir <- function() {
  # Create a temporary directory
  test_dir <- file.path(tempdir(), "db_utils_test")
  dir.create(test_dir, recursive = TRUE, showWarnings = FALSE)
  message("Created test directory at: ", test_dir)
  return(test_dir)
}

# Create test directory
test_dir <- create_test_dir()

# Test 1: Setting custom database paths
message("\nTest 1: Setting custom database paths")
custom_paths <- list(
  test_db1 = file.path(test_dir, "test_db1.duckdb"),
  test_db2 = file.path(test_dir, "test_db2.duckdb")
)

# Update the database paths with our custom ones
set_db_paths(custom_paths)

# Test 2: Connecting to databases
message("\nTest 2: Connecting to databases")
test_db1 <- dbConnect_from_list("test_db1", read_only = FALSE)
test_db2 <- dbConnect_from_list("test_db2", read_only = FALSE)

# Test 3: Creating tables and inserting data
message("\nTest 3: Creating tables and inserting data")

# Create a sample table in test_db1
tryCatch({
  message("Creating sample_table in test_db1...")
  dbExecute(test_db1, "CREATE TABLE sample_table (id INTEGER, name VARCHAR)")
  dbExecute(test_db1, "INSERT INTO sample_table VALUES (1, 'Test 1'), (2, 'Test 2'), (3, 'Test 3')")
  
  # Query the data
  result <- dbGetQuery(test_db1, "SELECT * FROM sample_table")
  message("Sample data in test_db1:")
  print(result)
}, error = function(e) {
  message("Error creating sample data: ", e$message)
})

# Create a different sample table in test_db2
tryCatch({
  message("Creating another_table in test_db2...")
  dbExecute(test_db2, "CREATE TABLE another_table (id INTEGER, value DOUBLE)")
  dbExecute(test_db2, "INSERT INTO another_table VALUES (1, 10.5), (2, 20.75), (3, 30.25)")
  
  # Query the data
  result <- dbGetQuery(test_db2, "SELECT * FROM another_table")
  message("Sample data in test_db2:")
  print(result)
}, error = function(e) {
  message("Error creating sample data: ", e$message)
})

# Test 4: Testing disconnection
message("\nTest 4: Testing disconnection")

# Disconnect all connections
message("Disconnecting all database connections...")
dbDisconnect_all(remove_vars = TRUE)

# Try to connect again to see if variables were removed
message("\nTest 5: Reconnecting after disconnection")
tryCatch({
  # This should work even if variables were removed
  test_db1 <- dbConnect_from_list("test_db1", read_only = TRUE)
  message("Successfully reconnected to test_db1")
  
  # Check if our table still exists
  if (dbExistsTable(test_db1, "sample_table")) {
    result <- dbGetQuery(test_db1, "SELECT * FROM sample_table")
    message("Data is still in test_db1:")
    print(result)
  } else {
    message("Table does not exist in test_db1")
  }
}, error = function(e) {
  message("Error reconnecting: ", e$message)
}, finally = {
  # Final cleanup
  dbDisconnect_all()
})

message("\nDatabase utilities testing completed")

# Cleanup the test directory
if (file.exists(file.path(test_dir, "test_db1.duckdb"))) {
  file.remove(file.path(test_dir, "test_db1.duckdb"))
}
if (file.exists(file.path(test_dir, "test_db2.duckdb"))) {
  file.remove(file.path(test_dir, "test_db2.duckdb"))
}
message("Cleaned up test database files")