# AI 載入動畫管理器
# 統一管理所有 AI 分析的載入狀態和動畫

library(shiny)
library(shinyjs)

# ============================================================================
# 載入動畫 CSS
# ============================================================================

#' 獲取載入動畫的 CSS 樣式
#' @return HTML style tag
get_loading_css <- function() {
  tags$style(HTML("
    @keyframes spin {
      0% { transform: rotate(0deg); }
      100% { transform: rotate(360deg); }
    }
    
    @keyframes pulse {
      0% { opacity: 1; }
      50% { opacity: 0.5; }
      100% { opacity: 1; }
    }
    
    .ai-loading-spinner {
      border: 4px solid #f3f3f3;
      border-top: 4px solid #3498db;
      border-radius: 50%;
      width: 40px;
      height: 40px;
      animation: spin 1s linear infinite;
      margin: 20px auto;
    }
    
    .ai-loading-container {
      text-align: center;
      padding: 30px;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      background-size: 200% 200%;
      animation: gradient 3s ease infinite;
      border-radius: 12px;
      margin: 15px 0;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    
    @keyframes gradient {
      0% { background-position: 0% 50%; }
      50% { background-position: 100% 50%; }
      100% { background-position: 0% 50%; }
    }
    
    .ai-loading-text {
      color: white;
      font-weight: 500;
      margin-top: 15px;
    }
    
    .ai-loading-subtext {
      color: rgba(255,255,255,0.8);
      font-size: 0.9em;
      margin-top: 5px;
    }
    
    .ai-typing-dots {
      display: inline-block;
      animation: typing 1.5s infinite;
    }
    
    @keyframes typing {
      0%, 20% { content: '.'; }
      40% { content: '..'; }
      60%, 100% { content: '...'; }
    }
  "))
}

# ============================================================================
# 載入動畫 UI 組件
# ============================================================================

#' 創建 AI 載入動畫 UI
#' @param id 唯一識別碼
#' @param message 主要訊息
#' @param submessage 次要訊息
#' @param style 額外的 CSS 樣式
#' @return Shiny UI 元素
create_ai_loading_ui <- function(id, 
                                message = "AI 分析中", 
                                submessage = "正在為您生成智能分析建議",
                                style = "") {
  div(
    id = id,
    class = "ai-loading-container",
    style = style,
    div(class = "ai-loading-spinner"),
    h5(
      class = "ai-loading-text",
      icon("robot"),
      " ",
      message,
      span("...", class = "ai-typing-dots")
    ),
    p(class = "ai-loading-subtext", submessage)
  )
}

#' 創建簡化版載入動畫
#' @param message 訊息文字
#' @return Shiny UI 元素
create_simple_ai_loading <- function(message = "分析中...") {
  div(
    style = "text-align: center; padding: 20px;",
    icon("spinner", class = "fa-spin fa-2x", style = "color: #3498db;"),
    br(),
    h5(message, style = "color: #666; margin-top: 10px;")
  )
}

# ============================================================================
# AI 分析包裝函數
# ============================================================================

#' 執行帶載入動畫的 AI 分析
#' @param analysis_name 分析名稱
#' @param analysis_function 執行分析的函數
#' @param progress_steps 進度步驟
#' @param ... 傳遞給分析函數的額外參數
#' @return 分析結果
with_ai_loading <- function(analysis_name, 
                           analysis_function, 
                           progress_steps = NULL,
                           ...) {
  
  # 預設進度步驟
  if(is.null(progress_steps)) {
    progress_steps <- list(
      list(value = 0.2, message = "🔌 連接 AI 服務..."),
      list(value = 0.4, message = "📊 準備數據..."),
      list(value = 0.6, message = "🤖 執行 AI 分析..."),
      list(value = 0.8, message = "✨ 生成建議..."),
      list(value = 1.0, message = "✅ 完成分析")
    )
  }
  
  # 使用 withProgress 顯示進度
  result <- withProgress(
    message = paste0("🤖 ", analysis_name, " - 初始化..."),
    value = 0,
    {
      # 遍歷進度步驟
      for(step in progress_steps) {
        setProgress(step$value, message = step$message)
        
        # 在 AI 分析步驟執行實際函數
        if(step$value == 0.6) {
          tryCatch({
            analysis_result <- analysis_function(...)
          }, error = function(e) {
            setProgress(1.0, message = "❌ 分析失敗")
            return(NULL)
          })
        } else {
          Sys.sleep(0.3)  # 讓用戶看到進度
        }
      }
      
      # 返回結果
      if(exists("analysis_result")) {
        return(analysis_result)
      } else {
        return(NULL)
      }
    }
  )
  
  return(result)
}

# ============================================================================
# UI 狀態管理
# ============================================================================

#' 顯示載入狀態
#' @param session Shiny session
#' @param loading_id 載入容器 ID
#' @param result_id 結果容器 ID
show_ai_loading <- function(session, loading_id, result_id = NULL) {
  # 顯示載入動畫
  shinyjs::show(loading_id)
  
  # 隱藏結果容器
  if(!is.null(result_id)) {
    shinyjs::hide(result_id)
  }
}

#' 隱藏載入狀態並顯示結果
#' @param session Shiny session
#' @param loading_id 載入容器 ID
#' @param result_id 結果容器 ID
hide_ai_loading <- function(session, loading_id, result_id = NULL) {
  # 隱藏載入動畫
  shinyjs::hide(loading_id)
  
  # 顯示結果容器
  if(!is.null(result_id)) {
    shinyjs::show(result_id)
  }
}

# ============================================================================
# 渲染函數
# ============================================================================

#' 渲染 AI 分析結果（帶載入效果）
#' @param expr 生成結果的表達式
#' @param loading_message 載入訊息
#' @param env 環境
#' @param quoted 是否已引用
#' @return renderUI 對象
renderAIAnalysis <- function(expr, 
                            loading_message = "AI 分析中...",
                            env = parent.frame(),
                            quoted = FALSE) {
  
  if (!quoted) {
    expr <- substitute(expr)
  }
  
  renderUI({
    # 首先顯示載入動畫
    loading_ui <- create_simple_ai_loading(loading_message)
    
    # 延遲執行實際分析
    invalidateLater(100)
    
    # 執行分析
    result <- eval(expr, env)
    
    # 如果有結果，返回結果；否則返回載入動畫
    if(!is.null(result)) {
      return(result)
    } else {
      return(loading_ui)
    }
  })
}

# ============================================================================
# 輔助函數
# ============================================================================

#' 創建 AI 分析容器（包含載入和結果區域）
#' @param ns 命名空間函數
#' @param analysis_id 分析 ID
#' @param button_label 按鈕標籤
#' @param button_class 按鈕 CSS 類別
#' @return Shiny UI 元素
create_ai_analysis_container <- function(ns, 
                                        analysis_id,
                                        button_label = "開始 AI 分析",
                                        button_class = "btn-primary") {
  tagList(
    # 分析按鈕
    actionButton(
      ns(paste0("btn_", analysis_id)),
      button_label,
      icon = icon("robot"),
      class = button_class
    ),
    br(), br(),
    
    # 載入動畫容器（初始隱藏）
    shinyjs::hidden(
      div(
        id = ns(paste0(analysis_id, "_loading")),
        create_ai_loading_ui(
          ns(paste0(analysis_id, "_loader")),
          message = "AI 分析進行中",
          submessage = "請稍候，正在生成智能建議..."
        )
      )
    ),
    
    # 結果容器
    uiOutput(ns(paste0("ai_", analysis_id)))
  )
}

#' 初始化 AI 載入管理器
#' @return 必要的 UI 元素
init_ai_loading_manager <- function() {
  tagList(
    useShinyjs(),
    get_loading_css()
  )
}