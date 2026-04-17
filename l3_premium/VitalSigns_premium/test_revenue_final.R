# 營收脈能模組最終測試
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
source("modules/module_revenue_pulse.R")

# 測試 UI
ui <- bs4DashPage(
  header = bs4DashNavbar(
    title = "營收脈能最終測試",
    rightUi = tags$li(
      class = "dropdown",
      tags$span(
        class = "badge badge-primary",
        "Final Test"
      )
    )
  ),
  sidebar = bs4DashSidebar(disable = TRUE),
  body = bs4DashBody(
    useShinyjs(),
    
    fluidRow(
      column(12,
        h2("🎯 營收脈能功能驗證", style = "color: #2c3e50; margin-bottom: 30px;")
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
            
            h6("1. CLV 分布圖"),
            p("• 散點圖顯示每個客戶", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 顯示中位數和平均值", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 四分位範圍區域", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("2. 日期軸修正"),
            p("• 月份正確顯示", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 無重複標籤", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("3. AI 分析"),
            p("• 自動執行分析", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• GPT 整合（如啟用）", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 顯示行銷建議", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("4. 美金標示"),
            p("• 所有金額顯示 $", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• KPI 卡片標示美金", style = "margin: 0 0 5px 20px; font-size: 12px;")
          )
        )
      ),
      
      # 營收脈能模組
      column(9,
        revenuePulseModuleUI("revenue_final", enable_hints = TRUE)
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
    set.seed(42)
    n <- 300
    
    # 生成客戶資料
    customers <- data.frame(
      customer_id = paste0("C", sprintf("%04d", 1:n)),
      r_value = round(rexp(n, 1/30)),  # 指數分布的 R 值
      f_value = rpois(n, lambda = 3) + 1,  # Poisson 分布的 F 值
      m_value = round(rlnorm(n, meanlog = 5, sdlog = 1.5) * 100),  # 對數常態分布的 M 值
      stringsAsFactors = FALSE
    )
    
    # 計算衍生欄位
    customers$total_spent <- customers$m_value * customers$f_value
    customers$times <- customers$f_value
    
    # 計算 CLV (使用更真實的分布)
    customers$clv <- customers$total_spent * (1 + runif(n, 0.2, 2))
    
    # 設定 CRI
    customers$cri <- pmin(1, pmax(0, 
      0.3 * (1 - customers$r_value/365) + 
      0.3 * (customers$f_value/10) + 
      0.4 * (customers$m_value/5000)
    ))
    
    # 設定 NES 狀態
    customers$nes_status <- cut(
      customers$total_spent,
      breaks = quantile(customers$total_spent, c(0, 0.2, 0.4, 0.6, 0.8, 1)),
      labels = c("N", "E0", "S1", "S2", "S3"),
      include.lowest = TRUE
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
      base_revenue <- 100000
      
      # 生成有趨勢和季節性的收入
      revenue <- numeric(12)
      for(i in 1:12) {
        trend <- base_revenue * (1 + 0.02 * i)  # 2% 月成長
        seasonal <- sin(2 * pi * i / 12) * 20000  # 季節性波動
        noise <- rnorm(1, 0, 5000)  # 隨機噪音
        revenue[i] <- trend + seasonal + noise
      }
      
      # 計算成長率
      growth <- c(NA, diff(revenue) / head(revenue, -1) * 100)
      
      data.frame(
        period_date = months,
        revenue = revenue,
        revenue_growth = growth
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
  
  # 初始化營收脈能模組
  revenue_results <- revenuePulseModuleServer(
    "revenue_final",
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
營收脈能最終測試
================================================================================

🎯 主要更新：

1. CLV 分布圖改為散點圖
   - 每個點代表一個客戶
   - 顯示中位數（黑線）和平均值（紅色鑽石）
   - 灰色區域表示四分位範圍

2. 日期軸修正
   - 使用 type = 'date' 確保正確解析
   - 設定 dtick = 'M1' 避免重複

3. AI 分析整合
   - 自動執行，無需按鈕
   - 如有 API Key 會使用 GPT 分析
   - 無 API Key 時使用預設建議

4. 美金標示
   - 所有 KPI 卡片標示「(美金)」
   - 數值前加 $ 符號

測試步驟：
1. 點擊「生成測試資料」（會自動執行）
2. 檢視各項圖表和 AI 分析結果

================================================================================
")

shinyApp(ui = ui, server = server)