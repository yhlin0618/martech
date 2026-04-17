# ============================================================================
# BrandEdge 旗艦版配置檔
# ============================================================================

# 載入環境變數（如果 .env 檔案存在）
if (file.exists(".env")) {
  dotenv::load_dot_env(file = ".env")
  cat("📁 已載入 .env 配置檔\n")
} else if (file.exists("config/.env")) {
  dotenv::load_dot_env(file = "config/.env")
  cat("📁 已載入 config/.env 配置檔\n")
}

# ── 應用程式設定 ──────────────────────────────────────────────────────────
APP_CONFIG <- list(
  # 應用程式基本資訊
  app_name = "BrandEdge",
  app_version = "v3.0",
  app_title = "品牌印記引擎 - 旗艦版",
  
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