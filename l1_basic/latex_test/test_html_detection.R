# =============================================================================
# Test HTML File Detection
# Purpose: Test if HTML files are being created and detected properly
# =============================================================================

cat("=== Testing HTML File Detection ===\n\n")

# Check if test_reports directory exists
if (dir.exists("test_reports")) {
  cat("✓ test_reports directory exists\n")
  
  # List all files
  files <- list.files("test_reports", full.names = TRUE)
  cat("Files in test_reports:\n")
  for (file in files) {
    file_info <- file.info(file)
    cat("  -", basename(file), "(", file_info$size, "bytes,", 
        format(file_info$mtime, "%Y-%m-%d %H:%M:%S"), ")\n")
  }
  
  # Check for HTML files specifically
  html_files <- list.files("test_reports", pattern = "\\.html$", full.names = TRUE)
  if (length(html_files) > 0) {
    cat("\n✓ Found", length(html_files), "HTML file(s):\n")
    for (html_file in html_files) {
      file_size <- file.size(html_file)
      cat("  -", basename(html_file), "(", file_size, "bytes)\n")
      
      # Test if file is readable
      tryCatch({
        content <- readLines(html_file, n = 5)
        cat("    First 5 lines:\n")
        for (line in content) {
          cat("      ", substr(line, 1, 80), "\n")
        }
      }, error = function(e) {
        cat("    Error reading file:", e$message, "\n")
      })
    }
  } else {
    cat("\n✗ No HTML files found\n")
  }
} else {
  cat("✗ test_reports directory does not exist\n")
}

# Test file path construction
cat("\n=== Testing File Path Construction ===\n")
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
test_paths <- c(
  file.path("test_reports", paste0("report_", timestamp, ".html")),
  paste0("test_reports/report_", timestamp, ".html"),
  paste0("test_reports\\report_", timestamp, ".html")
)

cat("Test paths:\n")
for (path in test_paths) {
  cat("  -", path, ":", ifelse(file.exists(path), "EXISTS", "NOT FOUND"), "\n")
}

cat("\n=== Test Complete ===\n") 