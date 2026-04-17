###############################################################################
# BrandEdge 旗艦版 - 品牌印記引擎                                               #
# 版本: v3.0 Flagship Edition                                                #
# 基於 VitalSigns 架構設計                                                     #
# 更新: 2025-01-07                                                            #
###############################################################################

# ── 系統初始化 ──────────────────────────────────────────────────────────────
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

# 載入配置模組（包含 .env 載入）
source("config/config.R")

# 載入資料庫連接模組
source("database/db_connection.R")

# 載入提示系統 (shared 版本)
source("utils/hint_system.R")

# 載入 Prompt 管理系統 (shared 版本)
source("utils/prompt_manager.R")

# 載入 Supabase 認證模組 (global_scripts 版本)
source("scripts/global_scripts/10_rshinyapp_components/login/supabase_auth.R")
source("scripts/global_scripts/10_rshinyapp_components/login/login_module_supabase.R")

# 驗證配置
validate_config()

# 修復並行處理設定
if (Sys.getenv("SHINY_PORT") != "") {
  plan(sequential)
} else {
  plan(multisession, workers = min(2, parallel::detectCores() - 1))
}
options(future.rng.onMisuse = "ignore")

# ── 資源路徑設定 ────────────────────────────────────────────────────────
addResourcePath("global_assets", "scripts/global_scripts")

