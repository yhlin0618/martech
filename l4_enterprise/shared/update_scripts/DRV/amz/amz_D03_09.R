#####
# CONSUMES: df_comment_property_ratingonly_*
# PRODUCES: df_comment_property_ratingonly_*
# DEPENDS_ON_ETL: none
# DEPENDS_ON_DRV: amz_D03_08
#####


#' @title amz_D03_09
#' @description Derivation task
#' @business_rules See script comments for business logic.
#' @platform amz
#' @author MAMBA Development Team
#' @date 2025-12-30
#' @logical_step_id D03_03
#' @logical_step_status reassigned
#' @legacy_step_id D03_09

# amz_D03_09.R - Process Reviews for Amazon
# D03_09: Process and aggregate review ratings
#
# Following principles:
# - MP47: Functional Programming
# - R21: One Function One File
# - R69: Function File Naming
# - R49: Apply Over Loops
# - MP81: Explicit Parameter Specification
# - MP30: Vectorization Principle

# Initialize environment
sql_read_candidates <- c(
  file.path("scripts", "global_scripts", "02_db_utils", "fn_sql_read.R"),
  file.path("..", "global_scripts", "02_db_utils", "fn_sql_read.R"),
  file.path("..", "..", "global_scripts", "02_db_utils", "fn_sql_read.R"),
  file.path("..", "..", "..", "global_scripts", "02_db_utils", "fn_sql_read.R")
)
sql_read_path <- sql_read_candidates[file.exists(sql_read_candidates)][1]
if (is.na(sql_read_path)) {
  stop("fn_sql_read.R not found in expected paths")
}
source(sql_read_path)
needgoogledrive <- TRUE
autoinit()


# Connect to databases with appropriate access
comment_property_rating <- dbConnectDuckdb(
  db_path_list$comment_property_rating, read_only = TRUE)
comment_property_rating_results <- dbConnectDuckdb(
  db_path_list$comment_property_rating_results,
  read_only = TRUE
)
processed_data <- dbConnectDuckdb(
  db_path_list$processed_data,
  read_only = FALSE
)

# Log beginning of process
message("Starting D03_03 (Process Reviews) for Amazon product lines")

# Process review ratings for all product lines
process_review_ratings(
  comment_property_rating = comment_property_rating,
  comment_property_rating_results = comment_property_rating_results,
  processed_data = processed_data,
  vec_product_line_id_noall = vec_product_line_id_noall
)

# Verify created tables
# Use DBI::dbListFields instead of PRAGMA (DuckDB rejects PRAGMA as subquery via dbplyr)
message("\nVerifying processed tables:")
system_cols <- c("product_id", "reviewer_id", "review_date",
                 "review_title", "review_body", "property_name",
                 "ai_rating_result", "ai_rating_gpt_model",
                 "ai_rating_timestamp", "product_line_id",
                 "asin", "brand", "rating", "sales", "verified", "helpful",
                 "url", "style", "included_competiter", "platform_id")
for (product_line_id_i in vec_product_line_id_noall) {
  table_name <- paste0("df_comment_property_ratingonly_", product_line_id_i)

  if (DBI::dbExistsTable(processed_data, table_name)) {
    # Count rows using direct SQL
    row_count <- DBI::dbGetQuery(processed_data,
      paste0('SELECT COUNT(*) AS n FROM "', table_name, '"'))$n

    # Get columns using DBI (avoids dbplyr PRAGMA subquery bug)
    all_cols <- DBI::dbListFields(processed_data, table_name)

    message("Table ", table_name, ": ", row_count, " rows, ",
            length(all_cols), " columns")

    property_cols <- setdiff(all_cols, system_cols)
    if (length(property_cols) > 0) {
      message("  Properties: ", paste(property_cols, collapse = ", "))
    } else {
      warning("  No property columns found in table: ", table_name)
    }
  } else {
    # Not all product lines have ratings — only warn, don't fail
    message("  (skip: ", table_name, " not created — no upstream data)")
  }
}

# Clean up and disconnect
autodeinit()

# Log completion
message("Amazon review processing completed successfully for D03_03 step")
