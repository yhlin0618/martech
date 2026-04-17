# =============================================================================
# LaTeX Diagnostic Test
# Purpose: Diagnose LaTeX compilation issues
# Author: Claude
# Date Created: 2025-01-27
# =============================================================================

cat("=== LaTeX 編譯診斷測試 ===\n\n")

# =============================================================================
# 1. Check System Information
# =============================================================================

cat("1. 系統資訊檢查...\n")
cat("   - 作業系統: ", Sys.info()["sysname"], "\n")
cat("   - R 版本: ", R.version.string, "\n")
cat("   - 工作目錄: ", getwd(), "\n")

# =============================================================================
# 2. Check LaTeX Installation
# =============================================================================

cat("\n2. LaTeX 安裝檢查...\n")

# Check pdflatex
cat("   檢查 pdflatex...\n")
pdflatex_result <- tryCatch({
  result <- system2("pdflatex", "--version", stdout = TRUE, stderr = TRUE)
  if (length(result) > 0) {
    cat("   ✓ pdflatex 可用\n")
    cat("   版本資訊: ", result[1], "\n")
    TRUE
  } else {
    cat("   ✗ pdflatex 不可用\n")
    FALSE
  }
}, error = function(e) {
  cat("   ✗ pdflatex 錯誤: ", e$message, "\n")
  FALSE
})

# Check xelatex
cat("   檢查 xelatex...\n")
xelatex_result <- tryCatch({
  result <- system2("xelatex", "--version", stdout = TRUE, stderr = TRUE)
  if (length(result) > 0) {
    cat("   ✓ xelatex 可用\n")
    cat("   版本資訊: ", result[1], "\n")
    TRUE
  } else {
    cat("   ✗ xelatex 不可用\n")
    FALSE
  }
}, error = function(e) {
  cat("   ✗ xelatex 錯誤: ", e$message, "\n")
  FALSE
})

# =============================================================================
# 3. Test Directory Creation
# =============================================================================

cat("\n3. 測試目錄檢查...\n")
test_dir <- "test_reports"

# Check if directory exists
if (dir.exists(test_dir)) {
  cat("   ✓ 測試目錄存在: ", test_dir, "\n")
} else {
  cat("   創建測試目錄...\n")
  dir_result <- tryCatch({
    dir.create(test_dir, recursive = TRUE)
    cat("   ✓ 測試目錄創建成功\n")
    TRUE
  }, error = function(e) {
    cat("   ✗ 測試目錄創建失敗: ", e$message, "\n")
    FALSE
  })
}

# Check write permissions
write_test <- tryCatch({
  test_file <- file.path(test_dir, "write_test.txt")
  writeLines("test", test_file)
  file.remove(test_file)
  cat("   ✓ 目錄可寫入\n")
  TRUE
}, error = function(e) {
  cat("   ✗ 目錄不可寫入: ", e$message, "\n")
  FALSE
})

# =============================================================================
# 4. Test Simple LaTeX Compilation
# =============================================================================

if (pdflatex_result || xelatex_result) {
  cat("\n4. 簡單 LaTeX 編譯測試...\n")
  
  # Create a very simple LaTeX document
  simple_latex <- paste(
    "\\documentclass{article}",
    "\\begin{document}",
    "Hello World!",
    "\\end{document}",
    sep = "\n"
  )
  
  # Write the LaTeX file
  tex_file <- file.path(test_dir, "simple_test.tex")
  writeLines(simple_latex, tex_file)
  cat("   ✓ LaTeX 檔案已創建: ", basename(tex_file), "\n")
  
  # Try to compile with available compiler
  compiler <- ifelse(pdflatex_result, "pdflatex", "xelatex")
  cat("   使用編譯器: ", compiler, "\n")
  
  compile_result <- tryCatch({
    # Run compilation
    result <- system2(
      compiler,
      args = c("-interaction=nonstopmode", "-output-directory", test_dir, tex_file),
      stdout = TRUE,
      stderr = TRUE
    )
    
    # Check if PDF was created
    pdf_file <- file.path(test_dir, "simple_test.pdf")
    if (file.exists(pdf_file)) {
      cat("   ✓ 編譯成功! PDF 已創建: ", basename(pdf_file), "\n")
      cat("   PDF 大小: ", file.size(pdf_file), " bytes\n")
      TRUE
    } else {
      cat("   ✗ 編譯失敗: PDF 未創建\n")
      cat("   編譯輸出:\n")
      cat(paste("   ", result), sep = "\n")
      FALSE
    }
  }, error = function(e) {
    cat("   ✗ 編譯錯誤: ", e$message, "\n")
    FALSE
  })
  
} else {
  cat("\n4. 跳過編譯測試 (無可用編譯器)\n")
  compile_result <- FALSE
}

# =============================================================================
# 5. Check LaTeX Packages
# =============================================================================

