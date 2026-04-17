#!/usr/bin/env Rscript

#' Fix WISER Poisson Analysis Tables
#'
#' This script creates the missing Poisson analysis tables in WISER
#' to fix the "coefficient not found" error
#'
#' @author Claude
#' @date 2025-01-28

library(DBI)
library(duckdb)

# Source the schema definition
source("SCHEMA_001_poisson_analysis.R")

#' Create All Required Poisson Tables for WISER
#'
#' Creates all necessary Poisson analysis tables based on MAMBA structure
#'
#' @param con Database connection
#' @param brands Vector of brand codes
#' @param product_lines Vector of product line codes
#' @param verbose Print progress
#'
create_wiser_poisson_tables <- function(con,
                                        brands = c("cbz", "eby"),
                                        product_lines = c("alf", "sop", "hc"),
                                        verbose = TRUE) {

  if (verbose) {
    message("========================================")
    message("Creating Poisson Analysis Tables for WISER")
    message("========================================\n")
  }

  tables_created <- character()

  for (brand in brands) {
    for (product_line in product_lines) {

      table_name <- paste0("df_", brand, "_poisson_analysis_", product_line)

      if (verbose) {
        message(sprintf("Creating table: %s", table_name))
      }

      # Create table with all required columns
      create_query <- sprintf("
        CREATE TABLE IF NOT EXISTS %s (
          product_line_id VARCHAR NOT NULL,
          platform VARCHAR NOT NULL,
          predictor VARCHAR NOT NULL,
          predictor_type VARCHAR NOT NULL,
          coefficient DOUBLE NOT NULL,
          incidence_rate_ratio DOUBLE NOT NULL,
          std_error DOUBLE NOT NULL,
          z_value DOUBLE NOT NULL,
          p_value DOUBLE NOT NULL,
          conf_low DOUBLE NOT NULL,
          conf_high DOUBLE NOT NULL,
          irr_conf_low DOUBLE NOT NULL,
          irr_conf_high DOUBLE NOT NULL,
          deviance DOUBLE NOT NULL,
          aic DOUBLE NOT NULL,
          sample_size INTEGER NOT NULL,
          convergence VARCHAR NOT NULL,
          analysis_date DATE NOT NULL,
          analysis_version VARCHAR NOT NULL,
          PRIMARY KEY (product_line_id, platform, predictor, analysis_date)
        )
      ", table_name)

      tryCatch({
        DBI::dbExecute(con, create_query)

        # Create indexes
        index_queries <- c(
          sprintf("CREATE INDEX IF NOT EXISTS idx_%s_platform ON %s(platform)",
                  table_name, table_name),
          sprintf("CREATE INDEX IF NOT EXISTS idx_%s_predictor ON %s(predictor)",
                  table_name, table_name),
          sprintf("CREATE INDEX IF NOT EXISTS idx_%s_pvalue ON %s(p_value)",
                  table_name, table_name),
          sprintf("CREATE INDEX IF NOT EXISTS idx_%s_coefficient ON %s(coefficient)",
                  table_name, table_name)
        )

        for (idx_query in index_queries) {
          tryCatch({
            DBI::dbExecute(con, idx_query)
          }, error = function(e) {
            # Index might already exist
          })
        }

        if (verbose) {
          message(sprintf("   ✅ Table created: %s", table_name))
        }

        tables_created <- c(tables_created, table_name)

        # MP029: No Fake Data - Do not insert sample data
        # Data should only come from actual analysis results

      }, error = function(e) {
        if (verbose) {
          message(sprintf("   ⚠️ Error creating %s: %s", table_name, e$message))
        }
      })
    }
  }

  if (verbose) {
    message(sprintf("\n✅ Created %d tables successfully", length(tables_created)))
    message("Tables created:")
    for (tbl in tables_created) {
      message(sprintf("   - %s", tbl))
    }
  }

  return(tables_created)
}

#' Insert Sample Poisson Analysis Data
#'
#' Inserts sample data to ensure tables work correctly
#'
insert_sample_data <- function(con, table_name, brand, product_line, verbose = TRUE) {

  # Sample predictors with realistic coefficients
  sample_data <- data.frame(
    product_line_id = product_line,
    platform = brand,
    predictor = c("year", "month_01", "month_02", "設計時尚美觀", "材質精良",
                 "易於使用", "運作良好", "品質優良"),
    predictor_type = c("time_feature", "time_feature", "time_feature",
                      "property", "property", "property", "property", "property"),
    coefficient = c(0.7368, -0.2345, 0.1234, 0.4567, 0.3456, 0.2345, 0.5678, 0.6789),
    std_error = c(0.3429, 0.1234, 0.0987, 0.2345, 0.1987, 0.1765, 0.2987, 0.3210),
    stringsAsFactors = FALSE
  )

  # Calculate derived columns
  sample_data$z_value <- sample_data$coefficient / sample_data$std_error
  sample_data$p_value <- 2 * pnorm(-abs(sample_data$z_value))
  sample_data$incidence_rate_ratio <- exp(sample_data$coefficient)
  sample_data$conf_low <- sample_data$coefficient - 1.96 * sample_data$std_error
  sample_data$conf_high <- sample_data$coefficient + 1.96 * sample_data$std_error
  sample_data$irr_conf_low <- exp(sample_data$conf_low)
  sample_data$irr_conf_high <- exp(sample_data$conf_high)

  # Add model statistics
  sample_data$deviance <- 204
  sample_data$aic <- 226
  sample_data$sample_size <- 1516
  sample_data$convergence <- "converged"
  sample_data$analysis_date <- Sys.Date()
  sample_data$analysis_version <- "v1.0_sample"

  # Insert data
  tryCatch({
    # First clear any existing sample data
    delete_query <- sprintf("DELETE FROM %s WHERE analysis_version = 'v1.0_sample'",
                           table_name)
    DBI::dbExecute(con, delete_query)

    # Insert new sample data
    DBI::dbWriteTable(con, table_name, sample_data, append = TRUE)

    if (verbose) {
      row_count <- nrow(sample_data)
      message(sprintf("   📊 Inserted %d sample rows", row_count))
    }

  }, error = function(e) {
    if (verbose) {
      message(sprintf("   ⚠️ Could not insert sample data: %s", e$message))
    }
  })
}

#' Validate All Poisson Tables
#'
#' Checks that all tables have the required structure
#'
validate_all_tables <- function(con, verbose = TRUE) {

  if (verbose) {
    message("\n========================================")
    message("Validating Poisson Analysis Tables")
    message("========================================\n")
  }

  # List all tables matching the pattern
  all_tables <- DBI::dbListTables(con)
  poisson_tables <- grep("^df_.*_poisson_analysis_", all_tables, value = TRUE)

  if (length(poisson_tables) == 0) {
    message("❌ No Poisson analysis tables found")
    return(FALSE)
  }

  all_valid <- TRUE

  for (table_name in poisson_tables) {
    result <- validate_poisson_analysis_table(con, table_name)

    if (verbose) {
      if (result$valid) {
        # Check for coefficient column specifically
        cols <- DBI::dbListFields(con, table_name)
        if ("coefficient" %in% cols) {
          # Get row count
          row_count <- DBI::dbGetQuery(con,
            sprintf("SELECT COUNT(*) as n FROM %s", table_name))$n
          message(sprintf("✅ %s: Valid (%d rows, coefficient column present)",
                         table_name, row_count))
        } else {
          message(sprintf("❌ %s: Missing coefficient column!", table_name))
          all_valid <- FALSE
        }
      } else {
        message(sprintf("❌ %s: %s", table_name, result$error))
        all_valid <- FALSE
      }
    }
  }

  if (verbose) {
    message(sprintf("\nValidation complete: %s",
                   ifelse(all_valid, "✅ All tables valid", "❌ Some tables invalid")))
  }

  return(all_valid)
}

# Main execution
if (!interactive()) {

  message("\n🔧 WISER Poisson Table Fix Script")
  message("==================================\n")

  # Parse arguments
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    # Default to WISER database
    db_path <- "/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/WISER/data/app_data/app_data.duckdb"
  } else {
    db_path <- args[1]
  }

  # Check if database exists
  if (!file.exists(db_path)) {
    stop(sprintf("Database not found: %s", db_path))
  }

  message(sprintf("Database: %s", db_path))

  # Connect to database
  con <- dbConnect(duckdb::duckdb(), db_path)

  tryCatch({

    # Create tables
    tables_created <- create_wiser_poisson_tables(con)

    # Validate
    validation_result <- validate_all_tables(con)

    if (validation_result) {
      message("\n✅ SUCCESS: Poisson tables created and validated")
      message("The 'coefficient not found' error should now be fixed!")
    } else {
      message("\n⚠️ WARNING: Some issues detected, please review")
    }

  }, finally = {
    dbDisconnect(con)
  })

} else {

  # Interactive mode - provide instructions
  message("To fix WISER Poisson tables, run:")
  message("  source('fix_wiser_poisson_tables.R')")
  message("  con <- dbConnect(duckdb::duckdb(), 'path/to/app_data.duckdb')")
  message("  create_wiser_poisson_tables(con)")
  message("  validate_all_tables(con)")

}