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

# ✅ Source customer tags calculation functions (Modular approach - MP016)
if (file.exists("utils/calculate_customer_tags.R")) {
  source("utils/calculate_customer_tags.R")
}

# UI Function
dnaMultiPremiumModuleUI <- function(id) {
  ns <- NS(id)
  
  div(
    h3("Value × Activity × Lifecycle 分析", style = "text-align: center; margin: 20px 0;"),
    
    # 狀態顯示
    wellPanel(
      h4("📊 處理狀態"),
      verbatimTextOutput(ns("status"))
    ),

    # ✅ Task 7.2: 資料摘要儀表板（分析完成後顯示）
    conditionalPanel(
      condition = paste0("output['", ns("show_results"), "'] == true"),
      fluidRow(
        column(3,
          bs4ValueBox(
            value = uiOutput(ns("total_customers")),
            subtitle = "總客戶數",
            icon = icon("users"),
            color = "primary",
            width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = uiOutput(ns("avg_order_value")),
            subtitle = "平均客單價",
            icon = icon("dollar-sign"),
            color = "success",
            width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = uiOutput(ns("avg_purchase_cycle")),
            subtitle = "平均購買週期 (天)",
            icon = icon("clock"),
            color = "warning",
            width = 12
          )
        ),
        column(3,
          bs4ValueBox(
            value = uiOutput(ns("avg_transaction")),
            subtitle = "平均交易次數",
            icon = icon("shopping-cart"),
            color = "info",
            width = 12
          )
        )
      )
    ),

    # 分析設定
    conditionalPanel(
      condition = paste0("output['", ns("has_uploaded_data"), "'] == true"),
      wellPanel(
        h4("⚙️ 分析設定"),
        p("系統將分析所有客戶的交易資料，活躍度計算將自動篩選交易次數 ≥ 4 的客戶。"),
        actionButton(ns("analyze_uploaded"), "🚀 開始分析", class = "btn-success btn-lg", style = "width: 100%;")
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
                "瞌睡客" = "sleepy",
                "半睡客" = "half_sleepy",
                "沉睡客" = "dormant"
              ),
              selected = "newbie",
              inline = TRUE
            )
          )
        )
      ),

      # 標籤摘要和匯出
      fluidRow(
        column(12,
          bs4Card(
            title = "📊 客戶標籤摘要與匯出",
            status = "info",
            width = 12,
            solidHeader = TRUE,
            fluidRow(
              column(6,
                h5("已生成標籤："),
                uiOutput(ns("tags_summary"))
              ),
              column(6,
                h5("資料匯出："),
                downloadButton(ns("download_customer_tags"), "📥 下載客戶策略建議 (CSV)", class = "btn-success btn-lg", style = "width: 100%; margin-top: 10px;"),
                br(), br(),
                p(style = "color: #6c757d; font-size: 0.9em;",
                  "包含客戶ID、價值等級、活躍度、生命週期階段及對應的行銷策略建議")
              )
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
dnaMultiPremiumModuleServer <- function(id, con, user_info, uploaded_dna_data = NULL) {
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

    # ✅ Task 7.2: 資料摘要儀表板輸出
    output$total_customers <- renderUI({
      req(values$dna_results)
      n_customers <- nrow(values$dna_results$data_by_customer)
      tags$h2(format(n_customers, big.mark = ","), style = "margin: 0;")
    })

    output$avg_order_value <- renderUI({
      req(values$dna_results)
      avg_m <- mean(values$dna_results$data_by_customer$m_value, na.rm = TRUE)
      tags$h2(paste0("$", round(avg_m, 0)), style = "margin: 0;")
    })

    output$avg_purchase_cycle <- renderUI({
      req(values$dna_results)
      avg_ipt <- mean(values$dna_results$data_by_customer$ipt_mean, na.rm = TRUE)
      if (is.na(avg_ipt)) avg_ipt <- mean(values$dna_results$data_by_customer$ipt, na.rm = TRUE)
      tags$h2(round(avg_ipt, 1), style = "margin: 0;")
    })

    output$avg_transaction <- renderUI({
      req(values$dna_results)
      avg_ni <- mean(values$dna_results$data_by_customer$ni, na.rm = TRUE)
      tags$h2(round(avg_ni, 1), style = "margin: 0;")
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

                # 確保 ni (交易次數) 欄位存在
                ni = if("ni" %in% names(.)) {
                  as.numeric(ni)
                } else if("times" %in% names(.)) {
                  as.numeric(times)
                } else {
                  as.numeric(f_value)  # 如果都沒有，使用 f_value
                },

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

                # 計算 IPT (Inter-Purchase Time)
                ipt_value = if("ipt" %in% names(.)) {
                  as.numeric(ipt)
                } else {
                  pmax(customer_age_days / pmax(ni - 1, 1), 1)  # 避免除以零
                }
              ) %>%
              # 計算整體平均 IPT（用於新客判斷）
              mutate(
                avg_ipt = median(ipt_value, na.rm = TRUE)  # 使用中位數更穩健
              ) %>%
              # ✅ 修復：移除重複的 customer_age_days 計算（已在 Line 373 計算過）
              # mutate(
              #   customer_age_days = as.numeric(difftime(Sys.time(), time_first, units = "days"))
              # ) %>%
              mutate(
                # ✅ GAP-001 修復：簡化新客定義（2025-10-26）
                # 新客定義：只要購買次數為 1 就是新客
                # 理由：簡單明確，符合業務直覺
                lifecycle_stage = case_when(
                  is.na(r_value) ~ "unknown",
                  # 新客：只買一次
                  ni == 1 ~ "newbie",
                  # 主力客：R值 <= 7天
                  r_value <= 7 ~ "active",
                  # 瞌睡客：7 < R <= 14
                  r_value <= 14 ~ "sleepy",
                  # 半睡客：14 < R <= 21
                  r_value <= 21 ~ "half_sleepy",
                  # 沉睡客：R > 21 或 單次購買但超過平均週期
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
                )
              )

            # ✅ GAP-001 除錯：顯示新客統計資訊
            cat("\n=== 新客判斷除錯資訊 ===\n")
            cat("平均購買週期 (avg_ipt):", unique(customer_data$avg_ipt), "天\n")
            cat("總客戶數:", nrow(customer_data), "\n")
            cat("單次購買客戶數 (ni==1):", sum(customer_data$ni == 1, na.rm = TRUE), "\n")

            newbie_candidates <- customer_data %>% filter(ni == 1)
            if (nrow(newbie_candidates) > 0) {
              cat("單次購買客戶的 customer_age_days 範圍:",
                  min(newbie_candidates$customer_age_days, na.rm = TRUE), "-",
                  max(newbie_candidates$customer_age_days, na.rm = TRUE), "天\n")
              cat("符合新客條件 (ni==1 & customer_age_days <= avg_ipt):",
                  sum(newbie_candidates$customer_age_days <= unique(customer_data$avg_ipt), na.rm = TRUE), "\n")
            }

            cat("各生命週期階段分佈:\n")
            print(table(customer_data$lifecycle_stage))
            cat("=========================\n\n")

            # ✅ 任務 5.1: 活躍度計算需要 >= 4 筆交易
            # 將資料分為兩組：符合條件（ni >= 4）和不符合條件（ni < 4）
            customers_sufficient_data <- customer_data %>%
              filter(ni >= 4)

            customers_insufficient_data <- customer_data %>%
              filter(ni < 4)

            # 只對交易次數充足的客戶計算活躍度
            if (nrow(customers_sufficient_data) > 0) {
              customers_sufficient_data <- customers_sufficient_data %>%
                mutate(
                  # ✅ 方案 A：完全按照規劃文檔使用 CAI (Customer Activity Index)
                  # 規劃文檔要求：Activity = CAI ≥ 80th pct
                  # DNA 分析返回欄位：cai_value (CAI 數值), cai_ecdf (CAI 百分位數)
                  #
                  # CAI 計算邏輯（來自 fn_analysis_dna.R Line 669-677）：
                  # - 只對 ni >= 4 且 times != 1 的客戶計算
                  # - cai = (mle - wmle) / mle
                  # - cai_ecdf = CAI 的累積分佈函數值（百分位數）
                  #
                  # 分類邏輯：
                  # - 高活躍：cai_ecdf >= 0.8 (P80 以上，逐漸活躍)
                  # - 中活躍：cai_ecdf >= 0.2 (P20-P80，穩定)
                  # - 低活躍：cai_ecdf < 0.2 (P20 以下，逐漸不活躍)
                  #
                  # 降級策略（ni < 4 無 CAI）：
                  # - 使用 r_value 作為活躍度代理指標
                  # - r_value 越小 = 越活躍（最近購買）
                  activity_level = case_when(
                    # ni >= 4 且有 CAI 值：使用 CAI
                    !is.na(cai_ecdf) ~ case_when(
                      cai_ecdf >= 0.8 ~ "高",  # P80 以上 = 高活躍
                      cai_ecdf >= 0.2 ~ "中",  # P20-P80 = 中活躍
                      TRUE ~ "低"              # P20 以下 = 低活躍
                    ),
                    # ni < 4 無 CAI 值：降級使用 r_value
                    !is.na(r_value) ~ case_when(
                      r_value <= quantile(r_value, 0.2, na.rm = TRUE) ~ "高",  # 最近購買
                      r_value <= quantile(r_value, 0.8, na.rm = TRUE) ~ "中",  # 中等時間
                      TRUE ~ "低"                                               # 最久沒購買
                    ),
                    # 都沒有：未知
                    TRUE ~ "未知"
                  )
                )
            }

            # ✅ 方案 A 修正：交易次數不足的客戶使用 r_value 降級策略
            # 原因：ni < 4 時 DNA 分析不會計算 CAI（cai_ecdf = NA）
            # 降級策略：使用 r_value 作為活躍度代理指標
            if (nrow(customers_insufficient_data) > 0) {
              # 對於 ni < 4 的客戶，排除新客（ni == 1）後計算 r_value 分位數
              insufficient_non_newbie <- customers_insufficient_data %>%
                filter(lifecycle_stage != "newbie")

              if (nrow(insufficient_non_newbie) > 0) {
                customers_insufficient_data <- customers_insufficient_data %>%
                  mutate(
                    # ni < 4 的非新客：使用 r_value 降級策略
                    activity_level = case_when(
                      lifecycle_stage == "newbie" ~ NA_character_,  # 新客不計算活躍度
                      !is.na(r_value) ~ case_when(
                        r_value <= quantile(r_value[lifecycle_stage != "newbie"], 0.2, na.rm = TRUE) ~ "高",
                        r_value <= quantile(r_value[lifecycle_stage != "newbie"], 0.8, na.rm = TRUE) ~ "中",
                        TRUE ~ "低"
                      ),
                      TRUE ~ NA_character_
                    ),
                    insufficient_data_flag = TRUE  # 標記這些客戶使用降級策略
                  )
              } else {
                # 全部都是新客
                customers_insufficient_data <- customers_insufficient_data %>%
                  mutate(
                    activity_level = NA_character_,
                    insufficient_data_flag = TRUE
                  )
              }
            }

            # 合併兩組資料
            customer_data <- bind_rows(
              customers_sufficient_data %>% mutate(insufficient_data_flag = FALSE),
              customers_insufficient_data
            ) %>%
              # ✅ 修正：只過濾掉真正「未知」的資料，保留 NA（交易次數不足）
              filter(lifecycle_stage != "unknown", value_level != "未知") %>%
              # activity_level 可以是 NA（ni < 4 的情況），不過濾
              filter(is.na(activity_level) | activity_level != "未知")

            # ========================================================================
            # ✅ 新增：計算九宮格位置 (grid_position)
            # ========================================================================
            customer_data <- customer_data %>%
              mutate(
                grid_position = case_when(
                  # ni < 4: activity_level 為 NA，無法分配到九宮格
                  is.na(activity_level) ~ "無",
                  # 九宮格分類 (Value × Activity)
                  value_level == "高" & activity_level == "高" ~ "A1",
                  value_level == "高" & activity_level == "中" ~ "A2",
                  value_level == "高" & activity_level == "低" ~ "A3",
                  value_level == "中" & activity_level == "高" ~ "B1",
                  value_level == "中" & activity_level == "中" ~ "B2",
                  value_level == "中" & activity_level == "低" ~ "B3",
                  value_level == "低" & activity_level == "高" ~ "C1",
                  value_level == "低" & activity_level == "中" ~ "C2",
                  value_level == "低" & activity_level == "低" ~ "C3",
                  TRUE ~ "其他"
                )
              )

            # ========================================================================
            # ✅ Phase 2: 客戶標籤計算（使用模組化函數）
            # ========================================================================

            # 使用 utils/calculate_customer_tags.R 中的模組化函數
            # 符合 MP016 Modularity 原則，提高可維護性和可測試性
            customer_data <- calculate_all_customer_tags(customer_data)

            # 生成分析完成訊息
            n_sufficient <- nrow(customers_sufficient_data)
            n_insufficient <- nrow(customers_insufficient_data)
            n_total <- nrow(customer_data)
            n_tags <- sum(grepl("^tag_", names(customer_data)))  # 計算標籤數量

            # ✅ Task 5.5: 樣本數警告（統計可靠性檢查）
            MIN_SAMPLE_SIZE <- 30  # 統計學建議的最小樣本數
            RECOMMENDED_SAMPLE_SIZE <- 100  # 建議的樣本數（更可靠的百分位數計算）

            # 建立基礎訊息
            status_message <- sprintf(
              "🎉 DNA 分析完成！\n總計 %d 位客戶，已生成 %d 個客戶標籤\n- %d 位客戶交易次數 ≥ 4（完整活躍度分析與 RFM 分數）\n- %d 位客戶交易次數 < 4（標記為低活躍，RFM 分數為 NA）",
              n_total, n_tags, n_sufficient, n_insufficient
            )

            # 添加樣本數警告
            if (n_total < MIN_SAMPLE_SIZE) {
              status_message <- paste0(
                status_message,
                sprintf(
                  "\n\n⚠️ 警告：樣本數不足（%d < %d）\n   百分位數計算可能不穩定，建議至少 %d 位客戶以確保統計可靠性",
                  n_total, MIN_SAMPLE_SIZE, MIN_SAMPLE_SIZE
                )
              )
            } else if (n_total < RECOMMENDED_SAMPLE_SIZE) {
              status_message <- paste0(
                status_message,
                sprintf(
                  "\n\n💡 提示：樣本數 %d 位，已達最小要求但建議達到 %d 位以獲得更可靠的分析結果",
                  n_total, RECOMMENDED_SAMPLE_SIZE
                )
              )
            }

            # 針對 ni >= 4 的客戶（用於活躍度計算）添加額外警告
            if (n_sufficient < MIN_SAMPLE_SIZE && n_sufficient > 0) {
              status_message <- paste0(
                status_message,
                sprintf(
                  "\n\n⚠️ 警告：符合活躍度分析條件的客戶數不足（%d < %d）\n   活躍度分群結果可能不夠穩定",
                  n_sufficient, MIN_SAMPLE_SIZE
                )
              )
            }

            dna_results$data_by_customer <- customer_data
            values$dna_results <- dna_results
            values$status_text <- status_message
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

      # ✅ Task 7.1: 增加進度指示器
      withProgress(message = '正在進行客戶分析', value = 0, {
        # 步驟 1: 準備資料
        incProgress(0.15, detail = "📊 準備分析資料...")
        Sys.sleep(0.3)  # 給使用者看到進度

        # 步驟 2: 執行 DNA 分析
        incProgress(0.20, detail = "🧬 執行 DNA 分析...")

        # ✅ 固定 min_transactions = 1，允許所有客戶（包括新客）進入分析
        # 活躍度計算的篩選（>= 4）將在後續步驟處理
        min_trans <- 1
        delta_val <- 0.1  # 固定時間折扣因子為0.1

        # 步驟 3: 計算客戶標籤
        incProgress(0.30, detail = "🏷️ 計算客戶標籤...")
        analyze_data(values$combined_data, min_trans, delta_val)

        # 步驟 4: 生成視覺化
        incProgress(0.20, detail = "📈 生成視覺化圖表...")
        Sys.sleep(0.3)

        # 步驟 5: 完成
        incProgress(0.15, detail = "✅ 分析完成！")
        Sys.sleep(0.2)
      })
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

    # ========================================================================
    # 標籤摘要顯示
    # ========================================================================

    output$tags_summary <- renderUI({
      req(values$dna_results)

      df <- values$dna_results$data_by_customer

      # 使用模組化函數獲取標籤摘要
      tags_info <- get_tags_summary(df)

      if (tags_info$total_tags == 0) {
        return(p("尚未生成標籤"))
      }

      # 建立 HTML 顯示
      tags_html <- lapply(names(tags_info$group_counts), function(group_name) {
        count <- tags_info$group_counts[[group_name]]

        if (count > 0) {
          tags$div(
            tags$strong(paste0("• ", group_name, ":")),
            tags$span(style = "color: #28a745; margin-left: 10px;",
              paste(count, "個標籤")),
            tags$br()
          )
        }
      })

      div(
        tags_html,
        tags$hr(),
        tags$strong(paste0("總計：", tags_info$total_tags, " 個客戶標籤"))
      )
    })

    # ========================================================================
    # CSV 下載功能
    # ========================================================================

    output$download_customer_tags <- downloadHandler(
      filename = function() {
        paste0("customer_strategy_", Sys.Date(), ".csv")
      },
      content = function(file) {
        req(values$dna_results)

        # 獲取完整資料
        df <- values$dna_results$data_by_customer

        # ✅ Phase 1.3: 簡化匯出欄位
        # 根據PDF需求，只保留5個核心欄位：
        # 1. customer_id（客戶ID）
        # 2. value_level（價值等級）
        # 3. activity_level（活躍度等級）
        # 4. lifecycle_stage（生命週期階段）
        # 5. strategy（建議策略）

        # 計算策略欄位
        df$grid_position <- paste0(
          switch(as.character(df$value_level), "高" = "A", "中" = "B", "低" = "C", NA_character_),
          switch(as.character(df$activity_level), "高" = "1", "中" = "2", "低" = "3", NA_character_),
          switch(as.character(df$lifecycle_stage),
            "newbie" = "N",
            "active" = "C",
            "sleepy" = "D",
            "half_sleepy" = "H",
            "dormant" = "S",
            NA_character_
          )
        )

        # 為每個客戶取得策略建議
        df$strategy_title <- sapply(df$grid_position, function(pos) {
          if (is.na(pos)) return(NA_character_)
          strategy <- get_strategy(pos)
          if (is.null(strategy)) return("新客不適用")
          return(strategy$title)
        })

        df$strategy_action <- sapply(df$grid_position, function(pos) {
          if (is.na(pos)) return(NA_character_)
          strategy <- get_strategy(pos)
          if (is.null(strategy)) return("統一新客歡迎計畫")
          return(strategy$action)
        })

        # 選擇匯出欄位（只保留5個核心欄位）
        export_data <- df[, c(
          "customer_id",
          "value_level",
          "activity_level",
          "lifecycle_stage",
          "strategy_title",
          "strategy_action"
        )]

        # 重新命名欄位（更清楚）
        names(export_data) <- c(
          "客戶ID",
          "價值等級",
          "活躍度等級",
          "生命週期階段",
          "策略名稱",
          "行動方案"
        )

        # 寫入 CSV（使用 UTF-8-BOM 編碼，Excel 可正確顯示中文）
        write.csv(export_data, file, row.names = FALSE, fileEncoding = "UTF-8", na = "")

        # 在 Windows 上，加入 BOM
        if (.Platform$OS.type == "windows") {
          content <- readLines(file, encoding = "UTF-8")
          writeLines(content, file, useBytes = TRUE)
        }
      }
    )

    # 生成九宮格內容（✅ Task 5.3: 優化視覺化）
    generate_grid_content <- function(value_level, activity_level, df, lifecycle_stage) {
      if (is.null(df)) {
        return(HTML('<div style="text-align: center; padding: 15px;">無此生命週期階段的客戶</div>'))
      }

      # 計算該區段的客戶數
      customers <- df[df$value_level == value_level & df$activity_level == activity_level, ]
      count <- nrow(customers)

      # ✅ 計算總客戶數和占比
      total_customers <- nrow(df)
      percentage <- if (total_customers > 0) round((count / total_customers) * 100, 1) else 0

      if (count == 0) {
        return(HTML('<div style="text-align: center; padding: 15px; color: #999;">無此類型客戶</div>'))
      }

      # 計算該區段的平均值
      avg_m <- round(mean(customers$m_value, na.rm = TRUE), 0)
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
        return(HTML('<div style="text-align: center; padding: 15px; color: #ccc; font-style: italic;">（新客不適用）</div>'))
      }

      # ✅ 改善顏色編碼：價值 × 活躍度雙重編碼
      # 價值顏色（背景漸層強度）
      value_intensity <- switch(value_level,
        "高" = 1.0,    # 100% 強度
        "中" = 0.6,    # 60% 強度
        "低" = 0.3     # 30% 強度
      )

      # 活躍度顏色（綠/黃/紅）
      activity_color <- switch(activity_level,
        "高" = "#10b981",  # 綠色
        "中" = "#f59e0b",  # 橙色
        "低" = "#ef4444"   # 紅色
      )

      # 生命週期階段顏色（左側邊框）
      stage_color <- switch(lifecycle_stage,
        "newbie" = "#4CAF50",      # 綠色
        "active" = "#2196F3",      # 藍色
        "sleepy" = "#FFC107",      # 黃色
        "half_sleepy" = "#FF9800", # 橙色
        "dormant" = "#F44336"      # 紅色
      )

      # 根據價值和活躍度組合背景色
      bg_color <- sprintf("rgba(%d, %d, %d, %.2f)",
        col2rgb(activity_color)[1],
        col2rgb(activity_color)[2],
        col2rgb(activity_color)[3],
        0.1 * value_intensity)  # 高價值客戶背景更深

      # ✅ 生成優化後的策略內容
      HTML(sprintf('
        <div style="text-align: center; padding: 20px; border-left: 5px solid %s; background: %s; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
            <span style="font-size: 14px; font-weight: bold; color: #666; background: white; padding: 4px 8px; border-radius: 4px;">%s</span>
            <span style="font-size: 12px; color: %s; background: white; padding: 4px 8px; border-radius: 4px; font-weight: bold;">%s占比</span>
          </div>

          <h4 style="margin: 10px 0; color: #333;">
            <i class="fas fa-%s" style="margin-right: 8px; color: %s;"></i>
            %s
          </h4>

          <div style="font-size: 28px; font-weight: bold; margin: 15px 0; color: #2c3e50;">
            %d <span style="font-size: 16px; color: #7f8c8d;">位</span>
          </div>

          <div style="background: white; padding: 12px; border-radius: 6px; margin: 12px 0;">
            <div style="display: flex; justify-content: space-around; text-align: center;">
              <div>
                <div style="color: #888; font-size: 11px; margin-bottom: 4px;">平均金額</div>
                <div style="color: #2c3e50; font-weight: bold; font-size: 15px;">%s</div>
              </div>
              <div style="border-left: 1px solid #ddd;"></div>
              <div>
                <div style="color: #888; font-size: 11px; margin-bottom: 4px;">購買頻率</div>
                <div style="color: #2c3e50; font-weight: bold; font-size: 15px;">%.2f</div>
              </div>
            </div>
          </div>

          <div style="background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%); color: white; padding: 12px; border-radius: 6px; margin: 10px 0;">
            <div style="font-size: 11px; margin-bottom: 4px; opacity: 0.9;">建議策略</div>
            <div style="font-weight: bold; font-size: 13px;">%s</div>
          </div>

          <div style="color: #888; font-size: 11px; margin-top: 8px; font-style: italic;">
            KPI: %s
          </div>
        </div>
      ', stage_color, bg_color, grid_position, activity_color, paste0(percentage, "%%"),
         strategy$icon, activity_color, strategy$title, count,
         format(avg_m, big.mark=","), avg_f, strategy$action, strategy$kpi))
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

      # ✅ 新增：檢查是否有 ni < 4 的非新客（這些客戶無法計算活躍度）
      # 這些客戶不應該顯示在九宮格中，給予提示說明
      insufficient_non_newbie <- df %>%
        filter(ni < 4, lifecycle_stage != "newbie")

      if (nrow(insufficient_non_newbie) > 0 & current_stage != "newbie") {
        # 顯示提示訊息，說明這些客戶交易次數不足，無法進行九宮格分析
        insufficient_message <- div(
          bs4Card(
            title = "⚠️ 交易次數不足",
            status = "warning",
            solidHeader = TRUE,
            width = 12,
            p(paste0("目前選擇的生命週期階段中，有 ", nrow(insufficient_non_newbie),
                     " 位客戶的交易次數少於 4 次，無法可靠計算活躍度。")),
            p("這些客戶不會顯示在下方的九宮格分析中。"),
            p(strong("建議："), "持續觀察這些客戶，待交易次數達到 4 次以上後再進行完整分析。")
          )
        )
      } else {
        insufficient_message <- NULL
      }

      # ✅ 過濾：只顯示 ni >= 4 或是新客的資料在九宮格中
      # 新客會有專屬顯示，其他 ni < 4 的客戶不進入九宮格
      df_for_grid <- df %>%
        filter(ni >= 4 | lifecycle_stage == "newbie")

      # 新客專屬顯示（不顯示九宮格）
      if (current_stage == "newbie") {
        # 統計新客數據
        newbie_data <- df %>% filter(lifecycle_stage == "newbie")
        newbie_count <- nrow(newbie_data)

        # 按價值層級分組
        newbie_by_value <- newbie_data %>%
          group_by(value_level) %>%
          summarise(
            count = n(),
            avg_value = mean(m_value, na.rm = TRUE),
            .groups = "drop"
          ) %>%
          arrange(desc(avg_value))

        return(div(
          h4("生命週期階段：新客", style = "text-align: center; margin: 20px 0;"),

          bs4Card(
            title = "📊 新客概況",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            fluidRow(
              column(4,
                bs4ValueBox(
                  value = newbie_count,
                  subtitle = "新客總數",
                  icon = icon("user-plus"),
                  color = "info",
                  width = 12
                )
              ),
              column(4,
                bs4ValueBox(
                  value = sprintf("$%.0f", mean(newbie_data$m_value, na.rm = TRUE)),
                  subtitle = "平均首單價值",
                  icon = icon("dollar-sign"),
                  color = "success",
                  width = 12
                )
              ),
              column(4,
                bs4ValueBox(
                  value = sprintf("%.0f天", mean(newbie_data$r_value, na.rm = TRUE)),
                  subtitle = "平均首購距今",
                  icon = icon("clock"),
                  color = "warning",
                  width = 12
                )
              )
            )
          ),

          h4("💡 新客行銷策略", style = "text-align: center; margin: 30px 0 20px 0;"),

          fluidRow(
            column(4,
              bs4Card(
                title = "A3N：王者休眠-N",
                status = "success",
                solidHeader = TRUE,
                width = 12,
                div(
                  h3(style = "color: #28a745; margin: 0;",
                     newbie_by_value %>% filter(value_level == "高") %>% pull(count) %>% {if(length(.) > 0) . else 0}),
                  p(class = "text-muted", "位客戶"),
                  hr(),
                  div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-bottom: 10px;",
                    strong("指標："), "高V 低(無)A 新客"
                  ),
                  div(style = "padding: 10px; background: #e7f3ff; border-radius: 5px;",
                    strong("🎯 行銷方案："),
                    tags$ul(style = "margin: 10px 0 0 0; padding-left: 20px;",
                      tags$li("首購後 48h 無互動 → 專屬客服問候")
                    )
                  )
                )
              )
            ),
            column(4,
              bs4Card(
                title = "B3N：成長停滯-N",
                status = "warning",
                solidHeader = TRUE,
                width = 12,
                div(
                  h3(style = "color: #ffc107; margin: 0;",
                     newbie_by_value %>% filter(value_level == "中") %>% pull(count) %>% {if(length(.) > 0) . else 0}),
                  p(class = "text-muted", "位客戶"),
                  hr(),
                  div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-bottom: 10px;",
                    strong("指標："), "中V 低(無)A 新客"
                  ),
                  div(style = "padding: 10px; background: #fff3cd; border-radius: 5px;",
                    strong("🎯 行銷方案："),
                    tags$ul(style = "margin: 10px 0 0 0; padding-left: 20px;",
                      tags$li("首購加碼券（限 72h）")
                    )
                  )
                )
              )
            ),
            column(4,
              bs4Card(
                title = "C3N：清倉邊緣-N",
                status = "danger",
                solidHeader = TRUE,
                width = 12,
                div(
                  h3(style = "color: #dc3545; margin: 0;",
                     newbie_by_value %>% filter(value_level == "低") %>% pull(count) %>% {if(length(.) > 0) . else 0}),
                  p(class = "text-muted", "位客戶"),
                  hr(),
                  div(style = "padding: 10px; background: #f8f9fa; border-radius: 5px; margin-bottom: 10px;",
                    strong("指標："), "低V 低(無)A 新客"
                  ),
                  div(style = "padding: 10px; background: #f8d7da; border-radius: 5px;",
                    strong("🎯 行銷方案："),
                    tags$ul(style = "margin: 10px 0 0 0; padding-left: 20px;",
                      tags$li("取消後續推播、只留月度新品 EDM")
                    )
                  )
                )
              )
            )
          ),

          wellPanel(
            style = "background-color: #fff3cd; border-left: 4px solid #ffc107;",
            h5(icon("info-circle"), " 說明", style = "margin-top: 0;"),
            p("新客（交易次數 = 1）無法計算活躍度（需 ≥4 筆交易），因此不顯示九宮格。"),
            p("建議針對不同價值層級的新客，採用差異化的培育策略，促進二次購買。")
          )
        ))
      }

      # 其他生命週期階段：顯示九宮格
      div(
        # ✅ 顯示交易次數不足的警告（如果有）
        insufficient_message,

        h4(paste("生命週期階段:",
                 switch(current_stage,
                        "active" = "主力客",
                        "sleepy" = "瞌睡客",
                        "half_sleepy" = "半睡客",
                        "dormant" = "沉睡客")),
            style = "text-align: center; margin: 20px 0;"),

        # ✅ 使用 df_for_grid（已過濾 ni < 4 的非新客）
        # 高價值客戶
        fluidRow(
          column(4, bs4Card(title = "高價值 × 高活躍度", status = "success", width = 12, solidHeader = TRUE,
                          generate_grid_content("高", "高", df_for_grid, current_stage))),
          column(4, bs4Card(title = "高價值 × 中活躍度", status = "success", width = 12, solidHeader = TRUE,
                          generate_grid_content("高", "中", df_for_grid, current_stage))),
          column(4, bs4Card(title = "高價值 × 低活躍度", status = "success", width = 12, solidHeader = TRUE,
                          generate_grid_content("高", "低", df_for_grid, current_stage)))
        ),

        # 中價值客戶
        fluidRow(
          column(4, bs4Card(title = "中價值 × 高活躍度", status = "warning", width = 12, solidHeader = TRUE,
                          generate_grid_content("中", "高", df_for_grid, current_stage))),
          column(4, bs4Card(title = "中價值 × 中活躍度", status = "warning", width = 12, solidHeader = TRUE,
                          generate_grid_content("中", "中", df_for_grid, current_stage))),
          column(4, bs4Card(title = "中價值 × 低活躍度", status = "warning", width = 12, solidHeader = TRUE,
                          generate_grid_content("中", "低", df_for_grid, current_stage)))
        ),

        # 低價值客戶
        fluidRow(
          column(4, bs4Card(title = "低價值 × 高活躍度", status = "danger", width = 12, solidHeader = TRUE,
                          generate_grid_content("低", "高", df_for_grid, current_stage))),
          column(4, bs4Card(title = "低價值 × 中活躍度", status = "danger", width = 12, solidHeader = TRUE,
                          generate_grid_content("低", "中", df_for_grid, current_stage))),
          column(4, bs4Card(title = "低價值 × 低活躍度", status = "danger", width = 12, solidHeader = TRUE,
                          generate_grid_content("低", "低", df_for_grid, current_stage)))
        )
      )
    })

    # 返回處理後的客戶資料（reactive）
    return(reactive({
      req(values$dna_results)
      values$dna_results$data_by_customer
    }))
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