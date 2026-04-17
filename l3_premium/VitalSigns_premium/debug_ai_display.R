# 簡單除錯腳本：測試 AI 分析結果顯示

library(shiny)

# 載入 AI 管理器
source("utils/ai_analysis_manager.R")

# 創建測試應用
ui <- fluidPage(
  h2("AI 分析顯示測試"),
  
  actionButton("test_no_result", "測試無結果狀態"),
  actionButton("test_with_result", "測試有結果狀態"),
  actionButton("test_loading", "測試載入中狀態"),
  
  hr(),
  
  h3("AI 分析結果："),
  uiOutput("ai_display")
)

server <- function(input, output, session) {
  # 創建 AI 管理器
  ai_manager <- create_ai_analysis_manager()
  
  # 測試無結果狀態
  observeEvent(input$test_no_result, {
    ai_manager$current_metric <- "M"
    ai_manager$results_cache[["M"]] <- NULL
    ai_manager$is_analyzing <- FALSE
  })
  
  # 測試有結果狀態
  observeEvent(input$test_with_result, {
    ai_manager$current_metric <- "M"
    
    # 模擬分析結果（HTML 格式）
    test_result <- list(
      summary = "<div style='padding: 15px;'>
        <h5>📊 購買金額分析摘要</h5>
        <p><b>分析時間：</b>2025-08-13 20:46:46</p>
        <p><b>總客戶數：</b>240 人</p>
        <p>240 list(segment = 1:2, count = c(52, 188), avg_r = c(4.42307692307692, 
3.95744680851064), avg_f = c(1, 2.22872340425532), avg_m = c(44.8496153846154, 
67.3127127659574), total_revenue = c(2332.18, 33224.1099999999)) F
1755089196.24364</p>
        </div>",
      recommendations = list(
        strategy = "基於購買金額的精準行銷策略",
        actions = c(
          "針對高價值客戶提供 VIP 專屬優惠",
          "為中等消費客戶設計升級方案",
          "使用入門優惠吸引低消費客戶"
        )
      ),
      timestamp = Sys.time(),
      metric = "M"
    )
    
    store_analysis_result(ai_manager, "M", test_result)
    ai_manager$is_analyzing <- FALSE
  })
  
  # 測試載入中狀態
  observeEvent(input$test_loading, {
    ai_manager$current_metric <- "M"
    ai_manager$is_analyzing <- TRUE
  })
  
  # 顯示 AI 分析結果
  output$ai_display <- renderUI({
    render_ai_analysis_ui(ai_manager)
  })
}

# 執行測試
cat("
================================================================================
AI 分析顯示測試
================================================================================

點擊按鈕測試不同狀態：
1. 無結果狀態 - 應顯示「請先執行 AI 分析」
2. 有結果狀態 - 應顯示分析結果
3. 載入中狀態 - 應顯示載入動畫

檢查顯示是否正確。

================================================================================
")

shinyApp(ui, server)