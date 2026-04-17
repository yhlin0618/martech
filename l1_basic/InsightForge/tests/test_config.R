# ============================================================================
# InsightForge 配置測試
# ============================================================================

# 載入配置
source(proj_path("config","packages.R"))
source(proj_path("config","config.R"))

# 測試套件載入
test_packages <- function() {
  cat("🧪 測試套件載入...\n")
  
  tryCatch({
    load_packages()
    cat("✅ 套件載入測試通過\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ 套件載入失敗:", e$message, "\n")
    return(FALSE)
  })
}

# 測試配置讀取
test_config <- function() {
  cat("🧪 測試配置讀取...\n")
  
  # 測試基本配置讀取
  app_name <- get_config("app_name")
  if (is.null(app_name) || app_name != "InsightForge") {
    cat("❌ 應用程式名稱配置錯誤\n")
    return(FALSE)
  }
  
  # 測試巢狀配置讀取
  db_host <- get_config("db.host")
  if (is.null(db_host)) {
    cat("❌ 資料庫主機配置錯誤\n")
    return(FALSE)
  }
  
  cat("✅ 配置讀取測試通過\n")
  return(TRUE)
}

# 測試環境變數
test_env_vars <- function() {
  cat("🧪 測試環境變數...\n")
  
  required_vars <- c("PGHOST", "PGUSER", "PGPASSWORD", "PGDATABASE", "OPENAI_API_KEY")
  missing_vars <- required_vars[!nzchar(Sys.getenv(required_vars))]
  
  if (length(missing_vars) > 0) {
    cat("❌ 缺少環境變數:", paste(missing_vars, collapse = ", "), "\n")
    return(FALSE)
  }
  
  cat("✅ 環境變數測試通過\n")
  return(TRUE)
}

# 執行所有測試
run_all_tests <- function() {
  cat("🚀 開始執行 InsightForge 配置測試\n")
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  tests <- list(
    "套件載入" = test_packages,
    "配置讀取" = test_config,
    "環境變數" = test_env_vars
  )
  
  results <- sapply(tests, function(test) test())
  
  cat(paste(rep("=", 50), collapse = ""), "\n")
  
  if (all(results)) {
    cat("🎉 所有測試通過！系統配置正常\n")
  } else {
    failed_tests <- names(results)[!results]
    cat("⚠️  有", length(failed_tests), "個測試失敗:", paste(failed_tests, collapse = ", "), "\n")
  }
  
  return(all(results))
}

# 如果直接執行此檔案，則運行測試
if (interactive() == FALSE) {
  run_all_tests()
} 