# PostgreSQL 參數轉換測試腳本
# 驗證修復後的參數轉換邏輯

cat("🧪 PostgreSQL 參數轉換測試\n")
cat("=" %x% 40, "\n")

# 定義測試函數（模擬修復後的邏輯）
test_parameter_conversion <- function(query, params = NULL) {
  original_query <- query
  cat("原始查詢: ", original_query, "\n")
  
  # 模擬PostgreSQL參數轉換
  if (!is.null(params) && grepl("\\?", query)) {
    param_count <- 1
    while (grepl("\\?", query)) {
      query <- sub("\\?", paste0("$", param_count), query)
      param_count <- param_count + 1
    }
  }
  
  cat("轉換後查詢: ", query, "\n")
  cat("參數數量: ", length(params), "\n")
  cat("---\n")
  
  return(query)
}

# 測試案例
cat("📋 測試案例:\n\n")

# 測試1: 單一參數
test_parameter_conversion(
  "SELECT * FROM users WHERE username=?", 
  params = list("admin")
)

# 測試2: 多個參數 
test_parameter_conversion(
  "SELECT * FROM users WHERE username=? AND role=?", 
  params = list("admin", "admin")
)

# 測試3: 三個參數
test_parameter_conversion(
  "INSERT INTO users (username, hash, role) VALUES (?, ?, ?)", 
  params = list("test", "hash123", "user")
)

# 測試4: 無參數
test_parameter_conversion(
  "SELECT COUNT(*) FROM users"
)

# 載入修復後的數據庫模組測試
cat("🔧 載入並測試修復後的數據庫模組...\n")
tryCatch({
  source("database/db_connection.R")
  cat("✅ 數據庫模組載入成功\n")
  
  # 測試實際的數據庫連接
  con <- get_con()
  cat("✅ 數據庫連接成功，類型: ", class(con), "\n")
  
  if (inherits(con, "PqConnection")) {
    cat("🐘 PostgreSQL 環境 - 測試實際查詢...\n")
    
    # 測試修復後的 db_query 函數
    result <- db_query("SELECT COUNT(*) as count FROM users WHERE role = ?", 
                       params = list("admin"))
    cat("✅ 修復後查詢測試通過，管理員數量: ", result$count, "\n")
    
  } else {
    cat("📁 SQLite 環境 - 無需參數轉換\n")
  }
  
}, error = function(e) {
  cat("❌ 測試失敗: ", e$message, "\n")
})

cat("\n🎉 參數轉換測試完成！\n")

# 定義 %x% 運算符（如果不存在）
if (!exists("%x%")) {
  `%x%` <- function(str, n) paste(rep(str, n), collapse = "")
} 