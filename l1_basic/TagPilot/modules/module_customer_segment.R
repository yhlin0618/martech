################################################################################
# Customer Segment Module - 顧客區隔與Email顯示模組
################################################################################

#' Customer Segment Module UI
#' @param id Module namespace ID
customerSegmentModuleUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    # 移除篩選控制區，直接顯示統計摘要
    
    fluidRow(
      # 統計摘要區
      column(width = 12,
        fluidRow(
          bs4ValueBox(
            value = textOutput(ns("total_customers")),
            subtitle = "總客戶數",
            icon = icon("users"),
            color = "primary",
            width = 3
          ),
          bs4ValueBox(
            value = textOutput(ns("segment_count")),
            subtitle = "區隔數量",
            icon = icon("layer-group"),
            color = "success",
            width = 3
          ),
          bs4ValueBox(
            value = textOutput(ns("avg_value")),
            subtitle = "平均客戶價值",
            icon = icon("dollar-sign"),
            color = "warning",
            width = 3
          ),
          bs4ValueBox(
            value = textOutput(ns("email_rate")),
            subtitle = "Email 完整率",
            icon = icon("envelope"),
            color = "info",
            width = 3
          )
        )
      )
    ),
    
    fluidRow(
      # 資料表格區
      column(width = 12,
        bs4Card(
          title = "客戶區隔明細",
          status = "primary",
          width = 12,
          maximizable = TRUE,
          collapsible = TRUE,
          
          # 下載按鈕區
          div(style = "margin-bottom: 15px;",
            downloadButton(ns("download_csv"), 
                          "下載 CSV", 
                          class = "btn-success",
                          icon = icon("file-csv")),
            downloadButton(ns("download_excel"), 
                          "下載 Excel", 
                          class = "btn-info",
                          icon = icon("file-excel"),
                          style = "margin-left: 10px;")
          ),
          
          # 資料表格
          DT::dataTableOutput(ns("segment_table"))
        )
      )
    ),
    
    fluidRow(
      # 視覺化區
      column(width = 6,
        bs4Card(
          title = "區隔分佈圖",
          status = "success",
          width = 12,
          plotlyOutput(ns("segment_pie"), height = "400px")
        )
      ),
      column(width = 6,
        bs4Card(
          title = "價值分佈圖",
          status = "warning",
          width = 12,
          plotlyOutput(ns("value_distribution"), height = "400px")
        )
      )
    )
  )
}

