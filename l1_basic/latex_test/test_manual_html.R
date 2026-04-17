# =============================================================================
# Manual HTML Compilation Test
# Purpose: Test manual compilation of existing markdown file
# =============================================================================

library(rmarkdown)

cat("=== Manual HTML Compilation Test ===\n\n")

# Check if the markdown file exists
md_file <- "test_reports/report_20250714_005331.md"
if (file.exists(md_file)) {
  cat("✓ Found markdown file:", md_file, "\n")
  cat("File size:", file.size(md_file), "bytes\n")
  
  # Read first few lines to verify content
  content <- readLines(md_file, n = 10)
  cat("First 10 lines:\n")
  for (line in content) {
    cat("  ", line, "\n")
  }
  
  # Try to compile manually
  cat("\nAttempting manual HTML compilation...\n")
  output_file <- "test_reports/manual_test.html"
  
  tryCatch({
    result <- rmarkdown::render(
      input = md_file,
      output_format = rmarkdown::html_document(
        toc = FALSE,
        number_sections = FALSE,
        highlight = NULL
      ),
      output_file = output_file,
      quiet = FALSE
    )
    
    cat("Compilation result:", result, "\n")
    
    if (file.exists(output_file)) {
      cat("✓ HTML file created:", output_file, "\n")
      cat("File size:", file.size(output_file), "bytes\n")
    } else {
      cat("✗ HTML file not found at expected location\n")
    }
    
    # Check if file was created with a different name
    html_files <- list.files("test_reports", pattern = "\\.html$", full.names = TRUE)
    if (length(html_files) > 0) {
      cat("Found HTML files:\n")
      for (file in html_files) {
        cat("  -", file, "(", file.size(file), "bytes)\n")
      }
    } else {
      cat("No HTML files found in test_reports directory\n")
    }
    
  }, error = function(e) {
    cat("✗ Compilation error:", e$message, "\n")
  })
  
} else {
  cat("✗ Markdown file not found:", md_file, "\n")
}

cat("\n=== Test Complete ===\n") 