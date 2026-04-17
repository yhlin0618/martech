# Reactive 載入動畫助手
# 專門處理自動執行的 reactive AI 分析

library(shiny)

#' 創建具有載入狀態的 reactive
#' @param expr 要執行的表達式
#' @param loading_message 載入訊息
#' @param delay 延遲時間（秒）
#' @return reactive 值
reactiveWithLoading <- function(expr, loading_message = "分析中...", delay = 0.5) {
  loading_state <- reactiveVal(TRUE)
  result <- reactiveVal(NULL)
  
  observe({
    # 設置載入狀態
    loading_state(TRUE)
    
    # 延遲執行以顯示載入動畫
    invalidateLater(delay * 1000)
    
    # 執行實際分析
    tryCatch({
      val <- expr
      result(val)
      loading_state(FALSE)
    }, error = function(e) {
      result(NULL)
      loading_state(FALSE)
    })
  })
  
  # 返回包含狀態的列表
  reactive({
    list(
      loading = loading_state(),
      value = result()
    )
  })
}

#' 渲染具有載入動畫的 UI
#' @param data_reactive 包含載入狀態的 reactive
#' @param render_function 渲染函數
#' @param loading_ui 載入時顯示的 UI
#' @return renderUI 對象
renderUIWithLoading <- function(data_reactive, 
                                render_function, 
                                loading_ui = NULL) {
  renderUI({
    data <- data_reactive()
    
    if(is.null(loading_ui)) {
      loading_ui <- div(
        style = "text-align: center; padding: 30px;",
        icon("spinner", class = "fa-spin fa-2x", style = "color: #3498db;"),
        br(),
        h5("分析中...", style = "color: #666; margin-top: 10px;")
      )
    }
    
    if(data$loading) {
      return(loading_ui)
    } else if(!is.null(data$value)) {
      return(render_function(data$value))
    } else {
      return(div(
        style = "text-align: center; padding: 20px; color: #999;",
        p("無資料可顯示")
      ))
    }
  })
}

#' 創建漸進式載入效果
#' @param steps 載入步驟
#' @param current_step 當前步驟
#' @return UI 元素
create_step_loading <- function(steps, current_step = 1) {
  div(
    style = "padding: 20px;",
    h5("🤖 AI 分析進行中", style = "color: #333; margin-bottom: 20px;"),
    div(
      class = "progress",
      style = "height: 25px;",
      div(
        class = "progress-bar progress-bar-striped progress-bar-animated",
        role = "progressbar",
        style = paste0("width: ", (current_step / length(steps)) * 100, "%;"),
        paste0(current_step, "/", length(steps))
      )
    ),
    p(
      style = "margin-top: 15px; color: #666;",
      icon("clock-o"),
      " ",
      steps[current_step]
    )
  )
}

#' 創建脈動載入效果
#' @param message 訊息
#' @param icon_name 圖標名稱
#' @return UI 元素
create_pulse_loading <- function(message = "AI 分析中...", icon_name = "robot") {
  tagList(
    tags$style(HTML("
      @keyframes pulse {
        0% { transform: scale(1); opacity: 1; }
        50% { transform: scale(1.1); opacity: 0.7; }
        100% { transform: scale(1); opacity: 1; }
      }
      .pulse-icon {
        animation: pulse 2s infinite;
        display: inline-block;
      }
    ")),
    div(
      style = "text-align: center; padding: 30px; background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); border-radius: 10px;",
      div(
        class = "pulse-icon",
        icon(icon_name, "fa-3x", style = "color: #4a90e2;")
      ),
      h4(message, style = "color: #333; margin-top: 20px;"),
      p("請稍候，正在為您生成深度分析...", style = "color: #666;")
    )
  )
}