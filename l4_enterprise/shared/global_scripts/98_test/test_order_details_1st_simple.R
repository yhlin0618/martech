# Simple test for order_details 1ST phase
# Bypasses autoinit to test core functionality

library(DBI)
library(duckdb)
library(dplyr)

cat("================================================================================\n")
cat("Testing Order Details 1ST Phase (Simplified)\n")
cat("================================================================================\n\n")

# Connect to databases
con_raw <- dbConnect(duckdb::duckdb(), "data/local_data/raw_data.duckdb", read_only = TRUE)
con_staged <- dbConnect(duckdb::duckdb(), "data/local_data/staged_data.duckdb", read_only = FALSE)

# Read raw data
cat("Reading raw order_details data...\n")
raw_data <- dbGetQuery(con_raw, "SELECT * FROM df_eby_order_details___raw___MAMBA")
cat(sprintf("✅ Loaded %d rows\n", nrow(raw_data)))

# Check columns
cat("\nColumns in raw data:\n")
cat(paste("  •", names(raw_data), collapse = "\n"))
cat("\n")

# Create column mapping (only for existing columns)
column_mapping <- c(
  "ORE001" = "order_id",
  "ORE002" = "line_item_number", 
  "ORE003" = "warehouse_code",
  "ORE004" = "product_name",
  "ORE005" = "spec",
  "ORE006" = "product_sku",
  "ORE007" = "condition",
  "ORE008" = "quantity",
  "ORE009" = "unit_price",
  "ORE010" = "transaction_price",
  "ORE011" = "ebay_transaction_id",
  "ORE012" = "order_date",
  "ORE013" = "batch_key",
  "ORE014" = "custom_label"
)

# Filter to only existing columns
existing_cols <- intersect(names(column_mapping), names(raw_data))
cat(sprintf("\n✅ Found %d of %d expected columns\n", 
            length(existing_cols), length(column_mapping)))

# Apply renaming only to existing columns
filtered_mapping <- column_mapping[existing_cols]
staged_data <- raw_data

for (old_name in names(filtered_mapping)) {
  new_name <- filtered_mapping[[old_name]]
  names(staged_data)[names(staged_data) == old_name] <- new_name
  cat(sprintf("  Renamed %s -> %s\n", old_name, new_name))
}

# Add metadata
staged_data$staging_timestamp <- Sys.time()
staged_data$staging_version <- "1.0.0"

# Store staged data
table_name <- "df_eby_order_details___staged___MAMBA"
if (dbExistsTable(con_staged, table_name)) {
  dbRemoveTable(con_staged, table_name)
  cat(sprintf("\nDropped existing table: %s\n", table_name))
}

dbWriteTable(con_staged, table_name, staged_data)
cat(sprintf("✅ Stored %d rows in %s\n", nrow(staged_data), table_name))

# Verify
cat("\nColumns in staged data:\n")
staged_cols <- dbListFields(con_staged, table_name)
business_cols <- grep("^(order_|line_|product_|quantity|price)", staged_cols, value = TRUE)
cat(paste("  •", business_cols[1:min(10, length(business_cols))], collapse = "\n"))

# Cleanup
dbDisconnect(con_raw)
dbDisconnect(con_staged)

cat("\n================================================================================\n")
cat("✅ Order Details 1ST Phase Test Complete\n")
cat("================================================================================\n")