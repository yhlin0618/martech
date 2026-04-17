# Template: {platform}_ETL_products_0IM.R - Products Data Import Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Products Pipeline Phase 0IM (Import): Pure data extraction for product catalog
# Template for creating platform-specific product import scripts
#
# USAGE: Copy this template and replace {platform} with actual platform_id (cbz, eby, amz, etc.)
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting {Platform} Products ETL Import Phase (0IM)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for products data import
message("INITIALIZE: 📦 Loading products ETL libraries...")
lib_start <- Sys.time()

# Standard ETL libraries
library(httr)      # API calls
library(jsonlite)  # JSON handling
library(dplyr)     # Data manipulation
library(stringr)   # String manipulation

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source products-specific ETL functions
message("INITIALIZE: 📋 Loading products ETL functions...")
source_start <- Sys.time()

# Data type-specific functions (customize per platform)
if (!exists("process_products_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_process_products_import.R"))
}
if (!exists("fetch_{platform}_products_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "{platform}", "import", "fn_fetch_{platform}_products_data.R"))
}
if (!exists("validate_products_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "validation", "fn_validate_products_import.R"))
}

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}
if (!exists("write_etl_output", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "output", "fn_write_etl_output.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Establish database connections using dbConnectDuckdb
message("INITIALIZE: 🔗 Connecting to raw_data database...")
db_start <- Sys.time()
raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = FALSE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connection established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting products data import processing...")
main_start_time <- Sys.time()

# Main execution function for products import
main_execution <- function() {
  tryCatch({
    
    # Step 1: Fetch products data from platform-specific source
    message("MAIN: 📥 Fetching products data from {Platform} source...")
    fetch_start <- Sys.time()
    
    # Platform-specific data fetching (customize per platform)
    products_raw_data <- fetch_{platform}_products_data()
    
    fetch_elapsed <- as.numeric(Sys.time() - fetch_start, units = "secs")
    message(sprintf("MAIN: ✅ Products data fetched (%d records, %.2fs)", 
                    nrow(products_raw_data), fetch_elapsed))
    
    # Step 2: Apply products-specific import processing
    message("MAIN: 🔄 Processing products import data...")
    process_start <- Sys.time()
    
    products_processed <- process_products_import(products_raw_data, platform_code = "{platform}")
    
    process_elapsed <- as.numeric(Sys.time() - process_start, units = "secs")
    message(sprintf("MAIN: ✅ Products import processing completed (%.2fs)", process_elapsed))
    
    # Step 3: Apply MP102 standardization for products data
    message("MAIN: 📋 Applying MP102 standardization...")
    standardize_start <- Sys.time()
    
    products_standardized <- products_processed %>%
      mutate(
        # Core fields (MP102 standard for products)
        product_id = as.character(product_id),
        product_name = as.character(product_name),
        category = as.character(category),
        subcategory = as.character(subcategory),
        brand = as.character(brand),
        sku = as.character(sku),
        upc = as.character(upc),
        price = as.numeric(price),
        cost = as.numeric(cost),
        weight = as.numeric(weight),
        dimensions = as.character(dimensions),
        description = as.character(description),
        is_active = as.logical(is_active),
        created_date = as.character(created_date),
        modified_date = as.character(modified_date),
        platform_code = "{platform}",
        import_timestamp = Sys.time(),
        import_source = "API",  # or "FILE" depending on source
        
        # Platform-specific extensions (customize per platform)
        {platform}_product_type = as.character({platform}_product_type),
        {platform}_vendor_id = as.character({platform}_vendor_id),
        {platform}_inventory_level = as.integer({platform}_inventory_level),
        {platform}_attributes = as.character({platform}_attributes)
        # Add more platform-specific fields as needed
      )
    
    standardize_elapsed <- as.numeric(Sys.time() - standardize_start, units = "secs")
    message(sprintf("MAIN: ✅ Standardization completed (%.2fs)", standardize_elapsed))
    
    # Step 4: Validate products import output
    message("MAIN: ✔️  Validating products import output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_products_import(products_standardized, platform_code = "{platform}")
    
    if (!validation_result$valid) {
      stop(sprintf("Products import validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 5: Write to raw_data database following MP102 naming
    message("MAIN: 💾 Writing products data to raw_data database...")
    write_start <- Sys.time()
    
    table_name <- sprintf("df_{platform}_products___raw")
    write_etl_output(raw_data, table_name, products_standardized, 
                     platform = "{platform}", datatype = "products", phase = "raw")
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Products data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return success result
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    result <- list(
      success = TRUE,
      records_processed = nrow(products_standardized),
      output_table = table_name,
      execution_time = main_elapsed
    )
    
    message(sprintf("MAIN: 🎉 Products import completed successfully (%d records, %.2fs total)", 
                    result$records_processed, result$execution_time))
    
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Products import failed: %s", e$message))
    stop(e$message)
  })
}

# Execute main function
tryCatch({
  result <- main_execution()
  script_success <- TRUE
  
}, error = function(e) {
  main_error <- e$message
  message(sprintf("EXECUTION: ❌ Script failed: %s", e$message))
})

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Running products import tests...")
test_start_time <- Sys.time()

# Test execution function
test_execution <- function() {
  
  if (!script_success) {
    return(list(passed = FALSE, message = sprintf("Main execution failed: %s", main_error)))
  }
  
  # Test 1: Verify output table exists
  table_name <- sprintf("df_{platform}_products___raw")
  if (!dbExistsTable(raw_data, table_name)) {
    return(list(passed = FALSE, message = sprintf("Output table %s does not exist", table_name)))
  }
  
  # Test 2: Verify record count > 0
  record_count <- dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
  if (record_count == 0) {
    return(list(passed = FALSE, message = "No records in imported output"))
  }
  
  # Test 3: Verify core fields exist
  imported_fields <- dbListFields(raw_data, table_name)
  required_fields <- c("product_id", "product_name", "category", "sku", "platform_code", "import_timestamp")
  missing_fields <- setdiff(required_fields, imported_fields)
  if (length(missing_fields) > 0) {
    return(list(passed = FALSE, message = sprintf("Missing required fields: %s", paste(missing_fields, collapse = ", "))))
  }
  
  # Test 4: Verify platform_id consistency
  platform_check <- dbGetQuery(raw_data, sprintf("SELECT DISTINCT platform_code FROM %s", table_name))
  if (nrow(platform_check) != 1 || platform_check$platform_code[1] != "{platform}") {
    return(list(passed = FALSE, message = "Platform ID inconsistency detected"))
  }
  
  # Test 5: Verify product_id uniqueness
  unique_check <- dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as total, COUNT(DISTINCT product_id) as unique_ids FROM %s", table_name))
  if (unique_check$total != unique_check$unique_ids) {
    return(list(passed = FALSE, message = "Duplicate product_id values detected"))
  }
  
  return(list(passed = TRUE, message = "All tests passed"))
}

# Execute tests
test_result <- test_execution()
test_passed <- test_result$passed
test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")

if (test_passed) {
  message(sprintf("TEST: ✅ All tests passed (%.2fs)", test_elapsed))
} else {
  message(sprintf("TEST: ❌ Tests failed: %s (%.2fs)", test_result$message, test_elapsed))
}

# ==============================================================================
# 4. RESULT
# ==============================================================================

script_end_time <- Sys.time()
total_elapsed <- as.numeric(script_end_time - script_start_time, units = "secs")

if (test_passed && script_success) {
  message(sprintf("RESULT: 🎉 {Platform} Products ETL Import completed successfully (%.2fs total)", total_elapsed))
  message(sprintf("RESULT: 📊 Output: df_{platform}_products___raw"))
} else {
  error_msg <- ifelse(!script_success, main_error, test_result$message)
  message(sprintf("RESULT: ❌ {Platform} Products ETL Import failed: %s (%.2fs total)", error_msg, total_elapsed))
  stop(sprintf("{Platform} Products ETL Import (0IM) failed: %s", error_msg))
}

# Cleanup and autodeinit
autodeinit()