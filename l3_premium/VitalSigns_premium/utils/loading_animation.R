# 載入動畫組件
# 用於顯示 AI 分析載入狀態

library(shiny)

#' 創建載入動畫 UI
#' @param message 載入訊息
#' @param style 額外的 CSS 樣式
#' @return HTML div 元素
create_loading_ui <- function(message = "AI 分析中...", style = "") {
  div(
    style = paste0("text-align: center; padding: 20px;", style),
    div(
      class = "spinner-border text-primary",
      style = "width: 3rem; height: 3rem;",
      role = "status",
      span(class = "sr-only", "Loading...")
    ),
    br(),
    h5(message, style = "color: #666; margin-top: 15px;"),
    p("請稍候，正在為您生成智能分析建議...", style = "color: #999; font-size: 0.9em;")
  )
}

#' 創建簡單的載入動畫（使用 CSS 動畫）
#' @param id 唯一 ID
#' @param message 載入訊息
#' @return HTML div 元素
create_simple_loading <- function(id, message = "分析中...") {
  tagList(
    tags$style(HTML(paste0("
      #", id, " .loading-spinner {
        border: 4px solid #f3f3f3;
        border-top: 4px solid #3498db;
        border-radius: 50%;
        width: 40px;
        height: 40px;
        animation: spin 1s linear infinite;
        margin: 20px auto;
      }
      
      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
      
      #", id, " .loading-dots {
        display: inline-block;
        animation: dots 1.5s infinite;
      }
      
      @keyframes dots {
        0%, 20% { content: '.'; }
        40% { content: '..'; }
        60%, 100% { content: '...'; }
      }
    "))),
    div(
      id = id,
      style = "text-align: center; padding: 30px;",
      div(class = "loading-spinner"),
      h5(
        message,
        span(class = "loading-dots", "..."),
        style = "color: #666;"
      )
    )
  )
}

#' 創建帶進度的載入動畫
#' @param id 唯一 ID
#' @param steps 步驟清單
#' @return HTML div 元素
create_progress_loading <- function(id, steps = NULL) {
  if(is.null(steps)) {
    steps <- c(
      "連接 AI 服務",
      "分析數據特徵",
      "生成智能建議",
      "優化呈現格式"
    )
  }
  
  tagList(
    tags$style(HTML(paste0("
      #", id, " .step-item {
        padding: 8px 15px;
        margin: 5px 0;
        border-left: 3px solid #ddd;
        background: #f8f9fa;
        transition: all 0.3s;
      }
      
      #", id, " .step-item.active {
        border-left-color: #007bff;
        background: #e7f3ff;
        animation: pulse 1s infinite;
      }
      
      #", id, " .step-item.completed {
        border-left-color: #28a745;
        background: #d4edda;
      }
      
      @keyframes pulse {
        0% { opacity: 1; }
        50% { opacity: 0.7; }
        100% { opacity: 1; }
      }
    "))),
    div(
      id = id,
      style = "padding: 20px;",
      h5("🤖 AI 分析進行中", style = "color: #333; margin-bottom: 20px;"),
      div(
        class = "steps-container",
        lapply(seq_along(steps), function(i) {
          div(
            class = paste0("step-item", if(i == 1) " active" else ""),
            id = paste0(id, "-step-", i),
            steps[i]
          )
        })
      )
    )
  )
}

#' 創建漸進式內容載入
#' @param default_content 預設內容（立即顯示）
#' @param loading_id 載入動畫的 ID
#' @param ai_result_id AI 結果的 ID
#' @return HTML div 元素
create_progressive_content <- function(default_content, loading_id, ai_result_id) {
  div(
    # 預設內容（立即顯示）
    div(
      id = paste0(loading_id, "-default"),
      default_content
    ),
    
    # 載入動畫（初始隱藏）
    div(
      id = loading_id,
      style = "display: none;",
      create_simple_loading(paste0(loading_id, "-spinner"), "AI 分析中")
    ),
    
    # AI 結果容器（初始為空）
    div(
      id = ai_result_id
    )
  )
}

#' 更新載入狀態的 JavaScript 函數
#' @param loading_id 載入動畫 ID
#' @param show 是否顯示載入動畫
#' @return JavaScript 代碼
toggle_loading_js <- function(loading_id, show = TRUE) {
  if(show) {
    sprintf("$('#%s').show(); $('#%s-default').hide();", loading_id, loading_id)
  } else {
    sprintf("$('#%s').hide();", loading_id)
  }
}

#' 更新進度步驟狀態
#' @param id 容器 ID
#' @param step 步驟編號
#' @param status 狀態 ("active", "completed")
#' @return JavaScript 代碼
update_step_status_js <- function(id, step, status = "completed") {
  js <- sprintf(
    "$('#%s-step-%d').removeClass('active').addClass('%s');",
    id, step, status
  )
  
  if(status == "completed" && step < 4) {
    js <- paste0(
      js,
      sprintf("$('#%s-step-%d').addClass('active');", id, step + 1)
    )
  }
  
  return(js)
}