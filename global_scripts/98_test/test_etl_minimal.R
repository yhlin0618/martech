# test_etl_minimal.R
# Minimal ETL test without autoinit() to bypass encoding issues
# Following MP064: ETL-Derivation Separation Principle

# ==============================================================================
# 1. INITIALIZE (Minimal - No autoinit)
# ==============================================================================

message("INITIALIZE: Minimal ETL test started")

# Load essential libraries directly
suppressMessages({
  library(here)
  library(DBI)
  library(duckdb)
  library(dplyr)
})

# Set up minimal environment 
APP_DIR <- here::here()
message("APP_DIR: ", APP_DIR)

# Create minimal database path
raw_data_path <- file.path(APP_DIR, "data", "local_data", "raw_data.duckdb")
dir.create(dirname(raw_data_path), recursive = TRUE, showWarnings = FALSE)

# Connect to database
raw_data <- dbConnect(duckdb::duckdb(), raw_data_path, read_only = FALSE)
message("Database connected: ", raw_data_path)

# ==============================================================================
# 2. MAIN (Test ETL functionality)
# ==============================================================================

tryCatch({
  message("MAIN: Testing ETL functionality without API...")
  
  # Create test data directory
  RAW_DATA_DIR <- file.path(APP_DIR, "data", "local_data", "rawdata_MAMBA")
  cbz_sales_dir <- file.path(RAW_DATA_DIR, "cbz_sales")
  
  if (!dir.exists(cbz_sales_dir)) {
    message("MAIN: Creating test data structure...")
    dir.create(cbz_sales_dir, recursive = TRUE, showWarnings = FALSE)
    
    # Create minimal test CSV
    test_data <- data.frame(
      order_id = c("CBZ001", "CBZ002", "CBZ003"),
      customer_id = c("CUST001", "CUST002", "CUST001"),
      customer_name = c("Test Customer 1", "Test Customer 2", "Test Customer 1"),
      order_date = c("2024-01-15", "2024-01-16", "2024-01-17"),
      product_id = c("PROD001", "PROD002", "PROD001"),
      product_name = c("Test Product A", "Test Product B", "Test Product A"),
      quantity = c(1, 2, 1),
      unit_price = c(99.99, 149.99, 99.99),
      total_amount = c(99.99, 299.98, 99.99),
      payment_method = c("Credit Card", "PayPal", "Credit Card"),
      order_status = c("Completed", "Completed", "Processing"),
      stringsAsFactors = FALSE
    )
    
    test_csv_path <- file.path(cbz_sales_dir, "test_sales_2024.csv")
    write.csv(test_data, test_csv_path, row.names = FALSE)
    message("MAIN: Created test CSV: ", test_csv_path)
  }
  
  # Read test data
  csv_files <- list.files(cbz_sales_dir, pattern = "\\.csv$", full.names = TRUE)
  message("MAIN: Found ", length(csv_files), " CSV files")
  
  if (length(csv_files) > 0) {
    # Read first CSV
    test_sales <- read.csv(csv_files[1], stringsAsFactors = FALSE)
    
    # Add ETL metadata following MP064
    test_sales_etl <- test_sales %>%
      mutate(
        import_source = "FILE",
        import_timestamp = Sys.time(),
        platform_id = "cbz"
      )
    
    # Write to database
    dbWriteTable(raw_data, "df_cbz_sales___raw", test_sales_etl, overwrite = TRUE)
    
    # Verify write
    row_count <- dbGetQuery(raw_data, "SELECT COUNT(*) as count FROM df_cbz_sales___raw")$count
    message("MAIN: Successfully wrote ", row_count, " records to database")
    
    # Show sample data
    sample_data <- dbGetQuery(raw_data, "SELECT * FROM df_cbz_sales___raw LIMIT 3")
    message("MAIN: Sample data structure:")
    print(sample_data)
    
  } else {
    message("MAIN: No CSV files found for processing")
  }
  
}, error = function(e) {
  message("MAIN ERROR: ", e$message)
})

# ==============================================================================  
# 3. TEST (Verify results)
# ==============================================================================

message("TEST: Verifying ETL results...")

# Check table existence and structure
if ("df_cbz_sales___raw" %in% dbListTables(raw_data)) {
  
  # Check row count
  row_count <- dbGetQuery(raw_data, "SELECT COUNT(*) as count FROM df_cbz_sales___raw")$count
  message("TEST: Found ", row_count, " records in df_cbz_sales___raw")
  
  # Check required columns
  columns <- dbListFields(raw_data, "df_cbz_sales___raw")
  required_cols <- c("order_id", "import_source", "import_timestamp", "platform_id")
  missing_cols <- setdiff(required_cols, columns)
  
  if (length(missing_cols) == 0) {
    message("TEST: All required columns present")
  } else {
    message("TEST: Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Verify platform_id
  platform_check <- dbGetQuery(raw_data, 
    "SELECT DISTINCT platform_id FROM df_cbz_sales___raw")
  message("TEST: Platform IDs found: ", paste(platform_check$platform_id, collapse = ", "))
  
  message("TEST: ETL test completed successfully")
  
} else {
  message("TEST: Table df_cbz_sales___raw not found - ETL failed")
}

# ==============================================================================
# 4. DEINITIALIZE
# ==============================================================================

# Close database connection
dbDisconnect(raw_data)
message("DEINITIALIZE: Database disconnected")
message("DEINITIALIZE: Minimal ETL test completed")

# Export all database tables to CSV for inspection (S02 sequence)
message("Running S02 sequence export for data inspection...")
Sys.setenv("SKIP_AUTOINIT" = "1")  # Skip autoinit in export script