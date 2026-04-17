# =============================================================================
# 測試 .env 檔案載入
# =============================================================================

# Load required packages
if (!require(dotenv)) install.packages("dotenv")
library(dotenv)

# 載入 .env 取得 API key
dotenv::load_dot_env(file = ".env")
OPENAI_API_KEY_LIN <- Sys.getenv("OPENAI_API_KEY_LIN")

cat("=== .env 檔案載入測試 ===\n")
cat("API Key 是否存在:", ifelse(OPENAI_API_KEY_LIN != "", "✓", "✗"), "\n")
cat("API Key 長度:", nchar(OPENAI_API_KEY_LIN), "\n")
cat("API Key 前10個字符:", substr(OPENAI_API_KEY_LIN, 1, 10), "\n")

# 測試 module 載入
cat("\n=== Module 載入測試 ===\n")
tryCatch({
  source("modules/module_latex_report.R")
  cat("✓ LaTeX Report Module 載入成功\n")
}, error = function(e) {
  cat("✗ LaTeX Report Module 載入失敗:", e$message, "\n")
})

cat("\n測試完成！\n") 