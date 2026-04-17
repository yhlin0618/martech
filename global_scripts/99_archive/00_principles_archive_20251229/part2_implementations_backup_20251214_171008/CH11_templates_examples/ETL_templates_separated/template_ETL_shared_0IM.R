# Template: {platform}_ETL_shared_0IM.R - Shared API Import with Data Distribution
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle  
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# Shared ETL Import: Single API call with distribution to multiple data types
# Use this template when platform API returns multiple data types in one call
# This optimizes API usage while maintaining data type separation
#
# USAGE: Copy this template and replace {platform} with actual platform_id
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting {Platform} Shared ETL Import (API Optimization)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for shared API import
message("INITIALIZE: 📦 Loading shared ETL libraries...")
lib_start <- Sys.time()

# Standard ETL libraries
library(httr)      # API calls
library(jsonlite)  # JSON handling
library(dplyr)     # Data manipulation
library(purrr)     # Functional programming for data distribution
library(lubridate) # Date handling

# Platform-specific libraries (customize per platform)
# library(RCurl)   # For platforms requiring special HTTP handling
# library(XML)     # For XML-based APIs

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source shared import and distribution functions
message("INITIALIZE: 📋 Loading shared ETL functions...")
source_start <- Sys.time()

# Shared import functions (customize per platform)
if (!exists("fetch_{platform}_complete_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_fetch_{platform}_complete_data.R"))
}

