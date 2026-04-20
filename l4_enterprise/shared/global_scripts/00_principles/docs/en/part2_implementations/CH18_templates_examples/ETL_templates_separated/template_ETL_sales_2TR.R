# Template: {platform}_ETL_sales_2TR.R - Sales Data Transform Pipeline
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP064: ETL-Derivation Separation Principle (v1.2 - includes structural JOINs)
# Following MP102: ETL Output Standardization Principle
# Following DM_R040: Structural JOIN Pattern Rule - JOINs belong in 2TR phase
# Following R113: Four-part Update Script Structure
#
# ETL Sales Pipeline Phase 2TR (Transform): Final schema transformation
# This phase handles:
# - Structural JOINs (normalized → denormalized records)
# - Schema standardization
# - Data enrichment
# - Type conversions
#
# Template for creating platform-specific sales transform scripts
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

message("INITIALIZE: ⚡ Starting {Platform} Sales ETL Transform Phase (2TR)")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries for sales data transformation
message("INITIALIZE: 📦 Loading sales transform libraries...")
lib_start <- Sys.time()

# Standard transformation libraries
library(dplyr)     # Data manipulation
library(lubridate) # Date handling
library(tidyr)     # Data tidying

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source sales-specific transformation functions
message("INITIALIZE: 📋 Loading sales transform functions...")
source_start <- Sys.time()

# Data type-specific transform functions (customize per platform)
if (!exists("transform_sales_schema", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "transform", "fn_transform_sales_schema.R"))
}
if (!exists("enrich_sales_data", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "transform", "fn_enrich_sales_data.R"))
}
if (!exists("validate_sales_transform", mode = "function")) {
  source(here::here("scripts", "global_scripts", "05_etl_utils", "common", "validation", "fn_validate_sales_transform.R"))
}

