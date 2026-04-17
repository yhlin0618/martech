# =============================================================================
# LaTeX Report Module - Corrected Test (Proper LaTeX Syntax)
# =============================================================================

# Load required packages
if (!require(jsonlite)) install.packages("jsonlite")
if (!require(httr)) install.packages("httr")

library(jsonlite)
library(httr)

# =============================================================================
# Test Functions with Correct LaTeX Syntax
# =============================================================================

test_latex_compilation_corrected <- function() {
  cat("=== 測試正確的 LaTeX 語法編譯 ===\n")
  
  # Test 1: Simple English document (basic test)
  cat("\n1. 測試簡單英文文檔...\n")
  simple_tex <- "\\documentclass{article}
\\usepackage[utf8]{inputenc}
\\title{Test Report}
\\author{LaTeX Test}
\\date{\\today}
\\begin{document}
\\maketitle
\\section{Summary}
This is a test report generated from the data.
\\section{Data Overview}
The report contains processed data from the application.
\\end{document}"
  
  result1 <- compile_simple_latex(simple_tex, "test_simple_english")
  cat("   結果: ", ifelse(result1$success, "✓", "✗"), "\n")
  
  # Test 2: Chinese document with xeCJK (recommended approach)
  cat("\n2. 測試中文文檔 (xeCJK)...\n")
  chinese_tex <- "\\documentclass{article}
\\usepackage{xeCJK}
\\setCJKmainfont{WenQuanYi Micro Hei}
\\XeTeXlinebreaklocale \"zh\"
\\title{測試報告}
\\author{LaTeX 測試}
\\date{\\today}
\\begin{document}
\\maketitle
\\section{摘要}
這是一個測試報告。
\\section{數據概覽}
報告包含來自應用程序的處理數據。
\\end{document}"
  
  result2 <- compile_simple_latex(chinese_tex, "test_chinese_xecjk", "xelatex")
  cat("   結果: ", ifelse(result2$success, "✓", "✗"), "\n")
  
  # Test 3: Chinese document with ctex (alternative approach)
  cat("\n3. 測試中文文檔 (ctex)...\n")
  ctex_tex <- "\\documentclass{ctexart}
\\title{測試報告}
\\author{LaTeX 測試}
\\date{\\today}
\\begin{document}
\\maketitle
\\section{摘要}
這是一個測試報告。
\\section{數據概覽}
報告包含來自應用程序的處理數據。
\\end{document}"
  
  result3 <- compile_simple_latex(ctex_tex, "test_chinese_ctex", "xelatex")
  cat("   結果: ", ifelse(result3$success, "✓", "✗"), "\n")
  
  # Test 4: Chinese document with CJKutf8 (pdflatex approach)
  cat("\n4. 測試中文文檔 (CJKutf8)...\n")
  cjk_tex <- "\\documentclass{article}
\\usepackage[utf8]{inputenc}
\\usepackage{CJKutf8}
\\title{測試報告}
\\author{LaTeX 測試}
\\date{\\today}
\\begin{document}
\\begin{CJK*}{UTF8}{gbsn}
\\maketitle
\\section{摘要}
這是一個測試報告。
\\section{數據概覽}
報告包含來自應用程序的處理數據。
\\end{CJK*}
\\end{document}"
  
  result4 <- compile_simple_latex(cjk_tex, "test_chinese_cjk", "pdflatex")
  cat("   結果: ", ifelse(result4$success, "✓", "✗"), "\n")
  
  return(list(
    simple_english = result1,
    chinese_xecjk = result2,
    chinese_ctex = result3,
    chinese_cjk = result4
  ))
}

compile_simple_latex <- function(latex_code, filename, compiler = "pdflatex") {
  # Compile LaTeX code with proper error handling.
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
  
  # Prepare compilation arguments
  args <- c(
    "-interaction=nonstopmode",
    "-output-directory", reports_dir,
    tex_file
  )
  
  # Compile LaTeX
  tryCatch({
    result <- system2(compiler, args, stdout = TRUE, stderr = TRUE)
    
    # Check if PDF was created
    if (file.exists(pdf_file)) {
      return(list(
        success = TRUE,
        pdf_path = pdf_file,
        tex_path = tex_file,
        log_path = log_file,
        output = result,
        compiler = compiler
      ))
    } else {
      # Check log file for errors
      log_content <- ""
      if (file.exists(log_file)) {
        log_content <- readLines(log_file, warn = FALSE)
      }
      
      return(list(
        success = FALSE,
        error = "PDF not created",
        tex_path = tex_file,
        log_path = log_file,
        log_content = log_content,
        output = result,
        compiler = compiler
      ))
    }
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message,
      tex_path = tex_file,
      compiler = compiler
    ))
  })
}

test_compiler_availability <- function() {
  cat("=== 檢查編譯器可用性 ===\n")
  
  compilers <- list(pdflatex = FALSE, xelatex = FALSE)
  
  # Check pdflatex
  tryCatch({
    result <- system2("pdflatex", "--version", stdout = TRUE, stderr = TRUE)
    compilers$pdflatex <- TRUE
    cat("   ✓ pdflatex 可用\n")
  }, error = function(e) {
    cat("   ✗ pdflatex 不可用: ", e$message, "\n")
  })
  
  # Check xelatex
  tryCatch({
    result <- system2("xelatex", "--version", stdout = TRUE, stderr = TRUE)
    compilers$xelatex <- TRUE
    cat("   ✓ xelatex 可用\n")
  }, error = function(e) {
    cat("   ✗ xelatex 不可用: ", e$message, "\n")
  })
  
  return(compilers)
}

# =============================================================================
# Main Test Execution
# =============================================================================

cat("=== LaTeX 報告模組語法修正測試 ===\n\n")

# Check compiler availability
compilers <- test_compiler_availability()

if (!compilers$pdflatex && !compilers$xelatex) {
  cat("\n✗ 無可用編譯器，測試終止\n")
  cat("請安裝 LaTeX 編譯器 (MiKTeX 或 TeX Live)\n")
} else {
  # Run compilation tests
  results <- test_latex_compilation_corrected()
  
  # Summary
  cat("\n=== 測試總結 ===\n")
  for (test_name in names(results)) {
    result <- results[[test_name]]
    status <- ifelse(result$success, "✓", "✗")
    cat(test_name, ": ", status, "\n")
    
    if (!result$success && !is.null(result$log_content)) {
      cat("   錯誤日誌 (前5行):\n")
      log_lines <- head(result$log_content, 5)
      for (line in log_lines) {
        cat("     ", line, "\n")
      }
    }
  }
  
  # Recommendations
  cat("\n=== 建議 ===\n")
  if (results$simple_english$success) {
    cat("✓ 基本 LaTeX 編譯正常\n")
  } else {
    cat("✗ 基本 LaTeX 編譯失敗 - 檢查編譯器安裝\n")
  }
  
  if (results$chinese_xecjk$success || results$chinese_ctex$success) {
    cat("✓ 中文支援正常 (推薦使用 xelatex + xeCJK 或 ctex)\n")
  } else if (results$chinese_cjk$success) {
    cat("✓ 中文支援正常 (使用 pdflatex + CJKutf8)\n")
  } else {
    cat("✗ 中文支援失敗 - 可能需要安裝中文字體或套件\n")
  }
}

cat("\n測試完成！\n") 