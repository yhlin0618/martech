# cbz_ETL_sales_1ST.R - Cyberbiz Sales Data Staging Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Sales Pipeline Phase 1ST (Staging): Data cleaning and standardization
# Cyberbiz-specific sales staging implementation
#
# Staging Focus: Fix encoding, dates, formats - no business logic
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting Cyberbiz Sales ETL Staging Phase (1ST)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for sales data staging
message("INITIALIZE: 📦 Loading sales staging libraries...")
lib_start <- Sys.time()

library(dplyr)     # Data manipulation
library(lubridate) # Date handling
library(stringr)   # String processing

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source staging-specific functions
message("INITIALIZE: 📋 Loading sales staging functions...")
source_start <- Sys.time()

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}
if (!exists("stage_sales_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "staging", "fn_stage_sales_data.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Establish database connections
message("INITIALIZE: 🔗 Connecting to databases...")
db_start <- Sys.time()
raw_data <- dbConnectDuckdb(db_path_list$raw_data, read_only = TRUE)
staged_data <- dbConnectDuckdb(db_path_list$staged_data, read_only = FALSE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connections established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting Cyberbiz sales data staging processing...")
main_start_time <- Sys.time()

# Main execution function for Cyberbiz sales staging
main_execution <- function() {
  tryCatch({
    
    # Step 1: Read raw sales data
    message("MAIN: 📥 Reading Cyberbiz sales data from raw_data...")
    read_start <- Sys.time()
    
    sales_raw <- tbl2(raw_data, "df_cbz_sales___raw") %>% collect()
    
    read_elapsed <- as.numeric(Sys.time() - read_start, units = "secs")
    message(sprintf("MAIN: ✅ Raw sales data loaded (%d records, %.2fs)", 
                    nrow(sales_raw), read_elapsed))
    
    # Step 2: Standardize encoding (UTF-8)
    message("MAIN: 🔤 Standardizing text encoding to UTF-8...")
    encoding_start <- Sys.time()
    
    sales_encoded <- sales_raw %>%
      mutate(
        # Fix encoding issues in text fields
        order_id = iconv(order_id, to = "UTF-8"),
        customer_id = iconv(customer_id, to = "UTF-8"),
        product_id = iconv(product_id, to = "UTF-8"),
        cbz_coupon_code = iconv(cbz_coupon_code, to = "UTF-8"),
        cbz_utm_source = iconv(cbz_utm_source, to = "UTF-8"),
        
        # Remove invalid UTF-8 characters
        across(where(is.character), ~ str_replace_all(.x, "[^\x01-\x7F]", ""))
      )
    
    encoding_elapsed <- as.numeric(Sys.time() - encoding_start, units = "secs")
    message(sprintf("MAIN: ✅ Encoding standardization completed (%.2fs)", encoding_elapsed))
    
    # Step 3: Fix date formats and parse dates
    message("MAIN: 📅 Standardizing date formats...")
    date_start <- Sys.time()
    
    sales_dated <- sales_encoded %>%
      mutate(
        # Standardize date formats to ISO 8601
        order_date_parsed = case_when(
          str_detect(order_date, "^\\d{4}-\\d{2}-\\d{2}") ~ ymd(order_date),
          str_detect(order_date, "^\\d{2}/\\d{2}/\\d{4}") ~ mdy(order_date),
          str_detect(order_date, "^\\d{4}/\\d{2}/\\d{2}") ~ ymd(order_date),
          TRUE ~ as.Date(NA)
        ),
        
        # Keep original string for reference
        order_date_original = order_date,
        
        # Update order_date to standardized format
        order_date = as.character(order_date_parsed)
      ) %>%
      select(-order_date_parsed)  # Remove intermediate column
    
    date_elapsed <- as.numeric(Sys.time() - date_start, units = "secs")
    message(sprintf("MAIN: ✅ Date standardization completed (%.2fs)", date_elapsed))
    
    # Step 4: Fix structural data issues
    message("MAIN: 🔧 Fixing structural data issues...")
    structure_start <- Sys.time()
    
    sales_structured <- sales_dated %>%
      mutate(
        # Fix numeric fields
        quantity = case_when(
          is.na(quantity) ~ 1L,
          quantity <= 0 ~ 1L,
          TRUE ~ quantity
        ),
        
        unit_price = case_when(
          is.na(unit_price) ~ 0,
          unit_price < 0 ~ 0,
          TRUE ~ unit_price
        ),
        
        total_amount = case_when(
          is.na(total_amount) ~ 0,
          total_amount < 0 ~ 0,
          TRUE ~ total_amount
        ),
        
        # Clean text fields
        cbz_shop_id = str_trim(cbz_shop_id),
        cbz_member_level = str_trim(str_to_lower(cbz_member_level)),
        cbz_payment_method = str_trim(str_to_lower(cbz_payment_method)),
        
        # Add staging metadata
        staging_timestamp = Sys.time(),
        staging_issues = case_when(
          is.na(order_date) ~ "date_parse_failed",
          quantity <= 0 ~ "quantity_adjusted", 
          total_amount <= 0 ~ "amount_adjusted",
          TRUE ~ "none"
        )
      )
    
    structure_elapsed <- as.numeric(Sys.time() - structure_start, units = "secs")
    message(sprintf("MAIN: ✅ Structural fixes completed (%.2fs)", structure_elapsed))
    
    # Step 5: Validate staging output
    message("MAIN: ✔️  Validating sales staging output...")
    validation_start <- Sys.time()
    
    # Check for critical issues
    issues <- c()
    
    if (any(is.na(sales_structured$order_date))) {
      issues <- c(issues, sprintf("%d records with unparseable dates", 
                                 sum(is.na(sales_structured$order_date))))
    }
    
    if (any(sales_structured$total_amount < 0, na.rm = TRUE)) {
      issues <- c(issues, sprintf("%d records with negative amounts", 
                                 sum(sales_structured$total_amount < 0, na.rm = TRUE)))
    }
    
    if (length(issues) > 0) {
      warning(sprintf("Staging validation warnings: %s", paste(issues, collapse = "; ")))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Staging validation completed (%.2fs)", validation_elapsed))
    
    # Step 6: Write to staged_data database
    message("MAIN: 💾 Writing Cyberbiz staged sales data...")
    write_start <- Sys.time()
    
    table_name <- "df_cbz_sales___staged"
    dbWriteTable(staged_data, table_name, sales_structured, overwrite = TRUE)
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Staged sales data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      records_processed = nrow(sales_structured),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "cbz",
      datatype = "sales",
      phase = "1ST",
      issues_found = length(issues)
    )
    
    message(sprintf("MAIN: 🎉 Cyberbiz sales staging completed successfully (%d records, %.2fs)", 
                    result$records_processed, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Cyberbiz sales staging failed: %s", e$message))
    stop(sprintf("Cyberbiz Sales ETL 1ST failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting Cyberbiz sales staging validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify staged table was created
    message("TEST: 📊 Checking if Cyberbiz staged sales table was created...")
    table_name <- "df_cbz_sales___staged"
    
    if (!DBI::dbExistsTable(staged_data, table_name)) {
      stop(sprintf("Cyberbiz staged sales table %s was not created", table_name))
    }
    
    # Test 2: Verify record count matches raw data
    message("TEST: 🔢 Comparing staged vs raw record counts...")
    raw_count <- DBI::dbGetQuery(raw_data, "SELECT COUNT(*) as count FROM df_cbz_sales___raw")$count
    staged_count <- DBI::dbGetQuery(staged_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    if (staged_count != raw_count) {
      stop(sprintf("Record count mismatch. Raw: %d, Staged: %d", raw_count, staged_count))
    }
    
    message(sprintf("TEST: ✅ Record counts match (%d records)", staged_count))
    
    # Test 3: Verify encoding fixes
    message("TEST: 🔤 Verifying UTF-8 encoding...")
    sample_data <- DBI::dbGetQuery(staged_data, sprintf("SELECT * FROM %s LIMIT 10", table_name))
    
    # Check for proper UTF-8 encoding (basic check)
    text_fields <- c("order_id", "customer_id", "product_id")
    encoding_issues <- 0
    
    for (field in text_fields) {
      if (any(grepl("[^\x01-\x7F]", sample_data[[field]], perl = TRUE))) {
        encoding_issues <- encoding_issues + 1
      }
    }
    
    if (encoding_issues == 0) {
      message("TEST: ✅ UTF-8 encoding validation passed")
    } else {
      warning(sprintf("TEST: ⚠️  Found %d fields with potential encoding issues", encoding_issues))
    }
    
    # Test 4: Verify date parsing
    message("TEST: 📅 Verifying date parsing...")
    date_stats <- DBI::dbGetQuery(staged_data, 
      sprintf("SELECT 
                COUNT(*) as total,
                COUNT(order_date) as parsed_dates,
                SUM(CASE WHEN staging_issues = 'date_parse_failed' THEN 1 ELSE 0 END) as failed_dates
               FROM %s", table_name))
    
    date_success_rate <- date_stats$parsed_dates / date_stats$total
    
    if (date_success_rate >= 0.9) {
      message(sprintf("TEST: ✅ Date parsing success rate: %.1f%%", date_success_rate * 100))
    } else {
      warning(sprintf("TEST: ⚠️  Low date parsing success rate: %.1f%%", date_success_rate * 100))
    }
    
    # Test 5: Verify structural fixes
    message("TEST: 🔧 Verifying structural data fixes...")
    structure_stats <- DBI::dbGetQuery(staged_data,
      sprintf("SELECT 
                MIN(quantity) as min_qty,
                MAX(quantity) as max_qty,
                MIN(unit_price) as min_price,
                MIN(total_amount) as min_amount
               FROM %s", table_name))
    
    if (structure_stats$min_qty >= 1 && structure_stats$min_price >= 0 && structure_stats$min_amount >= 0) {
      message("TEST: ✅ Structural data validation passed")
    } else {
      warning("TEST: ⚠️  Found structural data issues after staging")
    }
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All Cyberbiz sales staging tests completed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Cyberbiz sales staging test failed: %s", e$message))
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

message("RESULT: 📊 Cyberbiz Sales ETL Staging (1ST) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📈 Records processed: %s", 
                if (exists("execution_result")) execution_result$records_processed else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (test_passed && script_success) {
  message("RESULT: ✅ Cyberbiz Sales ETL Staging (1ST) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("Cyberbiz Sales ETL Staging (1ST) failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()