# Test MAMBA ETL Pipeline
# This script tests the separated eBay ETL pipeline

message("================================================================================")
message("Testing MAMBA ETL Pipeline - Data Processing Update")
message("================================================================================")

# Set working directory
setwd("/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA")

# Check if we have the necessary environment variables
# For testing, we'll use dummy values if not set
if (Sys.getenv("EBY_SSH_HOST") == "") {
  message("⚠️ Environment variables not set. This is a test run without actual data connection.")
  message("   To run with real data, please set the following environment variables:")
  message("   - EBY_SSH_HOST, EBY_SSH_USER, EBY_SSH_PASSWORD")
  message("   - EBY_SQL_HOST, EBY_SQL_PORT, EBY_SQL_USER, EBY_SQL_PASSWORD, EBY_SQL_DATABASE")
}

# Check if databases exist
library(DBI)
library(duckdb)

message("\n📊 Checking database structure...")

# Check raw_data database
if (file.exists("data/local_data/raw_data.duckdb")) {
  con_raw <- dbConnect(duckdb::duckdb(), "data/local_data/raw_data.duckdb", read_only = TRUE)
  tables_raw <- dbListTables(con_raw)
  message(sprintf("✅ raw_data.duckdb exists with %d tables", length(tables_raw)))
  
  # Check for eBay tables
  eby_tables <- grep("eby", tables_raw, value = TRUE)
  if (length(eby_tables) > 0) {
    message("   Found eBay tables:")
    for (tbl in eby_tables) {
      count <- dbGetQuery(con_raw, sprintf("SELECT COUNT(*) as n FROM %s", tbl))$n
      message(sprintf("   - %s: %d rows", tbl, count))
    }
  }
  dbDisconnect(con_raw)
} else {
  message("❌ raw_data.duckdb not found")
}

# Check staged_data database
if (file.exists("data/local_data/staged_data.duckdb")) {
  con_staged <- dbConnect(duckdb::duckdb(), "data/local_data/staged_data.duckdb", read_only = TRUE)
  tables_staged <- dbListTables(con_staged)
  message(sprintf("✅ staged_data.duckdb exists with %d tables", length(tables_staged)))
  
  # Check for eBay tables
  eby_tables <- grep("eby", tables_staged, value = TRUE)
  if (length(eby_tables) > 0) {
    message("   Found eBay tables:")
    for (tbl in eby_tables) {
      count <- dbGetQuery(con_staged, sprintf("SELECT COUNT(*) as n FROM %s", tbl))$n
      message(sprintf("   - %s: %d rows", tbl, count))
    }
  }
  dbDisconnect(con_staged)
} else {
  message("❌ staged_data.duckdb not found")
}

# Check transformed_data database
if (file.exists("data/local_data/transformed_data.duckdb")) {
  con_trans <- dbConnect(duckdb::duckdb(), "data/local_data/transformed_data.duckdb", read_only = TRUE)
  tables_trans <- dbListTables(con_trans)
  message(sprintf("✅ transformed_data.duckdb exists with %d tables", length(tables_trans)))
  
  # Check for eBay tables
  eby_tables <- grep("eby", tables_trans, value = TRUE)
  if (length(eby_tables) > 0) {
    message("   Found eBay tables:")
    for (tbl in eby_tables) {
      count <- dbGetQuery(con_trans, sprintf("SELECT COUNT(*) as n FROM %s", tbl))$n
      message(sprintf("   - %s: %d rows", tbl, count))
    }
  }
  dbDisconnect(con_trans)
} else {
  message("❌ transformed_data.duckdb not found")
}

message("\n🔍 ETL Scripts Available:")
etl_scripts <- list.files("scripts/update_scripts", pattern = "ETL.*\\.R$", full.names = FALSE)
eby_scripts <- grep("eby", etl_scripts, value = TRUE)
if (length(eby_scripts) > 0) {
  message("   eBay ETL scripts:")
  for (script in eby_scripts) {
    message(sprintf("   - %s", script))
  }
}

message("\n📋 ETL Pipeline Structure (per MP107 + MP108):")
message("   Horizontal Independence (MP107): Different ETLs can run in parallel")
message("   Vertical Sequence (MP108): Phases must run in order 0IM → 1ST → 2TR")

message("\n🚀 Recommended Execution Order for Full Update:")
message("   1. eby_ETL_orders_0IM___MAMBA.R")
message("   2. eby_ETL_orders_1ST___MAMBA.R")
message("   3. eby_ETL_order_details_0IM___MAMBA.R")
message("   4. eby_ETL_order_details_1ST___MAMBA.R")
message("   5. eby_ETL_sales_2TR___MAMBA.R (performs JOIN)")

message("\n================================================================================")
message("Test Complete. Use the scripts above to run the full data processing update.")
message("================================================================================")