# =============================================================================
# YAML PDF Test
# Purpose: Test PDF compilation with simplified YAML header
# =============================================================================

library(rmarkdown)

cat("Testing PDF compilation with simplified YAML header...\n")

# Create markdown content with simplified YAML header
yaml_md <- "---
title: \"Test Report\"
author: \"Test User\"
date: \"2025-01-27\"
---

# Test Report

This is a test report with simplified YAML header.

## Section 1

- Item 1
- Item 2
- Item 3

## Section 2

Some text here.

---

*Generated on 2025-01-27*
"

# Write test file
test_file <- "yaml_test.md"
writeLines(yaml_md, test_file)

cat("Test file created:", test_file, "\n")

# Test compilation with minimal settings
tryCatch({
  output_file <- "yaml_test_output.pdf"
  
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