if (compile_result) {
  cat("\n5. LaTeX 套件檢查...\n")
  
  # Test CJKutf8 package
  cat("   檢查 CJKutf8 套件...\n")
  cjk_latex <- paste(
    "\\documentclass{article}",
    "\\usepackage{CJKutf8}",
    "\\begin{document}",
    "\\begin{CJK*}{UTF8}{gbsn}",
    "測試",
    "\\end{CJK*}",
    "\\end{document}",
    sep = "\n"
  )
  
  cjk_tex_file <- file.path(test_dir, "cjk_test.tex")
  writeLines(cjk_latex, cjk_tex_file)
  
  cjk_result <- tryCatch({
    result <- system2(
      compiler,
      args = c("-interaction=nonstopmode", "-output-directory", test_dir, cjk_tex_file),
      stdout = TRUE,
      stderr = TRUE
    )
    
    cjk_pdf_file <- file.path(test_dir, "cjk_test.pdf")
    if (file.exists(cjk_pdf_file)) {
      cat("   ✓ CJKutf8 套件可用\n")
      TRUE
    } else {
      cat("   ✗ CJKutf8 套件不可用\n")
      cat("   錯誤訊息:\n")
      cat(paste("   ", result), sep = "\n")
      FALSE
    }
  }, error = function(e) {
    cat("   ✗ CJKutf8 測試錯誤: ", e$message, "\n")
    FALSE
  })
  
  # Test ctex package (if xelatex is available)
  if (xelatex_result) {
    cat("   檢查 ctex 套件...\n")
    ctex_latex <- paste(
      "\\documentclass[UTF8]{ctexart}",
      "\\begin{document}",
      "測試",
      "\\end{document}",
      sep = "\n"
    )
    
    ctex_tex_file <- file.path(test_dir, "ctex_test.tex")
    writeLines(ctex_latex, ctex_tex_file)
    
    ctex_result <- tryCatch({
      result <- system2(
        "xelatex",
        args = c("-interaction=nonstopmode", "-output-directory", test_dir, ctex_tex_file),
        stdout = TRUE,
        stderr = TRUE
      )
      
      ctex_pdf_file <- file.path(test_dir, "ctex_test.pdf")
      if (file.exists(ctex_pdf_file)) {
        cat("   ✓ ctex 套件可用\n")
        TRUE
      } else {
        cat("   ✗ ctex 套件不可用\n")
        cat("   錯誤訊息:\n")
        cat(paste("   ", result), sep = "\n")
        FALSE
      }
    }, error = function(e) {
      cat("   ✗ ctex 測試錯誤: ", e$message, "\n")
      FALSE
    })
  } else {
    cat("   跳過 ctex 測試 (需要 xelatex)\n")
    ctex_result <- FALSE
  }
  
} else {
  cat("\n5. 跳過套件檢查 (基本編譯失敗)\n")
  cjk_result <- FALSE
  ctex_result <- FALSE
}

# =============================================================================
# 6. Summary and Recommendations
# =============================================================================

cat("\n=== 診斷總結 ===\n")

cat("系統狀態:\n")
cat("- 作業系統: ", Sys.info()["sysname"], "\n")
cat("- LaTeX 編譯器: ", ifelse(pdflatex_result || xelatex_result, "✓ 可用", "✗ 不可用"), "\n")
cat("- 目錄權限: ", ifelse(write_test, "✓ 正常", "✗ 有問題"), "\n")
cat("- 基本編譯: ", ifelse(compile_result, "✓ 成功", "✗ 失敗"), "\n")

if (compile_result) {
  cat("- 中文支援:\n")
  cat("  - CJKutf8: ", ifelse(cjk_result, "✓ 可用", "✗ 不可用"), "\n")
  if (xelatex_result) {
    cat("  - ctex: ", ifelse(ctex_result, "✓ 可用", "✗ 不可用"), "\n")
  }
}

cat("\n=== 建議 ===\n")

if (!pdflatex_result && !xelatex_result) {
  cat("1. 安裝 LaTeX 編譯器:\n")
  cat("   - Windows: 下載並安裝 MiKTeX\n")
  cat("   - macOS: 安裝 MacTeX\n")
  cat("   - Linux: sudo apt-get install texlive-full\n")
}

if (!write_test) {
  cat("2. 檢查目錄權限:\n")
  cat("   - 確保對 test_reports 目錄有寫入權限\n")
  cat("   - 檢查磁碟空間是否充足\n")
}

if (compile_result && !cjk_result && !ctex_result) {
  cat("3. 安裝中文支援套件:\n")
  cat("   - 安裝 CJKutf8 套件\n")
  cat("   - 安裝 ctex 套件 (推薦)\n")
}

if (compile_result) {
  cat("4. 下一步:\n")
  cat("   - 運行 test_latex_quick_test_fixed.R\n")
  cat("   - 測試完整的 LaTeX 報告模組\n")
}

cat("\n診斷完成！\n") 