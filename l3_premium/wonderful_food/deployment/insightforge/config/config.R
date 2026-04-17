# ============================================================================
# InsightForge 應用程式配置檔
# ============================================================================

# 載入環境變數（支援本機開發與部署環境）
# Reference: ISSUE-118 (Deployment fix), Per SEC_R002, MP110 (fail-fast for missing credentials)

# Step 1: Try loading from .env file (for local development)
env_file <- file.path(getwd(), ".env")
if (file.exists(env_file)) {
  if (requireNamespace("dotenv", quietly = TRUE)) {
    dotenv::load_dot_env(file = env_file)
    message("✅ Environment variables loaded from .env using dotenv package")
  } else {
    readRenviron(env_file)
    message("✅ Environment variables loaded from .env using readRenviron")
  }
} else {
  # No .env file - assume deployment environment (Posit Connect, etc.)
  message("ℹ️ No .env file found - using environment variables from deployment platform")
}

# Step 2: Verify required variables are available (either from .env OR deployment environment)
required_vars <- c("OPENAI_API_KEY", "PGHOST", "PGPASSWORD")
missing <- required_vars[!nzchar(Sys.getenv(required_vars))]

if (length(missing) > 0) {
  stop(sprintf(
    paste0(
      "❌ Missing required environment variables:\n  - %s\n\n",
      "For local development:\n",
      "1. Copy .env.template to .env\n",
      "2. Fill in all credentials\n",
      "3. Ensure .env is in .gitignore\n\n",
      "For deployment:\n",
      "1. Set environment variables in deployment platform (e.g., Posit Connect)\n",
      "2. Ensure all required variables are configured"
    ),
    paste(missing, collapse = "\n  - ")
  ))
}

# ── 應用程式設定 ──────────────────────────────────────────────────────────
APP_CONFIG <- list(
  # 應用程式基本資訊
  app_name = "InsightForge",
  app_version = "v17",
  app_title = "精準行銷平台",
  
  # 資料庫設定
  db = list(
    host = Sys.getenv("PGHOST"),
    port = as.integer(Sys.getenv("PGPORT", 5432)),
    user = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    dbname = Sys.getenv("PGDATABASE"),
    sslmode = Sys.getenv("PGSSLMODE", "require")
  ),
  
  # AI API 設定
  ai = list(
    api_key = Sys.getenv("OPENAI_API_KEY"),
    api_url = "https://api.openai.com/v1/chat/completions",
    model = "gpt-4o-mini",
    timeout_sec = 60,
    temperature = 0.3,
    max_tokens = 1024
  ),
  
  # 分析設定
  analysis = list(
    default_facets = 6,
    max_rows = 100,
    default_rows = 50,
    score_range = c(1, 5)
  ),
  
  # UI 設定
  ui = list(
    theme = "cerulean",
    font_family = "Noto Sans TC",
    icon_height = "60px",
    spinner_type = 6,
    spinner_color = "#0d6efd"
  ),
  
  # 平行處理設定
  parallel = list(
    max_workers = if (Sys.getenv("SHINY_PORT") != "") 1 else min(2, parallel::detectCores() - 1),
    use_sequential = Sys.getenv("SHINY_PORT") != ""
  )
)

# ── 驗證設定 ──────────────────────────────────────────────────────────────
validate_config <- function() {
  # 檢查 AI API 金鑰（這是必須的）
  if (!nzchar(Sys.getenv("OPENAI_API_KEY"))) {
    cat("⚠️ 警告: 未設定 OPENAI_API_KEY，AI 功能將無法使用\n")
    cat("   請設定環境變數或在 .env 檔案中配置\n")
  }
  
  # 檢查資料庫配置（可選，會自動切換到 SQLite）
  db_vars <- c("PGHOST", "PGUSER", "PGPASSWORD", "PGDATABASE")
  missing_db_vars <- db_vars[!nzchar(Sys.getenv(db_vars))]
  
  if (length(missing_db_vars) > 0) {
    cat("⚠️ PostgreSQL 配置不完整，將使用 SQLite 測試模式\n")
    cat("   缺少環境變數:", paste(missing_db_vars, collapse = ", "), "\n")
  }
  
  cat("✅ 配置檢查通過\n")
  return(TRUE)
}

# ── 輔助函數 ──────────────────────────────────────────────────────────────
get_config <- function(key = NULL) {
  if (is.null(key)) {
    return(APP_CONFIG)
  }
  
  # 支援 dot notation，例如 "db.host"
  keys <- strsplit(key, "\\.")[[1]]
  result <- APP_CONFIG
  
  for (k in keys) {
    if (!k %in% names(result)) {
      return(NULL)
    }
    result <- result[[k]]
  }
  
  return(result)
} 