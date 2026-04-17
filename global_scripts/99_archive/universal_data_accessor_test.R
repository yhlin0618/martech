#' Universal Data Accessor Test Script
#' 
#' This script tests the universal_data_accessor function with a focus on DBI connections,
#' which is the most critical use case for the Precision Marketing application.
#'
#' @implements MP16 Modularity 
#' @implements MP17 Separation of Concerns
#' @implements R91 Universal Data Access Pattern
#' @implements R92 Universal DBI Approach
#' @implements R76 Module Data Connection
#' @implements P77 Performance Optimization

# === Setup ===

# Check if required packages are available
required_packages <- c("DBI", "duckdb", "testthat")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("Missing required packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("Install them using: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))\n")
  cat("Skipping tests that require these packages.\n")
}

# Source the functions
source("./update_scripts/global_scripts/02_db_utils/fn_universal_data_accessor.R")

# Create test data
test_data <- list(
  customer_profile = data.frame(
    customer_id = 1:3,
    name = c("Customer A", "Customer B", "Customer C"),
    email = c("a@example.com", "b@example.com", "c@example.com"),
    stringsAsFactors = FALSE
  ),
  
  sales_dta = data.frame(
    customer_id = c(1, 1, 2, 3, 3, 3),
    order_id = 101:106,
    amount = c(50, 25, 75, 30, 45, 60),
    stringsAsFactors = FALSE
  )
)

# === Test Functions ===

# Test DBI connection types
test_dbi_connection <- function() {
  cat("\n=== Testing DBI Connection Handling ===\n")
  
  if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
    cat("DBI or duckdb package not available. Skipping DBI tests.\n")
    return(invisible(NULL))
  }
  
  # Create in-memory DuckDB connection
  cat("Creating in-memory DuckDB connection...\n")
  
  con <- tryCatch({
    DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  }, error = function(e) {
    cat("Failed to create DuckDB connection:", e$message, "\n")
    return(NULL)
  })
  
  if (is.null(con)) {
    cat("Could not create DuckDB connection. Skipping tests.\n")
    return(invisible(NULL))
  }
  
  # Create test tables in the database
  tryCatch({
    DBI::dbWriteTable(con, "customer_profile", test_data$customer_profile, overwrite = TRUE)
    DBI::dbWriteTable(con, "sales_dta", test_data$sales_dta, overwrite = TRUE)
    
    # Test 1: Standard table access
    cat("\n1. Testing standard table access...\n")
    result1 <- universal_data_accessor(con, "customer_profile", log_level = 1)
    if (is.data.frame(result1) && nrow(result1) == 3) {
      cat("   ✓ Standard table access test passed\n")
    } else {
      cat("   ✗ Standard table access test failed\n")
    }
    
    # Test 2: Table with _dta suffix
    cat("\n2. Testing _dta suffix handling...\n")
    result2 <- universal_data_accessor(con, "sales", log_level = 1)
    if (is.data.frame(result2) && nrow(result2) == 6) {
      cat("   ✓ _dta suffix handling test passed\n")
    } else {
      cat("   ✗ _dta suffix handling test failed\n")
    }
    
    # Test 3: Custom query template
    cat("\n3. Testing custom query template...\n")
    # First ensure we have some data with customer_id = 1
    DBI::dbExecute(con, "CREATE OR REPLACE TABLE sales_test AS SELECT * FROM sales_dta WHERE customer_id = 1")
    
    query_template <- "SELECT * FROM sales_test"
    result3 <- universal_data_accessor(con, "ignored_table_name", query_template = query_template, log_level = 1)
    if (is.data.frame(result3) && nrow(result3) > 0 && all(result3$customer_id == 1)) {
      cat("   ✓ Custom query template test passed\n")
    } else {
      cat("   ✗ Custom query template test failed\n")
    }
    
    # Test 4: Non-existent table
    cat("\n4. Testing non-existent table handling...\n")
    result4 <- universal_data_accessor(con, "non_existent_table", log_level = 0)
    if (is.null(result4)) {
      cat("   ✓ Non-existent table test passed\n")
    } else {
      cat("   ✗ Non-existent table test failed\n")
    }
    
    # Test 5: Check if S4 handling is working correctly
    cat("\n5. Testing S4 class handling...\n")
    # For DuckDB and most DBI drivers, connections are S4 objects
    is_s4 <- isS4(con)
    cat("   Connection is", if (is_s4) "an S4 object" else "not an S4 object", "\n")
    
    # Use direct S4 method call to read a table for comparison
    direct_result <- tryCatch({
      DBI::dbReadTable(con, "customer_profile")
    }, error = function(e) NULL)
    
    # Use universal_data_accessor with explicit logging
    ua_result <- universal_data_accessor(con, "customer_profile", log_level = 3)
    
    if (is.data.frame(ua_result) && 
        is.data.frame(direct_result) && 
        nrow(ua_result) == nrow(direct_result)) {
      cat("   ✓ S4 handling test passed\n")
    } else {
      cat("   ✗ S4 handling test failed\n")
    }
    
    # Test 6: Verify tbl() access method is working (R100)
    cat("\n6. Testing tbl() access method (R100)...\n")
    
    # Ensure dplyr is loaded for this test
    if (!requireNamespace("dplyr", quietly = TRUE)) {
      cat("   dplyr package is not available. Skipping tbl() test.\n")
    } else {
      # Set log level to 4 to see detailed debug information
      tbl_result <- universal_data_accessor(con, "customer_profile", log_level = 4)
      
      # Verify tbl() result matches direct result
      if (is.data.frame(tbl_result) && nrow(tbl_result) == nrow(direct_result)) {
        cat("   ✓ tbl() access method test passed\n")
      } else {
        cat("   ✗ tbl() access method test failed\n")
      }
      
      # Create a temp table with a filter to test SQL queries with tbl()
      DBI::dbExecute(con, "CREATE OR REPLACE TABLE filtered_customers AS SELECT * FROM customer_profile WHERE customer_id = 1")
      
      # Test custom query with tbl() and sql()
      query_template <- "SELECT * FROM filtered_customers"
      query_result <- universal_data_accessor(con, "ignored", query_template = query_template, log_level = 4)
      
      if (is.data.frame(query_result) && nrow(query_result) > 0) {
        cat("   ✓ tbl() with SQL query test passed\n")
      } else {
        cat("   ✗ tbl() with SQL query test failed\n")
      }
    }
    
  }, error = function(e) {
    cat("Error in DBI test:", e$message, "\n")
  }, finally = {
    # Clean up
    tryCatch({
      DBI::dbDisconnect(con)
    }, error = function(e) {
      cat("Error disconnecting:", e$message, "\n")
    })
  })
}

