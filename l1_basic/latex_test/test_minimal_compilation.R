# =============================================================================
# Test Minimal Compilation
# Purpose: Test compilation with minimal template
# =============================================================================

# Load required packages
library(dotenv)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# Source utility functions
source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")

# Simple test content
latex_content <- c(
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

latex_content <- paste(latex_content, collapse = "\n")

# Test compilation
cat("Testing minimal template compilation...\n")
result <- fn_compile_latex_report(
  latex_source = latex_content,
  output_dir = "test_reports",
  compiler = "pdflatex",
  filename_prefix = "test_minimal",
  report_data = list(metadata = list(title = "Test Report", author = "Test User")),
  verbose = TRUE
)

if (!is.null(result$error)) {
  cat("Compilation failed:", result$error, "\n")
} else {
  cat("Compilation successful!\n")
  cat("PDF path:", result$pdf_path, "\n")
  cat("Compiler used:", result$compiler, "\n")
  
  # Check if PDF exists and has content
  if (file.exists(result$pdf_path)) {
    file_size <- file.size(result$pdf_path)
    cat("PDF file size:", file_size, "bytes\n")
    if (file_size > 1000) {
      cat("✓ PDF appears to be valid (size > 1KB)\n")
    } else {
      cat("⚠ PDF file is very small, may be empty\n")
    }
  }
}

cat("\nTest completed.\n") 