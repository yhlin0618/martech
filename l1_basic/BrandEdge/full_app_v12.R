###############################################################################
# full_app_step_wizard_v4.R – upload‑only, dynamic facets, JSON storage       #
# Updated: 2025‑05‑20                                                         #
###############################################################################

# ── Packages -----------------------------------------------------------------
library(shiny)
library(shinyjs)
library(DBI)
library(RSQLite)
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


library(plotly)
library(DT)
library(DBI)
library(duckdb)

# -----------------------------------------------------------------------------
show <- shinyjs::show
hide <- shinyjs::hide

LLM_URL   <- Sys.getenv("LLM_URL",   "http://localhost:11434/v1/chat/completions")
LLM_MODEL <- Sys.getenv("LLM_MODEL", "llama4:latest")

# ── DB helpers ----------------------------------------------------------------
get_con <- function() {
  db <- dbConnect(RSQLite::SQLite(), "users.sqlite")
  dbExecute(db, "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY,\n                                                  username TEXT UNIQUE,\n                                                  hash TEXT,\n                                                  role TEXT DEFAULT 'user',\n                                                  login_count INTEGER DEFAULT 0)")
  dbExecute(db, "CREATE TABLE IF NOT EXISTS rawdata (id INTEGER PRIMARY KEY,\n                                                     user_id INTEGER,\n                                                     uploaded_at TEXT,\n                                                     json TEXT)")
  dbExecute(db, "CREATE TABLE IF NOT EXISTS processed_data (id INTEGER PRIMARY KEY,\n                                                            user_id INTEGER,\n                                                            processed_at TEXT,\n                                                            json TEXT)")
  db
}


# ── reactive values -----------------------------------------------------------
facets_rv   <- reactiveVal(NULL)  # 目前 LLM 產出的 10 個屬性 (字串向量)

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

source("module.R")
# ── UI -----------------------------------------------------------------------
# ---- Global icon bar --------------------------------------------------------
icons_path <- if (dir.exists("www/icons")) "www/icons" else "www"
addResourcePath("icons", icons_path)  # <img src="icons/icon.png">

icon_bar <- div(id = "icon_bar", img(src = "icons/icon.png", height = "60px", id = "icon_main"), uiOutput("partner_icons"))

# ---- 登入 / 註冊 ----
login_ui <- div(id = "login_page",img(src = "icons/icon.png", height = "300px", id = "icon_main"), h4("🔐 使用者登入"), textInput("login_user", "帳號"), passwordInput("login_pw", "密碼"), actionButton("login_btn", "登入", class = "btn-primary"), br(), actionLink("to_register", "沒有帳號？點此註冊"),includeMarkdown("md/contacts.md"), verbatimTextOutput("login_msg"))

register_ui <- hidden(div(id = "register_page", h2("📝 註冊新帳號"), textInput("reg_user", "帳號"), passwordInput("reg_pw", "密碼"), passwordInput("reg_pw2", "確認密碼"), actionButton("register_btn", "註冊", class = "btn-success"), br(), actionLink("to_login", "已有帳號？回登入"),includeMarkdown("md/contacts.md"), verbatimTextOutput("register_msg")))

# ---- Step 1：上傳資料 -------------------------------------------------------
step1_ui <- div(id = "step1_box", h4("步驟 1：上傳評論 Excel"), includeMarkdown("md/notification.md"),fileInput("excel", "選擇 Excel (需含 Variation/Title/Body)"), br(), actionButton("load_btn", "上傳並預覽", class = "btn-success"), br(), verbatimTextOutput("step1_msg"), DTOutput("preview_tbl"), br(), actionButton("to_step2", "下一步 ➡️", class = "btn-info"),includeMarkdown("md/contacts.md"))

# ---- Step 2：產生屬性並評分 -------------------------------------------------
step2_ui <- hidden(div(id = "step2_box", h4("步驟 2：產生屬性並評分"), actionButton("gen_facets", "產生 10 個屬性", class = "btn-secondary"), verbatimTextOutput("facet_msg"), br(), sliderInput("nrows", "取前幾列 (評分)", min = 1, max = 100, value = 50, step = 1, ticks = FALSE), shinyjs::disabled(actionButton("score", "開始評分", class = "btn-primary")), br(), DTOutput("score_tbl"), br(), actionButton("to_step3", "下一步 ➡️", class = "btn-info"),includeMarkdown("md/contacts.md")))

