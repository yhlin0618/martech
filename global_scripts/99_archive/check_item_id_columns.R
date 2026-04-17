#!/usr/bin/env Rscript
# =============================================================
# Check which tables have item_id column
# This script helps identify all tables that need column renaming
# =============================================================

library(DBI)
library(duckdb)

# Function to check columns in a database
check_database_columns <- function(db_path, db_name) {
  if (!file.exists(db_path)) {
    message("⚠️  Database not found: ", db_path)
    return(NULL)
  }
  
  con <- NULL
  results <- data.frame(
    database = character(),
    table = character(),
    has_item_id = logical(),
    has_product_id = logical(),
    stringsAsFactors = FALSE
  )
  
  tryCatch({
    con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
    tables <- dbListTables(con)
    
    for (table in tables) {
      cols <- dbListFields(con, table)
      results <- rbind(results, data.frame(
        database = db_name,
        table = table,
        has_item_id = "item_id" %in% cols,
        has_product_id = "product_id" %in% cols,
        stringsAsFactors = FALSE
      ))
    }
    
  }, error = function(e) {
    message("❌ Error reading database '", db_name, "': ", e$message)
  }, finally = {
    if (!is.null(con)) dbDisconnect(con, shutdown = TRUE)
  })
  
  return(results)
}

# Main check function
check_all_databases <- function() {
  message("\n🔍 CHECKING ALL DATABASES FOR ITEM_ID COLUMNS")
  message(strrep("=", 60))
  
  # Database paths
  db_paths <- list(
    app_data = "data/app_data/app_data.duckdb",
    cleansed_data = "data/local_data/cleansed_data.duckdb",
    processed_data = "data/local_data/processed_data.duckdb",
    raw_data = "data/local_data/raw_data.duckdb",
    staged_data = "data/local_data/staged_data.duckdb",
    transformed_data = "data/local_data/transformed_data.duckdb"
  )
  
  all_results <- NULL
  
  for (db_name in names(db_paths)) {
    message("\n📂 Checking database: ", db_name)
    results <- check_database_columns(db_paths[[db_name]], db_name)
    if (!is.null(results)) {
      all_results <- rbind(all_results, results)
    }
  }
  
  # Show tables with item_id
  if (!is.null(all_results)) {
    tables_with_item_id <- all_results[all_results$has_item_id, ]
    
    message("\n📋 TABLES WITH ITEM_ID COLUMN:")
    message(strrep("-", 60))
    
    if (nrow(tables_with_item_id) > 0) {
      for (i in 1:nrow(tables_with_item_id)) {
        row <- tables_with_item_id[i, ]
        status <- if(row$has_product_id) " (⚠️  also has product_id)" else ""
        message(sprintf("  • %s.%s%s", row$database, row$table, status))
      }
    } else {
      message("  None found!")
    }
    
    message("\n📊 SUMMARY:")
    message("  Total tables checked: ", nrow(all_results))
    message("  Tables with item_id: ", sum(all_results$has_item_id))
    message("  Tables with product_id: ", sum(all_results$has_product_id))
    message("  Tables with both: ", sum(all_results$has_item_id & all_results$has_product_id))
  }
  
  return(all_results)
}

# Run the check
results <- check_all_databases()

# Save results for reference
if (!is.null(results) && nrow(results) > 0) {
  write.csv(results, "item_id_check_results.csv", row.names = FALSE)
  message("\n💾 Results saved to: item_id_check_results.csv")
}