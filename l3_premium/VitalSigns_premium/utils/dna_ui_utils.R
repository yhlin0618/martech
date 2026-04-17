# DNA 分析 UI 工具函數
# 從 module_dna_multi.R 抽取的 UI 相關函數

library(shiny)
library(bs4Dash)
library(shinyjs)
library(DT)

# ============================================================================
# 按鈕樣式管理函數
# ============================================================================

#' 更新指標按鈕樣式
#' @param session Shiny session
#' @param ns 命名空間函數
#' @param selected_metric 選中的指標
#' @param all_metrics 所有指標列表
update_metric_button_styles <- function(session, ns, selected_metric, 
                                      all_metrics = c("M", "R", "F", "IPT", "CAI", "PCV", "CRI", "NES")) {
  # 按鈕 ID 對應
  button_ids <- list(
    "M" = "show_m",
    "R" = "show_r", 
    "F" = "show_f",
    "IPT" = "show_ipt",
    "CAI" = "show_cai",
    "PCV" = "show_pcv",
    "CRI" = "show_cri",
    "NES" = "show_nes"
  )
  
  # 更新所有按鈕樣式
  for (metric in all_metrics) {
    btn_id <- button_ids[[metric]]
    if (!is.null(btn_id)) {
      if (metric == selected_metric) {
        # 選中的按鈕
        shinyjs::addClass(ns(btn_id), "selected-metric")
        shinyjs::removeClass(ns(btn_id), "btn-outline-primary")
        shinyjs::addClass(ns(btn_id), "btn-primary")
      } else {
        # 未選中的按鈕
        shinyjs::removeClass(ns(btn_id), "selected-metric")
        shinyjs::removeClass(ns(btn_id), "btn-primary")
        shinyjs::addClass(ns(btn_id), "btn-outline-primary")
      }
    }
  }
}

# ============================================================================
# 指標說明生成函數
# ============================================================================

#' 生成指標說明 HTML
#' @param metric 指標代碼
#' @return HTML 內容
generate_metric_description <- function(metric) {
  descriptions <- list(
    "M" = list(
      title = "💰 購買金額 (Monetary)",
      desc = "平均單次消費金額",
      insight = "80/20法則：20%的客戶貢獻80%營收",
      action = "• 高價值：VIP服務、專屬優惠<br>• 低價值：入門產品推薦"
    ),
    "R" = list(
      title = "📅 最近來店 (Recency)",
      desc = "距離最近一次購買的天數",
      insight = "越近期購買的客戶，回購機率越高",
      action = "• 高活躍：交叉銷售<br>• 低活躍：召回行銷"
    ),
    "F" = list(
      title = "🔄 購買頻率 (Frequency)",
      desc = "總購買次數",
      insight = "忠誠度指標，頻率越高越忠誠",
      action = "• 高頻：忠誠計劃<br>• 低頻：提升頻率方案"
    ),
    "CAI" = list(
      title = "📈 顧客活躍度 (Customer Activity Index)",
      desc = "購買行為趨勢（-1到1）",
      insight = ">0 漸趨活躍 | <0 漸趨靜止",
      action = "• 活躍：把握成長動能<br>• 靜止：緊急挽回"
    ),
    "PCV" = list(
      title = "💎 過去價值 (Past Customer Value)",
      desc = "歷史累積消費總額",
      insight = "客戶歷史貢獻度",
      action = "• 高價值：VIP經營<br>• 低價值：價值提升"
    ),
    "CRI" = list(
      title = "⭐ 顧客穩定度指標 (Customer Stability Index)",
      desc = "RFM綜合加權分數（0.3×R + 0.3×F + 0.4×M）",
      insight = "80/20法則：20%高穩定客戶貢獻80%營收",
      action = "• 高穩定(Top 20%)：VIP維護策略<br>• 中穩定(Middle 60%)：提升忠誠度<br>• 低穩定(Bottom 20%)：激活與挽留"
    ),
    "NES" = list(
      title = "👥 顧客狀態 (New-Existing-Sleeping)",
      desc = "客戶生命週期狀態",
      insight = "N新客 | E0主力 | S1-S3休眠",
      action = "• 新客：引導成長<br>• 主力：維護深化<br>• 休眠：喚醒策略"
    )
  )
  
  info <- descriptions[[metric]]
  if (is.null(info)) {
    return(div(p("請選擇指標")))
  }
  
  div(
    style = "background: #f8f9fa; padding: 15px; border-radius: 8px;",
    h5(info$title, style = "color: #2c3e50; margin-bottom: 10px;"),
    p(tags$b("定義："), info$desc, style = "margin-bottom: 8px;"),
    p(tags$b("洞察："), HTML(info$insight), style = "margin-bottom: 8px;"),
    p(tags$b("行動："), HTML(info$action), style = "margin-bottom: 0;")
  )
}

