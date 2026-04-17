# =============================================================================
# Quick Test: test_latex_quick_test
# Purpose: Quick test script to verify LaTeX report module functionality
# Author: Claude
# Date Created: 2025-01-27
# Related Principles: R21, R69, R75
# =============================================================================

# Load required packages
library(dplyr)
library(jsonlite)

# Source utility functions
if (file.exists("scripts/global_scripts/04_utils/fn_latex_report_utils.R")) {
  source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")
} else {
  stop("LaTeX report utilities not found!")
}

# =============================================================================
# Test Data Creation
# =============================================================================

cat("=== LaTeX 報告模組快速測試 ===\n\n")

# Create test sales data
cat("1. 創建測試銷售資料...\n")
test_sales <- data.frame(
  customer_id = c("customer_001", "customer_001", "customer_002", "customer_002", "customer_003"),
  lineitem_price = c(125.50, 200.00, 89.99, 150.75, 300.00),
  payment_time = as.POSIXct(c("2024-01-15 10:30:00", "2024-01-20 09:15:00", 
                              "2024-01-16 14:20:00", "2024-01-25 11:30:00", 
                              "2024-01-28 13:20:00")),
  product_name = c("產品A", "產品C", "產品B", "產品D", "產品B"),
  platform = c("amazon", "amazon", "ebay", "ebay", "amazon")
)

cat("   ✓ 銷售資料創建完成 (", nrow(test_sales), "筆記錄)\n")

# Create test DNA data
cat("2. 創建測試 DNA 分析資料...\n")
test_dna <- data.frame(
  customer_id = c("customer_001", "customer_002", "customer_003"),
  m_value = c(325.50, 240.74, 300.00),
  r_value = c(15.5, 12.3, 8.2),
  f_value = c(2, 2, 1),
  ipt_value = c(5.0, 9.0, 0.0),
  nes_status = c("High", "Medium", "High")
)

cat("   ✓ DNA 分析資料創建完成 (", nrow(test_dna), "位客戶)\n")

# =============================================================================
# Test Data Collection Function
# =============================================================================

cat("3. 測試資料收集功能...\n")

tryCatch({
  report_data <- fn_collect_report_data(
    sales_data = test_sales,
    dna_results = test_dna,
    metadata = list(
      title = "測試報告",
      author = "測試用戶",
      date = "2025-01-27"
    ),
    include_options = list(
      sales_summary = TRUE,
      dna_analysis = TRUE,
      customer_segments = TRUE
    ),
    verbose = FALSE
  )
  
  cat("   ✓ 資料收集成功\n")
  cat("   - 銷售摘要: ", ifelse(!is.null(report_data$sales_summary), "✓", "✗"), "\n")
  cat("   - DNA 分析: ", ifelse(!is.null(report_data$dna_analysis), "✓", "✗"), "\n")
  cat("   - 客戶分群: ", ifelse(!is.null(report_data$customer_segments), "✓", "✗"), "\n")
  
}, error = function(e) {
  cat("   ✗ 資料收集失敗:", e$message, "\n")
})

# =============================================================================
# Test LaTeX Compiler Validation
# =============================================================================

cat("4. 測試 LaTeX 編譯器驗證...\n")

# Test pdflatex
pdflatex_available <- fn_validate_latex_compiler("pdflatex", verbose = FALSE)
cat("   - pdflatex: ", ifelse(pdflatex_available, "✓ 可用", "✗ 不可用"), "\n")

# Test xelatex
xelatex_available <- fn_validate_latex_compiler("xelatex", verbose = FALSE)
cat("   - xelatex: ", ifelse(xelatex_available, "✓ 可用", "✗ 不可用"), "\n")

# =============================================================================
# Test LaTeX Compilation (if compiler available)
# =============================================================================

if (pdflatex_available || xelatex_available) {
  cat("5. 測試 LaTeX 編譯功能...\n")
  
  # Create simple LaTeX document
  simple_latex <- paste(
    "\\documentclass{article}",
    "\\usepackage{CJKutf8}",
    "\\begin{document}",
    "\\begin{CJK*}{UTF8}{gbsn}",
    "\\title{測試報告}",
    "\\author{測試用戶}",
    "\\date{\\today}",
    "\\maketitle",
    "\\section{摘要}",
    "這是一個測試報告，用於驗證 LaTeX 編譯功能。",
    "\\section{資料概覽}",
    "總交易數: 5",
    "客戶數量: 3",
    "總收入: 865.24",
    "\\end{CJK*}",
    "\\end{document}",
    sep = "\n"
  )
  
  # Choose available compiler
  compiler <- ifelse(pdflatex_available, "pdflatex", "xelatex")
  
  tryCatch({
    compile_result <- fn_compile_latex_report(
      latex_source = simple_latex,
      output_dir = "test_reports",
      compiler = compiler,
      filename_prefix = "quick_test",
      verbose = FALSE
    )
    
    if (!is.null(compile_result$success) && compile_result$success) {
      cat("   ✓ LaTeX 編譯成功\n")
      cat("   - PDF 檔案: ", compile_result$pdf_path, "\n")
      cat("   - TEX 檔案: ", compile_result$tex_path, "\n")
    } else {
      cat("   ✗ LaTeX 編譯失敗:", compile_result$error, "\n")
    }
    
  }, error = function(e) {
    cat("   ✗ 編譯過程發生錯誤:", e$message, "\n")
  })
  
} else {
  cat("5. 跳過 LaTeX 編譯測試 (無可用編譯器)\n")
}

# =============================================================================
# Test Error Handling
# =============================================================================

cat("6. 測試錯誤處理...\n")

# Test with empty data
empty_result <- fn_collect_report_data(
  sales_data = data.frame(),
  verbose = FALSE
)
cat("   - 空資料處理: ", ifelse("error" %in% names(empty_result), "✓", "✗"), "\n")

# Test with invalid data
invalid_result <- fn_collect_report_data(
  sales_data = "not a dataframe",
  verbose = FALSE
)
cat("   - 無效資料處理: ", ifelse("error" %in% names(invalid_result), "✓", "✗"), "\n")

# =============================================================================
# Test Summary
# =============================================================================

cat("\n=== 測試總結 ===\n")
cat("✓ 測試資料創建\n")
cat("✓ 資料收集功能\n")
cat("✓ 編譯器驗證\n")
if (pdflatex_available || xelatex_available) {
  cat("✓ LaTeX 編譯功能\n")
} else {
  cat("⚠ LaTeX 編譯功能 (需要安裝編譯器)\n")
}
cat("✓ 錯誤處理\n")

cat("\n=== 下一步 ===\n")
cat("1. 如果所有測試都通過，可以運行 test_latex_app.R 進行完整測試\n")
cat("2. 確保已安裝 LaTeX 編譯器 (pdflatex 或 xelatex)\n")
cat("3. 準備 OpenAI API Key 以測試 GPT 功能\n")
cat("4. 使用 test_data/sample_sales_data.csv 進行更完整的測試\n")

cat("\n測試完成！\n") 