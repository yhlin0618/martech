# cbz_ETL_sales_2TR.R - Cyberbiz Sales Data Transform Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# ETL Sales Pipeline Phase 2TR (Transform): Schema standardization and enrichment
# Cyberbiz-specific sales transform implementation
#
# Transform Focus: Schema mapping, type conversions, reference joins - no business calculations
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting Cyberbiz Sales ETL Transform Phase (2TR)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for sales data transformation
message("INITIALIZE: 📦 Loading sales transform libraries...")
lib_start <- Sys.time()

library(dplyr)     # Data manipulation
library(lubridate) # Date handling

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source transform-specific functions
message("INITIALIZE: 📋 Loading sales transform functions...")
source_start <- Sys.time()

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}
if (!exists("transform_sales_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "transform", "fn_transform_sales_data.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Establish database connections
message("INITIALIZE: 🔗 Connecting to databases...")
db_start <- Sys.time()
staged_data <- dbConnectDuckdb(db_path_list$staged_data, read_only = TRUE)
transformed_data <- dbConnectDuckdb(db_path_list$transformed_data, read_only = FALSE)
reference_data <- dbConnectDuckdb(db_path_list$reference_data, read_only = TRUE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connections established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting Cyberbiz sales data transform processing...")
main_start_time <- Sys.time()

# Main execution function for Cyberbiz sales transform
main_execution <- function() {
  tryCatch({
    
    # Step 1: Read staged sales data
    message("MAIN: 📥 Reading Cyberbiz staged sales data...")
    read_start <- Sys.time()
    
    sales_staged <- tbl2(staged_data, "df_cbz_sales___staged") %>% collect()
    
    read_elapsed <- as.numeric(Sys.time() - read_start, units = "secs")
    message(sprintf("MAIN: ✅ Staged sales data loaded (%d records, %.2fs)", 
                    nrow(sales_staged), read_elapsed))
    
    # Step 2: Apply schema standardization
    message("MAIN: 📋 Applying standardized schema transformations...")
    schema_start <- Sys.time()
    
    sales_schema <- sales_staged %>%
      mutate(
        # Convert dates to proper Date type
        order_date_final = ymd(order_date),
        
        # Standardize numeric types
        quantity = as.integer(quantity),
        unit_price = round(as.numeric(unit_price), 2),
        total_amount = round(as.numeric(total_amount), 2),
        
        # Create standardized categorical fields
        payment_method_std = case_when(
          str_detect(str_to_lower(cbz_payment_method), "credit|visa|master") ~ "credit_card",
          str_detect(str_to_lower(cbz_payment_method), "paypal") ~ "digital_wallet",
          str_detect(str_to_lower(cbz_payment_method), "cash") ~ "cash",
          str_detect(str_to_lower(cbz_payment_method), "transfer|bank") ~ "bank_transfer",
          TRUE ~ "other"
        ),
        
        # Standardize member levels
        customer_tier_std = case_when(
          str_detect(str_to_lower(cbz_member_level), "vip|premium|gold") ~ "premium",
          str_detect(str_to_lower(cbz_member_level), "silver") ~ "standard",
          str_detect(str_to_lower(cbz_member_level), "bronze|basic") ~ "basic",
          TRUE ~ "unknown"
        ),
        
        # Create derived fields for analytics (structural only, no business logic)
        year = year(order_date_final),
        month = month(order_date_final),
        day_of_week = wday(order_date_final, label = TRUE),
        
        # Add transform metadata
        transform_timestamp = Sys.time(),
        schema_version = "1.0"
      )
    
    schema_elapsed <- as.numeric(Sys.time() - schema_start, units = "secs")
    message(sprintf("MAIN: ✅ Schema standardization completed (%.2fs)", schema_elapsed))
    
    # Step 3: Join with reference data (products, customers if available)
    message("MAIN: 🔗 Joining with reference data...")
    reference_start <- Sys.time()
    
    # Check if product reference data exists
    has_product_ref <- DBI::dbExistsTable(reference_data, "ref_products")
    
    if (has_product_ref) {
      product_ref <- tbl2(reference_data, "ref_products") %>% 
        filter(platform_code == "cbz") %>%
        select(product_id, product_category, product_brand) %>%
        collect()
      
      sales_enriched <- sales_schema %>%
        left_join(product_ref, by = "product_id", suffix = c("", "_ref"))
    } else {
      sales_enriched <- sales_schema %>%
        mutate(
          product_category = NA_character_,
          product_brand = NA_character_
        )
      message("MAIN: ℹ️  No product reference data found, proceeding without enrichment")
    }
    
    reference_elapsed <- as.numeric(Sys.time() - reference_start, units = "secs")
    message(sprintf("MAIN: ✅ Reference data joining completed (%.2fs)", reference_elapsed))
    
    # Step 4: Final schema compliance check
    message("MAIN: ✔️  Applying final schema compliance...")
    compliance_start <- Sys.time()
    
    sales_final <- sales_enriched %>%
      select(
        # Core standardized fields
        order_id,
        customer_id,
        product_id,
        order_date = order_date_final,
        quantity,
        unit_price,
        total_amount,
        platform_code,
        
        # Standardized categorical fields
        payment_method = payment_method_std,
        customer_tier = customer_tier_std,
        
        # Time dimensions
        year,
        month, 
        day_of_week,
        
        # Reference data
        product_category,
        product_brand,
        
        # Cyberbiz-specific extensions (preserved)
        cbz_shop_id,
        cbz_payment_id,
        cbz_member_level,
        cbz_utm_source,
        cbz_coupon_code,
        cbz_payment_method,
        cbz_shipping_method,
        
        # ETL metadata
        import_timestamp,
        staging_timestamp,
        transform_timestamp,
        schema_version
      ) %>%
      # Remove any records with critical missing data
      filter(
        !is.na(order_id),
        !is.na(customer_id),
        !is.na(product_id),
        !is.na(order_date),
        quantity > 0,
        total_amount >= 0
      )
    
    compliance_elapsed <- as.numeric(Sys.time() - compliance_start, units = "secs")
    message(sprintf("MAIN: ✅ Schema compliance applied (%.2fs)", compliance_elapsed))
    
    # Step 5: Validate transform output
    message("MAIN: ✔️  Validating transform output...")
    validation_start <- Sys.time()
    
    # Check data integrity
    validation_issues <- c()
    
    if (nrow(sales_final) == 0) {
      stop("Transform resulted in empty dataset")
    }
    
    if (nrow(sales_final) < (nrow(sales_staged) * 0.95)) {
      validation_issues <- c(validation_issues, 
                           sprintf("Lost >5%% of records in transform (%d -> %d)", 
                                  nrow(sales_staged), nrow(sales_final)))
    }
    
    if (any(is.na(sales_final$order_date))) {
      validation_issues <- c(validation_issues, 
                           sprintf("%d records with invalid dates", 
                                  sum(is.na(sales_final$order_date))))
    }
    
    if (length(validation_issues) > 0) {
      warning(sprintf("Transform validation warnings: %s", paste(validation_issues, collapse = "; ")))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Transform validation completed (%.2fs)", validation_elapsed))
    
    # Step 6: Write to transformed_data database
    message("MAIN: 💾 Writing Cyberbiz transformed sales data...")
    write_start <- Sys.time()
    
    table_name <- "df_cbz_sales___transformed"
    dbWriteTable(transformed_data, table_name, sales_final, overwrite = TRUE)
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Transformed sales data written to %s (%.2fs)", table_name, write_elapsed))
    
    # Return execution summary
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    
    result <- list(
      success = TRUE,
      records_input = nrow(sales_staged),
      records_output = nrow(sales_final),
      table_created = table_name,
      execution_time_seconds = main_elapsed,
      platform = "cbz",
      datatype = "sales",
      phase = "2TR",
      validation_issues = length(validation_issues)
    )
    
    message(sprintf("MAIN: 🎉 Cyberbiz sales transform completed successfully (%d -> %d records, %.2fs)", 
                    result$records_input, result$records_output, result$execution_time_seconds))
    
    script_success <<- TRUE
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Cyberbiz sales transform failed: %s", e$message))
    stop(sprintf("Cyberbiz Sales ETL 2TR failed: %s", e$message))
  })
}

# Execute main function
execution_result <- main_execution()

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Starting Cyberbiz sales transform validation tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify transformed table was created
    message("TEST: 📊 Checking if Cyberbiz transformed sales table was created...")
    table_name <- "df_cbz_sales___transformed"
    
    if (!DBI::dbExistsTable(transformed_data, table_name)) {
      stop(sprintf("Cyberbiz transformed sales table %s was not created", table_name))
    }
    
    # Test 2: Verify record retention
    message("TEST: 🔢 Verifying record retention after transform...")
    staged_count <- DBI::dbGetQuery(staged_data, "SELECT COUNT(*) as count FROM df_cbz_sales___staged")$count
    transformed_count <- DBI::dbGetQuery(transformed_data, sprintf("SELECT COUNT(*) as count FROM %s", table_name))$count
    
    retention_rate <- transformed_count / staged_count
    
    if (retention_rate < 0.90) {
      warning(sprintf("Low retention rate: %.1f%% (%d -> %d records)", 
                     retention_rate * 100, staged_count, transformed_count))
    } else {
      message(sprintf("TEST: ✅ Good retention rate: %.1f%% (%d records)", 
                     retention_rate * 100, transformed_count))
    }
    
    # Test 3: Verify schema standardization
    message("TEST: 📋 Verifying schema standardization...")
    schema_check <- DBI::dbGetQuery(transformed_data, sprintf("
      SELECT 
        COUNT(*) as total_records,
        COUNT(order_date) as valid_dates,
        COUNT(DISTINCT payment_method) as payment_methods,
        COUNT(DISTINCT customer_tier) as customer_tiers
      FROM %s", table_name))
    
    date_completeness <- schema_check$valid_dates / schema_check$total_records
    
    if (date_completeness >= 0.95) {
      message(sprintf("TEST: ✅ Date parsing completeness: %.1f%%", date_completeness * 100))
    } else {
      warning(sprintf("TEST: ⚠️  Low date parsing completeness: %.1f%%", date_completeness * 100))
    }
    
    # Test 4: Verify categorical standardization
    message("TEST: 🏷️  Verifying categorical field standardization...")
    categorical_stats <- DBI::dbGetQuery(transformed_data, sprintf("
      SELECT 
        payment_method,
        customer_tier,
        COUNT(*) as count
      FROM %s 
      GROUP BY payment_method, customer_tier
      ORDER BY count DESC
      LIMIT 10", table_name))
    
    standard_payment_methods <- c("credit_card", "digital_wallet", "cash", "bank_transfer", "other")
    standard_tiers <- c("premium", "standard", "basic", "unknown")
    
    invalid_payments <- setdiff(categorical_stats$payment_method, standard_payment_methods)
    invalid_tiers <- setdiff(categorical_stats$customer_tier, standard_tiers)
    
    if (length(invalid_payments) == 0 && length(invalid_tiers) == 0) {
      message("TEST: ✅ Categorical standardization successful")
    } else {
      warning(sprintf("TEST: ⚠️  Found non-standard categories - Payments: %s, Tiers: %s",
                     paste(invalid_payments, collapse = ", "),
                     paste(invalid_tiers, collapse = ", ")))
    }
    
    # Test 5: Verify data types and constraints
    message("TEST: 🔧 Verifying data types and constraints...")
    constraint_check <- DBI::dbGetQuery(transformed_data, sprintf("
      SELECT 
        MIN(quantity) as min_qty,
        MAX(quantity) as max_qty,
        MIN(total_amount) as min_amount,
        COUNT(*) as total_records,
        COUNT(CASE WHEN quantity > 0 THEN 1 END) as valid_qty,
        COUNT(CASE WHEN total_amount >= 0 THEN 1 END) as valid_amount
      FROM %s", table_name))
    
    qty_validity <- constraint_check$valid_qty / constraint_check$total_records
    amount_validity <- constraint_check$valid_amount / constraint_check$total_records
    
    if (qty_validity == 1.0 && amount_validity == 1.0) {
      message("TEST: ✅ Data constraints validation passed")
    } else {
      warning(sprintf("TEST: ⚠️  Data constraint issues - Qty validity: %.1f%%, Amount validity: %.1f%%",
                     qty_validity * 100, amount_validity * 100))
    }
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All Cyberbiz sales transform tests completed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Cyberbiz sales transform test failed: %s", e$message))
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

message("RESULT: 📊 Cyberbiz Sales ETL Transform (2TR) Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 📈 Records processed: %s -> %s", 
                if (exists("execution_result")) execution_result$records_input else "Unknown",
                if (exists("execution_result")) execution_result$records_output else "Unknown"))
message(sprintf("RESULT: 🗃️  Output table: %s", 
                if (exists("execution_result")) execution_result$table_created else "Unknown"))

if (test_passed && script_success) {
  message("RESULT: ✅ Cyberbiz Sales ETL Transform (2TR) completed successfully")
  message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))
} else {
  error_msg <- sprintf("Cyberbiz Sales ETL Transform (2TR) failed. Script success: %s, Test passed: %s", 
                      script_success, test_passed)
  if (!is.null(main_error)) {
    error_msg <- paste(error_msg, "Error:", main_error)
  }
  message(sprintf("RESULT: ❌ %s", error_msg))
  stop(error_msg)
}

# Clean up and deinitialize
autodeinit()