# Test S3-based mock DBI connection
test_mock_dbi_connection <- function() {
  cat("\n=== Testing Mock DBI Connection ===\n")
  
  # Create a simple direct mock DBI connection without using fn_list_to_mock_dbi.R
  cat("Creating simple mock DBI connection...\n")
  
  # Create a more compatible mock DBI connection that handles queries properly
  # and supports the tbl() interface for R100
  simple_mock_con <- list(
    query = function(query_text) {
      # Add basic parsing for SELECT * FROM table
      
      # First check if it's a WHERE customer_id = 1 query (must check this first!)
      if (grepl("WHERE\\s+customer_id\\s*=\\s*1", query_text, ignore.case = TRUE)) {
        # Handle WHERE clause for customer_id = 1
        filtered <- test_data$sales_dta[test_data$sales_dta$customer_id == 1, ]
        return(filtered)
      } else if (grepl("SELECT\\s+\\*\\s+FROM\\s+customer_profile", query_text, ignore.case = TRUE)) {
        return(test_data$customer_profile)
      } else if (grepl("SELECT\\s+\\*\\s+FROM\\s+sales", query_text, ignore.case = TRUE)) {
        return(test_data$sales_dta)
      } else {
        stop("Unsupported query format: ", query_text)
      }
    },
    # Provide standard DBI-style interface
    dbGetQuery = function(query) {
      # Just delegate to the query function
      return(simple_mock_con$query(query))
    },
    dbReadTable = function(name) {
      if (name == "customer_profile") {
        return(test_data$customer_profile)
      } else if (name == "sales_dta" || name == "sales") {
        return(test_data$sales_dta)
      } else {
        stop("Table not found: ", name)
      }
    },
    dbListTables = function() {
      return(c("customer_profile", "sales_dta"))
    },
    dbExistsTable = function(name) {
      return(name %in% c("customer_profile", "sales_dta", "sales"))
    },
    # Support for dplyr tbl() interface (basic)
    sql_render = function(sql) {
      return(as.character(sql))
    },
    # Make the connection itself callable as a function for dbplyr
    .Call = function(...) {
      return(NULL)  # Simplified stub for dbplyr internals
    }
  )
  
  # Add direct dplyr tbl support
  # This simulates enough of the dplyr/dbplyr interface for our tests
  simple_mock_con$tbl <- function(table_name) {
    if (table_name == "customer_profile") {
      return(test_data$customer_profile)
    } else if (table_name == "sales_dta" || table_name == "sales") {
      return(test_data$sales_dta)
    } else {
      stop("Table not found for tbl(): ", table_name)
    }
  }
  
  class(simple_mock_con) <- c("mock_dbi_connection", "DBIConnection", "list")
  
  # Test 1: Standard access with mock DBI
  cat("\n1. Testing standard table access with mock DBI...\n")
  mock_result1 <- universal_data_accessor(simple_mock_con, "customer_profile", log_level = 1)
  if (is.data.frame(mock_result1) && nrow(mock_result1) == 3) {
    cat("   ✓ Standard table access test passed\n")
  } else {
    cat("   ✗ Standard table access test failed\n")
  }
  
  # Test 2: _dta suffix handling with mock DBI
  cat("\n2. Testing _dta suffix handling with mock DBI...\n")
  mock_result2 <- universal_data_accessor(simple_mock_con, "sales", log_level = 1)
  if (is.data.frame(mock_result2) && nrow(mock_result2) == 6) {
    cat("   ✓ _dta suffix handling test passed\n")
  } else {
    cat("   ✗ _dta suffix handling test failed\n")
  }
  
  # Test 3: With custom query template
  cat("\n3. Testing custom query template with mock DBI...\n")
  # For mock connections we need to use a simpler template that matches our regex pattern
  query_template <- "SELECT * FROM sales WHERE customer_id = 1"
  mock_result3 <- universal_data_accessor(simple_mock_con, "ignored_name", query_template = query_template, log_level = 1)
  
  # Check if result is correct - should contain only rows with customer_id = 1
  if (is.data.frame(mock_result3) && nrow(mock_result3) > 0 && all(mock_result3$customer_id == 1)) {
    cat("   ✓ Custom query template test passed\n")
  } else {
    cat("   ✗ Custom query template test failed\n", 
        if(!is.null(mock_result3)) paste("Got", nrow(mock_result3), "rows"), "\n")
  }
}

