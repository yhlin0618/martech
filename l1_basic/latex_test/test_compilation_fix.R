# =============================================================================
# Test Compilation Fix
# Purpose: Test the improved LaTeX compilation with multiple compilers
# =============================================================================

# Load required packages
library(dotenv)
library(dplyr)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# Source utility functions
source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")

# Create test data
test_sales_data <- data.frame(
  customer_id = paste0("customer_", 1:5),
  lineitem_price = c(100, 200, 300, 400, 500),
  payment_time = Sys.time() - runif(5, 0, 30) * 24 * 3600,
  product_name = sample(c("Product A", "Product B", "Product C"), 5, replace = TRUE)
)

# Test data collection
cat("Testing data collection...\n")
report_data <- fn_collect_report_data(
  sales_data = test_sales_data,
  metadata = list(
    title = "Test Report",
    author = "Test User",
    date = "2025-01-27"
  ),
  include_options = list(
    sales_summary = TRUE,
    dna_analysis = FALSE,
    customer_segments = FALSE
  ),
  verbose = TRUE
)

# Generate fallback LaTeX content (simulate API failure)
cat("\nGenerating fallback LaTeX content...\n")
fallback_content <- c(
  "\\section{Sales Summary}",
  "This analysis includes 5 transactions,",
  "involving 5 unique customers,",
  "with total revenue of 1500.00.",
  "Average transaction value is 300.00.",
  "",
  "\\subsection{Transaction Statistics}",
  "\\begin{itemize}",
  "\\item Total transactions: 5",
  "\\item Unique customers: 5",
  "\\item Total revenue: 1500.00",
  "\\item Average transaction amount: 300.00",
  "\\end{itemize}",
  "",
  "\\section{Report Generation Info}",
  paste0("Report generation time: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  "\\textit{Note: This report was generated using fallback mode.}"
)

latex_content <- paste(fallback_content, collapse = "\n")

# Test compilation with different templates
cat("\nTesting compilation with different templates...\n")

# Test with English template
cat("Testing with English template...\n")
result <- fn_compile_latex_report(
  latex_source = latex_content,
  output_dir = "test_reports",
  compiler = "pdflatex",
  filename_prefix = "test_english",
  report_data = report_data,
  verbose = TRUE
)

if (!is.null(result$error)) {
  cat("English template compilation failed:", result$error, "\n")
} else {
  cat("English template compilation successful!\n")
  cat("PDF path:", result$pdf_path, "\n")
  cat("Compiler used:", result$compiler, "\n")
}

# Test with original template (if available)
if (file.exists("template.tex")) {
  cat("\nTesting with original template...\n")
  result2 <- fn_compile_latex_report(
    latex_source = latex_content,
    output_dir = "test_reports",
    compiler = "xelatex",
    filename_prefix = "test_original",
    report_data = report_data,
    verbose = TRUE
  )
  
  if (!is.null(result2$error)) {
    cat("Original template compilation failed:", result2$error, "\n")
  } else {
    cat("Original template compilation successful!\n")
    cat("PDF path:", result2$pdf_path, "\n")
    cat("Compiler used:", result2$compiler, "\n")
  }
}

cat("\nCompilation test completed.\n") 