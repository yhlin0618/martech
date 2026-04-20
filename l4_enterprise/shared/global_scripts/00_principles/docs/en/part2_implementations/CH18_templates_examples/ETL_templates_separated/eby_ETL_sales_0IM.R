# eby_ETL_sales_0IM.R - eBay Sales Data Import Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Sales Pipeline Phase 0IM (Import): Pure data extraction for sales transactions
# eBay-specific sales import implementation
#
# eBay File Integration: Handles CSV/Excel files with variable formats
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting eBay Sales ETL Import Phase (0IM)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for eBay file processing
message("INITIALIZE: 📦 Loading eBay sales ETL libraries...")
lib_start <- Sys.time()

# Standard ETL libraries
library(readxl)    # Excel file handling
library(readr)     # CSV file handling
library(dplyr)     # Data manipulation
library(lubridate) # Date handling
library(stringr)   # String processing

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source eBay-specific ETL functions
message("INITIALIZE: 📋 Loading eBay sales ETL functions...")
source_start <- Sys.time()

# eBay sales-specific functions
if (!exists("process_sales_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "eby", "import", "fn_process_sales_import.R"))
}
if (!exists("detect_eby_file_format", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "eby", "import", "fn_detect_eby_file_format.R"))
}
if (!exists("read_eby_sales_file", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "eby", "import", "fn_read_eby_sales_file.R"))
}
if (!exists("validate_sales_import", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "validation", "fn_validate_sales_import.R"))
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

# Establish database connections
message("INITIALIZE: 🔗 Connecting to raw_data database...")
db_start <- Sys.time()
raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = FALSE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connection established (%.2fs)", db_elapsed))

# Define eBay file input directory
eby_input_dir <- file.path(GLOBAL_DATA_DIR, "input", "eby_sales")
if (!dir.exists(eby_input_dir)) {
  warning(sprintf("eBay input directory does not exist: %s", eby_input_dir))
}

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting eBay sales data import processing...")
main_start_time <- Sys.time()

