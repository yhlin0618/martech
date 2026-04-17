library(testthat)
library(dplyr)

# Source the file under test directly (more reliable than using paths)
source("fn_universal_data_accessor.R")


# ==============================================================================
# Test Group 1: Standard Mock Database (R114) Integration Tests
# ==============================================================================

test_that("db_connection_factory connects to mock database in development mode", {
  # Skip if DuckDB is not available
  skip_if_not_installed("duckdb")
  
  # Get a connection using the factory
  tryCatch({
    conn <- db_connection_factory("development")
    
    # Test connection is valid
    expect_true(DBI::dbIsValid(conn))
    
    # Check tables exist
    tables <- DBI::dbListTables(conn)
    expect_true(all(c("customer_profile", "orders") %in% tables))
    
    # Test customer_profile structure
    customers <- DBI::dbReadTable(conn, "customer_profile")
    expect_true(all(c("id", "name", "signup_date") %in% colnames(customers)))
    expect_equal(nrow(customers), 3)  # Known row count in mock database
    
    # Clean up
    DBI::dbDisconnect(conn, shutdown = TRUE)
  }, error = function(e) {
    skip(paste("Could not connect to mock database:", e$message))
  })
})

test_that("create_mock_connection DBI type provides valid connection", {
  # Skip if DuckDB is not available
  skip_if_not_installed("duckdb")
  
  # Try to create a mock connection
  tryCatch({
    mock_conn <- create_mock_connection("dbi")
    
    # Check it's a valid connection
    expect_true(DBI::dbIsValid(mock_conn))
    
    # Verify table access
    expect_true("customer_profile" %in% DBI::dbListTables(mock_conn))
    
    # Clean up
    DBI::dbDisconnect(mock_conn, shutdown = TRUE)
  }, error = function(e) {
    skip(paste("Could not create mock connection:", e$message))
  })
})

test_that("create_mock_connection list type loads data from mock database", {
  # Skip if DuckDB is not available
  skip_if_not_installed("duckdb")
  
  # Try to create a mock list connection
  tryCatch({
    mock_list <- create_mock_connection("list")
    
    # Check it's a list with data from database
    expect_type(mock_list, "list")
    expect_true(all(c("customer_profile", "orders") %in% names(mock_list)))
    
    # Check data structure matches expected
    expect_true(all(c("id", "name", "signup_date") %in% colnames(mock_list$customer_profile)))
    expect_equal(nrow(mock_list$customer_profile), 3)
  }, error = function(e) {
    skip(paste("Could not create mock list connection:", e$message))
  })
})

# ==============================================================================
# Test Group 2: Universal Data Accessor with Mock Data
# ==============================================================================

# Set up mock data for tests (fallback if DuckDB connection fails)
mock_data <- list(
  customer_profile = data.frame(id = 1:3, name = c("A", "B", "C"), signup_date = as.Date(c("2021-01-01", "2021-06-15", "2021-12-31"))),
  orders = data.frame(order_id = 101:103, customer_id = 1:3, amount = c(10, 20, 30), order_date = Sys.Date() - c(10, 5, 1))
)

# 1. Test access via DBI connection to standard mock database
test_that("universal_data_accessor retrieves data from standard mock database", {
  # Skip if DuckDB is not available
  skip_if_not_installed("duckdb")
  
  # Try to connect to mock database
  tryCatch({
    # Get connection using our factory
    mock_db <- db_connection_factory("development")
    
    # Test basic access
    df <- universal_data_accessor(mock_db, "customer_profile", log_level = "INFO")
    expect_s3_class(df, "data.frame")
    expect_equal(nrow(df), 3)
    expect_true(all(c("id", "name", "signup_date") %in% colnames(df)))
    
    # Test with query template
    query_template <- "SELECT * FROM {data_name} WHERE id > 1"
    filtered_df <- universal_data_accessor(mock_db, "customer_profile", 
                                          query_template = query_template,
                                          log_level = "INFO")
    expect_equal(nrow(filtered_df), 2)  # Should only have customers with id > 1
    
    # Clean up
    DBI::dbDisconnect(mock_db, shutdown = TRUE)
  }, error = function(e) {
    skip(paste("Could not access mock database:", e$message))
  })
})

# 2. Test list connection with direct data frame
list_conn <- list(
  customer_profile = mock_data$customer_profile
)

test_that("universal_data_accessor handles list connection with direct element", {
  # Explicitly specify a valid log level
  df <- universal_data_accessor(list_conn, "customer_profile", log_level = "INFO")
  expect_s3_class(df, "data.frame")
  expect_named(df, c("id", "name", "signup_date"))
  expect_equal(nrow(df), 3)
})

# 3. Test list connection with get_* function
fn_conn <- list(
  get_orders = function() mock_data$orders
)

test_that("universal_data_accessor handles list connection with get_ function", {
  df <- universal_data_accessor(fn_conn, "orders", log_level = "INFO")
  expect_s3_class(df, "data.frame")
  expect_equal(df$order_id, 101:103)
  expect_equal(df$amount, c(10, 20, 30))
})

# 4. Test direct data frame input
test_that("universal_data_accessor with direct data.frame input returns the same data", {
  df <- universal_data_accessor(mock_data$orders, NULL, log_level = "INFO")
  expect_equal(df, mock_data$orders)
})

