###############################################################################
# full_app_step_wizard_v4.R – upload‑only, dynamic facets, JSON storage       #
# Updated: 2025‑05‑20                                                         #
###############################################################################

# ── Packages -----------------------------------------------------------------
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
  library(dotenv)
  library(plotly)
  library(duckdb)
  library(httr2)
  library(future)
  library(furrr)
  library(markdown)
  library(shinycssloaders) # withSpinner()
})

# Fix parallel workers for shinyapps.io (limited to 1 CPU)
if (Sys.getenv("SHINY_PORT") != "") {
  # Running on shinyapps.io
  plan(sequential)  # Use sequential processing
} else {
  # Running locally
  plan(multisession, workers = min(2, parallel::detectCores() - 1))
}
options(future.rng.onMisuse = "ignore")  # 關閉隨機種子警告

# 條件式載入 .env 檔案（僅在檔案存在時）
if (file.exists(".env")) {
  dotenv::load_dot_env(file = ".env")
}

# -----------------------------------------------------------------------------
# Explicitly use shinyjs functions to avoid conflicts
show <- shinyjs::show
hide <- shinyjs::hide

# Handle other conflicts
filter <- dplyr::filter
lag <- dplyr::lag
validate <- shiny::validate

# Define null coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x






# LLM_URL   <- Sys.getenv("LLM_URL",   "http://localhost:11434/v1/chat/completions")
# LLM_MODEL <- Sys.getenv("LLM_MODEL", "llama4:latest")

# ── DB helpers ----------------------------------------------------------------

