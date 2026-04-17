# =============================================================================
# Simple PDF Test
# Purpose: Test PDF compilation with simplified settings
# =============================================================================

library(rmarkdown)

cat("Testing simple PDF compilation...\n")

# Create simple markdown content
simple_md <- "---
title: 'Simple Test Report'
author: 'Test User'
date: '2025-01-27'
output: pdf_document
---

# Simple Test Report

This is a simple test report.

## Key Points

- Point 1
- Point 2
- Point 3

## Summary

This test should work with pdflatex.

---

*Generated on 2025-01-27*
"

# Write test file
test_file <- "simple_test.md"
writeLines(simple_md, test_file)

cat("Test file created:", test_file, "\n")

# Test compilation
tryCatch({
  output_file <- "simple_test_output.pdf"
  
  cat("Compiling PDF...\n")
  rmarkdown::render(
    input = test_file,
    output_format = "pdf_document",
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