# ---- Step 3：視覺化 ---------------------------------------------------------
# step3_ui <- hidden(div(id = "step3_box", h4("步驟 3：視覺化結果"), tabsetPanel(tabPanel("原始資料", DTOutput("pairs_rawtbl")), 
#                                                                        tabPanel("散布矩陣", plotOutput("pairs_plot", height = 600)), 
#                                                                        tabPanel("摘要統計", tableOutput("pairs_summ")),
#                                                                       tabPanel("更多資訊",mainPanel(includeMarkdown("md/about.md")))),
#                        br(), actionButton("back_step2", "⬅️ 回上一步", class = "btn-secondary")))

step3_ui <- hidden(div(id = "step3_box", h4("步驟 3：定位分析"),
                       
                       tabsetPanel(
                         tabPanel("原始資料", DTOutput("pairs_rawtbl")), 
                         tabPanel("品牌分數", DTOutput("brand_mean")), 
                         tabPanel("關鍵因素與理想點分數", idealModuleUI("ideal1")),
                         tabPanel("品牌定位策略建議", strategyModuleUI("strat1")),
                         tabPanel("品牌DNA", dnaModuleUI("dna1")),
                         tabPanel("更多資訊",mainPanel(includeMarkdown("md/about.md")))
                       )
                       
                       ,
                       br(), actionButton("back_step2", "⬅️ 回上一步", class = "btn-secondary")))



# ---- Main ------------------------------------------------------------------
main_ui <- hidden(div(id = "main_page", div(id = "welcome_box", h3("🎉 歡迎！"), textOutput("welcome")), br(), step1_ui, step2_ui, step3_ui, br(), actionButton("logout", "登出")))

# ---- App UI ----------------------------------------------------------------
ui <- fluidPage(theme = app_theme, useShinyjs(), tags$head(tags$style("#icon_bar { display:flex; gap:12px; align-items:center; margin-bottom:16px; } #icon_bar img { max-height:60px; }")), icon_bar, login_ui, register_ui, main_ui)

