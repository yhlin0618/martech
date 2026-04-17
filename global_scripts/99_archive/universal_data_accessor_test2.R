#' Comprehensive Universal Data Accessor Test Framework
#' 
#' This script provides a comprehensive testing framework for the 
#' universal_data_accessor function, implementing the R99 Test App Building
#' principles. It tests all connection types and data scenarios.
#'
#' @implements MP16 Modularity 
#' @implements MP17 Separation of Concerns
#' @implements R91 Universal Data Access Pattern
#' @implements R92 Universal DBI Approach
#' @implements R76 Module Data Connection
#' @implements R99 Test App Building Principles
#' @implements P74 Test Data Design Patterns

# === Setup ===

# Check if required packages are available
required_packages <- c("DBI", "duckdb", "testthat", "shiny")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("Missing required packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("Install them using: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))\n")
  cat("Tests requiring these packages will be skipped.\n")
}

# Source the function under test
source("./update_scripts/global_scripts/02_db_utils/fn_universal_data_accessor.R")

# === Test Scenarios ===

# Create a test data fixture with multiple test scenarios
test_data <- list(
  # Test scenarios for different data states
  scenarios = list(
    # Complete/happy path scenario
    complete = list(
      customer_profile = data.frame(
        customer_id = 1:5,
        name = c("Customer A", "Customer B", "Customer C", "Customer D", "Customer E"),
        email = c("a@example.com", "b@example.com", "c@example.com", "d@example.com", "e@example.com"),
        stringsAsFactors = FALSE
      ),
      
      sales_dta = data.frame(
        customer_id = c(1, 1, 2, 3, 3, 3, 4, 5, 5),
        order_id = 101:109,
        amount = c(50, 25, 75, 30, 45, 60, 100, 90, 85),
        stringsAsFactors = FALSE
      ),
      
      dna_by_customer = data.frame(
        customer_id = 1:5,
        loyalty_score = c(0.8, 0.6, 0.9, 0.7, 0.5),
        purchase_frequency = c(12, 4, 24, 8, 2),
        stringsAsFactors = FALSE
      )
    ),
    
    # Incomplete data scenario
    incomplete = list(
      # Missing some customers
      customer_profile = data.frame(
        customer_id = c(1, 3, 5),
        name = c("Customer A", "Customer C", "Customer E"),
        email = c("a@example.com", "c@example.com", "e@example.com"),
        stringsAsFactors = FALSE
      ),
      
      # Missing some orders
      sales_dta = data.frame(
        customer_id = c(1, 3, 5),
        order_id = c(101, 103, 108),
        amount = c(50, 30, 90),
        stringsAsFactors = FALSE
      ),
      
      # DNA data has different structure
      dna_by_customer = data.frame(
        customer_id = 1:5,
        loyalty_score = c(0.8, 0.6, 0.9, 0.7, 0.5),
        # Missing purchase_frequency
        stringsAsFactors = FALSE
      )
    ),
    
    # Error scenario
    error = list(
      # Empty customer profile
      customer_profile = data.frame(
        customer_id = integer(0),
        name = character(0),
        email = character(0),
        stringsAsFactors = FALSE
      ),
      
      # Sales with invalid customer IDs
      sales_dta = data.frame(
        customer_id = c(999, 888, 777),
        order_id = c(901, 902, 903),
        amount = c(999, 888, 777),
        stringsAsFactors = FALSE
      ),
      
      # DNA with NULL values
      dna_by_customer = data.frame(
        customer_id = 1:3,
        loyalty_score = c(NA, 0.5, NA),
        purchase_frequency = c(NA, NA, 10),
        stringsAsFactors = FALSE
      )
    )
  ),
  
  # Non-standard naming patterns
  naming_variants = list(
    # With df_ prefix
    df_customer = data.frame(
      customer_id = 1:3,
      name = c("A Prefix", "B Prefix", "C Prefix"),
      stringsAsFactors = FALSE
    ),
    
    # With _dta suffix
    product_dta = data.frame(
      product_id = 1:3,
      name = c("Product X", "Product Y", "Product Z"),
      price = c(10, 20, 30),
      stringsAsFactors = FALSE
    )
  )
)

# === Connection Factory Functions ===

