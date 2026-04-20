#!/usr/bin/env Rscript
#' Master Validation Script for Precision Marketing ETL+DRV Pipeline
#' 
#' Comprehensive validation of Weeks 1-3 implementation using validation template
#' Validates compliance with MP029, MP108, MP109, MP064, MP102, R116, R117, R118
#' 
#' @author MAMBA Development Team
#' @date 2025-11-13
#' @version 1.0.0

library(dplyr)
library(DBI)
library(duckdb)

# Source validation template
source("scripts/global_scripts/04_utils/fn_validate_etl_drv_template.R")

message("=======================================================")
message("PRECISION MARKETING ETL+DRV PIPELINE VALIDATION")
message("=======================================================")
message(sprintf("Start time: %s\n", Sys.time()))

# ============================================================
# Custom Validation Checks for Precision Marketing
# ============================================================

custom_checks <- list(
  
  # Custom Check 1: Verify all 6 product lines processed
  precision_product_lines_complete = function() {
    con <- dbConnect(duckdb::duckdb(), "data/transformed_data.duckdb", read_only = TRUE)
    
    if (!dbExistsTable(con, "precision_product_profiles_2TR")) {
      dbDisconnect(con, shutdown = TRUE)
      return(list(
        principle = "CUSTOM",
        check = "All 6 product lines in transformed_data",
        compliant = FALSE,
        detail = "Table precision_product_profiles_2TR not found"
      ))
    }
    
    product_lines <- dbGetQuery(con, 
      "SELECT DISTINCT product_line FROM precision_product_profiles_2TR")
    
    expected_lines <- c("Aluminum fin", "Copper fin", "Dryer fin", 
                       "Evaporator fin", "Heater fin", "Oil cooler")
    
    all_present <- all(expected_lines %in% product_lines$product_line)
    n_lines <- nrow(product_lines)
    
    dbDisconnect(con, shutdown = TRUE)
    
    return(list(
      principle = "CUSTOM",
      check = "All 6 product lines in transformed_data",
      compliant = all_present,
      detail = sprintf("Found %d/%d product lines", n_lines, length(expected_lines))
    ))
  },
  
  # Custom Check 2: Verify currency standardization (R116)
  r116_all_prices_usd = function() {
    con <- dbConnect(duckdb::duckdb(), "data/transformed_data.duckdb", read_only = TRUE)
    
    if (!dbExistsTable(con, "precision_product_profiles_2TR")) {
      dbDisconnect(con, shutdown = TRUE)
      return(list(
        principle = "R116",
        check = "All prices converted to USD",
        compliant = FALSE,
        detail = "Table not found"
      ))
    }
    
    currency_check <- dbGetQuery(con,
      "SELECT 
         COUNT(*) as total_records,
         COUNT(DISTINCT standard_currency) as n_currencies,
         SUM(CASE WHEN standard_currency = 'USD' THEN 1 ELSE 0 END) as usd_count
       FROM precision_product_profiles_2TR
       WHERE standard_currency IS NOT NULL")
    
    all_usd <- currency_check$n_currencies == 1 && 
               currency_check$usd_count == currency_check$total_records
    
    dbDisconnect(con, shutdown = TRUE)
    
    return(list(
      principle = "R116",
      check = "All prices converted to USD",
      compliant = all_usd,
      detail = sprintf("%d/%d records in USD", 
                      currency_check$usd_count, 
                      currency_check$total_records)
    ))
  },
  
  # Custom Check 3: Verify feature preparation completeness
  feature_preparation_tables_exist = function() {
    con <- dbConnect(duckdb::duckdb(), "data/processed_data.duckdb", read_only = TRUE)
    
    expected_tables <- c(
      "df_precision_feature_preparation",
      "df_precision_time_series", 
      "df_precision_poisson_analysis"
    )
    
    existing_tables <- dbListTables(con)
    all_exist <- all(expected_tables %in% existing_tables)
    
    dbDisconnect(con, shutdown = TRUE)
    
    return(list(
      principle = "MP109",
      check = "All DRV output tables exist",
      compliant = all_exist,
      detail = sprintf("%d/%d tables present in processed_data", 
                      sum(expected_tables %in% existing_tables),
                      length(expected_tables))
    ))
  },
  
  # Custom Check 4: Verify Poisson analysis has coefficients
  poisson_has_coefficients = function() {
    con <- dbConnect(duckdb::duckdb(), "data/processed_data.duckdb", read_only = TRUE)
    
    if (!dbExistsTable(con, "df_precision_poisson_analysis")) {
      dbDisconnect(con, shutdown = TRUE)
      return(list(
        principle = "R118",
        check = "Poisson analysis has coefficients",
        compliant = FALSE,
        detail = "Table not found"
      ))
    }
    
    coef_count <- dbGetQuery(con,
      "SELECT COUNT(*) as n FROM df_precision_poisson_analysis 
       WHERE coefficient IS NOT NULL")
    
    has_coefficients <- coef_count$n > 0
    
    dbDisconnect(con, shutdown = TRUE)
    
    return(list(
      principle = "R118",
      check = "Poisson analysis has coefficients",
      compliant = has_coefficients,
      detail = sprintf("%d coefficient records found", coef_count$n)
    ))
  },
  
  # Custom Check 5: Verify time series has date range coverage
  time_series_date_coverage = function() {
    con <- dbConnect(duckdb::duckdb(), "data/processed_data.duckdb", read_only = TRUE)
    
    if (!dbExistsTable(con, "df_precision_time_series")) {
      dbDisconnect(con, shutdown = TRUE)
      return(list(
        principle = "R117",
        check = "Time series has adequate date coverage",
        compliant = FALSE,
        detail = "Table not found"
      ))
    }
    
    date_range <- dbGetQuery(con,
      "SELECT 
         MIN(date) as min_date,
         MAX(date) as max_date,
         COUNT(DISTINCT date) as n_dates
       FROM df_precision_time_series")
    
    # Check if at least 30 days of data
    has_coverage <- date_range$n_dates >= 30
    
    dbDisconnect(con, shutdown = TRUE)
    
    return(list(
      principle = "R117",
      check = "Time series has adequate date coverage",
      compliant = has_coverage,
      detail = sprintf("%d dates from %s to %s", 
                      date_range$n_dates,
                      date_range$min_date,
                      date_range$max_date)
    ))
  }
)

# ============================================================
# Run Validation
# ============================================================

validation_results <- fn_validate_etl_drv_template(
  domain = "precision",
  etl_stages = c("0IM", "1ST", "2TR"),
  drv_files = c("feature_preparation", "time_series", "poisson_analysis"),
  custom_checks = custom_checks
)

# ============================================================
# Save Results
# ============================================================

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
results_file <- sprintf("validation/precision_etl_drv_validation_%s.csv", timestamp)

write.csv(validation_results$results, results_file, row.names = FALSE)

message(sprintf("\n📊 Validation results saved to: %s", results_file))

# ============================================================
# Generate Summary Report
# ============================================================

summary_file <- sprintf("validation/precision_etl_drv_summary_%s.txt", timestamp)

sink(summary_file)
cat("=======================================================\n")
cat("PRECISION MARKETING ETL+DRV VALIDATION SUMMARY\n")
cat("=======================================================\n\n")
cat(sprintf("Timestamp: %s\n", Sys.time()))
cat(sprintf("Validation Template Version: 1.0.0\n"))
cat(sprintf("Domain: precision\n\n"))

cat("OVERALL COMPLIANCE\n")
cat(sprintf("  Total Checks: %d\n", validation_results$total_checks))
cat(sprintf("  Passed: %d (%.1f%%)\n", 
           validation_results$passed_checks,
           validation_results$compliance_rate * 100))
cat(sprintf("  Failed: %d\n\n", validation_results$failed_checks))

cat("PRINCIPLE BREAKDOWN\n")
principle_summary <- validation_results$results %>%
  group_by(principle) %>%
  summarize(
    total = n(),
    passed = sum(compliant),
    failed = sum(!compliant),
    .groups = "drop"
  ) %>%
  arrange(principle)

for (i in 1:nrow(principle_summary)) {
  cat(sprintf("  [%s] %d/%d passed\n",
             principle_summary$principle[i],
             principle_summary$passed[i],
             principle_summary$total[i]))
}

if (validation_results$failed_checks > 0) {
  cat("\nFAILED CHECKS\n")
  failed <- validation_results$results %>% filter(!compliant)
  for (i in 1:nrow(failed)) {
    cat(sprintf("  ✗ [%s] %s\n    Detail: %s\n",
               failed$principle[i],
               failed$check_description[i],
               failed$detail[i]))
  }
}

cat("\n=======================================================\n")
cat(sprintf("Report generated: %s\n", Sys.time()))
cat("=======================================================\n")
sink()

message(sprintf("📄 Summary report saved to: %s", summary_file))

# ============================================================
# Exit Status
# ============================================================

if (validation_results$compliance_rate == 1.0) {
  message("\n✅ VALIDATION PASSED - All checks compliant!")
  quit(status = 0)
} else if (validation_results$compliance_rate >= 0.95) {
  message(sprintf("\n⚠️ VALIDATION PASSED WITH WARNINGS - %.1f%% compliant (target: 95%%+)", 
                 validation_results$compliance_rate * 100))
  quit(status = 0)
} else {
  message(sprintf("\n❌ VALIDATION FAILED - %.1f%% compliant (target: 95%%+)", 
                 validation_results$compliance_rate * 100))
  quit(status = 1)
}