# ── Server ------------------------------------------------------------------
server <- function(input, output, session) {
  con_global   <- get_con()
  onStop(function() dbDisconnect(con_global))
  
  user_info    <- reactiveVal(NULL)   # 登入後的 user row
  working_data <- reactiveVal(NULL)   # 原始 / 評分後的資料
  
  output$partner_icons <- renderUI(NULL)  # 供動態加入 logo
  
  # ----------- 註冊/登入/登出 ----------------------------------------------
  observeEvent(input$to_register, { hide("login_page"); show("register_page") })
  observeEvent(input$to_login,    { hide("register_page"); show("login_page") })
  
  observeEvent(input$register_btn, {
    req(input$reg_user, input$reg_pw, input$reg_pw2)
    if (input$reg_pw != input$reg_pw2)
      return(output$register_msg <- renderText("❌ 兩次密碼不一致"))
    if (nchar(input$reg_pw) < 6)
      return(output$register_msg <- renderText("❌ 密碼至少 6 個字元"))
    
    if (nrow(dbGetQuery(con_global, "SELECT 1 FROM users WHERE username=?", params = list(input$reg_user)))) {
      return(output$register_msg <- renderText("❌ 帳號已存在"))
    }
    
    dbExecute(con_global, "INSERT INTO users (username,hash,role,login_count) VALUES (?,?, 'user',0)", params = list(input$reg_user, bcrypt::hashpw(input$reg_pw)))
    output$register_msg <- renderText("✅ 註冊成功！請登入")
    updateTextInput(session, "login_user", value = input$reg_user)
    hide("register_page"); show("login_page")
  })
  
  observeEvent(input$login_btn, {
    req(input$login_user, input$login_pw)
    row <- dbGetQuery(con_global, "SELECT * FROM users WHERE username=?", params = list(input$login_user))
    if (!nrow(row)) return(output$login_msg <- renderText("❌ 帳號不存在"))
    
    used <- row$login_count %||% 0
    if (row$role != "admin" && used >= 5)
      return(output$login_msg <- renderText("⛔ 已達登入次數上限"))
    
    if (bcrypt::checkpw(input$login_pw, row$hash)) {
      if (row$role != "admin")
        dbExecute(con_global, "UPDATE users SET login_count=login_count+1 WHERE id=?", params = list(row$id))
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
    if (!ext %in% c("xlsx", "xls"))
      return(output$step1_msg <- renderText("⚠️ 只能上傳 .xlsx / .xls"))
    
    dat <- read_excel(input$excel$datapath)
    must <- c("Variation", "Title", "Body")
    if (!all(must %in% names(dat)))
      return(output$step1_msg <- renderText("⚠️ 檔案缺少 Variation / Title / Body 欄位"))
    
    dbExecute(con_global, "INSERT INTO rawdata (user_id,uploaded_at,json) VALUES (?,?,?)", params = list(user_info()$id, as.character(Sys.time()), toJSON(dat, dataframe = "rows", auto_unbox = TRUE)))
    
    working_data(dat)
    output$preview_tbl <- renderDT(dat, selection = "none")
    output$step1_msg   <- renderText(sprintf("✅ 已上傳並存入 rawdata，共 %d 筆", nrow(dat)))
  })
  
  # ----------- 進入 Step2 ----------------------------------------------------
  observeEvent(input$to_step2, {
    req(!is.null(working_data()), cancelOutput = TRUE, "⚠️ 尚未有可用資料，請先完成步驟 1")
    hide("step1_box"); show("step2_box")
    shinyjs::disable("score")
    facets_rv(NULL)
    output$facet_msg <- renderText("ℹ️ 尚未產生屬性，請先按「產生 10 個屬性」")
  })
  
  # ----------- 產生 10 個屬性 -----------------------------------------------
  observeEvent(input$gen_facets, {
    dat <- working_data()
    if (is.null(dat))
      return(output$facet_msg <- renderText("⚠️ 尚未上傳任何資料"))
    #sample_txt <- toJSON(dat, dataframe = "rows", auto_unbox = TRUE)
    sample_txt <- toJSON(head(dat, 20), dataframe = "rows", auto_unbox = TRUE)
    prompt <- list(
      list(role = "system", content = "你是一位數據分析師，請用繁體中文回答。"),
      list(role = "user", content = paste0("請根據以下評論，產生 10 個關鍵屬性名稱，固定輸出格式為 {屬性1 , 屬性2 , … , 屬性10} 。禁止出現其他文字。\n\n評論：\n", sample_txt))
    )
    
    res <- tryCatch(
      POST(LLM_URL, body = list(model = LLM_MODEL, messages = prompt, stream = FALSE), encode = "json", timeout(60)),
      error = function(e) e)
    
    if (inherits(res, "error"))
      return(output$facet_msg <- renderText("❌ LLM 產生屬性失敗"))
    
    txt <- content(res, as = "parsed")$choices[[1]]$message$content
    # 抓大括號內或整段字串，再切割 , 、 或空白
    mm <- str_match(txt, "\\{\\s*([^}]*)\\s*\\}")
    props_str <- if (!is.na(mm[1,2])) mm[1,2] else txt
    attrs <- str_split(props_str, ",|，|、|\\s+")[[1]]
    attrs <- trimws(attrs)
    attrs <- attrs[attrs != ""]
    
    if (length(attrs) < 2) {
      shinyjs::disable("score")
      return(output$facet_msg <- renderText("⚠️ 無法解析屬性，請重試"))
    }
    
    facets_rv(attrs)              # 僅存屬性名稱向量
    shinyjs::enable("score")      # 啟用評分按鈕
    output$facet_msg <- renderText(sprintf("✅ 已產生屬性：%s", paste(attrs, collapse = ", ")))
  })
  
  # ----------- 开始評分 ------------------------------------------------------
  observeEvent(input$score, {
    facets <- facets_rv()
    if (is.null(facets))
      return(showNotification("⚠️ 請先產生屬性", type = "error"))
    
    dat <- working_data()
    req(dat, cancelOutput = TRUE, "⚠️ 尚未載入資料")
    
    dat <- head(dat, input$nrows)
    
    res_list <- vector("list", nrow(dat))
    
    withProgress(message = "評分中...", value = 0, {
      total <- nrow(dat); start_time <- Sys.time()
      for (i in seq_len(total)) {
        row      <- dat[i,]
        row_json <- toJSON(row[intersect(names(row), c("Variation", "Title", "Body"))],
                           dataframe = "rows", auto_unbox = TRUE)
        
        
        scores   <- list(Variation = as.character(row$Variation))
        
        for (ft in facets) {
          prompt <- list(
            list(role = "system", content = "你是一位數據分析師，請用繁體中文回答。"),
            list(role = "user", content = paste0("以下 JSON：\n", row_json, "\n\n請只回", ft, ":<1-5或無>"))
          )
          res <- tryCatch(POST(LLM_URL, body = list(model = LLM_MODEL, messages = prompt, stream = FALSE), encode = "json", timeout(30)), error = function(e) e)
          if (inherits(res, "error")) scores[[ft]] <- NA_real_ else {
            txt <- trimws(content(res, as = "parsed")$choices[[1]]$message$content)
            scores[[ft]] <- safe_value(txt)
          }
        }
        # 保留原始欄名（含中文）避免被 as.data.frame() 自動改成 X....
        res_list[[i]] <- as.data.frame(scores, check.names = FALSE)
        
        elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
        eta     <- (elapsed / i) * (total - i)
        incProgress(1 / total, detail = sprintf("剩餘 %02d:%02d", eta %/% 60, round(eta %% 60)))
      }
    })
    
    result_df <- bind_rows(res_list)
    # 合併上先前除了Body 和 Title 以外的資料
    other_col <- dat %>% select(-c("Variation","Title","Body"))
    result_df <- bind_cols(other_col,result_df)
    working_data(result_df)
    output$score_tbl <- renderDT(result_df, selection = "none")
    shinyjs::disable("score")
    
    dbExecute(con_global, "INSERT INTO processed_data (user_id, processed_at, json) VALUES (?,?,?)", params = list(user_info()$id, as.character(Sys.time()), toJSON(result_df, dataframe = "rows", auto_unbox = TRUE)))
    
    showNotification("✅ 評分完成並已存入 processed_data", type = "message")
  })
  
  # ----------- 進入 Step3 ----------------------------------------------------
  observeEvent(input$to_step3, {
    dat <- working_data()
    req(dat, cancelOutput = TRUE, "⚠️ 需要完成評分後才能進入")
    req(nrow(dat) > 1, cancelOutput = TRUE, "⚠️ 需要至少 2 筆資料才能產生散布矩陣")
    req("Brand" %in% names(dat), cancelOutput = TRUE, "需要有Brand 才能看定位")
    hide("step2_box"); show("step3_box")
    
    numeric_cols <- setdiff(names(dat), "Variation")
    dat_num <- mutate(dat, across(all_of(numeric_cols), as.numeric))
    # ggpairs 對中文欄名在內部 aes() 會解析失敗，轉成合法 R 名稱再繪圖
    dat_plot <- dat_num
    names(dat_plot) <- make.names(names(dat_plot), unique = TRUE)
    
    output$pairs_rawtbl <- renderDT(dat, selection = "none")
    
    position_dta <- dat %>%
      group_by(Variation, Brand) %>%
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
        Brand              = "Ideal",
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
    
    
    # key factors for Ideal & Strategy
    keyVars <- reactive({
      ideal_vals <- idealFull() %>% filter(Variation == "Ideal") %>% select(where(is.numeric))
      clean_vals <- ideal_vals %>% select(where(~ !any(is.na(.))))
      names(clean_vals)[ which(unlist(clean_vals[1,]) > mean(unlist(clean_vals[1,]))) ]
    })
    
    # Launch modules, pass indicator and keyVars to both if needed
    # pcaModuleServer("pca1",   pcaData)
    idealModuleServer("ideal1", idealFull, idealRaw,indicator = indicator, key_vars = keyVars)
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
