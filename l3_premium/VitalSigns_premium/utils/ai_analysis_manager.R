# AI 分析結果管理模組
# 用於管理和暫存不同指標的 AI 分析結果

library(shiny)

# ============================================================================
# AI 分析結果管理器類
# ============================================================================

#' 創建 AI 分析管理器
#' @return 管理器物件（reactiveValues）
create_ai_analysis_manager <- function() {
  reactiveValues(
    # 儲存各指標的分析結果
    results_cache = list(
      "M" = NULL,
      "R" = NULL,
      "F" = NULL,
      "CAI" = NULL,
      "PCV" = NULL,
      "CRI" = NULL,
      "NES" = NULL
    ),
    
    # 記錄各指標的分析時間
    analysis_timestamps = list(
      "M" = NULL,
      "R" = NULL,
      "F" = NULL,
      "CAI" = NULL,
      "PCV" = NULL,
      "CRI" = NULL,
      "NES" = NULL
    ),
    
    # 當前選擇的指標
    current_metric = NULL,
    
    # 整體分析狀態
    is_analyzing = FALSE,
    
    # 錯誤訊息
    error_message = NULL
  )
}

# ============================================================================
# 結果管理函數
# ============================================================================

#' 檢查指標是否已有分析結果
#' @param manager AI 分析管理器
#' @param metric 指標名稱
#' @return 邏輯值
has_analysis_result <- function(manager, metric) {
  !is.null(manager$results_cache[[metric]])
}

#' 獲取指標的分析結果
#' @param manager AI 分析管理器
#' @param metric 指標名稱
#' @return 分析結果或 NULL
get_analysis_result <- function(manager, metric) {
  if (has_analysis_result(manager, metric)) {
    return(manager$results_cache[[metric]])
  }
  return(NULL)
}

#' 儲存指標的分析結果
#' @param manager AI 分析管理器
#' @param metric 指標名稱
#' @param result 分析結果
store_analysis_result <- function(manager, metric, result) {
  manager$results_cache[[metric]] <- result
  manager$analysis_timestamps[[metric]] <- Sys.time()
}

#' 清除所有分析結果
#' @param manager AI 分析管理器
clear_all_results <- function(manager) {
  metrics <- c("M", "R", "F", "CAI", "PCV", "CRI", "NES")
  for (metric in metrics) {
    manager$results_cache[[metric]] <- NULL
    manager$analysis_timestamps[[metric]] <- NULL
  }
}

#' 清除特定指標的分析結果
#' @param manager AI 分析管理器
#' @param metric 指標名稱
clear_metric_result <- function(manager, metric) {
  manager$results_cache[[metric]] <- NULL
  manager$analysis_timestamps[[metric]] <- NULL
}

# ============================================================================
# AI 分析執行函數
# ============================================================================

#' 執行 AI 分析（含暫存邏輯）
#' @param manager AI 分析管理器
#' @param metric 指標名稱
#' @param data 分析數據
#' @param force_refresh 是否強制重新分析
#' @param analysis_function 執行分析的函數
#' @return 分析結果
execute_ai_analysis <- function(manager, metric, data, force_refresh = FALSE, analysis_function = NULL) {
  # 如果不強制更新且已有結果，返回暫存結果
  if (!force_refresh && has_analysis_result(manager, metric)) {
    showNotification(
      paste("📋 使用", metric, "的暫存分析結果"),
      type = "message",
      duration = 2
    )
    return(get_analysis_result(manager, metric))
  }
  
  # 設置分析狀態
  manager$is_analyzing <- TRUE
  manager$error_message <- NULL
  
  # 執行新分析
  result <- tryCatch({
    showNotification(
      paste("🤖 正在執行", metric, "的AI分析..."),
      type = "message",
      duration = 3
    )
    
    if (!is.null(analysis_function)) {
      # 執行提供的分析函數
      analysis_result <- analysis_function(data, metric)
    } else {
      # 預設分析結果（示範用）
      analysis_result <- generate_default_ai_analysis(data, metric)
    }
    
    # 儲存結果
    store_analysis_result(manager, metric, analysis_result)
    
    showNotification(
      paste("✅", metric, "分析完成並已暫存"),
      type = "message",
      duration = 2
    )
    
    analysis_result
  }, error = function(e) {
    manager$error_message <- paste("分析錯誤:", e$message)
    showNotification(
      paste("❌ AI分析失敗:", e$message),
      type = "error",
      duration = 5
    )
    NULL
  })
  
  # 重置分析狀態
  manager$is_analyzing <- FALSE
  
  return(result)
}

