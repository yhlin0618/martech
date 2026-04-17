# ============================================================================
# InsightForge 資料庫測試
# ============================================================================

# 載入必要模組
source("config/packages.R")
source("config/config.R")

# 初始化環境
initialize_packages(install_missing = FALSE)
validate_config()

# 載入資料庫模組
source("database/db_connection.R")

# ── 測試函數 ──────────────────────────────────────────────────────────────
test_database <- function() {
  cat("🧪 開始資料庫測試\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  # 1. 測試資料庫配置
  cat("⚙️ 檢查資料庫配置...\n")
  config_result <- check_db_config()
  cat(config_result$message, "\n")
  
  if (!config_result$success) {
    return(FALSE)
  }
  
  # 2. 測試資料庫連接
  cat("\n🔗 測試資料庫連接...\n")
  connection_result <- test_db_connection()
  cat(connection_result$message, "\n")
  
  if (connection_result$success) {
    cat("📋 找到的表格:", paste(connection_result$tables, collapse = ", "), "\n")
  }
  
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  if (connection_result$success) {
    cat("🎉 資料庫測試完全通過！\n")
    return(TRUE)
  } else {
    cat("⚠️ 資料庫測試失敗\n")
    cat("\n💡 建議檢查:\n")
    cat("  1. PostgreSQL 服務是否正在運行\n")
    cat("  2. 網路連接是否正常\n") 
    cat("  3. 資料庫憑證是否正確\n")
    cat("  4. 防火牆設定是否允許連接\n")
    return(FALSE)
  }
}

# 執行測試
if (!interactive()) {
  test_database()
} 