#' Customer Segment Module Server
#' @param id Module namespace ID
#' @param con Database connection
#' @param user_info Reactive user information
#' @param uploaded_data Reactive uploaded data from upload module
customerSegmentModuleServer <- function(id, con, user_info, uploaded_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive: 取得客戶區隔資料
    customer_data <- reactive({
      # 檢查使用者是否已登入（user_info 應該包含使用者資訊）
      if (is.null(user_info) || is.null(user_info())) {
        # 如果使用者未登入，返回空資料框，不顯示警告
        return(data.frame(
          customer_id = character(),
          customer_email = character(),
          platform_id = integer(),
          platform_name = character(),
          segment = character(),
          recency = numeric(),
          frequency = numeric(),
          monetary = numeric(),
          calculated_at = as.Date(character()),
          segment_chinese = character(),
          customer_value = numeric()
        ))
      }
      
      # 取得上傳的資料
      data <- uploaded_data()
      
      # 如果沒有上傳資料，返回空資料框
      if (is.null(data) || nrow(data) == 0) {
        return(data.frame())
      }
      
      message(sprintf("[Customer Segment] 接收到 %d 筆上傳資料", nrow(data)))
      
      tryCatch({
        # 直接處理上傳的資料，不從資料庫讀取
        col_names <- names(data)
        
        # 處理最小資料集（優先處理 amount，否則使用 lineitem_price）
        amount_col <- if("amount" %in% col_names) {
          "amount"
        } else if("lineitem_price" %in% col_names) {
          "lineitem_price"
        } else if("total_amount" %in% col_names) {
          "total_amount"
        } else {
          NULL
        }
        
        if ("customer_id" %in% col_names && !is.null(amount_col)) {
          # 聚合客戶資料
          date_col <- if("payments_date" %in% col_names) {
            "payments_date"
          } else if("payment_time" %in% col_names) {
            "payment_time"
          } else if("order_date" %in% col_names) {
            "order_date"
          } else {
            NULL
          }
          
          # 使用 dplyr 聚合資料
          library(dplyr)
          result <- data %>%
            filter(!is.na(customer_id)) %>%
            group_by(customer_id) %>%
            summarise(
              customer_email = first(customer_id),
              platform_id = 0,
              platform_name = "Unknown",
              segment = "待分析",
              recency = 0,
              frequency = n(),
              monetary = sum(as.numeric(get(amount_col)), na.rm = TRUE),
              calculated_at = Sys.Date(),
              segment_chinese = "待分析",
              customer_value = round(sum(as.numeric(get(amount_col)), na.rm = TRUE), 2),
              .groups = 'drop'
            )
            
            # 基於九宮格分類系統進行分類（與 module_dna_multi_basic 一致）
            if (nrow(result) > 0) {
              # 輸出調試信息
              message(sprintf("[Customer Segment] 分析 %d 筆客戶資料", nrow(result)))
              
              # 計算分位數（使用 20% 和 80% 分位點，與九宮格模組一致）
              m_quantiles <- quantile(result$customer_value, probs = c(0.2, 0.8), na.rm = TRUE)
              f_quantiles <- quantile(result$frequency, probs = c(0.2, 0.8), na.rm = TRUE)
              
              # 處理分位數相同的情況
              if (length(unique(m_quantiles)) < 2 || diff(m_quantiles) < 0.001) {
                m_min <- min(result$customer_value, na.rm = TRUE)
                m_max <- max(result$customer_value, na.rm = TRUE)
                if (m_max - m_min < 0.001) {
                  m_breaks <- c(m_min - 0.001, m_min, m_min + 0.001, m_max + 0.001)
                } else {
                  m_breaks <- c(m_min - 0.001, 
                               m_min + (m_max - m_min) * 0.33, 
                               m_min + (m_max - m_min) * 0.67, 
                               m_max + 0.001)
                }
              } else {
                m_breaks <- c(min(result$customer_value, na.rm = TRUE) - 0.001,
                             m_quantiles[1], m_quantiles[2],
                             max(result$customer_value, na.rm = TRUE) + 0.001)
              }
              
              if (length(unique(f_quantiles)) < 2 || diff(f_quantiles) < 0.001) {
                f_min <- min(result$frequency, na.rm = TRUE)
                f_max <- max(result$frequency, na.rm = TRUE)
                if (f_max - f_min < 0.001) {
                  f_breaks <- c(f_min - 0.001, f_min, f_min + 0.001, f_max + 0.001)
                } else {
                  f_breaks <- c(f_min - 0.001,
                               f_min + (f_max - f_min) * 0.33,
                               f_min + (f_max - f_min) * 0.67,
                               f_max + 0.001)
                }
              } else {
                f_breaks <- c(min(result$frequency, na.rm = TRUE) - 0.001,
                             f_quantiles[1], f_quantiles[2],
                             max(result$frequency, na.rm = TRUE) + 0.001)
              }
              
              # 確保 breaks 是唯一且遞增的
              m_breaks <- sort(unique(m_breaks))
              f_breaks <- sort(unique(f_breaks))
              
              # 如果仍然沒有足夠的分割點，使用預設值
              if (length(m_breaks) < 4) {
                m_breaks <- c(0, 100, 500, max(result$customer_value, na.rm = TRUE) + 1)
              }
              if (length(f_breaks) < 4) {
                f_breaks <- c(0, 1, 3, max(result$frequency, na.rm = TRUE) + 1)
              }
              
              # 分類客戶
              result$value_level <- cut(result$customer_value,
                                       breaks = m_breaks,
                                       labels = c("低", "中", "高"),
                                       include.lowest = TRUE,
                                       right = FALSE)
              
              result$activity_level <- cut(result$frequency,
                                          breaks = f_breaks,
                                          labels = c("低", "中", "高"),
                                          include.lowest = TRUE,
                                          right = FALSE)
              
              # 使用與九宮格相同的命名系統
              result$segment_chinese <- with(result, {
                ifelse(value_level == "高" & activity_level == "高", "A1C 王者引擎-C",
                ifelse(value_level == "高" & activity_level == "中", "A2C 王者穩健-C",
                ifelse(value_level == "高" & activity_level == "低", "A3C 王者休眠-C",
                ifelse(value_level == "中" & activity_level == "高", "B1C 成長火箭-C",
                ifelse(value_level == "中" & activity_level == "中", "B2C 成長常規-C",
                ifelse(value_level == "中" & activity_level == "低", "B3C 成長停滯-C",
                ifelse(value_level == "低" & activity_level == "高", "C1C 潛力新芽-C",
                ifelse(value_level == "低" & activity_level == "中", "C2C 潛力維持-C",
                ifelse(value_level == "低" & activity_level == "低", "C3C 清倉邊緣-C",
                "未分類")))))))))
              })
              
              # 輸出分類完成信息
              segment_summary <- table(result$segment_chinese)
              message(sprintf("[Customer Segment] 分類完成: %s", 
                            paste(names(segment_summary), segment_summary, sep=":", collapse=", ")))
            }
        } else {
          # 如果連基本欄位都沒有，返回空資料框
          result <- data.frame()
          message("[Customer Segment] 資料缺少必要欄位 (customer_id 或金額欄位)")
        }
        
        return(result)
        
      }, error = function(e) {
        # 錯誤時只在使用者已登入時顯示訊息
        if (!is.null(user_info) && !is.null(user_info())) {
          showNotification(
            paste("讀取客戶資料時發生錯誤:", e$message),
            type = "error",
            duration = 10
          )
        }
        
        # 返回包含必要欄位的空資料框，避免後續錯誤
        return(data.frame(
          customer_id = character(),
          customer_email = character(),
          platform_id = integer(),
          platform_name = character(),
          segment = character(),
          recency = numeric(),
          frequency = numeric(),
          monetary = numeric(),
          calculated_at = as.Date(character()),
          segment_chinese = character(),
          customer_value = numeric()
        ))
      })
    })
    
    # 不再需要篩選，直接使用所有資料
    # 為了保持向後兼容性，filtered_data 直接返回 customer_data
    filtered_data <- reactive({
      customer_data()
    })
    
    # 輸出：總客戶數
    output$total_customers <- renderText({
      format(nrow(filtered_data()), big.mark = ",")
    })
    
    # 輸出：區隔數量
    output$segment_count <- renderText({
      length(unique(filtered_data()$segment_chinese))
    })
    
    # 輸出：平均客戶價值
    output$avg_value <- renderText({
      data <- filtered_data()
      if (nrow(data) == 0 || !"customer_value" %in% names(data)) {
        return("$0")
      }
      
      # 確保 customer_value 是數值型
      values <- as.numeric(data$customer_value)
      avg_val <- mean(values, na.rm = TRUE)
      
      if (is.na(avg_val) || is.nan(avg_val)) {
        return("$0")
      }
      
      paste0("$", format(round(avg_val, 2), big.mark = ","))
    })
    
    # 輸出：Email 完整率
    output$email_rate <- renderText({
      data <- filtered_data()
      valid_emails <- sum(!is.na(data$customer_email) & data$customer_email != "")
      rate <- (valid_emails / nrow(data)) * 100
      paste0(round(rate, 1), "%")
    })
    
    # 輸出：資料表格
    output$segment_table <- DT::renderDataTable({
      data <- filtered_data()
      
      # 檢查資料是否為空
      if (nrow(data) == 0) {
        return(DT::datatable(
          data.frame(訊息 = "無資料顯示，請先上傳資料或調整篩選條件"),
          options = list(dom = 't'),
          rownames = FALSE
        ))
      }
      
      # 動態選擇存在的欄位
      available_cols <- names(data)
      display_cols <- c()
      col_names <- c()
      
      if ("customer_id" %in% available_cols) {
        display_cols <- c(display_cols, "customer_id")
        col_names <- c(col_names, "客戶ID")
      }
      
      if ("customer_email" %in% available_cols) {
        display_cols <- c(display_cols, "customer_email")
        col_names <- c(col_names, "Email")
      }
      
      if ("platform_name" %in% available_cols) {
        display_cols <- c(display_cols, "platform_name")
        col_names <- c(col_names, "平台")
      }
      
      if ("segment_chinese" %in% available_cols) {
        display_cols <- c(display_cols, "segment_chinese")
        col_names <- c(col_names, "客戶區隔")
      }
      
      if ("recency" %in% available_cols) {
        display_cols <- c(display_cols, "recency")
        col_names <- c(col_names, "最近購買(天)")
      }
      
      if ("frequency" %in% available_cols) {
        display_cols <- c(display_cols, "frequency")
        col_names <- c(col_names, "購買頻率")
      }
      
      if ("customer_value" %in% available_cols) {
        display_cols <- c(display_cols, "customer_value")
        col_names <- c(col_names, "客戶價值($)")
      }
      
      # 選擇要顯示的資料
      display_data <- data[, display_cols, drop = FALSE]
      names(display_data) <- col_names
      
      # 建立資料表
      dt <- DT::datatable(
        display_data,
        options = list(
          pageLength = 25,
          lengthMenu = c(10, 25, 50, 100),
          scrollX = TRUE,
          language = list(
            url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/Chinese-traditional.json"
          ),
          dom = 'Bfrtip',
          buttons = c('copy', 'print')
        ),
        rownames = FALSE,
        class = "display nowrap",
        filter = "top"
      )
      
      # 如果有客戶價值欄位，格式化貨幣
      if ("客戶價值($)" %in% names(display_data)) {
        dt <- dt %>% DT::formatCurrency("客戶價值($)", currency = "$", digits = 2)
      }
      
      # 如果有客戶區隔欄位，加上顏色樣式
      if ("客戶區隔" %in% names(display_data)) {
        # 取得所有可能的區隔值
        segments <- unique(display_data$客戶區隔)
        
        # 定義顏色對應
        color_map <- c(
          # 傳統 RFM 分類
          "冠軍客戶" = "#28a745", "忠誠客戶" = "#17a2b8", 
          "潛力客戶" = "#ffc107", "新客戶" = "#6c757d",
          "流失風險" = "#dc3545", "休眠客戶" = "#6c757d",
          # 簡單分類
          "高價值高頻" = "#28a745", "高價值低頻" = "#17a2b8",
          "低價值高頻" = "#ffc107", "中等客戶" = "#6c757d",
          "低價值低頻" = "#dc3545", 
          # 九宮格分類
          "A1C 王者引擎-C" = "#28a745", "A2C 王者穩健-C" = "#17a2b8", "A3C 王者休眠-C" = "#20c997",
          "B1C 成長火箭-C" = "#ffc107", "B2C 成長常規-C" = "#fd7e14", "B3C 成長停滯-C" = "#dc3545",
          "C1C 潛力新芽-C" = "#6c757d", "C2C 潛力維持-C" = "#6c757d", "C3C 清倉邊緣-C" = "#6c757d",
          "待分析" = "#e9ecef", "未分類" = "#e9ecef"
        )
        
        # 只對存在的區隔應用樣式
        existing_segments <- segments[segments %in% names(color_map)]
        if (length(existing_segments) > 0) {
          dt <- dt %>% DT::formatStyle(
            "客戶區隔",
            backgroundColor = DT::styleEqual(
              existing_segments,
              color_map[existing_segments]
            ),
            color = DT::styleEqual(
              existing_segments,
              ifelse(existing_segments == "待分析", "black", "white")
            )
          )
        }
      }
      
      return(dt)
    })
    
    # 下載 CSV
    output$download_csv <- downloadHandler(
      filename = function() {
        paste0("customer_segments_", Sys.Date(), ".csv")
      },
      content = function(file) {
        data <- filtered_data()
        write.csv(data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # 下載 Excel
    output$download_excel <- downloadHandler(
      filename = function() {
        paste0("customer_segments_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        data <- filtered_data()
        openxlsx::write.xlsx(data, file)
      }
    )
    
    # 區隔分佈圓餅圖
    output$segment_pie <- renderPlotly({
      data <- filtered_data()
      
      # 檢查是否有資料和區隔欄位
      if (nrow(data) == 0 || !"segment_chinese" %in% names(data)) {
        # 創建空白圖表，避免警告
        return(plot_ly(
          type = 'scatter',
          mode = 'text',
          x = c(0.5),
          y = c(0.5),
          text = "請上傳資料並執行分析",
          textfont = list(size = 20),
          hoverinfo = 'none',
          showlegend = FALSE
        ) %>% 
          layout(
            title = "無資料顯示",
            font = list(family = "Microsoft JhengHei"),
            xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
            yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
          ))
      }
      
      # 計算各區隔數量
      segment_counts <- table(data$segment_chinese)
      
      # 如果沒有區隔資料
      if (length(segment_counts) == 0) {
        return(plot_ly(
          type = 'scatter',
          mode = 'text',
          x = c(0.5),
          y = c(0.5),
          text = "無區隔資料",
          textfont = list(size = 20),
          hoverinfo = 'none',
          showlegend = FALSE
        ) %>% 
          layout(
            title = "無區隔資料",
            font = list(family = "Microsoft JhengHei"),
            xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
            yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
          ))
      }
      
      # 定義九宮格顏色（與九宮格模組一致）
      segment_colors <- c(
        "A1C 王者引擎-C" = "#28a745",
        "A2C 王者穩健-C" = "#17a2b8", 
        "A3C 王者休眠-C" = "#20c997",
        "B1C 成長火箭-C" = "#ffc107",
        "B2C 成長常規-C" = "#fd7e14",
        "B3C 成長停滯-C" = "#dc3545",
        "C1C 潛力新芽-C" = "#6f42c1",
        "C2C 潛力維持-C" = "#6c757d",
        "C3C 清倉邊緣-C" = "#343a40"
      )
      
      # 取得當前區隔的顏色
      current_segments <- names(segment_counts)
      colors_to_use <- segment_colors[current_segments]
      # 如果某些區隔沒有預設顏色，使用預設顏色集
      colors_to_use[is.na(colors_to_use)] <- c("#28a745", "#17a2b8", "#ffc107", "#6c757d", "#dc3545", "#fd7e14")[1:sum(is.na(colors_to_use))]
      
      plot_ly(
        labels = names(segment_counts),
        values = as.numeric(segment_counts),
        type = 'pie',
        textposition = 'inside',
        textinfo = 'label+percent',
        hoverinfo = 'text',
        text = paste(names(segment_counts), "<br>", 
                    as.numeric(segment_counts), "位客戶"),
        marker = list(
          colors = colors_to_use,
          line = list(color = '#FFFFFF', width = 2)
        )
      ) %>%
        layout(
          title = "客戶區隔分佈",
          showlegend = TRUE,
          font = list(family = "Microsoft JhengHei")
        )
    })
    
    # 價值分佈直方圖
    output$value_distribution <- renderPlotly({
      data <- filtered_data()
      
      # 檢查是否有資料和價值欄位
      if (nrow(data) == 0 || !"customer_value" %in% names(data)) {
        # 創建空白圖表，避免警告
        return(plot_ly(
          type = 'scatter',
          mode = 'text',
          x = c(0.5),
          y = c(0.5),
          text = "請上傳資料並執行分析",
          textfont = list(size = 20),
          hoverinfo = 'none',
          showlegend = FALSE
        ) %>% 
          layout(
            title = "無資料顯示",
            font = list(family = "Microsoft JhengHei"),
            xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
            yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
          ))
      }
      
      # 確保數值型態
      values <- as.numeric(data$customer_value)
      values <- values[!is.na(values) & !is.nan(values)]
      
      if (length(values) == 0) {
        return(plot_ly(
          type = 'scatter',
          mode = 'text',
          x = c(0.5),
          y = c(0.5),
          text = "無有效價值資料",
          textfont = list(size = 20),
          hoverinfo = 'none',
          showlegend = FALSE
        ) %>% 
          layout(
            title = "無有效價值資料",
            font = list(family = "Microsoft JhengHei"),
            xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
            yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
          ))
      }
      
      plot_ly(
        x = values,
        type = "histogram",
        nbinsx = 30,
        marker = list(
          color = '#ffc107',
          line = list(color = '#FFFFFF', width = 1)
        ),
        name = "客戶數"
      ) %>%
        layout(
          title = "客戶價值分佈",
          xaxis = list(title = "客戶價值 ($)"),
          yaxis = list(title = "客戶數量"),
          font = list(family = "Microsoft JhengHei"),
          showlegend = FALSE
        )
    })
    
    # 返回模組資料供其他模組使用
    return(list(
      data = filtered_data
    ))
  })
}