# Main execution function for eBay sales import
main_execution <- function() {
  tryCatch({
    
    # Step 1: Discover eBay sales files
    message("MAIN: 🔍 Discovering eBay sales files...")
    discovery_start <- Sys.time()
    
    # Look for sales files in input directory
    file_patterns <- c("*.xlsx", "*.xls", "*.csv")
    sales_files <- c()
    
    for (pattern in file_patterns) {
      found_files <- list.files(eby_input_dir, pattern = glob2rx(pattern), 
                               full.names = TRUE, recursive = FALSE)
      sales_files <- c(sales_files, found_files)
    }
    
    if (length(sales_files) == 0) {
      stop(sprintf("No eBay sales files found in directory: %s", eby_input_dir))
    }
    
    # Filter to recent files only (last 30 days by default)
    file_info <- file.info(sales_files)
    recent_files <- sales_files[file_info$mtime > (Sys.Date() - 30)]
    
    if (length(recent_files) == 0) {
      warning("No recent eBay files found, using all available files")
      recent_files <- sales_files
    }
    
    discovery_elapsed <- as.numeric(Sys.time() - discovery_start, units = "secs")
    message(sprintf("MAIN: ✅ Found %d eBay sales files (%.2fs)", 
                    length(recent_files), discovery_elapsed))
    
    # Step 2: Process each eBay file
    message("MAIN: 📥 Processing eBay sales files...")
    processing_start <- Sys.time()
    
    all_sales_data <- list()
    
    for (i in seq_along(recent_files)) {
      file_path <- recent_files[i]
      file_name <- basename(file_path)
      
      message(sprintf("MAIN: 📄 Processing file %d/%d: %s", i, length(recent_files), file_name))
      
      # Detect file format and structure
      file_format <- detect_eby_file_format(file_path)
      
      # Read file using appropriate method
      file_data <- read_eby_sales_file(file_path, format = file_format)
      
      if (nrow(file_data) == 0) {
        warning(sprintf("No data found in file: %s", file_name))
        next
      }
      
      # Add file metadata
      file_data$source_file <- file_name
      file_data$file_processed_time <- Sys.time()
      
      all_sales_data[[i]] <- file_data
      message(sprintf("MAIN: ✅ File processed: %d records from %s", nrow(file_data), file_name))
    }
    
    # Combine all file data
    if (length(all_sales_data) == 0) {
      stop("No valid data extracted from any eBay files")
    }
    
    sales_combined <- bind_rows(all_sales_data)
    
    processing_elapsed <- as.numeric(Sys.time() - processing_start, units = "secs")
    message(sprintf("MAIN: ✅ All eBay files processed (%d total records, %.2fs)", 
                    nrow(sales_combined), processing_elapsed))
    
    # Step 3: Apply eBay-specific import processing
    message("MAIN: 🔄 Processing eBay sales import data...")
    transform_start <- Sys.time()
    
    sales_processed <- process_sales_import(sales_combined, platform_id = "eby")
    
    transform_elapsed <- as.numeric(Sys.time() - transform_start, units = "secs")
    message(sprintf("MAIN: ✅ eBay sales import processing completed (%.2fs)", transform_elapsed))
    
    # Step 4: Apply MP102 standardization for eBay sales data
    message("MAIN: 📋 Applying MP102 standardization for eBay...")
    standardize_start <- Sys.time()
    
    sales_standardized <- sales_processed %>%
      mutate(
        # Core fields (required by MP102)
        order_id = as.character(order_id),
        customer_id = as.character(customer_id),
        order_date = as.character(order_date),
        product_id = as.character(product_id),
        quantity = as.integer(quantity),
        unit_price = as.numeric(unit_price),
        total_amount = as.numeric(total_amount),
        platform_id = "eby",
        import_timestamp = Sys.time(),
        import_source = "FILE",
        
        # eBay-specific extensions (preserving unique data)
        eby_item_id = as.character(item_id),
        eby_buyer_username = as.character(buyer_username),
        eby_transaction_id = as.character(transaction_id),
        eby_listing_type = as.character(listing_type),
        eby_feedback_score = as.integer(feedback_score),
        eby_shipping_service = as.character(shipping_service),
        eby_payment_method = as.character(payment_method),
        
        # File processing metadata
        source_file = as.character(source_file),
        file_processed_time = file_processed_time
      )
    
    standardize_elapsed <- as.numeric(Sys.time() - standardize_start, units = "secs")
    message(sprintf("MAIN: ✅ eBay standardization completed (%.2fs)", standardize_elapsed))
    
    # Step 5: Validate sales import output
    message("MAIN: ✔️  Validating eBay sales import output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_sales_import(sales_standardized, platform_id = "eby")
    
    if (!validation_result$valid) {
      stop(sprintf("eBay sales import validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 6: Write to raw_data database following MP102 naming
    message("MAIN: 💾 Writing eBay sales data to raw_data database...")
    write_start <- Sys.time()
    
    table_name <- "df_eby_sales___raw"
    write_etl_output(raw_data, table_name, sales_standardized, 
                     platform = "eby", datatype = "sales", phase = "raw")
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ eBay sales data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      files_processed = length(recent_files),
      records_processed = nrow(sales_standardized),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "eby",
      datatype = "sales",
      phase = "0IM"
    )
    
    message(sprintf("MAIN: 🎉 eBay sales import completed successfully (%d files, %d records, %.2fs)", 
                    result$files_processed, result$records_processed, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ eBay sales import failed: %s", e$message))
    stop(sprintf("eBay Sales ETL 0IM failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting eBay sales import validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify table was created
    message("TEST: 📊 Checking if eBay sales table was created...")
    table_name <- "df_eby_sales___raw"
    
    if (!DBI::dbExistsTable(raw_data, table_name)) {
      stop(sprintf("eBay sales table %s was not created", table_name))
    }
    
    # Test 2: Verify record count
    message("TEST: 🔢 Verifying eBay sales record count...")
    record_count <- DBI::dbGetQuery(raw_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    if (record_count == 0) {
      stop("eBay sales table is empty")
    }
    
    message(sprintf("TEST: ✅ eBay sales table contains %d records", record_count))
    
    # Test 3: Verify core schema compliance (MP102)
    message("TEST: 📋 Verifying MP102 core schema compliance...")
    table_info <- DBI::dbGetQuery(raw_data, sprintf("PRAGMA table_info(%s)", table_name))
    required_fields <- c("order_id", "customer_id", "order_date", "product_id", 
                         "quantity", "unit_price", "total_amount", "platform_id", 
                         "import_timestamp", "import_source")
    
    actual_fields <- table_info$name
    missing_fields <- setdiff(required_fields, actual_fields)
    
    if (length(missing_fields) > 0) {
      stop(sprintf("Missing required fields in eBay sales table: %s", paste(missing_fields, collapse = ", ")))
    }
    
    message("TEST: ✅ All required core fields present")
    
    # Test 4: Verify platform_id consistency
    message("TEST: 🏷️  Verifying eBay platform_id consistency...")
    platform_ids <- DBI::dbGetQuery(raw_data, 
      sprintf("SELECT DISTINCT platform_id FROM %s", table_name))$platform_id
    
    if (length(platform_ids) != 1 || platform_ids[1] != "eby") {
      stop(sprintf("Platform ID inconsistent. Expected: eby, Found: %s", 
                   paste(platform_ids, collapse = ", ")))
    }
    
    message(sprintf("TEST: ✅ Platform ID consistent: %s", platform_ids[1]))
    
    # Test 5: Verify eBay-specific fields
    message("TEST: 🏪 Verifying eBay-specific extensions...")
    eby_fields <- c("eby_item_id", "eby_buyer_username", "eby_transaction_id", "eby_listing_type")
    eby_missing <- setdiff(eby_fields, actual_fields)
    
    if (length(eby_missing) > 0) {
      warning(sprintf("Missing eBay extension fields: %s", paste(eby_missing, collapse = ", ")))
    } else {
      message("TEST: ✅ eBay extension fields present")
    }
    
    # Test 6: Verify file processing metadata
    message("TEST: 📄 Verifying file processing metadata...")
    file_stats <- DBI::dbGetQuery(raw_data, sprintf("
      SELECT 
        COUNT(DISTINCT source_file) as files_processed,
        COUNT(*) as total_records,
        MIN(file_processed_time) as earliest_processing,
        MAX(file_processed_time) as latest_processing
      FROM %s", table_name))
    
    if (file_stats$files_processed == 0) {
      warning("No source file metadata found")
    } else {
      message(sprintf("TEST: ✅ Processed %d files with complete metadata", file_stats$files_processed))
    }
    
    # Test 7: Verify data types
    message("TEST: 🔧 Verifying data types...")
    sample_data <- DBI::dbGetQuery(raw_data, sprintf("SELECT * FROM %s LIMIT 5", table_name))
    
    # Check for obvious data type issues
    if (any(is.na(sample_data$order_id))) {
      warning("Some order_id values are NA")
    }
    if (any(is.na(sample_data$customer_id))) {
      warning("Some customer_id values are NA") 
    }
    if (!is.numeric(sample_data$total_amount)) {
      warning("total_amount is not numeric")
    }
    
    message("TEST: ✅ Data type validation completed")
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All eBay sales import tests passed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ eBay sales import test failed: %s", e$message))
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

message("RESULT: 📊 eBay Sales ETL Import (0IM) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📁 Files processed: %s", 
                if (exists("execution_result")) execution_result$files_processed else "Unknown"))
message(sprintf("RESULT: 📈 Records processed: %s", 
                if (exists("execution_result")) execution_result$records_processed else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (test_passed && script_success) {
  message("RESULT: ✅ eBay Sales ETL Import (0IM) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("eBay Sales ETL Import (0IM) failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()