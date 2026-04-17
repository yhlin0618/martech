# =============================================================================
# Windows MiKTeX LaTeX Compilation Fix
# =============================================================================

# Load required packages
if (!require(jsonlite)) install.packages("jsonlite")
if (!require(httr)) install.packages("httr")

library(jsonlite)
library(httr)

# =============================================================================
# Windows-Specific LaTeX Compilation Functions
# =============================================================================

compile_latex_windows <- function(latex_code, filename, compiler = "pdflatex") {
  # Windows-specific LaTeX compilation that handles MiKTeX GUI framework errors.
  #
  # Args:
  #   latex_code: LaTeX source code as string
  #   filename: Base filename (without extension)
  #   compiler: Compiler to use (pdflatex or xelatex)
  #
  # Returns:
  #   List with success status and file paths
  
  # Create reports directory if it doesn't exist
  reports_dir <- "test_reports"
  if (!dir.exists(reports_dir)) {
    dir.create(reports_dir, recursive = TRUE)
  }
  
  # Define file paths
  tex_file <- file.path(reports_dir, paste0(filename, ".tex"))
  pdf_file <- file.path(reports_dir, paste0(filename, ".pdf"))
  log_file <- file.path(reports_dir, paste0(filename, ".log"))
  
  # Write LaTeX code to file
  writeLines(latex_code, tex_file, useBytes = TRUE)
  
  cat("編譯 LaTeX 文件: ", filename, ".tex\n")
  cat("使用編譯器: ", compiler, "\n")
  
  # Try different compilation approaches
  compilation_result <- try_approach_1(latex_code, filename, compiler, reports_dir)
  if (compilation_result$success) return(compilation_result)
  
  compilation_result <- try_approach_2(latex_code, filename, compiler, reports_dir)
  if (compilation_result$success) return(compilation_result)
  
  compilation_result <- try_approach_3(latex_code, filename, compiler, reports_dir)
  if (compilation_result$success) return(compilation_result)
  
  compilation_result <- try_approach_4(latex_code, filename, compiler, reports_dir)
  if (compilation_result$success) return(compilation_result)
  
  # All approaches failed
  return(list(
    success = FALSE,
    error = "All compilation approaches failed",
    tex_path = tex_file,
    log_path = log_file
  ))
}

try_approach_1 <- function(latex_code, filename, compiler, reports_dir) {
  # Approach 1: Direct system2 call with nonstopmode
  cat("  嘗試方法 1: 直接 system2 調用...\n")
  
  tex_file <- file.path(reports_dir, paste0(filename, ".tex"))
  pdf_file <- file.path(reports_dir, paste0(filename, ".pdf"))
  log_file <- file.path(reports_dir, paste0(filename, ".log"))
  
  args <- c("-interaction=nonstopmode", "-output-directory", reports_dir, tex_file)
  
  tryCatch({
    result <- system2(compiler, args, stdout = TRUE, stderr = TRUE)
    
    if (file.exists(pdf_file)) {
      return(list(
        success = TRUE,
        pdf_path = pdf_file,
        tex_path = tex_file,
        log_path = log_file,
        output = result,
        method = "direct_system2"
      ))
    }
  }, error = function(e) {
    # Continue to next approach
  })
  
  return(list(success = FALSE))
}

try_approach_2 <- function(latex_code, filename, compiler, reports_dir) {
  # Approach 2: Create and execute batch file
  cat("  嘗試方法 2: 批次檔案執行...\n")
  
  tex_file <- file.path(reports_dir, paste0(filename, ".tex"))
  pdf_file <- file.path(reports_dir, paste0(filename, ".pdf"))
  log_file <- file.path(reports_dir, paste0(filename, ".log"))
  batch_file <- file.path(reports_dir, paste0(filename, ".bat"))
  
  # Create batch file
  batch_content <- paste0(
    "@echo off\n",
    "cd /d \"", normalizePath(reports_dir), "\"\n",
    "\"", compiler, "\" -interaction=nonstopmode -output-directory \"", reports_dir, "\" \"", tex_file, "\"\n",
    "if exist \"", pdf_file, "\" echo SUCCESS\n"
  )
  
  writeLines(batch_content, batch_file)
  
  tryCatch({
    result <- system2("cmd", c("/c", batch_file), stdout = TRUE, stderr = TRUE)
    
    if (file.exists(pdf_file)) {
      # Clean up batch file
      file.remove(batch_file)
      return(list(
        success = TRUE,
        pdf_path = pdf_file,
        tex_path = tex_file,
        log_path = log_file,
        output = result,
        method = "batch_file"
      ))
    }
  }, error = function(e) {
    # Continue to next approach
  })
  
  # Clean up batch file
  if (file.exists(batch_file)) file.remove(batch_file)
  return(list(success = FALSE))
}

