# Multi-File DNA Analysis Module
# Supports Amazon sales data and general transaction files

library(shiny)
library(shinyjs)
library(dplyr)
library(DT)
library(plotly)
library(readxl)
library(later)
library(markdown)

# 載入提示和prompt系統
source("utils/hint_system.R")
source("utils/prompt_manager.R")

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
dnaMultiModuleUI <- function(id, enable_hints = TRUE) {
  ns <- NS(id)
  
  # 載入提示資料
  hints_df <- if(enable_hints) load_hints() else NULL
  
  div(
    # 初始化 shinyjs
    useShinyjs(),
    
    # 初始化提示系統
    if(enable_hints) init_hint_system() else NULL,
    
    h3("🧬 客戶 DNA 分析"),
    
    # Conditional File Upload Section (only show if no data uploaded from step 1)
    conditionalPanel(
      condition = paste0("output['", ns("has_uploaded_data"), "'] == false"),
      h4("📁 額外檔案上傳 (可選)"),
      fluidRow(
        column(6,
          wellPanel(
            h4("📁 多檔案上傳"),
            # 為檔案上傳添加提示
            add_hint_bs4(
              fileInput(ns("multi_files"), 
                       "選擇多個CSV檔案",
                       multiple = TRUE,
                       accept = c(".csv", ".xlsx", ".xls")),
              var_id = "upload_button",
              hints_df = hints_df,
              enable_hints = enable_hints
            ),
            
            p("支援: Amazon銷售報告、一般交易記錄"),
            p("自動偵測: Buyer Email (客戶ID), Purchase Date (時間), Item Price (金額)"),
            
            verbatimTextOutput(ns("file_info"))
          )
        ),
        
        column(6,
          wellPanel(
            h4("⚙️ 分析設定"),
            # 為分析參數添加提示
            add_hint_bs4(
              numericInput(ns("min_transactions"), "最少交易次數", value = 2, min = 1),
              var_id = "customer_segmentation",
              hints_df = hints_df,
              enable_hints = enable_hints
            ),
            checkboxInput(ns("auto_detect"), "自動偵測欄位", value = TRUE),
            br(),
            # 為分析按鈕添加提示
            add_hint_bs4(
              actionButton(ns("process_files"), "🚀 合併檔案並分析", class = "btn-success"),
              var_id = "kpi_dashboard",
              hints_df = hints_df,
              enable_hints = enable_hints
            )
          )
        )
      )
    ),
    
    # Analysis controls (always show)
    conditionalPanel(
      condition = paste0("output['", ns("has_uploaded_data"), "'] == true"),
      wellPanel(
        h4("⚙️ 分析設定"),
        fluidRow(
          column(6, 
                 add_hint_bs4(
                   numericInput(ns("min_transactions_2"), "最少交易次數", value = 2, min = 1),
                   var_id = "customer_segmentation",
                   hints_df = hints_df,
                   enable_hints = enable_hints
                 )),
          column(6, div(style = "margin-top: 25px;", 
                       add_hint_bs4(
                         actionButton(ns("analyze_uploaded"), "🚀 開始分析", class = "btn-success", style = "width: 100%;"),
                         var_id = "kpi_dashboard",
                         hints_df = hints_df,
                         enable_hints = enable_hints
                       )))
        )
      )
    ),
    
    # Status
    wellPanel(
      h4("📊 處理狀態"),
      verbatimTextOutput(ns("status"))
    ),
    
    # Results
    conditionalPanel(
      condition = paste0("output['", ns("show_results"), "'] == true"),
      
      h4("📈 DNA 分析結果"),
      
      fluidRow(
        # 左側：顧客標籤選擇
        column(3,
          wellPanel(
            style = "background: #f8f9fa;",
            h5("🏷️ 顧客標籤"),
            p("請點選顧客標籤，即可看到各標籤的視覺化圖形", style = "font-size: 13px; color: #6c757d;"),
            hr(),
            actionButton(ns("show_m"), "💰 購買金額", class = "btn-outline-info btn-block", style = "margin-bottom: 10px;"),
            actionButton(ns("show_r"), "🕒 最近來店時間", class = "btn-outline-info btn-block", style = "margin-bottom: 10px;"),
            actionButton(ns("show_f"), "🔁 購買頻率", class = "btn-outline-info btn-block", style = "margin-bottom: 10px;"),
            actionButton(ns("show_cai"), "📈 顧客活躍度", class = "btn-outline-info btn-block", style = "margin-bottom: 10px;"),
            actionButton(ns("show_pcv"), "💎 過去價值", class = "btn-outline-info btn-block", style = "margin-bottom: 10px;"),
            actionButton(ns("show_cri"), "🎯 參與度分數", class = "btn-outline-info btn-block", style = "margin-bottom: 10px;"),
            actionButton(ns("show_nes"), "👥 顧客狀態", class = "btn-outline-warning btn-block", style = "margin-bottom: 10px;"),
            hr(),
            h6("🔧 分析工具"),
            actionButton(ns("run_segmentation"), "📊 執行客戶分群", class = "btn-primary btn-block", style = "margin-bottom: 10px;"),
            actionButton(ns("run_ai_analysis"), "🤖 執行AI增強分析", class = "btn-success btn-block", style = "margin-bottom: 10px;"),
            hr(),
            h6("📊 檢視選項"),
            radioButtons(ns("view_mode"), NULL,
              choices = list(
                "統計圖表" = "charts",
                "AI分析結果" = "ai_results",
                "客群分組" = "segmentation"
              ),
              selected = "charts"
            ),
            hr(),
            h6("🤖 指標說明"),
            div(
              id = ns("ai_metric_description"),
              style = "background: white; padding: 10px; border-radius: 5px; font-size: 13px; min-height: 150px;",
              uiOutput(ns("metric_ai_description"))
            )
          )
        ),
        # 右側：動態內容區
        column(9,
          # 統計圖表視圖
          conditionalPanel(
            condition = "input.view_mode == 'charts'",
            ns = ns,
            wellPanel(
              h5("📊 視覺化分析"),
              fluidRow(
                column(6,
                  h6("ECDF 累積分佈圖", style = "text-align: center; font-weight: bold;"),
                  plotlyOutput(ns("plot_ecdf"), height = "350px"),
                  div(
                    style = "background: #e8f4f8; padding: 10px; border-radius: 5px; margin-top: 10px; font-size: 13px;",
                    uiOutput(ns("ecdf_insight"))
                  )
                ),
                column(6,
                  h6("分佈直方圖", style = "text-align: center; font-weight: bold;"),
                  plotlyOutput(ns("plot_hist"), height = "350px"),
                  div(
                    style = "background: #fff3cd; padding: 10px; border-radius: 5px; margin-top: 10px; font-size: 13px;",
                    uiOutput(ns("hist_insight"))
                  )
                )
              )
            )
          ),
          
          # AI分析結果視圖
          conditionalPanel(
            condition = "input.view_mode == 'ai_results'",
            ns = ns,
            wellPanel(
              h5("🤖 AI 深度分析結果"),
              conditionalPanel(
                condition = paste0("output['", ns("has_ai_analysis"), "'] == false"),
                div(
                  style = "text-align: center; padding: 40px;",
                  icon("robot", "fa-3x", style = "color: #6c757d;"),
                  h4("請先執行 AI 分析", style = "margin-top: 20px;"),
                  p("點擊左側「執行AI分析」按鈕開始智能分析", style = "color: #6c757d;")
                )
              ),
              conditionalPanel(
                condition = paste0("output['", ns("has_ai_analysis"), "'] == true"),
                uiOutput(ns("ai_analysis_results"))
              )
            )
          ),
          
          # 客群分組視圖
          conditionalPanel(
            condition = "input.view_mode == 'segmentation'",
            ns = ns,
            wellPanel(
              h5("👥 客群分組分析"),
              conditionalPanel(
                condition = paste0("output['", ns("has_segmentation"), "'] == false"),
                div(
                  style = "text-align: center; padding: 40px;",
                  icon("users", "fa-3x", style = "color: #6c757d;"),
                  h4("請選擇分析指標", style = "margin-top: 20px;"),
                  p("點擊左側任一指標按鈕即可自動進行客群分組", style = "color: #6c757d;")
                )
              ),
              conditionalPanel(
                condition = paste0("output['", ns("has_segmentation"), "'] == true"),
                uiOutput(ns("segmentation_view"))
              )
            )
          )
        )
      ),
      
      br(),
      
      # 資料表獨立成新的區塊
      h4("顧客資訊"),
      tabsetPanel(
        tabPanel("📄 顧客標籤分析",
          fluidRow(
            column(12,
              wellPanel(
                fluidRow(
                  column(4, checkboxInput(ns("convert_to_text"), "將數值轉換為高中低文字", value = FALSE)),
                  column(4, 
                    downloadButton(ns("download_analysis_data"), "📥 下載分析資料", 
                                  class = "btn-primary btn-sm", 
                                  style = "margin-top: 20px;")
                  ),
                  column(4, div(style = "margin-top: 25px;", 
                               textOutput(ns("table_info"), inline = TRUE)))
                )
              )
            )
          ),
          DTOutput(ns("dna_table"))
        ),
        tabPanel("📈 統計", DTOutput(ns("summary_table"))),
        tabPanel("📖 結果說明", 
          div(style = "padding: 20px;",
            htmlOutput(ns("dna_explanation"))
          )
        ),
        # Email mapping tab (only show if email mapping exists)
        conditionalPanel(
          condition = paste0("output['", ns("has_email_mapping"), "'] == true"),
          tabPanel("📧 客戶ID映射", DTOutput(ns("email_mapping_table")))
        ),
        tabPanel("🤖 AI 分析", 
          div(
            style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 20px;",
            conditionalPanel(
              condition = paste0("output['", ns("has_ai_insights"), "'] == false"),
              p("執行 DNA 分析後，AI 將提供深入的客戶洞察和建議。", 
                style = "color: #6c757d; margin: 0;")
            ),
            conditionalPanel(
              condition = paste0("output['", ns("has_ai_insights"), "'] == true"),
              uiOutput(ns("ai_insights_content"))
            )
          )
        )
      )
    )
  )
}