#' Create a test connection of the specified type
#' 
#' @param data The test data to include in the connection
#' @param connection_type The type of connection to create
#' @return A connection object of the specified type
create_test_connection <- function(data, connection_type = c("dbi", "list", "function", "mixed", "reactive")) {
  connection_type <- match.arg(connection_type)
  
  if (connection_type == "dbi") {
    # Check if DBI packages are available
    if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
      stop("DBI or duckdb package not available. Cannot create DBI connection.")
    }
    
    # Create an in-memory DuckDB connection
    con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
    
    # Write test data to the database
    for (name in names(data)) {
      DBI::dbWriteTable(con, name, data[[name]], overwrite = TRUE)
    }
    
    return(con)
    
  } else if (connection_type == "reactive") {
    # Check if shiny package is available
    if (!requireNamespace("shiny", quietly = TRUE)) {
      stop("Shiny package not available. Cannot create reactive connection.")
    }
    
    # Create a connection appropriate for the test case
    base_conn <- create_mock_connection(data, "list")
    
    # Wrap it in a reactive expression
    return(create_reactive_data_connection(base_conn))
    
  } else {
    # Create a mock connection for list, function, or mixed
    return(create_mock_connection(data, connection_type))
  }
}

#' Cleanup a test connection
#' 
#' @param conn The connection to clean up
#' @param connection_type The type of connection
cleanup_test_connection <- function(conn, connection_type = c("dbi", "list", "function", "mixed", "reactive")) {
  connection_type <- match.arg(connection_type)
  
  if (connection_type == "dbi") {
    # Clean up DBI connection
    tryCatch({
      DBI::dbDisconnect(conn)
    }, error = function(e) {
      warning("Error disconnecting from database: ", e$message)
    })
  }
  
  # Other connection types don't need explicit cleanup
  invisible(NULL)
}

# === Test Functions ===

#' Test data retrieval across all connection types
#' 
#' @param scenario_name The name of the scenario to test
#' @param scenario_data The data for the scenario
test_all_connection_types <- function(scenario_name, scenario_data) {
  cat("\n=== Testing all connection types with scenario:", scenario_name, "===\n")
  
  # Supported connection types
  connection_types <- c("list", "function", "mixed")
  
  # Add DBI and reactive if available
  if (requireNamespace("DBI", quietly = TRUE) && requireNamespace("duckdb", quietly = TRUE)) {
    connection_types <- c(connection_types, "dbi")
  }
  if (requireNamespace("shiny", quietly = TRUE)) {
    connection_types <- c(connection_types, "reactive")
  }
  
  results <- list()
  
  # Test each connection type
  for (conn_type in connection_types) {
    cat("\n--> Testing", conn_type, "connection type\n")
    
    # Create connection
    conn <- create_test_connection(scenario_data, conn_type)
    
    # Test access to different data elements
    for (data_name in names(scenario_data)) {
      cat("  Accessing data:", data_name, "... ")
      
      tryCatch({
        # Access the data
        result <- if (conn_type == "reactive") {
          # For reactive connections, we need shiny's isolate
          shiny::isolate(universal_data_accessor(conn(), data_name, log_level = 1))
        } else {
          universal_data_accessor(conn, data_name, log_level = 1)
        }
        
        # Validate result
        if (is.data.frame(result) && nrow(result) == nrow(scenario_data[[data_name]])) {
          cat("✓ Success (", nrow(result), "rows)\n")
          results[[paste0(conn_type, "_", data_name)]] <- TRUE
        } else {
          cat("✗ Failed - wrong data shape\n")
          results[[paste0(conn_type, "_", data_name)]] <- FALSE
        }
        
      }, error = function(e) {
        cat("✗ Error:", e$message, "\n")
        results[[paste0(conn_type, "_", data_name)]] <- FALSE
      })
    }
    
    # Test data name variants
    variant_tests <- list(
      # Standard name should work
      list(name = "customer_profile", expected_rows = nrow(scenario_data$customer_profile)),
      
      # _dta suffix handling
      list(name = "sales", expected_rows = nrow(scenario_data$sales_dta))
    )
    
    for (test in variant_tests) {
      cat("  Accessing data with variant name:", test$name, "... ")
      
      tryCatch({
        # Access the data
        result <- if (conn_type == "reactive") {
          shiny::isolate(universal_data_accessor(conn(), test$name, log_level = 1))
        } else {
          universal_data_accessor(conn, test$name, log_level = 1)
        }
        
        # Validate result
        if (is.data.frame(result) && nrow(result) == test$expected_rows) {
          cat("✓ Success (", nrow(result), "rows)\n")
          results[[paste0(conn_type, "_variant_", test$name)]] <- TRUE
        } else {
          cat("✗ Failed - wrong data shape\n")
          results[[paste0(conn_type, "_variant_", test$name)]] <- FALSE
        }
        
      }, error = function(e) {
        cat("✗ Error:", e$message, "\n")
        results[[paste0(conn_type, "_variant_", test$name)]] <- FALSE
      })
    }
    
    # Clean up
    cleanup_test_connection(conn, conn_type)
  }
  
  # Summarize results
  cat("\nSummary for scenario", scenario_name, ":\n")
  successes <- sum(unlist(results))
  total <- length(results)
  cat("Passed:", successes, "of", total, "tests (", 
      round(successes/total*100), "%)\n")
  
  return(results)
}

