# 測試營收脈能模組更新
# 驗證美金標示、AI分析、80/20法則等功能

library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(dplyr)
library(shinyjs)

# 載入所需模組
source("database/db_connection.R")
source("utils/hint_system.R")
source("utils/prompt_manager.R")
source("modules/module_dna_multi_optimized.R")
source("modules/module_revenue_pulse.R")

# 測試 UI
ui <- bs4DashPage(
  header = bs4DashNavbar(
    title = "營收脈能測試",
    rightUi = tags$li(
      class = "dropdown",
      tags$span(
        class = "badge badge-success",
        "測試版本"
      )
    )
  ),
  sidebar = bs4DashSidebar(disable = TRUE),
  body = bs4DashBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        .content-wrapper { background: #f4f4f4; }
        .small-box { transition: all 0.3s; }
        .small-box:hover { transform: translateY(-5px); box-shadow: 0 5px 20px rgba(0,0,0,0.1); }
      "))
    ),
    
    fluidRow(
      column(12,
        h2("📊 營收脈能模組測試", style = "color: #2c3e50; margin-bottom: 30px;")
      )
    ),
    
    fluidRow(
      # 控制面板
      column(3,
        bs4Card(
          title = "測試控制",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          
          h5("1️⃣ 載入測試資料"),
          actionButton("load_test_data", "載入模擬資料", 
                      class = "btn-info btn-block", icon = icon("database")),
          br(),
          
          h5("2️⃣ 執行 DNA 分析"),
          actionButton("run_dna_analysis", "執行分析", 
                      class = "btn-success btn-block", icon = icon("dna")),
          br(),
          
          hr(),
          
          h5("📋 測試清單"),
          div(
            style = "background: #f8f9fa; padding: 10px; border-radius: 5px;",
            tags$ul(
              style = "margin: 0; padding-left: 20px;",
              tags$li("✅ 美金標示"),
              tags$li("✅ 交易穩定度說明"),
              tags$li("✅ 新客數據顯示"),
              tags$li("✅ 80/20法則分群"),
              tags$li("✅ AI自動分析"),
              tags$li("✅ 日期軸修正")
            )
          ),
          
          hr(),
          
          h5("🔍 系統狀態"),
          verbatimTextOutput("system_status")
        )
      ),
      
      # 營收脈能模組
      column(9,
        revenuePulseModuleUI("revenue_test", enable_hints = TRUE)
      )
    ),
    
    # 測試結果
    fluidRow(
      column(12,
        bs4Card(
          title = "測試結果",
          status = "info",
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = TRUE,
          width = 12,
          verbatimTextOutput("test_results")
        )
      )
    )
  )
)