# ============================================================================
# 預設 AI 分析函數
# ============================================================================

#' 生成預設的 AI 分析結果
#' @param data 分析數據
#' @param metric 指標名稱
#' @return 分析結果列表
generate_default_ai_analysis <- function(data, metric) {
  # 計算基本統計
  if (is.null(data) || nrow(data) == 0) {
    return(list(
      summary = "無數據可分析",
      recommendations = list()
    ))
  }
  
  # 根據指標生成不同的分析
  metric_info <- switch(metric,
    "M" = list(
      title = "購買金額分析",
      focus = "消費力",
      key_metric = "m_value"
    ),
    "R" = list(
      title = "最近購買時間分析",
      focus = "活躍度",
      key_metric = "r_value"
    ),
    "F" = list(
      title = "購買頻率分析",
      focus = "忠誠度",
      key_metric = "f_value"
    ),
    "CAI" = list(
      title = "顧客活躍度分析",
      focus = "成長趨勢",
      key_metric = "cai_value"
    ),
    "PCV" = list(
      title = "過去價值分析",
      focus = "歷史貢獻",
      key_metric = "pcv"
    ),
    "CRI" = list(
      title = "參與度分析",
      focus = "互動規律",
      key_metric = "cri"
    ),
    "NES" = list(
      title = "顧客狀態分析",
      focus = "生命週期",
      key_metric = "nes_status"
    ),
    list(
      title = "綜合分析",
      focus = "整體表現",
      key_metric = NULL
    )
  )
  
  # 生成分析摘要
  summary <- paste0(
    "### ", metric_info$title, "\n\n",
    "**分析重點：** ", metric_info$focus, "\n\n",
    "**客戶總數：** ", nrow(data), " 人\n\n"
  )
  
  # 如果有具體指標，計算統計
  if (!is.null(metric_info$key_metric) && metric_info$key_metric %in% names(data)) {
    values <- data[[metric_info$key_metric]]
    if (is.numeric(values)) {
      summary <- paste0(
        summary,
        "**統計摘要：**\n",
        "- 平均值：", round(mean(values, na.rm = TRUE), 2), "\n",
        "- 中位數：", round(median(values, na.rm = TRUE), 2), "\n",
        "- 標準差：", round(sd(values, na.rm = TRUE), 2), "\n"
      )
    }
  }
  
  # 生成建議
  recommendations <- list(
    strategy = paste0(metric_info$focus, "優化策略"),
    actions = c(
      paste0("針對", metric_info$focus, "進行分群管理"),
      "制定差異化行銷策略",
      "持續監控關鍵指標變化"
    )
  )
  
  return(list(
    summary = summary,
    recommendations = recommendations,
    timestamp = Sys.time(),
    metric = metric
  ))
}

# ============================================================================
# UI 呈現函數
# ============================================================================

