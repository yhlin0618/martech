# Multi-File DNA Analysis Module
# Supports Amazon sales data and general transaction files

library(shiny)
library(shinyjs)
library(dplyr)
library(DT)
library(plotly)
library(readxl)
library(later)

# Helper functions from microDNADistribution component
`%+%` <- function(x, y) paste0(x, y)
`%||%` <- function(x, y) if (is.null(x)) y else x
nrow2 <- function(x) {
  if (is.null(x)) return(0)
  if (!is.data.frame(x) && !is.matrix(x)) return(0)
  return(nrow(x))
}

# Source DNA analysis function
if (file.exists("scripts/global_scripts/04_utils/fn_analysis_dna.R")) {
  source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
  source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
  source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
  
  # 確保函數正確載入
  if (exists("analysis_dna")) {
    message("✓ DNA analysis function loaded successfully")
  }
}

# UI Function
dnaMultiModuleUI <- function(id) {
  ns <- NS(id)
  
  div(
    h3("Value × Activity 九宮格分析", style = "text-align: center; margin: 20px 0;"),
    
    # 下載按鈕區
    fluidRow(
      column(12,
        div(style = "text-align: right; margin-bottom: 20px;",
          downloadButton(ns("download_all_csv"), "下載所有客戶資料 (CSV)", 
                        class = "btn-success", icon = icon("file-csv")),
          downloadButton(ns("download_all_excel"), "下載所有客戶資料 (Excel)", 
                        class = "btn-info", icon = icon("file-excel"),
                        style = "margin-left: 10px;")
        )
      )
    ),
    
    # 九宮格分析
    fluidRow(
      # 高價值客戶
      column(4,
        bs4Card(
          title = "高價值 × 高活躍度",
          status = "success",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("high_value_high_activity"))
        )
      ),
      column(4,
        bs4Card(
          title = "高價值 × 中活躍度",
          status = "success",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("high_value_mid_activity"))
        )
      ),
      column(4,
        bs4Card(
          title = "高價值 × 低活躍度",
          status = "success",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("high_value_low_activity"))
        )
      )
    ),
    fluidRow(
      # 中價值客戶
      column(4,
        bs4Card(
          title = "中價值 × 高活躍度",
          status = "warning",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("mid_value_high_activity"))
        )
      ),
      column(4,
        bs4Card(
          title = "中價值 × 中活躍度",
          status = "warning",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("mid_value_mid_activity"))
        )
      ),
      column(4,
        bs4Card(
          title = "中價值 × 低活躍度",
          status = "warning",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("mid_value_low_activity"))
        )
      )
    ),
    fluidRow(
      # 低價值客戶
      column(4,
        bs4Card(
          title = "低價值 × 高活躍度",
          status = "danger",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("low_value_high_activity"))
        )
      ),
      column(4,
        bs4Card(
          title = "低價值 × 中活躍度",
          status = "danger",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("low_value_mid_activity"))
        )
      ),
      column(4,
        bs4Card(
          title = "低價值 × 低活躍度",
          status = "danger",
          width = 12,
          solidHeader = TRUE,
          uiOutput(ns("low_value_low_activity"))
        )
      )
    ),
    
    # 資料預覽區塊
    fluidRow(
      column(12,
        bs4Card(
          title = "客戶資料預覽",
          status = "primary",
          width = 12,
          solidHeader = TRUE,
          collapsible = TRUE,
          collapsed = FALSE,
          maximizable = TRUE,
          DT::dataTableOutput(ns("customer_preview"))
        )
      )
    )
  )
}