# Server Function
dnaMultiModuleServer <- function(id, con, user_info, uploaded_dna_data = NULL, chat_api = NULL, enable_hints = TRUE, enable_prompts = TRUE) {
  moduleServer(id, function(input, output, session) {
    
    # 載入 prompts（在模組初始化時）
    prompts_df <- if(enable_prompts) load_prompts() else NULL
    
    # 如果啟用提示，定期觸發提示初始化
    if(enable_hints) {
      observe({
        trigger_hint_init(session)
      })
    }
    ns <- session$ns
    
    # Reactive values
    values <- reactiveValues(
      files_info = NULL,
      combined_data = NULL,
      dna_results = NULL,
      current_metric = "M",
      status_text = "等待檔案上傳...",
      ai_insights = NULL,
      segmented_data = NULL,
      ai_analysis_done = FALSE,
      ai_recommendations = NULL,
      ai_analysis_summary = NULL,
      ai_summary = NULL,
      temp_chinese_table = NULL  # 新增：統一的中文欄位表格
    )
    
    # 檢查是否有從步驟1傳來的資料
    observe({
      if (!is.null(uploaded_dna_data) && !is.null(uploaded_dna_data())) {
        values$combined_data <- uploaded_dna_data()
        values$status_text <- paste("✅ 已從步驟1載入資料，共", nrow(uploaded_dna_data()), "筆記錄，", 
                                   length(unique(uploaded_dna_data()$customer_id)), "位客戶。點擊「開始分析」進行DNA分析。")
        
        # 設置標記表示資料已準備好自動分析
        values$auto_analyze_ready <- TRUE
      }
    })
    
    # 控制是否顯示上傳區塊
    output$has_uploaded_data <- reactive({
      !is.null(uploaded_dna_data) && !is.null(uploaded_dna_data()) && nrow(uploaded_dna_data()) > 0
    })
    outputOptions(output, "has_uploaded_data", suspendWhenHidden = FALSE)
    
    # 自動分析觸發器
    observe({
      if (!is.null(values$auto_analyze_ready) && values$auto_analyze_ready && 
          !is.null(values$combined_data) && is.null(values$dna_results)) {
        values$auto_analyze_ready <- FALSE  # 防止重複觸發
        values$status_text <- "🚀 自動開始DNA分析..."
        analyze_data(values$combined_data, 2, 0.1)  # 固定時間折扣因子為0.1
      }
    })
    
    # File upload handler
    observeEvent(input$multi_files, {
      req(input$multi_files)
      
      values$files_info <- input$multi_files
      file_names <- input$multi_files$name
      
      output$file_info <- renderText({
        paste("已選擇", length(file_names), "個檔案:\n",
              paste(file_names, collapse = "\n"))
      })
      
      values$status_text <- paste("已上傳", length(file_names), "個檔案，準備處理...")
    })
    
    # Field detection function
    detect_fields <- function(df) {
      cols <- tolower(names(df))
      original_names <- names(df)
      
      # Customer ID (prioritize email)
      customer_field <- NULL
      email_patterns <- c("buyer email", "buyer_email", "buyer.email", "email")
      id_patterns <- c("customer_id", "customer", "buyer_id")
      
      # 先檢查電子郵件欄位（優先）
      for (pattern in email_patterns) {
        matches <- grepl(pattern, cols, fixed = TRUE)
        if (any(matches)) {
          customer_field <- original_names[matches][1]
          break
        }
      }
      
      # 如果沒找到電子郵件欄位，檢查一般ID欄位
      if (is.null(customer_field)) {
        for (pattern in id_patterns) {
          matches <- grepl(pattern, cols, fixed = TRUE)
          if (any(matches)) {
            customer_field <- original_names[matches][1]
            break
          }
        }
      }
      
      # Time field (包含Amazon格式)
      time_field <- NULL
      time_patterns <- c("purchase date", "purchase.date", "payments date", "payments.date", 
                        "payment_time", "date", "time")
      for (pattern in time_patterns) {
        matches <- grepl(pattern, cols, fixed = TRUE)
        if (any(matches)) {
          time_field <- original_names[matches][1]
          break
        }
      }
      
      # Amount field (包含Amazon格式)
      amount_field <- NULL
      amount_patterns <- c("item price", "item.price", "lineitem_price", "amount", "sales", "price")
      for (pattern in amount_patterns) {
        matches <- grepl(pattern, cols, fixed = TRUE)
        if (any(matches)) {
          amount_field <- original_names[matches][1]
          break
        }
      }
      
      return(list(customer_id = customer_field, time = time_field, amount = amount_field))
    }
    
    # 通用分析函數
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
            # customer_id 已經是數值型，不需要再次轉換
          ) %>%
          group_by(customer_id, date) %>%
          summarise(
            sum_spent_by_date = sum(lineitem_price),
            count_transactions_by_date = n(),
            payment_time = min(payment_time),  # 添加時間欄位供analysis_dna使用
            platform_id = "upload",  # 固定值，避免first()錯誤
            .groups = "drop"
          )
        
        sales_by_customer <- filtered_data %>%
          # customer_id 已經是數值型，不需要再次轉換
          group_by(customer_id) %>%
          summarise(
            total_spent = sum(lineitem_price),
            times = n(),
            first_purchase = min(payment_time),
            last_purchase = max(payment_time),
            platform_id = "upload",  # 固定值，避免first()錯誤
            .groups = "drop"
          ) %>%
          mutate(
            # customer_id 已經是數值型，不需要再次轉換
            ipt = pmax(as.numeric(difftime(last_purchase, first_purchase, units = "days")), 1),  # 避免0值
            r_value = as.numeric(difftime(Sys.time(), last_purchase, units = "days")),
            f_value = times,
            m_value = total_spent / times,
            ni = times,
            # 計算客戶生命週期
            customer_lifespan = as.numeric(difftime(last_purchase, first_purchase, units = "days"))
          ) %>%
          # 確保所有必要欄位存在且有正確的資料類型
          select(customer_id, total_spent, times, first_purchase, last_purchase, 
                 ipt, r_value, f_value, m_value, ni, platform_id, customer_lifespan)
        
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
          
          # 執行 DNA 分析並加入錯誤處理
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
              # 如果data_by_customer不是數據框，嘗試轉換
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
              # 嘗試從其他來源補充缺失的欄位
              if(!"r_value" %in% names(results$data_by_customer) && "r" %in% names(results$data_by_customer)) {
                results$data_by_customer$r_value <- results$data_by_customer$r
              }
              if(!"f_value" %in% names(results$data_by_customer) && "f" %in% names(results$data_by_customer)) {
                results$data_by_customer$f_value <- results$data_by_customer$f
              }
              if(!"m_value" %in% names(results$data_by_customer) && "m" %in% names(results$data_by_customer)) {
                results$data_by_customer$m_value <- results$data_by_customer$m
              }
              
              # 再次檢查
              missing_cols <- setdiff(required_cols, names(results$data_by_customer))
              if (length(missing_cols) > 0) {
                stop(paste("缺少必要欄位:", paste(missing_cols, collapse = ", ")))
              }
            }
            
            # 補充可能缺失的額外欄位
            if(!"cri" %in% names(results$data_by_customer) && 
               all(c("r_value", "f_value", "m_value") %in% names(results$data_by_customer))) {
              # 計算 CRI (Customer Regularity Index)
              results$data_by_customer$cri <- with(results$data_by_customer,
                0.3 * pmin(pmax(r_value, 0), 1) + 
                0.3 * pmin(pmax(f_value, 0), 1) + 
                0.4 * pmin(pmax(m_value, 0), 1)
              )
            }
            
            if(!"cai_value" %in% names(results$data_by_customer) && "cai" %in% names(results$data_by_customer)) {
              results$data_by_customer$cai_value <- results$data_by_customer$cai
            }
            
            if(!"pcv" %in% names(results$data_by_customer) && "total_spent" %in% names(results$data_by_customer)) {
              results$data_by_customer$pcv <- results$data_by_customer$total_spent
            }
            
            results
            
          }, error = function(e) {
            values$status_text <- paste("❌ DNA分析錯誤:", e$message)
            return(NULL)
          })
          
          if (!is.null(dna_results)) {
            # 補充額外的計算欄位
            if(!"total_spent" %in% names(dna_results$data_by_customer) && 
               "m_value" %in% names(dna_results$data_by_customer) && 
               "f_value" %in% names(dna_results$data_by_customer)) {
              dna_results$data_by_customer$total_spent <- 
                dna_results$data_by_customer$m_value * dna_results$data_by_customer$f_value
            }
            
            # 確保 CRI 存在
            if(!"cri" %in% names(dna_results$data_by_customer)) {
              # 標準化 RFM 值到 0-1 範圍
              normalize_01 <- function(x) {
                if(length(unique(x)) == 1) return(rep(0.5, length(x)))
                (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
              }
              
              # R值需要反向（值越小越好）
              r_norm <- 1 - normalize_01(dna_results$data_by_customer$r_value)
              f_norm <- normalize_01(dna_results$data_by_customer$f_value)
              m_norm <- normalize_01(dna_results$data_by_customer$m_value)
              
              dna_results$data_by_customer$cri <- 0.3 * r_norm + 0.3 * f_norm + 0.4 * m_norm
            }
            
            # 確保 CAI 值存在（如果有必要的數據）
            if(!"cai_value" %in% names(dna_results$data_by_customer) && 
               !"cai" %in% names(dna_results$data_by_customer)) {
              # 簡單的活躍度計算：基於最近購買時間的變化
              # 這裡使用簡化的方法：r_value < 30 為活躍(1), 30-90 為穩定(0), >90 為靜止(-1)
              dna_results$data_by_customer$cai_value <- ifelse(
                dna_results$data_by_customer$r_value < 30, 1,
                ifelse(dna_results$data_by_customer$r_value > 90, -1, 0)
              )
            }
            
            values$dna_results <- dna_results
            values$status_text <- "🎉 DNA 分析完成！"
            
            # 自動執行初始分群（使用預設的M指標）
            values$current_metric <- "M"
            updateMetricDescription("M")
            performSegmentation()
            
            # ---- AI 洞察分析（使用 Prompt 系統）--------------------------------
            if(enable_prompts && !is.null(chat_api)) {
              values$status_text <- "🤖 正在生成 AI 洞察..."
              
              # 準備分析數據摘要
              customer_data <- dna_results$data_by_customer
              summary_data <- list(
                total_customers = nrow(customer_data),
                avg_rfm_r = round(mean(customer_data$r_value, na.rm = TRUE), 2),
                avg_rfm_f = round(mean(customer_data$f_value, na.rm = TRUE), 2), 
                avg_rfm_m = round(mean(customer_data$m_value, na.rm = TRUE), 2),
                avg_clv = round(mean(customer_data$clv, na.rm = TRUE), 2),
                high_value_customers = sum(customer_data$m_value > 0.7, na.rm = TRUE),
                loyal_customers = sum(customer_data$f_value > 0.7, na.rm = TRUE),
                recent_customers = sum(customer_data$r_value > 0.7, na.rm = TRUE)
              )
              
              # 使用集中管理的 prompt 生成洞察
              tryCatch({
                ai_result <- execute_gpt_request(
                  var_id = "customer_segmentation_analysis",
                  variables = list(
                    customer_data = jsonlite::toJSON(summary_data, auto_unbox = TRUE),
                    segment_data = jsonlite::toJSON(
                      customer_data %>% 
                        select(customer_id, r_value, f_value, m_value, clv, nes_status) %>% 
                        head(10), 
                      auto_unbox = TRUE
                    )
                  ),
                  chat_api_function = chat_api,
                  model = "gpt-4o-mini",
                  prompts_df = prompts_df
                )
                
                values$ai_insights <- ai_result
                values$status_text <- "✅ DNA 分析與 AI 洞察完成！"
                
              }, error = function(e) {
                values$ai_insights <- "AI 分析暫時無法使用，請稍後再試。"
                cat("AI 分析錯誤:", e$message, "\n")
                values$status_text <- "✅ DNA 分析完成！（AI 洞察暫時無法使用）"
              })
            }
            
            output$show_results <- reactive(TRUE)
            outputOptions(output, "show_results", suspendWhenHidden = FALSE)
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
      
      min_trans <- ifelse(is.null(input$min_transactions_2), 2, input$min_transactions_2)
      delta_val <- 0.1  # 固定時間折扣因子為0.1
      
      analyze_data(values$combined_data, min_trans, delta_val)
    })
    
    # Process files
    observeEvent(input$process_files, {
      req(values$files_info)
      
      values$status_text <- "開始處理檔案..."
      
      tryCatch({
        all_data <- list()
        
        # Read all files
        for (i in seq_len(nrow(values$files_info))) {
          file_path <- values$files_info$datapath[i]
          file_name <- values$files_info$name[i]
          
          values$status_text <- paste("讀取檔案:", file_name)
          
          if (grepl("\\.csv$", file_name, ignore.case = TRUE)) {
            df <- read.csv(file_path, stringsAsFactors = FALSE)
          } else if (grepl("\\.(xlsx|xls)$", file_name, ignore.case = TRUE)) {
            df <- readxl::read_excel(file_path)
            df <- as.data.frame(df)
          }
          
          df$source_file <- file_name
          all_data[[i]] <- df
        }
        
        values$status_text <- "合併檔案..."
        
        # Combine files
        all_columns <- unique(unlist(lapply(all_data, names)))
        for (i in seq_along(all_data)) {
          missing_cols <- setdiff(all_columns, names(all_data[[i]]))
          for (col in missing_cols) {
            all_data[[i]][[col]] <- NA
          }
          all_data[[i]] <- all_data[[i]][all_columns]
        }
        
        combined_raw <- do.call(rbind, all_data)
        
        # 如果已有從步驟1的資料，合併它們
        if (!is.null(values$combined_data)) {
          existing_data <- values$combined_data
          # 確保欄位一致
          all_cols_combined <- unique(c(names(combined_raw), names(existing_data)))
          for (col in setdiff(all_cols_combined, names(combined_raw))) {
            combined_raw[[col]] <- NA
          }
          for (col in setdiff(all_cols_combined, names(existing_data))) {
            existing_data[[col]] <- NA
          }
          combined_raw <- rbind(existing_data, combined_raw)
        }
        
        values$status_text <- paste("合併完成，共", nrow(combined_raw), "筆記錄")
        
        # Detect fields
        if (input$auto_detect) {
          fields <- detect_fields(combined_raw)
          
          if (is.null(fields$customer_id) || is.null(fields$time) || is.null(fields$amount)) {
            values$status_text <- "錯誤: 無法偵測必要欄位"
            return()
          }
          
          # Standardize data
          standardized_data <- combined_raw %>%
            rename(
              customer_id = !!sym(fields$customer_id),
              payment_time = !!sym(fields$time),
              lineitem_price = !!sym(fields$amount)
            )
        } else {
          standardized_data <- combined_raw
        }
        
        # Clean and process data
        processed_data <- standardized_data %>%
          mutate(
            # 保留原始電子郵件以供參考
            original_customer_id = customer_id,
            # 創建電子郵件到數字ID的一對一映射
            customer_id = if(is.character(customer_id)) {
              if(any(grepl("@", customer_id, fixed = TRUE))) {
                # 為每個唯一的電子郵件創建數字ID
                as.integer(as.factor(customer_id))
              } else {
                as.integer(customer_id)
              }
            } else {
              as.integer(customer_id)
            },
            payment_time = as.POSIXct(payment_time),
            lineitem_price = as.numeric(lineitem_price),
            platform_id = "upload"
          ) %>%
          filter(
            !is.na(customer_id),
            !is.na(payment_time),
            !is.na(lineitem_price),
            lineitem_price > 0
          ) %>%
          arrange(customer_id, payment_time)
        
        # 創建電子郵件到數字ID的映射表以供後續使用
        if(any(grepl("@", standardized_data$customer_id, fixed = TRUE))) {
          email_to_id_mapping <- processed_data %>%
            select(original_customer_id, customer_id) %>%
            distinct() %>%
            arrange(customer_id)
          values$email_mapping <- email_to_id_mapping
          values$status_text <- paste("✅ 電子郵件映射完成:", nrow(email_to_id_mapping), "個唯一客戶")
        }
        
        values$combined_data <- processed_data
        values$status_text <- paste("✅ 資料處理完成，有效記錄:", nrow(processed_data), 
                                   "客戶數:", length(unique(processed_data$customer_id)))
        
        # 使用通用分析函數
        analyze_data(processed_data, input$min_transactions, 0.1)  # 固定時間折扣因子為0.1
        
      }, error = function(e) {
        values$status_text <- paste("處理錯誤:", e$message)
      })
    })
    
    # Status output
    output$status <- renderText({
      values$status_text
    })
    
    # 更新按鈕樣式的函數
    updateButtonStyles <- function(selected_metric) {
      # 所有按鈕的列表（需要加上命名空間）
      all_buttons <- c("show_m", "show_r", "show_f", "show_cai", "show_pcv", "show_cri", "show_nes")
      
      # 重置所有按鈕為未選中狀態
      for(btn in all_buttons) {
        btn_id <- session$ns(btn)
        if(btn == "show_nes") {
          shinyjs::removeClass(btn_id, "btn-warning")
          shinyjs::addClass(btn_id, "btn-outline-warning")
        } else {
          shinyjs::removeClass(btn_id, "btn-info")
          shinyjs::addClass(btn_id, "btn-outline-info")
        }
      }
      
      # 設置選中的按鈕為實心樣式
      selected_btn <- switch(selected_metric,
        "M" = "show_m",
        "R" = "show_r",
        "F" = "show_f",
        "CAI" = "show_cai",
        "PCV" = "show_pcv",
        "CRI" = "show_cri",
        "NES" = "show_nes"
      )
      
      if(!is.null(selected_btn)) {
        btn_id <- session$ns(selected_btn)
        if(selected_btn == "show_nes") {
          shinyjs::removeClass(btn_id, "btn-outline-warning")
          shinyjs::addClass(btn_id, "btn-warning")
        } else {
          shinyjs::removeClass(btn_id, "btn-outline-info")
          shinyjs::addClass(btn_id, "btn-info")
        }
      }
    }
    
    # Metric button handlers - 只切換顯示，不執行分群
    observeEvent(input$show_m, { 
      values$current_metric <- "M"
      updateMetricDescription("M")
      updateButtonStyles("M")
      updateDisplayForMetric("M")  # 更新顯示的分群資料
    })
    observeEvent(input$show_r, { 
      values$current_metric <- "R"
      updateMetricDescription("R")
      updateButtonStyles("R")
      updateDisplayForMetric("R")  # 更新顯示的分群資料
    })
    observeEvent(input$show_f, { 
      values$current_metric <- "F"
      updateMetricDescription("F")
      updateButtonStyles("F")
      updateDisplayForMetric("F")  # 更新顯示的分群資料
    })
    observeEvent(input$show_cai, { 
      values$current_metric <- "CAI"
      updateMetricDescription("CAI")
      updateButtonStyles("CAI")
      updateDisplayForMetric("CAI")  # 更新顯示的分群資料
    })
    observeEvent(input$show_pcv, { 
      values$current_metric <- "PCV"
      updateMetricDescription("PCV")
      updateButtonStyles("PCV")
      updateDisplayForMetric("PCV")  # 更新顯示的分群資料
    })
    observeEvent(input$show_cri, { 
      values$current_metric <- "CRI"
      updateMetricDescription("CRI")
      updateButtonStyles("CRI")
      updateDisplayForMetric("CRI")  # 更新顯示的分群資料
    })
    observeEvent(input$show_nes, { 
      values$current_metric <- "NES"
      updateMetricDescription("NES")
      updateButtonStyles("NES")
      updateDisplayForMetric("NES")  # 更新顯示的分群資料
    })
    
    # 新增：執行客戶分群按鈕
    observeEvent(input$run_segmentation, {
      req(values$dna_results)
      
      # 禁用按鈕避免重複點擊
      tryCatch({
        shinyjs::disable("run_segmentation")
      }, error = function(e) {
        # 如果 shinyjs 出錯，繼續執行
      })
      
      # 執行完整的分群分析
      performCompleteSegmentation()
      
      # 重新啟用按鈕
      tryCatch({
        shinyjs::enable("run_segmentation")
      }, error = function(e) {
        # 如果 shinyjs 出錯，忽略
      })
    })
    
    # AI Analysis button handler（專門用於AI增強分析）
    observeEvent(input$run_ai_analysis, {
      req(values$current_metric, values$dna_results, values$segmented_data)
      
      # 清除舊的AI結果，強制重新生成
      values$ai_recommendations <- NULL
      values$ai_analysis_summary <- NULL
      values$ai_analysis_done <- FALSE
      
      showNotification("🤖 正在執行AI增強分析...", type = "message", duration = 2)
      
      # 暫時停用按鈕避免重複點擊
      shinyjs::disable("run_ai_analysis")
      
      # 生成AI行銷建議（使用GPT API）
      generateAIRecommendations()
      
      # 生成AI分析摘要
      generateAIAnalysisSummary()
      
      # 標記AI分析已完成
      values$ai_analysis_done <- TRUE
      
      # 重新啟用按鈕
      shinyjs::enable("run_ai_analysis")
      
      showNotification("✅ AI增強分析完成！", type = "message", duration = 2)
    })
    
    # 生成AI分析摘要
    generateAIAnalysisSummary <- function() {
      req(values$segmented_data)
      
      # 計算各項統計
      segment_stats <- values$segmented_data %>%
        group_by(segment) %>%
        summarise(
          count = n(),
          avg_r = mean(r_value, na.rm = TRUE),
          avg_f = mean(f_value, na.rm = TRUE),
          avg_m = mean(m_value, na.rm = TRUE),
          total_revenue = sum(m_value * f_value, na.rm = TRUE),
          .groups = "drop"
        )
      
      # 生成HTML格式的分析摘要
      metric_name <- switch(values$current_metric,
        "R" = "最近來店時間",
        "F" = "購買頻率", 
        "M" = "購買金額",
        "CAI" = "顧客活躍度",
        "PCV" = "過去價值",
        "CRI" = "參與度分數",
        "NES" = "顧客狀態"
      )
      
      summary_html <- paste0(
        "<div style='padding: 15px;'>",
        "<h5>📊 ", metric_name, " 分析摘要</h5>",
        "<p><b>分析時間：</b>", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>",
        "<p><b>總客戶數：</b>", format(nrow(values$segmented_data), big.mark = ","), " 人</p>",
        "<br>",
        "<h6>🎯 客群分組結果（80/20法則）</h6>",
        "<table class='table table-bordered table-sm'>",
        "<thead><tr>",
        "<th>客群</th><th>人數</th><th>佔比</th><th>平均R</th><th>平均F</th><th>平均M</th><th>總營收</th>",
        "</tr></thead>",
        "<tbody>"
      )
      
      for(i in 1:nrow(segment_stats)) {
        row <- segment_stats[i,]
        summary_html <- paste0(summary_html,
          "<tr>",
          "<td>", row$segment, "</td>",
          "<td>", format(row$count, big.mark = ","), "</td>",
          "<td>", round(row$count/nrow(values$segmented_data)*100, 1), "%</td>",
          "<td>", round(row$avg_r, 1), "天</td>",
          "<td>", round(row$avg_f, 1), "次</td>",
          "<td>$", format(round(row$avg_m, 2), big.mark = ","), "</td>",
          "<td>$", format(round(row$total_revenue, 0), big.mark = ","), "</td>",
          "</tr>"
        )
      }
      
      summary_html <- paste0(summary_html,
        "</tbody></table>",
        "<br>",
        "<p class='text-muted'><i>註：使用80/20法則進行客群分組，高價值客群通常貢獻80%的營收</i></p>",
        "</div>"
      )
      
      values$ai_analysis_summary <- summary_html
      
      # 也保存原始數據供其他用途
      values$ai_summary <- list(
        total_customers = nrow(values$segmented_data),
        segment_stats = segment_stats,
        metric = values$current_metric,
        analysis_time = Sys.time()
      )
    }
    
    # 下載分析資料
    output$download_analysis_data <- downloadHandler(
      filename = function() {
        paste0("dna_analysis_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        req(values$dna_results)
        data <- values$dna_results$data_by_customer
        write.csv(data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # 下載客群分組資料
    output$download_segments_csv <- downloadHandler(
      filename = function() {
        paste0("customer_segments_", values$current_metric, "_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        req(values$segmented_data)
        export_data <- prepareExportData()
        write.csv(export_data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # 下載詳細資料
    output$download_detail_csv <- downloadHandler(
      filename = function() {
        paste0("segment_details_", values$current_metric, "_", format(Sys.Date(), "%Y%m%d"), ".csv")
      },
      content = function(file) {
        req(values$segmented_data)
        # 包含更多欄位的詳細資料
        detail_data <- values$segmented_data
        write.csv(detail_data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # 更新指標說明（整合hint系統）
    updateMetricDescription <- function(metric) {
      req(values$dna_results)
      data <- values$dna_results$data_by_customer
      
      # 載入hints
      hints_df <- load_hints()
      
      # 根據指標取得對應的hint var_id
      hint_var_id <- switch(metric,
        "M" = "monetary_stat",
        "R" = "recency_stat",
        "F" = "frequency_stat",
        "CAI" = "cai_stat",
        "PCV" = "pcv_stat",
        "CRI" = "cri_stat",
        "NES" = "customer_segmentation"
      )
      
      # 取得hint描述
      hint_text <- if(!is.null(hints_df) && hint_var_id %in% hints_df$var_id) {
        hints_df[hints_df$var_id == hint_var_id, "description"][1]
      } else {
        ""
      }
      
      description <- switch(metric,
        "M" = {
          m_values <- data$m_value[!is.na(data$m_value)]
          m_median <- median(m_values)
          m_mean <- mean(m_values)
          m_var <- var(m_values)
          m_q25 <- quantile(m_values, 0.25)
          m_q75 <- quantile(m_values, 0.75)
          
          # 區分高中低 (80/20法則)
          m_q20 <- quantile(m_values, 0.2)
          m_q80 <- quantile(m_values, 0.8)
          high_count <- sum(m_values >= m_q80)
          low_count <- sum(m_values <= m_q20)
          mid_count <- length(m_values) - high_count - low_count
          
          paste0(
            "💰 <b>購買金額分析</b>",
            if(hint_text != "") {
              paste0(" <i class='fas fa-info-circle' style='font-size: 12px; color: #17a2b8;' ",
                     "data-toggle='tooltip' data-placement='top' title='", hint_text, "'></i>")
            } else "",
            "<br>",
            "• <b>定義：</b>平均單次購買金額<br>",
            "• <b>平均數：</b>$", round(m_mean, 2), "<br>",
            "• <b>中位數：</b>$", round(m_median, 2), "<br>",
            "• <b>25%/75%分位數：</b>$", round(m_q25, 2), " / $", round(m_q75, 2), "<br>",
            "• <b>變異數：</b>", round(m_var, 2), "<br>",
            "• <b>整體輪廓：</b>", 
            if(m_var > (m_mean^2 * 0.5)) "購買金額離散程度大" else "購買金額相對集中",
            "<br><br>",
            "📊 <b>80/20分組：</b><br>",
            "• 高價值(≮$", round(m_q80, 2), ")：", high_count, "人<br>",
            "• 中價值：", mid_count, "人<br>",
            "• 低價值(≤$", round(m_q20, 2), ")：", low_count, "人"
          )
        },
        "R" = {
          r_values <- data$r_value[!is.na(data$r_value)]
          r_median <- median(r_values)
          r_mean <- mean(r_values)
          r_var <- var(r_values)
          r_q25 <- quantile(r_values, 0.25)
          r_q75 <- quantile(r_values, 0.75)
          
          # 區分高中低 (80/20法則) - 注意：R值越低越好
          r_q20 <- quantile(r_values, 0.2)
          r_q80 <- quantile(r_values, 0.8)
          active_count <- sum(r_values <= r_q20)  # 最近購買(活躍)
          inactive_count <- sum(r_values >= r_q80)  # 久未購買(不活躍)
          mid_count <- length(r_values) - active_count - inactive_count
          
          paste0(
            "🕒 <b>最近來店時間分析</b>",
            if(hint_text != "") {
              paste0(" <i class='fas fa-info-circle' style='font-size: 12px; color: #17a2b8;' ",
                     "data-toggle='tooltip' data-placement='top' title='", hint_text, "'></i>")
            } else "",
            "<br>",
            "• <b>定義：</b>距離最近一次購買的天數<br>",
            "• <b>平均數：</b>", round(r_mean, 0), " 天<br>",
            "• <b>中位數：</b>", round(r_median, 0), " 天<br>",
            "• <b>25%/75%分位數：</b>", round(r_q25, 0), " / ", round(r_q75, 0), " 天<br>",
            "• <b>變異數：</b>", round(r_var, 0), "<br>",
            "• <b>整體輪廓：</b>", 
            if(r_var > (r_mean^2 * 0.5)) "來店時間離散程度大" else "來店時間相對一致",
            "<br><br>",
            "📊 <b>80/20分組：</b><br>",
            "• 高度活躍(≤", round(r_q20, 0), "天)：", active_count, "人<br>",
            "• 中度活躍：", mid_count, "人<br>",
            "• 不活躍(≮", round(r_q80, 0), "天)：", inactive_count, "人"
          )
        },
        "F" = {
          f_values <- data$f_value[!is.na(data$f_value)]
          f_median <- median(f_values)
          f_mean <- mean(f_values)
          f_var <- var(f_values)
          f_q25 <- quantile(f_values, 0.25)
          f_q75 <- quantile(f_values, 0.75)
          
          # 區分高中低 (80/20法則)
          f_q20 <- quantile(f_values, 0.2)
          f_q80 <- quantile(f_values, 0.8)
          high_freq <- sum(f_values >= f_q80)
          low_freq <- sum(f_values <= f_q20)
          mid_freq <- length(f_values) - high_freq - low_freq
          
          paste0(
            "🔁 <b>購買頻率分析</b>",
            if(hint_text != "") {
              paste0(" <i class='fas fa-info-circle' style='font-size: 12px; color: #17a2b8;' ",
                     "data-toggle='tooltip' data-placement='top' title='", hint_text, "'></i>")
            } else "",
            "<br>",
            "• <b>定義：</b>觀察期間內的總購買次數<br>",
            "• <b>平均數：</b>", round(f_mean, 1), " 次<br>",
            "• <b>中位數：</b>", round(f_median, 1), " 次<br>",
            "• <b>25%/75%分位數：</b>", round(f_q25, 1), " / ", round(f_q75, 1), " 次<br>",
            "• <b>變異數：</b>", round(f_var, 2), "<br>",
            "• <b>整體輪廓：</b>",
            if(f_var > (f_mean^2 * 0.5)) "購買頻率差異大需分群管理" else "購買頻率較為一致",
            "<br><br>",
            "📊 <b>80/20分組：</b><br>",
            "• 高頻客戶(≮", round(f_q80, 1), "次)：", high_freq, "人<br>",
            "• 中頻客戶：", mid_freq, "人<br>",
            "• 低頻客戶(≤", round(f_q20, 1), "次)：", low_freq, "人"
          )
        },
        "CAI" = {
          if("cai_value" %in% names(data)) {
            cai_values <- data$cai_value[!is.na(data$cai_value)]
            cai_mean <- mean(cai_values)
            cai_median <- median(cai_values)
            cai_var <- var(cai_values)
            cai_q25 <- quantile(cai_values, 0.25)
            cai_q75 <- quantile(cai_values, 0.75)
            
            cai_active <- sum(cai_values > 0, na.rm = TRUE)
            cai_stable <- sum(abs(cai_values) <= 0.1, na.rm = TRUE)
            cai_declining <- sum(cai_values < -0.1, na.rm = TRUE)
            total <- length(cai_values)
            
            # 80/20分組
            cai_q20 <- quantile(cai_values, 0.2)
            cai_q80 <- quantile(cai_values, 0.8)
            high_active <- sum(cai_values >= cai_q80, na.rm = TRUE)
            low_active <- sum(cai_values <= cai_q20, na.rm = TRUE)
            
            paste0(
              "📈 <b>顧客活躍度分析</b>",
              if(hint_text != "") {
                paste0(" <i class='fas fa-info-circle' style='font-size: 12px; color: #17a2b8;' ",
                       "data-toggle='tooltip' data-placement='top' title='", hint_text, "'></i>")
              } else "",
              "<br>",
              "• <b>定義：</b>購買行為趨勢指標 (>0漸趨活躍，<0漸趨靜止)<br>",
              "• <b>管理意涵：</b>預測客戶未來行為，及早識別流失風險<br><br>",
              "📊 <b>統計摘要：</b><br>",
              "• <b>平均數：</b>", round(cai_mean, 3), "<br>",
              "• <b>中位數：</b>", round(cai_median, 3), "<br>",
              "• <b>25%/75%分位數：</b>", round(cai_q25, 3), " / ", round(cai_q75, 3), "<br>",
              "• <b>變異數：</b>", round(cai_var, 5), "<br>",
              "• <b>整體輪廓：</b>",
              if(cai_var > 0.01) "活躍度差異大需分群管理" else "活躍度較為一致",
              "<br><br>",
              "📊 <b>80/20分組：</b><br>",
              "• 高活躍(≥", round(cai_q80, 3), ")：", high_active, "人<br>",
              "• 中活躍：", total - high_active - low_active, "人<br>",
              "• 低活躍(≤", round(cai_q20, 3), ")：", low_active, "人<br><br>",
              "💡 <b>狀態分布：</b><br>",
              "• <b>漸趨活躍(>0)：</b>", cai_active, " 人 (", round(cai_active/total*100, 1), "%)<br>",
              "• <b>穩定(≈0)：</b>", cai_stable, " 人 (", round(cai_stable/total*100, 1), "%)<br>",
              "• <b>漸趨靜止(<0)：</b>", cai_declining, " 人 (", round(cai_declining/total*100, 1), "%)<br><br>",
              "🎯 <b>行銷建議：</b><br>",
              "• 活躍客戶：把握成長動能，推薦新品<br>",
              "• 穩定客戶：維持服務水準，定期關懷<br>",
              "• 靜止客戶：緊急挽回措施，特殊優惠"
            )
          } else {
            "📈 <b>顧客活躍度</b><br>• 資料不足"
          }
        },
        "PCV" = {
          if("pcv" %in% names(data) || "total_spent" %in% names(data)) {
            pcv_col <- if("pcv" %in% names(data)) "pcv" else "total_spent"
            pcv_values <- data[[pcv_col]][!is.na(data[[pcv_col]])]
            pcv_mean <- mean(pcv_values)
            pcv_median <- median(pcv_values)
            pcv_q25 <- quantile(pcv_values, 0.25)
            pcv_q75 <- quantile(pcv_values, 0.75)
            pcv_var <- var(pcv_values)
            
            # 80/20分組
            pcv_q20 <- quantile(pcv_values, 0.2)
            pcv_q80 <- quantile(pcv_values, 0.8)
            high_value <- sum(pcv_values >= pcv_q80)
            low_value <- sum(pcv_values <= pcv_q20)
            mid_value <- length(pcv_values) - high_value - low_value
            
            paste0(
              "💎 <b>過去價值分析</b>",
              if(hint_text != "") {
                paste0(" <i class='fas fa-info-circle' style='font-size: 12px; color: #17a2b8;' ",
                       "data-toggle='tooltip' data-placement='top' title='", hint_text, "'></i>")
              } else "",
              "<br>",
              "• <b>定義：</b>歷史累積消費總額<br>",
              "• <b>平均數：</b>$", round(pcv_mean, 2), "<br>",
              "• <b>中位數：</b>$", round(pcv_median, 2), "<br>",
              "• <b>25%/75%分位數：</b>$", round(pcv_q25, 2), " / $", round(pcv_q75, 2), "<br>",
              "• <b>變異數：</b>", round(pcv_var, 2), "<br><br>",
              "📊 <b>80/20分組：</b><br>",
              "• 高價值(≥$", round(pcv_q80, 2), ")：", high_value, "人<br>",
              "• 中價值：", mid_value, "人<br>",
              "• 低價值(≤$", round(pcv_q20, 2), ")：", low_value, "人<br><br>",
              "🎯 <b>行銷建議：</b><br>",
              "• 高價值：專屬VIP服務<br>",
              "• 中價值：提升計劃<br>",
              "• 低價值：激活策略"
            )
          } else {
            "💎 <b>過去價值</b><br>• 資料不足"
          }
        },
        "CRI" = {
          if("cri" %in% names(data)) {
            cri_values <- data$cri[!is.na(data$cri)]
            cri_mean <- mean(cri_values)
            cri_median <- median(cri_values)
            cri_var <- var(cri_values)
            cri_q25 <- quantile(cri_values, 0.25)
            cri_q75 <- quantile(cri_values, 0.75)
            
            # 80/20分組
            cri_q20 <- quantile(cri_values, 0.2)
            cri_q80 <- quantile(cri_values, 0.8)
            high_value <- sum(cri_values >= cri_q80, na.rm = TRUE)
            low_value <- sum(cri_values <= cri_q20, na.rm = TRUE)
            total <- length(cri_values)
            
            paste0(
              "🎯 <b>參與度分數分析</b>",
              if(hint_text != "") {
                paste0(" <i class='fas fa-info-circle' style='font-size: 12px; color: #17a2b8;' ",
                       "data-toggle='tooltip' data-placement='top' title='", hint_text, "'></i>")
              } else "",
              "<br>",
              "• <b>定義：</b>RFM綜合加權分數 (0.3×R + 0.3×F + 0.4×M)<br>",
              "• <b>計算方式：</b>標準化至0-100分，分數越高代表客戶越有價值<br>",
              "• <b>管理意涵：</b>整合多維度評估客戶價值，用於客戶分級與資源配置<br><br>",
              "📊 <b>統計摘要：</b><br>",
              "• <b>平均分數：</b>", round(cri_mean * 100, 1), " 分<br>",
              "• <b>中位數：</b>", round(cri_median * 100, 1), " 分<br>",
              "• <b>25%/75%分位數：</b>", round(cri_q25 * 100, 1), " / ", round(cri_q75 * 100, 1), " 分<br>",
              "• <b>變異數：</b>", round(cri_var * 10000, 2), "<br>",
              "• <b>整體輪廓：</b>",
              if(cri_var > 0.01) "參與度差異大需差異化服務" else "參與度較為平均",
              "<br><br>",
              "📊 <b>80/20分組：</b><br>",
              "• 高價值(≥", round(cri_q80 * 100, 1), "分)：", high_value, "人<br>",
              "• 中價值：", total - high_value - low_value, "人<br>",
              "• 低價值(≤", round(cri_q20 * 100, 1), "分)：", low_value, "人<br><br>",
              "💡 <b>價值層級解讀：</b><br>",
              "• >75分：核心價值客戶，提供VIP服務<br>",
              "• 50-75分：潛力客戶，加強培育<br>",
              "• 25-50分：一般客戶，維持基本服務<br>",
              "• <25分：需關注客戶，避免流失"
            )
          } else {
            "🎯 <b>參與度分數</b><br>• 資料不足"
          }
        },
        "NES" = {
          nes_table <- table(data$nes_status)
          paste0(
            "👥 <b>顧客狀態分析</b>",
            if(hint_text != "") {
              paste0(" <i class='fas fa-info-circle' style='font-size: 12px; color: #17a2b8;' ",
                     "data-toggle='tooltip' data-placement='top' title='", hint_text, "'></i>")
            } else "",
            "<br>",
            "• 新客(N)：", nes_table["N"] %||% 0, " 人<br>",
            "• 主力(E0)：", nes_table["E0"] %||% 0, " 人<br>",
            "• 沉睡(S1-S3)：", sum(nes_table[c("S1", "S2", "S3")], na.rm = TRUE), " 人"
          )
        }
      )
      
      output$metric_ai_description <- renderUI({
        HTML(description)
      })
    }
    
    # 統計概覽輸出
    output$statistics_summary <- renderUI({
      req(values$current_metric, values$dna_results)
      data <- values$dna_results$data_by_customer
      metric <- values$current_metric
      
      # 根據選定的指標取得資料欄位
      metric_col <- switch(metric,
        "M" = "m_value",
        "R" = "r_value",
        "F" = "f_value",
        "CAI" = "cai_value",
        "PCV" = "pcv",
        "CRI" = "cri",
        "NES" = "nes_status"
      )
      
      if(!metric_col %in% names(data)) {
        return(HTML("<p class='text-muted'>該指標資料不存在</p>"))
      }
      
      if(metric != "NES") {
        values_vec <- data[[metric_col]]
        values_vec <- values_vec[!is.na(values_vec)]
        
        # 計算統計量
        q25 <- quantile(values_vec, 0.25)
        q50 <- quantile(values_vec, 0.50)
        q75 <- quantile(values_vec, 0.75)
        mean_val <- mean(values_vec)
        sd_val <- sd(values_vec)
        cv_val <- sd_val / mean_val  # 變異係數
        
        # 根據指標類型格式化數值
        format_value <- function(x, type = metric) {
          if(type %in% c("M", "PCV")) {
            paste0("$", format(round(x, 2), big.mark = ","))
          } else if(type == "R") {
            paste0(round(x, 0), " 天")
          } else if(type == "F") {
            paste0(round(x, 1), " 次")
          } else if(type %in% c("CAI", "CRI")) {
            paste0(round(x * 100, 1), " 分")
          } else {
            round(x, 2)
          }
        }
        
        # 生成統計摘要
        tagList(
          fluidRow(
            column(3,
              bs4InfoBox(
                title = "平均數",
                value = format_value(mean_val),
                icon = icon("calculator"),
                color = "info",
                width = 12
              )
            ),
            column(3,
              bs4InfoBox(
                title = "中位數",
                value = format_value(q50),
                icon = icon("chart-line"),
                color = "primary",
                width = 12
              )
            ),
            column(3,
              bs4InfoBox(
                title = "25% / 75%",
                value = HTML(paste0(
                  format_value(q25), "<br>",
                  format_value(q75)
                )),
                icon = icon("chart-area"),
                color = "warning",
                width = 12
              )
            ),
            column(3,
              bs4InfoBox(
                title = "變異係數",
                value = paste0(round(cv_val * 100, 1), "%"),
                icon = icon("percentage"),
                color = if(cv_val > 0.5) "danger" else "success",
                width = 12
              )
            )
          ),
          br(),
          div(
            class = "alert alert-info",
            h5(icon("info-circle"), " 統計解讀"),
            p(
              if(cv_val > 0.5) {
                paste0("變異係數 ", round(cv_val * 100, 1), "%，表示", 
                      switch(metric,
                        "R" = "顧客來店時間差異很大，需要分群管理",
                        "F" = "購買頻率差異顯著，存在明顯的忠誠度分層",
                        "M" = "消費水平差異很大，需要差異化定價策略",
                        "顧客群體差異較大"
                      ))
              } else {
                paste0("變異係數 ", round(cv_val * 100, 1), "%，表示",
                      switch(metric,
                        "R" = "顧客來店時間相對穩定",
                        "F" = "購買頻率較為一致",
                        "M" = "消費水平相對集中",
                        "顧客群體較為同質"
                      ))
              }
            )
          )
        )
      } else {
        # NES 狀態的特殊處理
        nes_table <- table(data$nes_status)
        nes_pct <- prop.table(nes_table) * 100
        
        tagList(
          fluidRow(
            column(12,
              h5("顧客狀態分布"),
              tags$table(
                class = "table table-striped",
                tags$thead(
                  tags$tr(
                    tags$th("狀態"),
                    tags$th("人數"),
                    tags$th("比例")
                  )
                ),
                tags$tbody(
                  lapply(names(nes_table), function(status) {
                    tags$tr(
                      tags$td(status),
                      tags$td(nes_table[status]),
                      tags$td(paste0(round(nes_pct[status], 1), "%"))
                    )
                  })
                )
              )
            )
          )
        )
      }
    })
    
    # ECDF 洞察
    output$ecdf_insight <- renderUI({
      req(values$current_metric, values$dna_results)
      data <- values$dna_results$data_by_customer
      metric <- values$current_metric
      
      insight <- switch(metric,
        "M" = {
          col_data <- data$m_value[!is.na(data$m_value)]
          q25 <- quantile(col_data, 0.25)
          q50 <- quantile(col_data, 0.5)
          q75 <- quantile(col_data, 0.75)
          mean_val <- mean(col_data)
          var_val <- var(col_data)
          
          # 80/20分組
          q20 <- quantile(col_data, 0.2)
          q80 <- quantile(col_data, 0.8)
          
          HTML(paste0(
            "📊 <b>ECDF 統計摘要：</b><br>",
            "• 平均數：$", round(mean_val, 2), "<br>",
            "• 中位數：$", round(q50, 2), "<br>",
            "• 25%/75%分位數：$", round(q25, 2), " / $", round(q75, 2), "<br>",
            "• 變異數：", round(var_val, 2), "<br>",
            "• <b>整體輪廓：</b>", 
            if(var_val > (mean_val^2 * 0.5)) "金額離散程度大" else "金額相對集中",
            "<br><br>",
            "🎯 <b>AI行銷建議：</b><br>",
            "• 高價值客戶(≮$", round(q80, 2), ")：VIP服務<br>",
            "• 中價值客戶：升級推薦<br>",
            "• 低價值客戶(≤$", round(q20, 2), ")：入門優惠"
          ))
        },
        "R" = {
          col_data <- data$r_value[!is.na(data$r_value)]
          q25 <- quantile(col_data, 0.25)
          q50 <- quantile(col_data, 0.5)
          q75 <- quantile(col_data, 0.75)
          mean_val <- mean(col_data)
          var_val <- var(col_data)
          
          # 80/20分組
          q20 <- quantile(col_data, 0.2)
          q80 <- quantile(col_data, 0.8)
          
          HTML(paste0(
            "📊 <b>ECDF 統計摘要：</b><br>",
            "• 平均數：", round(mean_val, 0), " 天<br>",
            "• 中位數：", round(q50, 0), " 天<br>",
            "• 25%/75%分位數：", round(q25, 0), " / ", round(q75, 0), " 天<br>",
            "• 變異數：", round(var_val, 0), "<br>",
            "• <b>整體輪廓：</b>",
            if(var_val > (mean_val^2 * 0.5)) "來店時間差異大" else "來店時間一致",
            "<br><br>",
            "🎯 <b>AI行銷建議：</b><br>",
            "• 活躍客戶(≤", round(q20, 0), "天)：交叉銷售<br>",
            "• 中度活躍：定期關懷<br>",
            "• 不活躍(≮", round(q80, 0), "天)：召回活動"
          ))
        },
        "F" = {
          col_data <- data$f_value[!is.na(data$f_value)]
          q25 <- quantile(col_data, 0.25)
          q50 <- quantile(col_data, 0.5)
          q75 <- quantile(col_data, 0.75)
          mean_val <- mean(col_data)
          var_val <- var(col_data)
          
          # 80/20分組
          q20 <- quantile(col_data, 0.2)
          q80 <- quantile(col_data, 0.8)
          
          HTML(paste0(
            "📊 <b>ECDF 統計摘要：</b><br>",
            "• 平均數：", round(mean_val, 1), " 次<br>",
            "• 中位數：", round(q50, 1), " 次<br>",
            "• 25%/75%分位數：", round(q25, 1), " / ", round(q75, 1), " 次<br>",
            "• 變異數：", round(var_val, 2), "<br>",
            "• <b>整體輪廓：</b>",
            if(var_val > (mean_val^2 * 0.5)) "頻率差異大需分群" else "頻率較為一致",
            "<br><br>",
            "🎯 <b>AI行銷建議：</b><br>",
            "• 高頻客戶(≮", round(q80, 1), "次)：VIP計劃<br>",
            "• 中頻客戶：忠誠度獎勵<br>",
            "• 低頻客戶(≤", round(q20, 1), "次)：試用優惠"
          ))
        },
        "NES" = {
          HTML("📊 <b>ECDF 洞察：</b><br>• 顧客狀態為分類數據<br>• 請查看右側分布圖")
        }
      )
      
      return(insight)
    })
    
    # 直方圖洞察
    output$hist_insight <- renderUI({
      req(values$current_metric, values$dna_results)
      data <- values$dna_results$data_by_customer
      metric <- values$current_metric
      
      insight <- switch(metric,
        "M" = {
          col_data <- data$m_value[!is.na(data$m_value)]
          mode_val <- as.numeric(names(sort(table(round(col_data, 0)), decreasing = TRUE)[1]))
          mode_count <- max(table(round(col_data, 0)))
          
          # 使用80/20法則計算高中低群體比例
          q20 <- quantile(col_data, 0.2)
          q80 <- quantile(col_data, 0.8)
          high_pct <- round(sum(col_data >= q80) / length(col_data) * 100, 1)
          low_pct <- round(sum(col_data <= q20) / length(col_data) * 100, 1)
          mid_pct <- 100 - high_pct - low_pct
          
          HTML(paste0(
            "📊 <b>分布洞察：</b><br>",
            "• 最常見金額：$", mode_val, "<br>",
            "• 高中低比例：", high_pct, "% / ", mid_pct, "% / ", low_pct, "%<br>",
            "• ", ifelse(var(col_data) > (mean(col_data)^2 * 0.5), "需差異化策略", "客群相對同質")
          ))
        },
        "R" = {
          col_data <- data$r_value[!is.na(data$r_value)]
          recent <- sum(col_data <= 30)
          medium <- sum(col_data > 30 & col_data <= 90)
          old <- sum(col_data > 90)
          
          HTML(paste0(
            "📊 <b>分布洞察：</b><br>",
            "• 30天內：", recent, " 位 (", round(recent/length(col_data)*100, 1), "%)<br>",
            "• 31-90天：", medium, " 位 (", round(medium/length(col_data)*100, 1), "%)<br>",
            "• >90天：", old, " 位 (", round(old/length(col_data)*100, 1), "%)"
          ))
        },
        "F" = {
          col_data <- data$f_value[!is.na(data$f_value)]
          one_time <- sum(col_data == 1)
          two_three <- sum(col_data >= 2 & col_data <= 3)
          frequent <- sum(col_data > 3)
          
          HTML(paste0(
            "📊 <b>分布洞察：</b><br>",
            "• 單次購買：", one_time, " 位 (", round(one_time/length(col_data)*100, 1), "%)<br>",
            "• 2-3次：", two_three, " 位 (", round(two_three/length(col_data)*100, 1), "%)<br>",
            "• >3次：", frequent, " 位 (", round(frequent/length(col_data)*100, 1), "%)"
          ))
        },
        "NES" = {
          nes_table <- table(data$nes_status)
          max_status <- names(which.max(nes_table))
          HTML(paste0(
            "📊 <b>分布洞察：</b><br>",
            "• 最多顧客狀態：", max_status, "<br>",
            "• 共有 ", max(nes_table), " 位顧客"
          ))
        }
      )
      
      return(insight)
    })
    
    # ECDF Plot - Based on microDNADistribution component
    output$plot_ecdf <- renderPlotly({
      tryCatch({
        req(values$dna_results, values$current_metric)
        
        data <- values$dna_results$data_by_customer
        metric <- values$current_metric
        
        metric_mapping <- list(
          "M" = "m_value",
          "R" = "r_value", 
          "F" = "f_value",
          "CAI" = if("cai_value" %in% names(data)) "cai_value" else "cai",
          "PCV" = if("pcv" %in% names(data)) "pcv" else "total_spent",
          "CRI" = "cri",
          "NES" = "nes_status"  # NES 使用狀態分類而非數值
        )
        
        col_name <- metric_mapping[[metric]]
        
        # Handle missing data gracefully
        if (is.null(data) || nrow(data) == 0 || is.null(col_name) || !col_name %in% names(data)) {
          return(plotly_empty(type = "scatter") %>%
            add_annotations(
              text = paste("無法找到", metric, "數據\n請檢查數據是否已正確載入"),
              x = 0.5, y = 0.5,
              xref = "paper", yref = "paper",
              showarrow = FALSE,
              font = list(size = 16)
            ))
        }
        
        # Get metric values and remove NA
        metric_values <- data[[col_name]]
        metric_values <- metric_values[!is.na(metric_values)]
        
        if (length(metric_values) == 0) {
          return(plotly_empty(type = "scatter") %>%
            add_annotations(
              text = paste(metric, "數據為空或全為 NA 值"),
              x = 0.5, y = 0.5,
              xref = "paper", yref = "paper",
              showarrow = FALSE,
              font = list(size = 16)
            ))
        }
        
        # Special handling for categorical data (NES) 
        if (metric == "NES") {
          # For NES, show informative message in ECDF position
          return(plotly_empty(type = "scatter") %>%
            add_annotations(
              text = "NES 狀態分佈\n請查看右側直方圖",
              x = 0.5, y = 0.5,
              xref = "paper", yref = "paper",
              showarrow = FALSE,
              font = list(size = 18, color = "#1F77B4")
            ) %>%
            layout(
              title = list(text = "ECDF - NES", font = list(size = 16)),
              xaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE),
              yaxis = list(showgrid = FALSE, showticklabels = FALSE, zeroline = FALSE)
            ))
        } else {
          # Compute ECDF for continuous data
          sorted_values <- sort(unique(metric_values))
          ecdf_fn <- ecdf(metric_values)
          ecdf_values <- ecdf_fn(sorted_values)
          
          # Create plotly visualization with proper hover text
          plot_ly(
            x = sorted_values, 
            y = ecdf_values,
            type = "scatter", 
            mode = "lines",
            line = list(color = "#1F77B4", width = 2),
            hoverinfo = "text",
            text = paste0(
              metric, ": ", format(sorted_values, big.mark = ","),
              "<br>累積百分比: ", format(ecdf_values * 100, digits = 2), "%"
            )
          ) %>%
            layout(
              title = list(text = paste("ECDF -", metric), font = list(size = 16)),
              xaxis = list(title = metric),
              yaxis = list(title = "累積機率", tickformat = ".0%"),
              showlegend = FALSE
            )
        }
        
      }, error = function(e) {
        plotly_empty(type = "scatter") %>%
          add_annotations(
            text = paste("視覺化錯誤:", e$message),
            x = 0.5, y = 0.5,
            xref = "paper", yref = "paper",
            showarrow = FALSE,
            font = list(size = 14, color = "red")
          )
      })
    })
    
    # Histogram Plot - Based on microDNADistribution component  
    output$plot_hist <- renderPlotly({
      tryCatch({
        req(values$dna_results, values$current_metric)
        
        data <- values$dna_results$data_by_customer
        metric <- values$current_metric
        
        metric_mapping <- list(
          "M" = "m_value",
          "R" = "r_value",
          "F" = "f_value",
          "CAI" = if("cai_value" %in% names(data)) "cai_value" else "cai",
          "PCV" = if("pcv" %in% names(data)) "pcv" else "total_spent",
          "CRI" = "cri",
          "NES" = "nes_status"  # NES 使用狀態分類而非數值
        )
        
        col_name <- metric_mapping[[metric]]
        
        # Handle missing data gracefully
        if (is.null(data) || nrow(data) == 0 || is.null(col_name) || !col_name %in% names(data)) {
          return(plotly_empty(type = "bar") %>%
            add_annotations(
              text = paste("無法找到", metric, "數據\n請檢查數據是否已正確載入"),
              x = 0.5, y = 0.5,
              xref = "paper", yref = "paper",
              showarrow = FALSE,
              font = list(size = 16)
            ))
        }
        
        # Get metric values and remove NA
        metric_values <- data[[col_name]]
        metric_values <- metric_values[!is.na(metric_values)]
        
        if (length(metric_values) == 0) {
          return(plotly_empty(type = "bar") %>%
            add_annotations(
              text = paste(metric, "數據為空或全為 NA 值"),
              x = 0.5, y = 0.5,
              xref = "paper", yref = "paper",
              showarrow = FALSE,
              font = list(size = 16)
            ))
        }
        
        # Choose visualization based on metric type
        if (metric == "F" || metric == "NES") {
          # For categorical/frequency data, use bar plot
          if (metric == "F") {
            # For frequency, ensure proper integer ordering
            max_f <- max(metric_values, na.rm = TRUE)
            freq_levels <- as.character(1:min(max_f, 50))
            cnt <- table(factor(metric_values, levels = freq_levels))
          } else {
            # For NES, use predefined levels
            cnt <- table(factor(metric_values, levels = c("N", "E0", "S1", "S2", "S3")))
          }
          
          # Convert to data frame for plotting
          df <- data.frame(x = names(cnt), y = as.numeric(cnt))
          total <- sum(df$y)
          
          plot_ly(
            df, 
            x = ~x, 
            y = ~y, 
            type = "bar", 
            marker = list(color = "#1F77B4"), 
            hoverinfo = "text",
            text = ~paste0(
              "值: ", x, 
              "<br>計數: ", format(y, big.mark = ","),
              "<br>百分比: ", round(y / total * 100, 1), "%"
            )
          ) %>%
            layout(
              title = list(text = if(metric == "NES") "NES 狀態分佈" else paste("分佈圖 -", metric), font = list(size = 16)),
              xaxis = list(title = if(metric == "NES") "NES 狀態" else "值", categoryorder = "array", categoryarray = df$x),
              yaxis = list(title = if(metric == "NES") "客戶數" else "計數")
            )
        } else {
          # For continuous data (M, R), use histogram
          plot_ly(
            x = ~metric_values, 
            type = "histogram", 
            marker = list(color = "#1F77B4"),
            hovertemplate = paste0(
              metric, ": %{x}<br>",
              "計數: %{y}<br>",
              "<extra></extra>"
            )
          ) %>%
            layout(
              title = list(text = paste("直方圖 -", metric), font = list(size = 16)),
              xaxis = list(title = metric),
              yaxis = list(title = "頻率"),
              showlegend = FALSE
            )
        }
        
      }, error = function(e) {
        plotly_empty(type = "bar") %>%
          add_annotations(
            text = paste("視覺化錯誤:", e$message),
            x = 0.5, y = 0.5,
            xref = "paper", yref = "paper",
            showarrow = FALSE,
            font = list(size = 14, color = "red")
          )
      })
    })
    
    # Email Mapping Table
    output$email_mapping_table <- renderDT({
      req(values$email_mapping)
      
      values$email_mapping %>%
        rename(
          "原始電子郵件" = original_customer_id,
          "數字客戶ID" = customer_id
        ) %>%
        arrange(`數字客戶ID`)
      
    }, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
    
    # Check if email mapping exists
    output$has_email_mapping <- reactive({
      !is.null(values$email_mapping)
    })
    outputOptions(output, "has_email_mapping", suspendWhenHidden = FALSE)
    
    # Table info output
    output$table_info <- renderText({
      if (!is.null(input$convert_to_text) && input$convert_to_text) {
        "顯示模式：文字分類 (高/中/低)"
      } else {
        "顯示模式：數值 (小數點後2位)"
      }
    })
    
    # DNA Results Table
    output$dna_table <- renderDT({
      tryCatch({
        req(values$dna_results)
        
        # 強化數據檢查
        if (is.null(values$dna_results$data_by_customer)) {
          return(DT::datatable(data.frame(Message = "DNA分析結果中沒有客戶數據"), 
                               options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE))
        }
        
        data <- values$dna_results$data_by_customer
        
        # 確保數據是數據框格式
        if (!is.data.frame(data)) {
          if (is.list(data)) {
            # 嘗試轉換list為data.frame
            data <- tryCatch({
              # 檢查是否為簡單的list（每個元素都是原子型別）
              if (length(data) > 0 && all(sapply(data, is.atomic))) {
                as.data.frame(data, stringsAsFactors = FALSE)
              } else if (length(data) > 0 && all(sapply(data, is.list))) {
                # 處理嵌套list
                do.call(rbind, lapply(data, function(x) {
                  if (is.list(x)) {
                    as.data.frame(x, stringsAsFactors = FALSE)
                  } else {
                    as.data.frame(t(x), stringsAsFactors = FALSE)
                  }
                }))
              } else {
                stop("無法轉換數據格式：複雜的數據結構")
              }
            }, error = function(e) {
              stop(paste("數據轉換錯誤：", e$message))
            })
          } else if (is.matrix(data)) {
            data <- as.data.frame(data, stringsAsFactors = FALSE)
          } else {
            stop("數據格式錯誤：不是有效的二維數據結構")
          }
        }
        
        # 生成AI分析洞察
        values$ai_insights <- generate_ai_insights(data)
        
        # 檢查數據是否為空
        if (nrow(data) == 0) {
          return(DT::datatable(data.frame(Message = "沒有客戶數據可顯示"), 
                               options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE))
        }
        
        # 檢查並選擇可用的欄位 - 擴展搜尋範圍
        available_cols <- c("customer_id", "r_value", "f_value", "m_value", "ipt_mean", 
                           "cai_value", "cai", "pcv", "total_spent", "clv", 
                           "nes_status", "nes_value", "cri", "customer_lifespan")
        
        # 尋找實際存在的欄位
        existing_cols <- intersect(available_cols, names(data))
        
        # 如果找不到標準欄位名稱，嘗試其他可能的名稱
        if(!"r_value" %in% existing_cols && "r" %in% names(data)) {
          existing_cols <- c(existing_cols, "r")
        }
        if(!"f_value" %in% existing_cols && "f" %in% names(data)) {
          existing_cols <- c(existing_cols, "f")
        }
        if(!"m_value" %in% existing_cols && "m" %in% names(data)) {
          existing_cols <- c(existing_cols, "m")
        }
        
        if (length(existing_cols) == 0) {
          return(DT::datatable(data.frame(
            Message = "未找到預期的數據欄位",
            Available_Columns = paste(names(data), collapse = ", ")
          ), options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE))
        }
        
        # 選擇並處理數據
        data <- data[, existing_cols, drop = FALSE]
        
        # 標準化欄位名稱
        if("r" %in% names(data) && !"r_value" %in% names(data)) {
          names(data)[names(data) == "r"] <- "r_value"
        }
        if("f" %in% names(data) && !"f_value" %in% names(data)) {
          names(data)[names(data) == "f"] <- "f_value"
        }
        if("m" %in% names(data) && !"m_value" %in% names(data)) {
          names(data)[names(data) == "m"] <- "m_value"
        }
        if("cai" %in% names(data) && !"cai_value" %in% names(data)) {
          names(data)[names(data) == "cai"] <- "cai_value"
        }
        if("total_spent" %in% names(data) && !"pcv" %in% names(data)) {
          names(data)[names(data) == "total_spent"] <- "pcv"
        }
        
        # 轉換數值
        convert_values <- !is.null(input$convert_to_text) && input$convert_to_text
        
        if (convert_values) {
          # 轉換為高中低文字
          for (col in c("r_value", "f_value", "m_value", "ipt_mean", "pcv", "clv")) {
            if (col %in% names(data) && is.numeric(data[[col]])) {
              quantiles <- quantile(data[[col]], c(0.33, 0.67), na.rm = TRUE)
              data[[col]] <- factor(
                ifelse(data[[col]] <= quantiles[1], "低",
                       ifelse(data[[col]] <= quantiles[2], "中", "高")),
                levels = c("低", "中", "高")
              )
            }
          }
          
          # 特殊處理cai_value
          if ("cai_value" %in% names(data)) {
            data$cai_value <- factor(
              ifelse(data$cai_value <= 0.33, "漸趨靜止",
                     ifelse(data$cai_value <= 0.67, "穩定消費", "漸趨活躍")),
              levels = c("漸趨靜止", "穩定消費", "漸趨活躍")
            )
          }
        } else {
          # 保留數值，但四捨五入到小數點後2位
          for (col in c("r_value", "f_value", "m_value", "ipt_mean", "pcv", "clv", "cai_value")) {
            if (col %in% names(data) && is.numeric(data[[col]])) {
              data[[col]] <- round(data[[col]], 2)
            }
          }
          
          # 為cai_value添加文字描述
          if ("cai_value" %in% names(data)) {
            data$cai_value <- ifelse(data$cai_value <= 0.33, paste0(data$cai_value, " (漸趨靜止)"),
                                   ifelse(data$cai_value <= 0.67, paste0(data$cai_value, " (穩定消費)"),
                                          paste0(data$cai_value, " (漸趨活躍)")))
          }
        }
        
        # 重新命名欄位
        names(data) <- sapply(names(data), function(x) {
          switch(x,
                 "customer_id" = "顧客ID",
                 "r_value" = "最近來店時間",
                 "f_value" = "購買頻率",
                 "m_value" = "購買金額",
                 "ipt_mean" = "購買時間週期",
                 "cai_value" = "顧客活躍度",
                 "pcv" = "過去價值",
                 "clv" = "終身價值",
                 "nes_status" = "顧客狀態",
                 "nes_value" = "參與度分數",
                 x)
        })
        
        DT::datatable(data, options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
        
      }, error = function(e) {
        DT::datatable(data.frame(Error = paste("表格生成錯誤:", e$message)), 
                      options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE)
      })
    })
    
    # Summary Table
    output$summary_table <- renderDT({
      tryCatch({
        req(values$dna_results)
        
        # 強化數據檢查
        if (is.null(values$dna_results$data_by_customer)) {
          return(DT::datatable(data.frame(Error = "DNA分析結果中沒有客戶數據"), 
                               options = list(dom = 't'), rownames = FALSE))
        }
        
        data <- values$dna_results$data_by_customer
        
        # 確保數據是數據框格式
        if (!is.data.frame(data)) {
          if (is.list(data)) {
            data <- as.data.frame(data)
          } else {
            return(DT::datatable(data.frame(Error = "數據格式錯誤：不是有效的二維數據結構"), 
                                 options = list(dom = 't'), rownames = FALSE))
          }
        }
        
        # 檢查數據是否為空
        if (nrow(data) == 0) {
          return(DT::datatable(data.frame(Error = "沒有客戶數據可顯示"), 
                               options = list(dom = 't'), rownames = FALSE))
        }
        
        # 檢查必要欄位是否存在
        required_cols <- c("r_value", "f_value", "m_value", "clv")
        missing_cols <- setdiff(required_cols, names(data))
        
        if (length(missing_cols) > 0) {
          return(DT::datatable(data.frame(
            Error = paste("缺少必要欄位:", paste(missing_cols, collapse = ", "))
          ), options = list(dom = 't'), rownames = FALSE))
        }
        
        summary_stats <- data.frame(
          指標 = c("客戶總數", "平均R值", "平均F值", "平均M值", "平均CLV"),
          數值 = c(
            nrow(data),
            round(mean(data$r_value, na.rm = TRUE), 2),
            round(mean(data$f_value, na.rm = TRUE), 2),
            round(mean(data$m_value, na.rm = TRUE), 2),
            round(mean(data$clv, na.rm = TRUE), 2)
          )
        )
        
        DT::datatable(summary_stats, options = list(dom = 't'), rownames = FALSE)
        
      }, error = function(e) {
        DT::datatable(data.frame(Error = paste("統計摘要錯誤:", e$message)), 
                      options = list(dom = 't'), rownames = FALSE)
      })
    })
    
    # DNA Explanation from MD file
    output$dna_explanation <- renderText({
      tryCatch({
        # Read the markdown file
        md_path <- "md/dna_results_explanation.md"
        if (file.exists(md_path)) {
          md_content <- readLines(md_path, encoding = "UTF-8")
          
          # Process line by line for better control
          html_lines <- c()
          in_list <- FALSE
          
          for (line in md_content) {
            # Handle headers
            if (grepl("^### ", line)) {
              if (in_list) { html_lines <- c(html_lines, "</ul>"); in_list <- FALSE }
              header_text <- gsub("^### ", "", line)
              html_lines <- c(html_lines, paste0("<h4 style='color: #2c3e50; margin-top: 20px;'>", header_text, "</h4>"))
            } else if (grepl("^## ", line)) {
              if (in_list) { html_lines <- c(html_lines, "</ul>"); in_list <- FALSE }
              header_text <- gsub("^## ", "", line)
              html_lines <- c(html_lines, paste0("<h3 style='color: #34495e; margin-top: 25px;'>", header_text, "</h3>"))
            } else if (grepl("^# ", line)) {
              if (in_list) { html_lines <- c(html_lines, "</ul>"); in_list <- FALSE }
              header_text <- gsub("^# ", "", line)
              html_lines <- c(html_lines, paste0("<h2 style='color: #2c3e50; margin-top: 30px;'>", header_text, "</h2>"))
            } else if (grepl("^- ", line)) {
              # Handle list items
              if (!in_list) {
                html_lines <- c(html_lines, "<ul style='margin: 10px 0; padding-left: 20px;'>")
                in_list <- TRUE
              }
              list_text <- gsub("^- ", "", line)
              # Process bold text within list items
              list_text <- gsub("\\*\\*(.*?)\\*\\*", "<strong>\\1</strong>", list_text)
              html_lines <- c(html_lines, paste0("<li style='margin: 5px 0;'>", list_text, "</li>"))
            } else if (grepl("^[0-9]+\\.", line)) {
              # Handle numbered lists
              if (in_list) { html_lines <- c(html_lines, "</ul>"); in_list <- FALSE }
              number_text <- gsub("^[0-9]+\\. ", "", line)
              number_text <- gsub("\\*\\*(.*?)\\*\\*", "<strong>\\1</strong>", number_text)
              html_lines <- c(html_lines, paste0("<p style='margin: 8px 0;'><strong>", 
                                               gsub("^([0-9]+)\\.", "\\1.", line), "</strong> ", 
                                               gsub("^[0-9]+\\. \\*\\*(.*?)\\*\\*:", "\\1:", number_text), "</p>"))
            } else if (line == "") {
              # Handle empty lines
              if (in_list) { html_lines <- c(html_lines, "</ul>"); in_list <- FALSE }
              html_lines <- c(html_lines, "<br>")
            } else {
              # Handle regular paragraphs
              if (in_list) { html_lines <- c(html_lines, "</ul>"); in_list <- FALSE }
              if (line != "") {
                # Process bold text
                processed_line <- gsub("\\*\\*(.*?)\\*\\*", "<strong>\\1</strong>", line)
                html_lines <- c(html_lines, paste0("<p style='margin: 10px 0; text-align: justify;'>", processed_line, "</p>"))
              }
            }
          }
          
          # Close any remaining lists
          if (in_list) {
            html_lines <- c(html_lines, "</ul>")
          }
          
          # Combine all lines
          html_content <- paste(html_lines, collapse = "\n")
          
          # Add overall styling
          styled_content <- paste0(
            "<div style='font-family: system-ui, -apple-system, sans-serif; line-height: 1.6; color: #2c3e50; max-width: 100%; padding: 20px; background: #f8f9fa; border-radius: 8px;'>",
            html_content,
            "</div>"
          )
          
          return(styled_content)
        } else {
          return("<div style='color: red; padding: 20px; background: #fff5f5; border: 1px solid #fed7d7; border-radius: 8px;'><strong>錯誤:</strong> 找不到說明文件: md/dna_results_explanation.md</div>")
        }
      }, error = function(e) {
        return(paste0("<div style='color: red; padding: 20px; background: #fff5f5; border: 1px solid #fed7d7; border-radius: 8px;'><strong>載入錯誤:</strong> ", e$message, "</div>"))
      })
    })
    
    # 新增：AI分析洞察生成函數
    generate_ai_insights <- function(data) {
      insights <- list()
      
      # 1. 購買金額分析
      m_quantiles <- quantile(data$m_value, c(0.25, 0.5, 0.75), na.rm = TRUE)
      m_mean <- mean(data$m_value, na.rm = TRUE)
      insights$monetary <- sprintf(
        "購買金額分析：\n
        • 中位數購買金額為 %.2f 元，表示50%%的顧客單次消費低於此金額\n
        • 25%%的顧客單次消費低於 %.2f 元\n
        • 25%%的顧客單次消費高於 %.2f 元\n
        • 平均單次消費為 %.2f 元\n
        整體評估：%s",
        m_quantiles[2], m_quantiles[1], m_quantiles[3], m_mean,
        if(m_mean > m_quantiles[3]) "顧客群體消費能力較強，但存在較大差異" else 
        if(m_mean < m_quantiles[1]) "顧客群體消費較為保守" else "顧客消費較為均衡"
      )
      
      # 2. 最近購買時間分析
      r_quantiles <- quantile(data$r_value, c(0.25, 0.5, 0.75), na.rm = TRUE)
      r_mean <- mean(data$r_value, na.rm = TRUE)
      insights$recency <- sprintf(
        "最近購買時間分析：\n
        • 中位數距離上次購買時間為 %.0f 天\n
        • 25%%的顧客在 %.0f 天內有購買\n
        • 25%%的顧客超過 %.0f 天未購買\n
        • 平均未購買天數為 %.0f 天\n
        整體評估：%s",
        r_quantiles[2], r_quantiles[1], r_quantiles[3], r_mean,
        if(r_mean > 180) "需要加強客戶維繫，考慮召回活動" else 
        if(r_mean < 30) "客戶活躍度高，可考慮提升客單價" else "客戶活躍度適中"
      )
      
      # 3. 購買頻率分析
      f_quantiles <- quantile(data$f_value, c(0.25, 0.5, 0.75), na.rm = TRUE)
      f_mean <- mean(data$f_value, na.rm = TRUE)
      insights$frequency <- sprintf(
        "購買頻率分析：\n
        • 中位數購買次數為 %.0f 次\n
        • 25%%的顧客購買次數少於 %.0f 次\n
        • 25%%的顧客購買次數多於 %.0f 次\n
        • 平均購買次數為 %.1f 次\n
        整體評估：%s",
        f_quantiles[2], f_quantiles[1], f_quantiles[3], f_mean,
        if(f_mean > f_quantiles[3]) "有穩定的高頻購買客群" else 
        if(f_mean < f_quantiles[1]) "多為偶發性購買，需加強會員經營" else "購買頻率分布平均"
      )
      
      # 4. 顧客狀態分析
      nes_table <- table(data$nes_status)
      nes_pct <- prop.table(nes_table) * 100
      status_summary <- paste(names(nes_table), 
                            sprintf("%.1f%%", nes_pct),
                            sep = ": ",
                            collapse = "\n• ")
      
      insights$nes <- sprintf(
        "顧客狀態分布：\n• %s\n
        整體評估：%s",
        status_summary,
        if(nes_pct["S2"] + nes_pct["S3"] > 50) "高度參與客群占比較大，可開發深度服務" else 
        if(nes_pct["E0"] > 40) "需要加強客戶參與度，建議開發入門級服務" else "客戶參與度分布平均"
      )
      
      insights
    }
    
    # 執行客群分組
    performSegmentation <- function() {
      # 檢查必要條件
      if(is.null(values$dna_results)) {
        showNotification("⚠️ 請先執行 DNA 分析", type = "warning", duration = 3)
        return()
      }
      if(is.null(values$current_metric)) {
        showNotification("⚠️ 請選擇分析指標", type = "warning", duration = 3)
        return()
      }
      
      data <- values$dna_results$data_by_customer
      metric <- values$current_metric
      
      # 顯示分組進行中的訊息
      showNotification(paste0("📊 正在進行", metric, "指標的客群分組..."), type = "message", duration = 2)
      
      # 確保必要的欄位存在
      if(!"cai_value" %in% names(data) && "cai" %in% names(data)) {
        data$cai_value <- data$cai
      }
      if(!"pcv" %in% names(data) && "total_spent" %in% names(data)) {
        data$pcv <- data$total_spent
      }
      
      # 如果缺少CAI值，計算簡單的活躍度
      if(!"cai_value" %in% names(data) && !"cai" %in% names(data)) {
        if("r_value" %in% names(data)) {
          # 基於最近購買時間計算活躍度
          data$cai_value <- ifelse(
            data$r_value < 30, 1,  # 30天內購買：活躍
            ifelse(data$r_value > 90, -1, 0)  # 90天以上：靜止，30-90天：穩定
          )
        }
      }
      
      # 如果缺少CRI，計算它
      if(!"cri" %in% names(data) && all(c("r_value", "f_value", "m_value") %in% names(data))) {
        # 正規化到0-1
        normalize_01 <- function(x) {
          if(length(unique(x)) == 1) return(rep(0.5, length(x)))
          (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
        }
        
        r_norm <- 1 - normalize_01(data$r_value)  # R值反向
        f_norm <- normalize_01(data$f_value)
        m_norm <- normalize_01(data$m_value)
        
        data$cri <- 0.3 * r_norm + 0.3 * f_norm + 0.4 * m_norm
      }
      
      # 根據選定的指標取得資料欄位
      metric_col <- switch(metric,
        "M" = "m_value",
        "R" = "r_value",
        "F" = "f_value",
        "CAI" = if("cai_value" %in% names(data)) "cai_value" else "cai",
        "PCV" = if("pcv" %in% names(data)) "pcv" else "total_spent",
        "CRI" = "cri",
        "NES" = "nes_status"
      )
      
      # 檢查欄位是否存在
      if(!metric_col %in% names(data)) {
        showNotification(paste0("⚠️ 找不到", metric, "的資料欄位"), type = "warning", duration = 3)
        return()
      }
      
      if(metric_col %in% names(data) && metric != "NES") {
        values_vec <- data[[metric_col]]
        values_vec[is.na(values_vec)] <- median(values_vec, na.rm = TRUE)
        
        # 使用80/20法則進行分組
        q20 <- quantile(values_vec, 0.2, na.rm = TRUE)
        q80 <- quantile(values_vec, 0.8, na.rm = TRUE)
        
        # 對於R值（最近來店時間），數值越小越好
        if(metric == "R") {
          data$segment <- ifelse(values_vec <= q20, "高活躍",
                                ifelse(values_vec >= q80, "低活躍", "中活躍"))
        } else if(metric == "CAI") {
          # 顧客活躍度特殊處理
          data$segment <- ifelse(values_vec > 0, "漸趨活躍",
                                ifelse(values_vec < -0.1, "漸趨靜止", "穩定"))
        } else {
          # 其他指標，數值越大越好
          data$segment <- ifelse(values_vec >= q80, "高價值",
                                ifelse(values_vec <= q20, "低價值", "中價值"))
        }
        
        # 儲存分組結果（包含新增的欄位）
        values$segmented_data <- data
        values$dna_results$data_by_customer <- data  # 更新原始資料
        values$current_segmentation <- list(
          metric = metric,
          metric_col = metric_col,
          q20 = q20,
          q80 = q80,
          timestamp = Sys.time()
        )
        
        # 顯示分組完成訊息
        showNotification(paste0("✅ ", metric, " 客群分組完成！"), type = "message", duration = 2)
        
        # 創建統一的中文欄位表格
        createChineseTable(data)
        
        # 自動生成預設行銷建議（不需要AI）
        generateDefaultRecommendations()
        
      } else if(metric == "NES" && "nes_status" %in% names(data)) {
        # NES特殊處理
        data$segment <- data$nes_status
        values$segmented_data <- data
        values$dna_results$data_by_customer <- data  # 更新原始資料
        values$current_segmentation <- list(
          metric = metric,
          metric_col = "nes_status",
          timestamp = Sys.time()
        )
        
        # 顯示分組完成訊息
        showNotification(paste0("✅ ", metric, " 客群分組完成！"), type = "message", duration = 2)
        
        # 創建統一的中文欄位表格
        createChineseTable(data)
        
        # 自動生成預設行銷建議（不需要AI）
        generateDefaultRecommendations()
      }
    }
    
    # 執行完整的客戶分群分析
    performCompleteSegmentation <- function() {
      tryCatch({
        if(is.null(values$dna_results)) {
          showNotification("⚠️ 請先執行 DNA 分析", type = "warning", duration = 3)
          return()
        }
        
        data <- values$dna_results$data_by_customer
        
        # 設定分群已完成標記
        values$segmentation_completed <- TRUE
      
      # 確保必要的欄位存在
      if(!"cai_value" %in% names(data) && "cai" %in% names(data)) {
        data$cai_value <- data$cai
      }
      if(!"pcv" %in% names(data) && "total_spent" %in% names(data)) {
        data$pcv <- data$total_spent
      }
      
      # 如果缺少CAI值，計算簡單的活躍度
      if(!"cai_value" %in% names(data) && !"cai" %in% names(data)) {
        if("r_value" %in% names(data)) {
          data$cai_value <- ifelse(
            data$r_value < 30, 1,  # 30天內購買：活躍
            ifelse(data$r_value > 90, -1, 0)  # 90天以上：靜止，30-90天：穩定
          )
        }
      }
      
      # 如果缺少CRI，計算它
      if(!"cri" %in% names(data) && all(c("r_value", "f_value", "m_value") %in% names(data))) {
        normalize_01 <- function(x) {
          if(length(unique(x)) == 1) return(rep(0.5, length(x)))
          (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
        }
        
        r_norm <- 1 - normalize_01(data$r_value)  # R值反向
        f_norm <- normalize_01(data$f_value)
        m_norm <- normalize_01(data$m_value)
        
        data$cri <- 0.3 * r_norm + 0.3 * f_norm + 0.4 * m_norm
      }
      
      # 為每個指標計算分群
      # R值分群
      if("r_value" %in% names(data) && !all(is.na(data$r_value))) {
        r_values <- data$r_value[!is.na(data$r_value)]
        if(length(unique(r_values)) > 2) {
          r_quantiles <- quantile(r_values, c(0.33, 0.67))
          # 確保 breaks 是唯一的
          if(r_quantiles[1] == r_quantiles[2]) {
            # 如果分位數相同，使用平均值分組
            r_mean <- mean(r_values)
            data$segment_r <- ifelse(data$r_value <= r_mean, "高活躍", "低活躍")
            data$segment_r <- factor(data$segment_r, levels = c("高活躍", "低活躍"))
          } else {
            data$segment_r <- cut(data$r_value, 
                                  breaks = c(-Inf, r_quantiles[1], r_quantiles[2], Inf),
                                  labels = c("高活躍", "中活躍", "低活躍"),
                                  include.lowest = TRUE)
          }
        } else {
          # 值太少，全部歸為一組
          data$segment_r <- factor("中活躍", levels = c("高活躍", "中活躍", "低活躍"))
        }
      }
      
      # F值分群
      if("f_value" %in% names(data) && !all(is.na(data$f_value))) {
        f_values <- data$f_value[!is.na(data$f_value)]
        if(length(unique(f_values)) > 2) {
          f_quantiles <- quantile(f_values, c(0.33, 0.67))
          # 確保 breaks 是唯一的
          if(f_quantiles[1] == f_quantiles[2]) {
            # 如果分位數相同，使用平均值分組
            f_mean <- mean(f_values)
            data$segment_f <- ifelse(data$f_value <= f_mean, "低頻率", "高頻率")
            data$segment_f <- factor(data$segment_f, levels = c("低頻率", "高頻率"))
          } else {
            data$segment_f <- cut(data$f_value,
                                  breaks = c(-Inf, f_quantiles[1], f_quantiles[2], Inf),
                                  labels = c("低頻率", "中頻率", "高頻率"),
                                  include.lowest = TRUE)
          }
        } else {
          # 值太少，全部歸為一組
          data$segment_f <- factor("中頻率", levels = c("低頻率", "中頻率", "高頻率"))
        }
      }
      
      # M值分群
      if("m_value" %in% names(data) && !all(is.na(data$m_value))) {
        m_values <- data$m_value[!is.na(data$m_value)]
        if(length(unique(m_values)) > 2) {
          m_quantiles <- quantile(m_values, c(0.33, 0.67))
          # 確保 breaks 是唯一的
          if(m_quantiles[1] == m_quantiles[2]) {
            # 如果分位數相同，使用平均值分組
            m_mean <- mean(m_values)
            data$segment_m <- ifelse(data$m_value <= m_mean, "低價值", "高價值")
            data$segment_m <- factor(data$segment_m, levels = c("低價值", "高價值"))
          } else {
            data$segment_m <- cut(data$m_value,
                                  breaks = c(-Inf, m_quantiles[1], m_quantiles[2], Inf),
                                  labels = c("低價值", "中價值", "高價值"),
                                  include.lowest = TRUE)
          }
        } else {
          # 值太少，全部歸為一組
          data$segment_m <- factor("中價值", levels = c("低價值", "中價值", "高價值"))
        }
      }
      
      # CAI分群
      if("cai_value" %in% names(data) && !all(is.na(data$cai_value))) {
        cai_values <- data$cai_value[!is.na(data$cai_value)]
        if(length(unique(cai_values)) > 1) {
          # CAI 值通常在 -1 到 1 之間
          data$segment_cai <- cut(data$cai_value,
                                  breaks = c(-Inf, -0.33, 0.33, Inf),
                                  labels = c("漸趨靜止", "穩定", "漸趨活躍"),
                                  include.lowest = TRUE)
        } else {
          # 值太少，全部歸為穩定
          data$segment_cai <- factor("穩定", levels = c("漸趨靜止", "穩定", "漸趨活躍"))
        }
      }
      
      # PCV分群（使用80/20法則）
      if("pcv" %in% names(data) && !all(is.na(data$pcv))) {
        pcv_values <- data$pcv[!is.na(data$pcv)]
        if(length(unique(pcv_values)) > 1) {
          pcv_sorted <- sort(pcv_values, decreasing = TRUE)
          pcv_cumsum <- cumsum(pcv_sorted)
          pcv_total <- sum(pcv_sorted)
          
          # 找出累積80%的價值
          if(pcv_total > 0) {
            pcv_80_index <- which(pcv_cumsum >= pcv_total * 0.8)[1]
            if(!is.na(pcv_80_index)) {
              pcv_80_value <- pcv_sorted[pcv_80_index]
              data$segment_pcv <- ifelse(data$pcv >= pcv_80_value, "高價值", "一般價值")
            } else {
              # 如果無法找到門檻，使用中位數
              pcv_median <- median(pcv_values)
              data$segment_pcv <- ifelse(data$pcv >= pcv_median, "高價值", "一般價值")
            }
          } else {
            data$segment_pcv <- factor("一般價值", levels = c("高價值", "一般價值"))
          }
        } else {
          # 值太少，全部歸為一組
          data$segment_pcv <- factor("一般價值", levels = c("高價值", "一般價值"))
        }
      }
      
      # CRI分群
      if("cri" %in% names(data) && !all(is.na(data$cri))) {
        cri_values <- data$cri[!is.na(data$cri)]
        if(length(unique(cri_values)) > 2) {
          cri_quantiles <- quantile(cri_values, c(0.33, 0.67))
          # 確保 breaks 是唯一的
          if(cri_quantiles[1] == cri_quantiles[2]) {
            # 如果分位數相同，使用平均值分組
            cri_mean <- mean(cri_values)
            data$segment_cri <- ifelse(data$cri <= cri_mean, "低參與", "高參與")
            data$segment_cri <- factor(data$segment_cri, levels = c("低參與", "高參與"))
          } else {
            data$segment_cri <- cut(data$cri,
                                    breaks = c(-Inf, cri_quantiles[1], cri_quantiles[2], Inf),
                                    labels = c("低參與", "中參與", "高參與"),
                                    include.lowest = TRUE)
          }
        } else {
          # 值太少，全部歸為一組
          data$segment_cri <- factor("中參與", levels = c("低參與", "中參與", "高參與"))
        }
      }
      
      # NES分群（直接使用狀態）
      if("nes_status" %in% names(data)) {
        data$segment_nes <- data$nes_status
      }
      
      # 儲存完整的分群數據
      values$complete_segmented_data <- data
      
      # 創建統一的中文表格
      createChineseTable(data)
      
      # 設定初始的分群資料（預設使用M值）
      if("segment_m" %in% names(data)) {
        data$segment <- data$segment_m
        values$segmented_data <- data
        values$current_metric <- "M"
        updateMetricDescription("M")
        updateButtonStyles("M")
      }
      
        showNotification("✅ 客戶分群分析完成！現在可以查看各項分群指標。", type = "message", duration = 4)
      }, error = function(e) {
        values$status_text <- paste("❌ 分析錯誤:", e$message)
        showNotification(paste("分群分析失敗:", e$message), type = "error", duration = 5)
        values$segmentation_completed <- FALSE
      })
    }
    
    # 更新顯示的分群資料（不重新執行分群）
    updateDisplayForMetric <- function(metric) {
      if(!isTRUE(values$segmentation_completed) || is.null(values$complete_segmented_data)) {
        showNotification("請先執行客戶分群分析", type = "warning")
        return()
      }
      
      data <- values$complete_segmented_data
      
      # 根據選擇的指標更新 segment 欄位
      segment_col <- switch(metric,
        "R" = "segment_r",
        "F" = "segment_f",
        "M" = "segment_m",
        "CAI" = "segment_cai",
        "PCV" = "segment_pcv",
        "CRI" = "segment_cri",
        "NES" = "segment_nes"
      )
      
      if(segment_col %in% names(data)) {
        data$segment <- data[[segment_col]]
        values$segmented_data <- data
        values$current_metric <- metric
        
        # 重新創建中文表格以更新客群分組欄位
        createChineseTable(data)
      } else {
        showNotification(paste("無法找到", metric, "指標的分群資料"), type = "error")
      }
    }
    
    # 創建統一的中文欄位表格
    createChineseTable <- function(data) {
      # 創建一個副本以保留原始數據
      temp_table <- data
      
      # 選擇需要的欄位並重命名為中文
      col_mapping <- list(
        "customer_id" = "客戶ID",
        "segment" = "客群分組",
        "r_value" = "最近購買(天)",
        "f_value" = "購買頻率(次)",
        "m_value" = "平均金額($)",
        "cai_value" = "活躍度",
        "cai" = "活躍度",
        "pcv" = "過去價值($)",
        "total_spent" = "總消費($)",
        "cri" = "參與度分數",
        "times" = "購買次數",
        "nes_status" = "客戶狀態",
        "clv" = "終身價值($)",
        "segment_r" = "R分群",
        "segment_f" = "F分群",
        "segment_m" = "M分群",
        "segment_cai" = "活躍度分群",
        "segment_pcv" = "價值分群",
        "segment_cri" = "參與度分群",
        "segment_nes" = "狀態分群"
      )
      
      # 重命名存在的欄位
      for(old_name in names(col_mapping)) {
        if(old_name %in% names(temp_table)) {
          new_name <- col_mapping[[old_name]]
          # 避免重複的欄位名稱
          if(!new_name %in% names(temp_table)) {
            names(temp_table)[names(temp_table) == old_name] <- new_name
          }
        }
      }
      
      # 處理特殊情況：如果有cai但沒有活躍度，重命名
      if("cai" %in% names(temp_table) && !"活躍度" %in% names(temp_table)) {
        names(temp_table)[names(temp_table) == "cai"] <- "活躍度"
      }
      
      # 處理特殊情況：如果有total_spent但沒有過去價值，可以考慮重命名或保留兩者
      if("total_spent" %in% names(temp_table) && !"總消費($)" %in% names(temp_table)) {
        names(temp_table)[names(temp_table) == "total_spent"] <- "總消費($)"
      }
      
      # 儲存統一的中文表格
      values$temp_chinese_table <- temp_table
    }
    
    # 生成預設行銷建議（不需要AI）
    generateDefaultRecommendations <- function() {
      req(values$segmented_data)
      
      segments <- unique(values$segmented_data$segment)
      recommendations <- list()
      
      for(seg in segments) {
        recommendations[[seg]] <- getDefaultRecommendations(seg, values$current_metric)
      }
      
      values$ai_recommendations <- recommendations
    }
    
    # 生成AI行銷建議（使用集中管理的prompt）
    generateAIRecommendations <- function() {
      req(values$segmented_data)
      
      # 強制清除舊的建議
      values$ai_recommendations <- NULL
      
      # 載入prompts
      prompts_df <- load_prompts()
      
      # 根據不同客群生成建議
      segments <- unique(values$segmented_data$segment)
      recommendations <- list()
      
      # 檢查是否有GPT API設定
      use_ai <- !is.null(prompts_df) && 
                Sys.getenv("OPENAI_API_KEY") != "" && 
                exists("execute_gpt_request") &&
                !is.null(chat_api)  # 確保chat_api存在
      
      for(seg in segments) {
        seg_data <- values$segmented_data[values$segmented_data$segment == seg, ]
        
        # 如果可以使用AI，嘗試生成AI建議
        if(use_ai) {
          tryCatch({
            # 準備分群數據
            segment_stats <- seg_data %>%
              summarise(
                count = n(),
                avg_r = mean(r_value, na.rm = TRUE),
                avg_f = mean(f_value, na.rm = TRUE),
                avg_m = mean(m_value, na.rm = TRUE),
                total_revenue = sum(m_value * f_value, na.rm = TRUE)
              )
            
            # 使用集中管理的prompt
            ai_result <- execute_gpt_request(
              var_id = "dna_segment_marketing",
              variables = list(
                segment_name = seg,
                segment_characteristics = paste0(
                  "平均R: ", round(segment_stats$avg_r, 1), "天, ",
                  "平均F: ", round(segment_stats$avg_f, 1), "次, ",
                  "平均M: $", round(segment_stats$avg_m, 2)
                ),
                avg_metrics = jsonlite::toJSON(segment_stats, auto_unbox = TRUE),
                segment_size = paste0(segment_stats$count, "人")
              ),
              chat_api_function = chat_api,
              model = "gpt-4o-mini",
              prompts_df = prompts_df
            )
            
            # 解析AI回應
            recommendations[[seg]] <- list(
              strategy = paste0("AI建議：", seg),
              actions = strsplit(ai_result, "\n")[[1]]
            )
            
          }, error = function(e) {
            # 如果AI失敗，使用預設建議
            recommendations[[seg]] <- getDefaultRecommendations(seg, values$current_metric)
          })
        } else {
          # 使用預設建議
          recommendations[[seg]] <- getDefaultRecommendations(seg, values$current_metric)
        }
      }
      
      values$ai_recommendations <- recommendations
    }
    
    # 預設建議函數
    getDefaultRecommendations <- function(seg, metric) {
      switch(metric,
        "R" = {
          if(seg == "高活躍") {
            list(
              strategy = "深化經營",
              actions = c("交叉銷售相關產品", "提供VIP專屬優惠", "邀請參加新品體驗")
            )
          } else if(seg == "低活躍") {
            list(
              strategy = "召回激活",
              actions = c("發送個人化召回郵件", "提供限時優惠券", "推送懷舊產品")
              )
            } else {
              list(
                strategy = "維持互動",
                actions = c("定期推送內容", "季節性促銷", "會員積分獎勵")
              )
            }
          },
          "F" = {
            if(seg == "高價值") {
              list(
                strategy = "忠誠度深化",
                actions = c("VIP會員計劃", "批量採購優惠", "專屬客服")
              )
            } else if(seg == "低價值") {
              list(
                strategy = "頻率提升",
                actions = c("首購後跟進", "試用品贈送", "購買提醒")
              )
            } else {
              list(
                strategy = "穩定維護",
                actions = c("累積消費獎勵", "生日優惠", "定期關懷")
              )
            }
          },
          "M" = {
            if(seg == "高價值") {
              list(
                strategy = "價值最大化",
                actions = c("高端產品推薦", "客製化服務", "尊榮體驗")
              )
            } else if(seg == "低價值") {
              list(
                strategy = "價值提升",
                actions = c("入門產品推薦", "組合優惠", "分期付款")
              )
            } else {
              list(
                strategy = "向上銷售",
                actions = c("升級產品推薦", "捆綁銷售", "會員升級")
              )
            }
          },
          "CAI" = {
            if(seg == "漸趨活躍" || seg == "高價值") {
              list(
                strategy = "把握成長動能",
                actions = c("推薦新品", "加強互動頻率", "提供升級方案")
              )
            } else if(seg == "漸趨靜止" || seg == "低價值") {
              list(
                strategy = "緊急挽回",
                actions = c("個人化關懷", "特殊優惠", "了解流失原因")
              )
            } else {
              list(
                strategy = "穩定維護",
                actions = c("定期關懷", "季節性活動", "維持現有服務")
              )
            }
          },
          "PCV" = {
            if(seg == "高價值") {
              list(
                strategy = "價值最大化",
                actions = c("VIP專屬服務", "提供高端產品", "客製化方案")
              )
            } else if(seg == "低價值") {
              list(
                strategy = "價值培育",
                actions = c("入門優惠", "教育內容", "小額試用")
              )
            } else {
              list(
                strategy = "價值提升",
                actions = c("升級引導", "組合優惠", "忠誠度計劃")
              )
            }
          },
          "CRI" = {
            if(seg == "高價值") {
              list(
                strategy = "核心客戶經營",
                actions = c("優先服務", "專屬活動", "共創價值")
              )
            } else if(seg == "低價值") {
              list(
                strategy = "參與度提升",
                actions = c("互動激勵", "簡化流程", "新手引導")
              )
            } else {
              list(
                strategy = "潛力開發",
                actions = c("目標設定", "階段獎勵", "社群互動")
              )
            }
          },
          "NES" = {
            if(seg == "N") {
              list(
                strategy = "新客培育",
                actions = c("歡迎禮遇", "新手引導", "首購優惠")
              )
            } else if(seg == "E0") {
              list(
                strategy = "主力維護",
                actions = c("持續關懷", "會員權益", "專屬服務")
              )
            } else {
              list(
                strategy = "沉睡喚醒",
                actions = c("召回活動", "限時優惠", "產品更新通知")
              )
            }
          },
          list(strategy = "標準維護", actions = c("定期關懷", "基本優惠", "品牌溝通"))
        )
    }
    
    # 準備匯出資料
    prepareExportData <- function() {
      req(values$segmented_data)
      
      # 選擇要匯出的欄位
      export_cols <- c("customer_id", "segment", "r_value", "f_value", "m_value")
      
      # 添加過去價值和參與度分數（如果存在）
      if("pcv" %in% names(values$segmented_data)) {
        export_cols <- c(export_cols, "pcv")
      } else if("total_spent" %in% names(values$segmented_data)) {
        export_cols <- c(export_cols, "total_spent")
      }
      
      if("cri" %in% names(values$segmented_data)) {
        export_cols <- c(export_cols, "cri")
      }
      
      if("cai_value" %in% names(values$segmented_data)) {
        export_cols <- c(export_cols, "cai_value")
      }
      
      # 選擇存在的欄位
      export_cols <- intersect(export_cols, names(values$segmented_data))
      
      # 建立匯出資料框
      export_data <- values$segmented_data[, export_cols]
      
      # 重新命名欄位為中文
      names(export_data) <- sapply(names(export_data), function(x) {
        switch(x,
          "customer_id" = "客戶ID",
          "segment" = "客群分組",
          "r_value" = "最近購買天數",
          "f_value" = "購買頻率",
          "m_value" = "平均購買金額",
          "pcv" = "過去價值",
          "total_spent" = "累積消費",
          "cri" = "參與度分數",
          "cai_value" = "活躍度指標",
          x
        )
      })
      
      # 按分組排序
      export_data <- export_data[order(export_data$客群分組), ]
      
      return(export_data)
    }
    
    # 客群分組分析函數
    updateSegmentationAnalysis <- function() {
      req(values$dna_results, values$current_metric)
      data <- values$dna_results$data_by_customer
      metric <- values$current_metric
      
      # 根據選定的指標取得資料欄位
      metric_col <- switch(metric,
        "M" = "m_value",
        "R" = "r_value",
        "F" = "f_value",
        "CAI" = "cai_value",
        "PCV" = "pcv",
        "CRI" = "cri",
        "NES" = "nes_status"
      )
      
      if(metric_col %in% names(data) && metric != "NES") {
        # 使用80/20法則進行分組
        values_vec <- data[[metric_col]]
        
        # 計算分位數
        q20 <- quantile(values_vec, 0.2, na.rm = TRUE)
        q80 <- quantile(values_vec, 0.8, na.rm = TRUE)
        
        # 分組
        data$segment <- ifelse(values_vec <= q20, "低",
                              ifelse(values_vec >= q80, "高", "中"))
        
        # 儲存分組結果
        values$segmented_data <- data
      }
    }
    
    # 客群分組分析輸出
    output$segmentation_analysis <- renderUI({
      # 只有在已執行分群且有選擇指標時才顯示
      if(!isTRUE(values$segmentation_completed) || is.null(values$current_metric)) {
        return(
          div(
            class = "alert alert-info",
            icon("info-circle"),
            "請先執行客戶分群分析，然後選擇指標查看結果"
          )
        )
      }
      
      req(values$segmented_data)
      data <- values$segmented_data
      metric <- values$current_metric
      
      # 根據不同指標計算統計
      if(metric == "NES") {
        # NES 使用狀態分群
        segment_stats <- data %>%
          filter(!is.na(segment)) %>%
          group_by(segment) %>%
          summarise(
            count = n(),
            avg_r = mean(r_value, na.rm = TRUE),
            avg_f = mean(f_value, na.rm = TRUE),
            avg_m = mean(m_value, na.rm = TRUE),
            .groups = "drop"
          )
      } else {
        # 其他指標使用數值分群
        metric_col <- switch(metric,
          "M" = "m_value",
          "R" = "r_value",
          "F" = "f_value",
          "CAI" = "cai_value",
          "PCV" = "pcv",
          "CRI" = "cri"
        )
        
        if(metric_col %in% names(data)) {
          segment_stats <- data %>%
            filter(!is.na(segment)) %>%
            group_by(segment) %>%
            summarise(
              count = n(),
              avg_value = mean(get(metric_col), na.rm = TRUE),
              avg_r = mean(r_value, na.rm = TRUE),
              avg_f = mean(f_value, na.rm = TRUE),
              avg_m = mean(m_value, na.rm = TRUE),
              .groups = "drop"
            )
        } else {
          return(div(class = "alert alert-warning", "無法找到指標數據"))
        }
      }
      
      # 根據指標顯示不同標題
      title_text <- switch(metric,
        "R" = "📊 最近購買時間分群結果",
        "F" = "📊 購買頻率分群結果",
        "M" = "📊 購買金額分群結果（80/20法則）",
        "CAI" = "📊 活躍度分群結果",
        "PCV" = "📊 過去價值分群結果（80/20法則）",
        "CRI" = "📊 參與度分群結果",
        "NES" = "📊 顧客狀態分群結果",
        "📊 客群分組結果"
      )
      
      tagList(
        h5(title_text),
        fluidRow(
          lapply(c("高", "中", "低"), function(seg) {
            seg_data <- segment_stats[segment_stats$segment == seg, ]
            if(nrow(seg_data) > 0) {
              column(4,
                bs4Card(
                  title = paste0(seg, "價值群"),
                  status = if(seg == "高") "success" else if(seg == "中") "warning" else "danger",
                  solidHeader = TRUE,
                  width = 12,
                  h4(seg_data$count, " 人"),
                  p(paste0("佔比：", round(seg_data$count / sum(segment_stats$count) * 100, 1), "%")),
                  hr(),
                  h6("行銷建議："),
                  p(
                    switch(seg,
                      "高" = switch(metric,
                        "R" = "近期不活躍，需要召回策略",
                        "F" = "高頻客戶，提供VIP服務",
                        "M" = "高價值客戶，深度經營",
                        "提供專屬優惠"
                      ),
                      "中" = switch(metric,
                        "R" = "適度活躍，維持互動",
                        "F" = "中頻客戶，提升忠誠度",
                        "M" = "中價值客戶，向上銷售",
                        "定期關懷"
                      ),
                      "低" = switch(metric,
                        "R" = "高度活躍，把握機會",
                        "F" = "低頻客戶，激發興趣",
                        "M" = "低價值客戶，入門引導",
                        "基礎培育"
                      )
                    ),
                    style = "font-size: 13px;"
                  )
                )
              )
            }
          })
        )
      )
    })
    
    # 客群詳細表格
    output$segment_detail_table <- renderDT({
      # 檢查是否已執行分群分析
      if(!isTRUE(values$segmentation_completed) || is.null(values$temp_chinese_table)) {
        return(datatable(
          data.frame(提示 = "請先執行客戶分群分析"),
          options = list(
            dom = 't',
            language = list(emptyTable = "請點擊『執行客戶分群』按鈕開始分析")
          ),
          rownames = FALSE
        ))
      }
      
      data <- values$temp_chinese_table
      available_cols <- names(data)
      
      # 選擇存在的中文欄位
      select_cols <- c()
      if("客戶ID" %in% available_cols) select_cols <- c(select_cols, "客戶ID")
      if("客群分組" %in% available_cols) select_cols <- c(select_cols, "客群分組")
      if("最近購買(天)" %in% available_cols) select_cols <- c(select_cols, "最近購買(天)")
      if("購買頻率(次)" %in% available_cols) select_cols <- c(select_cols, "購買頻率(次)")
      if("平均金額($)" %in% available_cols) select_cols <- c(select_cols, "平均金額($)")
      
      # 只選擇實際存在的欄位
      if(length(select_cols) > 0) {
        display_data <- data[, select_cols, drop = FALSE]
      } else {
        display_data <- data.frame(訊息 = "沒有可顯示的欄位")
      }
      
      # 定義需要格式化的中文欄位
      format_round_cols <- c("最近購買(天)", "購買頻率(次)", "購買次數")
      format_currency_cols <- c("平均金額($)", "過去價值($)", "總消費($)")
      
      dt <- datatable(
        display_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          order = list(list(1, 'asc'))
        ),
        rownames = FALSE
      )
      
      # 格式化實際存在的欄位
      existing_round_cols <- intersect(format_round_cols, names(display_data))
      if(length(existing_round_cols) > 0) {
        tryCatch({
          dt <- dt %>% formatRound(existing_round_cols, 0)
        }, error = function(e) {
          message("formatRound error: ", e$message)
        })
      }
      
      existing_currency_cols <- intersect(format_currency_cols, names(display_data))
      if(length(existing_currency_cols) > 0) {
        tryCatch({
          dt <- dt %>% formatCurrency(existing_currency_cols, "$")
        }, error = function(e) {
          message("formatCurrency error: ", e$message)
        })
      }
      
      dt
    })
    
    # 行銷建議函數
    updateMarketingRecommendations <- function() {
      req(values$dna_results, values$current_metric)
      # 觸發行銷建議生成
    }
    
    # AI 行銷建議輸出
    output$marketing_recommendations <- renderUI({
      # 只有在已執行分群且有選擇指標時才顯示
      if(!isTRUE(values$segmentation_completed) || is.null(values$current_metric)) {
        return(NULL)
      }
      
      req(values$current_metric, values$segmented_data)
      data <- values$segmented_data
      metric <- values$current_metric
      
      # 生成針對性的行銷建議
      tagList(
        div(
          class = "alert alert-warning",
          h5(icon("lightbulb"), " AI 智能行銷建議"),
          p(paste0("基於 ", 
                  switch(metric,
                    "R" = "最近來店時間",
                    "F" = "購買頻率",
                    "M" = "購買金額",
                    "CAI" = "顧客活躍度",
                    "PCV" = "過去價值",
                    "CRI" = "參與度分數",
                    "NES" = "顧客狀態"
                  ),
                  " 分析"))
        ),
        
        # 根據不同指標提供具體建議
        if(metric == "R") {
          tagList(
            h5("🎯 最近來店時間行銷策略"),
            bs4Card(
              title = "召回策略（超過75分位數）",
              status = "danger",
              width = 12,
              p("• 發送個人化召回郵件"),
              p("• 提供限時優惠券（7天內使用）"),
              p("• 推送新品資訊喚醒興趣")
            ),
            bs4Card(
              title = "維持策略（25-75分位數）",
              status = "warning",
              width = 12,
              p("• 定期推送會員專屬優惠"),
              p("• 建立積分獎勵機制"),
              p("• 提供生日月優惠")
            ),
            bs4Card(
              title = "深化策略（低於25分位數）",
              status = "success",
              width = 12,
              p("• 推薦相關產品交叉銷售"),
              p("• 邀請加入VIP計劃"),
              p("• 提供升級服務機會")
            )
          )
        } else if(metric == "F") {
          tagList(
            h5("🎯 購買頻率行銷策略"),
            bs4Card(
              title = "高頻客戶（前20%）",
              status = "success",
              width = 12,
              p("• 建立VIP專屬服務"),
              p("• 提供批量採購優惠"),
              p("• 優先體驗新品")
            ),
            bs4Card(
              title = "中頻客戶（20-80%）",
              status = "warning",
              width = 12,
              p("• 設計忠誠度計劃"),
              p("• 提供累積消費獎勵"),
              p("• 定期關懷提醒")
            ),
            bs4Card(
              title = "低頻客戶（後20%）",
              status = "danger",
              width = 12,
              p("• 了解購買障礙"),
              p("• 提供試用優惠"),
              p("• 簡化購買流程")
            )
          )
        } else if(metric == "M") {
          tagList(
            h5("🎯 購買金額行銷策略"),
            bs4Card(
              title = "高價值客戶（前20%）",
              status = "success",
              width = 12,
              p("• 提供專屬客戶經理"),
              p("• 客製化產品推薦"),
              p("• 尊榮級售後服務")
            ),
            bs4Card(
              title = "中價值客戶（20-80%）",
              status = "warning",
              width = 12,
              p("• 推薦升級產品"),
              p("• 捆綁銷售優惠"),
              p("• 分期付款方案")
            ),
            bs4Card(
              title = "低價值客戶（後20%）",
              status = "info",
              width = 12,
              p("• 入門級產品推薦"),
              p("• 首購優惠券"),
              p("• 教育內容行銷")
            )
          )
        } else if(metric == "CAI") {
          tagList(
            h5("🎯 顧客活躍度行銷策略"),
            bs4Card(
              title = "漸趨活躍（>0）",
              status = "success",
              width = 12,
              p("• 把握成長動能，加強互動"),
              p("• 推薦熱門產品"),
              p("• 邀請參與會員活動")
            ),
            bs4Card(
              title = "穩定（≈0）",
              status = "warning",
              width = 12,
              p("• 維持現有服務水準"),
              p("• 定期但不過度打擾"),
              p("• 季節性促銷活動")
            ),
            bs4Card(
              title = "漸趨靜止（<0）",
              status = "danger",
              width = 12,
              p("• 緊急挽回措施"),
              p("• 了解流失原因"),
              p("• 提供特別優惠重新激活")
            )
          )
        } else {
          div(
            class = "alert alert-info",
            p("請選擇具體指標以獲得詳細行銷建議")
          )
        }
      )
    })
    
    # 檢查是否有分組資料
    output$has_segmentation <- reactive({
      !is.null(values$segmented_data)
    })
    outputOptions(output, "has_segmentation", suspendWhenHidden = FALSE)
    
    # 檢查是否已執行分群並且有選擇指標
    output$has_ai_recommendations <- reactive({
      isTRUE(values$segmentation_completed) && !is.null(values$current_metric)
    })
    outputOptions(output, "has_ai_recommendations", suspendWhenHidden = FALSE)
    
    # 客群分組視圖
    output$segmentation_view <- renderUI({
      # 只有在已執行分群且有選擇指標時才顯示
      if(!isTRUE(values$segmentation_completed) || is.null(values$current_metric)) {
        return(
          div(
            class = "alert alert-info",
            icon("info-circle"),
            "請先執行客戶分群分析，然後選擇指標查看結果"
          )
        )
      }
      
      req(values$segmented_data)
      
      # 根據指標顯示不同標題
      title_text <- switch(values$current_metric,
        "R" = "📊 最近購買時間分群結果",
        "F" = "📊 購買頻率分群結果",
        "M" = "📊 購買金額分群結果（80/20法則）",
        "CAI" = "📊 活躍度分群結果",
        "PCV" = "📊 過去價值分群結果（80/20法則）",
        "CRI" = "📊 參與度分群結果",
        "NES" = "📊 顧客狀態分群結果",
        "📊 客群分組結果"
      )
      
      tagList(
        h5(title_text),
        uiOutput(ns("segmentation_summary")),
        hr(),
        
        # AI行銷建議（如果有的話）
        conditionalPanel(
          condition = paste0("output['", ns("has_ai_recommendations"), "'] == true"),
          h5("🎯 AI 行銷建議"),
          uiOutput(ns("ai_marketing_advice")),
          hr()
        ),
        
        h5("📋 詳細客戶名單"),
        DTOutput(ns("segmented_customers_table"))
      )
    })
    
    # 當前分群結果摘要（簡化版本，不顯示卡片）
    output$current_segmentation_summary <- renderUI({
      NULL  # 不顯示任何內容
    })
    
    # 當前行銷建議（顯示在右側）
    output$current_marketing_advice <- renderUI({
      if(is.null(values$ai_recommendations)) {
        return(div(
          class = "text-muted",
          style = "padding: 8px; font-size: 11px;",
          p("點擊「執行AI增強分析」以獲得行銷建議")
        ))
      }
      
      # 將建議轉換為markdown格式（調整字體大小）
      markdown_content <- paste(
        lapply(names(values$ai_recommendations), function(seg) {
          rec <- values$ai_recommendations[[seg]]
          paste0(
            "##### ", seg, "\n",  # 改用 ##### 讓標題更小
            "**策略：** ", rec$strategy, "\n\n",
            "**行動建議：**\n",
            paste(lapply(rec$actions, function(action) {
              paste0("- ", action)
            }), collapse = "\n"),
            "\n"
          )
        }),
        collapse = "\n---\n\n"
      )
      
      # 使用HTML函數渲染markdown，並包裝在div中控制字體大小（改為11px）
      div(
        style = "font-size: 11px; line-height: 1.4;",
        HTML(markdown::markdownToHTML(
          text = markdown_content,
          fragment.only = TRUE,
          options = c("use_xhtml", "smartypants")
        ))
      )
    })
    
    # 客群分組摘要（簡化版本）
    output$segmentation_summary <- renderUI({
      req(values$segmented_data, values$current_metric)
      
      # 計算各分組統計，並檢查欄位存在性
      data <- values$segmented_data
      available_cols <- names(data)
      metric <- values$current_metric
      
      # 根據現有欄位計算統計
      segment_summary <- data %>%
        filter(!is.na(segment)) %>%
        group_by(segment) %>%
        summarise(
          count = n(),
          pct = round(n() / nrow(data) * 100, 1),
          avg_r = if("r_value" %in% available_cols) round(mean(r_value, na.rm = TRUE), 1) else NA,
          avg_f = if("f_value" %in% available_cols) round(mean(f_value, na.rm = TRUE), 1) else NA,
          avg_m = if("m_value" %in% available_cols) round(mean(m_value, na.rm = TRUE), 2) else NA,
          .groups = "drop"
        ) %>%
        arrange(desc(count))
      
      # 根據指標決定顯示的欄位標題
      metric_label <- switch(metric,
        "R" = "最近購買",
        "F" = "購買頻率",
        "M" = "購買金額",
        "CAI" = "活躍度",
        "PCV" = "過去價值",
        "CRI" = "參與度",
        "NES" = "顧客狀態",
        "指標"
      )
      
      # 簡化的表格顯示
      tags$table(
        class = "table table-sm table-hover",
        tags$thead(
          tags$tr(
            tags$th(paste0(metric_label, "分群")),
            tags$th("人數"),
            tags$th("佔比"),
            if("r_value" %in% available_cols) tags$th("R(天)") else NULL,
            if("f_value" %in% available_cols) tags$th("F(次)") else NULL,
            if("m_value" %in% available_cols) tags$th("M($)") else NULL
          )
        ),
        tags$tbody(
          lapply(1:nrow(segment_summary), function(i) {
            seg <- segment_summary[i, ]
            tags$tr(
              tags$td(seg$segment),
              tags$td(seg$count),
              tags$td(paste0(seg$pct, "%")),
              if("r_value" %in% available_cols) tags$td(if(!is.na(seg$avg_r)) seg$avg_r else "-") else NULL,
              if("f_value" %in% available_cols) tags$td(if(!is.na(seg$avg_f)) seg$avg_f else "-") else NULL,
              if("m_value" %in% available_cols) tags$td(if(!is.na(seg$avg_m)) paste0("$", seg$avg_m) else "-") else NULL
            )
          })
        )
      )
    })
    
    # AI行銷建議顯示（簡化版本，不使用卡片）
    output$ai_marketing_advice <- renderUI({
      # 只有在已執行分群且有選擇指標時才顯示
      if(!isTRUE(values$segmentation_completed) || is.null(values$current_metric)) {
        return(NULL)
      }
      
      # 使用分群數據生成建議
      req(values$segmented_data, values$current_metric)
      generateMarketingAdviceForMetric(values$current_metric, values$segmented_data)
    })
    
    # 根據指標生成行銷建議
    generateMarketingAdviceForMetric <- function(metric, data) {
      # 計算各分群的統計
      segments <- unique(data$segment)
      segments <- segments[!is.na(segments)]
      
      if(length(segments) == 0) {
        return(p("無分群數據"))
      }
      
      # 根據不同指標提供建議
      tagList(
        lapply(segments, function(seg) {
          seg_data <- data[data$segment == seg & !is.na(data$segment), ]
          
          if(nrow(seg_data) == 0) return(NULL)
          
          # 計算統計數據
          seg_stats <- seg_data %>%
            summarise(
              count = n(),
              avg_r = mean(r_value, na.rm = TRUE),
              avg_f = mean(f_value, na.rm = TRUE),
              avg_m = mean(m_value, na.rm = TRUE)
            )
          
          # 根據指標和分群提供建議
          advice <- getSegmentAdvice(metric, seg, seg_stats)
          
          div(
            style = "margin-bottom: 15px; padding: 10px; background: #f8f9fa; border-radius: 5px;",
            h6(paste0("🔸 ", seg, " (", seg_stats$count, "人)"), 
               style = "color: #2c3e50; font-weight: bold; margin-bottom: 8px;"),
            tags$ul(
              style = "margin: 0; padding-left: 20px;",
              lapply(advice, function(action) {
                tags$li(action, style = "margin: 3px 0; color: #495057;")
              })
            )
          )
        })
      )
    }
    
    # 根據指標和分群獲取建議
    getSegmentAdvice <- function(metric, segment, stats) {
      if(metric == "R") {
        if(grepl("高活躍", segment)) {
          return(c(
            "推薦相關產品交叉銷售",
            "邀請加入VIP計劃",
            "提供升級服務機會"
          ))
        } else if(grepl("低活躍", segment)) {
          return(c(
            "發送個人化召回郵件",
            "提供限時優惠券",
            "推送新品資訊喚醒興趣"
          ))
        } else {
          return(c(
            "定期推送會員專屬優惠",
            "建立積分獎勵機制",
            "提供生日月優惠"
          ))
        }
      } else if(metric == "F") {
        if(grepl("高頻", segment)) {
          return(c(
            "建立VIP專屬服務",
            "提供批量採購優惠",
            "優先體驗新品"
          ))
        } else if(grepl("低頻", segment)) {
          return(c(
            "了解購買障礙",
            "提供試用優惠",
            "簡化購買流程"
          ))
        } else {
          return(c(
            "設計忠誠度計劃",
            "提供累積消費獎勵",
            "定期關懷提醒"
          ))
        }
      } else if(metric == "M") {
        if(grepl("高價值", segment)) {
          return(c(
            "提供專屬客戶經理",
            "客製化產品推薦",
            "尊榮級售後服務"
          ))
        } else if(grepl("低價值", segment)) {
          return(c(
            "推薦入門產品",
            "提供體驗優惠",
            "教育產品價值"
          ))
        } else {
          return(c(
            "推薦升級產品",
            "捆綁銷售優惠",
            "分期付款方案"
          ))
        }
      } else {
        # 預設建議
        return(c(
          "定期關懷維護",
          "提供個人化服務",
          "建立長期關係"
        ))
      }
    }
    
    # 分組客戶詳細表格
    output$segmented_customers_table <- renderDT({
      # 檢查是否已執行分群分析
      if(!isTRUE(values$segmentation_completed) || is.null(values$temp_chinese_table)) {
        return(datatable(
          data.frame(提示 = "請先執行客戶分群分析"),
          options = list(
            dom = 't',
            language = list(emptyTable = "請點擊『執行客戶分群』按鈕開始分析")
          ),
          rownames = FALSE
        ))
      }
      
      if(nrow(values$temp_chinese_table) == 0) {
        return(datatable(data.frame(訊息 = "分組資料為空，請確認資料正確"), rownames = FALSE))
      }
      
      # 使用統一的中文表格
      display_data <- values$temp_chinese_table
      metric <- values$current_metric
      
      # 根據當前指標選擇對應的分群欄位
      segment_col_mapping <- list(
        "R" = "R分群",
        "F" = "F分群",
        "M" = "M分群",
        "CAI" = "活躍度分群",
        "PCV" = "價值分群",
        "CRI" = "參與度分群",
        "NES" = "狀態分群"
      )
      
      # 找到對應的分群欄位
      segment_col <- segment_col_mapping[[metric]]
      if(is.null(segment_col) || !segment_col %in% names(display_data)) {
        segment_col <- "客群分組"  # 預設使用「客群分組」
      }
      
      # 選擇要顯示的欄位
      display_cols <- c("客戶ID", segment_col)
      
      # 根據當前指標只添加對應的中文欄位
      if(values$current_metric == "R") {
        if("最近購買(天)" %in% names(display_data)) display_cols <- c(display_cols, "最近購買(天)")
      } else if(values$current_metric == "F") {
        if("購買頻率(次)" %in% names(display_data)) display_cols <- c(display_cols, "購買頻率(次)")
      } else if(values$current_metric == "M") {
        if("平均金額($)" %in% names(display_data)) display_cols <- c(display_cols, "平均金額($)")
      } else if(values$current_metric == "CAI") {
        if("活躍度" %in% names(display_data)) display_cols <- c(display_cols, "活躍度")
      } else if(values$current_metric == "PCV") {
        if("過去價值($)" %in% names(display_data)) {
          display_cols <- c(display_cols, "過去價值($)")
        } else if("總消費($)" %in% names(display_data)) {
          display_cols <- c(display_cols, "總消費($)")
        }
      } else if(values$current_metric == "CRI") {
        if("參與度分數" %in% names(display_data)) display_cols <- c(display_cols, "參與度分數")
      } else if(values$current_metric == "NES") {
        if("客戶狀態" %in% names(display_data)) display_cols <- c(display_cols, "客戶狀態")
      }
      
      # 確保欄位存在
      display_cols <- intersect(display_cols, names(display_data))
      
      # 建立顯示資料框
      if(length(display_cols) > 0) {
        display_data <- display_data[, display_cols, drop = FALSE]
      } else {
        return(datatable(data.frame(訊息 = "沒有可顯示的欄位"), rownames = FALSE))
      }
      
      # 記錄需要格式化的中文欄位
      format_round_cols <- c("最近購買(天)", "購買頻率(次)", "購買次數")
      format_currency_cols <- c("平均金額($)", "過去價值($)", "總消費($)", "終身價值($)")
      
      # 按分組排序
      if("客群分組" %in% names(display_data)) {
        display_data <- display_data[order(display_data$客群分組), ]
      }
      
      dt <- datatable(
        display_data,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          order = list(list(1, 'asc')),
          dom = 'Bfrtip',
          buttons = list(
            list(extend = 'copy', exportOptions = list(modifier = list(page = "all"))),
            list(extend = 'csv', exportOptions = list(modifier = list(page = "all"))),
            list(extend = 'excel', exportOptions = list(modifier = list(page = "all")))
          ),
          language = list(
            search = "搜尋:",
            lengthMenu = "顯示 _MENU_ 筆資料",
            info = "顯示第 _START_ 至 _END_ 筆，共 _TOTAL_ 筆",
            paginate = list(
              first = "第一頁",
              last = "最後一頁",
              `next` = "下一頁",
              previous = "上一頁"
            )
          )
        ),
        extensions = 'Buttons',
        rownames = FALSE
      )
      
      # 直接檢查並格式化中文欄位
      # 格式化整數欄位
      existing_round <- intersect(format_round_cols, names(display_data))
      if(length(existing_round) > 0) {
        tryCatch({
          dt <- dt %>% formatRound(existing_round, 0)
        }, error = function(e) {
          message("formatRound error: ", e$message)
        })
      }
      
      # 格式化貨幣欄位
      existing_currency <- intersect(format_currency_cols, names(display_data))
      if(length(existing_currency) > 0) {
        tryCatch({
          dt <- dt %>% formatCurrency(existing_currency, "$")
        }, error = function(e) {
          message("formatCurrency error: ", e$message)
        })
      }
      
      dt
    })
    
    # 客群分組結果顯示
    output$segmentation_results <- renderUI({
      req(values$segmented_data)
      
      # 計算各分組統計
      segment_stats <- values$segmented_data %>%
        group_by(segment) %>%
        summarise(
          count = n(),
          avg_r = mean(r_value, na.rm = TRUE),
          avg_f = mean(f_value, na.rm = TRUE),
          avg_m = mean(m_value, na.rm = TRUE),
          .groups = "drop"
        )
      
      tagList(
        fluidRow(
          lapply(1:nrow(segment_stats), function(i) {
            row <- segment_stats[i,]
            color <- switch(as.character(row$segment),
              "高價值" = "success",
              "高活躍" = "success",
              "中價值" = "warning",
              "中活躍" = "warning",
              "低價值" = "danger",
              "低活躍" = "danger",
              "漸趨活躍" = "success",
              "穩定" = "info",
              "漸趨靜止" = "warning",
              "default" = "secondary"
            )
            
            column(4,
              bs4InfoBox(
                title = row$segment,
                value = paste0(row$count, " 人"),
                subtitle = paste0(
                  "R: ", round(row$avg_r, 1), "天 | ",
                  "F: ", round(row$avg_f, 1), "次 | ",
                  "M: $", round(row$avg_m, 2)
                ),
                icon = icon("users"),
                color = color,
                width = 12
              )
            )
          })
        ),
        hr(),
        h5("詳細客戶名單"),
        DTOutput("segmented_customers_table")
      )
    })
    
    # 新增：AI分析結果顯示
    output$ai_analysis <- renderUI({
      req(values$ai_insights)
      
      insights <- values$ai_insights
      
      HTML(paste0(
        "<div style='padding: 20px; background: #f8f9fa; border-radius: 8px;'>",
        "<h4 style='color: #2c3e50; margin-bottom: 20px;'>🤖 AI 分析洞察</h4>",
        
        "<div style='margin-bottom: 20px;'>",
        "<h5 style='color: #34495e;'>💰 購買金額分析</h5>",
        "<pre style='background: white; padding: 10px; border-radius: 4px;'>", insights$monetary, "</pre>",
        "</div>",
        
        "<div style='margin-bottom: 20px;'>",
        "<h5 style='color: #34495e;'>⏰ 最近購買時間分析</h5>",
        "<pre style='background: white; padding: 10px; border-radius: 4px;'>", insights$recency, "</pre>",
        "</div>",
        
        "<div style='margin-bottom: 20px;'>",
        "<h5 style='color: #34495e;'>🔄 購買頻率分析</h5>",
        "<pre style='background: white; padding: 10px; border-radius: 4px;'>", insights$frequency, "</pre>",
        "</div>",
        
        "<div style='margin-bottom: 20px;'>",
        "<h5 style='color: #34495e;'>👥 顧客狀態分析</h5>",
        "<pre style='background: white; padding: 10px; border-radius: 4px;'>", insights$nes, "</pre>",
        "</div>",
        
        "</div>"
      ))
    })
    
    # ---- AI 洞察輸出 --------------------------------------------------------
    output$has_ai_insights <- reactive({
      !is.null(values$ai_insights)
    })
    outputOptions(output, "has_ai_insights", suspendWhenHidden = FALSE)
    
    # AI分析完成標記
    output$has_ai_analysis <- reactive({
      !is.null(values$ai_analysis_done) && values$ai_analysis_done == TRUE
    })
    outputOptions(output, "has_ai_analysis", suspendWhenHidden = FALSE)
    
    # AI分析結果顯示
    output$ai_analysis_results <- renderUI({
      # 確保AI分析完成（使用 isTRUE 來安全檢查）
      if(!isTRUE(values$ai_analysis_done)) {
        return(NULL)
      }
      
      # 檢查是否有任何結果
      if(is.null(values$ai_analysis_summary) && is.null(values$ai_recommendations)) {
        return(div(
          class = "alert alert-info",
          p("正在生成AI分析結果，請稍候...")
        ))
      }
      
      # 使用isolate確保只在需要時更新
      isolate({
        tagList(
          # AI分析摘要
          if(!is.null(values$ai_analysis_summary)) {
            bs4Card(
              title = "📊 整體分析摘要",
              status = "primary",
              solidHeader = FALSE,
              width = 12,
              collapsible = TRUE,
              HTML(values$ai_analysis_summary)
            )
          },
          
          # AI行銷建議（dna_segment_marketing的結果）
          if(!is.null(values$ai_recommendations)) {
            bs4Card(
              title = "🎯 分群行銷建議",
              status = "success",
              solidHeader = FALSE,
              width = 12,
              collapsible = TRUE,
              collapsed = FALSE,
              div(
                style = "font-size: 12px; line-height: 1.5;",
                HTML(
                  paste(
                    lapply(names(values$ai_recommendations), function(seg) {
                      rec <- values$ai_recommendations[[seg]]
                      paste0(
                        "<div style='margin-bottom: 15px; padding: 10px; background: #f8f9fa; border-radius: 5px;'>",
                        "<h6 style='color: #2c3e50; margin-bottom: 8px;'>", seg, "</h6>",
                        "<p style='margin-bottom: 5px;'><strong>策略：</strong> ", rec$strategy, "</p>",
                        "<p style='margin-bottom: 5px;'><strong>行動建議：</strong></p>",
                        "<ul style='margin-left: 20px; margin-bottom: 0;'>",
                        paste(lapply(rec$actions, function(action) {
                          paste0("<li style='margin-bottom: 3px;'>", action, "</li>")
                        }), collapse = ""),
                        "</ul>",
                        "</div>"
                      )
                    }),
                    collapse = ""
                  )
                )
              )
            )
          }
        )
      })  # 結束 isolate
    })
    
    output$ai_insights_content <- renderUI({
      if (!is.null(values$ai_insights)) {
        # 將 AI 結果轉換為 HTML 格式
        insights_html <- markdown::markdownToHTML(
          text = values$ai_insights,
          fragment.only = TRUE
        )
        
        div(
          class = "ai-insights-section",
          style = "background: #ffffff; border: 1px solid #dee2e6; border-radius: 5px; padding: 15px;",
          HTML(insights_html)
        )
      }
    })
    
    # Return results
    return(reactive({
      list(
        dna_results = values$dna_results,
        combined_data = values$combined_data,
        status = values$status_text,
        ai_insights = values$ai_insights  # 新增：AI洞察結果
      )
    }))
  })
} 