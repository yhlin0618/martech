# Test script for dbConnectTwoDatabases functionality
# This script follows the R113 four-part script structure

# 1. INITIALIZE
# Load required packages
library(DBI)
library(duckdb)

# Source the db_utils module which includes our database functions
source("../02_db_utils/db_utils.R")

# Define test databases
test_db1_name <- "test_db1"
test_db2_name <- "test_db2"

# Create temporary test databases in the current directory
test_path_list <- list(
  test_db1 = file.path(tempdir(), "test_db1.duckdb"),
  test_db2 = file.path(tempdir(), "test_db2.duckdb")
)

# 2. MAIN
# Test 1: Connect to two databases
cat("\n=== Test 1: Connect to two databases ===\n")
connections <- tryCatch({
  dbConnectTwoDatabases(test_db1_name, test_db2_name, 
                        path_list = test_path_list,
                        verbose = TRUE)
}, error = function(e) {
  cat("Error:", e$message, "\n")
  NULL
})

if (!is.null(connections)) {
  cat("Successfully connected to both databases\n")
  
  # Create test tables in each database
  dbExecute(connections$db1, "CREATE TABLE test_table1 (id INTEGER, name VARCHAR)")
  dbExecute(connections$db2, "CREATE TABLE test_table2 (id INTEGER, value DOUBLE)")
  
  # Insert test data
  dbExecute(connections$db1, "INSERT INTO test_table1 VALUES (1, 'Test1'), (2, 'Test2')")
  dbExecute(connections$db2, "INSERT INTO test_table2 VALUES (1, 10.5), (2, 20.75)")
  
  # Test querying from both databases
  test_data1 <- dbGetQuery(connections$db1, "SELECT * FROM test_table1")
  test_data2 <- dbGetQuery(connections$db2, "SELECT * FROM test_table2")
  
  cat("\nData from test_db1:\n")
  print(test_data1)
  
  cat("\nData from test_db2:\n")
  print(test_data2)
  
  # Test disconnecting
  cat("\n=== Test 2: Disconnect from both databases ===\n")
  disconnect_result <- dbDisconnectTwoDatabases(connections)
  
  if (disconnect_result) {
    cat("Successfully disconnected from both databases\n")
  } else {
    cat("Error disconnecting from databases\n")
  }
}

# Test 3: Error handling with non-existent database
cat("\n=== Test 3: Error handling with non-existent database ===\n")
bad_path_list <- list(
  test_db1 = file.path(tempdir(), "test_db1.duckdb"),
  nonexistent_db = "/path/that/does/not/exist/nonexistent.duckdb"
)

error_test <- tryCatch({
  dbConnectTwoDatabases("test_db1", "nonexistent_db", 
                        path_list = bad_path_list,
                        verbose = TRUE)
  TRUE
}, error = function(e) {
  cat("Expected error caught:", e$message, "\n")
  cat("Error handling works as expected\n")
  FALSE
})

if (error_test) {
  cat("TEST FAILED: Error was not caught properly\n")
  # Make sure to clean up
  if (exists("test_db1", envir = .GlobalEnv)) {
    dbDisconnect(test_db1, shutdown = TRUE)
    rm(test_db1, envir = .GlobalEnv)
  }
}

# 3. TEST
# Define test status based on results
if (exists("test_db1", envir = .GlobalEnv) || exists("test_db2", envir = .GlobalEnv)) {
  test_passed <- FALSE
  cat("\nTEST FAILED: Database connections were not properly closed\n")
} else if (error_test) {
  test_passed <- FALSE
  cat("\nTEST FAILED: Error handling did not work as expected\n")
} else {
  test_passed <- TRUE
  cat("\nTEST PASSED: All tests completed successfully\n")
}

# 4. DEINITIALIZE
# First set final status
final_status <- test_passed

# Clean up test databases
if (file.exists(test_path_list$test_db1)) {
  file.remove(test_path_list$test_db1)
}
if (file.exists(test_path_list$test_db2)) {
  file.remove(test_path_list$test_db2)
}

cat("\nTest script execution completed\n")