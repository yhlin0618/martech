# 客戶留存模組測試
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
source("modules/module_customer_retention_new.R")

# 測試 UI
ui <- bs4DashPage(
  header = bs4DashNavbar(
    title = "客戶留存模組測試",
    rightUi = tags$li(
      class = "dropdown",
      tags$span(
        class = "badge badge-warning",
        "Test Mode"
      )
    )
  ),
  sidebar = bs4DashSidebar(disable = TRUE),
  body = bs4DashBody(
    useShinyjs(),
    
    fluidRow(
      column(12,
        h2("🔒 客戶留存功能驗證", style = "color: #2c3e50; margin-bottom: 30px;")
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
            
            h6("1. KPI 定義提示"),
            p("• 留存率 tooltip ✓", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 流失率 tooltip ✓", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 風險客戶 tooltip ✓", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 主力客比率 tooltip ✓", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("2. 新增方框"),
            p("• 靜止戶預測 ✓", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 首購客 (N) ✓", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 瞌睡客 (S1) ✓", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 沉睡客 (S3) ✓", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("3. 客戶狀態順序"),
            p("• N→E0→S1→S2→S3 ✓", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("4. CSV 下載"),
            p("• 結構 CSV ✓", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 風險 CSV ✓", style = "margin: 0 0 10px 20px; font-size: 12px;"),
            
            h6("5. AI 分析"),
            p("• 5個分頁式分析 ✓", style = "margin: 0 0 5px 20px; font-size: 12px;"),
            p("• 集中在下方 ✓", style = "margin: 0 0 5px 20px; font-size: 12px;")
          )
        )
      ),
      
      # 客戶留存模組
      column(9,
        customerRetentionModuleUI("customer_retention1", enable_hints = TRUE)
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
    set.seed(456)
    n <- 600
    
    # 生成客戶資料，確保有適當的 NES 狀態分布
    customers <- data.frame(
      customer_id = paste0("C", sprintf("%04d", 1:n)),
      stringsAsFactors = FALSE
    )
    
    # 設定 NES 狀態（按照正確順序 N, E0, S1, S2, S3）
    # 確保首購客(N)有適當數量
    customers$nes_status <- sample(
      c("N", "E0", "S1", "S2", "S3"),
      n,
      replace = TRUE,
      prob = c(0.15, 0.40, 0.15, 0.15, 0.15)  # 調整比例使首購客不為0
    )
    
    # 根據狀態設定其他屬性
    customers <- customers %>%
      mutate(
        r_value = case_when(
          nes_status == "N" ~ runif(n(), 1, 30),
          nes_status == "E0" ~ runif(n(), 5, 20),
          nes_status == "S1" ~ runif(n(), 30, 60),
          nes_status == "S2" ~ runif(n(), 60, 90),
          nes_status == "S3" ~ runif(n(), 90, 180),
          TRUE ~ runif(n(), 1, 180)
        ),
        f_value = case_when(
          nes_status == "N" ~ 1,
          nes_status == "E0" ~ rpois(n(), lambda = 8) + 5,
          nes_status == "S1" ~ rpois(n(), lambda = 3) + 2,
          nes_status == "S2" ~ rpois(n(), lambda = 2) + 1,
          nes_status == "S3" ~ rpois(n(), lambda = 1) + 1,
          TRUE ~ rpois(n(), lambda = 3) + 1
        ),
        m_value = case_when(
          nes_status == "N" ~ rlnorm(n(), meanlog = 4, sdlog = 0.5) * 100,
          nes_status == "E0" ~ rlnorm(n(), meanlog = 5, sdlog = 0.5) * 100,
          nes_status == "S1" ~ rlnorm(n(), meanlog = 4.5, sdlog = 0.5) * 100,
          nes_status == "S2" ~ rlnorm(n(), meanlog = 4, sdlog = 0.5) * 100,
          nes_status == "S3" ~ rlnorm(n(), meanlog = 3.5, sdlog = 0.5) * 100,
          TRUE ~ rlnorm(n(), meanlog = 4, sdlog = 0.5) * 100
        )
      )
    
    # 計算衍生欄位
    customers$total_spent <- customers$m_value * customers$f_value
    customers$times <- customers$f_value
    
    test_data(customers)
    
    # 顯示統計
    status_counts <- table(customers$nes_status)
    showNotification(
      paste("✅ 測試資料已生成",
            "\nN:", status_counts["N"],
            "E0:", status_counts["E0"],
            "S1:", status_counts["S1"],
            "S2:", status_counts["S2"],
            "S3:", status_counts["S3"]),
      type = "success",
      duration = 5
    )
  })
  
  # 模擬 DNA 結果
  dna_module_result <- reactive({
    if (!is.null(test_data())) {
      list(dna_results = list(data_by_customer = test_data()))
    } else {
      NULL
    }
  })
  
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
  
  # 初始化客戶留存模組
  retention_results <- customerRetentionModuleServer(
    "customer_retention1",
    con = con,
    user_info = user_info,
    dna_module_result = dna_module_result,
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
客戶留存模組測試
================================================================================

🎯 主要更新：

1. KPI 定義說明 ✓
   - 留存率、流失率、風險客戶、主力客比率都有 tooltip

2. 新增客戶狀態方框 ✓
   - 靜止戶預測（30天內）
   - 首購客 (N)
   - 主力客 (E0)
   - 瞌睡客 (S1)
   - 半睡客 (S2)
   - 沉睡客 (S3)

3. 客戶狀態結構 ✓
   - 順序：N→E0→S1→S2→S3
   - 可下載 CSV

4. 流失風險分析 ✓
   - 按風險等級分類
   - 可下載 CSV

5. AI 分析建議 ✓
   - 5個分頁：留存分析、首購客策略、瞌睡客喚醒、沉睡客激活、結構優化
   - 集中顯示在下方
   - 支援 GPT API（如有設定）

測試步驟：
1. 點擊「生成測試資料」（會自動執行）
2. 檢視各 KPI 卡片和 tooltip
3. 檢查客戶狀態順序
4. 測試 CSV 下載功能
5. 查看 AI 分析分頁

注意：
- 已移除與 TagPilot 重複的圖表
- AI 分析需要設定 OPENAI_API_KEY 才會使用 GPT

================================================================================
")

shinyApp(ui = ui, server = server)