###############################################################################
# BrandEdge Brand Imprint Engine - 品牌印記引擎                               #
# 版本: v2.0 (bs4Dash)                                                        #
# 基於 VitalSigns 外觀設計                                                     #
# 更新: 2025-06-28                                                            #
###############################################################################

# ── 系統初始化 ──────────────────────────────────────────────────────────────
# 載入套件（抑制啟動訊息以避免衝突警告）
suppressPackageStartupMessages({
  library(shiny)
  library(shinyjs)
  library(DBI)
  library(RSQLite)
  library(RPostgres)
  library(RMariaDB)
  library(bcrypt)
  library(readxl)
  library(jsonlite)
  library(httr)
  library(DT)
  library(dplyr)
  library(GGally)
  library(tidyverse)
  library(stringr)
  library(bslib)
  library(bs4Dash)
  library(dotenv)
  library(plotly)
  library(duckdb)
  library(httr2)
  library(future)
  library(furrr)
  library(markdown)
  library(shinycssloaders)
  library(tibble)
})

# 修復並行處理設定
if (Sys.getenv("SHINY_PORT") != "") {
  plan(sequential)
} else {
  plan(multisession, workers = min(2, parallel::detectCores() - 1))
}
options(future.rng.onMisuse = "ignore")

# 條件式載入 .env 檔案（僅在檔案存在時）
if (file.exists(".env")) {
  dotenv::load_dot_env(file = ".env")
}

# 明確使用 shinyjs 函數避免衝突
show <- shinyjs::show
hide <- shinyjs::hide
filter <- dplyr::filter
lag <- dplyr::lag
validate <- shiny::validate

