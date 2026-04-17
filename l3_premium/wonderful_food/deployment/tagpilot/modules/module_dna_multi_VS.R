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
    h3("🧬 客戶 DNA 分析"),
    
    # Conditional File Upload Section (only show if no data uploaded from step 1)
    conditionalPanel(
      condition = paste0("output['", ns("has_uploaded_data"), "'] == false"),
      h4("📁 額外檔案上傳 (可選)"),
      fluidRow(
        column(6,
          wellPanel(
            h4("📁 多檔案上傳"),
            fileInput(ns("multi_files"), 
                     "選擇多個CSV檔案",
                     multiple = TRUE,
                     accept = c(".csv", ".xlsx", ".xls")),
            
            p("支援: Amazon銷售報告、一般交易記錄"),
            p("自動偵測: Buyer Email (客戶ID), Purchase Date (時間), Item Price (金額)"),
            
            verbatimTextOutput(ns("file_info"))
          )
        ),
        
        column(6,
          wellPanel(
            h4("⚙️ 分析設定"),
            numericInput(ns("min_transactions"), "最少交易次數", value = 2, min = 1),
            checkboxInput(ns("auto_detect"), "自動偵測欄位", value = TRUE),
            br(),
            actionButton(ns("process_files"), "🚀 合併檔案並分析", class = "btn-success")
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
          column(6, numericInput(ns("min_transactions_2"), "最少交易次數", value = 2, min = 1)),
          column(6, div(style = "margin-top: 25px;", 
                       actionButton(ns("analyze_uploaded"), "🚀 開始分析", class = "btn-success", style = "width: 100%;")))
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
      
      # Visualization controls
      div(style = "text-align: center; margin: 20px;",
        actionButton(ns("show_m"), "金額 (M)", class = "btn-info", style = "margin: 5px;"),
        actionButton(ns("show_r"), "最近性 (R)", class = "btn-info", style = "margin: 5px;"),
        actionButton(ns("show_f"), "頻率 (F)", class = "btn-info", style = "margin: 5px;"),
        actionButton(ns("show_nes"), "參與度 (NES)", class = "btn-warning", style = "margin: 5px;")
      ),
      
      # Results tabs
      tabsetPanel(
        tabPanel("📊 視覺化",
          fluidRow(
            column(6, plotlyOutput(ns("plot_ecdf"))),
            column(6, plotlyOutput(ns("plot_hist")))
          )
        ),
        tabPanel("📋 資料表",
          fluidRow(
            column(12,
              wellPanel(
                fluidRow(
                  column(6, checkboxInput(ns("convert_to_text"), "將數值轉換為高中低文字", value = FALSE)),
                  column(6, div(style = "margin-top: 25px;", 
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
        tabPanel("🤖 AI 分析", uiOutput(ns("ai_analysis")))
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
      files_info = NULL,
      combined_data = NULL,
      dna_results = NULL,
      current_metric = "M",
      status_text = "等待檔案上傳...",
      ai_insights = NULL
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
            ni = times
          ) %>%
          # 確保所有必要欄位存在且有正確的資料類型
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
              stop(paste("缺少必要欄位:", paste(missing_cols, collapse = ", ")))
            }
            
            results
            
          }, error = function(e) {
            values$status_text <- paste("❌ DNA分析錯誤:", e$message)
            return(NULL)
          })
          
          if (!is.null(dna_results)) {
            values$dna_results <- dna_results
            values$status_text <- "🎉 DNA 分析完成！"
            
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
    
    # Metric button handlers
    observeEvent(input$show_m, { values$current_metric <- "M" })
    observeEvent(input$show_r, { values$current_metric <- "R" })
    observeEvent(input$show_f, { values$current_metric <- "F" })
    observeEvent(input$show_nes, { values$current_metric <- "NES" })
    
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
            x = ~sorted_values, 
            y = ~ecdf_values,
            type = "scatter", 
            mode = "lines",
            line = list(color = "#1F77B4", width = 2),
            hoverinfo = "text",
            text = ~paste0(
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
        
        # 檢查並選擇可用的欄位
        available_cols <- c("customer_id", "r_value", "f_value", "m_value", "ipt_mean", "cai_value", "pcv", "clv", "nes_status", "nes_value")
        existing_cols <- intersect(available_cols, names(data))
        
        if (length(existing_cols) == 0) {
          return(DT::datatable(data.frame(
            Message = "未找到預期的數據欄位",
            Available_Columns = paste(names(data), collapse = ", ")
          ), options = list(pageLength = 15, scrollX = TRUE), rownames = FALSE))
        }
        
        # 選擇並處理數據
        data <- data[, existing_cols, drop = FALSE]
        
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
    
    # Return results
    return(reactive({
      list(
        dna_results = values$dna_results,
        combined_data = values$combined_data,
        status = values$status_text
      )
    }))
  })
} 