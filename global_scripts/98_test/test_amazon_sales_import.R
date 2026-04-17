# Test Script for Amazon Sales Data Structure
# Run this script to examine the structure of the Amazon sales data
# and diagnose any issues with the data format or table structure.

# Initialize the environment
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))

# Connect to databases
message("Connecting to databases...")
raw_data <- tryCatch({
  dbConnect_from_list("raw_data", read_only = TRUE)
}, error = function(e) {
  message("Could not connect to raw_data: ", e$message)
  NULL
})

cleansed_data <- tryCatch({
  dbConnect_from_list("cleansed_data", read_only = TRUE)
}, error = function(e) {
  message("Could not connect to cleansed_data: ", e$message)
  NULL
})

# Check if we could connect to any database
if (is.null(raw_data) && is.null(cleansed_data)) {
  stop("Could not connect to any database. Please check database configuration.")
}

# First check raw data if available
if (!is.null(raw_data)) {
  message("\n=== RAW DATA DATABASE ===")
  
  # List all tables
  tables <- dbListTables(raw_data)
  message("Tables in raw_data:")
  print(tables)
  
  # Check for amazon_sales_dta table
  if ("amazon_sales_dta" %in% tables) {
    message("\nExamining amazon_sales_dta in raw database...")
    
    # Get column information
    tryCatch({
      cols <- dbListFields(raw_data, "amazon_sales_dta")
      message("Columns in raw amazon_sales_dta:")
      print(cols)
      
      # Sample data
      raw_sample <- tbl(raw_data, "amazon_sales_dta") %>% head(5) %>% collect()
      message("\nSample data from raw amazon_sales_dta:")
      print(raw_sample)
      
      # Check for key columns
      key_cols <- c("buyer_email", "customer_email", "email", "customer_id", 
                   "purchase_date", "order_date", "sku", "asin", "product_id")
      found_cols <- intersect(key_cols, cols)
      
      message("\nKey columns found:")
      print(found_cols)
      
      missing_cols <- setdiff(key_cols, cols)
      message("\nMissing key columns:")
      print(missing_cols)
      
      # Count rows
      row_count <- tbl(raw_data, "amazon_sales_dta") %>% count() %>% pull()
      message("\nTotal rows in raw_data.amazon_sales_dta:", row_count)
      
    }, error = function(e) {
      message("Error examining raw amazon_sales_dta: ", e$message)
    })
  } else {
    message("No amazon_sales_dta table found in raw database!")
  }
}

# Check cleansed data if available
if (!is.null(cleansed_data)) {
  message("\n\n=== CLEANSED DATA DATABASE ===")
  
  # List all tables
  tables <- dbListTables(cleansed_data)
  message("Tables in cleansed_data:")
  print(tables)
  
  # Check for amazon_sales_dta table
  if ("amazon_sales_dta" %in% tables) {
    message("\nExamining amazon_sales_dta in cleansed database...")
    
    # Get column information
    tryCatch({
      cols <- dbListFields(cleansed_data, "amazon_sales_dta")
      message("Columns in cleansed amazon_sales_dta:")
      print(cols)
      
      # Sample data
      cleansed_sample <- tbl(cleansed_data, "amazon_sales_dta") %>% head(5) %>% collect()
      message("\nSample data from cleansed amazon_sales_dta:")
      print(cleansed_sample)
      
      # Check for required columns for DNA analysis
      required_cols <- c("customer_id", "time", "sku")
      missing_required <- setdiff(required_cols, cols)
      
      if (length(missing_required) > 0) {
        message("\nWARNING: Missing required columns for DNA analysis:")
        print(missing_required)
      } else {
        message("\nAll required columns for DNA analysis are present!")
      }
      
      # Count rows
      row_count <- tbl(cleansed_data, "amazon_sales_dta") %>% count() %>% pull()
      message("\nTotal rows in cleansed_data.amazon_sales_dta:", row_count)
      
    }, error = function(e) {
      message("Error examining cleansed amazon_sales_dta: ", e$message)
    })
  } else {
    message("No amazon_sales_dta table found in cleansed database!")
  }
}

# Suggest fixes based on findings
message("\n\n=== RECOMMENDATIONS ===")

# Disconnect from databases
if (!is.null(raw_data)) dbDisconnect(raw_data)
if (!is.null(cleansed_data)) dbDisconnect(cleansed_data)

message("\nTest complete. Use the information above to diagnose any issues with the Amazon sales data.")