# Test basic list accessors which are also common
test_list_accessors <- function() {
  cat("\n=== Testing List-Based Data Accessors ===\n")
  
  # Test direct list access
  cat("\n1. Testing direct list element access...\n")
  list_result <- universal_data_accessor(test_data, "customer_profile", log_level = 1)
  if (is.data.frame(list_result) && nrow(list_result) == 3) {
    cat("   ✓ Direct list element access test passed\n")
  } else {
    cat("   ✗ Direct list element access test failed\n")
  }
  
  # Test _dta suffix handling
  cat("\n2. Testing _dta suffix with list access...\n")
  list_result2 <- universal_data_accessor(test_data, "sales", log_level = 1)
  if (is.data.frame(list_result2) && nrow(list_result2) == 6) {
    cat("   ✓ _dta suffix list access test passed\n")
  } else {
    cat("   ✗ _dta suffix list access test failed\n")
  }
  
  # Test function-based access
  cat("\n3. Testing function-based list access...\n")
  
  # Create a list with accessor functions
  function_list <- list(
    get_customer_profile = function() test_data$customer_profile,
    get_sales = function() test_data$sales_dta
  )
  
  function_result <- universal_data_accessor(function_list, "customer_profile", log_level = 1)
  if (is.data.frame(function_result) && nrow(function_result) == 3) {
    cat("   ✓ Function-based list access test passed\n")
  } else {
    cat("   ✗ Function-based list access test failed\n")
  }
}