# ============================================================================
# DataTable 格式化函數
# ============================================================================

#' 創建格式化的 DataTable
#' @param data 資料框架
#' @param format_round_cols 需要格式化為整數的欄位
#' @param format_currency_cols 需要格式化為貨幣的欄位
#' @param page_length 每頁顯示筆數
#' @return DT::datatable 物件
create_formatted_datatable <- function(data, 
                                      format_round_cols = NULL,
                                      format_currency_cols = NULL,
                                      page_length = 10) {
  # 基本 DataTable 設定
  dt <- datatable(
    data,
    options = list(
      pageLength = page_length,
      scrollX = TRUE,
      dom = 'Bfrtip',
      buttons = c('copy', 'csv', 'excel'),
      language = list(
        search = "搜尋:",
        lengthMenu = "顯示 _MENU_ 筆資料",
        info = "顯示第 _START_ 至 _END_ 筆，共 _TOTAL_ 筆",
        paginate = list(
          first = "第一頁",
          last = "最後一頁",
          `next` = "下一頁",
          previous = "上一頁"
        ),
        emptyTable = "無資料",
        zeroRecords = "查無符合資料"
      )
    ),
    extensions = 'Buttons',
    rownames = FALSE
  )
  
  # 格式化整數欄位
  if (!is.null(format_round_cols)) {
    existing_round <- intersect(format_round_cols, names(data))
    if (length(existing_round) > 0) {
      tryCatch({
        dt <- dt %>% formatRound(existing_round, 0)
      }, error = function(e) {
        message("formatRound error: ", e$message)
      })
    }
  }
  
  # 格式化貨幣欄位
  if (!is.null(format_currency_cols)) {
    existing_currency <- intersect(format_currency_cols, names(data))
    if (length(existing_currency) > 0) {
      tryCatch({
        dt <- dt %>% formatCurrency(existing_currency, "$")
      }, error = function(e) {
        message("formatCurrency error: ", e$message)
      })
    }
  }
  
  return(dt)
}

# ============================================================================
# 狀態訊息函數
# ============================================================================

#' 顯示處理狀態訊息
#' @param message 訊息內容
#' @param type 訊息類型 (info, success, warning, error)
#' @param icon 圖示
#' @return HTML div
show_status_message <- function(message, type = "info", icon = NULL) {
  # 選擇適當的圖示
  if (is.null(icon)) {
    icon <- switch(type,
      "success" = "check-circle",
      "warning" = "exclamation-triangle",
      "error" = "times-circle",
      "info" = "info-circle"
    )
  }
  
  # 選擇適當的顏色
  color <- switch(type,
    "success" = "#28a745",
    "warning" = "#ffc107",
    "error" = "#dc3545",
    "info" = "#17a2b8"
  )
  
  div(
    class = paste0("alert alert-", type),
    style = paste0("border-left: 4px solid ", color, ";"),
    icon(icon),
    " ",
    message
  )
}

# ============================================================================
# 圖表工具函數
# ============================================================================

