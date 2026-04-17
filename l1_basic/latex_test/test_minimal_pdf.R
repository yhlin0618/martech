# =============================================================================
# Minimal PDF Test
# Purpose: Test PDF compilation with absolute minimal settings
# =============================================================================

library(rmarkdown)

cat("Testing minimal PDF compilation...\n")

# Create minimal markdown content (no YAML header)
minimal_md <- "# Test Report

This is a minimal test report.

## Section 1

- Item 1
- Item 2

## Section 2

Some text here.

---

*Generated on 2025-01-27*
"

# Write test file
test_file <- "minimal_test.md"
writeLines(minimal_md, test_file)

cat("Test file created:", test_file, "\n")

# Test compilation with minimal settings
tryCatch({
  output_file <- "minimal_test_output.pdf"
  
  cat("Compiling PDF with minimal settings...\n")
  rmarkdown::render(
    input = test_file,
    output_format = rmarkdown::pdf_document(
      latex_engine = "pdflatex",
      toc = FALSE,
      number_sections = FALSE,
      highlight = NULL
    ),
    output_file = output_file,
    quiet = FALSE
  )
  
  if (file.exists(output_file)) {
    file_size <- file.size(output_file)
    cat("✓ PDF compilation successful!\n")
    cat("Output file:", output_file, "\n")
    cat("File size:", file_size, "bytes\n")
    
    if (file_size > 1000) {
      cat("✓ PDF appears to be valid\n")
    } else {
      cat("⚠ PDF file is very small\n")
    }
  } else {
    cat("✗ PDF compilation failed - no output file\n")
  }
  
}, error = function(e) {
  cat("✗ Compilation error:", e$message, "\n")
})

# Clean up
if (file.exists(test_file)) file.remove(test_file)

cat("\nTest completed.\n") 