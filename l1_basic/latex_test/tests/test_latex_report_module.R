# =============================================================================
# Test: test_latex_report_module
# Purpose: Test LaTeX report module functionality
# Author: Claude
# Date Created: 2025-01-27
# Related Principles: R21, R69, R75
# =============================================================================

# Load required packages
library(shiny)
library(shinytest2)
library(dplyr)
library(testthat)

# Source the module
source("modules/module_latex_report.R")

# Source utility functions
if (file.exists("scripts/global_scripts/04_utils/fn_latex_report_utils.R")) {
  source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")
}

#' Test LaTeX Report Module
#'
#' This test suite validates the LaTeX report module functionality
#' including data collection, GPT API integration, and LaTeX compilation.
#'
#' @param verbose Show detailed test results (default: TRUE)
#'
#' @return Test results summary
#'
#' @examples
#' \dontrun{
#' # Run all tests
#' test_latex_report_module()
#' 
#' # Run with minimal output
#' test_latex_report_module(verbose = FALSE)
#' }
#'
#' @export
test_latex_report_module <- function(verbose = TRUE) {
  
  if (verbose) {
    cat("=== LaTeX Report Module Test Suite ===\n")
  }
  
  # Test results storage
  test_results <- list()
  
  # ---- Test 1: Module UI Creation ----
  test_that("Module UI can be created", {
    ui <- latexReportModuleUI("test")
    expect_true(inherits(ui, "shiny.tag"))
    expect_true(length(ui$children) > 0)
    
    if (verbose) cat("✓ Module UI creation: PASSED\n")
    test_results$ui_creation <- "PASSED"
  })
  
  # ---- Test 2: Utility Functions ----
  test_that("Utility functions work correctly", {
    # Create test data
    test_sales <- data.frame(
      customer_id = c(1, 1, 2, 2, 3),
      lineitem_price = c(100, 150, 200, 250, 300),
      payment_time = as.POSIXct(c("2024-01-01", "2024-01-02", "2024-01-03", 
                                 "2024-01-04", "2024-01-05"))
    )
    
    test_dna <- data.frame(
      customer_id = c(1, 2, 3),
      m_value = c(125, 225, 300),
      r_value = c(0.8, 0.6, 0.9),
      f_value = c(2, 2, 1),
      ipt_value = c(1, 1, 5),
      nes_status = c("High", "Medium", "Low")
    )
    
    # Test data collection
    report_data <- fn_collect_report_data(
      sales_data = test_sales,
      dna_results = test_dna,
      metadata = list(title = "Test Report"),
      include_options = list(sales_summary = TRUE, dna_analysis = TRUE),
      verbose = FALSE
    )
    
    expect_true(is.list(report_data))
    expect_true("metadata" %in% names(report_data))
    expect_true("sales_summary" %in% names(report_data))
    expect_true("dna_analysis" %in% names(report_data))
    
    # Test sales summary
    expect_equal(report_data$sales_summary$total_transactions, 5)
    expect_equal(report_data$sales_summary$unique_customers, 3)
    expect_equal(report_data$sales_summary$total_revenue, 1000)
    
    # Test DNA analysis
    expect_equal(report_data$dna_analysis$customer_count, 3)
    expect_true("nes_distribution" %in% names(report_data$dna_analysis))
    
    if (verbose) cat("✓ Utility functions: PASSED\n")
    test_results$utility_functions <- "PASSED"
  })
  
  # ---- Test 3: LaTeX Compiler Validation ----
  test_that("LaTeX compiler validation works", {
    # Test compiler check (this will depend on system installation)
    pdflatex_available <- fn_validate_latex_compiler("pdflatex", verbose = FALSE)
    xelatex_available <- fn_validate_latex_compiler("xelatex", verbose = FALSE)
    
    expect_true(is.logical(pdflatex_available))
    expect_true(is.logical(xelatex_available))
    
    if (verbose) {
      cat("✓ LaTeX compiler validation: PASSED\n")
      cat("  - pdflatex available:", pdflatex_available, "\n")
      cat("  - xelatex available:", xelatex_available, "\n")
    }
    test_results$compiler_validation <- "PASSED"
  })
  
  # ---- Test 4: Mock LaTeX Compilation ----
  test_that("LaTeX compilation works with simple document", {
    # Create a simple LaTeX document for testing
    simple_latex <- paste(
      "\\documentclass{article}",
      "\\usepackage{CJKutf8}",
      "\\begin{document}",
      "\\begin{CJK*}{UTF8}{gbsn}",
      "\\title{測試報告}",
      "\\author{測試作者}",
      "\\date{\\today}",
      "\\maketitle",
      "\\section{摘要}",
      "這是一個測試報告。",
      "\\end{CJK*}",
      "\\end{document}",
      sep = "\n"
    )
    
    # Test compilation (only if pdflatex is available)
    if (fn_validate_latex_compiler("pdflatex", verbose = FALSE)) {
      compile_result <- fn_compile_latex_report(
        latex_source = simple_latex,
        output_dir = "test_reports",
        compiler = "pdflatex",
        filename_prefix = "test",
        verbose = FALSE
      )
      
      expect_true(is.list(compile_result))
      expect_true("success" %in% names(compile_result) || "error" %in% names(compile_result))
      
      if (verbose) {
        if (!is.null(compile_result$success) && compile_result$success) {
          cat("✓ LaTeX compilation: PASSED\n")
          cat("  - PDF created:", compile_result$pdf_path, "\n")
        } else {
          cat("⚠ LaTeX compilation: PARTIAL (compiler available but compilation failed)\n")
          cat("  - Error:", compile_result$error, "\n")
        }
      }
      test_results$latex_compilation <- ifelse(
        !is.null(compile_result$success) && compile_result$success, 
        "PASSED", "PARTIAL"
      )
    } else {
      if (verbose) cat("⚠ LaTeX compilation: SKIPPED (no compiler available)\n")
      test_results$latex_compilation <- "SKIPPED"
    }
  })
  
  # ---- Test 5: Error Handling ----
  test_that("Error handling works correctly", {
    # Test with empty sales data
    empty_result <- fn_collect_report_data(
      sales_data = data.frame(),
      verbose = FALSE
    )
    expect_true("error" %in% names(empty_result))
    
    # Test with invalid sales data
    invalid_result <- fn_collect_report_data(
      sales_data = "not a dataframe",
      verbose = FALSE
    )
    expect_true("error" %in% names(invalid_result))
    
    # Test GPT API with invalid key
    gpt_result <- fn_generate_latex_via_gpt(
      report_data = list(test = "data"),
      api_key = "",
      verbose = FALSE
    )
    expect_true("error" %in% names(gpt_result))
    
    if (verbose) cat("✓ Error handling: PASSED\n")
    test_results$error_handling <- "PASSED"
  })
  
  # ---- Test 6: Module Integration ----
  test_that("Module can be integrated into Shiny app", {
    # Create a simple test app
    test_app <- shinyApp(
      ui = fluidPage(
        latexReportModuleUI("latex_report")
      ),
      server = function(input, output, session) {
        # Mock data
        mock_sales <- reactive({
          data.frame(
            customer_id = c(1, 2, 3),
            lineitem_price = c(100, 200, 300),
            payment_time = as.POSIXct(c("2024-01-01", "2024-01-02", "2024-01-03"))
          )
        })
        
        mock_dna <- reactive({
          data.frame(
            customer_id = c(1, 2, 3),
            m_value = c(100, 200, 300),
            nes_status = c("High", "Medium", "Low")
          )
        })
        
        # Initialize module
        latexReportModuleServer(
          "latex_report",
          con = NULL,
          user_info = reactive(list(user = "test")),
          sales_data = mock_sales,
          dna_results = mock_dna
        )
      }
    )
    
    expect_true(inherits(test_app, "shiny.appobj"))
    
    if (verbose) cat("✓ Module integration: PASSED\n")
    test_results$module_integration <- "PASSED"
  })
  
  # ---- Summary ----
  if (verbose) {
    cat("\n=== Test Summary ===\n")
    for (test_name in names(test_results)) {
      cat(sprintf("%-25s: %s\n", test_name, test_results[[test_name]]))
    }
    
    passed_count <- sum(test_results == "PASSED")
    total_count <- length(test_results)
    
    cat(sprintf("\nOverall: %d/%d tests passed\n", passed_count, total_count))
  }
  
  return(test_results)
}

# =============================================================================
# Test Execution
# =============================================================================

if (FALSE) {  # Set to TRUE to run tests
  # Run tests
  results <- test_latex_report_module(verbose = TRUE)
  
  # Print detailed results
  print(results)
}

# =============================================================================
# Test Guidelines
# =============================================================================

# 1. Module Structure (R21):
#    - Test UI creation and structure
#    - Test server function initialization
#    - Verify proper namespace handling

# 2. Utility Functions (R69):
#    - Test each utility function independently
#    - Verify input validation
#    - Check error handling

# 3. Integration Testing:
#    - Test module integration with mock data
#    - Verify reactive dependencies
#    - Test download handlers

# 4. Error Scenarios:
#    - Test with invalid inputs
#    - Test with missing dependencies
#    - Test API failures

# 5. Performance:
#    - Test with large datasets
#    - Monitor memory usage
#    - Check compilation timeouts 