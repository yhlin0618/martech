# Test script for eby_ETL_order_details_1ST___MAMBA.R
# This script tests the fixed version that handles missing columns dynamically

# Clear any existing connections first
if (exists("raw_data")) try(DBI::dbDisconnect(raw_data), silent = TRUE)
if (exists("staged_data")) try(DBI::dbDisconnect(staged_data), silent = TRUE)

# Set working directory to project root
setwd("/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA")

# Create a test environment to simulate the columns we have
message("================================================================================")
message("TEST: Simulating eby_ETL_order_details_1ST execution")
message("================================================================================")

# Load required libraries
library(DBI)
library(duckdb)
library(dplyr)
library(lubridate)
library(stringr)

# Connect to databases with exclusive mode to avoid locks
tryCatch({
  raw_data <- dbConnect(duckdb::duckdb(), 
                       "data/local_data/raw_data.duckdb", 
                       read_only = TRUE)
  
  staged_data <- dbConnect(duckdb::duckdb(), 
                          "data/local_data/staged_data.duckdb", 
                          read_only = FALSE)
  
  message("✅ Connected to databases successfully")
  
  # Read the raw data
  raw_details <- dbReadTable(raw_data, "df_eby_order_details___raw___MAMBA")
  message(sprintf("✅ Loaded %d rows from raw data", nrow(raw_details)))
  
  # Check which columns exist
  existing_columns <- names(raw_details)
  message(sprintf("📊 Found %d columns: %s", 
                  length(existing_columns), 
                  paste(existing_columns, collapse = ", ")))
  
  # Define the full column mapping
  column_mapping <- list(
    ORE001 = "order_id",
    ORE002 = "line_item_number",
    ORE003 = "warehouse_code",
    ORE004 = "transaction_date",
    ORE005 = "order_status",
    ORE006 = "product_sku",
    ORE007 = "product_title",
    ORE008 = "product_category",
    ORE009 = "quantity",
    ORE010 = "unit_price",
    ORE011 = "line_total",
    ORE012 = "discount_amount",
    ORE013 = "batch_key",
    ORE014 = "product_condition",
    ORE015 = "variation_details",
    ORE016 = "item_location",
    ORE017 = "seller_id",
    ORE018 = "seller_name",
    ORE019 = "fulfillment_type",
    ORE020 = "shipping_service",
    ORE021 = "estimated_delivery",
    ORE022 = "actual_delivery",
    ORE023 = "ebay_item_id",
    ORE024 = "ebay_transaction_id",
    ORE025 = "ebay_order_line_id",
    ORE026 = "item_cost",
    ORE027 = "shipping_cost",
    ORE028 = "tax_amount",
    ORE029 = "fee_amount",
    ORE030 = "net_amount"
  )
  
  # Filter to only columns that exist
  columns_to_rename <- column_mapping[names(column_mapping) %in% existing_columns]
  message(sprintf("🔄 Will rename %d columns (out of %d defined mappings)", 
                  length(columns_to_rename), 
                  length(column_mapping)))
  
  # Show which columns are missing
  missing_columns <- setdiff(names(column_mapping), existing_columns)
  if (length(missing_columns) > 0) {
    message(sprintf("⚠️  Missing columns: %s", paste(missing_columns, collapse = ", ")))
  }
  
  # Perform the rename
  staged_details <- raw_details %>%
    rename(!!!columns_to_rename)
  
  message(sprintf("✅ Successfully renamed columns. New column count: %d", 
                  ncol(staged_details)))
  message(sprintf("📋 New column names: %s", 
                  paste(names(staged_details), collapse = ", ")))
  
  # Apply data type conversions only for columns that exist
  staged_columns <- names(staged_details)
  
  staged_details <- staged_details %>%
    mutate(
      across(any_of(c("transaction_date")), ~as.POSIXct(., tz = "UTC")),
      across(any_of(c("estimated_delivery", "actual_delivery")), ~as.POSIXct(., tz = "UTC")),
      across(any_of(c("quantity")), ~as.integer(.)),
      across(any_of(c("unit_price", "line_total", "discount_amount", 
                      "item_cost", "shipping_cost", "tax_amount", 
                      "fee_amount", "net_amount")), ~as.numeric(.)),
      staged_timestamp = Sys.time(),
      staging_version = "2.0.0"
    )
  
  message("✅ Data type conversions completed")
  
  # Store in staged database
  table_name <- "df_eby_order_details___staged___MAMBA"
  
  if (dbExistsTable(staged_data, table_name)) {
    dbRemoveTable(staged_data, table_name)
    message(sprintf("🗑️  Dropped existing table: %s", table_name))
  }
  
  dbWriteTable(staged_data, table_name, staged_details)
  message(sprintf("✅ Stored %d rows in %s", nrow(staged_details), table_name))
  
  # Verify the data
  verification <- dbGetQuery(staged_data, 
                            sprintf("SELECT COUNT(*) as n FROM %s", table_name))
  message(sprintf("✅ Verification: %d rows in staged table", verification$n))
  
  # Show sample
  sample_data <- head(staged_details, 3)
  available_display_cols <- intersect(
    c("order_id", "line_item_number", "batch_key", "product_sku", "quantity", "line_total"),
    names(sample_data)
  )
  
  if (length(available_display_cols) > 0) {
    message("📊 Sample of staged data:")
    print(sample_data[, available_display_cols])
  }
  
}, error = function(e) {
  message(sprintf("❌ Error: %s", e$message))
}, finally = {
  # Always disconnect
  if (exists("raw_data")) try(dbDisconnect(raw_data), silent = TRUE)
  if (exists("staged_data")) try(dbDisconnect(staged_data), silent = TRUE)
  message("🔒 Database connections closed")
})

message("================================================================================")
message("TEST COMPLETED")
message("================================================================================")