#' Test SQL query templates
#' 
#' @description Tests SQL query templates with DBI connections
test_query_templates <- function() {
  cat("\n=== Testing SQL query templates ===\n")
  
  # Skip if DBI packages not available
  if (!requireNamespace("DBI", quietly = TRUE) || !requireNamespace("duckdb", quietly = TRUE)) {
    cat("DBI or duckdb package not available. Skipping query template tests.\n")
    return(invisible(NULL))
  }
  
  # Create DBI connection with complete test data
  con <- create_test_connection(test_data$scenarios$complete, "dbi")
  
  # Test various query templates
  templates <- list(
    simple = list(
      template = "SELECT * FROM customer_profile",
      expected_rows = nrow(test_data$scenarios$complete$customer_profile)
    ),
    
    where_clause = list(
      template = "SELECT * FROM customer_profile WHERE customer_id = 1",
      expected_rows = 1
    ),
    
    join = list(
      template = paste0(
        "SELECT c.customer_id, c.name, s.order_id, s.amount ",
        "FROM customer_profile c ",
        "JOIN sales_dta s ON c.customer_id = s.customer_id"
      ),
      expected_rows = nrow(test_data$scenarios$complete$sales_dta)
    ),
    
    aggregate = list(
      template = paste0(
        "SELECT customer_id, SUM(amount) as total_amount ",
        "FROM sales_dta ",
        "GROUP BY customer_id"
      ),
      expected_rows = length(unique(test_data$scenarios$complete$sales_dta$customer_id))
    )
  )
  
  results <- list()
  
  # Test each template
  for (name in names(templates)) {
    test <- templates[[name]]
    cat("Testing template:", name, "... ")
    
    tryCatch({
      # Use the query template
      result <- universal_data_accessor(
        con, 
        "ignored_name", 
        query_template = test$template,
        log_level = 1
      )
      
      # Validate result
      if (is.data.frame(result) && nrow(result) == test$expected_rows) {
        cat("✓ Success (", nrow(result), "rows)\n")
        results[[name]] <- TRUE
      } else {
        cat("✗ Failed - got", nrow(result), "rows, expected", test$expected_rows, "\n")
        results[[name]] <- FALSE
      }
      
    }, error = function(e) {
      cat("✗ Error:", e$message, "\n")
      results[[name]] <- FALSE
    })
  }
  
  # Clean up
  cleanup_test_connection(con, "dbi")
  
  # Summarize results
  cat("\nSQL template test summary:\n")
  successes <- sum(unlist(results))
  total <- length(results)
  cat("Passed:", successes, "of", total, "tests (", 
      round(successes/total*100), "%)\n")
  
  return(results)
}