# General ETL utilities
if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Establish database connections
message("INITIALIZE: 🔗 Connecting to databases...")
db_start <- Sys.time()
staged_data <- dbConnectDuckdb(db_path_list$staged_data, read_only = TRUE)
transformed_data <- dbConnectDuckdb(db_path_list$transformed_data, read_only = FALSE)
db_elapsed <- as.numeric(Sys.time() - db_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Database connections established (%.2fs)", db_elapsed))

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting sales data transformation processing...")
main_start_time <- Sys.time()

# Main execution function for sales transformation
main_execution <- function() {
  tryCatch({
    
    # Step 1: Read sales data from staged_data
    message("MAIN: 📥 Reading sales data from staged_data...")
    read_start <- Sys.time()
    
    staged_table_name <- sprintf("df_{platform}_sales___staged")
    sales_staged <- tbl2(staged_data, staged_table_name) %>% collect()
    
    read_elapsed <- as.numeric(Sys.time() - read_start, units = "secs")
    message(sprintf("MAIN: ✅ Sales staged data read (%d records, %.2fs)", 
                    nrow(sales_staged), read_elapsed))
    
    # Step 2: STRUCTURAL JOIN (if needed for normalized sources)
    # Following DM_R040: Structural JOIN Pattern Rule
    # This is where normalized tables are combined into denormalized records
    message("MAIN: 🔗 Checking for structural JOINs...")
    
    # Example: If platform has separate order/detail tables (like eBay's BAYORD/BAYORE)
    # Uncomment and adapt this section for platforms with normalized structures:
    # if ("{platform}" %in% c("eby", "other_normalized_platform")) {
    #   orders_staged <- tbl2(staged_data, sprintf("df_{platform}_orders___staged")) %>% collect()
    #   details_staged <- tbl2(staged_data, sprintf("df_{platform}_order_details___staged")) %>% collect()
    #   
    #   sales_staged <- orders_staged %>%
    #     inner_join(details_staged, by = "order_id") %>%
    #     mutate(
    #       total_amount = quantity * unit_price,
    #       record_type = "denormalized_sale"
    #     )
    #   message(sprintf("MAIN: ✅ Structural JOIN completed (%d records)", nrow(sales_staged)))
    # }
    
    # Step 3: Apply schema transformation
    message("MAIN: 🔄 Applying schema transformation...")
    schema_start <- Sys.time()
    
    sales_schema_transformed <- transform_sales_schema(sales_staged, platform_id = "{platform}")
    
    schema_elapsed <- as.numeric(Sys.time() - schema_start, units = "secs")
    message(sprintf("MAIN: ✅ Schema transformation completed (%.2fs)", schema_elapsed))
    
    # Step 4: Apply data enrichment
    message("MAIN: 🔧 Applying data enrichment...")
    enrich_start <- Sys.time()
    
    sales_enriched <- enrich_sales_data(sales_schema_transformed, platform_id = "{platform}")
    
    enrich_elapsed <- as.numeric(Sys.time() - enrich_start, units = "secs")
    message(sprintf("MAIN: ✅ Data enrichment completed (%.2fs)", enrich_elapsed))
    
    # Step 5: Final transformation and standardization
    message("MAIN: 📋 Applying final transformation...")
    final_start <- Sys.time()
    
    sales_transformed <- sales_enriched %>%
      mutate(
        # Ensure core field types are correct for MP102 compliance
        order_id = as.character(order_id),
        customer_id = as.character(customer_id),
        product_id = as.character(product_id),
        quantity = as.integer(quantity),
        unit_price = as.numeric(unit_price),
        total_amount = as.numeric(total_amount),
        platform_id = as.character(platform_id),
        
        # Add transformation metadata
        transform_timestamp = Sys.time(),
        transform_source = "2TR_pipeline",
        data_quality_score = calculate_quality_score(.)
      ) %>%
      # Remove intermediate columns that aren't needed in final output
      select(
        # Core MP102 fields
        order_id, customer_id, order_date, product_id, 
        quantity, unit_price, total_amount, platform_id,
        
        # Parsed and enriched fields
        order_date_parsed,
        
        # Platform-specific extensions (keep all {platform}_ prefixed fields)
        starts_with("{platform}_"),
        
        # Metadata fields
        import_timestamp, staging_timestamp, transform_timestamp,
        import_source, staging_source, transform_source,
        data_quality_score
      )
    
    final_elapsed <- as.numeric(Sys.time() - final_start, units = "secs")
    message(sprintf("MAIN: ✅ Final transformation completed (%.2fs)", final_elapsed))
    
    # Step 5: Validate transformation output
    message("MAIN: ✔️  Validating transformation output...")
    validation_start <- Sys.time()
    
    validation_result <- validate_sales_transform(sales_transformed, platform_id = "{platform}")
    
    if (!validation_result$valid) {
      stop(sprintf("Sales transformation validation failed: %s", validation_result$message))
    }
    
    validation_elapsed <- as.numeric(Sys.time() - validation_start, units = "secs")
    message(sprintf("MAIN: ✅ Validation passed (%.2fs)", validation_elapsed))
    
    # Step 6: Write to transformed_data database
    message("MAIN: 💾 Writing transformed sales data to database...")
    write_start <- Sys.time()
    
    transformed_table_name <- sprintf("df_{platform}_sales___transformed")
    dbWriteTable(transformed_data, transformed_table_name, sales_transformed, overwrite = TRUE)
    
    write_elapsed <- as.numeric(Sys.time() - write_start, units = "secs")
    message(sprintf("MAIN: ✅ Transformed data written to %s (%.2fs)", transformed_table_name, write_elapsed))
    
    # Return success result
    main_elapsed <- as.numeric(Sys.time() - main_start_time, units = "secs")
    result <- list(
      success = TRUE,
      records_processed = nrow(sales_transformed),
      output_table = transformed_table_name,
      execution_time = main_elapsed
    )
    
    message(sprintf("MAIN: 🎉 Sales transformation completed successfully (%d records, %.2fs total)", 
                    result$records_processed, result$execution_time))
    
    return(result)
    
  }, error = function(e) {
    main_error <<- e$message
    message(sprintf("MAIN: ❌ Sales transformation failed: %s", e$message))
    stop(e$message)
  })
}

# Helper function for data quality scoring
calculate_quality_score <- function(data) {
  # Simple quality score based on completeness
  core_fields <- c("order_id", "customer_id", "product_id", "quantity", "unit_price", "total_amount")
  completeness_scores <- map_dbl(core_fields, ~ mean(!is.na(data[[.x]])))
  return(mean(completeness_scores))
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

message("TEST: 🧪 Running sales transformation tests...")
test_start_time <- Sys.time()

# Test execution function
test_execution <- function() {
  
  if (!script_success) {
    return(list(passed = FALSE, message = sprintf("Main execution failed: %s", main_error)))
  }
  
  # Test 1: Verify output table exists
  transformed_table_name <- sprintf("df_{platform}_sales___transformed")
  if (!dbExistsTable(transformed_data, transformed_table_name)) {
    return(list(passed = FALSE, message = sprintf("Output table %s does not exist", transformed_table_name)))
  }
  
  # Test 2: Verify record count > 0
  record_count <- dbGetQuery(transformed_data, sprintf("SELECT COUNT(*) as count FROM %s", transformed_table_name))$count
  if (record_count == 0) {
    return(list(passed = FALSE, message = "No records in transformed output"))
  }
  
  # Test 3: Verify core MP102 fields exist
  transformed_fields <- dbListFields(transformed_data, transformed_table_name)
  required_mp102_fields <- c("order_id", "customer_id", "product_id", "quantity", "unit_price", "total_amount", "platform_id")
  missing_fields <- setdiff(required_mp102_fields, transformed_fields)
  if (length(missing_fields) > 0) {
    return(list(passed = FALSE, message = sprintf("Missing MP102 required fields: %s", paste(missing_fields, collapse = ", "))))
  }
  
  # Test 4: Verify metadata fields exist
  metadata_fields <- c("import_timestamp", "staging_timestamp", "transform_timestamp")
  missing_metadata <- setdiff(metadata_fields, transformed_fields)
  if (length(missing_metadata) > 0) {
    return(list(passed = FALSE, message = sprintf("Missing metadata fields: %s", paste(missing_metadata, collapse = ", "))))
  }
  
  # Test 5: Verify platform_id consistency
  platform_check <- dbGetQuery(transformed_data, sprintf("SELECT DISTINCT platform_id FROM %s", transformed_table_name))
  if (nrow(platform_check) != 1 || platform_check$platform_id[1] != "{platform}") {
    return(list(passed = FALSE, message = "Platform ID inconsistency detected"))
  }
  
  # Test 6: Verify data quality score exists and is reasonable
  quality_check <- dbGetQuery(transformed_data, sprintf("SELECT AVG(data_quality_score) as avg_quality FROM %s", transformed_table_name))
  if (is.na(quality_check$avg_quality) || quality_check$avg_quality < 0 || quality_check$avg_quality > 1) {
    return(list(passed = FALSE, message = "Invalid data quality scores detected"))
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
  message(sprintf("RESULT: 🎉 {Platform} Sales ETL Transform completed successfully (%.2fs total)", total_elapsed))
  message(sprintf("RESULT: 📊 Output: df_{platform}_sales___transformed"))
} else {
  error_msg <- ifelse(!script_success, main_error, test_result$message)
  message(sprintf("RESULT: ❌ {Platform} Sales ETL Transform failed: %s (%.2fs total)", error_msg, total_elapsed))
  stop(sprintf("{Platform} Sales ETL Transform (2TR) failed: %s", error_msg))
}

# Cleanup and autodeinit
autodeinit()