# 定義 null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# ── 全域 CSS 樣式 ────────────────────────────────────────────────────────
css_deps <- tags$head(tags$style(HTML("
  /* 確保 DataTables 的滾動條始終顯示 */
  .dataTables_scrollBody { overflow-x: scroll !important; }
  .dataTables_scrollBody::-webkit-scrollbar { -webkit-appearance: none; }
  .dataTables_scrollBody::-webkit-scrollbar:horizontal { height: 10px; }
  .dataTables_scrollBody::-webkit-scrollbar-thumb { border-radius: 5px; background-color: rgba(0,0,0,.3); }
  .dataTables_scrollBody::-webkit-scrollbar-track { background-color: rgba(0,0,0,.1); border-radius: 5px; }
  
  /* 登入頁面樣式 */
  .login-container { 
    max-width: 400px; 
    margin: 2rem auto; 
    padding: 2rem;
    background: white;
    border-radius: 10px;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
  }
  .login-icon { text-align: center; margin-bottom: 2rem; }
  
  /* 步驟指示器 */
  .step-indicator {
    display: flex;
    justify-content: space-between;
    margin-bottom: 2rem;
    padding: 1rem;
    background: #f8f9fa;
    border-radius: 8px;
  }
  .step-item {
    flex: 1;
    text-align: center;
    padding: 0.5rem;
    border-radius: 5px;
    transition: all 0.3s;
    font-size: 0.9rem;
  }
  .step-item.active {
    background: #007bff;
    color: white;
  }
  .step-item.completed {
    background: #28a745;
    color: white;
  }
  
  /* 歡迎訊息樣式 */
  .welcome-banner {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 1.5rem;
    border-radius: 10px;
    margin-bottom: 2rem;
    text-align: center;
  }
")))

# ── 資料庫連接 ────────────────────────────────────────────────────────────
get_con <- function() {
  con <- dbConnect(
    Postgres(),
    host     = Sys.getenv("PGHOST"),
    port     = as.integer(Sys.getenv("PGPORT", 5432)),
    user     = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    dbname   = Sys.getenv("PGDATABASE"),
    sslmode  = Sys.getenv("PGSSLMODE", "require")
  )
  
  # 建立必要的資料表
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS users (
      id           SERIAL PRIMARY KEY,
      username     TEXT UNIQUE,
      hash         TEXT,
      role         TEXT DEFAULT 'user',
      login_count  INTEGER DEFAULT 0
    );
  ")
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS rawdata (
      id           SERIAL PRIMARY KEY,
      user_id      INTEGER REFERENCES users(id),
      uploaded_at  TIMESTAMPTZ DEFAULT now(),
      json         JSONB
    );
  ")
  
  dbExecute(con, "
    CREATE TABLE IF NOT EXISTS processed_data (
      id            SERIAL PRIMARY KEY,
      user_id       INTEGER REFERENCES users(id),
      processed_at  TIMESTAMPTZ DEFAULT now(),
      json          JSONB
    );
  ")
  
  con
}

# ── 資料庫資訊函數 ────────────────────────────────────────────────────────
get_db_info <- function(con) {
  tryCatch({
    # 檢查連接是否有效
    dbGetQuery(con, "SELECT 1")
    
    # 獲取資料庫類型
    if (inherits(con, "PostgreSQLConnection")) {
      type <- "PostgreSQL"
      icon <- "🐘"
      color <- "#336791"
    } else if (inherits(con, "SQLiteConnection")) {
      type <- "SQLite"
      icon <- "📁"
      color <- "#003B57"
    } else {
      type <- "Unknown"
      icon <- "🔗"
      color <- "#666666"
    }
    
    return(list(
      type = type,
      icon = icon,
      color = color,
      status = "已連接"
    ))
  }, error = function(e) {
    return(list(
      type = "Error",
      icon = "❌",
      color = "#dc3545",
      status = "連接失敗"
    ))
  })
}

# ── 資源路徑設定 ──────────────────────────────────────────────────────────
# 設定 global_scripts 資源路徑
addResourcePath("assets", "scripts/global_scripts/24_assets")

# 解決 www/icons 衝突警告
if (dir.exists("www/icons")) {
  # 使用不衝突的名稱以避免警告
  if ("icons" %in% names(shiny:::resourcePaths())) {
    shiny:::removeResourcePath("icons")
  }
  addResourcePath("app_icons", "www/icons")
}

# ── 載入模組 ────────────────────────────────────────────────────────────────
source("module_wo_b.R")

# ── API 函數 ──────────────────────────────────────────────────────────────
chat_api <- function(messages, max_retries = 5, retry_delay = 5, use_mock = FALSE) {
  # 如果使用模擬模式，直接返回模擬屬性
  if (use_mock) {
    return("品質優良,價格實惠,使用方便,外觀美觀,功能豐富,服務良好,耐用性高,安裝簡單,效能卓越,設計精巧")
  }
  
  # 檢查 API key 是否存在
  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (is.null(api_key) || api_key == "") {
    stop("OPENAI_API_KEY 環境變數未設定。請檢查 .env 文件。")
  }
  
  body <- list(
    model = "gpt-4o-mini",
    messages = messages,
    temperature = 0.7,
    max_tokens = 500
  )
  
  for (attempt in 1:max_retries) {
    tryCatch({
      resp <- POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers("Authorization" = paste("Bearer", api_key)),
        body = body,
        encode = "json"
      )
      
      status <- status_code(resp)
      
      if (status == 200) {
        result <- content(resp, "parsed")
        return(result$choices[[1]]$message$content)
      } else if (status == 429) {
        # 從響應頭中獲取重試建議時間
        retry_after <- as.numeric(headers(resp)$`retry-after` %||% retry_delay)
        wait_time <- min(retry_after * (2^(attempt-1)), 300)  # 最多等待5分鐘
        
        if (attempt < max_retries) {
          cat("⚠️ API 速率限制 (", attempt, "/", max_retries, ")，等待", wait_time, "秒後重試...\n")
          cat("💡 建議：考慮升級 API 計劃以獲得更高的速率限制\n")
          Sys.sleep(wait_time)
          next
        } else {
          stop("❌ API 速率限制，已達到最大重試次數。\n解決方案：\n1. 等待幾分鐘後再試\n2. 升級 OpenAI API 計劃\n3. 使用模擬模式測試功能")
        }
      } else if (status == 401) {
        stop("❌ API 金鑰無效。請檢查 .env 文件中的 OPENAI_API_KEY 設定。")
      } else if (status == 403) {
        stop("❌ API 訪問被拒絕。請檢查 API 金鑰權限或帳戶狀態。")
      } else {
        error_content <- content(resp, "parsed")
        error_msg <- error_content$error$message %||% paste("未知錯誤，狀態碼:", status)
        stop(paste("❌ API 錯誤:", error_msg))
      }
    }, error = function(e) {
      if (attempt < max_retries && grepl("429|rate|limit", e$message, ignore.case = TRUE)) {
        wait_time <- min(retry_delay * (2^(attempt-1)), 300)
        cat("⚠️ 遇到速率限制 (", attempt, "/", max_retries, ")，等待", wait_time, "秒後重試...\n")
        Sys.sleep(wait_time)
        next
      } else {
        stop(e$message)
      }
    })
  }
}

# ── 輔助函數 ──────────────────────────────────────────────────────────────
strip_code_fence <- function(text) {
  # 移除 markdown 代碼塊標記
  text <- gsub("```[a-zA-Z]*\\n", "", text)
  text <- gsub("\\n```", "", text)
  text <- gsub("```", "", text)
  return(text)
}

# 驗證屬性是否有效
validate_attributes <- function(attrs) {
  if (is.null(attrs) || length(attrs) == 0) return(FALSE)
  
  # 檢查是否包含錯誤信息
  error_patterns <- c("API", "error", "Error", "fail", "failed", "429", "limit", "rate")
  has_errors <- any(sapply(error_patterns, function(p) any(grepl(p, attrs, ignore.case = TRUE))))
  
  if (has_errors) return(FALSE)
  
  # 檢查屬性長度和內容
  valid_attrs <- attrs[nchar(attrs) > 1 & nchar(attrs) < 50]  # 1-50字元
  valid_attrs <- valid_attrs[!grepl("^[0-9\\s\\.,，：:]+$", valid_attrs)]  # 不全是數字和標點
  
  return(length(valid_attrs) >= 3)
}

# ── 反應式變數 ──────────────────────────────────────────────────────────────
facets_rv <- reactiveVal(NULL)
progress_info <- reactiveVal(list(start=NULL, done=0, total=0))

safe_value <- function(txt) {
  txt <- trimws(txt)
  num <- str_extract(txt, "[1-5]")
  if (!is.na(num)) return(as.numeric(num))
  val <- suppressWarnings(as.numeric(txt))
  if (!is.na(val) && val >= 1 && val <= 5) return(val)
  NA_real_
}

# ── 登入介面 UI ────────────────────────────────────────────────────────────
login_ui <- div(
  class = "login-container",
  div(class = "login-icon", style = "text-align: center; margin-bottom: 2rem;",
      tags$img(
        src = "assets/icons/app_icon.png",
        style = "height: 80px; width: 80px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"
      )
  ),
  h3("🔐 品牌印記引擎", style = "text-align: center; margin-bottom: 2rem;"),
  h4("使用者登入", style = "text-align: center;"),
  textInput("login_user", "帳號"),
  passwordInput("login_pw", "密碼"),
  div(style = "text-align: center;",
      actionButton("login_btn", "登入", class = "btn-primary btn-block", style = "margin-bottom: 1rem;"),
      actionLink("to_register", "沒有帳號？點此註冊")
  ),
  verbatimTextOutput("login_msg"),
  includeMarkdown("md/contacts.md")
)

register_ui <- hidden(
  div(
    class = "login-container",
    div(class = "login-icon", style = "text-align: center; margin-bottom: 2rem;",
        tags$img(
          src = "assets/icons/app_icon.png",
          style = "height: 80px; width: 80px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1);"
        )
    ),
    h3("📝 註冊新帳號", style = "text-align: center;"),
    textInput("reg_user", "帳號"),
    passwordInput("reg_pw", "密碼"),
    passwordInput("reg_pw2", "確認密碼"),
    div(style = "text-align: center;",
        actionButton("register_btn", "註冊", class = "btn-success btn-block", style = "margin-bottom: 1rem;"),
        actionLink("to_login", "已有帳號？回登入")
    ),
    verbatimTextOutput("register_msg"),
    includeMarkdown("md/contacts.md")
  )
)

# ── 主要應用 UI (bs4Dash) ───────────────────────────────────────────────
main_app_ui <- bs4DashPage(
  title = "品牌印記引擎",
  fullscreen = TRUE,
  
  # 頁首
  header = bs4DashNavbar(
    title = bs4DashBrand(
      title = "品牌印記引擎",
      color = "primary",
      image = "assets/icons/app_icon.png"
    ),
    skin = "light",
    status = "primary",
    fixed = TRUE,
    rightUi = tagList(
      uiOutput("db_status"),
      uiOutput("user_menu")
    )
  ),
  
  # 側邊欄
  sidebar = bs4DashSidebar(
    status = "primary",
    width = "280px",
    elevation = 3,
    minified = FALSE,
    
    # 歡迎訊息
    div(class = "welcome-banner",
        h5("🎯 歡迎使用品牌印記引擎！", style = "margin: 0;"),
        textOutput("welcome_user", inline = TRUE)
    ),
    
    # 步驟指示器
    div(class = "step-indicator",
        div(class = "step-item", id = "step_1", "1. 上傳評論"),
        div(class = "step-item", id = "step_2", "2. 屬性評分"),
        div(class = "step-item", id = "step_3", "3. 印記分析")
    ),
    
    # 選單
    sidebarMenu(
      id = "sidebar_menu",
      bs4SidebarHeader("分析流程"),
      bs4SidebarMenuItem(
        text = "資料上傳",
        tabName = "upload",
        icon = icon("upload")
      ),
      bs4SidebarMenuItem(
        text = "屬性評分",
        tabName = "scoring",
        icon = icon("star")
      ),
      bs4SidebarMenuItem(
        text = "印記分析",
        tabName = "analysis",
        icon = icon("chart-line")
      ),
      bs4SidebarHeader("平台資訊"),
      bs4SidebarMenuItem(
        text = "關於我們",
        tabName = "about",
        icon = icon("info-circle")
      )
    ),
    
    # 登出按鈕
    div(style = "position: absolute; bottom: 20px; width: calc(100% - 40px);",
        actionButton("logout", "登出", class = "btn-secondary btn-block", icon = icon("sign-out-alt"))
    )
  ),
  
  # 主要內容
  body = bs4DashBody(
    css_deps,
    useShinyjs(),
    
    bs4TabItems(
      # 資料上傳頁面
      bs4TabItem(
        tabName = "upload",
        fluidRow(
          bs4Card(
            title = "步驟 1：上傳評論 Excel",
            status = "primary",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            includeMarkdown("md/notification.md"),
            fileInput("excel", "選擇 Excel (需含 Variation/Title/Body)", 
                     accept = c(".xlsx", ".xls", ".csv")),
            actionButton("load_btn", "上傳並預覽", class = "btn-success"),
            hr(),
            verbatimTextOutput("step1_msg"),
            DTOutput("preview_tbl"),
            hr(),
            actionButton("to_step2", "下一步 ➡️", class = "btn-info"),
            includeMarkdown("md/contacts.md")
          )
        )
      ),
      
      # 屬性評分頁面
      bs4TabItem(
        tabName = "scoring",
        fluidRow(
          bs4Card(
            title = "步驟 2：產生屬性並評分",
            status = "warning",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            
            # 產生屬性區塊
            bs4Card(
              title = "1. 產生 10 個屬性",
              status = "secondary",
              width = 12,
                       actionButton("gen_facets", "產生 10 個屬性", class = "btn-secondary"),
              verbatimTextOutput("facet_msg")
            ),
            
            # 選擇評論數量
            bs4Card(
              title = "2. 選擇要分析的顧客評論則數",
              status = "info",
              width = 12,
              sliderInput("nrows", "取前幾列 (評分)", min = 1, max = 100, value = 50, step = 1, ticks = FALSE)
            ),
            
            # 開始評分
            bs4Card(
              title = "3. 開始評分",
              status = "success",
              width = 12,
              shinyjs::disabled(actionButton("score", "開始評分", class = "btn-primary")),
              hr(),
              DTOutput("score_tbl"),
              hr(),
                       shinyjs::disabled(actionButton("to_step3", "下一步 ➡️", class = "btn-info")),
              includeMarkdown("md/contacts.md")
            )
          )
        )
      ),
      
      # 定位分析頁面
      bs4TabItem(
        tabName = "analysis",
        fluidRow(
          bs4Card(
            title = "步驟 3：品牌印記分析結果",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
                       
                       tabsetPanel(
              tabPanel("原始資料", 
                       DTOutput("pairs_rawtbl"),
                       includeMarkdown("md/rawdata_info.md")
              ),
              tabPanel("品牌分數", 
                       DTOutput("brand_mean"),
                       br(), br(),
                       includeMarkdown("md/brandscore_info.md"),
                       br(), br(),
                                  actionButton("refresh", "分析報告"), 
                       br(), br(),
                                  withSpinner(
                                    htmlOutput("brand_ideal_summary"),
                         type = 6,
                         color = "#0d6efd"
                       )
              ),
              tabPanel("品牌DNA", 
                       dnaModuleUI("dna1"),
                       includeMarkdown("md/DNA_info.md")
              ),
              tabPanel("關鍵因素與理想點分數", 
                       idealModuleUI("ideal1"),
                       br(), br(),
                                  includeMarkdown("md/keyfactor_info.md")
              ),
              tabPanel("品牌印記策略建議", 
                       strategyModuleUI("strat1")
              ),
              tabPanel("更多資訊",
                       mainPanel(includeMarkdown("md/about.md"))
                       )
            ),
            
            hr(),
            actionButton("back_step2", "⬅️ 回上一步", class = "btn-secondary")
          )
        )
      ),
      
      # 關於頁面
      bs4TabItem(
        tabName = "about",
        fluidRow(
          bs4Card(
            title = "關於品牌印記引擎",
            status = "info",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            includeMarkdown("md/about.md")
          )
        )
      )
    )
  ),
  
  # 頁尾
  footer = bs4DashFooter(
    fixed = TRUE,
    left = "品牌印記引擎 v2.0",
    right = "© 2024 All Rights Reserved"
  )
)

# ── 主要 UI ──────────────────────────────────────────────────────────────
ui <- fluidPage(
  css_deps,
  useShinyjs(),
  
  # 靜態資源設定
  tags$head(
    tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css")
  ),
  
  # 根據登入狀態顯示不同介面
  conditionalPanel(
    condition = "output.user_logged_in == false",
    div(id = "login_section",
        login_ui,
        register_ui
    )
  ),
  
  conditionalPanel(
    condition = "output.user_logged_in == true",
    main_app_ui
  )
)

# ── Server ──────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  con_global <- get_con()
  db_info <- get_db_info(con_global)  # 取得資料庫連接資訊
  onStop(function() dbDisconnect(con_global))
  
  user_info <- reactiveVal(NULL)
  working_data <- reactiveVal(NULL)
  
  # 登入狀態輸出
  output$user_logged_in <- reactive({
    !is.null(user_info())
  })
  outputOptions(output, "user_logged_in", suspendWhenHidden = FALSE)
  
  # 歡迎訊息
  output$welcome_user <- renderText({
    if (!is.null(user_info())) {
      sprintf("%s (%s)", user_info()$username, user_info()$role)
    } else {
      ""
    }
  })
  
  # 用戶選單
  output$user_menu <- renderUI({
    if (!is.null(user_info())) {
      div(
        style = "color: white; padding: 8px;",
        sprintf("👤 %s", user_info()$username)
      )
    }
  })
  
  # 資料庫狀態顯示
  output$db_status <- renderUI({
    div(
      style = sprintf("color: %s; padding: 8px; margin-right: 15px; background: rgba(255,255,255,0.1); border-radius: 5px;", db_info$color),
      span(db_info$icon, style = "margin-right: 5px;"),
      span(db_info$type, style = "font-weight: bold; margin-right: 5px;"),
      span(sprintf("(%s)", db_info$status), style = "font-size: 0.9em; opacity: 0.8;")
    )
  })
  
  # ──── 登入/註冊邏輯 ──────────────────────────────────────────────────
  observeEvent(input$to_register, {
    hide("login_ui")
    show("register_ui")
  })
  
  observeEvent(input$to_login, {
    hide("register_ui")
    show("login_ui")
  })
  
  observeEvent(input$register_btn, {
    req(input$reg_user, input$reg_pw, input$reg_pw2)
    
    if (input$reg_pw != input$reg_pw2) {
      output$register_msg <- renderText("❌ 兩次密碼不一致")
      return()
    }
    
    if (nchar(input$reg_pw) < 6) {
      output$register_msg <- renderText("❌ 密碼至少 6 個字元")
      return()
    }
    
    existing_user <- dbGetQuery(con_global, "SELECT 1 FROM users WHERE username=$1", 
                                params = list(input$reg_user))
    if (nrow(existing_user) > 0) {
      output$register_msg <- renderText("❌ 帳號已存在")
      return()
    }
    
    dbExecute(con_global, 
              "INSERT INTO users (username,hash,role,login_count) VALUES ($1,$2, 'user',0)", 
              params = list(input$reg_user, bcrypt::hashpw(input$reg_pw)))
    
    output$register_msg <- renderText("✅ 註冊成功！請登入")
    updateTextInput(session, "login_user", value = input$reg_user)
    hide("register_ui")
    show("login_ui")
  })
  
  observeEvent(input$login_btn, {
    req(input$login_user, input$login_pw)
    
    row <- dbGetQuery(con_global, "SELECT * FROM users WHERE username=$1", 
                      params = list(input$login_user))
    
    if (nrow(row) == 0) {
      output$login_msg <- renderText("❌ 帳號不存在")
      return()
    }
    
    used <- row$login_count %||% 0
    if (row$role != "admin" && used >= 5) {
      output$login_msg <- renderText("⛔ 已達登入次數上限")
      return()
    }
    
    if (bcrypt::checkpw(input$login_pw, row$hash)) {
      if (row$role != "admin") {
        dbExecute(con_global, "UPDATE users SET login_count=login_count+1 WHERE id=$1", 
                  params = list(row$id))
      }
      user_info(row)
      output$login_msg <- renderText("")
      
      # 自動導航到第一個頁面
      updateTabItems(session, "sidebar_menu", "upload")
      
      # 更新步驟指示器
      runjs("$('.step-item').removeClass('active completed'); $('#step_1').addClass('active');")
      
    } else {
      output$login_msg <- renderText("❌ 帳號或密碼錯誤")
    }
  })
  
  observeEvent(input$logout, {
    user_info(NULL)
    working_data(NULL)
    facets_rv(NULL)
    
    # 清理輸出
    output$preview_tbl <- renderDT(NULL)
    output$score_tbl <- renderDT(NULL)
    output$pairs_rawtbl <- renderDT(NULL)
    output$brand_mean <- renderDT(NULL)
    
    # 重置步驟指示器
    runjs("$('.step-item').removeClass('active completed');")
  })
  
  # ──── 步驟 1：上傳資料 ──────────────────────────────────────────────────
  observeEvent(input$load_btn, {
    req(user_info())
    
    if (is.null(input$excel)) {
      output$step1_msg <- renderText("⚠️ 請先上傳 Excel 檔案")
      return()
    }
    
    ext <- tolower(tools::file_ext(input$excel$name))
    if (!ext %in% c("xlsx", "xls", "csv")) {
      output$step1_msg <- renderText("⚠️ 只能上傳 .xlsx / .xls / .csv")
      return()
    }
    
    # 讀取資料
    if (ext == "csv") {
      dat <- read_csv(input$excel$datapath)
    } else {
      dat <- read_excel(input$excel$datapath)
    }
    
    # 處理欄位名稱大小寫問題
    col_mapping <- list(
      "variation" = "Variation",
      "title" = "Title", 
      "body" = "Body"
    )
    
    for (old_name in names(col_mapping)) {
      new_name <- col_mapping[[old_name]]
      idx <- which(tolower(names(dat)) == old_name)
      if (length(idx) > 0) {
        names(dat)[idx[1]] <- new_name
      }
    }
    
    must <- c("Variation", "Title", "Body")
    if (!all(must %in% names(dat))) {
      output$step1_msg <- renderText("⚠️ 檔案缺少 Variation / Title / Body 欄位")
      return()
    }
    
    # 儲存到資料庫
    dbExecute(con_global, 
              "INSERT INTO rawdata (user_id,uploaded_at,json) VALUES ($1,$2,$3)", 
              params = list(user_info()$id, as.character(Sys.time()), 
                          toJSON(dat, dataframe = "rows", auto_unbox = TRUE)))
    
    working_data(dat)
    output$preview_tbl <- renderDT(dat, options = list(scrollX = TRUE))
    output$step1_msg <- renderText(sprintf("✅ 已上傳並存入 rawdata，共 %d 筆", nrow(dat)))
    
    # 更新步驟指示器
    runjs("$('#step_1').removeClass('active').addClass('completed');")
  })
  
  observeEvent(input$to_step2, {
    req(!is.null(working_data()))
    updateTabItems(session, "sidebar_menu", "scoring")
    runjs("$('#step_2').addClass('active');")
    
    # 重置評分相關狀態
    shinyjs::disable("score")
    shinyjs::disable("to_step3")
    facets_rv(NULL)
    output$facet_msg <- renderText("尚未產生屬性，請先按「產生 10 個屬性」")
  })
  
  # ──── 步驟 2：產生屬性並評分 ────────────────────────────────────────────
  observeEvent(input$gen_facets, {
    dat <- working_data()
    req(nrow(dat) > 0)
    
    if (is.null(dat)) {
      output$facet_msg <- renderText("⚠️ 尚未上傳任何資料")
      return()
    }
    
    withProgress(message = "正在產生屬性...", value = 0, {
      incProgress(0.3, detail = "準備評論資料")
      
      # 取前50筆評論作為樣本
      sample_data <- head(dat, 50)
      sample_txt <- toJSON(sample_data, dataframe = "rows", auto_unbox = TRUE)
      
      incProgress(0.5, detail = "調用AI分析")
    
    sys <- list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。")
    usr <- list(
      role = "user",
      content = paste0(
          "請針對以下各顧客評論中，從產品定位理論中的屬性、功能、利益和用途等特質，探勘出與該產品最重要、且出現次數最高的 10 個正面描述且具體的特質，並依照該特質出現頻率進行排序。",
          "請只回傳10個屬性，每個屬性用逗號分隔，例如：品質優良,價格實惠,使用方便,外觀美觀,功能豐富,服務良好,耐用性高,安裝簡單,效能卓越,設計精巧\n\n評論：\n",
        sample_txt
      )
    )
    
      incProgress(0.8, detail = "解析屬性")
      
      tryCatch({
        # 如果遇到速率限制，自動切換到模擬模式
        use_mock_mode <- FALSE
        txt <- tryCatch({
          chat_api(list(sys, usr), use_mock = use_mock_mode)
        }, error = function(e) {
          if (grepl("速率限制|rate.limit", e$message, ignore.case = TRUE)) {
            showNotification("⚠️ 偵測到 API 速率限制，切換到模擬模式進行測試", type = "warning", duration = 8)
            use_mock_mode <<- TRUE
            chat_api(list(sys, usr), use_mock = TRUE)
          } else {
            stop(e)
          }
        })
        
        cat("API 回應:", txt, "\n")
        
        # 檢查API回應是否有效
        if (is.null(txt) || nchar(txt) < 10 || grepl("error|Error|API", txt, ignore.case = TRUE)) {
          stop("API 回應無效或包含錯誤")
        }
        
        # 更寬鬆的屬性解析邏輯
        clean_txt <- gsub("[{}\\[\\]]", "", txt)
        
        # 用各種分隔符號切分
        attrs <- unlist(strsplit(clean_txt, "[,，、；;\\n\\r]+"))
        attrs <- trimws(attrs)
        attrs <- attrs[attrs != ""]
        attrs <- attrs[!grepl("^\\d+\\.?$", attrs)]  # 移除純數字
        attrs <- unique(attrs)
        
        # 第二次嘗試：用空白分割
        if (length(attrs) < 3) {
          attrs <- unlist(strsplit(clean_txt, "[\\s]+"))
          attrs <- trimws(attrs)
          attrs <- attrs[attrs != ""]
          attrs <- attrs[nchar(attrs) > 1]
          attrs <- unique(attrs)
        }
        
        # 過濾無效屬性
        attrs <- attrs[nchar(attrs) > 1 & nchar(attrs) < 50]
        attrs <- attrs[!grepl("^[0-9\\s\\.,，：:]+$", attrs)]
        attrs <- attrs[!grepl("API|error|fail|429|limit|rate", attrs, ignore.case = TRUE)]
        
        cat("解析出的屬性:", paste(attrs, collapse = " | "), "\n")
        
        # 取前10個
        attrs <- head(attrs, 10)
        
        incProgress(1.0, detail = "完成")
        
        # 使用驗證函數檢查
        if (validate_attributes(attrs)) {
    facets_rv(attrs)
    shinyjs::enable("score")
    output$facet_msg <- renderText(
            sprintf("✅ 已產生 %d 個屬性：%s", length(attrs), paste(attrs, collapse = ", "))
    )
        } else {
          shinyjs::disable("score")
          if (length(attrs) == 0) {
            output$facet_msg <- renderText("⚠️ 無法解析出有效屬性，請檢查API設定或重試")
          } else {
            output$facet_msg <- renderText(
              sprintf("⚠️ 解析出的屬性品質不佳：%s。請重試", paste(attrs, collapse = ", "))
            )
          }
        }
        
      }, error = function(e) {
        shinyjs::disable("score")
        error_msg <- if (grepl("429|rate", e$message, ignore.case = TRUE)) {
          "❌ API 速率限制，請稍後再試"
        } else if (grepl("401|unauthorized", e$message, ignore.case = TRUE)) {
          "❌ API 金鑰無效，請檢查設定"
        } else {
          paste("❌ API 調用失敗：", e$message)
        }
        output$facet_msg <- renderText(error_msg)
      })
    })
  })
  

  
  observeEvent(input$score, {
    shinyjs::disable("score")
    attrs <- facets_rv()
    req(length(attrs) > 0)
    
    df0 <- working_data()
    req(!is.null(df0))
    df <- head(df0, input$nrows)
    total <- nrow(df)
    
    start_time <- Sys.time()
    progress_info(list(start=start_time, done=0, total=total))
    results_list <- vector("list", total)
    
    withProgress(message = "評分中…", value = 0, {
      for (i in seq_len(total)) {
        row <- df[i, ]
        
        # 為每個屬性準備提示
        prompts <- lapply(attrs, function(a) {
          list(
            list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。"),
            list(role = "user", content = sprintf(
              "以下 JSON：%s請只回%s:<1-5或無>",
              toJSON(row[c("Variation","Title","Body")], dataframe = "rows", auto_unbox = TRUE), a
            ))
          )
        })
        
        # 並行或順序處理
        if (Sys.getenv("SHINY_PORT") != "") {
          res_vec <- purrr::map_chr(prompts, function(msgs) {
            out <- try(chat_api(msgs), silent = TRUE)
            if (inherits(out, "try-error")) NA_character_ else out
          })
        } else {
          res_vec <- future_map_chr(prompts, function(msgs) {
            out <- try(chat_api(msgs), silent = TRUE)
            if (inherits(out, "try-error")) NA_character_ else out
          })
        }
        
        # 轉換為數值
        score_vec <- sapply(res_vec, safe_value)
        names(score_vec) <- attrs
        
        # 結合原始資料和評分
        result_row <- c(
          list(
            Variation = row$Variation,
            Title = row$Title,
            Body = row$Body
          ),
          as.list(score_vec)
        )
        results_list[[i]] <- result_row
        
        # 更新進度
        progress_info(list(start=start_time, done=i, total=total))
        incProgress(1/total, detail = sprintf("完成 %d/%d", i, total))
      }
    })
    
    # 轉換為 data.frame
    results_df <- do.call(rbind, lapply(results_list, data.frame, stringsAsFactors = FALSE))
    
    # 儲存評分結果
    dbExecute(con_global,
              "INSERT INTO processed_data (user_id,processed_at,json) VALUES ($1,$2,$3)", 
              params = list(user_info()$id, as.character(Sys.time()), 
                          toJSON(results_df, dataframe = "rows", auto_unbox = TRUE)))
    
    working_data(results_df)
    output$score_tbl <- renderDT(results_df, options = list(scrollX = TRUE))
    shinyjs::enable("to_step3")
    shinyjs::enable("score")
    
    # 更新步驟指示器
    runjs("$('#step_2').removeClass('active').addClass('completed');")
  })
  
  observeEvent(input$to_step3, {
    req(!is.null(working_data()))
    updateTabItems(session, "sidebar_menu", "analysis")
    runjs("$('#step_3').addClass('active');")
    
         # 準備分析資料
     df <- working_data()
     attrs <- facets_rv()
     
     if (!is.null(df) && !is.null(attrs)) {
       # 顯示原始資料
       output$pairs_rawtbl <- renderDT(df, options = list(scrollX = TRUE))
       
       # 顯示品牌平均分數（使用 brand_data reactive）
       output$brand_mean <- renderDT({
         brand_scores <- brand_data()
         if (!is.null(brand_scores)) {
           # 格式化數值欄位
           numeric_cols <- which(sapply(brand_scores, is.numeric))
           
           datatable(brand_scores, rownames = FALSE, options = list(scrollX = TRUE)) %>%
             formatRound(columns = numeric_cols, digits = 3)
         }
       })
     }
  })
  
  observeEvent(input$back_step2, {
    updateTabItems(session, "sidebar_menu", "scoring")
    runjs("$('#step_3').removeClass('active'); $('#step_2').addClass('active');")
  })
  
  # ──── 側邊欄導航邏輯 ──────────────────────────────────────────────────
  observeEvent(input$sidebar_menu, {
    switch(input$sidebar_menu,
           "upload" = {
             runjs("$('.step-item').removeClass('active'); $('#step_1').addClass('active');")
           },
           "scoring" = {
             runjs("$('.step-item').removeClass('active'); $('#step_2').addClass('active');")
           },
           "analysis" = {
             runjs("$('.step-item').removeClass('active'); $('#step_3').addClass('active');")
           }
    )
  })
  
     # ──── 模組伺服器 ──────────────────────────────────────────────────────
   # 準備模組需要的數據
   brand_data <- reactive({
     df <- working_data()
     attrs <- facets_rv()
     
     if (is.null(df) || is.null(attrs)) return(NULL)
     
     # 檢查數據是否包含評分欄位（不僅僅是原始數據）
     basic_cols <- c("Variation", "Title", "Body")
     if (all(names(df) %in% basic_cols)) {
       cat("brand_data: 等待評分完成，目前只有基本欄位\n")
       return(NULL)
     }
     
     # 驗證屬性是否有效
     if (!validate_attributes(attrs)) {
       warning("屬性驗證失敗，無法進行分析")
       return(NULL)
     }
     
     # 創建屬性名稱的可能變體（去除空格、標點符號等）
     clean_attrs <- gsub("[\\s,，。：:；;！!？?]", "", attrs)
     clean_df_names <- gsub("[\\s,，。：:；;！!？?]", "", names(df))
     
     # 嘗試多種匹配方式
     available_attrs <- c()
     
     # 1. 直接匹配
     direct_match <- intersect(attrs, names(df))
     available_attrs <- c(available_attrs, direct_match)
     
     # 2. 清理後匹配
     for (i in seq_along(clean_attrs)) {
       matches <- which(clean_df_names == clean_attrs[i])
       if (length(matches) > 0) {
         available_attrs <- c(available_attrs, names(df)[matches[1]])
       }
     }
     
     # 3. 模糊匹配（包含關係）
     for (attr in attrs) {
       if (!attr %in% available_attrs) {
         partial_matches <- names(df)[grepl(attr, names(df), fixed = TRUE)]
         if (length(partial_matches) > 0) {
           available_attrs <- c(available_attrs, partial_matches[1])
         }
       }
     }
     
     # 去除重複並確保在數據中存在
     available_attrs <- unique(available_attrs)
     available_attrs <- intersect(available_attrs, names(df))
     
     # 進一步篩選：只保留數值型欄位（評分欄位）
     if (length(available_attrs) > 0) {
       numeric_attrs <- c()
       for (attr in available_attrs) {
         if (is.numeric(df[[attr]]) || all(!is.na(suppressWarnings(as.numeric(df[[attr]]))))) {
           numeric_attrs <- c(numeric_attrs, attr)
         }
       }
       available_attrs <- numeric_attrs
     }
     
     if (length(available_attrs) == 0) {
       warning("數據中沒有匹配的數值屬性欄位")
       cat("期望的屬性:", paste(attrs, collapse = ", "), "\n")
       cat("數據欄位:", paste(names(df), collapse = ", "), "\n")
       cat("數值欄位:", paste(names(df)[sapply(df, is.numeric)], collapse = ", "), "\n")
       return(NULL)
     }
     
     cat("成功匹配的屬性:", paste(available_attrs, collapse = ", "), "\n")
     
     # 如果有效屬性少於原始屬性，更新 facets_rv
     if (length(available_attrs) < length(attrs)) {
       cat("更新有效屬性: 從", length(attrs), "個減少到", length(available_attrs), "個\n")
       facets_rv(available_attrs)
     }
     
     # 計算品牌平均分數
     tryCatch({
       brand_scores <- df %>%
         group_by(Variation) %>%
         summarise(across(all_of(available_attrs), ~ mean(.x, na.rm = TRUE)), .groups = "drop")
       
       # 添加理想點（如果不存在）
       if (!"Ideal" %in% brand_scores$Variation) {
         ideal_vals <- brand_scores %>%
           select(all_of(available_attrs)) %>%
           summarise(across(everything(), ~ mean(.x, na.rm = TRUE)))
         
         ideal_row <- tibble(
           Variation = "Ideal",
           !!!ideal_vals
         )
         
         brand_scores <- bind_rows(brand_scores, ideal_row)
       }
       
       return(brand_scores)
       
     }, error = function(e) {
       warning("計算品牌分數時出錯: ", e$message)
       return(NULL)
     })
    })
    
   raw       <- reactive({ 
     req(brand_data())
     brand_data() 
   })
   with_na   <- reactive({ 
     req(raw())
     raw() %>% select(where(~ !all(is.na(.)))) 
   })
   no_na     <- reactive({ 
     req(with_na())
     with_na() %>% select(where(~ !any(is.na(.)))) 
   })
    
    # PCA data: numeric only
   pcaData   <- reactive({ 
     req(no_na())
     no_na() %>% select(where(is.numeric)) 
   })
    
    # Ideal data
   idealFull <- reactive({ 
     req(with_na())
     with_na() 
   })
   idealRaw  <- reactive({ 
     req(idealFull())
     idealFull() %>% filter(Variation != "Ideal") 
   })
    
    # Indicator for Strategy
    indicator <- reactive({
     req(idealFull(), idealRaw())
      # 抓理想点数值
      ideal_vals <- idealFull() %>%
        filter(Variation == "Ideal") %>%
        select(where(is.numeric))
      # 抓其它 Variation 的数值
      df_vals <- idealRaw() %>%
        select(where(is.numeric))
      # 只保留非 sales/rating 的特征
      feature_names <- setdiff(names(df_vals), c("sales", "rating"))
      df_vals <- df_vals[ , feature_names]
      ideal_cmp <- unlist(ideal_vals[1, feature_names])
      mat <- sweep(df_vals, 2, ideal_cmp, FUN = ">") * 1
      ind <- as.data.frame(mat)
      ind$Variation <- idealRaw()$Variation
      ind
    })
    
    
    indicator_eq <- reactive({
     req(idealFull(), idealRaw())
      # 抓理想点数值
      ideal_vals <- idealFull() %>%
        filter(Variation == "Ideal") %>%
        select(where(is.numeric))
      # 抓其它 Variation 的数值
      df_vals <- idealRaw() %>%
        select(where(is.numeric))
      # 只保留非 sales/rating 的特征
      feature_names <- setdiff(names(df_vals), c("sales", "rating"))
      df_vals <- df_vals[ , feature_names]
      ideal_cmp <- unlist(ideal_vals[1, feature_names])
      mat <- sweep(df_vals, 2, ideal_cmp, FUN = ">=") * 1
      ind <- as.data.frame(mat)
      ind$Variation <- idealRaw()$Variation
      ind
    })
    
    
    # key factors for Ideal & Strategy
    keyVars <- reactive({
     req(idealFull())
      ideal_vals <- idealFull() %>% filter(Variation == "Ideal") %>% select(where(is.numeric))
      clean_vals <- ideal_vals %>% select(where(~ !any(is.na(.))))
      names(clean_vals)[ which(unlist(clean_vals[1,]) > mean(unlist(clean_vals[1,]))) ]
    })
    
    # Launch modules, pass indicator and keyVars to both if needed
    # pcaModuleServer("pca1",   pcaData)
   idealModuleServer("ideal1", idealFull, idealRaw, indicator = indicator_eq, key_vars = keyVars)
    strategyModuleServer("strat1", indicator, key_vars = keyVars)
    dnaModuleServer("dna1", raw)
    
     # ──── 分析報告 ──────────────────────────────────────────────────────
   observeEvent(input$refresh, {
     req(brand_data(), facets_rv())
     
     # 生成分析報告
     output$brand_ideal_summary <- renderText({
       brand_scores <- brand_data()
       attrs <- facets_rv()
       
       if (is.null(brand_scores) || is.null(attrs) || !validate_attributes(attrs)) {
         return("<p>無可用數據進行分析</p>")
       }
       
       # 確保屬性存在於數據中
       available_attrs <- intersect(attrs, names(brand_scores))
       if (length(available_attrs) == 0) {
         return("<p>數據中沒有有效的屬性欄位可供分析</p>")
       }
       
       # 排除理想點，找出最高分品牌
       real_brands <- brand_scores %>% filter(Variation != "Ideal")
       
       if (nrow(real_brands) == 0) {
         return("<p>沒有品牌數據可供分析</p>")
       }
       
       top_brand <- real_brands %>%
         rowwise() %>%
         mutate(total_score = sum(c_across(all_of(available_attrs)), na.rm = TRUE)) %>%
         ungroup() %>%
         slice_max(total_score, n = 1)
       
       paste0(
         "<h4>📊 分析摘要</h4>",
         "<p><strong>表現最佳品牌：</strong>", top_brand$Variation, "</p>",
         "<p><strong>總分：</strong>", round(top_brand$total_score, 2), "</p>",
         "<p><strong>分析屬性：</strong>", paste(available_attrs, collapse = ", "), "</p>",
         "<p>詳細分析請查看各個分頁標籤。</p>"
       )
     })
  })
}

# ── 啟動應用 ──────────────────────────────────────────────────────────────
shinyApp(ui = ui, server = server)
