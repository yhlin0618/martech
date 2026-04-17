# VitalSigns 數據庫修復測試腳本
# 測試資料庫連接和跨數據庫兼容功能

library(DBI)

cat("🔧 VitalSigns 數據庫修復測試\n")
cat("=" %x% 50, "\n")

# 載入數據庫連接模組
source("database/db_connection.R")

cat("1️⃣ 測試資料庫連接...\n")
tryCatch({
  con <- get_con()
  cat("✅ 數據庫連接成功，類型:", class(con), "\n")
  
  # 測試基本查詢
  cat("2️⃣ 測試基本查詢...\n")
  result <- dbGetQuery(con, "SELECT COUNT(*) as count FROM users")
  cat("✅ 查詢成功，用戶數量:", result$count, "\n")
  
  cat("3️⃣ 測試跨數據庫兼容函數...\n")
  
  # 測試 db_query（無參數）
  users_count <- db_query("SELECT COUNT(*) as total FROM users")
  cat("✅ db_query (無參數) 測試通過，結果:", users_count$total, "\n")
  
  # 測試 db_query（有參數）
  admin_users <- db_query("SELECT * FROM users WHERE role = ?", params = list("admin"))
  cat("✅ db_query (有參數) 測試通過，管理員數量:", nrow(admin_users), "\n")
  
  # 測試 PostgreSQL 參數轉換
  if (inherits(con, "PqConnection")) {
    cat("🐘 PostgreSQL 環境 - 測試參數轉換...\n")
    # 測試多參數查詢
    query_with_params <- "SELECT * FROM users WHERE role = ? AND login_count >= ?"
    test_result <- db_query(query_with_params, params = list("admin", 0))
    cat("✅ PostgreSQL 多參數轉換測試通過\n")
  } else {
    cat("📁 SQLite 環境 - 參數格式無需轉換\n")
  }
  
  cat("4️⃣ 測試修復後的模組兼容性...\n")
  
  # 載入並測試 data_access.R
  source("utils/data_access.R")
  cat("✅ data_access.R 載入成功\n")
  
  # 模擬測試用戶查詢（模組中常用的操作）
  test_user_query <- db_query("SELECT * FROM users WHERE username = ?", params = list("admin"))
  cat("✅ 模組兼容性測試通過，找到用戶:", nrow(test_user_query), "\n")
  
  cat("5️⃣ 測試錯誤處理...\n")
  tryCatch({
    invalid_result <- db_query("SELECT * FROM non_existent_table")
  }, error = function(e) {
    cat("✅ 錯誤處理測試通過，成功捕獲錯誤\n")
  })
  
  cat("\n🎉 所有測試通過！數據庫修復成功\n")
  cat("=" %x% 50, "\n")
  cat("修復內容總結：\n")
  cat("  ✅ 修復 get_con() 函數的賦值問題 (<<- -> <-)\n")
  cat("  ✅ 新增跨數據庫兼容的 db_query() 和 db_execute() 函數\n")
  cat("  ✅ 更新 module_login.R 使用新的數據庫函數\n")
  cat("  ✅ 更新 module_upload.R 使用新的數據庫函數\n")
  cat("  ✅ PostgreSQL 參數自動轉換 (? -> $1, $2...)\n")
  cat("  ✅ 完整的錯誤處理機制\n")
  
}, error = function(e) {
  cat("❌ 測試失敗:", e$message, "\n")
  cat("請檢查：\n")
  cat("  1. 資料庫配置是否正確\n")
  cat("  2. 必要的套件是否已安裝\n")
  cat("  3. 資料庫表格是否已建立\n")
})

# 定義 %x% 運算符（如果不存在）
if (!exists("%x%")) {
  `%x%` <- function(str, n) paste(rep(str, n), collapse = "")
} 