# 客戶增長模組測試
# 驗證所有更新功能

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
source("modules/module_wo_b.R")  # 載入 chat_api
source("modules/module_customer_acquisition.R")

# 測試 UI
ui <- bs4DashPage(
  header = bs4DashNavbar(
    title = "客戶增長測試",
    rightUi = tags$li(
      class = "dropdown",
      tags$span(
        class = "badge badge-success",
        "Test Mode"
      )
    )
  ),
  sidebar = bs4DashSidebar(disable = TRUE),
  body = bs4DashBody(
    useShinyjs(),
    
    fluidRow(
      column(12,
        h2("🚀 客戶增長功能驗證", style = "color: #2c3e50; margin-bottom: 30px;")
      )
    ),
    
    fluidRow(
      # 測試控制
      column(3,
        bs4Card(
          title = "測試項目",
          status = "primary",
          solidHeader = TRUE,
          width = 12,
          
          actionButton("generate_data", "生成測試資料", 
                      class = "btn-info btn-block", icon = icon("database")),
          br(),
          
          h5("✅ 驗證清單"),
          div(
            style = "background: #f8f9fa; padding: 15px; border-radius: 5px;",
            
            h6("1. KPI 定義說明"),
            p("• 顧客總數 tooltip", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 累積顧客數 tooltip", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 顧客新增率 tooltip", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 顧客變動率 tooltip", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("2. 獲客漏斗"),
            p("• 移除「潛在客戶」", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 從「首次購買」開始", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("3. AI 分析"),
            p("• 顧客新增率分析", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 顧客變動率分析", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 集中呈現在下方", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("4. 資料整合"),
            p("• hint.csv 已更新", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• prompt.csv 已更新", style = "margin: 0 0 5px 20px; font-size: 12px;")
          )
        )
      ),
      
      # 客戶增長模組
      column(9,
        customerAcquisitionModuleUI("customer_acquisition1", enable_hints = TRUE)
      )
    )
  )
)

# 測試 Server
server <- function(input, output, session) {
  # 測試資料
  test_data <- reactiveVal(NULL)
  
  # 生成測試資料
  observeEvent(input$generate_data, {
    set.seed(123)
    n <- 500
    
    # 生成客戶資料
    customers <- data.frame(
      customer_id = paste0("C", sprintf("%04d", 1:n)),
      r_value = round(rexp(n, 1/45)),  # 指數分布的 R 值
      f_value = rpois(n, lambda = 4) + 1,  # Poisson 分布的 F 值
      m_value = round(rlnorm(n, meanlog = 5, sdlog = 1.2) * 100),  # 對數常態分布的 M 值
      stringsAsFactors = FALSE
    )
    
    # 計算衍生欄位
    customers$total_spent <- customers$m_value * customers$f_value
    customers$times <- customers$f_value
    
    # 設定 NES 狀態（模擬真實客戶分布）
    customers$nes_status <- sample(
      c("N", "E0", "S1", "S2", "S3"),
      n,
      replace = TRUE,
      prob = c(0.25, 0.35, 0.15, 0.15, 0.10)  # 新客戶25%, 主力客戶35%, 沉睡客戶分級
    )
    
    test_data(customers)
    
    showNotification("✅ 測試資料已生成", type = "success")
  })
  
  # 模擬 DNA 結果
  dna_module_result <- reactive({
    if (!is.null(test_data())) {
      list(dna_results = list(data_by_customer = test_data()))
    } else {
      NULL
    }
  })
  
  # 模擬時間序列資料
  time_series_data <- list(
    monthly_data = reactive({
      # 生成 12 個月的資料
      months <- seq(as.Date("2023-01-01"), as.Date("2023-12-01"), by = "month")
      base_customers <- 100
      
      # 生成有成長趨勢的客戶數
      customers <- numeric(12)
      for(i in 1:12) {
        growth <- base_customers * (1 + 0.03 * i)  # 3% 月成長
        seasonal <- sin(2 * pi * i / 12) * 10  # 季節性波動
        noise <- rnorm(1, 0, 5)  # 隨機噪音
        customers[i] <- round(growth + seasonal + noise)
      }
      
      # 計算成長率
      growth <- c(NA, diff(customers) / head(customers, -1) * 100)
      
      data.frame(
        period_date = months,
        customers = customers,
        customer_growth = growth
      )
    })
  )
  
  # 資料庫連接
  con <- tryCatch({
    get_con()
  }, error = function(e) {
    NULL
  })
  
  # 使用者資訊
  user_info <- reactive({
    list(user_id = 1, username = "test_user")
  })
  
  # 初始化客戶增長模組
  acquisition_results <- customerAcquisitionModuleServer(
    "customer_acquisition1",
    con = con,
    user_info = user_info,
    dna_module_result = dna_module_result,
    time_series_data = time_series_data,
    enable_hints = TRUE,
    enable_gpt = !is.null(Sys.getenv("OPENAI_API_KEY")) && Sys.getenv("OPENAI_API_KEY") != "",
    chat_api = if(exists("chat_api")) chat_api else NULL
  )
  
  # 初始生成資料
  observe({
    isolate({
      if(is.null(test_data())) {
        shinyjs::click("generate_data")
      }
    })
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
客戶增長模組測試
================================================================================

🎯 主要更新：

1. KPI 定義說明
   - 每個 KPI 都有 tooltip 提示
   - 滑鼠懸停可看到詳細說明
   - 從 hint.csv 讀取定義

2. 獲客漏斗優化
   - 移除「潛在客戶」階段
   - 從「首次購買」開始計算
   - 更準確反映實際客戶狀態

3. AI 分析功能
   - 顧客新增率分析（與行業基準比較）
   - 顧客變動率分析（客戶池健康度）
   - 集中在下方顯示所有分析結果

4. 資料整合
   - hint.csv 新增 4 個客戶增長相關定義
   - prompt.csv 新增 2 個 AI 分析 prompt

測試步驟：
1. 點擊「生成測試資料」（會自動執行）
2. 檢視 KPI 卡片的 tooltip（滑鼠懸停）
3. 檢查獲客漏斗（應該沒有潛在客戶）
4. 查看 AI 分析結果（在頁面底部）

================================================================================
")

shinyApp(ui = ui, server = server)