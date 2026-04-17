# 測試 AI 分析管理器
# 驗證 AI 分析結果的暫存和管理功能

library(shiny)
library(bs4Dash)
library(DT)
library(plotly)
library(shinyjs)

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
    title = "AI 分析管理器測試",
    rightUi = tags$li(
      class = "dropdown",
      tags$span(
        id = "cache_status",
        class = "badge badge-info",
        "快取狀態"
      )
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
        .ai-result-container {
          min-height: 400px;
          border: 1px solid #dee2e6;
          border-radius: 8px;
          padding: 20px;
          background: #f8f9fa;
        }
      "))
    ),
    
    fluidRow(
      # 左側：控制面板
      column(4,
        bs4Card(
          title = "🎮 測試控制面板",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          
          h5("📊 AI 管理器功能測試"),
          hr(),
          
          # 測試按鈕
          actionButton("test_single", "測試單一指標分析", 
                      class = "btn-info btn-block", icon = icon("flask")),
          br(),
          
          actionButton("test_switch", "測試指標切換", 
                      class = "btn-warning btn-block", icon = icon("exchange-alt")),
          br(),
          
          actionButton("test_cache", "測試暫存機制", 
                      class = "btn-success btn-block", icon = icon("database")),
          br(),
          
          actionButton("test_batch", "批次分析所有指標", 
                      class = "btn-danger btn-block", icon = icon("tasks")),
          br(),
          
          actionButton("clear_cache", "清除所有暫存", 
                      class = "btn-secondary btn-block", icon = icon("trash")),
          
          hr(),
          
          # 快取統計
          h5("📈 快取統計"),
          verbatimTextOutput("cache_stats"),
          
          hr(),
          
          # 測試日誌
          h5("📝 測試日誌"),
          verbatimTextOutput("test_log")
        )
      ),
      
      # 右側：DNA 模組
      column(8,
        bs4Card(
          title = "🧬 DNA 分析模組（含 AI 管理器）",
          status = "success",
          solidHeader = TRUE,
          width = 12,
          
          dnaMultiModuleUI("dna_test", enable_hints = TRUE)
        )
      )
    ),
    
    # 底部：測試結果詳情
    fluidRow(
      column(12,
        bs4Card(
          title = "🔍 AI 分析結果詳情",
          status = "info",
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = FALSE,
          width = 12,
          
          div(
            class = "ai-result-container",
            uiOutput("ai_result_display")
          )
        )
      )
    )
  )
)