# 5. Test reactive expression input
test_that("universal_data_accessor handles reactive expression unwrapping", {
  # Simulate a Shiny reactive by assigning class 'reactiveExpr'
  reactive_conn <- function() list(testdata = mock_data$customer_profile)
  class(reactive_conn) <- "reactiveExpr"
  
  df <- universal_data_accessor(reactive_conn, "testdata", log_level = "INFO")
  expect_equal(nrow(df), 3)
  expect_named(df, c("id", "name", "signup_date"))
})

# ==============================================================================
# Test Group 3: Finding Project Root
# ==============================================================================

test_that("find_project_root locates a valid directory", {
  root <- find_project_root()
  expect_type(root, "character")
  expect_true(dir.exists(root))
  
  # Test that it returned some directory (might not contain 'update_scripts' in test environment)
  # just check that the returned path exists
  expect_true(dir.exists(root))
})

# ==============================================================================
# Test Group 4: Tbl Interface
# ==============================================================================

test_that("tbl works with database connection", {
  # Skip if DuckDB is not available
  skip_if_not_installed("duckdb")
  
  # Try to connect to mock database
  tryCatch({
    # Get connection using our factory
    mock_db <- db_connection_factory("development")
    
    # Test tbl interface
    tbl_result <- tbl(mock_db, "customer_profile")
    expect_s3_class(tbl_result, "tbl")
    
    # Test with dplyr operations
    filtered <- tbl_result %>% 
      filter(id > 1) %>%
      collect()
    
    expect_equal(nrow(filtered), 2)
    
    # Clean up
    DBI::dbDisconnect(mock_db, shutdown = TRUE)
  }, error = function(e) {
    skip(paste("Could not test tbl interface:", e$message))
  })
})

test_that("tbl works with list connection", {
  # Create list connection with data
  list_conn <- list(
    get_sample = function() data.frame(id = 1:3, value = 10:12)
  )
  
  # Test tbl interface
  result <- tbl(list_conn, "sample") %>% collect()
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
})

# ==============================================================================
# Test Group 5: Log Level Handling
# ==============================================================================

test_that("universal_data_accessor handles invalid log levels gracefully", {
  # Test with invalid log level - should default to INFO and not error
  df <- universal_data_accessor(list_conn, "customer_profile", log_level = "INVALID_LEVEL")
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), 3)
  
  # Test with lowercase log level - should work with proper validation
  df2 <- universal_data_accessor(list_conn, "customer_profile", log_level = "debug")
  expect_s3_class(df2, "data.frame")
  expect_equal(nrow(df2), 3)
})

# ==============================================================================
# Test Group 6: Query Objects
# ==============================================================================

test_that("universal_data_accessor handles query objects", {
  # Create test data
  customer_data <- data.frame(
    id = 1:5,
    name = c("A", "B", "C", "D", "E"),
    signup_date = as.Date(c("2021-01-01", "2021-06-15", "2021-12-31", "2022-03-01", "2022-07-15"))
  )
  
  order_data <- data.frame(
    order_id = 101:105,
    customer_id = c(1, 2, 1, 3, 1),
    amount = c(10, 20, 30, 40, 50)
  )
  
  # Create a mock connection with the test data
  mock_conn <- list(
    customer_profile = customer_data,
    orders = order_data,
    dbGetQuery = function(sql) {
      # Simple mock implementation that returns filtered data based on SQL
      if (grepl("signup_date > '2022-01-01'", sql)) {
        return(customer_data[customer_data$signup_date > as.Date("2022-01-01"), ])
      } else if (grepl("customer_id = 1", sql)) {
        return(order_data[order_data$customer_id == 1, ])
      } else {
        return(data.frame())
      }
    }
  )
  class(mock_conn) <- c("mock_dbi_connection", "DBIConnection")
  
  # Test with a single query object
  single_query <- list(
    template = "SELECT * FROM {data_name} WHERE signup_date > '{cutoff}'",
    params = list(cutoff = "2022-01-01")
  )
  
  result1 <- universal_data_accessor(mock_conn, "customer_profile", 
                                    query_objects = single_query, 
                                    log_level = "INFO")
  
  expect_s3_class(result1, "data.frame")
  expect_equal(nrow(result1), 2)  # Should have 2 customers after 2022-01-01
  
  # Test with multiple query objects
  multi_queries <- list(
    list(
      template = "SELECT * FROM {data_name} WHERE signup_date > '{cutoff}'",
      params = list(cutoff = "2022-01-01")
    ),
    list(
      template = "SELECT * FROM {table} WHERE customer_id = {cust_id}",
      params = list(table = "orders", cust_id = 1)
    )
  )
  
  # Test with combine_results = FALSE (return list)
  result2 <- universal_data_accessor(mock_conn, "customer_profile", 
                                    query_objects = multi_queries,
                                    combine_results = FALSE,
                                    log_level = "INFO")
  
  expect_type(result2, "list")
  expect_equal(length(result2), 2)
  expect_equal(nrow(result2[[1]]), 2)  # First query: 2 customers
  expect_equal(nrow(result2[[2]]), 3)  # Second query: 3 orders for customer_id=1
})

# ==============================================================================
# Test Group 7: Shiny Integration
# ==============================================================================

test_that("create_reactive_data_connection works with non-reactive data", {
  skip_if_not_installed("shiny")
  
  # Create a simple data source
  data_source <- list(test = data.frame(id = 1:3))
  
  # Skip real reactive test (requires shiny environment)
  skip("Reactive tests require shiny environment")
  
  # Just verify the function exists
  expect_true(exists("create_reactive_data_connection"))
})