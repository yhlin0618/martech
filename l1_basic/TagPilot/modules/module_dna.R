################################################################################
# DNA Analysis Module                                                           #
# Based on D01: DNA Analysis Derivation Flow                                   #
################################################################################

# Load required packages
library(dplyr)
library(tidyr)
library(plotly)

# Source required functions
if (file.exists("scripts/global_scripts/04_utils/fn_analysis_dna.R")) {
  source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
} else {
  warning("DNA analysis function not found. Please check the global_scripts path.")
}

#' DNA Analysis Module – UI
dnaModuleUI <- function(id) {
  ns <- NS(id)
  div(id = ns("dna_analysis_box"),
      h4("步驟 3：DNA 分析"),
      includeMarkdown("md/dna_analysis_format.md"),
      
      fluidRow(
        column(4,
               h5("🔧 分析參數"),
               numericInput(ns("min_transactions"), "最少交易次數", value = 2, min = 1, max = 10),
               numericInput(ns("delta"), "折扣因子 (δ)", value = 0.1, min = 0.001, max = 1, step = 0.01),
               checkboxInput(ns("skip_within_subject"), "跳過主體內分析（提升速度）", value = FALSE),
               br(),
               actionButton(ns("run_dna"), "🧬 執行 DNA 分析", class = "btn-primary"),
               br(), br(),
               textOutput(ns("analysis_status"))
        ),
        column(8,
               h5("📊 資料預處理結果"),
               DTOutput(ns("processed_data_preview"))
        )
      ),
      
      hr(),
      
      # DNA 分析結果展示
      conditionalPanel(
        condition = paste0("output['", ns("show_results"), "'] == true"),
        tabsetPanel(
          id = ns("dna_tabs"),
          tabPanel("📈 分佈視覺化", 
                   fluidRow(
                     column(4,
                            h5("📊 指標選擇"),
                            actionButton(ns("show_m_ecdf"), "購買金額 (M)", class = "btn-block btn-info mb-2"),
                            actionButton(ns("show_r_ecdf"), "最近性 (R)", class = "btn-block btn-info mb-2"),
                            actionButton(ns("show_f_ecdf"), "頻率 (F)", class = "btn-block btn-info mb-2"),
                            actionButton(ns("show_ipt_ecdf"), "購買間隔 (IPT)", class = "btn-block btn-info mb-2"),
                            hr(),
                            actionButton(ns("show_f_hist"), "頻率直方圖", class = "btn-block btn-secondary mb-2"),
                            actionButton(ns("show_nes_hist"), "NES 分佈", class = "btn-block btn-secondary mb-2")
                     ),
                     column(8,
                            plotlyOutput(ns("dna_plot"), height = "500px")
                     )
                   )
          ),
          tabPanel("📋 DNA 資料表", 
                   h5("🧬 客戶 DNA 分析結果"),
                   DTOutput(ns("dna_results_table"))
          ),
          tabPanel("📊 統計摘要",
                   h5("📈 客戶群體統計"),
                   DTOutput(ns("dna_summary_table")),
                   br(),
                   h5("🎯 NES 狀態分佈"),
                   DTOutput(ns("nes_distribution_table"))
          ),
          # Email mapping tab (conditional)
          conditionalPanel(
            condition = paste0("output['", ns("has_email_mapping"), "'] == true"),
            tabPanel("📧 客戶ID映射",
                     h5("📧 電子郵件與數字ID對應表"),
                     DTOutput(ns("email_mapping_table"))
            )
          )
        )
      )
  )
}