#' 生成 AI 分析結果的 UI
#' @param manager AI 分析管理器
#' @param metric 指標名稱（NULL 表示使用當前指標）
#' @return UI 元素
render_ai_analysis_ui <- function(manager, metric = NULL) {
  # 使用提供的指標或當前指標
  if (is.null(metric)) {
    metric <- manager$current_metric
  }
  
  # 如果沒有選擇指標
  if (is.null(metric)) {
    return(
      div(
        style = "text-align: center; padding: 40px; background: #f8f9fa; border-radius: 8px;",
        icon("robot", style = "font-size: 48px; color: #6c757d; margin-bottom: 20px;"),
        h4("請先選擇分析指標", style = "color: #6c757d; margin-bottom: 15px;"),
        p("選擇左側的指標按鈕開始分析", style = "color: #6c757d;")
      )
    )
  }
  
  # 檢查是否正在分析
  if (isTRUE(manager$is_analyzing)) {
    return(
      div(
        class = "text-center",
        style = "padding: 40px;",
        tags$div(class = "spinner-border text-primary", role = "status"),
        h5("AI 分析進行中...", class = "mt-3 text-muted"),
        p(paste("正在分析", metric, "指標"), class = "text-muted")
      )
    )
  }
  
  # 檢查是否有錯誤
  if (!is.null(manager$error_message)) {
    return(
      div(
        class = "alert alert-danger",
        icon("exclamation-triangle"),
        strong(" 分析錯誤："),
        manager$error_message
      )
    )
  }
  
  # 獲取分析結果
  result <- get_analysis_result(manager, metric)
  
  # 如果沒有結果，顯示提示
  if (is.null(result)) {
    return(
      div(
        style = "text-align: center; padding: 40px; background: #f8f9fa; border-radius: 8px;",
        icon("robot", style = "font-size: 48px; color: #6c757d; margin-bottom: 20px;"),
        h4("請先執行 AI 分析", style = "color: #6c757d; margin-bottom: 15px;"),
        p(
          paste0("點擊左側「執行AI分析」按鈕開始", metric, "指標的智能分析"),
          style = "color: #6c757d;"
        )
      )
    )
  }
  
  # 顯示分析結果
  tagList(
    # 時間戳記
    if (!is.null(result$timestamp)) {
      div(
        class = "text-right text-muted small mb-2",
        icon("clock"),
        " 分析時間：",
        format(result$timestamp, "%Y-%m-%d %H:%M:%S")
      )
    },
    
    # 分析摘要
    if (!is.null(result$summary)) {
      div(
        class = "analysis-summary",
        style = "background: white; padding: 20px; border-radius: 8px; margin-bottom: 20px;",
        # 檢查是否已經是 HTML 格式
        if (grepl("^<div", result$summary) || grepl("^<h[1-6]", result$summary)) {
          HTML(result$summary)  # 如果已經是 HTML，直接使用
        } else {
          HTML(markdown::markdownToHTML(
            text = result$summary,
            fragment.only = TRUE
          ))
        }
      )
    },
    
    # 行銷建議（結構化顯示）
    if (!is.null(result$recommendations)) {
      # 檢查是否為分群建議格式（有多個客群）
      if (is.list(result$recommendations) && !is.null(names(result$recommendations)) && 
          all(c("strategy", "actions") %in% names(unlist(result$recommendations, recursive = FALSE)))) {
        # 簡單格式：單一策略和行動列表
        div(
          class = "recommendations",
          style = "background: #f0f8ff; padding: 20px; border-radius: 8px; border-left: 4px solid #007bff;",
          h5("🎯 分群行銷建議", style = "color: #2c3e50; margin-bottom: 15px;"),
          if (!is.null(result$recommendations$strategy)) {
            p(
              tags$b("整體策略："),
              result$recommendations$strategy,
              style = "margin-bottom: 10px;"
            )
          },
          if (!is.null(result$recommendations$actions) && length(result$recommendations$actions) > 0) {
            tags$ul(
              style = "margin: 0; padding-left: 20px;",
              lapply(result$recommendations$actions, function(action) {
                tags$li(action, style = "margin: 5px 0;")
              })
            )
          }
        )
      } else if (is.list(result$recommendations) && length(result$recommendations) > 0) {
        # 結構化格式：多個客群的建議
        segment_order <- c("低價值顧客", "中價值顧客", "高價值顧客")
        chinese_numbers <- c("一", "二", "三")
        
        # 排序客群
        sorted_segments <- names(result$recommendations)
        sorted_segments <- sorted_segments[order(match(sorted_segments, segment_order, nomatch = 99))]
        
        div(
          class = "recommendations",
          style = "background: #f0f8ff; padding: 20px; border-radius: 8px; border-left: 4px solid #007bff;",
          h5("🎯 分群行銷建議", style = "color: #2c3e50; margin-bottom: 20px;"),
          
          # 為每個客群建立結構化顯示
          tagList(
            lapply(seq_along(sorted_segments), function(i) {
              seg <- sorted_segments[i]
              rec <- result$recommendations[[seg]]
              
              div(
                style = "margin-bottom: 20px; padding: 15px; background: white; border-radius: 5px;",
                # 使用中文數字作為主標題
                h6(
                  paste0(chinese_numbers[i], "、", seg),
                  style = "color: #34495e; margin-bottom: 12px; font-weight: bold;"
                ),
                
                # 策略說明
                if (!is.null(rec$strategy)) {
                  p(
                    tags$b("策略方向："),
                    rec$strategy,
                    style = "margin-bottom: 10px; color: #555;"
                  )
                },
                
                # 具體行動建議（使用數字編號）
                if (!is.null(rec$actions) && length(rec$actions) > 0) {
                  tags$ol(
                    style = "margin: 0; padding-left: 25px;",
                    lapply(rec$actions, function(action) {
                      tags$li(action, style = "margin: 5px 0; color: #333;")
                    })
                  )
                }
              )
            })
          )
        )
      } else {
        # 後備方案：簡單文字顯示
        div(
          class = "recommendations",
          style = "background: #f0f8ff; padding: 20px; border-radius: 8px; border-left: 4px solid #007bff;",
          h5("🎯 行銷建議", style = "color: #2c3e50; margin-bottom: 15px;"),
          p(result$recommendations)
        )
      }
    }
  )
}