# 測試 Server
server <- function(input, output, session) {
  # 創建測試用的 AI 管理器
  test_manager <- create_ai_analysis_manager()
  
  # 測試日誌
  log_messages <- reactiveVal("")
  
  add_log <- function(msg) {
    current <- log_messages()
    new_log <- paste0("[", format(Sys.time(), "%H:%M:%S"), "] ", msg, "\n", current)
    # 限制日誌長度
    lines <- strsplit(new_log, "\n")[[1]]
    if (length(lines) > 20) {
      lines <- lines[1:20]
    }
    log_messages(paste(lines, collapse = "\n"))
  }
  
  # 建立資料庫連接
  con <- tryCatch({
    get_con()
  }, error = function(e) {
    add_log(paste("⚠️ 資料庫連接失敗:", e$message))
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
    enable_hints = TRUE,
    enable_prompts = TRUE
  )
  
  # 測試單一指標分析
  observeEvent(input$test_single, {
    add_log("🧪 開始測試單一指標分析...")
    
    # 模擬數據
    test_data <- data.frame(
      customer_id = paste0("C", 1:100),
      r_value = runif(100, 1, 365),
      f_value = rpois(100, 5),
      m_value = runif(100, 10, 1000),
      stringsAsFactors = FALSE
    )
    
    # 執行分析
    result <- execute_ai_analysis(
      manager = test_manager,
      metric = "M",
      data = test_data,
      force_refresh = FALSE
    )
    
    if (!is.null(result)) {
      add_log("✅ M 指標分析完成")
    } else {
      add_log("❌ M 指標分析失敗")
    }
  })
  
  # 測試指標切換
  observeEvent(input$test_switch, {
    add_log("🔄 測試指標切換...")
    
    metrics <- c("M", "R", "F")
    for (metric in metrics) {
      test_manager$current_metric <- metric
      add_log(paste("  切換到", metric))
      Sys.sleep(0.5)
    }
    
    add_log("✅ 指標切換測試完成")
  })
  
  # 測試暫存機制
  observeEvent(input$test_cache, {
    add_log("💾 測試暫存機制...")
    
    # 第一次分析
    test_data <- data.frame(
      customer_id = paste0("C", 1:50),
      m_value = runif(50, 10, 500)
    )
    
    add_log("  第一次分析 R 指標...")
    result1 <- execute_ai_analysis(
      manager = test_manager,
      metric = "R",
      data = test_data,
      force_refresh = TRUE
    )
    
    add_log("  第二次分析 R 指標（應使用暫存）...")
    result2 <- execute_ai_analysis(
      manager = test_manager,
      metric = "R",
      data = test_data,
      force_refresh = FALSE
    )
    
    if (identical(result1, result2)) {
      add_log("✅ 暫存機制正常")
    } else {
      add_log("⚠️ 暫存可能有問題")
    }
  })
  
  # 批次分析
  observeEvent(input$test_batch, {
    add_log("🚀 開始批次分析...")
    
    test_data <- data.frame(
      customer_id = paste0("C", 1:200),
      r_value = runif(200, 1, 365),
      f_value = rpois(200, 5),
      m_value = runif(200, 10, 1000),
      cai_value = runif(200, -1, 1),
      pcv = runif(200, 100, 10000),
      cri = runif(200, 0, 100),
      nes_status = sample(c("N", "E0", "S1", "S2", "S3"), 200, replace = TRUE)
    )
    
    batch_analyze_all_metrics(
      manager = test_manager,
      data = test_data,
      metrics = c("M", "R", "F")
    )
    
    add_log("✅ 批次分析完成")
  })
  
  # 清除暫存
  observeEvent(input$clear_cache, {
    add_log("🗑️ 清除所有暫存...")
    clear_all_results(test_manager)
    add_log("✅ 暫存已清除")
  })
  
  # 顯示快取統計
  output$cache_stats <- renderText({
    invalidateLater(1000)  # 每秒更新
    
    stats <- get_cache_statistics(test_manager)
    paste0(
      "總指標數: ", stats$total_metrics, "\n",
      "已暫存: ", stats$cached_count, "\n",
      "暫存率: ", stats$cache_rate, "%\n",
      "當前指標: ", test_manager$current_metric %||% "未選擇", "\n",
      if (!is.null(stats$oldest_timestamp)) {
        paste0("最舊暫存: ", stats$oldest_metric, 
               " (", format(stats$oldest_timestamp, "%H:%M:%S"), ")")
      } else {
        "無暫存資料"
      }
    )
  })
  
  # 顯示測試日誌
  output$test_log <- renderText({
    log_messages()
  })
  
  # 顯示 AI 結果
  output$ai_result_display <- renderUI({
    if (is.null(test_manager$current_metric)) {
      return(
        div(
          class = "text-center text-muted",
          icon("robot", style = "font-size: 48px;"),
          h4("選擇指標並執行分析以查看結果")
        )
      )
    }
    
    render_ai_analysis_ui(test_manager)
  })
  
  # 更新快取狀態標籤
  observe({
    invalidateLater(1000)
    stats <- get_cache_statistics(test_manager)
    
    shinyjs::html("cache_status", 
                  paste0("快取: ", stats$cached_count, "/", stats$total_metrics))
  })
  
  # 清理資源
  onStop(function() {
    if (!is.null(con)) {
      DBI::dbDisconnect(con)
    }
  })
}

# 執行測試應用
cat("
================================================================================
AI 分析管理器測試應用
================================================================================

主要功能：
1. ✨ AI 分析結果暫存管理
2. 🔄 指標切換時保留各自的分析結果
3. 💾 智能快取機制，避免重複分析
4. 🚀 批次分析多個指標
5. 📊 即時快取統計

測試項目：
• 單一指標分析：執行並暫存單個指標的 AI 分析
• 指標切換：切換不同指標時自動載入對應的暫存結果
• 暫存機制：第二次分析相同指標時使用暫存
• 批次分析：一次分析所有指標並暫存
• 清除暫存：清空所有暫存的分析結果

優勢：
✅ 避免重複 API 調用，節省成本
✅ 提升用戶體驗，快速切換查看
✅ 分離管理邏輯，程式碼更清晰
✅ 易於擴展和維護
================================================================================
")

shinyApp(ui = ui, server = server)