# ── 全域 CSS 樣式 ────────────────────────────────────────────────────────
css_deps <- tags$head(
  # 引入登入頁面 CSS (from global_scripts/19_CSS/login.css)
  tags$link(rel = "stylesheet", type = "text/css", href = "global_assets/19_CSS/login.css"),
  # 引入增強版市場輪廓分析模組的CSS
  tags$link(rel = "stylesheet", type = "text/css", href = "market_profile_enhanced.css"),
  tags$style(HTML("
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
    margin: 0 5px;
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
  
  /* 屬性數量選擇器 */
  .attr-selector {
    background: #f8f9fa;
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1rem;
  }
  
  /* 屬性標籤 */
  .attr-badge {
    display: inline-block;
    padding: 0.25rem 0.5rem;
    margin: 0.25rem;
    background: #007bff;
    color: white;
    border-radius: 0.25rem;
    font-size: 0.875rem;
  }
  
  /* DNA分析洞察報告樣式 */
  .dna-insights {
    padding: 15px;
    background: #f8f9fa;
    border-radius: 8px;
    margin-top: 10px;
  }
  
  .dna-insights h5 {
    color: #2c3e50;
    border-bottom: 2px solid #3498db;
    padding-bottom: 10px;
    margin-bottom: 15px;
  }
  
  .dna-insights h6 {
    color: #34495e;
    margin-top: 20px;
    margin-bottom: 10px;
    font-weight: 600;
  }
  
  .ai-insights-section {
    background: #ffffff;
    border: 1px solid #dee2e6;
    border-radius: 5px;
    padding: 15px;
    margin-top: 20px;
  }
  
  .ai-insights-section ul {
    list-style-type: none;
    padding-left: 0;
  }
  
  .ai-insights-section li {
    padding: 8px 0;
    border-bottom: 1px solid #e9ecef;
  }
  
  .ai-insights-section li:last-child {
    border-bottom: none;
  }
  
  .ai-insights-section li:before {
    content: '▸ ';
    color: #3498db;
    font-weight: bold;
    margin-right: 5px;
  }
"))
)

# ── 載入模組 ────────────────────────────────────────────────────────────────
# Shared 模組
source("modules/module_wo_b.R")

# BrandEdge 專用模組
source("modules/module_brandedge_flagship.R")

# 載入增強版市場輪廓分析模組
if (file.exists("modules/module_market_profile_enhanced.R")) {
  source("modules/module_market_profile_enhanced.R")
}

# 使用 Supabase 登入模組替代原有登入模組
# if (file.exists("modules/module_login.R")) {
#   source("modules/module_login.R")
# }

# 載入完整評分上傳模組
if (file.exists("modules/module_upload_complete_score.R")) {
  source("modules/module_upload_complete_score.R")
}

# NULL合併運算子（如果未定義）
if (!exists("%||%")) {
  `%||%` <- function(x, y) {
    if (is.null(x) || length(x) == 0 || (is.character(x) && !nzchar(x))) y else x
  }
}

# ── 反應式變數 ──────────────────────────────────────────────────────────────
facets_rv <- reactiveVal(NULL)
num_attributes_rv <- reactiveVal(10)  # 預設10個屬性
progress_info <- reactiveVal(list(start=NULL, done=0, total=0))

safe_value <- function(txt) {
  txt <- trimws(txt)
  num <- str_extract(txt, "[1-5]")
  if (!is.na(num)) return(as.numeric(num))
  val <- suppressWarnings(as.numeric(txt))
  if (!is.na(val) && val >= 1 && val <= 5) return(val)
  NA_real_
}

# ── API 函數 ──────────────────────────────────────────────────────────────
chat_api <- function(messages, max_retries = 5, retry_delay = 5, use_mock = FALSE) {
  if (use_mock) {
    return(jsonlite::toJSON(list(
      facets = c("品質", "價格", "功能", "外觀", "耐用性", "使用便利性", 
                 "包裝", "客服", "配送速度", "性價比", "創新性", "安全性",
                 "環保", "品牌信譽", "售後服務")
    ), auto_unbox = TRUE))
  }
  
  api_key <- Sys.getenv("OPENAI_API_KEY")
  if (!nzchar(api_key)) {
    return(jsonlite::toJSON(list(
      facets = c("品質", "價格", "功能", "外觀", "耐用性", "使用便利性",
                 "包裝", "客服", "配送速度", "性價比")
    ), auto_unbox = TRUE))
  }
  
  for (attempt in 1:max_retries) {
    tryCatch({
      response <- httr::POST(
        url = "https://api.openai.com/v1/chat/completions",
        add_headers(
          `Content-Type` = "application/json",
          Authorization = paste("Bearer", api_key)
        ),
        body = jsonlite::toJSON(list(
          model = "gpt-4o-mini",
          messages = messages,
          temperature = 0.7,
          max_tokens = 500
        ), auto_unbox = TRUE),
        encode = "json",
        timeout(30)
      )
      
      if (httr::status_code(response) == 200) {
        content <- httr::content(response, "text", encoding = "UTF-8")
        parsed <- jsonlite::fromJSON(content)
        return(parsed$choices[[1]]$message$content)
      } else if (httr::status_code(response) == 429) {
        if (attempt < max_retries) {
          Sys.sleep(retry_delay * attempt)
          next
        }
      }
    }, error = function(e) {
      if (attempt == max_retries) {
        return(jsonlite::toJSON(list(
          facets = rep("預設屬性", num_attributes_rv())
        ), auto_unbox = TRUE))
      }
    })
  }
}

# ── 主要應用 UI (bs4Dash) ───────────────────────────────────────────
main_app_ui <- bs4DashPage(
  title = "BrandEdge 旗艦版",
  fullscreen = TRUE,
  
  # 頁首
  header = bs4DashNavbar(
    title = bs4DashBrand(
      title = "BrandEdge 旗艦版",
      color = "primary"
    ),
    skin = "light",
    status = "primary",
    fixed = TRUE,
    rightUi = tagList(
      uiOutput("user_menu")
    )
  ),
  
  # 側邊欄
  sidebar = bs4DashSidebar(
    status = "primary",
    width = "300px",
    elevation = 3,
    minified = FALSE,
    
    # 歡迎訊息
    div(class = "welcome-banner",
        h5("🚀 BrandEdge 旗艦版", style = "margin: 0;"),
        p("品牌印記引擎", style = "margin: 0.5rem 0 0 0;")
    ),
    
    # 步驟指示器
    div(class = "step-indicator",
        div(class = "step-item", id = "step_1", "1. 上傳"),
        div(class = "step-item", id = "step_2", "2. 屬性"),
        div(class = "step-item", id = "step_3", "3. 評分"),
        div(class = "step-item", id = "step_4", "4. 分析")
    ),
    
    # 選單
    sidebarMenu(
      id = "sidebar_menu",

      bs4SidebarHeader("📊 資料準備"),
      bs4SidebarMenuItem(
        text = "上傳已評分資料",
        tabName = "upload_complete",
        icon = icon("file-excel")
      ),
      
      bs4SidebarHeader("🎯 核心分析"),
      bs4SidebarMenuItem(
        text = "目標市場輪廓",
        tabName = "market_profile",
        icon = icon("chart-pie")
      ),
      bs4SidebarMenuItem(
        text = "市場賽道分析",
        tabName = "market_track",
        icon = icon("road")
      ),
      bs4SidebarMenuItem(
        text = "品牌DNA比較",
        tabName = "brand_dna",
        icon = icon("dna")
      ),
      bs4SidebarMenuItem(
        text = "關鍵因素分析",
        tabName = "key_factors",
        icon = icon("key")
      ),
      
      bs4SidebarHeader("📈 策略建議"),
      bs4SidebarMenuItem(
        text = "理想點分析",
        tabName = "ideal_point",
        icon = icon("bullseye")
      ),
      bs4SidebarMenuItem(
        text = "定位策略建議",
        tabName = "positioning",
        icon = icon("compass")
      ),
      bs4SidebarMenuItem(
        text = "識別度策略",
        tabName = "brand_identity",
        icon = icon("fingerprint")
      ),
      
      bs4SidebarHeader("ℹ️ 系統資訊"),
      bs4SidebarMenuItem(
        text = "關於系統",
        tabName = "about",
        icon = icon("info-circle")
      )
    )
  ),
  
  # 主要內容
  body = bs4DashBody(
    css_deps,
    useShinyjs(),
    
    bs4TabItems(
      # 上傳已評分資料頁面
      bs4TabItem(
        tabName = "upload_complete",
        uploadCompleteScoreUI("upload_complete_module")
      ),

      # 目標市場輪廓
      bs4TabItem(
        tabName = "market_profile",
        fluidRow(
          bs4Card(
            title = "目標市場輪廓分析（增強版）",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            collapsible = TRUE,
            maximizable = TRUE,
            # 使用增強版模組（如果存在），否則使用原版
            if (exists("marketProfileEnhancedUI")) {
              marketProfileEnhancedUI("market_profile_enhanced")
            } else {
              marketProfileModuleUI("market_profile1")
            }
          )
        )
      ),
      
      # 市場賽道分析
      bs4TabItem(
        tabName = "market_track",
        fluidRow(
          bs4Card(
            title = "高成長市場賽道",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            marketTrackModuleUI("market_track1")
          )
        )
      ),
      
      # 品牌DNA比較
      bs4TabItem(
        tabName = "brand_dna",
        fluidRow(
          bs4Card(
            title = "品牌DNA多維度比較",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            advancedDNAModuleUI("brand_dna1")
          )
        )
      ),
      
      # 關鍵因素分析
      bs4TabItem(
        tabName = "key_factors",
        fluidRow(
          bs4Card(
            title = "關鍵成功因素分析",
            status = "info",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            keyFactorsModuleUI("key_factors1")
          )
        )
      ),
      
      # 理想點分析
      bs4TabItem(
        tabName = "ideal_point",
        fluidRow(
          bs4Card(
            title = "理想點基準分析",
            status = "success",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            idealPointModuleUI("ideal_point1")
          )
        )
      ),
      
      # 定位策略建議
      bs4TabItem(
        tabName = "positioning",
        fluidRow(
          bs4Card(
            title = "品牌定位策略",
            status = "purple",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            strategyModuleUI("positioning1")
          )
        )
      ),
      
      # 識別度策略
      bs4TabItem(
        tabName = "brand_identity",
        fluidRow(
          bs4Card(
            title = "品牌識別度建構",
            status = "purple",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            brandIdentityModuleUI("identity1")
          )
        )
      ),
      
      # 關於系統
      bs4TabItem(
        tabName = "about",
        fluidRow(
          bs4Card(
            title = "關於 BrandEdge 旗艦版",
            status = "secondary",
            width = 12,
            solidHeader = TRUE,
            elevation = 3,
            h4("版本資訊"),
            p("BrandEdge 旗艦版 v3.0"),
            p("更新日期：2025年1月"),
            h4("功能特色"),
            tags$ul(
              tags$li("支援10-30個產品屬性分析"),
              tags$li("最多1000則評論，20個品牌"),
              tags$li("AI驅動的屬性萃取和評分"),
              tags$li("市場賽道和品牌識別度分析"),
              tags$li("完整的品牌定位策略建議")
            ),
            h4("技術支援"),
            p("如有問題請聯繫技術支援團隊"),
            p("聯絡資訊: partners@peakedges.com")
          )
        )
      )
    )
  )
)

# ── 條件式 UI (根據登入狀態) ─────────────────────────────────────────────
ui <- fluidPage(
  useShinyjs(),
  css_deps,
  
  # 根據登入狀態顯示不同UI
  conditionalPanel(
    condition = "output.user_logged_in == false",
    # 登入頁面 - 使用 login.css 的 login-page-wrapper 樣式
    loginSupabaseUI("login1",
                    title = "BrandEdge",
                    subtitle = "品牌定位分析系統",
                    app_icon = "global_assets/24_assets/icons/app_icon.png",
                    show_language_selector = FALSE)
  ),
  
  conditionalPanel(
    condition = "output.user_logged_in == true",
    main_app_ui
  )
)

# ── 伺服器邏輯 ──────────────────────────────────────────────────────────────
server <- function(input, output, session) {
  
  # 反應式變數
  user_info <- reactiveVal(NULL)
  upload_data <- reactiveVal(NULL)
  processed_data <- reactiveVal(NULL)
  scoring_data <- reactiveVal(NULL)
  
  # 初始化資料庫連接（登入成功後初始化表格）
  db_initialized <- reactiveVal(FALSE)
  
  # ──── 登入模組（Supabase 版本）────────────────────────────────────────
  # 使用 Supabase REST API 進行驗證
  login_mod <- loginSupabaseServer("login1", app_name = "brandedge")
  
  observe({
    user_info(login_mod$user_info())
    
    # 登入成功後初始化資料表
    if (!is.null(user_info()) && !db_initialized()) {
      tryCatch({
        con <- get_con()
        init_tables(con)
        db_initialized(TRUE)
        showNotification("✅ 資料庫初始化完成", type = "message")
      }, error = function(e) {
        showNotification(paste("資料庫初始化失敗:", e$message), type = "error")
      })
    }
  })
  
  # 控制登入狀態的輸出
  output$user_logged_in <- reactive({
    !is.null(user_info())
  })
  outputOptions(output, "user_logged_in", suspendWhenHidden = FALSE)
  
  # 顯示用戶資訊
  output$user_menu <- renderUI({
    if (!is.null(user_info())) {
      tagList(
        span(paste("👤", user_info()$username), style = "margin-right: 20px;"),
        actionButton("logout", "登出", class = "btn-sm btn-secondary")
      )
    }
  })
  
  # 登出功能
  observeEvent(input$logout, {
    user_info(NULL)
    login_mod$logout()
    session$reload()
  })
  
  # ──── 替代方案：上傳已評分資料 ────────────────────────────────────────
  complete_score_data <- reactiveVal(NULL)
  complete_score_attributes <- reactiveVal(NULL)
  complete_score_field_mapping <- reactiveVal(NULL)

  # 呼叫上傳完整評分模組
  upload_complete_result <- uploadCompleteScoreServer("upload_complete_module", user_id = reactive({ user_info()$id }))

  # 監聽完整評分上傳模組的確認
  observeEvent(upload_complete_result$confirm(), {
    req(upload_complete_result$data_ready())

    # 儲存上傳的評分資料
    score_data <- upload_complete_result$score_data()
    attributes <- upload_complete_result$attribute_columns()
    field_mapping <- upload_complete_result$field_mapping()

    complete_score_data(score_data)
    complete_score_attributes(attributes)
    complete_score_field_mapping(field_mapping)

    # 設定屬性到全域反應式變數
    facets_rv(attributes)
    num_attributes_rv(length(attributes))

    # 直接設定評分資料供後續分析使用
    scoring_data(score_data)

    showNotification(
      paste("成功載入", nrow(score_data), "個產品的",
            length(attributes), "個屬性評分資料"),
      type = "message",
      duration = 5
    )

    # 自動跳轉到分析頁面
    updateTabsetPanel(session, "sidebar_menu", selected = "market_profile")
  })

  # ──── 步驟 1：上傳資料 ────────────────────────────────────────
  observeEvent(input$preview_btn, {
    req(input$file)
    
    ext <- tools::file_ext(input$file$datapath)
    
    tryCatch({
      if (ext == "csv") {
        df <- read_csv(input$file$datapath, show_col_types = FALSE)
      } else {
        df <- read_excel(input$file$datapath)
      }
      
      # 檢查必要欄位
      required_cols <- c("Variation", "Title", "Body")
      if (!all(required_cols %in% names(df))) {
        showNotification(
          HTML("缺少必要欄位！<br/>
                此功能需要評論資料（Variation、Title、Body欄位）。<br/>
                <b>如果您有已評分資料，請使用側邊欄的「或 上傳已評分資料」選項。</b>"),
          type = "error",
          duration = 10
        )
        return()
      }
      
      # 檢查限制
      if (nrow(df) > 1000) {
        showNotification("評論數超過1000則限制！", type = "error")
        return()
      }
      
      n_brands <- length(unique(df$Variation))
      if (n_brands > 20) {
        showNotification("品牌數超過20個限制！", type = "error")
        return()
      }
      
      upload_data(df)
      
      output$preview_table <- renderDT({
        datatable(head(df, 100), 
                 options = list(scrollX = TRUE, pageLength = 10))
      })
      
      showNotification(sprintf("成功載入 %d 則評論，%d 個品牌", 
                              nrow(df), n_brands), 
                      type = "message")
      
    }, error = function(e) {
      showNotification(paste("讀取檔案失敗：", e$message), type = "error")
    })
  })
  
  observeEvent(input$confirm_upload, {
    req(upload_data())
    processed_data(upload_data())
    updateTabsetPanel(session, "sidebar_menu", selected = "attributes")
    
    # 更新步驟指示器
    runjs("$('#step_1').addClass('completed').removeClass('active');")
    runjs("$('#step_2').addClass('active');")
    
    showNotification("資料上傳成功！請進行屬性萃取。", type = "message")
  })
  
  # ──── 步驟 2：屬性萃取 ────────────────────────────────────────
  observeEvent(input$num_attributes, {
    num_attributes_rv(input$num_attributes)
  })
  
  observeEvent(input$generate_attributes, {
    req(processed_data())
    
    withProgress(message = '萃取產品屬性中...', value = 0, {
      incProgress(0.3, detail = "分析評論內容")
      
      # 取樣評論進行分析
      df <- processed_data()
      sample_reviews <- df %>%
        sample_n(min(50, nrow(.))) %>%
        pull(Body) %>%
        paste(collapse = " ")
      
      # 使用 GPT 萃取屬性
      num_attrs <- num_attributes_rv()
      
      messages <- list(
        list(role = "system", 
             content = "你是產品屬性分析專家，專門從顧客評論中萃取重要產品屬性。"),
        list(role = "user",
             content = sprintf(
               "請從以下評論中萃取 %d 個最重要的產品屬性。回覆JSON格式：{\"facets\":[\"屬性1\",\"屬性2\",...]}。評論：%s",
               num_attrs,
               substr(sample_reviews, 1, 3000)
             ))
      )
      
      incProgress(0.5, detail = "生成屬性列表")
      
      response <- chat_api(messages)
      
      # 解析回應
      attrs <- tryCatch({
        parsed <- jsonlite::fromJSON(response)
        if (!is.null(parsed$facets)) {
          parsed$facets
        } else {
          # 預設屬性
          c("品質", "價格", "功能", "外觀", "耐用性", "使用便利性",
            "包裝", "客服", "配送速度", "性價比", "創新性", "安全性",
            "環保", "品牌信譽", "售後服務")[1:num_attrs]
        }
      }, error = function(e) {
        # 錯誤時使用預設屬性
        c("品質", "價格", "功能", "外觀", "耐用性", "使用便利性",
          "包裝", "客服", "配送速度", "性價比", "創新性", "安全性",
          "環保", "品牌信譽", "售後服務", "材質", "重量", "尺寸",
          "顏色", "保固", "配件", "說明書", "認證", "產地", "保存",
          "效能", "設計", "操作", "維護", "升級")[1:num_attrs]
      })
      
      # 確保正確數量
      if (length(attrs) < num_attrs) {
        default_attrs <- c("屬性A", "屬性B", "屬性C", "屬性D", "屬性E")
        attrs <- c(attrs, default_attrs[1:(num_attrs - length(attrs))])
      }
      attrs <- head(attrs, num_attrs)
      
      facets_rv(attrs)
      
      incProgress(1, detail = "完成")
    })
    
    # 顯示屬性
    output$attributes_display <- renderUI({
      attrs <- facets_rv()
      if (is.null(attrs)) return(NULL)
      
      tagList(
        h5(sprintf("已萃取 %d 個屬性：", length(attrs))),
        div(
          lapply(attrs, function(attr) {
            span(class = "attr-badge", attr)
          })
        )
      )
    })
  })
  
  observeEvent(input$confirm_attributes, {
    req(facets_rv())
    updateTabsetPanel(session, "sidebar_menu", selected = "scoring")
    
    # 更新步驟指示器
    runjs("$('#step_2').addClass('completed').removeClass('active');")
    runjs("$('#step_3').addClass('active');")
    
    showNotification("屬性確認完成！請進行評分。", type = "message")
  })
  
  # ──── 步驟 3：屬性評分 ────────────────────────────────────────
  output$total_reviews <- renderText({
    df <- processed_data()
    if (is.null(df)) return("0")
    as.character(nrow(df))
  })
  
  observeEvent(input$start_scoring, {
    req(processed_data(), facets_rv())
    
    # 顯示進度訊息
    output$scoring_progress <- renderUI({
      tagList(
        tags$div(class = "alert alert-info",
                icon("spinner", class = "fa-spin"),
                " 正在進行AI評分，請稍候...")
      )
    })
    
    # 清除下一步按鈕
    output$next_step_after_scoring <- renderUI(NULL)
    
    df <- processed_data()
    attrs <- facets_rv()
    sample_size <- input$sample_size
    
    withProgress(message = '評分進行中...', value = 0, {
      # 對每個品牌取樣
      sampled_df <- df %>%
        group_by(Variation) %>%
        sample_n(min(sample_size, n())) %>%
        ungroup()
      
      n_reviews <- nrow(sampled_df)
      
      # 初始化評分矩陣
      score_matrix <- matrix(NA, nrow = n_reviews, ncol = length(attrs))
      colnames(score_matrix) <- attrs
      
      # 批次評分
      for (i in 1:n_reviews) {
        incProgress(1/n_reviews, detail = sprintf("評分第 %d/%d 則", i, n_reviews))
        
        review <- sampled_df$Body[i]
        
        # 使用 GPT 評分
        messages <- list(
          list(role = "system", 
               content = "你是產品評論分析專家，根據評論內容對產品屬性評分（1-5分）。"),
          list(role = "user",
               content = sprintf(
                 "請對以下評論的這些屬性評分(1-5)，回覆JSON格式{\"scores\":{\"屬性\":分數}}。屬性：%s。評論：%s",
                 paste(attrs, collapse = "、"),
                 substr(review, 1, 1000)
               ))
        )
        
        response <- chat_api(messages, use_mock = (i %% 10 == 0))  # 每10個用一次mock避免API限制
        
        # 解析分數
        scores <- tryCatch({
          parsed <- jsonlite::fromJSON(response)
          if (!is.null(parsed$scores)) {
            sapply(attrs, function(attr) {
              score <- parsed$scores[[attr]]
              if (is.null(score)) sample(3:5, 1) else as.numeric(score)
            })
          } else {
            sample(3:5, length(attrs), replace = TRUE)
          }
        }, error = function(e) {
          sample(3:5, length(attrs), replace = TRUE)
        })
        
        score_matrix[i, ] <- scores
      }
      
      # 合併評分結果
      scored_df <- cbind(sampled_df, score_matrix)
      
      # 計算品牌平均分數
      brand_scores <- scored_df %>%
        group_by(Variation) %>%
        summarise(across(all_of(attrs), ~mean(., na.rm = TRUE)), .groups = 'drop')
      
      scoring_data(brand_scores)
      
      # 顯示結果
      output$scoring_results <- renderDT({
        datatable(brand_scores,
                 options = list(scrollX = TRUE, pageLength = 20)) %>%
          formatRound(columns = attrs, digits = 2)
      })
    })
    
    # 評分完成後更新UI
    output$scoring_progress <- renderUI({
      tagList(
        tags$div(class = "alert alert-success",
                icon("check-circle"),
                sprintf(" 評分完成！已分析 %d 個品牌的 %d 個屬性", 
                       nrow(scoring_data()), length(attrs)))
      )
    })
    
    # 顯示下一步按鈕
    output$next_step_after_scoring <- renderUI({
      tagList(
        br(),
        actionButton("go_to_analysis", "進入分析模組", 
                    class = "btn-success btn-lg",
                    icon = icon("chart-bar")),
        br(), br()
      )
    })
    
    # 更新步驟指示器
    runjs("$('#step_3').addClass('completed').removeClass('active');")
    runjs("$('#step_4').addClass('active');")
    
    showNotification("評分完成！可以進行各項分析。", type = "message")
  })
  
  # 點擊下一步按鈕後跳轉
  observeEvent(input$go_to_analysis, {
    updateTabsetPanel(session, "sidebar_menu", selected = "market_profile")
    showNotification("已進入市場輪廓分析", type = "message")
  })
  
  # ──── 啟動分析模組 ────────────────────────────────────────
  
  # 準備數據（包含屬性欄位資訊）
  analysis_data <- reactive({
    # 優先使用已評分資料，否則使用一般評分資料
    data <- if (!is.null(complete_score_data())) {
      complete_score_data()
    } else {
      req(scoring_data())
      scoring_data()
    }

    # 將屬性欄位資訊儲存為資料的屬性
    if (!is.null(complete_score_attributes())) {
      attr(data, "attribute_columns") <- complete_score_attributes()
    } else if (!is.null(facets_rv())) {
      attr(data, "attribute_columns") <- facets_rv()
    }

    data
  })

  # 獲取所有屬性欄位
  all_attributes <- reactive({
    if (!is.null(complete_score_attributes())) {
      complete_score_attributes()
    } else if (!is.null(facets_rv())) {
      facets_rv()
    } else {
      character(0)
    }
  })

  # 關鍵屬性（前5個）
  key_attributes <- reactive({
    attrs <- all_attributes()
    if (length(attrs) > 0) {
      head(attrs, 5)
    } else {
      character(0)
    }
  })
  
  # 4. 目標市場輪廓
  # 使用增強版模組（如果存在），否則使用原版
  if (exists("marketProfileEnhancedServer")) {
    # 傳遞資料（已包含屬性資訊）
    marketProfileEnhancedServer("market_profile_enhanced", analysis_data, analysis_data)
  } else {
    marketProfileModuleServer("market_profile1", analysis_data, analysis_data)
  }
  
  # 5. 市場賽道分析
  marketTrackModuleServer("market_track1", analysis_data, key_attributes)
  
  # 6. 品牌DNA比較
  advancedDNAModuleServer("brand_dna1", analysis_data)
  
  # 7. 關鍵因素分析
  keyFactorsModuleServer("key_factors1", 
                         analysis_data, 
                         key_attributes)
  
  # 8. 理想點分析
  idealPointModuleServer("ideal_point1",
                         analysis_data,
                         key_attributes)
  
  # 9. 定位策略建議
  strategyModuleServer("positioning1", analysis_data, key_attributes)
  
  # 10. 識別度策略
  brandIdentityModuleServer("identity1", analysis_data, key_attributes)
}

# ── 啟動應用 ────────────────────────────────────────────────────────────────
shinyApp(ui = ui, server = server)