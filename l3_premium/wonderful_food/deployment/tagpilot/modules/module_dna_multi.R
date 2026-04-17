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
}

# UI Function
dnaMultiModuleUI <- function(id) {
  ns <- NS(id)
  
  div(
    h3("Value × Activity × Lifecycle 分析", style = "text-align: center; margin: 20px 0;"),
    
    # 狀態顯示
    wellPanel(
      h4("📊 處理狀態"),
      verbatimTextOutput(ns("status"))
    ),
    
    # 分析設定
    conditionalPanel(
      condition = paste0("output['", ns("has_uploaded_data"), "'] == true"),
      wellPanel(
        h4("⚙️ 分析設定"),
        fluidRow(
          column(6, numericInput(ns("min_transactions"), "最少交易次數", value = 2, min = 1)),
          column(6, div(style = "margin-top: 25px;", 
                       actionButton(ns("analyze_uploaded"), "🚀 開始分析", class = "btn-success", style = "width: 100%;")))
        )
      )
    ),
    
    # 生命週期選擇器
    conditionalPanel(
      condition = paste0("output['", ns("show_results"), "'] == true"),
      fluidRow(
        column(12,
          bs4Card(
            title = "生命週期階段選擇",
            status = "primary",
            width = 12,
            solidHeader = TRUE,
            radioButtons(
              ns("lifecycle_stage"),
              label = "選擇生命週期階段：",
              choices = c(
                "新客" = "newbie",
                "主力客" = "active",
                "睡眠客" = "sleepy",
                "半睡客" = "half_sleepy",
                "沉睡客" = "dormant"
              ),
              selected = "newbie",
              inline = TRUE
            )
          )
        )
      ),
      
      # 九宮格分析
      uiOutput(ns("dynamic_grid"))
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
      status_text = "等待資料分析...",
      combined_data = NULL
    )
    
    # 檢查是否有從步驟1傳來的資料
    observe({
      if (!is.null(uploaded_dna_data) && !is.null(uploaded_dna_data())) {
        values$combined_data <- uploaded_dna_data()
        values$status_text <- paste("✅ 已從步驟1載入資料，共", nrow(uploaded_dna_data()), "筆記錄，", 
                                   length(unique(uploaded_dna_data()$customer_id)), "位客戶。點擊「開始分析」進行DNA分析。")
      }
    })
    
    # 控制是否顯示分析區塊
    output$has_uploaded_data <- reactive({
      !is.null(uploaded_dna_data) && !is.null(uploaded_dna_data()) && nrow(uploaded_dna_data()) > 0
    })
    outputOptions(output, "has_uploaded_data", suspendWhenHidden = FALSE)
    
    # 控制是否顯示結果
    output$show_results <- reactive({
      !is.null(values$dna_results)
    })
    outputOptions(output, "show_results", suspendWhenHidden = FALSE)
    
    # 狀態輸出
    output$status <- renderText({
      values$status_text
    })
    
    # DNA 分析函數
    analyze_data <- function(data, min_transactions, delta_factor) {
      tryCatch({
        values$status_text <- "📊 準備分析資料..."
        
        # Filter by minimum transactions
        customer_counts <- data %>%
          group_by(customer_id) %>%
          summarise(n_transactions = n(), .groups = "drop")
        
        valid_customers <- customer_counts %>%
          filter(n_transactions >= min_transactions) %>%
          pull(customer_id)
        
        filtered_data <- data %>%
          filter(customer_id %in% valid_customers)
        
        values$status_text <- paste("✅ 篩選後客戶:", length(valid_customers), "筆交易:", nrow(filtered_data))
        
        if (nrow(filtered_data) == 0) {
          values$status_text <- "❌ 沒有符合最少交易次數的客戶"
          return()
        }
        
        # 確保platform_id欄位存在
        if (!"platform_id" %in% names(filtered_data)) {
          filtered_data$platform_id <- "upload"
        }
        
        # Prepare data for DNA analysis
        sales_by_customer_by_date <- filtered_data %>%
          mutate(
            date = as.Date(payment_time)
          ) %>%
          group_by(customer_id, date) %>%
          summarise(
            sum_spent_by_date = sum(lineitem_price),
            count_transactions_by_date = n(),
            payment_time = min(payment_time),
            platform_id = "upload",
            .groups = "drop"
          )
        
        sales_by_customer <- filtered_data %>%
          group_by(customer_id) %>%
          summarise(
            total_spent = sum(lineitem_price),
            times = n(),
            first_purchase = min(payment_time),
            last_purchase = max(payment_time),
            platform_id = "upload",
            .groups = "drop"
          ) %>%
          mutate(
            ipt = pmax(as.numeric(difftime(last_purchase, first_purchase, units = "days")), 1),
            r_value = as.numeric(difftime(Sys.time(), last_purchase, units = "days")),
            f_value = times,
            m_value = total_spent / times,
            ni = times
          ) %>%
          select(customer_id, total_spent, times, first_purchase, last_purchase, 
                 ipt, r_value, f_value, m_value, ni, platform_id)
        
        # Run DNA analysis
        values$status_text <- "🧬 執行 DNA 分析..."
        
        if (exists("analysis_dna")) {
          # 設定完整的全域參數
          complete_global_params <- list(
            delta = delta_factor,
            ni_threshold = min_transactions,
            cai_breaks = c(0, 0.1, 0.9, 1),
            text_cai_label = c("逐漸不活躍", "穩定", "日益活躍"),
            f_breaks = c(-0.0001, 1.1, 2.1, Inf),
            text_f_label = c("低頻率", "中頻率", "高頻率"),
            r_breaks = c(-0.0001, 0.1, 0.9, 1.0001),
            text_r_label = c("長期不活躍", "中期不活躍", "近期購買"),
            m_breaks = c(-0.0001, 0.1, 0.9, 1.0001),
            text_m_label = c("低價值", "中價值", "高價值"),
            nes_breaks = c(0, 1, 2, 2.5, Inf),
            text_nes_label = c("E0", "S1", "S2", "S3")
          )
          
          # 執行 DNA 分析
          dna_results <- tryCatch({
            results <- analysis_dna(
              df_sales_by_customer = as.data.frame(sales_by_customer),
              df_sales_by_customer_by_date = as.data.frame(sales_by_customer_by_date),
              skip_within_subject = FALSE,
              verbose = TRUE,
              global_params = complete_global_params
            )
            
            # 驗證結果結構
            if (is.null(results) || !is.list(results)) {
              stop("DNA分析結果為空或格式不正確")
            }
            
            if (is.null(results$data_by_customer) || !is.data.frame(results$data_by_customer)) {
              if (is.list(results$data_by_customer)) {
                results$data_by_customer <- as.data.frame(results$data_by_customer, stringsAsFactors = FALSE)
              } else {
                stop("data_by_customer 不是有效的數據結構")
              }
            }
            
            # 確保必要欄位存在
            required_cols <- c("customer_id", "r_value", "f_value", "m_value")
            missing_cols <- setdiff(required_cols, names(results$data_by_customer))
            if (length(missing_cols) > 0) {
              stop(paste("缺少必要欄位:", paste(missing_cols, collapse = ", ")))
            }
            
            results
            
          }, error = function(e) {
            values$status_text <- paste("❌ DNA分析錯誤:", e$message)
            return(NULL)
          })
          
          if (!is.null(dna_results)) {
            # 檢查 data_by_customer 的結構
            print("DNA results structure:")
            print(names(dna_results$data_by_customer))
            
            # 新增生命週期分類
            customer_data <- dna_results$data_by_customer %>%
              mutate(
                # 確保必要欄位為數值型且處理 NA 值
                r_value = as.numeric(r_value),
                f_value = as.numeric(f_value),
                m_value = as.numeric(m_value),
                
                # 檢查 first_purchase 欄位是否存在，如果不存在則使用其他欄位
                first_purchase_clean = if("first_purchase" %in% names(.)) {
                  as.POSIXct(first_purchase)
                } else if("first_order_date" %in% names(.)) {
                  as.POSIXct(first_order_date)
                } else {
                  Sys.time() - 365*24*3600  # 預設為一年前
                },
                
                # 計算客戶年齡（天數）
                customer_age_days = as.numeric(difftime(Sys.time(), first_purchase_clean, units = "days")),
                
                # 根據 r_value 計算生命週期，加入 NA 處理
                lifecycle_stage = case_when(
                  is.na(r_value) | is.na(customer_age_days) ~ "unknown",
                  customer_age_days <= 30 ~ "newbie",
                  r_value <= 7 ~ "active",
                  r_value <= 14 ~ "sleepy",
                  r_value <= 21 ~ "half_sleepy",
                  TRUE ~ "dormant"
                ),
                
                # 使用圖片中表格的標準進行分類
                value_level = case_when(
                  is.na(m_value) ~ "未知",
                  # 根據表格：高 = CLV ≥ 80th pct且過去價值 ≥ 80th，中 = 20-80th pct，低 = ≤ 20th pct
                  # 這裡使用 m_value 的分位數來對應
                  m_value >= quantile(m_value, 0.8, na.rm = TRUE) ~ "高",
                  m_value >= quantile(m_value, 0.2, na.rm = TRUE) ~ "中",
                  TRUE ~ "低"
                ),
                activity_level = case_when(
                  is.na(f_value) ~ "未知",
                  # 根據表格：高 = CAI ≥ 80th pct 且購買頻率 ≥ 80th pct，中 = 20-80th pct，低 = ≤ 20th pct
                  # 這裡使用 f_value 的分位數來對應
                  f_value >= quantile(f_value, 0.8, na.rm = TRUE) ~ "高",
                  f_value >= quantile(f_value, 0.2, na.rm = TRUE) ~ "中",
                  TRUE ~ "低"
                )
              ) %>%
              # 過濾掉未知類型的資料
              filter(lifecycle_stage != "unknown", value_level != "未知", activity_level != "未知")
            
            dna_results$data_by_customer <- customer_data
            values$dna_results <- dna_results
            values$status_text <- "🎉 DNA 分析完成！"
          }
          
        } else {
          values$status_text <- "❌ analysis_dna 函數不存在，請檢查 global_scripts"
        }
        
      }, error = function(e) {
        values$status_text <- paste("❌ 分析錯誤:", e$message)
      })
    }
    
    # 分析已上傳的資料
    observeEvent(input$analyze_uploaded, {
      req(values$combined_data)
      
      min_trans <- ifelse(is.null(input$min_transactions), 2, input$min_transactions)
      delta_val <- 0.1  # 固定時間折扣因子為0.1
      
      analyze_data(values$combined_data, min_trans, delta_val)
    })
    
    # 計算九宮格分析結果
    nine_grid_data <- reactive({
      req(values$dna_results, input$lifecycle_stage)
      
      df <- values$dna_results$data_by_customer
      
      # 過濾選定的生命週期階段
      df <- df[df$lifecycle_stage == input$lifecycle_stage, ]
      
      if (nrow(df) == 0) return(NULL)
      
      return(df)
    })
    
    # 生成九宮格內容
    generate_grid_content <- function(value_level, activity_level, df, lifecycle_stage) {
      if (is.null(df)) {
        return(HTML('<div style="text-align: center; padding: 15px;">無此生命週期階段的客戶</div>'))
      }
      
      # 計算該區段的客戶數
      customers <- df[df$value_level == value_level & df$activity_level == activity_level, ]
      count <- nrow(customers)
      
      if (count == 0) {
        return(HTML('<div style="text-align: center; padding: 15px;">無此類型客戶</div>'))
      }
      
      # 計算該區段的平均值
      avg_m <- round(mean(customers$m_value, na.rm = TRUE), 2)
      avg_f <- round(mean(customers$f_value, na.rm = TRUE), 2)
      
      # 根據九宮格位置和生命週期定義策略
      grid_position <- paste0(
        switch(value_level, "高" = "A", "中" = "B", "低" = "C"),
        switch(activity_level, "高" = "1", "中" = "2", "低" = "3"),
        switch(lifecycle_stage,
          "newbie" = "N",
          "active" = "C",
          "sleepy" = "D",
          "half_sleepy" = "H",
          "dormant" = "S"
        )
      )
      
      # 獲取策略
      strategy <- get_strategy(grid_position)
      
      # 如果策略為NULL（被隱藏的組合），返回空白內容
      if (is.null(strategy)) {
        return(HTML('<div style="text-align: center; padding: 15px;"></div>'))
      }
      
      # 根據不同生命週期階段設定不同的顏色
      stage_color <- switch(lifecycle_stage,
        "newbie" = "#4CAF50",      # 綠色
        "active" = "#2196F3",      # 藍色
        "sleepy" = "#FFC107",      # 黃色
        "half_sleepy" = "#FF9800", # 橙色
        "dormant" = "#F44336"      # 紅色
      )
      
      # 生成策略內容
      HTML(sprintf('
        <div style="text-align: center; padding: 15px; border-left: 4px solid %s;">
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
            平均M值: %.2f<br>
            平均F值: %.2f
          </div>
          <div style="color: #666; margin-top: 10px;">
            建議策略：<br>
            <strong>%s</strong>
          </div>
          <div style="color: #888; margin-top: 5px; font-size: 12px;">
            KPI: %s
          </div>
        </div>
      ', stage_color, grid_position, strategy$icon, strategy$title, count, avg_m, avg_f, strategy$action, strategy$kpi))
    }
    
    # 動態生成九宮格
    output$dynamic_grid <- renderUI({
      df <- nine_grid_data()
      
      if (is.null(df)) {
        return(
          div(style = "text-align: center; padding: 50px;",
              h4("請先完成資料上傳並進行分析"))
        )
      }
      
      current_stage <- input$lifecycle_stage
      
      div(
        h4(paste("生命週期階段:", 
                 switch(current_stage,
                        "newbie" = "新客",
                        "active" = "主力客", 
                        "sleepy" = "睡眠客",
                        "half_sleepy" = "半睡客",
                        "dormant" = "沉睡客")),
            style = "text-align: center; margin: 20px 0;"),
        
        # 高價值客戶
        fluidRow(
          column(4, bs4Card(title = "高價值 × 高活躍度", status = "success", width = 12, solidHeader = TRUE,
                          generate_grid_content("高", "高", df, current_stage))),
          column(4, bs4Card(title = "高價值 × 中活躍度", status = "success", width = 12, solidHeader = TRUE,
                          generate_grid_content("高", "中", df, current_stage))),
          column(4, bs4Card(title = "高價值 × 低活躍度", status = "success", width = 12, solidHeader = TRUE,
                          generate_grid_content("高", "低", df, current_stage)))
        ),
        
        # 中價值客戶
        fluidRow(
          column(4, bs4Card(title = "中價值 × 高活躍度", status = "warning", width = 12, solidHeader = TRUE,
                          generate_grid_content("中", "高", df, current_stage))),
          column(4, bs4Card(title = "中價值 × 中活躍度", status = "warning", width = 12, solidHeader = TRUE,
                          generate_grid_content("中", "中", df, current_stage))),
          column(4, bs4Card(title = "中價值 × 低活躍度", status = "warning", width = 12, solidHeader = TRUE,
                          generate_grid_content("中", "低", df, current_stage)))
        ),
        
        # 低價值客戶
        fluidRow(
          column(4, bs4Card(title = "低價值 × 高活躍度", status = "danger", width = 12, solidHeader = TRUE,
                          generate_grid_content("低", "高", df, current_stage))),
          column(4, bs4Card(title = "低價值 × 中活躍度", status = "danger", width = 12, solidHeader = TRUE,
                          generate_grid_content("低", "中", df, current_stage))),
          column(4, bs4Card(title = "低價值 × 低活躍度", status = "danger", width = 12, solidHeader = TRUE,
                          generate_grid_content("低", "低", df, current_stage)))
        )
      )
    })
  })
}

# 策略定義函數
get_strategy <- function(grid_position) {
  # 需要隱藏的組合
  hidden_segments <- c("A1N", "A2N", "B1N", "B2N", "C1N", "C2N")
  
  # 如果是需要隱藏的組合，返回NULL
  if (grid_position %in% hidden_segments) {
    return(NULL)
  }
  
  # 根據45種不同組合返回相應的策略
  strategies <- list(
    # 新客策略 (N) - 只保留A3N, B3N, C3N
    "A3N" = list(
      title = "王者休眠-N",
      action = "首購後 48h 無互動 → 專屬客服問候",
      icon = "user-clock",
      kpi = "高V 低A 新客"
    ),
    "B3N" = list(
      title = "成長停滯-N",
      action = "首購加碼券 (限 72h)",
      icon = "pause",
      kpi = "中V 低A 新客"
    ),
    "C3N" = list(
      title = "清倉邊緣-N",
      action = "取消後續推播、只留月度新品 EDM",
      icon = "trash",
      kpi = "低V 低A 新客"
    ),

    # 主力客策略 (C)
    "A1C" = list(
      title = "王者引擎-C",
      action = "VIP 社群 + 新品搶先權",
      icon = "crown",
      kpi = "高V 高A 主力"
    ),
    "A2C" = list(
      title = "王者穩健-C",
      action = "階梯折扣券 (高門檻)",
      icon = "star",
      kpi = "高V 中A 主力"
    ),
    "A3C" = list(
      title = "王者休眠-C",
      action = "高值客深度訪談 + 專屬客服",
      icon = "user-clock",
      kpi = "高V 低A 主力"
    ),
    "B1C" = list(
      title = "成長火箭-C",
      action = "訂閱制試用 + 個性化推薦",
      icon = "rocket",
      kpi = "中V 高A 主力"
    ),
    "B2C" = list(
      title = "成長常規-C",
      action = "點數倍數日/會員日",
      icon = "chart-line",
      kpi = "中V 中A 主力"
    ),
    "B3C" = list(
      title = "成長停滯-C",
      action = "再購提醒 + 小樣包",
      icon = "pause",
      kpi = "中V 低A 主力"
    ),
    "C1C" = list(
      title = "潛力新芽-C",
      action = "引導升級高單價品",
      icon = "seedling",
      kpi = "低V 高A 主力"
    ),
    "C2C" = list(
      title = "潛力維持-C",
      action = "補貨提醒 + 省運方案",
      icon = "balance-scale",
      kpi = "低V 中A 主力"
    ),
    "C3C" = list(
      title = "清倉邊緣-C",
      action = "低成本關懷：避免過度促銷",
      icon = "trash",
      kpi = "低V 低A 主力"
    ),

    # 瞌睡客策略 (D)
    "A1D" = list(
      title = "王者引擎-D",
      action = "專屬醒修券 (8 折上限)",
      icon = "crown",
      kpi = "高V 高A 瞌睡"
    ),
    "A2D" = list(
      title = "王者穩健-D",
      action = "客服致電關懷 + NPS 調查",
      icon = "star",
      kpi = "高V 中A 瞌睡"
    ),
    "A3D" = list(
      title = "王者休眠-D",
      action = "Win-Back 套餐 + VIP 續會禮",
      icon = "user-clock",
      kpi = "高V 低A 瞌睡"
    ),
    "B1D" = list(
      title = "成長火箭-D",
      action = "小遊戲抽獎 + 回購券",
      icon = "rocket",
      kpi = "中V 高A 瞌睡"
    ),
    "B2D" = list(
      title = "成長常規-D",
      action = "品類換血建議 + 搭售優惠",
      icon = "chart-line",
      kpi = "中V 中A 瞌睡"
    ),
    "B3D" = list(
      title = "成長停滯-D",
      action = "Push+SMS 雙管齊下",
      icon = "pause",
      kpi = "中V 低A 瞌睡"
    ),
    "C1D" = list(
      title = "潛力新芽-D",
      action = "低價快速回購品推薦",
      icon = "seedling",
      kpi = "低V 高A 瞌睡"
    ),
    "C2D" = list(
      title = "潛力維持-D",
      action = "簡訊喚醒 + 滿額贈",
      icon = "balance-scale",
      kpi = "低V 中A 瞌睡"
    ),
    "C3D" = list(
      title = "清倉邊緣-D",
      action = "清庫存閃購一天",
      icon = "trash",
      kpi = "低V 低A 瞌睡"
    ),

    # 半睡客策略 (H)
    "A1H" = list(
      title = "王者引擎-H",
      action = "專屬客服 + 差異化補貼",
      icon = "crown",
      kpi = "高V 高A 半睡"
    ),
    "A2H" = list(
      title = "王者穩健-H",
      action = "兩步式「問卷→優惠」",
      icon = "star",
      kpi = "高V 中A 半睡"
    ),
    "A3H" = list(
      title = "王者休眠-H",
      action = "VIP 醒修券...滿額升等",
      icon = "user-clock",
      kpi = "高V 低A 半睡"
    ),
    "B1H" = list(
      title = "成長火箭-H",
      action = "會員日兌換券",
      icon = "rocket",
      kpi = "中V 高A 半睡"
    ),
    "B2H" = list(
      title = "成長常規-H",
      action = "價格敏品小額試用",
      icon = "chart-line",
      kpi = "中V 中A 半睡"
    ),
    "B3H" = list(
      title = "成長停滯-H",
      action = "封存前最後折扣",
      icon = "pause",
      kpi = "中V 低A 半睡"
    ),
    "C1H" = list(
      title = "潛力新芽-H",
      action = "爆款低價促購",
      icon = "seedling",
      kpi = "低V 高A 半睡"
    ),
    "C2H" = list(
      title = "潛力維持-H",
      action = "免運券 + 再購提醒",
      icon = "balance-scale",
      kpi = "低V 中A 半睡"
    ),
    "C3H" = list(
      title = "清倉邊緣-H",
      action = "月度 EDM；不再 Push",
      icon = "trash",
      kpi = "低V 低A 半睡"
    ),

    # 沉睡客策略 (S)
    "A1S" = list(
      title = "王者引擎-S",
      action = "客服電話 + 專屬復活禮盒",
      icon = "crown",
      kpi = "高V 高A 沉睡"
    ),
    "A2S" = list(
      title = "王者穩健-S",
      action = "高值客流失調查 + 買一送一",
      icon = "star",
      kpi = "高V 中A 沉睡"
    ),
    "A3S" = list(
      title = "王者休眠-S",
      action = "只做客情維繫，勿頻促",
      icon = "user-clock",
      kpi = "高V 低A 沉睡"
    ),
    "B1S" = list(
      title = "成長火箭-S",
      action = "不定期驚喜包",
      icon = "rocket",
      kpi = "中V 高A 沉睡"
    ),
    "B2S" = list(
      title = "成長常規-S",
      action = "庫存清倉先行名單",
      icon = "chart-line",
      kpi = "中V 中A 沉睡"
    ),
    "B3S" = list(
      title = "成長停滯-S",
      action = "定向廣告 retarget + SMS",
      icon = "pause",
      kpi = "中V 低A 沉睡"
    ),
    "C1S" = list(
      title = "潛力新芽-S",
      action = "簡訊一次 + 退訂選項",
      icon = "seedling",
      kpi = "低V 高A 沉睡"
    ),
    "C2S" = list(
      title = "潛力維持-S",
      action = "只保留月報 EDM",
      icon = "balance-scale",
      kpi = "低V 中A 沉睡"
    ),
    "C3S" = list(
      title = "清倉邊緣-S",
      action = "名單除重/不再接觸",
      icon = "trash",
      kpi = "低V 低A 沉睡"
    )
  )
  
  # 如果找不到對應策略，返回預設值
  default_strategy <- list(
    title = paste("分類", grid_position),
    action = "一般性行銷活動",
    icon = "users",
    kpi = "基礎指標追蹤"
  )
  
  return(strategies[[grid_position]] %||% default_strategy)
} 