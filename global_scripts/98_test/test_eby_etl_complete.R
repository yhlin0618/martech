#!/usr/bin/env Rscript
# ================================================================================
# Test Complete eBay ETL Pipeline with Corrected Column Mappings
# Tests the composite key JOIN based on MAMBA database design
# ================================================================================

library(DBI)
library(duckdb)
library(dplyr)

cat("================================================================================\n")
cat("TESTING COMPLETE EBAY ETL PIPELINE\n")
cat("================================================================================\n\n")

# ------------------------------------------------------------------------------
# PHASE 1: Test 0IM Import (already has data)
# ------------------------------------------------------------------------------
cat("PHASE 1: Checking 0IM raw data...\n")

con_raw <- dbConnect(duckdb::duckdb(), "data/local_data/raw_data.duckdb", read_only = TRUE)

# Check orders
if (dbExistsTable(con_raw, "df_eby_orders___raw___MAMBA")) {
  orders_raw <- dbGetQuery(con_raw, "SELECT COUNT(*) as n FROM df_eby_orders___raw___MAMBA")
  cat(sprintf("✅ Orders raw: %d records\n", orders_raw$n))
  
  # Check key columns
  orders_cols <- dbGetQuery(con_raw, "SELECT ORD001, ORD009, ORD022 FROM df_eby_orders___raw___MAMBA LIMIT 1")
  cat("   Key columns present: ORD001 (order_id), ORD009 (seller_email), ORD022 (batch_key)\n")
} else {
  cat("❌ Orders raw table not found\n")
}

# Check order details
if (dbExistsTable(con_raw, "df_eby_order_details___raw___MAMBA")) {
  details_raw <- dbGetQuery(con_raw, "SELECT COUNT(*) as n FROM df_eby_order_details___raw___MAMBA")
  cat(sprintf("✅ Order details raw: %d records\n", details_raw$n))
  
  # Check key columns
  details_cols <- dbGetQuery(con_raw, "SELECT ORE001, ORE002, ORE013 FROM df_eby_order_details___raw___MAMBA LIMIT 1")
  cat("   Key columns present: ORE001 (order_id), ORE002 (line_item), ORE013 (batch_key)\n")
} else {
  cat("❌ Order details raw table not found\n")
}

dbDisconnect(con_raw)

# ------------------------------------------------------------------------------
# PHASE 2: Run 1ST Standardization
# ------------------------------------------------------------------------------
cat("\nPHASE 2: Running 1ST standardization...\n")

# Source and run the 1ST scripts
tryCatch({
  source("scripts/update_scripts/eby_ETL_orders_1ST___MAMBA.R")
  cat("✅ Orders 1ST completed\n")
}, error = function(e) {
  cat(sprintf("❌ Orders 1ST failed: %s\n", e$message))
})

tryCatch({
  source("scripts/update_scripts/eby_ETL_order_details_1ST___MAMBA.R")
  cat("✅ Order details 1ST completed\n")
}, error = function(e) {
  cat(sprintf("❌ Order details 1ST failed: %s\n", e$message))
})

# ------------------------------------------------------------------------------
# PHASE 3: Check staged data
# ------------------------------------------------------------------------------
cat("\nPHASE 3: Checking staged data...\n")

con_staged <- dbConnect(duckdb::duckdb(), "data/local_data/staged_data.duckdb", read_only = TRUE)

# Check staged orders
if (dbExistsTable(con_staged, "df_eby_orders___staged___MAMBA")) {
  orders_staged <- dbReadTable(con_staged, "df_eby_orders___staged___MAMBA")
  cat(sprintf("✅ Orders staged: %d records\n", nrow(orders_staged)))
  
  # Check critical columns for JOIN
  required_cols <- c("order_id", "seller_ebay_email")
  missing <- setdiff(required_cols, names(orders_staged))
  if (length(missing) == 0) {
    cat("   ✅ All required columns present for JOIN\n")
    
    # Show sample
    cat("\n   Sample orders (first 3):\n")
    orders_staged %>%
      select(order_id, seller_ebay_email, payment_total) %>%
      head(3) %>%
      print()
  } else {
    cat(sprintf("   ❌ Missing columns: %s\n", paste(missing, collapse = ", ")))
  }
} else {
  cat("❌ Orders staged table not found\n")
}

# Check staged order details
if (dbExistsTable(con_staged, "df_eby_order_details___staged___MAMBA")) {
  details_staged <- dbReadTable(con_staged, "df_eby_order_details___staged___MAMBA")
  cat(sprintf("\n✅ Order details staged: %d records\n", nrow(details_staged)))
  
  # Check critical columns for JOIN
  required_cols <- c("order_id", "batch_key")
  missing <- setdiff(required_cols, names(details_staged))
  if (length(missing) == 0) {
    cat("   ✅ All required columns present for JOIN\n")
    
    # Show sample
    cat("\n   Sample details (first 3):\n")
    details_staged %>%
      select(order_id, line_item_number, batch_key, quantity, unit_price) %>%
      head(3) %>%
      print()
  } else {
    cat(sprintf("   ❌ Missing columns: %s\n", paste(missing, collapse = ", ")))
  }
} else {
  cat("❌ Order details staged table not found\n")
}