#' Test error handling and edge cases
#' 
#' @description Tests how the function handles error conditions and edge cases
test_error_handling <- function() {
  cat("\n=== Testing error handling and edge cases ===\n")
  
  # Create a list connection with the error scenario data
  conn <- create_test_connection(test_data$scenarios$error, "list")
  
  edge_cases <- list(
    # Non-existent data
    non_existent = list(
      data_name = "nonexistent_data",
      should_return_null = TRUE
    ),
    
    # Empty data frame
    empty_df = list(
      data_name = "customer_profile",  # This is empty in the error scenario
      should_have_zero_rows = TRUE
    ),
    
    # Data with NULL values
    null_values = list(
      data_name = "dna_by_customer",
      should_have_nulls = TRUE
    )
  )
  
  results <- list()
  
  # Test each edge case
  for (name in names(edge_cases)) {
    test <- edge_cases[[name]]
    cat("Testing edge case:", name, "... ")
    
    tryCatch({
      # Access the data
      result <- universal_data_accessor(conn, test$data_name, log_level = 1)
      
      # Validate based on expected behavior
      if (test$should_return_null && is.null(result)) {
        cat("✓ Success (correctly returned NULL)\n")
        results[[name]] <- TRUE
      } else if (test$should_have_zero_rows && is.data.frame(result) && nrow(result) == 0) {
        cat("✓ Success (correctly returned empty data frame)\n")
        results[[name]] <- TRUE
      } else if (test$should_have_nulls && is.data.frame(result) && any(is.na(result))) {
        cat("✓ Success (correctly handled NULL values)\n")
        results[[name]] <- TRUE
      } else {
        cat("✗ Failed - unexpected result\n")
        results[[name]] <- FALSE
      }
      
    }, error = function(e) {
      # Some errors might be expected, but we prefer the function to return NULL
      # rather than error for non-existent data
      cat("✗ Error instead of NULL:", e$message, "\n")
      results[[name]] <- FALSE
    })
  }
  
  # Test invalid connection types
  invalid_connections <- list(
    null_connection = NULL,
    numeric_connection = 42,
    character_connection = "this is not a connection"
  )
  
  for (name in names(invalid_connections)) {
    conn <- invalid_connections[[name]]
    cat("Testing invalid connection:", name, "... ")
    
    tryCatch({
      result <- universal_data_accessor(conn, "any_data", log_level = 1)
      
      if (is.null(result)) {
        cat("✓ Success (correctly returned NULL for invalid connection)\n")
        results[[paste0("invalid_", name)]] <- TRUE
      } else {
        cat("✗ Failed - did not return NULL for invalid connection\n")
        results[[paste0("invalid_", name)]] <- FALSE
      }
      
    }, error = function(e) {
      cat("✗ Error instead of NULL:", e$message, "\n")
      results[[paste0("invalid_", name)]] <- FALSE
    })
  }
  
  # Summarize results
  cat("\nError handling test summary:\n")
  successes <- sum(unlist(results))
  total <- length(results)
  cat("Passed:", successes, "of", total, "tests (", 
      round(successes/total*100), "%)\n")
  
  return(results)
}

# === Interactive Test App ===

