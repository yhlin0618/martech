#!/usr/bin/env Rscript
#####
#P07_D04_04
# DERIVATION: AMZ Time Series Expansion (Wrapper)
# VERSION: 1.2
# PLATFORM: amz
# GROUP: D04
# SEQUENCE: 04
# PURPOSE: Wrapper entry point for time series expansion (delegates to ETL)
# CONSUMES: (via amz_ETL_sales_time_series_2TR.R)
# PRODUCES: app_data.df_amz_sales_complete_time_series_{product_line},
#           app_data.df_amz_sales_complete_time_series
# PRINCIPLE: DM_R044, MP064, MP109, R117
#####

#' @title AMZ D04_04 Wrapper - Time Series Expansion
#' @description Wrapper entry point that executes the AMZ time series ETL script.
#' @requires base
#' @input_tables transformed_data.df_amz_sales___transformed, raw_data.df_all_item_profile_{product_line}
#' @output_tables app_data.df_amz_sales_complete_time_series_{product_line}, app_data.df_amz_sales_complete_time_series
#' @business_rules Wrapper only; delegates execution to amz_ETL_sales_time_series_2TR.R.
#' @platform amz
#' @author MAMBA Development Team
#' @date 2026-01-02

# ==============================================================================
# PART 1: INITIALIZE
# ==============================================================================
source("scripts/global_scripts/22_initializations/sc_Rprofile.R")
autoinit()

error_occurred <- FALSE
test_passed <- FALSE
start_time <- Sys.time()

# ==============================================================================
# PART 2: MAIN
# ==============================================================================
tryCatch({
  message("Running AMZ time series ETL via wrapper (D04_04)...")
  exit_status <- system2(
    "Rscript",
    "scripts/update_scripts/ETL/amz/amz_ETL_sales_time_series_2TR.R"
  )
  if (!is.null(exit_status) && exit_status != 0) {
    stop(sprintf("amz_ETL_sales_time_series_2TR.R exited with status %s", exit_status))
  }
  test_passed <- TRUE
}, error = function(e) {
  message("ERROR in MAIN: ", e$message)
  error_occurred <<- TRUE
})

# ==============================================================================
# PART 3: TEST
# ==============================================================================
if (!error_occurred) {
  message("Wrapper completed without errors.")
}

# ==============================================================================
# PART 4: SUMMARIZE
# ==============================================================================
message("DERIVATION SUMMARY")
message(sprintf("Script: %s", "amz_D04_04.R"))
message(sprintf("Status: %s", ifelse(test_passed && !error_occurred, "SUCCESS", "FAILED")))
message(sprintf("Execution Time: %.2f seconds", as.numeric(difftime(Sys.time(), start_time, units = "secs"))))

# ==============================================================================
# PART 5: DEINITIALIZE
# ==============================================================================
autodeinit()
# End of file
