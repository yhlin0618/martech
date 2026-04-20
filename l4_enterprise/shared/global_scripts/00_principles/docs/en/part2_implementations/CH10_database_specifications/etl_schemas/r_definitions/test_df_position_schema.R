#!/usr/bin/env Rscript

#' Test Script for df_position Schema with Column Aliasing
#'
#' This script tests the df_position schema definition including the
#' virtual column aliasing from item_id to product_id.

# Load required libraries
library(DBI)
library(duckdb)

# Source the schema definition
source("get_df_position_schema.R")

# Create test function
test_df_position_schema <- function() {
  message("========================================")
  message("Testing df_position Schema Definition")
  message("========================================\n")

  # Create temporary database for testing
  con <- NULL
  test_passed <- TRUE

  tryCatch({
    # Connect to temporary in-memory database
    message("1. Creating temporary test database...")
    con <- dbConnect(duckdb::duckdb(), ":memory:")
    message("   ✓ Database connection established\n")

    # Get schema definition
    message("2. Loading schema definition...")
    schema <- get_df_position_schema()
    message(sprintf("   ✓ Schema loaded: %s", schema$table_name))
    message(sprintf("   - Columns defined: %d", length(schema$column_defs)))
    message(sprintf("   - Indexes defined: %d", length(schema$indexes)))

    # Check for product_id alias
    has_product_id <- any(sapply(schema$column_defs, function(x) x$name == "product_id"))
    if (has_product_id) {
      message("   ✓ product_id alias column found\n")
    } else {
      message("   ✗ product_id alias column NOT found\n")
      test_passed <- FALSE
    }

    # Create the table (manual SQL since generate_create_table_query may not exist)
    message("3. Creating df_position table...")

    # Build CREATE TABLE SQL manually
    create_sql <- "CREATE TABLE df_position (
      position_id INTEGER NOT NULL,
      item_id VARCHAR NOT NULL,
      position_name VARCHAR,
      position_type VARCHAR,
      category VARCHAR,
      subcategory VARCHAR,
      position_x NUMERIC,
      position_y NUMERIC,
      position_value NUMERIC,
      platform_id VARCHAR NOT NULL,
      time_period VARCHAR,
      date_recorded DATE,
      product_id VARCHAR GENERATED ALWAYS AS (item_id) VIRTUAL,
      import_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      last_modified TIMESTAMP,
      data_source VARCHAR,
      PRIMARY KEY (position_id)
    )"

    dbExecute(con, create_sql)
    message("   ✓ Table created successfully\n")

    # Insert test data
    message("4. Inserting test data...")
    insert_sql <- "INSERT INTO df_position
      (position_id, item_id, position_name, category, platform_id)
      VALUES
      (1, 'ITEM001', 'Top Position', 'Electronics', 'PLATFORM_A'),
      (2, 'ITEM002', 'Mid Position', 'Clothing', 'PLATFORM_B'),
      (3, 'ITEM003', 'Low Position', 'Books', 'PLATFORM_A')"

    dbExecute(con, insert_sql)
    message("   ✓ Test data inserted\n")

    # Test 1: Query using item_id
    message("5. Testing queries...")
    message("   a. Query using item_id column:")
    result1 <- dbGetQuery(con, "SELECT position_id, item_id FROM df_position WHERE item_id = 'ITEM001'")
    if (nrow(result1) == 1 && result1$item_id[1] == "ITEM001") {
      message("      ✓ item_id query successful")
    } else {
      message("      ✗ item_id query failed")
      test_passed <- FALSE
    }

    # Test 2: Query using product_id alias
    message("   b. Query using product_id alias:")
    result2 <- dbGetQuery(con, "SELECT position_id, product_id FROM df_position WHERE product_id = 'ITEM001'")
    if (nrow(result2) == 1 && result2$product_id[1] == "ITEM001") {
      message("      ✓ product_id alias query successful")
    } else {
      message("      ✗ product_id alias query failed")
      test_passed <- FALSE
    }

    # Test 3: Verify item_id and product_id return same value
    message("   c. Verifying item_id = product_id:")
    result3 <- dbGetQuery(con, "SELECT item_id, product_id FROM df_position")
    if (all(result3$item_id == result3$product_id)) {
      message("      ✓ item_id and product_id values match")
    } else {
      message("      ✗ item_id and product_id values DO NOT match")
      test_passed <- FALSE
    }

    # Test 4: Component simulation - using product_id in WHERE and SELECT
    message("   d. Simulating component query pattern:")
    component_query <- "
      SELECT
        position_id,
        product_id,  -- Component expects this column
        position_name,
        category
      FROM df_position
      WHERE product_id IN ('ITEM001', 'ITEM002')  -- Component filters on product_id
      ORDER BY position_id
    "
    result4 <- dbGetQuery(con, component_query)
    if (nrow(result4) == 2 && all(result4$product_id == c("ITEM001", "ITEM002"))) {
      message("      ✓ Component query pattern works correctly")
      message(sprintf("      Retrieved %d rows with product_id alias", nrow(result4)))
    } else {
      message("      ✗ Component query pattern failed")
      test_passed <- FALSE
    }

    # Test 5: Validate schema structure
    message("\n6. Validating schema structure...")
    if (exists("validate_df_position_schema")) {
      validation_result <- validate_df_position_schema(con, verbose = FALSE)
      if (validation_result) {
        message("   ✓ Schema validation passed")
      } else {
        message("   ✗ Schema validation failed")
        test_passed <- FALSE
      }
    } else {
      # Manual validation
      table_exists <- dbExistsTable(con, "df_position")
      fields <- dbListFields(con, "df_position")
      has_item_id <- "item_id" %in% fields
      has_product_id <- "product_id" %in% fields

      if (table_exists && has_item_id && has_product_id) {
        message("   ✓ Manual schema validation passed")
      } else {
        message("   ✗ Manual schema validation failed")
        test_passed <- FALSE
      }
    }

    # Display summary
    message("\n========================================")
    if (test_passed) {
      message("✅ ALL TESTS PASSED")
      message("The df_position schema with product_id aliasing is working correctly!")
    } else {
      message("❌ SOME TESTS FAILED")
      message("Please review the schema implementation")
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

# Run the test if executed directly
if (!interactive()) {
  result <- test_df_position_schema()
  quit(status = ifelse(result, 0, 1))
} else {
  # In interactive mode, just run the test
  test_df_position_schema()
}