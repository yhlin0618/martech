# Test Complete MAMBA eBay ETL Pipeline
# Tests the full flow: orders + order_details → sales

library(DBI)
library(duckdb)

cat("================================================================================\n")
cat("Testing Complete MAMBA eBay ETL Pipeline\n")
cat("================================================================================\n\n")

# Check all required tables
cat("📊 Checking BASE ETL outputs...\n")

# Connect to raw_data
con_raw <- dbConnect(duckdb::duckdb(), "data/local_data/raw_data.duckdb", read_only = TRUE)

# Check orders
orders_table <- "df_eby_orders___raw___MAMBA"
if(dbExistsTable(con_raw, orders_table)) {
  orders_count <- dbGetQuery(con_raw, sprintf("SELECT COUNT(*) as n FROM %s", orders_table))$n
  cat(sprintf("✅ Orders: %d records in %s\n", orders_count, orders_table))
} else {
  cat(sprintf("❌ Orders table not found: %s\n", orders_table))
  orders_count <- 0
}

# Check order_details
details_table <- "df_eby_order_details___raw___MAMBA"
if(dbExistsTable(con_raw, details_table)) {
  details_count <- dbGetQuery(con_raw, sprintf("SELECT COUNT(*) as n FROM %s", details_table))$n
  cat(sprintf("✅ Order Details: %d records in %s\n", details_count, details_table))
} else {
  cat(sprintf("❌ Order Details table not found: %s\n", details_table))
  details_count <- 0
}

dbDisconnect(con_raw)

# Test JOIN capability
if(orders_count > 0 && details_count > 0) {
  cat("\n📊 Testing JOIN capability for DERIVED sales ETL...\n")
  
  # Connect again for JOIN test
  con <- dbConnect(duckdb::duckdb(), "data/local_data/raw_data.duckdb", read_only = TRUE)
  
  # Test JOIN
  join_query <- sprintf("
    SELECT COUNT(*) as matches
    FROM %s o
    INNER JOIN %s d
    ON o.ORD001 = d.ORE001
  ", orders_table, details_table)
  
  matches <- dbGetQuery(con, join_query)$matches
  cat(sprintf("✅ JOIN test: %d matching records between orders and order_details\n", matches))
  
  # Sample joined data
  sample_query <- sprintf("
    SELECT 
      o.ORD001 as order_id,
      o.ORD003 as order_date,
      o.ORD016 as country,
      d.ORE002 as line_number,
      d.ORE003 as product_sku
    FROM %s o
    INNER JOIN %s d
    ON o.ORD001 = d.ORE001
    LIMIT 5
  ", orders_table, details_table)
  
  sample_data <- dbGetQuery(con, sample_query)
  cat("\nSample joined data:\n")
  print(sample_data)
  
  dbDisconnect(con)
  
  cat("\n✅ Pipeline Status:\n")
  cat("   • BASE ETL (orders): Ready ✅\n")
  cat("   • BASE ETL (order_details): Ready ✅\n")
  cat("   • DERIVED ETL (sales): Can be executed ✅\n")
  
  cat("\n💡 Next Steps:\n")
  cat("   1. Run: Rscript scripts/update_scripts/eby_ETL_orders_1ST___MAMBA.R\n")
  cat("   2. Run: Rscript scripts/update_scripts/eby_ETL_order_details_1ST___MAMBA.R\n")
  cat("   3. Run: Rscript scripts/update_scripts/eby_ETL_sales_2TR___MAMBA.R\n")
  
} else {
  cat("\n❌ Cannot test JOIN - missing data\n")
  if(orders_count == 0) cat("   Need to run: eby_ETL_orders_0IM___MAMBA.R\n")
  if(details_count == 0) cat("   Need to run: eby_ETL_order_details_0IM___MAMBA.R\n")
}

cat("\n================================================================================\n")
cat("Test Complete\n")
cat("================================================================================\n")