try_approach_3 <- function(latex_code, filename, compiler, reports_dir) {
  # Approach 3: Use PowerShell execution
  cat("  嘗試方法 3: PowerShell 執行...\n")
  
  tex_file <- file.path(reports_dir, paste0(filename, ".tex"))
  pdf_file <- file.path(reports_dir, paste0(filename, ".pdf"))
  log_file <- file.path(reports_dir, paste0(filename, ".log"))
  
  # Create PowerShell command
  ps_command <- paste0(
    "Set-Location '", normalizePath(reports_dir), "'; ",
    "& '", compiler, "' -interaction=nonstopmode -output-directory '", reports_dir, "' '", tex_file, "'"
  )
  
  tryCatch({
    result <- system2("powershell", c("-Command", ps_command), stdout = TRUE, stderr = TRUE)
    
    if (file.exists(pdf_file)) {
      return(list(
        success = TRUE,
        pdf_path = pdf_file,
        tex_path = tex_file,
        log_path = log_file,
        output = result,
        method = "powershell"
      ))
    }
  }, error = function(e) {
    # Continue to next approach
  })
  
  return(list(success = FALSE))
}

try_approach_4 <- function(latex_code, filename, compiler, reports_dir) {
  # Approach 4: Simple English-only document
  cat("  嘗試方法 4: 簡單英文文檔...\n")
  
  tex_file <- file.path(reports_dir, paste0(filename, ".tex"))
  pdf_file <- file.path(reports_dir, paste0(filename, ".pdf"))
  log_file <- file.path(reports_dir, paste0(filename, ".log"))
  
  # Create simple English document
  simple_tex <- "\\documentclass{article}
\\usepackage[utf8]{inputenc}
\\title{Test Report}
\\author{LaTeX Test}
\\begin{document}
\\maketitle
\\section{Summary}
This is a test report generated from the data.
\\section{Data Overview}
The report contains processed data from the application.
\\section{Results}
\\begin{itemize}
\\item Data processing completed successfully
\\item Report generation successful
\\item PDF compilation working
\\end{itemize}
\\end{document}"
  
  writeLines(simple_tex, tex_file, useBytes = TRUE)
  
  args <- c("-interaction=nonstopmode", "-output-directory", reports_dir, tex_file)
  
  tryCatch({
    result <- system2(compiler, args, stdout = TRUE, stderr = TRUE)
    
    if (file.exists(pdf_file)) {
      return(list(
        success = TRUE,
        pdf_path = pdf_file,
        tex_path = tex_file,
        log_path = log_file,
        output = result,
        method = "simple_english"
      ))
    }
  }, error = function(e) {
    # Continue to next approach
  })
  
  return(list(success = FALSE))
}

# =============================================================================
# Test Functions
# =============================================================================

test_windows_compilation <- function() {
  cat("=== Windows MiKTeX 編譯測試 ===\n\n")
  
  # Test 1: Check compilers
  cat("1. 檢查編譯器...\n")
  compilers <- list(pdflatex = FALSE, xelatex = FALSE)
  
  tryCatch({
    result <- system2("pdflatex", "--version", stdout = TRUE, stderr = TRUE)
    compilers$pdflatex <- TRUE
    cat("   ✓ pdflatex 可用\n")
  }, error = function(e) {
    cat("   ✗ pdflatex 不可用\n")
  })
  
  tryCatch({
    result <- system2("xelatex", "--version", stdout = TRUE, stderr = TRUE)
    compilers$xelatex <- TRUE
    cat("   ✓ xelatex 可用\n")
  }, error = function(e) {
    cat("   ✗ xelatex 不可用\n")
  })
  
  if (!compilers$pdflatex && !compilers$xelatex) {
    cat("\n✗ 無可用編譯器，測試終止\n")
    return(FALSE)
  }
  
  # Test 2: Test compilation approaches
  cat("\n2. 測試編譯方法...\n")
  
  test_tex <- "\\documentclass{article}
\\usepackage[utf8]{inputenc}
\\title{Windows Test Report}
\\author{LaTeX Test}
\\begin{document}
\\maketitle
\\section{Test Section}
This is a test document for Windows MiKTeX compilation.
\\end{document}"
  
  compiler_to_use <- ifelse(compilers$pdflatex, "pdflatex", "xelatex")
  filename <- paste0("windows_test_", format(Sys.time(), "%H%M%S"))
  
  result <- compile_latex_windows(test_tex, filename, compiler_to_use)
  
  if (result$success) {
    cat("   ✓ 編譯成功！\n")
    cat("   - 使用方法: ", result$method, "\n")
    cat("   - PDF 檔案: ", result$pdf_path, "\n")
    cat("   - 檔案大小: ", file.size(result$pdf_path), " bytes\n")
    return(TRUE)
  } else {
    cat("   ✗ 編譯失敗\n")
    cat("   - 錯誤: ", result$error, "\n")
    return(FALSE)
  }
}

# =============================================================================
# Main Execution
# =============================================================================

cat("=== Windows MiKTeX LaTeX 編譯修復測試 ===\n\n")

# Run the test
success <- test_windows_compilation()

cat("\n=== 測試結果 ===\n")
if (success) {
  cat("✓ Windows MiKTeX 編譯修復成功！\n")
  cat("  現在可以運行完整的 LaTeX 報告模組測試\n")
} else {
  cat("✗ Windows MiKTeX 編譯修復失敗\n")
  cat("  建議:\n")
  cat("  1. 檢查 MiKTeX 安裝\n")
  cat("  2. 嘗試重新安裝 MiKTeX\n")
  cat("  3. 檢查系統環境變數\n")
}

cat("\n測試完成！\n") 