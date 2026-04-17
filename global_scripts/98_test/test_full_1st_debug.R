# Debug script to trace full 1ST execution
library(DBI)
library(duckdb)
library(data.table)

# Clean column names function (same as global_scripts)
clean_column_names <- function(column_names, separator = "\\.\\.") {
  pattern <- paste0(separator, ".*")
  cleaned_names <- gsub(pattern, "", column_names)
  return(cleaned_names)
}

# Connect to raw database
raw_conn <- dbConnect(duckdb(), "data/local_data/raw_data.duckdb")

# Read raw data
df_raw <- dbGetQuery(raw_conn, "SELECT * FROM df_eby_sales___raw")

message(sprintf("Loaded %d raw records", nrow(df_raw)))
message("Original columns from raw database:")
print(names(df_raw))

# Convert to data.table
dt_staging <- as.data.table(df_raw)

# Define column mapping (same as in the 1ST script)
column_mapping <- c(
  # Order header fields (BAYORD)
  "ORD001" = "order_number",
  "ORD002" = "other_order_number", 
  "ORD003" = "order_date",
  "ORD004" = "payment_date",
  "ORD005" = "total_payment",
  "ORD006" = "payment_method",
  "ORD007" = "payment_currency",
  "ORD008" = "seller_ebay_account",
  "ORD009" = "seller_ebay_email",
  "ORD010" = "recipient",
  "ORD011" = "street1",
  "ORD012" = "street2", 
  "ORD013" = "city_name",
  "ORD014" = "state_or_province",
  "ORD015" = "postal_code",
  "ORD016" = "country_name",
  "ORD020" = "buyer_ebay",
  "ORD021" = "shipping_fee",
  "ORD046" = "tax_code_type",
  "ORD047" = "tax_code", 
  "ORD048" = "vat_amount",
  
  # Order detail fields (BAYORE)
  "ORE002" = "serial_number",
  "ORE003" = "ebay_item_number",
  "ORE004" = "product_name",
  "ORE005" = "erp_product_number", 
  "ORE006" = "application_data",
  "ORE007" = "item_condition",
  "ORE008" = "quantity",
  "ORE009" = "unit_price",
  "ORE010" = "transaction_price",
  "ORE011" = "ebay_transaction_id",
  "ORE012" = "purchase_date",
  "ORE014" = "variation",
  "ORE015" = "payment_status"
)

message("\n=== STEP 1: Column Renaming ===")
renamed_count <- 0
for (old_name in names(column_mapping)) {
  if (old_name %in% names(dt_staging)) {
    new_name <- column_mapping[[old_name]]
    setnames(dt_staging, old_name, new_name)
    renamed_count <- renamed_count + 1
    message(sprintf("  Renamed %s -> %s", old_name, new_name))
  }
}
message(sprintf("Total columns renamed: %d", renamed_count))

message("\nColumns after renaming:")
print(names(dt_staging))

message("\n=== STEP 2: Clean column names ===")
names(dt_staging) <- clean_column_names(names(dt_staging))
message("Columns after clean_column_names:")
print(names(dt_staging))

# Check for unrenamed ORD/ORE columns
remaining_ord_ore <- grep("^(ORD|ORE)", names(dt_staging), value = TRUE)
if (length(remaining_ord_ore) > 0) {
  message("\n⚠️ ERROR: These ORD/ORE columns were NOT renamed:")
  print(remaining_ord_ore)
  message("\nThis violates MP064 and MP102 principles!")
} else {
  message("\n✅ SUCCESS: All ORD/ORE columns have been renamed")
}

# Now let's see what the actual 1ST script does differently
# by running it and checking the result

dbDisconnect(raw_conn)