#' 創建 ECDF 圖表
#' @param data 資料向量
#' @param title 圖表標題
#' @param x_label X 軸標籤
#' @param color 線條顏色
#' @return plotly 物件
create_ecdf_plot <- function(data, title, x_label, color = "#3498db") {
  ecdf_data <- ecdf(data)
  x_vals <- sort(unique(data))
  y_vals <- ecdf_data(x_vals)
  
  plotly::plot_ly(
    x = x_vals,
    y = y_vals,
    type = 'scatter',
    mode = 'lines',
    line = list(color = color, width = 2),
    hovertemplate = paste0(
      x_label, ": %{x}<br>",
      "累積比例: %{y:.2%}<extra></extra>"
    )
  ) %>%
    plotly::layout(
      title = list(text = title, font = list(size = 14)),
      xaxis = list(title = x_label),
      yaxis = list(title = "累積分布", tickformat = ".0%"),
      hovermode = "x unified"
    )
}

#' 創建直方圖
#' @param data 資料向量
#' @param title 圖表標題
#' @param x_label X 軸標籤
#' @param bins 分組數
#' @param color 顏色
#' @return plotly 物件
create_histogram_plot <- function(data, title, x_label, bins = 30, color = "#3498db") {
  plotly::plot_ly(
    x = data,
    type = 'histogram',
    nbinsx = bins,
    marker = list(
      color = color,
      line = list(color = 'white', width = 1)
    ),
    hovertemplate = paste0(
      x_label, ": %{x}<br>",
      "數量: %{y}<extra></extra>"
    )
  ) %>%
    plotly::layout(
      title = list(text = title, font = list(size = 14)),
      xaxis = list(title = x_label),
      yaxis = list(title = "數量"),
      bargap = 0.1
    )
}

# ============================================================================
# 驗證與錯誤處理函數
# ============================================================================

#' 安全執行函數並處理錯誤
#' @param expr 要執行的表達式
#' @param error_message 錯誤時顯示的訊息
#' @param default_value 錯誤時的預設返回值
#' @return 執行結果或預設值
safe_execute <- function(expr, error_message = "執行錯誤", default_value = NULL) {
  tryCatch(
    expr,
    error = function(e) {
      showNotification(
        paste(error_message, ":", e$message),
        type = "error",
        duration = 5
      )
      return(default_value)
    },
    warning = function(w) {
      showNotification(
        paste("警告:", w$message),
        type = "warning",
        duration = 3
      )
      return(suppressWarnings(expr))
    }
  )
}

#' 驗證必要欄位
#' @param data 資料框架
#' @param required_fields 必要欄位列表
#' @param show_notification 是否顯示通知
#' @return 邏輯值
validate_required_fields <- function(data, required_fields, show_notification = TRUE) {
  missing_fields <- setdiff(required_fields, names(data))
  
  if (length(missing_fields) > 0) {
    if (show_notification) {
      showNotification(
        paste("缺少必要欄位:", paste(missing_fields, collapse = ", ")),
        type = "error",
        duration = 5
      )
    }
    return(FALSE)
  }
  
  return(TRUE)
}

# ============================================================================
# 匯出功能函數
# ============================================================================

#' 準備匯出資料
#' @param data 原始資料
#' @param include_chinese 是否包含中文欄位
#' @param selected_columns 選擇的欄位
#' @return 準備匯出的資料框架
prepare_export_data <- function(data, include_chinese = TRUE, selected_columns = NULL) {
  # 複製資料
  export_data <- data
  
  # 轉換為中文欄位（如果需要）
  if (include_chinese) {
    export_data <- convert_to_chinese_columns(export_data)
  }
  
  # 選擇特定欄位（如果指定）
  if (!is.null(selected_columns)) {
    available_cols <- intersect(selected_columns, names(export_data))
    if (length(available_cols) > 0) {
      export_data <- export_data[, available_cols, drop = FALSE]
    }
  }
  
  # 確保資料格式正確
  export_data <- as.data.frame(export_data)
  
  return(export_data)
}