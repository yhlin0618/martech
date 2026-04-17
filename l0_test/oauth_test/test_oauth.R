# 測試 OAuth 設定的腳本
# 在部署前先測試基本連線

library(httr2)

# 讀取環境變數（請先設定 .env 檔案）
if (file.exists(".env")) {
  dotenv::load_dot_env()
}

ISSUER <- Sys.getenv("OIDC_ISSUER")

# 測試 1: 檢查環境變數
cat("=== 環境變數檢查 ===\n")
cat("OIDC_ISSUER:", ISSUER, "\n")
cat("OIDC_CLIENT_ID:", 
    if(nzchar(Sys.getenv("OIDC_CLIENT_ID"))) "✓ 已設定" else "✗ 未設定", "\n")
cat("OIDC_CLIENT_SECRET:", 
    if(nzchar(Sys.getenv("OIDC_CLIENT_SECRET"))) "✓ 已設定" else "✗ 未設定", "\n")

# 測試 2: 檢查 Discovery Endpoint
if (nzchar(ISSUER)) {
  cat("\n=== Discovery Endpoint 測試 ===\n")
  discovery_url <- paste0(ISSUER, "/.well-known/openid-configuration")
  cat("嘗試連線:", discovery_url, "\n")
  
  tryCatch({
    response <- request(discovery_url) |>
      req_perform()
    
    if (resp_status(response) == 200) {
      cat("✓ 成功連線到 Discovery Endpoint\n")
      
      config <- resp_body_json(response)
      cat("\n找到的端點:\n")
      cat("- Authorization:", config$authorization_endpoint, "\n")
      cat("- Token:", config$token_endpoint, "\n")
      cat("- UserInfo:", config$userinfo_endpoint %||% "無", "\n")
      cat("- JWKS:", config$jwks_uri, "\n")
      
      if (!is.null(config$scopes_supported)) {
        cat("\n支援的 Scopes:\n")
        cat(paste("- ", config$scopes_supported, collapse = "\n"), "\n")
      }
    }
  }, error = function(e) {
    cat("✗ 連線失敗:", e$message, "\n")
    cat("\n可能原因:\n")
    cat("1. OIDC_ISSUER 網址錯誤\n")
    cat("2. WordPress OAuth Server 未正確設定\n")
    cat("3. 網路連線問題\n")
  })
} else {
  cat("\n✗ 請先設定 OIDC_ISSUER 環境變數\n")
}

# 測試 3: Redirect URI 確認
cat("\n=== Redirect URI 設定提醒 ===\n")
cat("請確認 WordPress OAuth Client 的 Redirect URI 設定為:\n")
cat("https://kyleyhl-brandedge.share.connect.posit.cloud/?oidc_cb=1\n")
cat("（必須一字不差，包括 ?oidc_cb=1 參數）\n")