#' Create an interactive Shiny test app
#' 
#' @description Creates a Shiny app that allows interactive testing of the universal_data_accessor
create_interactive_test_app <- function() {
  # Skip if shiny package not available
  if (!requireNamespace("shiny", quietly = TRUE)) {
    cat("Shiny package not available. Cannot create interactive test app.\n")
    return(invisible(NULL))
  }
  
  # Initialize connections for each type
  connections <- list(
    list = create_test_connection(test_data$scenarios$complete, "list"),
    func = create_test_connection(test_data$scenarios$complete, "function"),
    mixed = create_test_connection(test_data$scenarios$complete, "mixed")
  )
  
  # Add DBI connection if available
  if (requireNamespace("DBI", quietly = TRUE) && requireNamespace("duckdb", quietly = TRUE)) {
    connections$dbi <- create_test_connection(test_data$scenarios$complete, "dbi")
  }
  
  # Define the UI
  ui <- shiny::fluidPage(
    shiny::titlePanel("Universal Data Accessor Test App"),
    
    shiny::sidebarLayout(
      shiny::sidebarPanel(
        shiny::selectInput("connection_type", "Connection Type:",
                    choices = names(connections)),
        
        shiny::selectInput("data_name", "Data Name:",
                    choices = c("customer_profile", "sales", 
                               "sales_dta", "dna_by_customer")),
        
        shiny::textInput("query_template", "SQL Query Template (optional):",
                  value = ""),
        
        shiny::sliderInput("log_level", "Log Level:",
                    min = 0, max = 4, value = 3, step = 1),
        
        shiny::actionButton("fetch_data", "Fetch Data")
      ),
      
      shiny::mainPanel(
        shiny::h3("Result:"),
        shiny::verbatimTextOutput("log_output"),
        shiny::tableOutput("data_preview"),
        shiny::verbatimTextOutput("data_summary")
      )
    )
  )
  
  # Define the server
  server <- function(input, output, session) {
    # Create a reactive value to store logs
    logs <- shiny::reactiveVal("")
    
    # Custom logger that captures output
    log_capture <- function(message) {
      current <- logs()
      logs(paste0(current, message, "\n"))
    }
    
    # Data retrieval reactive
    result_data <- shiny::reactiveVal(NULL)
    
    # Handle the fetch button
    shiny::observeEvent(input$fetch_data, {
      # Clear previous logs
      logs("")
      
      # Get the selected connection
      conn <- connections[[input$connection_type]]
      
      # Set up capturing of log messages
      log_output <- capture.output({
        # Get the data
        data <- universal_data_accessor(
          conn,
          input$data_name,
          query_template = if (input$query_template == "") NULL else input$query_template,
          log_level = input$log_level
        )
        
        # Store the result
        result_data(data)
      })
      
      # Update the logs
      logs(paste(log_output, collapse = "\n"))
    })
    
    # Output the log
    output$log_output <- shiny::renderText({
      logs()
    })
    
    # Output the data preview
    output$data_preview <- shiny::renderTable({
      data <- result_data()
      if (is.null(data)) {
        return(data.frame(Message = "No data or NULL result"))
      }
      
      # Return the first 10 rows
      head(data, 10)
    })
    
    # Output data summary
    output$data_summary <- shiny::renderText({
      data <- result_data()
      if (is.null(data)) {
        return("Result: NULL")
      }
      
      if (!is.data.frame(data)) {
        return(paste("Result is not a data frame. Class:", class(data)))
      }
      
      paste0(
        "Dimensions: ", nrow(data), " rows x ", ncol(data), " columns\n",
        "Column names: ", paste(names(data), collapse = ", "), "\n",
        "Data types: ", paste(sapply(data, class), collapse = ", ")
      )
    })
    
    # Clean up connections when the session ends
    shiny::onSessionEnded(function() {
      if (requireNamespace("DBI", quietly = TRUE) && 
          "dbi" %in% names(connections)) {
        tryCatch({
          DBI::dbDisconnect(connections$dbi)
        }, error = function(e) {
          warning("Error disconnecting from database:", e$message)
        })
      }
    })
  }
  
  # Create and return the Shiny app
  shiny::shinyApp(ui, server)
}

# === Run Tests ===

#' Run all automated tests
run_all_tests <- function() {
  cat("\n=== UNIVERSAL DATA ACCESSOR COMPREHENSIVE TEST SUITE ===\n")
  cat("Testing the universal_data_accessor function with all connection types and scenarios\n")
  
  # Test with different scenarios
  results_complete <- test_all_connection_types("complete", test_data$scenarios$complete)
  results_incomplete <- test_all_connection_types("incomplete", test_data$scenarios$incomplete)
  
  # Test query templates
  results_queries <- test_query_templates()
  
  # Test error handling
  results_errors <- test_error_handling()
  
  # Overall summary
  cat("\n=== OVERALL TEST SUMMARY ===\n")
  
  # Combine all results
  all_results <- c(
    unlist(results_complete),
    unlist(results_incomplete),
    unlist(results_queries),
    unlist(results_errors)
  )
  
  total_success <- sum(all_results)
  total_tests <- length(all_results)
  success_rate <- round(total_success / total_tests * 100)
  
  cat(total_success, "of", total_tests, "tests passed (", success_rate, "%)\n")
  
  if (success_rate == 100) {
    cat("\n✓✓✓ ALL TESTS PASSED! ✓✓✓\n")
  } else {
    cat("\n⚠️ SOME TESTS FAILED ⚠️\n")
    cat("Review the test output above for details.\n")
  }
}

# === Main Execution ===

# Automatically run the tests when the script is sourced
cat("\nStarting universal_data_accessor comprehensive tests...\n")
cat("This script implements the R99 Test App Building Principles.\n")

# Run the automated tests
run_all_tests()

# Provide instructions for running the interactive app
cat("\n=== INTERACTIVE TESTING ===\n")
cat("To launch the interactive test app, run:\n")
cat("create_interactive_test_app()\n")

# Don't clean up the environment so the interactive app can be launched later
cat("\nTest environment is ready for interactive testing.\n")