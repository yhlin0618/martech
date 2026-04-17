# Test script to verify column mapping logic
# This tests the dynamic column checking before renaming

library(dplyr)

# Simulate the raw data structure (only ORE001-ORE014)
raw_columns <- paste0("ORE", sprintf("%03d", 1:14))
message(sprintf("Raw data has %d columns: %s", 
                length(raw_columns), 
                paste(raw_columns, collapse = ", ")))

# Define the full column mapping (as in the 1ST script)
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
  ORE015 = "variation_details",    # NOT IN RAW DATA
  ORE016 = "item_location",         # NOT IN RAW DATA
  ORE017 = "seller_id",             # NOT IN RAW DATA
  ORE018 = "seller_name",           # NOT IN RAW DATA
  ORE019 = "fulfillment_type",      # NOT IN RAW DATA
  ORE020 = "shipping_service",      # NOT IN RAW DATA
  ORE021 = "estimated_delivery",    # NOT IN RAW DATA
  ORE022 = "actual_delivery",       # NOT IN RAW DATA
  ORE023 = "ebay_item_id",          # NOT IN RAW DATA
  ORE024 = "ebay_transaction_id",   # NOT IN RAW DATA
  ORE025 = "ebay_order_line_id",    # NOT IN RAW DATA
  ORE026 = "item_cost",             # NOT IN RAW DATA
  ORE027 = "shipping_cost",         # NOT IN RAW DATA
  ORE028 = "tax_amount",            # NOT IN RAW DATA
  ORE029 = "fee_amount",            # NOT IN RAW DATA
  ORE030 = "net_amount"             # NOT IN RAW DATA
)

message(sprintf("\nFull mapping has %d column definitions", length(column_mapping)))

# Filter mapping to only include columns that exist
columns_to_rename <- column_mapping[names(column_mapping) %in% raw_columns]

message(sprintf("\nAfter filtering, will rename %d columns:", length(columns_to_rename)))
for (old_name in names(columns_to_rename)) {
  new_name <- columns_to_rename[[old_name]]
  message(sprintf("  %s -> %s", old_name, new_name))
}

# Check for missing columns
missing_columns <- setdiff(names(column_mapping), raw_columns)
message(sprintf("\n⚠️  Missing %d columns from the mapping:", length(missing_columns)))
message(paste("  ", missing_columns, collapse = "\n"))

# Check critical columns
critical_columns <- c("ORE001", "ORE002", "ORE004", "ORE013")
critical_present <- critical_columns %in% raw_columns
message(sprintf("\n✅ Critical columns status:"))
for (i in seq_along(critical_columns)) {
  status <- if(critical_present[i]) "✓" else "✗"
  message(sprintf("  %s %s", status, critical_columns[i]))
}

# Create test data frame with the actual columns
test_data <- data.frame(
  ORE001 = "ORDER123",
  ORE002 = 1,
  ORE003 = "WH01",
  ORE004 = "2024-01-01",
  ORE005 = "COMPLETED",
  ORE006 = "SKU123",
  ORE007 = "Test Product",
  ORE008 = "Electronics",
  ORE009 = 2,
  ORE010 = 99.99,
  ORE011 = 199.98,
  ORE012 = 10.00,
  ORE013 = "BATCH001",
  ORE014 = "NEW"
)

message("\n🧪 Testing rename operation on sample data...")

# Test the rename operation
# For rename(), we need new_name = old_name format
# So we need to swap the names and values
rename_args <- setNames(names(columns_to_rename), unlist(columns_to_rename))
renamed_data <- test_data %>%
  rename(!!!rename_args)

message(sprintf("✅ Rename successful! New columns:"))
message(paste("  ", names(renamed_data), collapse = "\n"))

message("\n✅ TEST PASSED: Dynamic column mapping works correctly!")