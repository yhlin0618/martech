# =============================================================
# app.R - Application Entry Point
# =============================================================

# 載入 Supabase PostgreSQL 連線所需的套件
# (必須在此明確載入，以確保 rsconnect 將其包含在 manifest.json 中)
library(RPostgres)

# 載入 .Rprofile 以確保 autoinit() 函數可用
if (file.exists(".Rprofile")) {
  source(".Rprofile")
}

# 讀取設定
if (!requireNamespace("yaml", quietly = TRUE)) {
  stop("Please install the 'yaml' package")
}

config <- yaml::read_yaml("app_config.yaml")
main_file <- config$deployment$main_file

if (!file.exists(main_file)) {
  stop("Cannot find main_file: ", main_file)
}

# Save project root so union files can restore it after shiny::runApp() changes wd
Sys.setenv(PROJECT_ROOT = normalizePath(getwd()))

# Ensure tags resolves to htmltools in runApp/Connect envs.
# Avoids masked `tags` objects breaking tags$head usage in UI scripts.
if (!exists("tags", envir = .GlobalEnv, inherits = FALSE) ||
    is.function(get("tags", envir = .GlobalEnv, inherits = FALSE))) {
  assign("tags", htmltools::tags, envir = .GlobalEnv)
}

# Force APP_MODE so autoinit loads app configs (df_platform, etc.).
if (!exists("OPERATION_MODE", envir = .GlobalEnv, inherits = FALSE)) {
  assign("OPERATION_MODE", "APP_MODE", envir = .GlobalEnv)
}

# 判斷部署環境 ---------------------------------------------------
on_connect <- identical(Sys.getenv("RSTUDIO_PRODUCT"), "CONNECT") ||
  nzchar(Sys.getenv("RSTUDIO_CONNECT_VERSION")) ||
  nzchar(Sys.getenv("CONNECT_SERVER")) ||
  !interactive()  # 非互動多半是 CI / Connect

# 啟動 ----------------------------------------------------------
if (on_connect) {
  # 在 Posit Connect 直接 source() 並回傳 shiny.appobj
  app <- source(main_file, local = FALSE)$value
  app  # 最終表達式回傳給 Posit Connect
} else {
  # 本機開發：使用 runApp() 跑整個專案目錄，方便熱重載
  library(shiny)
  shiny::runApp(main_file, launch.browser = TRUE)
}
