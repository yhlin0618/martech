# ==============================================================================
# Supabase Login Test Script
# Purpose: 測試 Supabase 登入功能是否正常
# Date: 2025-01-19
# ==============================================================================

# 載入環境變數
if (file.exists(".env")) {
  if (!requireNamespace("dotenv", quietly = TRUE)) {
    install.packages("dotenv")
  }
  dotenv::load_dot_env(".env")
  message("✅ 已載入 .env 環境變數")
}

# 載入 Supabase 認證模組
source("scripts/global_scripts/10_rshinyapp_components/login/supabase_auth.R")

# 檢查環境變數
config <- get_supabase_config()
cat("\n=== Supabase 設定 ===\n")
cat("URL:", config$url, "\n")
cat("Key 已設定:", nchar(config$anon_key) > 0, "\n")

# 測試連線
cat("\n=== 測試 Supabase 連線 ===\n")
connection_ok <- test_supabase_connection()

if (!connection_ok) {
  stop("❌ Supabase 連線失敗")
}

# 測試登入 (使用 admin 帳號)
cat("\n=== 測試登入功能 ===\n")
cat("測試帳號: admin\n")
cat("測試密碼: 618112\n")

# 測試 1: 驗證密碼
cat("\n--- 測試 authenticate_user() ---\n")
auth_result <- authenticate_user("admin", "618112")
cat("認證結果:\n")
print(auth_result)

if (isTRUE(auth_result$success)) {
  cat("✅ 密碼驗證成功\n")
  cat("  user_id:", auth_result$user_id, "\n")
  cat("  role:", auth_result$role, "\n")

  # 測試 2: 檢查登入限制
  cat("\n--- 測試 check_login_limit() ---\n")
  limit_result <- check_login_limit(auth_result$user_id, "tagpilot")
  cat("登入限制結果:\n")
  print(limit_result)

  if (isTRUE(limit_result$allowed)) {
    cat("✅ 登入限制檢查通過\n")
    if (isTRUE(limit_result$is_admin)) {
      cat("  身份: Admin (無限制)\n")
    } else {
      cat("  剩餘次數:", limit_result$remaining, "\n")
    }
  } else {
    cat("❌ 登入限制超過\n")
  }

  # 測試 3: 完整登入流程
  cat("\n--- 測試 login_user() 完整流程 ---\n")
  login_result <- login_user("admin", "618112", "tagpilot")
  cat("完整登入結果:\n")
  print(login_result)

  if (isTRUE(login_result$success) && isTRUE(login_result$allowed)) {
    cat("\n🎉 所有測試通過！Supabase 登入功能正常運作\n")
  }

} else {
  cat("❌ 密碼驗證失敗:", auth_result$error, "\n")
}

cat("\n=== 測試完成 ===\n")
