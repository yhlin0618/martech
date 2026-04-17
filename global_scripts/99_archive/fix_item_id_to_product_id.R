#!/usr/bin/env Rscript
# =============================================================
# Fix item_id to product_id in all DuckDB tables
# This script renames item_id column to product_id across all tables
# Date: 2025-08-03
# =============================================================

library(DBI)
library(duckdb)

# Function to safely rename column in a table
rename_column_safely <- function(con, table_name, old_col = "item_id", new_col = "product_id") {
  tryCatch({
    # Check if table exists
    if (!dbExistsTable(con, table_name)) {
      message("⚠️  Table '", table_name, "' does not exist. Skipping...")
      return(FALSE)
    }
    
    # Get column names
    cols <- dbListFields(con, table_name)
    
    # Check if old column exists and new column doesn't
    if (old_col %in% cols && !(new_col %in% cols)) {
      message("🔄 Renaming '", old_col, "' to '", new_col, "' in table: ", table_name)
      
      # Create the ALTER TABLE statement
      sql <- sprintf("ALTER TABLE %s RENAME COLUMN %s TO %s", 
                     dbQuoteIdentifier(con, table_name),
                     dbQuoteIdentifier(con, old_col),
                     dbQuoteIdentifier(con, new_col))
      
      # Execute the rename
      dbExecute(con, sql)
      message("✅ Successfully renamed column in table: ", table_name)
      return(TRUE)
      
    } else if (new_col %in% cols) {
      message("ℹ️  Table '", table_name, "' already has '", new_col, "' column. Skipping...")
      return(FALSE)
      
    } else {
      message("ℹ️  Table '", table_name, "' does not have '", old_col, "' column. Skipping...")
      return(FALSE)
    }
    
  }, error = function(e) {
    message("❌ Error processing table '", table_name, "': ", e$message)
    return(FALSE)
  })
}

# Main function to process all databases
process_all_databases <- function() {
  # List of database paths to process
  db_paths <- list(
    app_data = "data/app_data/app_data.duckdb",
    local_data = "data/local_data/cleansed_data.duckdb",
    processed_data = "data/local_data/processed_data.duckdb",
    raw_data = "data/local_data/raw_data.duckdb",
    staged_data = "data/local_data/staged_data.duckdb",
    transformed_data = "data/local_data/transformed_data.duckdb"
  )
  
  # Track statistics
  total_tables <- 0
  renamed_tables <- 0
  
  # Process each database
  for (db_name in names(db_paths)) {
    db_path <- db_paths[[db_name]]
    
    message("\n📂 Processing database: ", db_name, " (", db_path, ")")
    
    # Check if database file exists
    if (!file.exists(db_path)) {
      message("⚠️  Database file does not exist: ", db_path)
      next
    }
    
    # Connect to database
    con <- NULL
    tryCatch({
      con <- dbConnect(duckdb::duckdb(), db_path, read_only = FALSE)
      message("✅ Connected to database: ", db_name)
      
      # Get all tables
      tables <- dbListTables(con)
      message("📋 Found ", length(tables), " tables")
      
      # Process each table
      for (table in tables) {
        total_tables <- total_tables + 1
        if (rename_column_safely(con, table)) {
          renamed_tables <- renamed_tables + 1
        }
      }
      
    }, error = function(e) {
      message("❌ Error connecting to database '", db_name, "': ", e$message)
    }, finally = {
      # Always disconnect
      if (!is.null(con)) {
        dbDisconnect(con, shutdown = TRUE)
        message("🔌 Disconnected from database: ", db_name)
      }
    })
  }
  
  # Summary
  message("\n" , strrep("=", 60))
  message("📊 SUMMARY")
  message(strrep("=", 60))
  message("Total tables processed: ", total_tables)
  message("Tables with column renamed: ", renamed_tables)
  message("Tables skipped: ", total_tables - renamed_tables)
  
  return(list(
    total = total_tables,
    renamed = renamed_tables
  ))
}

# Create backup function
create_backups <- function() {
  message("\n🔒 Creating backups before modification...")
  
  backup_dir <- paste0("data/backups/", format(Sys.Date(), "%Y%m%d"))
  if (!dir.exists(backup_dir)) {
    dir.create(backup_dir, recursive = TRUE)
  }
  
  # List of databases to backup
  db_files <- list.files(path = "data", pattern = "\\.duckdb$", 
                         recursive = TRUE, full.names = TRUE)
  
  for (db_file in db_files) {
    if (file.exists(db_file)) {
      backup_file <- file.path(backup_dir, basename(db_file))
      message("📦 Backing up: ", basename(db_file))
      file.copy(db_file, backup_file, overwrite = TRUE)
    }
  }
  
  message("✅ Backups created in: ", backup_dir)
  return(backup_dir)
}

# Main execution
main <- function() {
  cat("\n")
  message(strrep("=", 60))
  message("🔧 ITEM_ID TO PRODUCT_ID MIGRATION SCRIPT")
  message(strrep("=", 60))
  message("This script will rename 'item_id' columns to 'product_id'")
  message("across all DuckDB tables in the MAMBA project.")
  message(strrep("=", 60))
  
  # Ask for confirmation
  cat("\n⚠️  This will modify your database files. Continue? (yes/no): ")
  response <- tolower(trimws(readline()))
  
  if (response != "yes" && response != "y") {
    message("❌ Operation cancelled by user.")
    return(invisible(NULL))
  }
  
  # Create backups
  backup_dir <- create_backups()
  
  # Process all databases
  result <- process_all_databases()
  
  message("\n✅ Migration completed!")
  message("💡 Backups are stored in: ", backup_dir)
  message("💡 If you need to restore, copy files from backup directory")
  
  return(result)
}

# Run if executed directly
if (!interactive()) {
  main()
} else {
  message("ℹ️  To run this script, use: source('scripts/fix_item_id_to_product_id.R') and then call main()")
}