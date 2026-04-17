# =============================================================================
# LaTeX Report Module - Quick Test (Fixed for Windows MiKTeX)
# =============================================================================

# Load required packages
if (!require(shiny)) install.packages("shiny")
if (!require(jsonlite)) install.packages("jsonlite")
if (!require(httr)) install.packages("httr")

library(shiny)
library(jsonlite)
library(httr)

# Source the utility functions
source("modules/latex_report_utils.R")

# =============================================================================
# Test Functions
# =============================================================================

test_data_collection <- function() {
  cat("=== 測試數據收集 ===\n")
  
  # Create sample data
  sample_data <- list(
    sales_data = data.frame(
      date = seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "month"),
      revenue = runif(12, 10000, 50000),
      units = round(runif(12, 100, 1000))
    ),
    dna_analysis = data.frame(
      customer_id = 1:100,
      segment = sample(c("High", "Medium", "Low"), 100, replace = TRUE),
      score = runif(100, 0, 100)
    ),
    other_results = list(
      total_revenue = 350000,
      avg_score = 65.5,
      top_segment = "High"
    )
  )
  
  # Test data collection
  tryCatch({
    collected_data <- collect_app_data(sample_data)
    cat("✓ 數據收集成功\n")
    cat("   - 銷售數據: ", nrow(collected_data$sales_data), " 行\n")
    cat("   - DNA分析: ", nrow(collected_data$dna_analysis), " 行\n")
    cat("   - 其他結果: ", length(collected_data$other_results), " 項\n")
    return(TRUE)
  }, error = function(e) {
    cat("✗ 數據收集失敗: ", e$message, "\n")
    return(FALSE)
  })
}

test_compiler_availability <- function() {
  cat("\n=== 測試編譯器可用性 ===\n")
  
  # Test compiler validation
  tryCatch({
    compilers <- validate_latex_compilers()
    cat("✓ 編譯器檢查完成\n")
    cat("   - pdflatex: ", ifelse(compilers$pdflatex, "✓", "✗"), "\n")
    cat("   - xelatex: ", ifelse(compilers$xelatex, "✓", "✗"), "\n")
    return(compilers)
  }, error = function(e) {
    cat("✗ 編譯器檢查失敗: ", e$message, "\n")
    return(list(pdflatex = FALSE, xelatex = FALSE))
  })
}

test_latex_compilation <- function(compilers) {
  cat("\n=== 測試 LaTeX 編譯 ===\n")
  
  # Create a simple test LaTeX file
  test_tex <- "\\documentclass{article}
\\usepackage[utf8]{inputenc}
\\usepackage{CJKutf8}
\\begin{document}
\\begin{CJK*}{UTF8}{gbsn}
\\title{測試報告}
\\author{LaTeX 測試}
\\maketitle
\\section{摘要}
這是一個測試報告。
\\end{CJK*}
\\end{document}"
  
  # Try different compilation approaches
  compilation_results <- list()
  
  # Approach 1: pdflatex with CJKutf8
  if (compilers$pdflatex) {
    cat("測試 pdflatex + CJKutf8...\n")
    tryCatch({
      result <- compile_latex_to_pdf(test_tex, "test_pdflatex_cjk", "pdflatex")
      compilation_results$pdflatex_cjk <- result
      cat("  ", ifelse(result$success, "✓", "✗"), " pdflatex + CJKutf8\n")
    }, error = function(e) {
      compilation_results$pdflatex_cjk <- list(success = FALSE, error = e$message)
      cat("  ✗ pdflatex + CJKutf8: ", e$message, "\n")
    })
  }
  
  # Approach 2: xelatex with ctex
  if (compilers$xelatex) {
    cat("測試 xelatex + ctex...\n")
    ctex_tex <- "\\documentclass{ctexart}
\\title{測試報告}
\\author{LaTeX 測試}
\\begin{document}
\\maketitle
\\section{摘要}
這是一個測試報告。
\\end{document}"
    
    tryCatch({
      result <- compile_latex_to_pdf(ctex_tex, "test_xelatex_ctex", "xelatex")
      compilation_results$xelatex_ctex <- result
      cat("  ", ifelse(result$success, "✓", "✗"), " xelatex + ctex\n")
    }, error = function(e) {
      compilation_results$xelatex_ctex <- list(success = FALSE, error = e$message)
      cat("  ✗ xelatex + ctex: ", e$message, "\n")
    })
  }
  
  # Approach 3: Simple English-only document
  cat("測試簡單英文文檔...\n")
  simple_tex <- "\\documentclass{article}
\\usepackage[utf8]{inputenc}
\\title{Test Report}
\\author{LaTeX Test}
\\begin{document}
\\maketitle
\\section{Summary}
This is a test report.
\\end{document}"
  
  tryCatch({
    result <- compile_latex_to_pdf(simple_tex, "test_simple_english", "pdflatex")
    compilation_results$simple_english <- result
    cat("  ", ifelse(result$success, "✓", "✗"), " 簡單英文文檔\n")
  }, error = function(e) {
    compilation_results$simple_english <- list(success = FALSE, error = e$message)
    cat("  ✗ 簡單英文文檔: ", e$message, "\n")
  })
  
  return(compilation_results)
}

