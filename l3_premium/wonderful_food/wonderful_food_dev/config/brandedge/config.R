# ============================================================================
# BrandEdge 旗艦版配置檔
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
# IMPORTANT: 使用函數來動態讀取環境變數，而非靜態快照
# Reference: ISSUE-119 (Posit Connect variable timing issue)
#
# WHY: APP_CONFIG 在 config.R 載入時建立，如果此時環境變數尚未設定
# （如 Posit Connect 在稍後才注入變數），則會捕獲空值導致連接失敗

get_app_config <- function() {
  # 輔助函數：清理環境變數值（去除空格、引號、換行符等）
  # Reference: ISSUE-119 - Posit Connect 可能在變數值中加入額外字元
  clean_env <- function(var_name, default = "") {
    value <- Sys.getenv(var_name, default)
    # 去除前後空格
    value <- trimws(value)
    # 去除可能的引號（單引號或雙引號）
    value <- gsub('^["\']|["\']$', '', value)
    # 去除換行符
    value <- gsub('[\r\n]+', '', value)
    return(value)
  }

  list(
    # 應用程式基本資訊
    app_name = "BrandEdge",
    app_version = "v3.0",
    app_title = "品牌印記引擎 - 旗艦版",

    # 資料庫設定（動態讀取，確保取得最新的環境變數值）
    db = list(
      host = clean_env("PGHOST"),
      port = as.integer(clean_env("PGPORT", "5432")),
      user = clean_env("PGUSER"),
      password = clean_env("PGPASSWORD"),
      dbname = clean_env("PGDATABASE"),
      sslmode = clean_env("PGSSLMODE", "require")
    ),

    # AI API 設定（動態讀取）
    ai = list(
      api_key = clean_env("OPENAI_API_KEY"),
      api_url = "https://api.openai.com/v1/chat/completions",
      model = "gpt-4o-mini",
      timeout_sec = 60,
      temperature = 0.3,
      max_tokens = 2048
    ),
  
    # 分析設定（旗艦版擴展）
    analysis = list(
      min_attributes = 10,
      max_attributes = 30,
      default_attributes = 15,
      max_reviews = 1000,
      max_brands = 20,
      min_reviews_per_brand = 50,
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
}

# 註解：為了向後兼容，保留 APP_CONFIG 變數
# 但請改用 get_config() 函數來取得配置，以確保取得最新的環境變數值
# Reference: ISSUE-119
APP_CONFIG <- get_app_config()

# ── 驗證設定 ──────────────────────────────────────────────────────────────
validate_config <- function() {
  # 檢查 AI API 金鑰
  if (!nzchar(Sys.getenv("OPENAI_API_KEY"))) {
    cat("⚠️ 警告: 未設定 OPENAI_API_KEY，AI 功能將使用模擬模式\n")
  }
  
  # 檢查資料庫配置
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
  # 每次呼叫都動態生成配置，確保取得最新的環境變數
  # Reference: ISSUE-119 - 修復 Posit Connect 變數注入時機問題
  config <- get_app_config()

  if (is.null(key)) {
    return(config)
  }

  # 支援 dot notation，例如 "db.host"
  keys <- strsplit(key, "\\.")[[1]]
  result <- config

  for (k in keys) {
    if (!k %in% names(result)) {
      return(NULL)
    }
    result <- result[[k]]
  }

  return(result)
}