#' DNA Analysis Module – Server
#'
#' @param user_info reactive – passed from login module
#' @param sales_data reactive – sales data from upload module
#' @return reactive containing the DNA analysis results
dnaModuleServer <- function(id, con, user_info, sales_data) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive values for storing results
    processed_sales <- reactiveVal(NULL)
    dna_results <- reactiveVal(NULL)
    current_plot_data <- reactiveVal(NULL)
    
    # ---- 資料預處理 --------------------------------------------------------
    observe({
      req(sales_data())
      
      tryCatch({
        # 標準化欄位名稱
        sales_raw <- sales_data()
        
        # 識別客戶 ID 欄位
        customer_id_col <- NULL
        possible_customer_cols <- c("customer_id", "buyer_email", "email", "customer", "buyer_id")
        for (col in possible_customer_cols) {
          if (col %in% names(sales_raw)) {
            customer_id_col <- col
            break
          }
        }
        
        # 識別時間欄位
        time_col <- NULL
        possible_time_cols <- c("payment_time", "time", "order_date", "purchase_date", "date")
        for (col in possible_time_cols) {
          if (col %in% names(sales_raw)) {
            time_col <- col
            break
          }
        }
        
        # 識別金額欄位
        amount_col <- NULL
        possible_amount_cols <- c("lineitem_price", "total_spent", "sales", "amount", "price", "total")
        for (col in possible_amount_cols) {
          if (col %in% names(sales_raw)) {
            amount_col <- col
            break
          }
        }
        
        if (is.null(customer_id_col) || is.null(time_col) || is.null(amount_col)) {
          processed_sales(data.frame(
            Message = paste("缺少必要欄位:",
                          ifelse(is.null(customer_id_col), "客戶ID", ""),
                          ifelse(is.null(time_col), "時間", ""),
                          ifelse(is.null(amount_col), "金額", ""))
          ))
          return()
        }
        
        # 資料標準化
        standardized_data <- sales_raw %>%
          rename(
            customer_id = !!sym(customer_id_col),
            payment_time = !!sym(time_col),
            lineitem_price = !!sym(amount_col)
          ) %>%
          mutate(
            # 保留原始客戶ID以供參考
            original_customer_id = customer_id,
            # 標準化客戶 ID（如果是郵件，轉換為數字）
            customer_id = if(is.character(customer_id)) {
              # 為每個唯一的電子郵件創建數字ID
              as.integer(as.factor(customer_id))
            } else {
              as.integer(customer_id)
            },
            # 標準化時間格式
            payment_time = as.POSIXct(payment_time),
            # 標準化金額
            lineitem_price = as.numeric(lineitem_price),
            # 平台 ID（上傳資料預設為 "upload"）
            platform_id = "upload"
          ) %>%
          filter(
            !is.na(customer_id),
            !is.na(payment_time),
            !is.na(lineitem_price),
            lineitem_price > 0
          ) %>%
          arrange(customer_id, payment_time)
        
        # 計算客戶層級統計
        customer_summary <- standardized_data %>%
          group_by(customer_id) %>%
          summarise(
            total_transactions = n(),
            min_transaction_count = n(),
            .groups = "drop"
          )
        
        # 顯示預處理結果
        preview_data <- data.frame(
          統計項目 = c("總交易數", "客戶數量", "符合條件客戶數", "平均每客戶交易數"),
          數值 = c(
            nrow(standardized_data),
            length(unique(standardized_data$customer_id)),
            sum(customer_summary$total_transactions >= input$min_transactions %||% 2),
            round(mean(customer_summary$total_transactions), 2)
          )
        )
        
        # 創建電子郵件到數字ID的映射表以供後續使用
        email_mapping <- NULL
        if("original_customer_id" %in% names(standardized_data) && 
           any(grepl("@", standardized_data$original_customer_id, fixed = TRUE))) {
          email_mapping <- standardized_data %>%
            select(original_customer_id, customer_id) %>%
            distinct() %>%
            arrange(customer_id)
        }
        
        processed_sales(list(
          standardized = standardized_data,
          summary = customer_summary,
          preview = preview_data,
          email_mapping = email_mapping
        ))
        
        output$processed_data_preview <- renderDT(preview_data, options = list(pageLength = 10), selection = "none")
        
      }, error = function(e) {
        processed_sales(data.frame(Message = paste("資料預處理錯誤:", e$message)))
        output$processed_data_preview <- renderDT(
          data.frame(錯誤 = paste("資料預處理失敗:", e$message)), 
          selection = "none"
        )
      })
    })
    
    # ---- DNA 分析執行 -------------------------------------------------------
    observeEvent(input$run_dna, {
      req(processed_sales())
      
      output$analysis_status <- renderText("🔄 正在執行 DNA 分析...")
      
      tryCatch({
        data_list <- processed_sales()
        
        if (is.data.frame(data_list) && "Message" %in% names(data_list)) {
          output$analysis_status <- renderText("❌ 無法執行分析：資料預處理失敗")
          return()
        }
        
        standardized_data <- data_list$standardized
        customer_summary <- data_list$summary
        
        # 過濾符合最少交易次數的客戶
        min_trans <- input$min_transactions %||% 2
        valid_customers <- customer_summary %>%
          filter(total_transactions >= min_trans) %>%
          pull(customer_id)
        
        if (length(valid_customers) == 0) {
          output$analysis_status <- renderText("❌ 沒有客戶符合最少交易次數要求")
          return()
        }
        
        filtered_data <- standardized_data %>%
          filter(customer_id %in% valid_customers)
        
        # D01 步驟：創建客戶時間序列
        sales_by_customer_by_date <- filtered_data %>%
          # customer_id 已經是數值型，不需要再次轉換
          group_by(customer_id, date = as.Date(payment_time)) %>%
          summarise(
            sum_spent_by_date = sum(lineitem_price, na.rm = TRUE),
            count_transactions_by_date = n(),
            payment_time = min(payment_time, na.rm = TRUE),  # 添加時間欄位供analysis_dna使用
            platform_id = "upload",  # 固定值，避免first()錯誤
            .groups = "drop"
          )
        
        # 創建客戶級聚合
        sales_by_customer <- filtered_data %>%
          # customer_id 已經是數值型，不需要再次轉換
          group_by(customer_id) %>%
          summarise(
            total_spent = sum(lineitem_price, na.rm = TRUE),
            times = n(),
            first_purchase = min(payment_time, na.rm = TRUE),
            last_purchase = max(payment_time, na.rm = TRUE),
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
        
        # 執行 DNA 分析
        output$analysis_status <- renderText("🧬 計算客戶 DNA 指標...")
        
        # 設定全域參數
        global_params <- list(
          delta = input$delta %||% 0.1,
          ni_threshold = min_trans,
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
        dna_analysis_results <- analysis_dna(
          df_sales_by_customer = sales_by_customer,
          df_sales_by_customer_by_date = sales_by_customer_by_date,
          skip_within_subject = input$skip_within_subject %||% FALSE,
          verbose = TRUE,  # 啟用詳細訊息以便診斷問題
          global_params = global_params
        )
        
        dna_results(dna_analysis_results)
        output$analysis_status <- renderText("✅ DNA 分析完成！")
        
        # 顯示結果表格
        output$dna_results_table <- renderDT(
          dna_analysis_results$data_by_customer %>%
            select(customer_id, r_value, f_value, m_value, ipt_mean, cai_value, pcv, clv, nes_status),
          options = list(pageLength = 15, scrollX = TRUE),
          selection = "none"
        )
        
        # 統計摘要
        summary_stats <- dna_analysis_results$data_by_customer %>%
          summarise(
            客戶總數 = n(),
            平均RFM_R = round(mean(r_value, na.rm = TRUE), 2),
            平均RFM_F = round(mean(f_value, na.rm = TRUE), 2),
            平均RFM_M = round(mean(m_value, na.rm = TRUE), 2),
            平均購買間隔 = round(mean(ipt_mean, na.rm = TRUE), 2),
            平均CLV = round(mean(clv, na.rm = TRUE), 2)
          ) %>%
          pivot_longer(everything(), names_to = "指標", values_to = "數值")
        
        output$dna_summary_table <- renderDT(summary_stats, options = list(pageLength = 10), selection = "none")
        
        # NES 分佈
        nes_dist <- dna_analysis_results$data_by_customer %>%
          count(nes_status, name = "客戶數") %>%
          mutate(百分比 = round(客戶數 / sum(客戶數) * 100, 1)) %>%
          arrange(desc(客戶數))
        
        output$nes_distribution_table <- renderDT(nes_dist, options = list(pageLength = 10), selection = "none")
        
        # 電子郵件映射表
        data_list <- processed_sales()
        if (!is.null(data_list$email_mapping)) {
          output$email_mapping_table <- renderDT({
            data_list$email_mapping %>%
              rename(
                "原始電子郵件" = original_customer_id,
                "數字客戶ID" = customer_id
              )
          }, options = list(pageLength = 15, scrollX = TRUE), selection = "none")
        }
        
      }, error = function(e) {
        output$analysis_status <- renderText(paste("❌ DNA 分析失敗:", e$message))
        message("DNA Analysis Error: ", e$message)
      })
    })
    
    # 檢查是否有電子郵件映射
    output$has_email_mapping <- reactive({
      data_list <- processed_sales()
      !is.null(data_list) && !is.null(data_list$email_mapping) && nrow(data_list$email_mapping) > 0
    })
    outputOptions(output, "has_email_mapping", suspendWhenHidden = FALSE)
    
    # ---- 視覺化控制 ---------------------------------------------------------
    
    # 控制結果顯示
    output$show_results <- reactive({
      !is.null(dna_results())
    })
    outputOptions(output, "show_results", suspendWhenHidden = FALSE)
    
    # ECDF 圖表
    observeEvent(input$show_m_ecdf, {
      req(dna_results())
      current_plot_data("m_ecdf")
      update_plot()
    })
    
    observeEvent(input$show_r_ecdf, {
      req(dna_results())
      current_plot_data("r_ecdf")
      update_plot()
    })
    
    observeEvent(input$show_f_ecdf, {
      req(dna_results())
      current_plot_data("f_ecdf")
      update_plot()
    })
    
    observeEvent(input$show_ipt_ecdf, {
      req(dna_results())
      current_plot_data("ipt_ecdf")
      update_plot()
    })
    
    # 直方圖
    observeEvent(input$show_f_hist, {
      req(dna_results())
      current_plot_data("f_hist")
      update_plot()
    })
    
    observeEvent(input$show_nes_hist, {
      req(dna_results())
      current_plot_data("nes_hist")
      update_plot()
    })
    
    # 更新圖表函數
    update_plot <- function() {
      req(dna_results(), current_plot_data())
      
      plot_type <- current_plot_data()
      dna_data <- dna_results()$data_by_customer
      
      if (plot_type == "m_ecdf") {
        p <- dna_data %>%
          plot_ly(x = ~m_value, type = "scatter", mode = "lines",
                  line = list(shape = "hv"), name = "ECDF") %>%
          add_trace(y = seq(0, 1, length.out = nrow(dna_data)), 
                   line = list(color = "blue")) %>%
          layout(title = "購買金額 (M) 累積分佈函數",
                 xaxis = list(title = "M 值"),
                 yaxis = list(title = "累積機率"))
        
      } else if (plot_type == "r_ecdf") {
        p <- dna_data %>%
          plot_ly(x = ~r_value, type = "scatter", mode = "lines",
                  line = list(shape = "hv"), name = "ECDF") %>%
          add_trace(y = seq(0, 1, length.out = nrow(dna_data)), 
                   line = list(color = "red")) %>%
          layout(title = "最近性 (R) 累積分佈函數",
                 xaxis = list(title = "R 值（天數）"),
                 yaxis = list(title = "累積機率"))
        
      } else if (plot_type == "f_ecdf") {
        p <- dna_data %>%
          plot_ly(x = ~f_value, type = "scatter", mode = "lines",
                  line = list(shape = "hv"), name = "ECDF") %>%
          add_trace(y = seq(0, 1, length.out = nrow(dna_data)), 
                   line = list(color = "green")) %>%
          layout(title = "頻率 (F) 累積分佈函數",
                 xaxis = list(title = "F 值"),
                 yaxis = list(title = "累積機率"))
        
      } else if (plot_type == "ipt_ecdf") {
        p <- dna_data %>%
          plot_ly(x = ~ipt_mean, type = "scatter", mode = "lines",
                  line = list(shape = "hv"), name = "ECDF") %>%
          add_trace(y = seq(0, 1, length.out = nrow(dna_data)), 
                   line = list(color = "orange")) %>%
          layout(title = "購買間隔 (IPT) 累積分佈函數",
                 xaxis = list(title = "IPT 值（天數）"),
                 yaxis = list(title = "累積機率"))
        
      } else if (plot_type == "f_hist") {
        p <- dna_data %>%
          plot_ly(x = ~f_value, type = "histogram", name = "頻率分佈") %>%
          layout(title = "購買頻率分佈直方圖",
                 xaxis = list(title = "購買次數"),
                 yaxis = list(title = "客戶數量"))
        
      } else if (plot_type == "nes_hist") {
        nes_counts <- dna_data %>% count(nes_status)
        p <- nes_counts %>%
          plot_ly(x = ~nes_status, y = ~n, type = "bar", name = "NES 分佈") %>%
          layout(title = "NES 狀態分佈",
                 xaxis = list(title = "NES 狀態"),
                 yaxis = list(title = "客戶數量"))
      }
      
      output$dna_plot <- renderPlotly(p)
    }
    
    # ---- 回傳結果 -----------------------------------------------------------
    list(
      dna_data = reactive(dna_results()),
      processed_data = reactive(processed_sales())
    )
  })
} 