# 測試 Server
server <- function(input, output, session) {
  # 測試資料
  test_data <- reactiveVal(NULL)
  dna_results <- reactiveVal(NULL)
  test_log <- reactiveVal("")
  
  # 新增日誌
  add_log <- function(msg) {
    current <- test_log()
    test_log(paste0(current, "[", format(Sys.time(), "%H:%M:%S"), "] ", msg, "\n"))
  }
  
  # 載入測試資料
  observeEvent(input$load_test_data, {
    add_log("載入測試資料...")
    
    set.seed(123)
    n_customers <- 500
    
    # 生成測試資料
    data <- data.frame(
      customer_id = paste0("CUST", sprintf("%04d", 1:n_customers)),
      r_value = round(runif(n_customers, 1, 365)),
      f_value = rpois(n_customers, lambda = 5) + 1,
      m_value = round(runif(n_customers, 100, 5000)),
      stringsAsFactors = FALSE
    )
    
    # 計算衍生欄位
    data$last_purchase_date <- Sys.Date() - data$r_value
    data$total_spent <- data$m_value * data$f_value
    data$times <- data$f_value
    
    # 計算 CLV (簡化版)
    data$clv <- data$total_spent * 1.5  # 假設未來價值為歷史價值的1.5倍
    
    # 計算 CRI (Customer Regularity Index)
    data$cri <- runif(n_customers, 0.3, 0.9)
    
    # 設定 NES 狀態
    data$nes_status <- sample(c("N", "E0", "S1", "S2", "S3"), 
                             n_customers, 
                             replace = TRUE, 
                             prob = c(0.2, 0.3, 0.2, 0.2, 0.1))
    
    test_data(data)
    add_log(paste("✅ 已載入", nrow(data), "筆測試資料"))
  })
  
  # 執行 DNA 分析
  observeEvent(input$run_dna_analysis, {
    req(test_data())
    add_log("執行 DNA 分析...")
    
    # 模擬 DNA 分析結果
    dna_results(list(
      data_by_customer = test_data()
    ))
    
    add_log("✅ DNA 分析完成")
  })
  
  # 模擬使用者資訊
  user_info <- reactive({
    list(user_id = 1, username = "test_user")
  })
  
  # 模擬 DNA 模組結果
  dna_module_result <- reactive({
    if (!is.null(dna_results())) {
      list(dna_results = dna_results())
    } else {
      NULL
    }
  })
  
  # 模擬時間序列資料
  time_series_data <- list(
    monthly_data = reactive({
      # 生成模擬月度資料
      months <- seq(as.Date("2023-01-01"), as.Date("2023-12-01"), by = "month")
      revenue <- cumsum(runif(12, 50000, 150000))
      growth <- c(NA, diff(revenue) / head(revenue, -1) * 100)
      
      data.frame(
        period_date = months,
        revenue = revenue,
        revenue_growth = growth
      )
    })
  )
  
  # 建立資料庫連接（測試用）
  con <- tryCatch({
    get_con()
  }, error = function(e) {
    add_log(paste("⚠️ 資料庫連接失敗:", e$message))
    NULL
  })
  
  # 初始化營收脈能模組
  revenue_results <- revenuePulseModuleServer(
    "revenue_test",
    con = con,
    user_info = user_info,
    dna_module_result = dna_module_result,
    time_series_data = time_series_data,
    enable_hints = TRUE
  )
  
  # 系統狀態
  output$system_status <- renderText({
    status <- c(
      paste("資料狀態:", if(!is.null(test_data())) "已載入" else "未載入"),
      paste("DNA分析:", if(!is.null(dna_results())) "已完成" else "未執行"),
      paste("資料庫:", if(!is.null(con)) "已連接" else "未連接"),
      paste("Hints系統:", "已啟用"),
      paste("AI分析:", "已整合")
    )
    paste(status, collapse = "\n")
  })
  
  # 測試結果
  output$test_results <- renderText({
    test_log()
  })
  
  # 清理資源
  onStop(function() {
    if (!is.null(con)) {
      DBI::dbDisconnect(con)
    }
  })
}

# 顯示測試說明
cat("
================================================================================
營收脈能模組測試
================================================================================

主要測試項目：
1. ✅ 美金標示 - KPI卡片應顯示 $ 符號
2. ✅ 交易穩定度 - 滑鼠移到標題會顯示說明
3. ✅ 客單價分析 - 顯示順序：全體平均、新客、主力客
4. ✅ CLV分布 - 使用80/20法則分三群
5. ✅ AI分析 - 自動顯示在各圖表下方
6. ✅ 日期軸 - 月度顯示應正確不重複

測試步驟：
1. 點擊「載入模擬資料」
2. 點擊「執行分析」
3. 檢視營收脈能各項指標
4. 確認AI分析自動顯示
5. 測試下載CLV分群名單

預期結果：
- KPI卡片顯示美金符號
- 交易穩定度有詳細說明
- AI分析自動執行並顯示建議
- CLV使用80/20法則分三群
- 可下載客戶分群名單

================================================================================
")

shinyApp(ui = ui, server = server)