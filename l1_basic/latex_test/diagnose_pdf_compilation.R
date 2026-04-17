# =============================================================================
# PDF Compilation Diagnosis
# Purpose: Diagnose PDF compilation issues
# =============================================================================

cat("=== PDF Compilation Diagnosis ===\n\n")

# 1. Check R packages
cat("1. Checking R packages...\n")
required_packages <- c("rmarkdown", "knitr", "markdown")
for (pkg in required_packages) {
  if (require(pkg, character.only = TRUE)) {
    cat("✓", pkg, "is installed\n")
  } else {
    cat("✗", pkg, "is NOT installed\n")
  }
}

# 2. Check LaTeX installation
cat("\n2. Checking LaTeX installation...\n")
latex_engines <- c("pdflatex", "xelatex", "lualatex")
for (engine in latex_engines) {
  tryCatch({
    result <- system2(engine, "--version", stdout = TRUE, stderr = TRUE)
    if (length(result) > 0) {
      cat("✓", engine, "is available\n")
    } else {
      cat("✗", engine, "is NOT available\n")
    }
  }, error = function(e) {
    cat("✗", engine, "test failed:", e$message, "\n")
  })
}

# 3. Check MiKTeX installation
cat("\n3. Checking MiKTeX installation...\n")
miktex_paths <- c(
  "C:/Program Files/MiKTeX/miktex/bin/x64/pdflatex.exe",
  "C:/Program Files/MiKTeX/miktex/bin/x64/xelatex.exe"
)
for (path in miktex_paths) {
  if (file.exists(path)) {
    cat("✓", basename(path), "found at:", path, "\n")
  } else {
    cat("✗", basename(path), "NOT found\n")
  }
}

# 4. Test simple markdown compilation
cat("\n4. Testing simple markdown compilation...\n")
test_md <- "---
title: 'Test Report'
author: 'Test User'
date: '2025-01-27'
output: pdf_document
---

# Test Report

This is a test report.

## Section 1

- Item 1
- Item 2
- Item 3

## Section 2

Some text here.
"

# Write test file
test_file <- "test_simple.md"
writeLines(test_md, test_file)

# Test compilation methods
methods <- list(
  list(name = "Default", format = "pdf_document"),
  list(name = "pdflatex", format = rmarkdown::pdf_document(latex_engine = "pdflatex")),
  list(name = "xelatex", format = rmarkdown::pdf_document(latex_engine = "xelatex"))
)

for (method in methods) {
  cat("\nTesting method:", method$name, "\n")
  tryCatch({
    output_file <- paste0("test_output_", method$name, ".pdf")
    rmarkdown::render(
      input = test_file,
      output_format = method$format,
      output_file = output_file,
      quiet = TRUE
    )
    if (file.exists(output_file)) {
      file_size <- file.size(output_file)
      cat("✓ Success! File size:", file_size, "bytes\n")
      # Clean up
      file.remove(output_file)
    } else {
      cat("✗ Failed - no output file created\n")
    }
  }, error = function(e) {
    cat("✗ Failed:", e$message, "\n")
  })
}

# 5. Check system info
cat("\n5. System information...\n")
cat("R version:", R.version.string, "\n")
cat("Platform:", R.version$platform, "\n")
cat("OS:", Sys.info()["sysname"], Sys.info()["release"], "\n")
cat("Working directory:", getwd(), "\n")

# 6. Check pandoc
cat("\n6. Checking pandoc...\n")
tryCatch({
  pandoc_version <- rmarkdown::pandoc_version()
  cat("✓ Pandoc version:", pandoc_version, "\n")
}, error = function(e) {
  cat("✗ Pandoc check failed:", e$message, "\n")
})

# 7. Test with Chinese content
cat("\n7. Testing with Chinese content...\n")
test_md_chinese <- "---
title: '測試報告'
author: '測試用戶'
date: '2025-01-27'
output: 
  pdf_document:
    latex_engine: xelatex
---

# 測試報告

這是一個測試報告。

## 章節一

- 項目一
- 項目二
- 項目三

## 章節二

一些文字內容。
"

test_file_chinese <- "test_chinese.md"
writeLines(test_md_chinese, test_file_chinese, useBytes = TRUE)

tryCatch({
  output_file <- "test_output_chinese.pdf"
  rmarkdown::render(
    input = test_file_chinese,
    output_format = rmarkdown::pdf_document(latex_engine = "xelatex"),
    output_file = output_file,
    quiet = TRUE
  )
  if (file.exists(output_file)) {
    file_size <- file.size(output_file)
    cat("✓ Chinese test successful! File size:", file_size, "bytes\n")
    file.remove(output_file)
  } else {
    cat("✗ Chinese test failed - no output file created\n")
  }
}, error = function(e) {
  cat("✗ Chinese test failed:", e$message, "\n")
})

# Clean up
file.remove(test_file, test_file_chinese)

cat("\n=== Diagnosis Complete ===\n")
cat("\nRecommendations:\n")
cat("1. If LaTeX engines are missing, install MiKTeX\n")
cat("2. If Chinese content fails, install xeCJK package\n")
cat("3. If pandoc fails, update rmarkdown package\n")
cat("4. Check file permissions in working directory\n") 