# Test R101 Unified tbl-like Data Access Pattern
test_unified_tbl_pattern <- function() {
  cat("\n=== Testing Unified tbl-like Data Access Pattern (R101) ===\n")
  
  # Check if dplyr is available for more comprehensive tests
  has_dplyr <- requireNamespace("dplyr", quietly = TRUE)
  if (!has_dplyr) {
    cat("dplyr package is not available. Some tests will be limited.\n")
  }
  
  # Create test data
  test_customers <- data.frame(
    id = 1:5,
    name = c("A", "B", "C", "D", "E"),
    region = c("East", "West", "East", "North", "South"),
    status = c("active", "inactive", "active", "active", "inactive"),
    value = c(100, 200, 150, 300, 250),
    stringsAsFactors = FALSE
  )
  
  # Create various connection types to test with
  connections <- list(
    # Direct data frame
    data_frame = test_customers,
    
    # List with direct data
    list_direct = list(
      customers = test_customers
    ),
    
    # List with function
    list_function = list(
      get_customers = function() test_customers
    ),
    
    # List with custom named function
    list_custom = list(
      custom_get_customers = function() test_customers
    )
  )
  
  # Add a DBI connection if available
  if (requireNamespace("DBI", quietly = TRUE) && requireNamespace("duckdb", quietly = TRUE)) {
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
    DBI::dbWriteTable(con, "customers", test_customers)
    connections$dbi <- con
  }
  
  # Test each connection type
  results <- list()
  
  for (conn_type in names(connections)) {
    cat(paste("\nTesting", conn_type, "connection with unified tbl pattern:\n"))
    conn <- connections[[conn_type]]
    
    # 1. Test basic data access
    tryCatch({
      # Set log level to 4 to see detailed debugging information
      data <- universal_data_accessor(conn, "customers", log_level = 4)
      
      if (is.data.frame(data) && nrow(data) == nrow(test_customers)) {
        cat(paste("  ✓ Basic data access test passed:", nrow(data), "rows retrieved\n"))
        results[[paste0(conn_type, "_basic")]] <- TRUE
      } else {
        cat("  ✗ Basic data access test failed\n")
        results[[paste0(conn_type, "_basic")]] <- FALSE
      }
    }, error = function(e) {
      cat(paste("  ✗ Basic data access test failed with error:", e$message, "\n"))
      results[[paste0(conn_type, "_basic")]] <- FALSE
    })
    
    # 2. For DBI connections, specifically test tbl() approach
    if (conn_type == "dbi" && requireNamespace("dplyr", quietly = TRUE)) {
      tryCatch({
        # This should be using tbl() internally
        data <- universal_data_accessor(conn, "customers", log_level = 4)
        
        # Compare with direct tbl() usage - avoid pipe operator
        tbl_ref <- dplyr::tbl(conn, "customers")
        direct_tbl <- dplyr::collect(tbl_ref)
        
        if (identical(data, direct_tbl)) {
          cat("  ✓ tbl() comparison test passed\n")
          results[[paste0(conn_type, "_tbl")]] <- TRUE
        } else {
          cat("  ✗ tbl() comparison test failed\n")
          results[[paste0(conn_type, "_tbl")]] <- FALSE
        }
      }, error = function(e) {
        cat(paste("  ✗ tbl() comparison test failed with error:", e$message, "\n"))
        results[[paste0(conn_type, "_tbl")]] <- FALSE
      })
    }
    
    # Clean up DBI connection if used
    if (conn_type == "dbi") {
      DBI::dbDisconnect(conn)
    }
  }
  
  # Summarize results
  cat("\nR101 Unified tbl-like Pattern test summary:\n")
  successes <- sum(unlist(results))
  total <- length(results)
  cat("Passed:", successes, "of", total, "tests (", 
      round(successes/total*100), "%)\n")
  
  return(results)
}

# === Run Tests ===

# Run the tests
cat("\n=== UNIVERSAL DATA ACCESSOR TEST SUITE ===\n")
cat("Testing the universal_data_accessor function with an emphasis on DBI connections\n")
cat("These tests will validate handling of various connection types...\n")

# Test basic list accessors (most reliable)
test_list_accessors()

# Test mock DBI (moderately reliable)
test_mock_dbi_connection()

# Test real DBI (most realistic but requires DBI/duckdb)
test_dbi_connection()

# Test the unified tbl-like pattern (R101)
test_unified_tbl_pattern()

cat("\n=== TEST SUITE COMPLETE ===\n")
cat("Make sure to check the test results above for any failures.\n")
cat("Tests that rely on external packages may be skipped if those packages are not installed.\n")

# Clean up environment
rm(list = ls())
cat("\nTest environment cleaned up.\n")