get_con <- function() {
  # ➊ 建立連線
  con <- dbConnect(
    Postgres(),
    host     = Sys.getenv("PGHOST"),
    port     = as.integer(Sys.getenv("PGPORT", 5432)),
    user     = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    dbname   = Sys.getenv("PGDATABASE"),
    sslmode  = Sys.getenv("PGSSLMODE", "require") # DO 版一定要 require
  )
  
  # 儲存連接資訊
  db_info <- list(
    type = "PostgreSQL",
    host = Sys.getenv("PGHOST"),
    port = Sys.getenv("PGPORT", 5432),
    dbname = Sys.getenv("PGDATABASE"),
    icon = "🐘",
    color = "#336791",
    status = "雲端資料庫"
  )
  attr(con, "db_info") <- db_info
  
  # ➋ 建表（若不存在）
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

# ── 取得資料庫連接資訊 ──────────────────────────────────────────────────────
get_db_info <- function(con = NULL) {
  if (is.null(con)) {
    return(list(
      type = "未連接",
      icon = "❌",
      color = "#DC3545",
      status = "未連接"
    ))
  }
  
  db_info <- attr(con, "db_info")
  if (!is.null(db_info)) {
    return(db_info)
  }
  
  # 如果沒有屬性，嘗試判斷類型
  if (inherits(con, "PqConnection")) {
    return(list(
      type = "PostgreSQL",
      icon = "🐘",
      color = "#336791",
      status = "雲端資料庫"
    ))
  } else {
    return(list(
      type = "未知",
      icon = "❓",
      color = "#6C757D",
      status = "未知"
    ))
  }
}

# ── reactive values -----------------------------------------------------------
facets_rv   <- reactiveVal(NULL)  # 目前 LLM 產出的 10 個屬性 (字串向量)
progress_info <- reactiveVal(list(start=NULL, done=0, total=0))
safe_value <- function(txt) {
  txt <- trimws(txt)
  num <- str_extract(txt, "[1-5]")
  if (!is.na(num)) return(as.numeric(num))
  val <- suppressWarnings(as.numeric(txt))
  if (!is.na(val) && val >= 1 && val <= 5) return(val)
  NA_real_
}

# ── bslib theme --------------------------------------------------------------
#app_theme <- bs_theme(version = 5, bootswatch = "minty", primary = "#006699", secondary = "#ffb74d", base_font = font_google("Noto Sans TC"))
app_theme <- bslib::bs_theme(
  preset = "cerulean",
  base_font = font_google("Noto Sans TC", wght = "400", ital = 0, local = FALSE),
  code_font = font_google("Noto Sans TC", wght = "400", ital = 0, local = FALSE),
  heading_font = font_google("Noto Sans TC", wght = "600", ital = 0, local = FALSE)
)

app_theme <- bs_add_rules(app_theme, "\n  #icon_bar { background-color: $gray-100; padding:.5rem 1rem; }\n  #welcome_box { background:$secondary; color:$white; padding:.75rem 1rem; border-radius:.5rem; }\n")

source("module_wo_b.R")
# ── UI -----------------------------------------------------------------------
# ---- Global icon bar --------------------------------------------------------
# 設定圖片資源路徑，使用不會衝突的名稱
if (dir.exists("www/icons")) {
  addResourcePath("app_icons", "www/icons")
  icon_src <- "app_icons/icon.png"
} else {
  icon_src <- "icons/icon.png"  # 備用路徑
}

icon_bar <- div(id = "icon_bar", img(src = icon_src, height = "60px", id = "icon_main"), uiOutput("partner_icons"))

# ---- 登入 / 註冊 ----
login_ui <- div(id = "login_page",img(src = icon_src, height = "300px", id = "icon_main"), h4("🔐 使用者登入"), textInput("login_user", "帳號"), passwordInput("login_pw", "密碼"), actionButton("login_btn", "登入", class = "btn-primary"), br(), actionLink("to_register", "沒有帳號？點此註冊"),includeMarkdown("md/contacts.md"), verbatimTextOutput("login_msg"))

register_ui <- hidden(div(id = "register_page", h2("📝 註冊新帳號"), textInput("reg_user", "帳號"), passwordInput("reg_pw", "密碼"), passwordInput("reg_pw2", "確認密碼"), actionButton("register_btn", "註冊", class = "btn-success"), br(), actionLink("to_login", "已有帳號？回登入"),includeMarkdown("md/contacts.md"), verbatimTextOutput("register_msg")))

# ---- Step 1：上傳資料 -------------------------------------------------------
step1_ui <- div(id = "step1_box", h4("步驟 1：上傳評論 Excel"), includeMarkdown("md/notification.md"),fileInput("excel", "選擇 Excel (需含 Variation/Title/Body)"), br(), actionButton("load_btn", "上傳並預覽", class = "btn-success"), br(), verbatimTextOutput("step1_msg"), DTOutput("preview_tbl"), br(), actionButton("to_step2", "下一步 ➡️", class = "btn-info"),includeMarkdown("md/contacts.md"))

# ---- Step 2：產生屬性並評分 -------------------------------------------------
step2_ui <- hidden(div(id = "step2_box", h4("步驟 2：產生屬性並評分"), 
                       h5("1. 產生6個屬性"),
                       actionButton("gen_facets", "產生 6 個屬性", class = "btn-secondary"),
                       verbatimTextOutput("facet_msg"), br(), 
                       h5("2. 選擇要分析的顧客評論則數"),
                       sliderInput("nrows", "取前幾列 (評分)", min = 1, max = 100, value = 50, step = 1, ticks = FALSE), 
                       h5("3. 請點擊 [開始評分]"),
                       shinyjs::disabled(actionButton("score", "開始評分", class = "btn-primary")), br(), br(),
                       DTOutput("score_tbl"), br(), 
                       shinyjs::disabled(actionButton("to_step3", "下一步 ➡️", class = "btn-info")),
                                         includeMarkdown("md/contacts.md")))

# ---- Step 3：視覺化 ---------------------------------------------------------
# step3_ui <- hidden(div(id = "step3_box", h4("步驟 3：視覺化結果"), tabsetPanel(tabPanel("原始資料", DTOutput("pairs_rawtbl")), 
#                                                                        tabPanel("散布矩陣", plotOutput("pairs_plot", height = 600)), 
#                                                                        tabPanel("摘要統計", tableOutput("pairs_summ")),
#                                                                       tabPanel("更多資訊",mainPanel(includeMarkdown("md/about.md")))),
#                        br(), actionButton("back_step2", "⬅️ 回上一步", class = "btn-secondary")))

step3_ui <- hidden(div(id = "step3_box", h4("步驟 3：定位分析"),
                       
                       tabsetPanel(
                         tabPanel("原始資料", DTOutput("pairs_rawtbl"),
                                  includeMarkdown("md/rawdata_info.md")), 
                         tabPanel("品牌分數", DTOutput("brand_mean"),br(),br(),
                                  includeMarkdown("md/brandscore_info.md"),br(),br(),
                                  actionButton("refresh", "分析報告"), 
                                  br(),br(),
                                  withSpinner(
                                    htmlOutput("brand_ideal_summary"),
                                    type  = 6,       # 內建多種 spinner 型號 1–8
                                    color = "#0d6efd" # Bootstrap 主題色
                                  )), 
                         tabPanel("品牌DNA", dnaModuleUI("dna1"),includeMarkdown("md/DNA_info.md")),
                         tabPanel("關鍵因素與理想點分數", idealModuleUI("ideal1"),
                                  br(),br(),
                                  includeMarkdown("md/keyfactor_info.md")
                                  # actionButton("refresh_key_factor", "關鍵因素探索"),
                                  # br(),br(),
                                  # withSpinner(
                                  #   htmlOutput("key_factor_gpt"),
                                  #   type  = 6,       # 內建多種 spinner 型號 1–8
                                  #   color = "#0d6efd" # Bootstrap 主題色
                                  # )
                                  ),
                         tabPanel("品牌定位策略建議", strategyModuleUI("strat1")),
                         tabPanel("更多資訊",mainPanel(includeMarkdown("md/about.md")))
                       )
                       
                       ,
                       br(), actionButton("back_step2", "⬅️ 回上一步", class = "btn-secondary")))



# ---- Main ------------------------------------------------------------------
main_ui <- hidden(div(id = "main_page", div(id = "welcome_box", h3("🎉 歡迎！"), textOutput("welcome")), br(), step1_ui, step2_ui, step3_ui, br(), actionButton("logout", "登出")))

# ---- App UI ----------------------------------------------------------------
ui <- fluidPage(
  theme = app_theme, 
  useShinyjs(), 
  tags$head(
    tags$style(HTML("
      #icon_bar { display:flex; gap:12px; align-items:center; margin-bottom:16px; } 
      #icon_bar img { max-height:60px; }
      #db_status_bar { 
        position: fixed; 
        top: 10px; 
        right: 10px; 
        z-index: 1000;
        padding: 8px 15px;
        border-radius: 5px;
        background: rgba(255,255,255,0.95);
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
    "))
  ), 
  div(id = "db_status_bar", uiOutput("db_status")),
  icon_bar, 
  login_ui, 
  register_ui, 
  main_ui
)

# ── Server ------------------------------------------------------------------
server <- function(input, output, session) {
  con_global   <- get_con()
  db_info <- get_db_info(con_global)  # 取得資料庫連接資訊
  onStop(function() dbDisconnect(con_global))
  
  user_info    <- reactiveVal(NULL)   # 登入後的 user row
  working_data <- reactiveVal(NULL)   # 原始 / 評分後的資料
  
  output$partner_icons <- renderUI(NULL)  # 供動態加入 logo
  
  # 資料庫狀態顯示
  output$db_status <- renderUI({
    div(
      style = sprintf("color: %s; font-weight: bold;", db_info$color),
      span(db_info$icon, style = "margin-right: 5px;"),
      span(db_info$type, style = "margin-right: 5px;"),
      span(sprintf("(%s)", db_info$status), style = "font-size: 0.9em; opacity: 0.8;")
    )
  })
  
  # ----------- 註冊/登入/登出 ----------------------------------------------
  observeEvent(input$to_register, { hide("login_page"); show("register_page") })
  observeEvent(input$to_login,    { hide("register_page"); show("login_page") })
  
  observeEvent(input$register_btn, {
    req(input$reg_user, input$reg_pw, input$reg_pw2)
    if (input$reg_pw != input$reg_pw2)
      return(output$register_msg <- renderText("❌ 兩次密碼不一致"))
    if (nchar(input$reg_pw) < 6)
      return(output$register_msg <- renderText("❌ 密碼至少 6 個字元"))
    
    if (nrow(dbGetQuery(con_global, "SELECT 1 FROM users WHERE username=$1", params = list(input$reg_user)))) {
      return(output$register_msg <- renderText("❌ 帳號已存在"))
    }
    
    dbExecute(con_global, "INSERT INTO users (username,hash,role,login_count) VALUES ($1,$2, 'user',0)", params = list(input$reg_user, bcrypt::hashpw(input$reg_pw)))
    output$register_msg <- renderText("✅ 註冊成功！請登入")
    updateTextInput(session, "login_user", value = input$reg_user)
    hide("register_page"); show("login_page")
  })
  
  observeEvent(input$login_btn, {
    req(input$login_user, input$login_pw)
    row <- dbGetQuery(con_global, "SELECT * FROM users WHERE username=$1", params = list(input$login_user))
    if (!nrow(row)) return(output$login_msg <- renderText("❌ 帳號不存在"))
    
    used <- row$login_count %||% 0
    if (row$role != "admin" && used >= 5)
      return(output$login_msg <- renderText("⛔ 已達登入次數上限"))
    
    if (bcrypt::checkpw(input$login_pw, row$hash)) {
      if (row$role != "admin")
        dbExecute(con_global, "UPDATE users SET login_count=login_count+1 WHERE id=$1", params = list(row$id))
      user_info(row)
      hide("login_page"); hide("register_page"); show("main_page")
      output$welcome <- renderText(sprintf("Hello %s (role:%s)", row$username, row$role))
      shinyjs::delay(3000, hide("welcome_box"))
    } else output$login_msg <- renderText("❌ 帳號或密碼錯誤")
  })
  
  observeEvent(input$logout, {
    user_info(NULL); working_data(NULL); facets_rv(NULL)
    hide("main_page"); show("login_page")
    hide("step2_box"); hide("step3_box"); show("step1_box")
    output$preview_tbl <- renderDT(NULL)
    output$score_tbl   <- renderDT(NULL)
    output$pairs_plot  <- NULL; output$pairs_rawtbl <- NULL; output$pairs_summ <- NULL
    show("welcome_box")
  })
  
  # ----------- Step 1：上傳資料 ---------------------------------------------
  observeEvent(input$load_btn, {
    req(user_info())
    hide("step2_box"); hide("step3_box"); show("step1_box")
    output$pairs_plot <- NULL
    
    if (is.null(input$excel))
      return(output$step1_msg <- renderText("⚠️ 請先上傳 Excel 檔案"))
    
    ext <- tolower(tools::file_ext(input$excel$name))
    if (!ext %in% c("xlsx", "xls","csv"))
      return(output$step1_msg <- renderText("⚠️ 只能上傳 .xlsx / .xls/.csv"))
    
    if(ext=="csv"){
      dat <- read_csv(input$excel$datapath)
    } else{
      dat <- read_excel(input$excel$datapath)
    }
    
    # Handle case-insensitive column names
    # Find and rename the required columns regardless of case
    col_mapping <- list(
      "variation" = "Variation",
      "title" = "Title", 
      "body" = "Body"
    )
    
    for (old_name in names(col_mapping)) {
      new_name <- col_mapping[[old_name]]
      # Find column index with case-insensitive match
      idx <- which(tolower(names(dat)) == old_name)
      if (length(idx) > 0) {
        names(dat)[idx[1]] <- new_name
      }
    }
    
    must <- c("Variation", "Title", "Body")
    if (!all(must %in% names(dat)))
      return(output$step1_msg <- renderText("⚠️ 檔案缺少 Variation / Title / Body 欄位"))
    
    dbExecute(con_global, "INSERT INTO rawdata (user_id,uploaded_at,json) VALUES ($1,$2,$3)", params = list(user_info()$id, as.character(Sys.time()), toJSON(dat, dataframe = "rows", auto_unbox = TRUE)))
    
    working_data(dat)
    output$preview_tbl <- renderDT(dat, selection = "none")
    output$step1_msg   <- renderText(sprintf("✅ 已上傳並存入 rawdata，共 %d 筆", nrow(dat)))
  })
  
  # ----------- 進入 Step2 ----------------------------------------------------
  observeEvent(input$to_step2, {
    req(!is.null(working_data()), cancelOutput = TRUE, "⚠️ 尚未有可用資料，請先完成步驟 1")
    hide("step1_box"); show("step2_box")
    shinyjs::disable("score")
    shinyjs::disable("to_step3")
    facets_rv(NULL)
    output$facet_msg <- renderText("尚未產生屬性，請先按「產生 6 個屬性」")
  })
  
  # ----------- 產生 10 個屬性 -----------------------------------------------
  
  observeEvent(input$gen_facets, {
    dat <- working_data()
    req(nrow(dat) > 0)
    if (is.null(dat))
      return(output$facet_msg <- renderText("⚠️ 尚未上傳任何資料"))
    sample_txt <- toJSON(head(dat, 100), dataframe = "rows", auto_unbox = TRUE)
    
    sys <- list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。")
    usr <- list(
      role = "user",
      content = paste0(
        "請針對以下各顧客評論中，從產品定位理論中的屬性、功能、利益和用途等特質，探勘出與該產品最重要、且出現次數最高的 6 個正面描述且具體的特質，並依照該特質出現頻率進行排序",
        "輸出格式為 {屬性1 , 屬性2 , … , 屬性6} 。禁止出現其他文字。\n\n評論：\n",
        sample_txt
      )
    )
    
    txt <- chat_api(list(sys, usr))   # ← 一次完成
    attrs <- str_extract_all(txt, "[^{},，\\s]+")[[1]]
    attrs <- unique(trimws(attrs))
    
    if (length(attrs) < 5) {
      shinyjs::disable("score")
      return(output$facet_msg <- renderText("⚠️ 無法解析屬性，請重試"))
    }
    
    facets_rv(attrs)
    shinyjs::enable("score")
    output$facet_msg <- renderText(
      sprintf("✅ 已產生屬性：%s", paste(attrs, collapse = ", "))
    )
  })
  
  
  
  # ----------- 开始評分 ------------------------------------------------------
  observeEvent(input$score, {
    shinyjs::disable("score")
    attrs <- facets_rv(); req(length(attrs) > 0)
    df0 <- working_data(); req(!is.null(df0))
    df  <- head(df0, input$nrows)
    total <- nrow(df)
    start_time <- Sys.time()
    progress_info(list(start=start_time, done=0, total=total))
    results_list <- vector("list", total)
    withProgress(message = "評分中…", value = 0, {
      for (i in seq_len(total)) {
        row <- df[i, ]
        # prepare prompts for attributes in this row
        prompts <- lapply(attrs, function(a) {
          list(
            list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。"),
            list(role = "user", content = sprintf(
              "以下 JSON：%s請只回%s:<1-5或無>",
              toJSON(row[c("Variation","Title","Body")], dataframe = "rows", auto_unbox = TRUE), a
            ))
          )
        })
        # parallel call for this row (or sequential on shinyapps.io)
        if (Sys.getenv("SHINY_PORT") != "") {
          # Sequential processing on shinyapps.io
          res_vec <- purrr::map_chr(prompts, function(msgs) {
            out <- try(chat_api(msgs), silent = TRUE)
            if (inherits(out, "try-error")) NA_character_ else out
          })
        } else {
          # Parallel processing locally
          res_vec <- future_map_chr(prompts, function(msgs) {
            out <- try(chat_api(msgs), silent = TRUE)
            if (inherits(out, "try-error")) NA_character_ else out
          }, .options = furrr_options(seed = TRUE))
        }
        vals <- purrr::map_dbl(res_vec, safe_value)
        # build one-row data.frame: each attribute as column
        tmp_list <- setNames(as.list(vals), attrs)
        scores_df <- as.data.frame(tmp_list, check.names = FALSE, stringsAsFactors = FALSE)
        # prepend Variation column
        scores_df <- cbind(Variation = row$Variation, scores_df)
        results_list[[i]] <- scores_df
        # update modal progress
        incProgress(1 / total, detail = {
          elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
          eta <- (elapsed / i) * (total - i)
          sprintf("預估剩餘 %02d:%02d", eta %/% 60, round(eta %% 60))
        })
        # update ETA display
        progress_info(list(start = start_time, done = i, total = total))
      }
    })
    result_df <- bind_rows(results_list)
    other_col <- df %>% select(-c("Variation","Title","Body"))
    result_df <- bind_cols(other_col,result_df)
    working_data(result_df)
    output$score_tbl <- renderDT(result_df, selection = "none")
    shinyjs::enable("to_step3")
    # store to DB
    dbExecute(con_global,
              "INSERT INTO processed_data (user_id, processed_at, json) VALUES ($1,$2,$3)",
              params = list(
                user_info()$id,
                as.character(Sys.time()),
                toJSON(result_df, dataframe = "rows", auto_unbox = TRUE)
              )
    )
    showNotification("✅ 評分完成並已存入 processed_data", type = "message")
  })
  # display ETA
  # output$eta <- renderText({
  #   pi <- progress_info()
  #   if (is.null(pi$start) || pi$done==0) return(NULL)
  #   elapsed <- as.numeric(difftime(Sys.time(), pi$start, units="secs"))
  #   rem     <- (elapsed/pi$done)*(pi$total-pi$done)
  #   sprintf("預估剩餘時間：%02d:%02d", rem%/%60, round(rem%%60))
  # })
  
  # ----------- 進入 Step3 ----------------------------------------------------
  observeEvent(input$to_step3, {
    dat <- working_data()
    req(dat, cancelOutput = TRUE, "⚠️ 需要完成評分後才能進入")
    #req(nrow(dat) > 1, cancelOutput = TRUE, "⚠️ 需要至少 2 筆資料才能產生散布矩陣")
  #  req("Brand" %in% names(dat), cancelOutput = TRUE, "需要有Brand 才能看定位")
    hide("step2_box"); show("step3_box")
    
    numeric_cols <- setdiff(names(dat), "Variation")
    dat_num <- mutate(dat, across(all_of(numeric_cols), as.numeric))
    # ggpairs 對中文欄名在內部 aes() 會解析失敗，轉成合法 R 名稱再繪圖
    dat_plot <- dat_num
    names(dat_plot) <- make.names(names(dat_plot), unique = TRUE)
    
    output$pairs_rawtbl <- renderDT(dat, selection = "none")
    
    position_dta <- dat %>%
      group_by(Variation) %>%
      summarise(
        across(
          where(is.numeric),       # 所有数值列
          ~ mean(.x, na.rm = TRUE), # 用 sum 
          .names = "{.col}"     # 输出列名会变成 sum_score、sum_sales...
        ),
        .groups = "drop"
      )
    
    num_cols <- names(position_dta)[
      sapply(position_dta, is.numeric) 
    ]
    
    
    
    # 如果没有 “Ideal” 这一行，就计算均值并绑定进来
    if (! "Ideal" %in% position_dta$Variation) {
      ideal_vals <- position_dta %>% 
        filter(Variation != "Ideal") %>%        # 确保不含理想点
        select(all_of(num_cols)) %>% 
        summarise(across(everything(), mean, na.rm = TRUE))
      
      # 构造完整 ideal 行：Variation、brand、其它字段
      ideal_row <- tibble(
        Variation               = "Ideal",
        # 把数值列拼进去
        !!!ideal_vals
      )
      
      # 插入到原表
      position_dta <- bind_rows(position_dta, ideal_row)
      
    }

    
    output$brand_mean <- renderDT({
      # 1. 找出所有 numeric 欄位的索引
      num_cols <- which(sapply(position_dta, is.numeric))
      
      # 2. 建立 datatable 並套用 formatRound
      datatable(position_dta, rownames = FALSE) %>%
        formatRound(
          columns = num_cols,
          digits  = 3
        )
      
    } , selection = "none")
    
    md_text <- reactive({
      req(input$refresh)  # 按鈕才會更新
      position_txt <- toJSON(position_dta, dataframe = "rows", auto_unbox = TRUE)
      
      sys <- list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。")
      usr <- list(
        role = "user",
        content = paste0(
          "請列出各Variation的優勢和劣勢，不用列出各Variation的分數，IDEAL也不用列出優勢和劣勢，2.針對各Variation提出行銷策略和廣告文字建議。字數限200字內",
          "請回覆為 markdown 的內容，**不要用 ``` 或任何程式碼區塊包起來**。資料:",
          position_txt
        )
      )
      # txt <- 
      chat_api(list(sys, usr))   # ← 一次完成
      # attrs <- str_extract_all(txt, "[^{},，\\s]+")[[1]]
      # attrs <- unique(trimws(attrs))

    })
    
    output$brand_ideal_summary <- renderUI({
      # markdownToHTML 會回傳一個 HTML 字串
      res <- md_text()
      res <-   strip_code_fence(res)
      #print(res)
      html <- markdownToHTML(text = res, fragment.only = TRUE)
      HTML(html)
    })
    
    
    md_text_key_fac <- reactive({
      req(input$refresh_key_factor)  # 按鈕才會更新
      position_txt <- toJSON(position_dta, dataframe = "rows", auto_unbox = TRUE)
      
      sys <- list(role = "system", content = "你是一位行銷專業的數據分析師，請用繁體中文回答。")
      usr <- list(
        role = "user",
        content = paste0(
          "請描述儀表板上列出的關鍵因素名稱，並說明這些關鍵因素是顧客重視的產品特質，和提出行銷策略和廣告建議，字數限200字內",
          "請回覆為markdown的格式。資料:",
          position_txt
        )
      )
     # txt <- 
      chat_api(list(sys, usr))   # ← 一次完成
      # attrs <- str_extract_all(txt, "[^{},，\\s]+")[[1]]
      # attrs <- unique(trimws(attrs))
      
    })
    
    output$key_factor_gpt <- renderUI({
      # markdownToHTML 會回傳一個 HTML 字串
      res <- md_text_key_fac()
      res <- strip_code_fence(res)
    #  print(res)
      html <- markdownToHTML(text = res, fragment.only = TRUE)
      HTML(html)
    })
    
     
    
    raw       <- reactive({ position_dta })
    with_na   <- reactive({ raw() %>% select(where(~ !all(is.na(.)))) })
    no_na     <- reactive({ with_na() %>% select(where(~ !any(is.na(.)))) })
    
    # PCA data: numeric only
    pcaData   <- reactive({ no_na() %>% select(where(is.numeric)) })
    
    # Ideal data
    idealFull <- reactive({ with_na() })
    idealRaw  <- reactive({ idealFull() %>% filter(Variation != "Ideal") })
    
    # Indicator for Strategy
    indicator <- reactive({
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
      ideal_vals <- idealFull() %>% filter(Variation == "Ideal") %>% select(where(is.numeric))
      clean_vals <- ideal_vals %>% select(where(~ !any(is.na(.))))
      names(clean_vals)[ which(unlist(clean_vals[1,]) > mean(unlist(clean_vals[1,]))) ]
    })
    
    # Launch modules, pass indicator and keyVars to both if needed
    # pcaModuleServer("pca1",   pcaData)
    idealModuleServer("ideal1", idealFull, idealRaw,indicator = indicator_eq, key_vars = keyVars)
    strategyModuleServer("strat1", indicator, key_vars = keyVars)
    dnaModuleServer("dna1", raw)
    
    
    # output$pairs_plot <- renderPlot({
    #   req(length(numeric_cols) >= 2)
    #   ggpairs(dat_plot[, make.names(numeric_cols, unique = TRUE)], 
    #           title = "Pairs Plot of Scores")
    # })
    # 
    # output$pairs_summ <- renderTable({
    #   dat_num %>% summarise(across(all_of(numeric_cols), list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE), min = ~min(.x, na.rm = TRUE), max = ~max(.x, na.rm = TRUE)))) %>% pivot_longer(everything(), names_to = c("Variable", ".value"), names_sep = "_")
    # }, digits = 2)
    
    
    
    
    
    
    
    
  })
  
  observeEvent(input$back_step2, {
    hide("step3_box"); show("step2_box")
    output$pairs_plot   <- NULL
    output$pairs_rawtbl <- NULL
    output$pairs_summ   <- NULL
  })
}

# ---- Run --------------------------------------------------------------------
shinyApp(ui, server)
