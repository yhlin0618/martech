#!/usr/bin/env Rscript

#' Test Migration Script: item_id to product_id
#'
#' This script tests the migration from item_id to product_id column

library(DBI)
library(duckdb)

# Source migration script only if in the same directory
if (file.exists("migrate_item_id_to_product_id.R")) {
  # Get the functions without executing the main block
  migration_env <- new.env()
  sys.source("migrate_item_id_to_product_id.R", envir = migration_env)
  migrate_item_id_to_product_id <- migration_env$migrate_item_id_to_product_id
  rollback_migration <- migration_env$rollback_migration
} else {
  stop("Migration script not found. Please run this test from the same directory as migrate_item_id_to_product_id.R")
}

test_migration <- function() {
  message("========================================")
  message("Testing Migration: item_id → product_id")
  message("========================================\n")

  con <- NULL
  test_passed <- TRUE

  tryCatch({
    # Create temporary test database
    message("1. Creating test database...")
    test_db <- tempfile(fileext = ".duckdb")
    con <- dbConnect(duckdb::duckdb(), test_db)
    message(sprintf("   ✓ Test database created: %s\n", test_db))

    # Create test table with item_id (old structure)
    message("2. Creating test table with item_id (old structure)...")
    create_old_table <- "
      CREATE TABLE df_position (
        position_id INTEGER NOT NULL,
        item_id VARCHAR NOT NULL,
        position_name VARCHAR,
        category VARCHAR,
        platform_id VARCHAR NOT NULL,
        PRIMARY KEY (position_id)
      )
    "
    dbExecute(con, create_old_table)
    message("   ✓ Old structure table created\n")

    # Insert test data
    message("3. Inserting test data...")
    insert_data <- "
      INSERT INTO df_position (position_id, item_id, position_name, category, platform_id)
      VALUES
        (1, 'PROD001', 'Position A', 'Electronics', 'PLAT_A'),
        (2, 'PROD002', 'Position B', 'Clothing', 'PLAT_B'),
        (3, 'PROD003', 'Position C', 'Books', 'PLAT_A'),
        (4, 'PROD004', 'Position D', 'Electronics', 'PLAT_C'),
        (5, 'PROD005', 'Position E', 'Toys', 'PLAT_B')
    "
    dbExecute(con, insert_data)
    row_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM df_position")$n
    message(sprintf("   ✓ Inserted %d test rows\n", row_count))

    # Show structure before migration
    message("4. Structure BEFORE migration:")
    columns_before <- dbListFields(con, "df_position")
    message(sprintf("   Columns: %s", paste(columns_before, collapse = ", ")))

    # Show sample data before
    data_before <- dbGetQuery(con, "SELECT * FROM df_position ORDER BY position_id LIMIT 3")
    message("   Sample data:")
    print(data_before)
    message("")

    # Test dry run first
    message("5. Testing dry run mode...")
    dry_result <- migrate_item_id_to_product_id(con, dry_run = TRUE, verbose = FALSE)
    if (dry_result$success) {
      message("   ✓ Dry run completed successfully\n")
    } else {
      message("   ✗ Dry run failed\n")
      test_passed <- FALSE
    }

    # Perform actual migration
    message("6. Performing actual migration...")
    migration_result <- migrate_item_id_to_product_id(con, verbose = FALSE)

    if (migration_result$success) {
      message("   ✓ Migration completed successfully")
      message(sprintf("   Backup created: %s\n", migration_result$backup_table))
    } else {
      message("   ✗ Migration failed\n")
      test_passed <- FALSE
    }

    # Show structure after migration
    message("7. Structure AFTER migration:")
    columns_after <- dbListFields(con, "df_position")
    message(sprintf("   Columns: %s", paste(columns_after, collapse = ", ")))

    # Verify product_id exists and item_id doesn't
    has_product_id <- "product_id" %in% columns_after
    has_item_id <- "item_id" %in% columns_after

    if (has_product_id && !has_item_id) {
      message("   ✓ Column renamed successfully (item_id → product_id)")
    } else {
      message(sprintf("   ✗ Column rename failed (has_product_id: %s, has_item_id: %s)",
                     has_product_id, has_item_id))
      test_passed <- FALSE
    }

    # Show sample data after
    data_after <- dbGetQuery(con, "SELECT * FROM df_position ORDER BY position_id LIMIT 3")
    message("   Sample data:")
    print(data_after)
    message("")

    # Verify data integrity
    message("8. Verifying data integrity...")
    final_count <- dbGetQuery(con, "SELECT COUNT(*) as n FROM df_position")$n

    if (final_count == row_count) {
      message(sprintf("   ✓ Row count preserved: %d rows", final_count))
    } else {
      message(sprintf("   ✗ Row count mismatch: %d before, %d after", row_count, final_count))
      test_passed <- FALSE
    }

    # Test querying with product_id
    message("\n9. Testing queries with product_id...")
    query_result <- dbGetQuery(con,
      "SELECT position_id, product_id, position_name
       FROM df_position
       WHERE product_id = 'PROD002'"
    )

    if (nrow(query_result) == 1 && query_result$product_id[1] == "PROD002") {
      message("   ✓ Query with product_id works correctly")
    } else {
      message("   ✗ Query with product_id failed")
      test_passed <- FALSE
    }

    # Test rollback
    message("\n10. Testing rollback functionality...")
    rollback_success <- rollback_migration(con, "df_position", migration_result$backup_table,
                                          verbose = FALSE)
    if (rollback_success) {
      columns_rollback <- dbListFields(con, "df_position")
      has_item_after_rollback <- "item_id" %in% columns_rollback

      if (has_item_after_rollback) {
        message("   ✓ Rollback successful - item_id restored")
      } else {
        message("   ✗ Rollback failed - item_id not restored")
        test_passed <- FALSE
      }
    } else {
      message("   ✗ Rollback failed")
      test_passed <- FALSE
    }

    # Final summary
    message("\n========================================")
    if (test_passed) {
      message("✅ ALL MIGRATION TESTS PASSED")
      message("The migration script works correctly!")
      message("\nTo migrate your actual database, run:")
      message("  Rscript migrate_item_id_to_product_id.R path/to/your/database.duckdb")
      message("\nTo preview changes without executing:")
      message("  Rscript migrate_item_id_to_product_id.R path/to/your/database.duckdb --dry-run")
    } else {
      message("❌ SOME MIGRATION TESTS FAILED")
      message("Please review the migration script")
    }
    message("========================================")

  }, error = function(e) {
    message(sprintf("\n❌ ERROR during testing: %s", e$message))
    test_passed <- FALSE
  }, finally = {
    # Clean up
    if (!is.null(con)) {
      dbDisconnect(con)
      message("\nTest database connection closed")
    }
  })

  return(test_passed)
}

# Run test
if (!interactive()) {
  result <- test_migration()
  quit(status = ifelse(result, 0, 1))
} else {
  test_migration()
}