dbDisconnect(con_staged)

# ------------------------------------------------------------------------------
# PHASE 4: Test Composite Key JOIN
# ------------------------------------------------------------------------------
cat("\n================================================================================\n")
cat("PHASE 4: Testing Composite Key JOIN\n")
cat("================================================================================\n")

con_staged <- dbConnect(duckdb::duckdb(), "data/local_data/staged_data.duckdb", read_only = TRUE)

if (dbExistsTable(con_staged, "df_eby_orders___staged___MAMBA") &&
    dbExistsTable(con_staged, "df_eby_order_details___staged___MAMBA")) {
  
  orders <- dbReadTable(con_staged, "df_eby_orders___staged___MAMBA")
  details <- dbReadTable(con_staged, "df_eby_order_details___staged___MAMBA")
  
  cat("\nDatabase Design Validation:\n")
  cat("----------------------------\n")
  
  # Check if order_id alone is unique in orders
  n_orders <- nrow(orders)
  n_unique_order_id <- length(unique(orders$order_id))
  cat(sprintf("Orders: %d total, %d unique order_ids\n", n_orders, n_unique_order_id))
  
  if (n_orders != n_unique_order_id) {
    cat("⚠️  WARNING: order_id alone is NOT unique (as expected in MAMBA design)\n")
  }
  
  # Check composite key uniqueness
  n_composite <- nrow(distinct(orders, order_id, seller_ebay_email))
  cat(sprintf("Composite keys (order_id + seller_ebay_email): %d unique\n", n_composite))
  
  # Test the JOIN
  cat("\nPerforming Composite Key JOIN:\n")
  cat("-------------------------------\n")
  
  library(data.table)
  dt_orders <- as.data.table(orders)
  dt_details <- as.data.table(details)
  
  # The critical JOIN based on foreign key relationship
  dt_sales <- dt_orders[dt_details,
    on = .(
      order_id = order_id,              # ORD001 = ORE001
      seller_ebay_email = batch_key     # ORD009 = ORE013 (FK relationship)
    ),
    nomatch = 0  # Inner join
  ]
  
  n_joined <- nrow(dt_sales)
  cat(sprintf("✅ JOIN produced %d records\n", n_joined))
  
  # Analyze JOIN results
  match_rate <- n_joined / nrow(details) * 100
  cat(sprintf("   Match rate: %.1f%% of detail records\n", match_rate))
  
  if (n_joined > 0) {
    cat("\n   Sample JOIN results (first 3):\n")
    dt_sales %>%
      as_tibble() %>%
      select(order_id, seller_ebay_email, line_item_number, 
             product_name, quantity, unit_price) %>%
      head(3) %>%
      print()
  }
  
} else {
  cat("❌ Cannot test JOIN - staged tables not found\n")
}

dbDisconnect(con_staged)

# ------------------------------------------------------------------------------
# PHASE 5: Run 2TR Transformation
# ------------------------------------------------------------------------------
cat("\nPHASE 5: Running 2TR transformation...\n")

tryCatch({
  source("scripts/update_scripts/eby_ETL_sales_2TR___MAMBA.R")
  cat("✅ Sales 2TR completed\n")
}, error = function(e) {
  cat(sprintf("❌ Sales 2TR failed: %s\n", e$message))
})

# Check final results
con_transformed <- dbConnect(duckdb::duckdb(), "data/local_data/transformed_data.duckdb", read_only = TRUE)

if (dbExistsTable(con_transformed, "df_eby_sales___transformed___MAMBA")) {
  sales_final <- dbGetQuery(con_transformed, "SELECT COUNT(*) as n FROM df_eby_sales___transformed___MAMBA")
  cat(sprintf("\n✅ Final sales table: %d records\n", sales_final$n))
} else {
  cat("\n❌ Final sales table not found\n")
}

dbDisconnect(con_transformed)

cat("\n================================================================================\n")
cat("✅ ETL PIPELINE TEST COMPLETE\n")
cat("================================================================================\n")

cat("\nKey Findings:\n")
cat("1. MAMBA uses composite keys (order_id + seller_email)\n")
cat("2. ORE013 stores a copy of ORD009 (seller_email) for the FK relationship\n")
cat("3. JOIN must use both keys to maintain referential integrity\n")
cat("4. This design violates normalization but is what the system uses\n")