test_gpt_integration <- function() {
  cat("\n=== 測試 GPT 整合 ===\n")
  
  # Check if API key is available
  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (api_key == "") {
    cat("⚠ 未設置 OPENAI_API_KEY 環境變數\n")
    cat("  請設置 API 金鑰以測試 GPT 整合\n")
    return(FALSE)
  }
  
  # Test GPT interaction
  tryCatch({
    sample_data <- list(
      sales_data = data.frame(
        date = as.Date("2024-01-01"),
        revenue = 25000,
        units = 500
      ),
      dna_analysis = data.frame(
        customer_id = 1,
        segment = "High",
        score = 85
      ),
      other_results = list(
        total_revenue = 25000,
        avg_score = 85
      )
    )
    
    result <- generate_latex_from_gpt(sample_data, api_key)
    cat("✓ GPT 整合測試成功\n")
    cat("   - LaTeX 代碼長度: ", nchar(result$latex_code), " 字符\n")
    return(TRUE)
  }, error = function(e) {
    cat("✗ GPT 整合測試失敗: ", e$message, "\n")
    return(FALSE)
  })
}

# =============================================================================
# Main Test Execution
# =============================================================================

cat("=== LaTeX 報告模組快速測試 (Windows 修復版) ===\n\n")

# Test 1: Data Collection
data_test <- test_data_collection()

# Test 2: Compiler Availability
compiler_test <- test_compiler_availability()

# Test 3: LaTeX Compilation
if (compiler_test$pdflatex || compiler_test$xelatex) {
  compilation_test <- test_latex_compilation(compiler_test)
} else {
  cat("\n⚠ 跳過編譯測試 (無可用編譯器)\n")
  compilation_test <- NULL
}

# Test 4: GPT Integration
gpt_test <- test_gpt_integration()

# =============================================================================
# Summary
# =============================================================================

cat("\n=== 測試總結 ===\n")
cat("數據收集: ", ifelse(data_test, "✓", "✗"), "\n")
cat("編譯器可用性: ", ifelse(compiler_test$pdflatex || compiler_test$xelatex, "✓", "✗"), "\n")
cat("GPT 整合: ", ifelse(gpt_test, "✓", "✗"), "\n")

if (!is.null(compilation_test)) {
  cat("編譯測試結果:\n")
  for (test_name in names(compilation_test)) {
    result <- compilation_test[[test_name]]
    cat("  - ", test_name, ": ", ifelse(result$success, "✓", "✗"), "\n")
  }
}

cat("\n=== 建議 ===\n")
if (!data_test) {
  cat("1. 檢查數據收集函數\n")
}
if (!compiler_test$pdflatex && !compiler_test$xelatex) {
  cat("2. 安裝 LaTeX 編譯器 (MiKTeX 或 TeX Live)\n")
}
if (!is.null(compilation_test) && !any(sapply(compilation_test, function(x) x$success))) {
  cat("3. 檢查 LaTeX 套件安裝:\n")
  cat("   - 安裝 CJKutf8 套件\n")
  cat("   - 安裝 ctex 套件\n")
  cat("   - 檢查 MiKTeX 設置\n")
}
if (!gpt_test) {
  cat("4. 設置 OpenAI API 金鑰\n")
}

cat("\n測試完成！\n") 