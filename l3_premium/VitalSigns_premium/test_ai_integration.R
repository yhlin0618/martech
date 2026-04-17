# 測試 AI 分析管理器與 DNA 模組的整合
# 此腳本確認 AI 分析結果能正確顯示

library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(shinyjs)
library(dplyr)

# 載入所需檔案
source("utils/dna_analysis_utils.R")
source("utils/dna_ui_utils.R")
source("utils/dna_marketing_utils.R")
source("utils/ai_analysis_manager.R")
source("utils/hint_system.R")
source("utils/prompt_manager.R")
source("utils/openai_api.R")
source("modules/module_dna_multi_optimized.R")
source("database/db_connection.R")

# 測試 UI
ui <- bs4DashPage(
  header = bs4DashNavbar(
    title = "AI 整合測試",
    rightUi = tags$li(
      class = "dropdown",
      actionButton("debug_btn", "除錯資訊", class = "btn-warning btn-sm")
    )
  ),
  sidebar = bs4DashSidebar(disable = TRUE),
  body = bs4DashBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        .selected-metric {
          background-color: #007bff !important;
          color: white !important;
        }
        .metric-button {
          margin: 5px;
        }
        .debug-panel {
          background: #f8f9fa;
          border: 2px solid #dee2e6;
          border-radius: 8px;
          padding: 15px;
          margin: 15px 0;
        }
        .status-indicator {
          display: inline-block;
          width: 10px;
          height: 10px;
          border-radius: 50%;
          margin-right: 8px;
        }
        .status-active { background: #28a745; }
        .status-inactive { background: #dc3545; }
        .status-pending { background: #ffc107; }
      "))
    ),
    
    fluidRow(
      # 左側：控制與狀態
      column(4,
        bs4Card(
          title = "🎮 測試控制",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          
          h5("📊 資料載入"),
          actionButton("load_test_data", "載入測試資料", 
                      class = "btn-info btn-block", icon = icon("database")),
          br(),
          
          h5("🧬 DNA 分析"),
          actionButton("run_dna", "執行 DNA 分析", 
                      class = "btn-success btn-block", icon = icon("dna")),
          br(),
          
          h5("📈 指標切換測試"),
          div(
            class = "btn-group btn-group-sm",
            style = "width: 100%;",
            actionButton("test_m", "M", class = "btn-outline-primary"),
            actionButton("test_r", "R", class = "btn-outline-primary"),
            actionButton("test_f", "F", class = "btn-outline-primary"),
            actionButton("test_cai", "CAI", class = "btn-outline-primary")
          ),
          br(), br(),
          
          h5("🤖 AI 分析測試"),
          actionButton("test_ai_analysis", "執行 AI 分析", 
                      class = "btn-warning btn-block", icon = icon("robot")),
          br(),
          
          hr(),
          
          h5("📊 系統狀態"),
          div(
            class = "debug-panel",
            uiOutput("system_status")
          )
        )
      ),
      
      # 右側：DNA 模組
      column(8,
        bs4Card(
          title = "🧬 DNA 分析模組",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          
          dnaMultiModuleUI("dna_test", enable_hints = TRUE)
        )
      )
    ),
    
    # 底部：除錯資訊
    conditionalPanel(
      condition = "input.debug_btn % 2 == 1",
      fluidRow(
        column(12,
          bs4Card(
            title = "🔍 除錯資訊",
            status = "danger",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            
            h5("AI 管理器狀態"),
            verbatimTextOutput("ai_manager_state"),
            
            h5("當前 Values"),
            verbatimTextOutput("current_values"),
            
            h5("執行日誌"),
            verbatimTextOutput("execution_log")
          )
        )
      )
    )
  )
)

# 測試 Server
server <- function(input, output, session) {
  # 日誌系統
  log_messages <- reactiveVal("")
  
  add_log <- function(msg, type = "info") {
    current <- log_messages()
    timestamp <- format(Sys.time(), "%H:%M:%S")
    icon <- switch(type,
      "success" = "✅",
      "error" = "❌",
      "warning" = "⚠️",
      "info" = "ℹ️"
    )
    new_log <- paste0("[", timestamp, "] ", icon, " ", msg, "\n", current)
    # 限制日誌長度
    lines <- strsplit(new_log, "\n")[[1]]
    if (length(lines) > 50) {
      lines <- lines[1:50]
    }
    log_messages(paste(lines, collapse = "\n"))
  }
  
  # 測試資料
  test_data <- reactiveVal(NULL)
  
  # 建立資料庫連接
  con <- tryCatch({
    add_log("連接資料庫...", "info")
    conn <- get_con()
    add_log("資料庫連接成功", "success")
    conn
  }, error = function(e) {
    add_log(paste("資料庫連接失敗:", e$message), "error")
    NULL
  })
  
  # 模擬使用者資訊
  user_info <- reactive({
    list(user_id = 1, username = "test_user")
  })
  
  # 初始化 DNA 模組
  dna_results <- dnaMultiModuleServer(
    "dna_test",
    con = con,
    user_info = user_info,
    uploaded_dna_data = test_data,
    enable_hints = TRUE,
    enable_prompts = TRUE
  )
  
  # 載入測試資料
  observeEvent(input$load_test_data, {
    add_log("載入測試資料...", "info")
    
    # 生成測試資料
    set.seed(123)
    n_customers <- 500
    
    data <- data.frame(
      customer_id = paste0("CUST", sprintf("%04d", 1:n_customers)),
      r_value = round(runif(n_customers, 1, 365)),
      f_value = rpois(n_customers, lambda = 5) + 1,
      m_value = round(runif(n_customers, 100, 10000)),
      stringsAsFactors = FALSE
    )
    
    # 添加額外欄位
    data$last_purchase_date <- Sys.Date() - data$r_value
    data$total_spent <- data$m_value * data$f_value
    
    test_data(data)
    add_log(paste("已載入", nrow(data), "筆測試資料"), "success")
  })
  
  # 執行 DNA 分析
  observeEvent(input$run_dna, {
    if (is.null(test_data())) {
      add_log("請先載入測試資料", "warning")
      return()
    }
    
    add_log("觸發 DNA 分析...", "info")
    
    # 模擬點擊 DNA 模組的分析按鈕
    shinyjs::click("dna_test-analyze_button")
    
    add_log("DNA 分析已觸發", "success")
  })
  
  # 測試指標切換
  observeEvent(input$test_m, {
    add_log("切換到 M 指標", "info")
    shinyjs::click("dna_test-show_m")
  })
  
  observeEvent(input$test_r, {
    add_log("切換到 R 指標", "info")
    shinyjs::click("dna_test-show_r")
  })
  
  observeEvent(input$test_f, {
    add_log("切換到 F 指標", "info")
    shinyjs::click("dna_test-show_f")
  })
  
  observeEvent(input$test_cai, {
    add_log("切換到 CAI 指標", "info")
    shinyjs::click("dna_test-show_cai")
  })
  
  # 測試 AI 分析
  observeEvent(input$test_ai_analysis, {
    add_log("觸發 AI 分析...", "info")
    
    # 模擬點擊 AI 分析按鈕
    shinyjs::click("dna_test-run_ai_analysis")
    
    add_log("AI 分析已觸發", "success")
  })
  
  # 系統狀態顯示
  output$system_status <- renderUI({
    tagList(
      div(
        span(class = if(!is.null(con)) "status-indicator status-active" else "status-indicator status-inactive"),
        "資料庫連接：", if(!is.null(con)) "已連接" else "未連接"
      ),
      br(),
      div(
        span(class = if(!is.null(test_data())) "status-indicator status-active" else "status-indicator status-inactive"),
        "測試資料：", if(!is.null(test_data())) paste(nrow(test_data()), "筆") else "未載入"
      ),
      br(),
      div(
        span(class = "status-indicator status-pending"),
        "DNA 模組：運行中"
      )
    )
  })
  
  # AI 管理器狀態（嘗試從模組內部獲取）
  output$ai_manager_state <- renderPrint({
    # 這裡無法直接訪問模組內部的 ai_manager
    # 但可以顯示一般狀態
    list(
      "模組已載入" = TRUE,
      "AI 功能啟用" = !is.null(Sys.getenv("OPENAI_API_KEY")) && Sys.getenv("OPENAI_API_KEY") != "",
      "當前時間" = Sys.time()
    )
  })
  
  # 當前 Values
  output$current_values <- renderPrint({
    if (!is.null(dna_results)) {
      result <- dna_results()
      if (!is.null(result)) {
        list(
          "DNA 分析完成" = !is.null(result$dna_results),
          "客戶數" = if(!is.null(result$dna_results)) nrow(result$dna_results$data_by_customer) else 0,
          "當前指標" = result$current_metric
        )
      } else {
        "等待分析結果..."
      }
    } else {
      "模組未初始化"
    }
  })
  
  # 執行日誌
  output$execution_log <- renderText({
    log_messages()
  })
  
  # 清理資源
  onStop(function() {
    if (!is.null(con)) {
      DBI::dbDisconnect(con)
      add_log("資料庫連接已關閉", "info")
    }
  })
}

# 執行測試應用
cat("
================================================================================
AI 整合測試應用
================================================================================

測試步驟：
1. 點擊「載入測試資料」載入模擬資料
2. 點擊「執行 DNA 分析」進行分析
3. 使用指標切換按鈕測試不同指標
4. 點擊「執行 AI 分析」測試 AI 功能
5. 觀察右側 AI 深度分析結果區域

預期行為：
- 未執行 AI 分析時顯示「請先執行 AI 分析」
- 執行後顯示分析結果
- 切換指標時保留各自的分析結果
- 重新執行時更新當前指標的結果

除錯：
- 點擊右上角「除錯資訊」查看詳細狀態
- 檢查執行日誌了解運行過程

================================================================================
")

shinyApp(ui = ui, server = server)