# Server Function
dnaMultiModuleServer <- function(id, con, user_info, uploaded_dna_data = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values
    values <- reactiveValues(
      dna_results = NULL,
      status_text = "等待資料分析..."
    )
    
    # 監聽上傳的資料
    observe({
      if (!is.null(uploaded_dna_data) && !is.null(uploaded_dna_data())) {
        data <- uploaded_dna_data()
        
        # 檢查數據結構
        print("Received DNA data structure:")
        print(str(data))
        
        # 使用 fn_analysis_dna 函數進行分析
        if ("customer_id" %in% names(data) && exists("analysis_dna")) {
          tryCatch({
            # 使用 lineitem_price 作為金額（參照 l2_pro 的方法）
            if ("lineitem_price" %in% names(data)) {
              data$total_amount <- data$lineitem_price
            } else if ("total_amount" %in% names(data)) {
              # 如果已有 total_amount 欄位，直接使用
              print("Using existing total_amount column")
            } else {
              # 如果都沒有，嘗試其他可能的金額欄位
              amount_cols <- c("amount", "price", "revenue", "sales")
              found_col <- intersect(amount_cols, names(data))
              if (length(found_col) > 0) {
                data$total_amount <- data[[found_col[1]]]
                print(paste("Using", found_col[1], "as total_amount"))
              } else {
                stop("No amount column found in data")
              }
            }
            
            # 轉換payment_time為日期格式（如果需要）
            if ("payment_time" %in% names(data)) {
              data$date <- as.Date(substr(data$payment_time, 1, 10))
            }
            
            # 準備 analysis_dna 所需的資料格式（參照 l2_pro 的方法）
            # 需要兩個資料框：按客戶按日期彙總和按客戶彙總的資料
            
            # 1. 按客戶按日期彙總的資料 (df_sales_by_customer_by_date)
            df_sales_by_customer_by_date <- data %>%
              mutate(
                date = if ("date" %in% names(.)) date else as.Date(payment_time)
              ) %>%
              group_by(customer_id, date) %>%
              summarise(
                sum_spent_by_date = sum(total_amount, na.rm = TRUE),
                count_transactions_by_date = n(),
                payment_time = min(payment_time, na.rm = TRUE),
                .groups = 'drop'
              )
            
            # 2. 按客戶彙總的資料 (df_sales_by_customer) - 參照 l2_pro line 547-565
            df_sales_by_customer <- data %>%
              group_by(customer_id) %>%
              summarise(
                total_spent = sum(total_amount, na.rm = TRUE),
                times = n(),
                first_purchase = min(payment_time, na.rm = TRUE),
                last_purchase = max(payment_time, na.rm = TRUE),
                .groups = 'drop'
              ) %>%
              mutate(
                # 計算 IPT - 平均購買間隔時間
                ipt = pmax(as.numeric(difftime(last_purchase, first_purchase, units = "days")) / pmax(times - 1, 1), 1),
                # 計算其他 RFM 相關指標
                r_value = as.numeric(difftime(Sys.time(), last_purchase, units = "days")),
                f_value = times,
                m_value = total_spent / times,
                ni = times
              )
            
            # 呼叫 analysis_dna 函數
            print("Calling analysis_dna function...")
            dna_results <- analysis_dna(
              df_sales_by_customer = df_sales_by_customer,
              df_sales_by_customer_by_date = df_sales_by_customer_by_date,
              skip_within_subject = TRUE,  # 跳過某些複雜計算以提高速度
              verbose = TRUE
            )
            
            # 提取結果中的客戶資料
            if (!is.null(dna_results$data_by_customer)) {
              customer_data <- dna_results$data_by_customer
              
              # 使用 DNA 分析的結果，提取 M 和 F 值用於九宮格
              # 先檢查欄位是否存在
              if ("m_value" %in% names(customer_data)) {
                customer_data$M <- customer_data$m_value
              } else if ("total_spent" %in% names(customer_data)) {
                customer_data$M <- customer_data$total_spent
              } else {
                customer_data$M <- 0
              }
              
              if ("f_value" %in% names(customer_data)) {
                customer_data$F <- customer_data$f_value
              } else if ("ni" %in% names(customer_data)) {
                customer_data$F <- customer_data$ni
              } else if ("times" %in% names(customer_data)) {
                customer_data$F <- customer_data$times
              } else {
                customer_data$F <- 0
              }
              
              dna_data <- customer_data
              
              print("DNA Analysis Results from fn_analysis_dna:")
              print(paste("Customers analyzed:", nrow(dna_data)))
              print(paste("M range:", round(min(dna_data$M, na.rm=TRUE), 2), "-", round(max(dna_data$M, na.rm=TRUE), 2)))
              print(paste("F range:", round(min(dna_data$F, na.rm=TRUE), 2), "-", round(max(dna_data$F, na.rm=TRUE), 2)))
              
              values$dna_results <- dna_data
            } else {
              # 如果 analysis_dna 失敗，使用簡單計算作為備案
              print("Using fallback calculation...")
              dna_data <- df_sales_by_customer %>%
                rename(
                  M = total_spent,
                  F = times
                )
              
              values$dna_results <- dna_data
            }
            
          }, error = function(e) {
            print(paste("Error in DNA analysis:", e$message))
            # 錯誤時使用簡單的 M/F 計算作為備案
            if ("order_date" %in% names(data)) {
              dna_data <- data %>%
                group_by(customer_id) %>%
                summarise(
                  M = sum(total_amount, na.rm = TRUE),
                  F = n_distinct(order_date),
                  .groups = 'drop'
                )
              values$dna_results <- dna_data
            }
          })
        } else if ("customer_id" %in% names(data)) {
          # 如果 analysis_dna 函數不存在，使用原始簡單計算
          print("analysis_dna function not found, using simple calculation...")
          if ("order_date" %in% names(data)) {
            dna_data <- data %>%
              group_by(customer_id) %>%
              summarise(
                M = sum(total_amount, na.rm = TRUE),
                F = n_distinct(order_date),
                .groups = 'drop'
              )
            values$dna_results <- dna_data
          }
        }
      }
    })
    
    # 計算九宮格分析結果
    nine_grid_data <- reactive({
      req(values$dna_results)
      
      df <- values$dna_results
      
      # 確保M和F列存在且為數值型
      if (!all(c("M", "F") %in% names(df))) {
        print("Error: Missing M or F columns")
        return(NULL)
      }
      
      # 移除無效值
      df <- df[!is.na(df$M) & !is.na(df$F) & df$M >= 0 & df$F >= 0, ]
      
      if (nrow(df) == 0) {
        print("Error: No valid data after cleaning")
        return(NULL)
      }
      
      # 計算分位數 (使用20%和80%分位點)
      m_quantiles <- quantile(df$M, probs = c(0.2, 0.8), na.rm = TRUE)
      f_quantiles <- quantile(df$F, probs = c(0.2, 0.8), na.rm = TRUE)
      
      print("Quantiles:")
      print("M quantiles (20%, 80%):")
      print(m_quantiles)
      print("F quantiles (20%, 80%):")
      print(f_quantiles)
      
      # 處理分位數重複的情況 - 確保 breaks 是唯一的
      if (length(unique(m_quantiles)) < 2 || diff(m_quantiles) < 0.001) {
        # 如果M值分位數相同或太接近，使用三等分方法
        m_min <- min(df$M, na.rm = TRUE)
        m_max <- max(df$M, na.rm = TRUE)
        if (m_max - m_min < 0.001) {
          # 所有值都相同，創建微小差異
          m_breaks <- c(m_min - 0.001, m_min, m_min + 0.001, m_max + 0.001)
        } else {
          # 使用三等分
          m_breaks <- c(m_min - 0.001, 
                       m_min + (m_max - m_min) * 0.33, 
                       m_min + (m_max - m_min) * 0.67, 
                       m_max + 0.001)
        }
      } else {
        # 確保 breaks 唯一
        m_breaks <- c(min(df$M, na.rm = TRUE) - 0.001, 
                     m_quantiles[1], 
                     m_quantiles[2], 
                     max(df$M, na.rm = TRUE) + 0.001)
      }
      
      if (length(unique(f_quantiles)) < 2 || diff(f_quantiles) < 0.001) {
        # 如果F值分位數相同或太接近，使用三等分方法
        f_min <- min(df$F, na.rm = TRUE)
        f_max <- max(df$F, na.rm = TRUE)
        if (f_max - f_min < 0.001) {
          # 所有值都相同，創建微小差異
          f_breaks <- c(f_min - 0.001, f_min, f_min + 0.001, f_max + 0.001)
        } else {
          # 使用三等分
          f_breaks <- c(f_min - 0.001,
                       f_min + (f_max - f_min) * 0.33,
                       f_min + (f_max - f_min) * 0.67,
                       f_max + 0.001)
        }
      } else {
        # 確保 breaks 唯一
        f_breaks <- c(min(df$F, na.rm = TRUE) - 0.001,
                     f_quantiles[1],
                     f_quantiles[2],
                     max(df$F, na.rm = TRUE) + 0.001)
      }
      
      # 確保 breaks 是唯一且遞增的
      m_breaks <- sort(unique(m_breaks))
      f_breaks <- sort(unique(f_breaks))
      
      # 如果仍然沒有足夠的分割點，使用預設值
      if (length(m_breaks) < 4) {
        m_breaks <- c(0, 100, 500, max(df$M, na.rm = TRUE) + 1)
      }
      if (length(f_breaks) < 4) {
        f_breaks <- c(0, 1, 3, max(df$F, na.rm = TRUE) + 1)
      }
      
      # 分類
      df$value_level <- cut(df$M, 
                         breaks = m_breaks,
                         labels = c("低", "中", "高"),
                         include.lowest = TRUE,
                         right = FALSE)
      
      df$activity_level <- cut(df$F,
                            breaks = f_breaks,
                            labels = c("低", "中", "高"),
                            include.lowest = TRUE,
                            right = FALSE)
      
      # 加入特殊區隔名稱（基於 TagPilot Pro 的命名系統）
      df$segment_name <- with(df, {
        case_when(
          value_level == "高" & activity_level == "高" ~ "A1C 王者引擎-C",
          value_level == "高" & activity_level == "中" ~ "A2C 王者穩健-C",
          value_level == "高" & activity_level == "低" ~ "A3C 王者休眠-C",
          value_level == "中" & activity_level == "高" ~ "B1C 成長火箭-C",
          value_level == "中" & activity_level == "中" ~ "B2C 成長常規-C",
          value_level == "中" & activity_level == "低" ~ "B3C 成長停滯-C",
          value_level == "低" & activity_level == "高" ~ "C1C 潛力新芽-C",
          value_level == "低" & activity_level == "中" ~ "C2C 潛力維持-C",
          value_level == "低" & activity_level == "低" ~ "C3C 清倉邊緣-C",
          TRUE ~ "未分類"
        )
      })
      
      print("Break points:")
      print("M breaks (低: <20%, 中: 20-80%, 高: >80%):")
      print(m_breaks)
      print("F breaks (低: <20%, 中: 20-80%, 高: >80%):")
      print(f_breaks)
      
      print("Segment distribution:")
      print(table(df$value_level, df$activity_level))
      
      return(df)
    })
    
    # 生成九宮格內容
    generate_grid_content <- function(value_level, activity_level, df) {
      if (is.null(df)) {
        return(HTML('<div style="text-align: center; padding: 15px;">等待數據分析...</div>'))
      }
      
      # 計算該區段的客戶數
      customers <- df[df$value_level == value_level & df$activity_level == activity_level, ]
      count <- nrow(customers)
      
      # 計算該區段的平均值
      avg_m <- round(mean(customers$M, na.rm = TRUE), 2)
      avg_f <- round(mean(customers$F, na.rm = TRUE), 2)
      
      # 根據九宮格位置定義策略
      grid_position <- paste0(
        switch(value_level, "高" = "A", "中" = "B", "低" = "C"),
        switch(activity_level, "高" = "1", "中" = "2", "低" = "3")
      )
      
      strategy <- switch(grid_position,
        "A1" = list(
          title = "王者引擎",
          action = "VIP 社群、會員等級升級、試用新品「搶先權」",
          icon = "crown",
          kpi = "客戶維持率、客單"
        ),
        "A2" = list(
          title = "王者穩健",
          action = "優惠券分級（高門檻）、生日禮遇升級",
          icon = "star",
          kpi = "ARPU、淨推薦值"
        ),
        "A3" = list(
          title = "王者休眠",
          action = "專屬客服電話喚醒、「流失前後優惠」",
          icon = "user-clock",
          kpi = "喚醒率、成本/營收比"
        ),
        "B1" = list(
          title = "成長火箭",
          action = "組合加價購、訂閱制試用",
          icon = "chart-line",
          kpi = "升級率、毛利"
        ),
        "B2" = list(
          title = "成長常規",
          action = "例行EDM「月度熱銷」、累積點數",
          icon = "balance-scale",
          kpi = "FQ、月度營收"
        ),
        "B3" = list(
          title = "成長停滯",
          action = "回購折扣券、首購小禮包",
          icon = "history",
          kpi = "再購率"
        ),
        "C1" = list(
          title = "潛力新芽",
          action = "新手教學內容、首購加購「第二件半價」",
          icon = "seedling",
          kpi = "二購率"
        ),
        "C2" = list(
          title = "潛力維持",
          action = "配對低客單商品、小額免運",
          icon = "exchange-alt",
          kpi = "ROI、轉換率"
        ),
        "C3" = list(
          title = "潛力邊緣",
          action = "清庫存時購、退訂/封存管控",
          icon = "users",
          kpi = "清庫率、行銷成本"
        )
      )
      
      HTML(sprintf('
        <div style="text-align: center; padding: 15px;">
          <div style="font-size: 18px; font-weight: bold; color: #666; margin-bottom: 5px;">
            %s
          </div>
          <h3 style="margin-bottom: 15px;">
            <i class="fas fa-%s" style="margin-right: 10px;"></i>
            %s
          </h3>
          <div style="font-size: 24px; font-weight: bold; margin: 15px 0;">
            %d 位客戶
          </div>
          <div style="color: #666; margin: 10px 0;">
            平均消費: $%.2f<br>
            平均頻率: %.1f次
          </div>
          <div style="color: #666; margin-top: 10px;">
            建議策略：<br>
            <strong>%s</strong>
          </div>
          <div style="color: #888; margin-top: 5px; font-size: 12px;">
            KPI: %s
          </div>
        </div>
      ', grid_position, strategy$icon, strategy$title, count, avg_m, avg_f, strategy$action, strategy$kpi))
    }
    
    # 渲染各個九宮格
    output$high_value_high_activity <- renderUI({
      generate_grid_content("高", "高", nine_grid_data())
    })
    output$high_value_mid_activity <- renderUI({
      generate_grid_content("高", "中", nine_grid_data())
    })
    output$high_value_low_activity <- renderUI({
      generate_grid_content("高", "低", nine_grid_data())
    })
    output$mid_value_high_activity <- renderUI({
      generate_grid_content("中", "高", nine_grid_data())
    })
    output$mid_value_mid_activity <- renderUI({
      generate_grid_content("中", "中", nine_grid_data())
    })
    output$mid_value_low_activity <- renderUI({
      generate_grid_content("中", "低", nine_grid_data())
    })
    output$low_value_high_activity <- renderUI({
      generate_grid_content("低", "高", nine_grid_data())
    })
    output$low_value_mid_activity <- renderUI({
      generate_grid_content("低", "中", nine_grid_data())
    })
    output$low_value_low_activity <- renderUI({
      generate_grid_content("低", "低", nine_grid_data())
    })
    
    # 客戶資料預覽表格
    output$customer_preview <- DT::renderDataTable({
      data <- nine_grid_data()
      
      if (is.null(data) || nrow(data) == 0) {
        return(DT::datatable(data.frame(訊息 = "尚無資料，請先上傳銷售資料")))
      }
      
      # 準備顯示的資料
      display_data <- data %>%
        select(customer_id, M, F, value_level, activity_level, segment_name) %>%
        arrange(desc(M), desc(F))
      
      # 重新命名欄位為中文
      names(display_data) <- c("客戶ID", "總消費金額", "購買頻率", 
                               "價值等級", "活躍度等級", "客戶區隔")
      
      # 建立 DataTable
      DT::datatable(
        display_data,
        options = list(
          pageLength = 10,
          lengthMenu = c(10, 25, 50, 100),
          scrollX = TRUE,
          language = list(
            url = "//cdn.datatables.net/plug-ins/1.10.25/i18n/Chinese-traditional.json"
          ),
          dom = 'Bfrtip',
          buttons = c('copy', 'print')
        ),
        rownames = FALSE,
        class = "display nowrap"
      ) %>%
        DT::formatCurrency("總消費金額", currency = "$", digits = 2) %>%
        DT::formatRound("購買頻率", digits = 0) %>%
        DT::formatStyle(
          "客戶區隔",
          backgroundColor = DT::styleEqual(
            c("A1C 王者引擎-C", "A2C 王者穩健-C", "A3C 王者休眠-C",
              "B1C 成長火箭-C", "B2C 成長常規-C", "B3C 成長停滯-C",
              "C1C 潛力新芽-C", "C2C 潛力維持-C", "C3C 清倉邊緣-C"),
            c("#28a745", "#5cb85c", "#6c757d",
              "#17a2b8", "#5bc0de", "#868e96",
              "#ffc107", "#fd7e14", "#dc3545")
          ),
          color = DT::styleEqual(
            c("A1C 王者引擎-C", "A2C 王者穩健-C", "A3C 王者休眠-C"),
            c("white", "white", "white")
          )
        )
    })
    
    # 下載CSV功能
    output$download_all_csv <- downloadHandler(
      filename = function() {
        paste0("customer_segments_", Sys.Date(), ".csv")
      },
      content = function(file) {
        data <- nine_grid_data()
        if (!is.null(data)) {
          # 使用已有的 segment_name 欄位
          write.csv(data, file, row.names = FALSE, fileEncoding = "UTF-8")
        }
      }
    )
    
    # 下載Excel功能
    output$download_all_excel <- downloadHandler(
      filename = function() {
        paste0("customer_segments_", Sys.Date(), ".xlsx")
      },
      content = function(file) {
        data <- nine_grid_data()
        if (!is.null(data)) {
          # 確保有openxlsx套件
          if (!requireNamespace("openxlsx", quietly = TRUE)) {
            install.packages("openxlsx")
          }
          library(openxlsx)
          
          # 重新命名欄位為中文
          names(data)[names(data) == "customer_id"] <- "客戶ID"
          names(data)[names(data) == "M"] <- "總消費金額"
          names(data)[names(data) == "F"] <- "購買頻率"
          names(data)[names(data) == "value_level"] <- "價值等級"
          names(data)[names(data) == "activity_level"] <- "活躍度等級"
          names(data)[names(data) == "segment_name"] <- "客戶區隔"
          
          write.xlsx(data, file)
        }
      }
    )
  })
} 