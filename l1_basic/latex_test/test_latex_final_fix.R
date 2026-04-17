# =============================================================================
# LaTeX Report Module - Final Fix (Using shell() for Windows)
# =============================================================================

# Load required packages
if (!require(jsonlite)) install.packages("jsonlite")
if (!require(httr)) install.packages("httr")

library(jsonlite)
library(httr)

# =============================================================================
# Fixed LaTeX Compilation Functions
# =============================================================================

compile_latex_fixed <- function(latex_code, filename, compiler = "pdflatex") {
  # Compile LaTeX code using shell() instead of system2() for better Windows compatibility.
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
  
  # Change to reports directory
  old_wd <- getwd()
  setwd(reports_dir)
  
  # Prepare compilation command
  cmd <- paste0(compiler, " -interaction=nonstopmode ", basename(tex_file))
  
  cat("編譯命令: ", cmd, "\n")
  
  # Compile LaTeX using shell()
  tryCatch({
    result <- shell(cmd, intern = TRUE)
    
    # Check if PDF was created
    if (file.exists(basename(pdf_file))) {
      setwd(old_wd)
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
      if (file.exists(basename(log_file))) {
        log_content <- readLines(basename(log_file), warn = FALSE)
      }
      
      setwd(old_wd)
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
    setwd(old_wd)
    return(list(
      success = FALSE,
      error = e$message,
      tex_path = tex_file,
      compiler = compiler
    ))
  })
}

test_latex_compilation_fixed <- function() {
  cat("=== 測試修正後的 LaTeX 編譯 ===\n")
  
  # Test 1: Simple English document
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
  
  result1 <- compile_latex_fixed(simple_tex, "test_simple_english_fixed")
  cat("   結果: ", ifelse(result1$success, "✓", "✗"), "\n")
  
  # Test 2: Chinese document with xeCJK
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
  
  result2 <- compile_latex_fixed(chinese_tex, "test_chinese_xecjk_fixed", "xelatex")
  cat("   結果: ", ifelse(result2$success, "✓", "✗"), "\n")
  
  # Test 3: Chinese document with ctex
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
  
  result3 <- compile_latex_fixed(ctex_tex, "test_chinese_ctex_fixed", "xelatex")
  cat("   結果: ", ifelse(result3$success, "✓", "✗"), "\n")
  
  return(list(
    simple_english = result1,
    chinese_xecjk = result2,
    chinese_ctex = result3
  ))
}

test_compiler_availability_fixed <- function() {
  cat("=== 檢查編譯器可用性 (使用 shell()) ===\n")
  
  compilers <- list(pdflatex = FALSE, xelatex = FALSE)
  
  # Check pdflatex using shell()
  tryCatch({
    result <- shell("pdflatex --version", intern = TRUE)
    compilers$pdflatex <- TRUE
    cat("   ✓ pdflatex 可用\n")
  }, error = function(e) {
    cat("   ✗ pdflatex 不可用: ", e$message, "\n")
  })
  
  # Check xelatex using shell()
  tryCatch({
    result <- shell("xelatex --version", intern = TRUE)
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

cat("=== LaTeX 報告模組最終修正測試 ===\n\n")

# Check compiler availability
compilers <- test_compiler_availability_fixed()

if (!compilers$pdflatex && !compilers$xelatex) {
  cat("\n✗ 無可用編譯器，測試終止\n")
  cat("請安裝 LaTeX 編譯器 (MiKTeX 或 TeX Live)\n")
} else {
  # Run compilation tests
  results <- test_latex_compilation_fixed()
  
  # Summary
  cat("\n=== 測試總結 ===\n")
  for (test_name in names(results)) {
    result <- results[[test_name]]
    status <- ifelse(result$success, "✓", "✗")
    cat(test_name, ": ", status, "\n")
    
    if (result$success) {
      cat("   PDF 檔案: ", result$pdf_path, "\n")
      cat("   檔案大小: ", file.size(result$pdf_path), " bytes\n")
    } else if (!is.null(result$log_content)) {
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
    cat("✓ 基本 LaTeX 編譯正常 (使用 shell() 方法)\n")
  } else {
    cat("✗ 基本 LaTeX 編譯失敗\n")
  }
  
  if (results$chinese_xecjk$success || results$chinese_ctex$success) {
    cat("✓ 中文支援正常 (推薦使用 xelatex + xeCJK 或 ctex)\n")
  } else {
    cat("✗ 中文支援失敗 - 可能需要安裝中文字體或套件\n")
  }
  
  if (results$simple_english$success) {
    cat("\n✓ LaTeX 報告模組現在可以正常工作了！\n")
    cat("  可以運行完整的測試應用程式\n")
  }
}

cat("\n測試完成！\n") 