# ============================================================================
# 批次分析函數
# ============================================================================

#' 批次執行所有指標的 AI 分析
#' @param manager AI 分析管理器
#' @param data 分析數據
#' @param metrics 要分析的指標列表
#' @param analysis_function 分析函數
batch_analyze_all_metrics <- function(manager, data, 
                                     metrics = c("M", "R", "F", "CAI", "PCV", "CRI", "NES"),
                                     analysis_function = NULL) {
  
  showNotification(
    paste("🚀 開始批次分析", length(metrics), "個指標"),
    type = "message",
    duration = 3
  )
  
  success_count <- 0
  
  withProgress(message = "執行批次 AI 分析", value = 0, {
    for (i in seq_along(metrics)) {
      metric <- metrics[i]
      
      # 更新進度
      incProgress(1/length(metrics), detail = paste("分析", metric))
      
      # 執行分析
      result <- execute_ai_analysis(
        manager = manager,
        metric = metric,
        data = data,
        force_refresh = TRUE,
        analysis_function = analysis_function
      )
      
      if (!is.null(result)) {
        success_count <- success_count + 1
      }
      
      # 短暫延遲，避免 API 過載
      Sys.sleep(0.5)
    }
  })
  
  showNotification(
    paste("✅ 批次分析完成！成功分析", success_count, "/", length(metrics), "個指標"),
    type = if(success_count == length(metrics)) "message" else "warning",
    duration = 4
  )
}

# ============================================================================
# 快取管理函數
# ============================================================================

#' 獲取快取統計
#' @param manager AI 分析管理器
#' @return 統計資訊列表
get_cache_statistics <- function(manager) {
  metrics <- c("M", "R", "F", "CAI", "PCV", "CRI", "NES")
  
  cached_count <- sum(sapply(metrics, function(m) {
    !is.null(manager$results_cache[[m]])
  }))
  
  # 找出最舊的分析
  oldest_timestamp <- NULL
  oldest_metric <- NULL
  
  for (metric in metrics) {
    timestamp <- manager$analysis_timestamps[[metric]]
    if (!is.null(timestamp)) {
      if (is.null(oldest_timestamp) || timestamp < oldest_timestamp) {
        oldest_timestamp <- timestamp
        oldest_metric <- metric
      }
    }
  }
  
  list(
    total_metrics = length(metrics),
    cached_count = cached_count,
    cache_rate = round(cached_count / length(metrics) * 100, 1),
    oldest_metric = oldest_metric,
    oldest_timestamp = oldest_timestamp
  )
}