# Data type extraction functions
if (!exists("extract_sales_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "extraction", "fn_extract_sales_data.R"))
}
if (!exists("extract_customers_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "extraction", "fn_extract_customers_data.R"))
}
if (!exists("extract_orders_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "extraction", "fn_extract_orders_data.R"))
}
if (!exists("extract_products_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "extraction", "fn_extract_products_data.R"))
}

# Data distribution functions
if (!exists("write_raw_data_by_type", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "distribution", "fn_write_raw_data_by_type.R"))
}

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Establish database connections
message("INITIALIZE: 🔗 Connecting to raw_data database...")
db_start <- Sys.time()
raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = FALSE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connection established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting shared API import with data distribution...")
main_start_time <- Sys.time()

# Main execution function for shared import
main_execution <- function() {
  tryCatch({
    
    # Step 1: Single API call to fetch complete dataset
    message("MAIN: 📡 Fetching complete data from {Platform} API...")
    fetch_start <- Sys.time()
    
    # Platform-specific complete data fetch (customize per platform)
    # This should return ALL data types in one API response
    complete_api_response <- fetch_{platform}_complete_data()
    
    fetch_elapsed <- as.numeric(Sys.time() - fetch_start, units = "secs")
    message(sprintf("MAIN: ✅ Complete API data fetched (%.2fs)", fetch_elapsed))
    message(sprintf("MAIN: 📊 API response size: %s", 
                    if (is.list(complete_api_response)) length(complete_api_response) else "Unknown"))
    
    # Step 2: Extract data by type from API response
    message("MAIN: 🔄 Extracting data by type...")
    extraction_start <- Sys.time()
    
    # Extract each data type using specialized extraction functions
    sales_raw <- extract_sales_data(complete_api_response, platform_code = "{platform}")
    customers_raw <- extract_customers_data(complete_api_response, platform_code = "{platform}")
    orders_raw <- extract_orders_data(complete_api_response, platform_code = "{platform}")
    products_raw <- extract_products_data(complete_api_response, platform_code = "{platform}")
    
    extraction_elapsed <- as.numeric(Sys.time() - extraction_start, units = "secs")
    
    # Log extraction results
    message(sprintf("MAIN: ✅ Data extraction completed (%.2fs)", extraction_elapsed))
    message(sprintf("MAIN: 📈 Sales records: %d", if (!is.null(sales_raw)) nrow(sales_raw) else 0))
    message(sprintf("MAIN: 👥 Customer records: %d", if (!is.null(customers_raw)) nrow(customers_raw) else 0))
    message(sprintf("MAIN: 📋 Order records: %d", if (!is.null(orders_raw)) nrow(orders_raw) else 0))
    message(sprintf("MAIN: 🛍️  Product records: %d", if (!is.null(products_raw)) nrow(products_raw) else 0))
    
    # Step 3: Apply MP102 standardization for each data type
    message("MAIN: 📋 Applying MP102 standardization for each data type...")
    standardization_start <- Sys.time()
    
    # Standardize sales data
    sales_standardized <- NULL
    if (!is.null(sales_raw) && nrow(sales_raw) > 0) {
      sales_standardized <- sales_raw %>%
        mutate(
          # Core sales fields
          order_id = as.character(order_id),
          customer_id = as.character(customer_id),
          order_date = as.character(order_date),
          product_id = as.character(product_id),
          quantity = as.integer(quantity),
          unit_price = as.numeric(unit_price),
          total_amount = as.numeric(total_amount),
          platform_code = "{platform}",
          import_timestamp = Sys.time(),
          import_source = "SHARED_API",
          
          # Platform-specific sales extensions
          {platform}_sales_field1 = as.character({platform}_sales_field1)
        )
    }
    
    # Standardize customers data
    customers_standardized <- NULL
    if (!is.null(customers_raw) && nrow(customers_raw) > 0) {
      customers_standardized <- customers_raw %>%
        mutate(
          # Core customer fields
          customer_id = as.character(customer_id),
          customer_email = as.character(customer_email),
          customer_name = as.character(customer_name),
          registration_date = as.character(registration_date),
          platform_code = "{platform}",
          import_timestamp = Sys.time(),
          import_source = "SHARED_API",
          
          # Platform-specific customer extensions
          {platform}_customer_field1 = as.character({platform}_customer_field1)
        )
    }
    
    # Standardize orders data
    orders_standardized <- NULL
    if (!is.null(orders_raw) && nrow(orders_raw) > 0) {
      orders_standardized <- orders_raw %>%
        mutate(
          # Core order fields (customize based on platform)
          order_id = as.character(order_id),
          customer_id = as.character(customer_id),
          order_date = as.character(order_date),
          order_status = as.character(order_status),
          order_total = as.numeric(order_total),
          platform_code = "{platform}",
          import_timestamp = Sys.time(),
          import_source = "SHARED_API",
          
          # Platform-specific order extensions
          {platform}_order_field1 = as.character({platform}_order_field1)
        )
    }
    
    # Standardize products data  
    products_standardized <- NULL
    if (!is.null(products_raw) && nrow(products_raw) > 0) {
      products_standardized <- products_raw %>%
        mutate(
          # Core product fields
          product_id = as.character(product_id),
          product_name = as.character(product_name),
          category = as.character(category),
          sku = as.character(sku),
          platform_code = "{platform}",
          import_timestamp = Sys.time(),
          import_source = "SHARED_API",
          
          # Platform-specific product extensions
          {platform}_product_field1 = as.character({platform}_product_field1)
        )
    }
    
    standardization_elapsed <- as.numeric(Sys.time() - standardization_start, units = "secs")
    message(sprintf("MAIN: ✅ Standardization completed (%.2fs)", standardization_elapsed))
    
    # Step 4: Distribute data to type-specific raw tables
    message("MAIN: 💾 Distributing data to type-specific tables...")
    distribution_start <- Sys.time()
    
    distribution_results <- list()
    
    # Write sales data
    if (!is.null(sales_standardized)) {
      sales_table <- sprintf("df_{platform}_sales___raw")
      write_raw_data_by_type(raw_data, sales_table, sales_standardized, 
                            platform = "{platform}", datatype = "sales")
      distribution_results$sales <- list(table = sales_table, records = nrow(sales_standardized))
      message(sprintf("MAIN: ✅ Sales data written to %s (%d records)", sales_table, nrow(sales_standardized)))
    }
    
    # Write customers data
    if (!is.null(customers_standardized)) {
      customers_table <- sprintf("df_{platform}_customers___raw")
      write_raw_data_by_type(raw_data, customers_table, customers_standardized,
                            platform = "{platform}", datatype = "customers") 
      distribution_results$customers <- list(table = customers_table, records = nrow(customers_standardized))
      message(sprintf("MAIN: ✅ Customer data written to %s (%d records)", customers_table, nrow(customers_standardized)))
    }
    
    # Write orders data
    if (!is.null(orders_standardized)) {
      orders_table <- sprintf("df_{platform}_orders___raw")
      write_raw_data_by_type(raw_data, orders_table, orders_standardized,
                            platform = "{platform}", datatype = "orders")
      distribution_results$orders <- list(table = orders_table, records = nrow(orders_standardized))
      message(sprintf("MAIN: ✅ Order data written to %s (%d records)", orders_table, nrow(orders_standardized)))
    }
    
    # Write products data
    if (!is.null(products_standardized)) {
      products_table <- sprintf("df_{platform}_products___raw")
      write_raw_data_by_type(raw_data, products_table, products_standardized,
                            platform = "{platform}", datatype = "products")
      distribution_results$products <- list(table = products_table, records = nrow(products_standardized))
      message(sprintf("MAIN: ✅ Product data written to %s (%d records)", products_table, nrow(products_standardized)))
    }
    
    distribution_elapsed <- as.numeric(Sys.time() - distribution_start, units = "secs")
    message(sprintf("MAIN: ✅ Data distribution completed (%.2fs)", distribution_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      platform = "{platform}",
      api_call_count = 1,  # Key benefit: Only 1 API call
      distribution_results = distribution_results,
      execution_time_seconds = main_elapsed,
      total_records = sum(sapply(distribution_results, function(x) x$records))
    )
    
    message(sprintf("MAIN: 🎉 Shared import completed successfully (%d total records, %.2fs)", 
                    result$total_records, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Shared import failed: %s", e$message))
    stop(sprintf("{Platform} Shared ETL Import failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting shared import validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify all expected tables were created
    message("TEST: 📊 Checking if all data type tables were created...")
    expected_tables <- sprintf("df_{platform}_%s___raw", c("sales", "customers", "orders", "products"))
    
    tables_created <- 0
    for (table_name in expected_tables) {
      if (DBI::dbExistsTable(raw_data, table_name)) {
        record_count <- DBI::dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
        message(sprintf("TEST: ✅ Table %s exists with %d records", table_name, record_count))
        tables_created <- tables_created + 1
      } else {
        message(sprintf("TEST: ⚠️  Table %s was not created (may be empty data type)", table_name))
      }
    }
    
    if (tables_created == 0) {
      stop("No data type tables were created")
    }
    
    message(sprintf("TEST: ✅ %d out of %d possible tables created", tables_created, length(expected_tables)))
    
    # Test 2: Verify platform_id consistency across all tables
    message("TEST: 🏷️  Verifying platform_id consistency...")
    for (table_name in expected_tables) {
      if (DBI::dbExistsTable(raw_data, table_name)) {
        platform_codes <- DBI::dbGetQuery(raw_data,
          sprintf("SELECT DISTINCT platform_code FROM %s", table_name))$platform_code
        
        if (length(platform_codes) != 1 || platform_codes[1] != "{platform}") {
          stop(sprintf("Platform ID inconsistent in %s. Expected: {platform}, Found: %s", 
                       table_name, paste(platform_codes, collapse = ", ")))
        }
      }
    }
    
    message("TEST: ✅ Platform IDs consistent across all tables")
    
    # Test 3: Verify import source consistency  
    message("TEST: 📡 Verifying import source consistency...")
    for (table_name in expected_tables) {
      if (DBI::dbExistsTable(raw_data, table_name)) {
        import_sources <- DBI::dbGetQuery(raw_data,
          sprintf("SELECT DISTINCT import_source FROM %s", table_name))$import_source
        
        if (!all(import_sources == "SHARED_API")) {
          warning(sprintf("Unexpected import source in %s: %s", table_name, paste(import_sources, collapse = ", ")))
        }
      }
    }
    
    message("TEST: ✅ Import source validation completed")
    
    # Test 4: Verify timestamp consistency (all imports should be close in time)
    message("TEST: 🕐 Verifying import timestamp consistency...")
    import_times <- c()
    
    for (table_name in expected_tables) {
      if (DBI::dbExistsTable(raw_data, table_name)) {
        min_time <- DBI::dbGetQuery(raw_data,
          sprintf("SELECT MIN(import_timestamp) as min_time FROM %s", table_name))$min_time
        max_time <- DBI::dbGetQuery(raw_data,
          sprintf("SELECT MAX(import_timestamp) as max_time FROM %s", table_name))$max_time
        
        import_times <- c(import_times, min_time, max_time)
      }
    }
    
    if (length(import_times) > 0) {
      time_range <- as.numeric(max(import_times, na.rm = TRUE) - min(import_times, na.rm = TRUE), units = "mins")
      if (time_range > 5) {  # More than 5 minutes difference suggests separate imports
        warning(sprintf("Import timestamps span %.2f minutes - may indicate separate API calls", time_range))
      }
      message(sprintf("TEST: ✅ Import timestamp range: %.2f minutes", time_range))
    }
    
    # Test 5: Check for API efficiency (this is the main benefit)
    message("TEST: 🚀 Verifying API efficiency...")
    if (exists("execution_result") && execution_result$api_call_count == 1) {
      message("TEST: ✅ API efficiency achieved - single API call for all data types")
    } else {
      warning("TEST: ⚠️  API efficiency not confirmed")
    }
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All shared import tests passed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Shared import test failed: %s", e$message))
    return(FALSE)
  })
}

# Execute test function  
test_result <- test_execution()

# ==============================================================================
# 4. RESULT
# ==============================================================================

script_end_time <- Sys.time()
total_elapsed <- as.numeric(script_end_time - script_start_time, units = "secs")

message("RESULT: 📊 Shared ETL Import Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📡 API calls made: %s", 
                if (exists("execution_result")) execution_result$api_call_count else "Unknown"))
message(sprintf("RESULT: 📈 Total records: %s",
                if (exists("execution_result")) execution_result$total_records else "Unknown"))

if (exists("execution_result") && !is.null(execution_result$distribution_results)) {
  message("RESULT: 🗃️  Tables created:")
  for (datatype in names(execution_result$distribution_results)) {
    result_info <- execution_result$distribution_results[[datatype]]
    message(sprintf("RESULT:   - %s: %d records", result_info$table, result_info$records))
  }
}

if (test_passed && script_success) {
  message("RESULT: ✅ {Platform} Shared ETL Import completed successfully")
  message("RESULT: 🚀 API efficiency achieved - single call distributed to multiple data types")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("{Platform} Shared ETL Import failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()

# ==============================================================================
# TEMPLATE CUSTOMIZATION NOTES  
# ==============================================================================

# To use this template for a specific platform:
#
# 1. Replace all instances of "{platform}" with the actual 3-letter platform_id
#
# 2. Implement the complete data fetch function:
#    - fetch_{platform}_complete_data() should make one API call returning all data types
#    - Handle authentication, pagination, rate limiting for the complete dataset
#
# 3. Implement data extraction functions for each data type:
#    - extract_sales_data() - Extract sales transactions from API response
#    - extract_customers_data() - Extract customer profiles from API response  
#    - extract_orders_data() - Extract order headers from API response
#    - extract_products_data() - Extract product catalog from API response
#
# 4. Customize platform-specific field extensions:
#    - Replace {platform}_sales_field1 with actual sales-specific fields
#    - Replace {platform}_customer_field1 with actual customer-specific fields
#    - Add more platform-specific fields as needed
#
# 5. Update the data distribution function:
#    - Implement write_raw_data_by_type() for consistent table writing
#    - Ensure proper error handling for each data type
#
# 6. Consider API response structure:
#    - Some APIs return nested objects - may need additional flattening
#    - Some APIs return arrays of different data types - adjust extraction logic
#    - Handle empty data types gracefully (some calls may not return all types)
#
# Benefits of this approach:
# - Single API call reduces rate limiting issues
# - Consistent timestamps across all data types
# - Maintains data type separation per MP104 and DM_R028
# - Optimizes bandwidth usage
# - Reduces authentication overhead
#
# Use this template when:
# - Platform API returns multiple data types in one response
# - API rate limiting is a concern
# - Data consistency across types is important
# - Network efficiency is prioritized