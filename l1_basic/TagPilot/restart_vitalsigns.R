# VitalSigns 重啟測試腳本
# 測試修復後的PostgreSQL參數轉換

cat("🚀 VitalSigns 重啟測試\n")
cat("=" %x% 50, "\n")

# 先測試參數轉換邏輯
cat("1️⃣ 測試參數轉換修復...\n")
source("test_parameter_conversion.R")

cat("\n2️⃣ 測試表格生成修復...\n")
source("test_table_generation_fix.R")

cat("\n3️⃣ 啟動 VitalSigns 應用...\n")
cat("🌐 訪問地址: http://localhost:3839\n")
cat("🔑 測試賬號: admin / admin123\n") 
cat("🛑 按 Ctrl+C 停止應用\n\n")

# 啟動應用
shiny::runApp(port = 3839, host = "0.0.0.0")

# 定義 %x% 運算符（如果不存在）
if (!exists("%x%")) {
  `%x%` <- function(str, n) paste(rep(str, n), collapse = "")
} 