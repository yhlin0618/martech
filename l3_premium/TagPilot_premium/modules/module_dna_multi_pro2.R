# Multi-File DNA Analysis Module with ROS Analysis
# Supports Amazon sales data and general transaction files

library(shiny)
library(shinyjs)
library(dplyr)
library(DT)
library(plotly)
library(readxl)
library(later)
library(ggplot2)

# Helper functions
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
  if (exists("fn_analysis_dna")) {
    analysis_dna <- fn_analysis_dna
  }
}

# Load strategy data function
load_strategy_data <- function() {
  tryCatch({
    mapping_file <- "database/mapping.csv"
    strategy_file <- "database/strategy.csv"
    
    if (file.exists(mapping_file) && file.exists(strategy_file)) {
      # 讀取mapping.csv並標準化欄位名稱
      mapping <- read.csv(mapping_file, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
      names(mapping)[1] <- "segment"  # 靜態區隔 (39)
      names(mapping)[2] <- "ros_baseline"  # ROS Baseline
      names(mapping)[3] <- "scripts"  # 腳本編號 (Primary／Secondary)
      names(mapping)[4] <- "example"  # 主要腳本範例
      names(mapping)[5] <- "tempo"  # Tempo T
      names(mapping)[6] <- "value"  # Value V
      names(mapping)[7] <- "contact_times"  # 信件接觸顧客的次數
      names(mapping)[8] <- "discount"  # 折扣百分比
      names(mapping)[9] <- "kpi"  # KPI 追蹤
      
      # 讀取strategy.csv並標準化欄位名稱
      strategy <- read.csv(strategy_file, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
      names(strategy)[1] <- "code"  # 編號
      names(strategy)[2] <- "baseline"  # 歸屬 Baseline
      names(strategy)[3] <- "core_action"  # 行銷腳本核心
      names(strategy)[4] <- "channel"  # 主要觸點 / 渠道
      names(strategy)[5] <- "main_kpi"  # 主要 KPI
      
      cat("✅ 策略資料載入成功\n")
      cat("   Mapping 記錄:", nrow(mapping), "筆\n")
      cat("   Strategy 記錄:", nrow(strategy), "筆\n")
      
      return(list(
        mapping = mapping,
        strategy = strategy
      ))
    } else {
      cat("❌ 找不到策略檔案:", mapping_file, "或", strategy_file, "\n")
      return(NULL)
    }
  }, error = function(e) {
    cat("❌ 無法載入策略資料:", e$message, "\n")
    return(NULL)
  })
}

# Filter customers by ROS baseline requirement
filter_customers_by_ros_baseline <- function(customers, required_baseline) {
  if (is.null(customers) || nrow(customers) == 0 || is.null(required_baseline)) {
    return(customers)
  }
  
  required_baseline_normalized <- gsub("S‑", "S-", required_baseline)
  matched_customers <- customers[FALSE, ]
  
  for (i in 1:nrow(customers)) {
    customer_ros <- customers$ros_segment[i]
    
    if (customer_ros == required_baseline_normalized) {
      matched_customers <- rbind(matched_customers, customers[i, ])
      next
    }
    
    if (grepl("^R \\+ S-", required_baseline_normalized)) {
      if (customer_ros == required_baseline_normalized) {
        matched_customers <- rbind(matched_customers, customers[i, ])
      }
    } else if (grepl("S-.*\\+ O$", required_baseline_normalized)) {
      stability_level <- gsub(".*?(S-[A-Za-z]+).*", "\\1", required_baseline_normalized)
      if (customer_ros == "O" || 
          grepl(paste0("O.*", stability_level), customer_ros) ||
          grepl(paste0("o.*", stability_level), customer_ros)) {
        matched_customers <- rbind(matched_customers, customers[i, ])
      }
    } else if (grepl("S-.*\\+ R$", required_baseline_normalized)) {
      stability_level <- gsub(".*?(S-[A-Za-z]+).*", "\\1", required_baseline_normalized)
      if (grepl(paste0("R.*", stability_level), customer_ros) ||
          grepl(paste0("r.*", stability_level), customer_ros)) {
        matched_customers <- rbind(matched_customers, customers[i, ])
      }
    }
  }
  
  return(matched_customers)
}

# Get strategy details by segment code
get_strategy_by_segment <- function(segment_code, strategy_data) {
  if (is.null(strategy_data$mapping) || is.null(strategy_data$strategy)) {
    cat("❌ 策略資料為空\n")
    return(NULL)
  }
  
  # 查找匹配的區段（尋找以segment_code開頭的記錄）
  segment_matches <- grep(paste0("^", segment_code), strategy_data$mapping$segment, value = FALSE)
  
  if (length(segment_matches) == 0) {
    cat("❌ 找不到區段:", segment_code, "\n")
    return(NULL)
  }
  
  segment_match <- strategy_data$mapping[segment_matches[1], ]
  cat("✅ 找到區段:", segment_match$segment[1], "\n")
  
  # 分割腳本編號 (Primary／Secondary)
  scripts_text <- segment_match$scripts[1]
  scripts <- strsplit(scripts_text, "／")[[1]]
  primary_code <- trimws(scripts[1])
  secondary_code <- if(length(scripts) > 1) trimws(scripts[2]) else ""
  
  cat("   主要腳本:", primary_code, "\n")
  cat("   次要腳本:", secondary_code, "\n")
  
  # 查找主要策略
  primary_strategy <- strategy_data$strategy[strategy_data$strategy$code == primary_code, ]
  if (nrow(primary_strategy) == 0) {
    cat("❌ 找不到主要策略:", primary_code, "\n")
    primary_strategy <- NULL
  } else {
    cat("✅ 找到主要策略:", primary_strategy$core_action[1], "\n")
  }
  
  # 查找次要策略
  secondary_strategy <- NULL
  if (secondary_code != "") {
    secondary_strategy <- strategy_data$strategy[strategy_data$strategy$code == secondary_code, ]
    if (nrow(secondary_strategy) == 0) {
      cat("❌ 找不到次要策略:", secondary_code, "\n")
      secondary_strategy <- NULL
    } else {
      cat("✅ 找到次要策略:", secondary_strategy$core_action[1], "\n")
    }
  }
  
  return(list(
    primary = primary_strategy,
    secondary = secondary_strategy,
    segment_info = segment_match,
    primary_code = primary_code,
    secondary_code = secondary_code
  ))
}

# UI Function
dnaMultiPro2ModuleUI <- function(id) {
  ns <- NS(id)
  
  div(
    # 標題區域
    div(
      style = "padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px; margin-bottom: 20px;",
      h3("🔬 Value × Activity × Lifecycle × ROS 分析", 
         style = "text-align: center; margin: 0; color: white; font-weight: bold; text-shadow: 1px 1px 2px rgba(0,0,0,0.3);")
    ),
    
    # 狀態顯示
    wellPanel(
      style = "background-color: #ffffff; border: 1px solid #dee2e6; border-radius: 8px; padding: 15px; margin-bottom: 20px;",
      h4("📊 處理狀態", style = "color: #495057; margin-bottom: 15px;"),
      div(style = "background-color: #f8f9fa; padding: 10px; border-radius: 6px; border-left: 4px solid #28a745;",
        verbatimTextOutput(ns("status"))
      )
    ),
    
    # ROS 參數設定
    conditionalPanel(
      condition = paste0("output['", ns("has_uploaded_data"), "'] == true"),
      wellPanel(
        style = "background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 8px; padding: 20px;",
        h4("⚙️ ROS 分析設定", style = "color: #495057; margin-bottom: 20px;"),
        
        # 第一行：基本參數
        fluidRow(
          column(3, 
            div(style = "margin-bottom: 15px;",
              numericInput(ns("min_transactions"), "最少交易次數", 
                         value = 2, min = 1, width = "100%")
            )
          ),
          column(3,
            div(style = "margin-bottom: 15px;",
              numericInput(ns("risk_threshold"), "Risk 閾值 (流失機率)", 
                         value = 0.6, min = 0, max = 1, step = 0.1, width = "100%")
            )
          ),
          column(3,
            div(style = "margin-bottom: 15px;",
              numericInput(ns("opportunity_threshold"), "Opportunity 閾值 (天數)", 
                         value = 7, min = 1, step = 1, width = "100%")
            )
          ),
          column(3,
            div(style = "margin-top: 25px;",
              actionButton(ns("analyze_uploaded"), "🚀 開始分析", 
                         class = "btn-success btn-lg",
                         style = "width: 100%; font-weight: bold;")
            )
          )
        ),
        
        br(),
        
        # 第二行：Stability 參數
        fluidRow(
          column(3,
            div(style = "margin-bottom: 10px;",
              numericInput(ns("stability_low"), "Stability Low 閾值", 
                         value = 0.3, min = 0, max = 1, step = 0.1, width = "100%")
            )
          ),
          column(3,
            div(style = "margin-bottom: 10px;",
              numericInput(ns("stability_high"), "Stability High 閾值", 
                         value = 0.7, min = 0, max = 1, step = 0.1, width = "100%")
            )
          ),
          column(6,
            div(style = "margin-top: 20px; padding: 10px; background-color: #e3f2fd; border-radius: 6px; border-left: 4px solid #2196f3;",
              tags$b("Stability 分級說明：", style = "color: #1976d2;"),
              br(),
              tags$span("Low < ", style = "color: #666;"),
              tags$code("低閾值", style = "background-color: #fff3e0; padding: 2px 6px; border-radius: 3px;"),
              tags$span(" ≤ Medium < ", style = "color: #666;"),
              tags$code("高閾值", style = "background-color: #fff3e0; padding: 2px 6px; border-radius: 3px;"),
              tags$span(" ≤ High", style = "color: #666;")
            )
          )
        )
      )
    ),
    
    # Tab設定
    conditionalPanel(
      condition = paste0("output['", ns("show_results"), "'] == true"),
      div(
        style = "margin-top: 20px; padding: 20px; background-color: #ffffff; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1);",
        tabsetPanel(
          id = ns("analysis_tabs"),
          type = "tabs",
          
          # 九宮格分析 Tab
          tabPanel(
            "九宮格分析",
            br(),
            fluidRow(
              column(12,
                bs4Card(
                  title = "生命週期階段選擇",
                  status = "primary",
                  width = 12,
                  solidHeader = TRUE,
                  fluidRow(
                    column(12,
                      radioButtons(ns("lifecycle_stage"), "",
                                 choices = list(
                                   "新客 (Newbie)" = "newbie",
                                   "主力客 (Active)" = "active", 
                                   "睡眠客 (Sleepy)" = "sleepy",
                                   "半睡客 (Half Sleepy)" = "half_sleepy",
                                   "沉睡客 (Dormant)" = "dormant"
                                 ),
                                 selected = "newbie",
                                 inline = TRUE)
                    )
                  )
                )
              )
            ),
            br(),
            fluidRow(
              column(12,
                bs4Card(
                  title = "價值 × 活躍度分析",
                  status = "info", 
                  width = 12,
                  solidHeader = TRUE,
                  uiOutput(ns("nine_grid_output"))
                )
              )
            )
          ),
          
          # ROS 分析 Tab
          tabPanel(
            "ROS 分析",
            br(),
            fluidRow(
              column(6,
                bs4Card(
                  title = "ROS 分佈圖表",
                  status = "warning",
                  width = 12,
                  solidHeader = TRUE,
                  plotOutput(ns("ros_distribution_plot"))
                )
              ),
              column(6,
                bs4Card(
                  title = "ROS 統計摘要",
                  status = "success",
                  width = 12, 
                  solidHeader = TRUE,
                  br(),
                  h4("ROS 詳細統計"),
                  DT::dataTableOutput(ns("ros_summary_table"))
                )
              )
            )
          ),
          
          # 客戶資料檢查 Tab
          tabPanel(
            "客戶資料檢查",
            br(),
            fluidRow(
              column(12,
                bs4Card(
                  title = "客戶 DNA 資料表",
                  status = "warning",
                  width = 12,
                  solidHeader = TRUE,
                  
                  # 資料篩選控制
                  fluidRow(
                    column(2,
                      selectInput(ns("filter_static_segment"), "靜態區隔:",
                                choices = c("全部" = "all"),
                                selected = "all")
                    ),
                    column(2,
                      selectInput(ns("filter_lifecycle"), "生命週期階段:",
                                choices = c("全部" = "all", "新客" = "newbie", "主力客" = "active", 
                                          "睡眠客" = "sleepy", "半睡客" = "half_sleepy", "沉睡客" = "dormant"),
                                selected = "all")
                    ),
                    column(2,
                      selectInput(ns("filter_ros_segment"), "ROS 分類:",
                                choices = c("全部" = "all"),
                                selected = "all")
                    ),
                    column(2,
                      numericInput(ns("min_m_value"), "最小 M 值:", value = 0, min = 0, step = 1)
                    ),
                    column(2,
                      numericInput(ns("min_f_value"), "最小 F 值:", value = 0, min = 0, step = 1)
                    ),
                    column(2,
                      downloadButton(ns("download_customer_data"), "下載資料", 
                                   class = "btn-primary", style = "margin-top: 25px;")
                    )
                  ),
                  
                  br(),
                  DT::dataTableOutput(ns("customer_data_table"))
                )
              )
            )
          )
        )
      )
    )
  )
}

# Server Function
dnaMultiPro2ModuleServer <- function(id, con, user_info, uploaded_dna_data = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values
    values <- reactiveValues(
      combined_data = NULL,
      dna_results = NULL,
      ros_data = NULL,
      status_text = "⏳ 等待開始分析..."
    )
    
    # ROS 分析函數
    calculate_ros_metrics <- function(dna_data, risk_threshold, opportunity_threshold, stability_low, stability_high) {
      # 先檢查並新增缺失的欄位
      if (!"nrec_prob" %in% names(dna_data)) {
        dna_data$nrec_prob <- 0
      }
      if (!"ipt_mean" %in% names(dna_data) && !"ipt" %in% names(dna_data)) {
        dna_data$ipt_mean <- 30
      }
      if (!"cri" %in% names(dna_data)) {
        dna_data$cri <- 0.5
      }
      
      dna_data %>%
        mutate(
          # Risk 評分 (基於流失機率)
          risk_score = ifelse(is.na(nrec_prob), 0, nrec_prob),
          risk_flag = ifelse(risk_score >= risk_threshold, 1, 0),
          
          # Opportunity 評分 (基於預期購買間隔)
          predicted_tnp = case_when(
            !is.na(ipt_mean) ~ ipt_mean,
            !is.na(ipt) ~ ipt,
            TRUE ~ 30
          ),
          opportunity_flag = ifelse(predicted_tnp <= opportunity_threshold, 1, 0),
          
          # Stability 評分 (基於規律性指數)
          stability_score = ifelse(is.na(cri), 0.5, cri),
          stability_level = case_when(
            stability_score >= stability_high ~ "S-High",   # 穩定度 ≥ 0.7
            stability_score > stability_low ~ "S-Medium",   # 0.3 < 穩定度 < 0.7
            TRUE ~ "S-Low"                                  # 穩定度 ≤ 0.3
          ),
          
          # ROS 綜合分類
          ros_segment = case_when(
            # Baseline 組合：R=1 且 S=Low
            risk_flag == 1 & stability_level == "S-Low" ~ paste("R +", stability_level),
            # Baseline 組合：只有 O=1
            risk_flag == 0 & opportunity_flag == 1 & stability_level != "S-Low" ~ "O",
            risk_flag == 0 & opportunity_flag == 1 & stability_level == "S-Low" ~ paste("O +", stability_level),
            # 一般組合
            TRUE ~ paste0(
              ifelse(risk_flag == 1, "R", "r"),
              ifelse(opportunity_flag == 1, "O", "o"), 
              " + ", stability_level
            )
          ),
          
          # ROS 描述
          ros_description = paste0(
            ifelse(risk_flag == 1, "高風險", "低風險"), " | ",
            ifelse(opportunity_flag == 1, "高機會", "低機會"), " | ",
            case_when(
              stability_level == "S-High" ~ "高穩定",
              stability_level == "S-Medium" ~ "中穩定", 
              TRUE ~ "低穩定"
            )
          ),
          
          # 靜態區隔 (Static Segment)
          static_segment = paste0(
            case_when(
              value_level == "高" ~ "A",
              value_level == "中" ~ "B",
              TRUE ~ "C"
            ),
            case_when(
              activity_level == "高" ~ "1",
              activity_level == "中" ~ "2", 
              TRUE ~ "3"
            ),
            case_when(
              lifecycle_stage == "newbie" ~ "N",
              lifecycle_stage == "active" ~ "C",
              lifecycle_stage == "sleepy" ~ "D",
              lifecycle_stage == "half_sleepy" ~ "H",
              TRUE ~ "S"  # dormant
            )
          ),
          
          # 生命週期中文描述
          lifecycle_stage_zh = case_when(
            lifecycle_stage == "newbie" ~ "新客",
            lifecycle_stage == "active" ~ "主力客",
            lifecycle_stage == "sleepy" ~ "睡眠客",
            lifecycle_stage == "half_sleepy" ~ "半睡客",
            lifecycle_stage == "dormant" ~ "沉睡客",
            TRUE ~ lifecycle_stage
          )
        )
    }
    
    # DNA 分析函數 (與原版相似，但加入ROS分析)
    analyze_data <- function(data, min_transactions, delta_factor, risk_threshold, opportunity_threshold, stability_low, stability_high) {
      tryCatch({
        values$status_text <- "📊 準備分析資料..."
        
        # Filter by minimum transactions
        customer_counts <- data %>%
          group_by(customer_id) %>%
          summarise(n_transactions = n(), .groups = "drop")
        
        valid_customers <- customer_counts %>%
          filter(n_transactions >= min_transactions) %>%
          pull(customer_id)
        
        if (length(valid_customers) == 0) {
          values$status_text <- "❌ 沒有符合最少交易次數的客戶"
          return(NULL)
        }
        
        filtered_data <- data %>%
          filter(customer_id %in% valid_customers)
        
        values$status_text <- "🧬 正在進行 DNA 分析..."
        
        # 確保platform_id欄位存在
        if (!"platform_id" %in% names(filtered_data)) {
          filtered_data$platform_id <- "upload"
        }
        
        # Prepare data for DNA analysis (使用原始模組的相同邏輯)
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
        
        # 執行 DNA 分析 (使用現有函數)
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
            
            results
          }, error = function(e) {
            stop(paste("DNA分析錯誤:", e$message))
          })
          
          # 處理DNA分析結果
          dna_result <- dna_results$data_by_customer %>%
            mutate(
              # 確保必要欄位為數值型且處理 NA 值
              r_value = as.numeric(r_value),
              f_value = as.numeric(f_value),
              m_value = as.numeric(m_value),
              
              # 檢查 first_purchase 欄位是否存在
              first_purchase_clean = if("first_purchase" %in% names(.)) {
                as.POSIXct(first_purchase)
              } else if("first_order_date" %in% names(.)) {
                as.POSIXct(first_order_date)
              } else {
                Sys.time() - 365*24*3600  # 預設為一年前
              },
              
              # 計算客戶年齡（天數）
              customer_age_days = as.numeric(difftime(Sys.time(), first_purchase_clean, units = "days")),
              
              # 根據 r_value 計算生命週期
              lifecycle_stage = case_when(
                is.na(r_value) | is.na(customer_age_days) ~ "unknown",
                customer_age_days <= 30 ~ "newbie",
                r_value <= 7 ~ "active",
                r_value <= 14 ~ "sleepy",
                r_value <= 21 ~ "half_sleepy",
                TRUE ~ "dormant"
              ),
              
              # 使用分位數進行分類
              value_level = case_when(
                is.na(m_value) ~ "未知",
                m_value >= quantile(m_value, 0.8, na.rm = TRUE) ~ "高",
                m_value >= quantile(m_value, 0.2, na.rm = TRUE) ~ "中",
                TRUE ~ "低"
              ),
              activity_level = case_when(
                is.na(f_value) ~ "未知",
                f_value >= quantile(f_value, 0.8, na.rm = TRUE) ~ "高",
                f_value >= quantile(f_value, 0.2, na.rm = TRUE) ~ "中",
                TRUE ~ "低"
              )
            ) %>%
            # 過濾掉未知類型的資料
            filter(lifecycle_stage != "unknown", value_level != "未知", activity_level != "未知")
            
        } else {
          # 基本DNA分析作為fallback (使用正確的欄位名稱)
          dna_result <- sales_by_customer %>%
            mutate(
              # ✅ 需求 #2: 使用 P20/P80 (80/20法則) 統一分群標準
              value_level = case_when(
                m_value >= quantile(m_value, 0.80, na.rm = TRUE) ~ "高",
                m_value >= quantile(m_value, 0.20, na.rm = TRUE) ~ "中",
                TRUE ~ "低"
              ),
              activity_level = case_when(
                f_value >= quantile(f_value, 0.80, na.rm = TRUE) ~ "高",
                f_value >= quantile(f_value, 0.20, na.rm = TRUE) ~ "中",
                TRUE ~ "低"
              ),
              lifecycle_stage = case_when(
                r_value <= 30 ~ "active",
                r_value <= 90 ~ "sleepy",
                r_value <= 180 ~ "half_sleepy",
                TRUE ~ "dormant"
              )
            )
        }
        
        values$status_text <- "🎯 計算 ROS 指標..."
        
        # 計算 ROS 指標
        ros_data <- calculate_ros_metrics(dna_result, risk_threshold, opportunity_threshold, stability_low, stability_high)
        
        values$dna_results <- dna_result
        values$ros_data <- ros_data
        values$status_text <- "✅ DNA 與 ROS 分析完成！"
        
        return(ros_data)
      }, error = function(e) {
        values$status_text <- paste("❌ 分析錯誤:", e$message)
        return(NULL)
      })
    }
    
    # 偵測並載入上傳的資料
    observe({
      if (!is.null(uploaded_dna_data)) {
        if (is.reactive(uploaded_dna_data)) {
          data <- uploaded_dna_data()
        } else {
          data <- uploaded_dna_data
        }
        
        if (!is.null(data) && nrow(data) > 0) {
          values$combined_data <- data
          values$status_text <- paste("📁 已載入", nrow(data), "筆資料，準備進行分析")
        }
      }
    })
    
    # 檢查是否有上傳資料
    output$has_uploaded_data <- reactive({
      !is.null(values$combined_data) && nrow(values$combined_data) > 0
    })
    outputOptions(output, "has_uploaded_data", suspendWhenHidden = FALSE)
    
    # 顯示分析結果
    output$show_results <- reactive({
      !is.null(values$ros_data)
    })
    outputOptions(output, "show_results", suspendWhenHidden = FALSE)
    
    # 狀態輸出
    output$status <- renderText({
      values$status_text
    })
    
    # 分析按鈕事件
    observeEvent(input$analyze_uploaded, {
      req(values$combined_data)
      
      min_trans <- ifelse(is.null(input$min_transactions), 2, input$min_transactions)
      delta_val <- 0.1  # 固定時間折扣因子為0.1
      risk_thresh <- ifelse(is.null(input$risk_threshold), 0.6, input$risk_threshold)
      opp_thresh <- ifelse(is.null(input$opportunity_threshold), 7, input$opportunity_threshold)
      stab_low <- ifelse(is.null(input$stability_low), 0.3, input$stability_low)
      stab_high <- ifelse(is.null(input$stability_high), 0.7, input$stability_high)
      
      analyze_data(values$combined_data, min_trans, delta_val, risk_thresh, opp_thresh, stab_low, stab_high)
    })
    
    # 更新篩選器選項
    observe({
      if (!is.null(values$ros_data)) {
        # 更新靜態區隔選項
        static_segments <- unique(values$ros_data$static_segment)
        static_segments <- static_segments[!is.na(static_segments)]
        static_segments <- sort(static_segments)  # 排序
        static_choices <- c("全部" = "all")
        names(static_choices) <- c("全部")
        for (segment in static_segments) {
          static_choices <- c(static_choices, setNames(segment, segment))
        }
        updateSelectInput(session, "filter_static_segment", choices = static_choices)
        
        # 更新 ROS 分類選項
        ros_choices <- c("全部" = "all", unique(values$ros_data$ros_segment))
        updateSelectInput(session, "filter_ros_segment", choices = ros_choices)
      }
    })
    
    # 下載客戶資料
    output$download_customer_data <- downloadHandler(
      filename = function() {
        paste("customer_data_", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        req(values$ros_data)
        
        # 使用與表格相同的篩選邏輯
        filtered_data <- values$ros_data
        
        # 靜態區隔篩選
        if (!is.null(input$filter_static_segment) && input$filter_static_segment != "all") {
          filtered_data <- filtered_data %>%
            filter(static_segment == input$filter_static_segment)
        }
        
        # 生命週期篩選
        if (!is.null(input$filter_lifecycle) && input$filter_lifecycle != "all") {
          filtered_data <- filtered_data %>%
            filter(lifecycle_stage == input$filter_lifecycle)
        }
        
        # ROS 分類篩選
        if (!is.null(input$filter_ros_segment) && input$filter_ros_segment != "all") {
          filtered_data <- filtered_data %>%
            filter(ros_segment == input$filter_ros_segment)
        }
        
        # M 值篩選
        if (!is.null(input$min_m_value)) {
          filtered_data <- filtered_data %>%
            filter(m_value >= input$min_m_value)
        }
        
        # F 值篩選
        if (!is.null(input$min_f_value)) {
          filtered_data <- filtered_data %>%
            filter(f_value >= input$min_f_value)
        }
        
        # 選擇要下載的欄位（保持原始欄位名稱）
        download_data <- filtered_data %>%
          select(
            customer_id,
            static_segment,
            lifecycle_stage,
            lifecycle_stage_zh,
            value_level,
            activity_level,
            ros_segment,
            ros_description,
            m_value,
            f_value,
            r_value,
            risk_score,
            predicted_tnp,
            stability_score,
            total_spent,
            times
          )
        
        write.csv(download_data, file, row.names = FALSE, fileEncoding = "UTF-8")
      }
    )
    
    # 計算九宮格分析結果
    nine_grid_data <- reactive({
      req(values$dna_results, input$lifecycle_stage)
      
      filtered_results <- values$ros_data %>%
        filter(lifecycle_stage == input$lifecycle_stage)
      
      if (nrow(filtered_results) == 0) {
        return(NULL)
      }
      
      return(filtered_results)
    })
    
    # 載入策略資料
    strategy_data <- reactive({
      load_strategy_data()
    })
    
    # 生成九宮格內容（根據區隔ROS Baseline篩選客戶）
    generate_grid_content <- function(value_level, activity_level, df, lifecycle_stage, strategy_data) {
      if (is.null(df)) {
        return(HTML('<div style="text-align: center; padding: 15px;">無此生命週期階段的客戶</div>'))
      }
      
      # 根據九宮格位置和生命週期定義區段代碼
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
      
      # 獲取該區段對應的 ROS Baseline 要求
      required_ros_baseline <- NULL
      if (!is.null(strategy_data$mapping)) {
        segment_match <- strategy_data$mapping[grep(paste0("^", grid_position), strategy_data$mapping$segment), ]
        if (nrow(segment_match) > 0) {
          required_ros_baseline <- segment_match$ros_baseline[1]
        }
      }
      
      # 取得該區段的所有客戶
      all_customers <- df[df$value_level == value_level & df$activity_level == activity_level, ]
      
      # 根據 ROS Baseline 篩選客戶
      filtered_customers <- all_customers
      if (!is.null(required_ros_baseline) && nrow(all_customers) > 0) {
        filtered_customers <- filter_customers_by_ros_baseline(all_customers, required_ros_baseline)
      }
      
      count_all <- nrow(all_customers)
      count_filtered <- nrow(filtered_customers)
      
      if (count_all == 0) {
        return(HTML('<div style="text-align: center; padding: 15px;">無此類型客戶</div>'))
      }
      
      # 計算篩選後客戶的平均值
      if (count_filtered > 0) {
        avg_m <- round(mean(filtered_customers$m_value, na.rm = TRUE), 2)
        avg_f <- round(mean(filtered_customers$f_value, na.rm = TRUE), 2)
      } else {
        avg_m <- avg_f <- 0
      }
      
      # 獲取策略信息
      strategy_info <- NULL
      if (!is.null(strategy_data)) {
        cat("🔍 獲取區段策略:", grid_position, "\n")
        strategy_info <- get_strategy_by_segment(grid_position, strategy_data)
      } else {
        cat("❌ 策略資料未載入\n")
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
      strategy_content <- ""
      if (!is.null(strategy_info)) {
        primary_strategy <- ""
        secondary_strategy <- ""
        
        # 顯示主要策略 (大字粗體)
        if (!is.null(strategy_info$primary) && nrow(strategy_info$primary) > 0) {
          primary_strategy <- sprintf(
            '<div style="margin: 15px 0; padding: 12px; background: #f0f8ff; border-radius: 6px; border-left: 4px solid #2196f3; box-shadow: 0 2px 4px rgba(0,0,0,0.1);"><strong style="font-size: 20px; color: #1976d2;">🎯 主要策略 (%s)</strong><br><span style="font-size: 18px; font-weight: bold; color: #333; line-height: 1.4;">%s</span><br><div style="margin-top: 10px; padding-top: 8px; border-top: 1px solid #e3f2fd;"><small style="color: #666; font-size: 13px;"><strong>💬 渠道:</strong> %s</small><br><small style="color: #666; font-size: 13px;"><strong>📊 KPI:</strong> %s</small></div></div>',
            strategy_info$primary_code,
            strategy_info$primary$core_action[1],
            strategy_info$primary$channel[1],
            strategy_info$primary$main_kpi[1]
          )
        }
        
        # 顯示次要策略 (小字灰色)
        if (!is.null(strategy_info$secondary) && nrow(strategy_info$secondary) > 0) {
          secondary_strategy <- sprintf(
            '<div style="margin: 10px 0; padding: 8px; background: #f8f9fa; border-radius: 4px; border-left: 3px solid #adb5bd;"><strong style="font-size: 14px; color: #6c757d;">📋 次要策略 (%s)</strong><br><span style="font-size: 13px; color: #6c757d; line-height: 1.3;">%s</span><br><div style="margin-top: 6px;"><small style="color: #adb5bd; font-size: 11px;"><strong>渠道:</strong> %s</small> | <small style="color: #adb5bd; font-size: 11px;"><strong>KPI:</strong> %s</small></div></div>',
            strategy_info$secondary_code,
            strategy_info$secondary$core_action[1],
            strategy_info$secondary$channel[1],
            strategy_info$secondary$main_kpi[1]
          )
        }
        
        strategy_content <- paste0(primary_strategy, secondary_strategy)
        
        # 加入區段信息
        if (!is.null(strategy_info$segment_info) && !is.null(strategy_info$segment_info$discount)) {
          segment_info <- sprintf(
            '<div style="margin: 10px 0; padding: 10px; background: linear-gradient(135deg, #fefefe 0%%, #f8f9fa 100%%); border: 1px solid #dee2e6; border-radius: 6px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);"><div style="font-weight: bold; color: #495057; margin-bottom: 6px; font-size: 14px;">📈 區段參數</div><div style="display: flex; gap: 15px; flex-wrap: wrap;"><span style="color: #dc3545; font-weight: bold; font-size: 13px;">💰 折扣: %s%%</span><span style="color: #007bff; font-weight: bold; font-size: 13px;">📧 接觸: %s次</span><span style="color: #28a745; font-weight: bold; font-size: 13px;">🎯 KPI: %s</span></div></div>',
            strategy_info$segment_info$discount[1],
            strategy_info$segment_info$contact_times[1],
            strategy_info$segment_info$kpi[1]
          )
          strategy_content <- paste0(strategy_content, segment_info)
        }
        
        cat("✅ 策略內容生成完成 -", grid_position, "\n")
      } else {
        strategy_content <- '<div style="margin: 15px 0; padding: 12px; background: #fff3cd; border-radius: 6px; border-left: 4px solid #ffc107; color: #856404;"><strong>⚠️ 提醒</strong><br>此區隔暫無對應策略資料</div>'
        cat("❌ 無策略資料 -", grid_position, "\n")
      }
      
      # ROS篩選狀態顯示
      ros_filter_status <- ""
      if (!is.null(required_ros_baseline)) {
        ros_filter_status <- sprintf(
          '<div style="margin: 10px 0; padding: 6px; background: #e3f2fd; border-radius: 4px;"><small><strong>ROS 篩選條件:</strong> %s<br><strong>符合條件客戶:</strong> %d / %d</small></div>',
          required_ros_baseline,
          count_filtered,
          count_all
        )
      }
      
      # 生成完整內容
      HTML(sprintf('
        <div style="text-align: left; padding: 15px; border-left: 4px solid %s;">
          <div style="text-align: center; font-size: 18px; font-weight: bold; color: #666; margin-bottom: 5px;">
            %s
          </div>
          <div style="text-align: center; font-size: 24px; font-weight: bold; margin: 15px 0; color: %s;">
            %d 位符合客戶
          </div>
          <div style="text-align: center; color: #666; margin: 10px 0;">
            平均M值: %.2f | 平均F值: %.2f
          </div>
          %s
          %s
        </div>
      ', stage_color, grid_position, ifelse(count_filtered > 0, "#2e7d32", "#d32f2f"), count_filtered, avg_m, avg_f, ros_filter_status, strategy_content))
    }
    
    # 九宮格輸出
    output$nine_grid_output <- renderUI({
      req(nine_grid_data())
      
      df <- nine_grid_data()
      lifecycle <- input$lifecycle_stage
      strategy_data_val <- strategy_data()
      
      # 創建九宮格
      grid_structure <- list(
        list("高", "高"), list("高", "中"), list("高", "低"),
        list("中", "高"), list("中", "中"), list("中", "低"),
        list("低", "高"), list("低", "中"), list("低", "低")
      )
      
      # 創建3x3網格
      fluidRow(
        lapply(1:3, function(row) {
          column(4,
            fluidRow(
              lapply(1:3, function(col) {
                index <- (row - 1) * 3 + col
                value_level <- grid_structure[[index]][[1]]
                activity_level <- grid_structure[[index]][[2]]
                
                column(12,
                  wellPanel(
                    style = "min-height: 200px; margin-bottom: 10px;",
                    generate_grid_content(value_level, activity_level, df, lifecycle, strategy_data_val)
                  )
                )
              })
            )
          )
        })
      )
    })
    
    # ROS 分佈圖表
    output$ros_distribution_plot <- renderPlot({
      req(values$ros_data)
      
      ros_summary <- values$ros_data %>%
        count(ros_segment) %>%
        arrange(desc(n))
      
      ggplot(ros_summary, aes(x = reorder(ros_segment, n), y = n, fill = ros_segment)) +
        geom_bar(stat = "identity") +
        coord_flip() +
        labs(title = "ROS 分類分佈", x = "ROS 分類", y = "客戶數量") +
        theme_minimal() +
        theme(legend.position = "none") +
        scale_fill_viridis_d()
    })
    
    # ROS 統計表
    output$ros_summary_table <- DT::renderDataTable({
      req(values$ros_data)
      
      summary_data <- values$ros_data %>%
        group_by(ros_segment, ros_description) %>%
        summarise(
          客戶數 = n(),
          平均M值 = round(mean(m_value, na.rm = TRUE), 2),
          平均F值 = round(mean(f_value, na.rm = TRUE), 1),
          平均風險分數 = round(mean(risk_score, na.rm = TRUE), 3),
          平均穩定分數 = round(mean(stability_score, na.rm = TRUE), 3),
          .groups = "drop"
        ) %>%
        arrange(desc(客戶數))
      
      DT::datatable(
        summary_data,
        options = list(
          pageLength = 15,
          scrollX = TRUE
        ),
        rownames = FALSE
      )
    })
    
    # 客戶資料表
    output$customer_data_table <- DT::renderDataTable({
      req(values$ros_data)
      
      filtered_data <- values$ros_data
      
      # 靜態區隔篩選
      if (!is.null(input$filter_static_segment) && input$filter_static_segment != "all") {
        filtered_data <- filtered_data %>%
          filter(static_segment == input$filter_static_segment)
      }
      
      # 生命週期篩選
      if (!is.null(input$filter_lifecycle) && input$filter_lifecycle != "all") {
        filtered_data <- filtered_data %>%
          filter(lifecycle_stage == input$filter_lifecycle)
      }
      
      # ROS 分類篩選
      if (!is.null(input$filter_ros_segment) && input$filter_ros_segment != "all") {
        filtered_data <- filtered_data %>%
          filter(ros_segment == input$filter_ros_segment)
      }
      
      # M 值篩選
      if (!is.null(input$min_m_value)) {
        filtered_data <- filtered_data %>%
          filter(m_value >= input$min_m_value)
      }
      
      # F 值篩選
      if (!is.null(input$min_f_value)) {
        filtered_data <- filtered_data %>%
          filter(f_value >= input$min_f_value)
      }
      
      # 選擇要顯示的欄位
      display_data <- filtered_data %>%
        select(
          客戶ID = customer_id,
          靜態區隔 = static_segment,
          生命週期 = lifecycle_stage_zh,
          原生命週期 = lifecycle_stage,
          價值等級 = value_level,
          活躍等級 = activity_level,
          ROS分類 = ros_segment,
          ROS描述 = ros_description,
          M值 = m_value,
          F值 = f_value,
          R值 = r_value,
          風險分數 = risk_score,
          機會天數 = predicted_tnp,
          穩定分數 = stability_score,
          總消費 = total_spent,
          交易次數 = times
        ) %>%
        mutate(
          M值 = round(M值, 2),
          F值 = round(F值, 0),
          R值 = round(R值, 1),
          風險分數 = round(風險分數, 3),
          機會天數 = round(機會天數, 1),
          穩定分數 = round(穩定分數, 3),
          總消費 = round(總消費, 2)
        )
      
      DT::datatable(
        display_data,
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          searching = TRUE,
          order = list(list(9, "desc")),  # 按 M 值降序排列（調整為第9欄）
          columnDefs = list(
            list(width = '80px', targets = c(1)),  # 靜態區隔欄位寬度
            list(width = '100px', targets = c(2)),  # 生命週期欄位寬度
            list(width = '150px', targets = c(7, 8))  # ROS分類和描述欄位寬度
          )
        ),
        rownames = FALSE
      ) %>%
        DT::formatStyle(
          "靜態區隔",
          backgroundColor = DT::styleEqual(
            unique(display_data$靜態區隔),
            rainbow(length(unique(display_data$靜態區隔)), alpha = 0.2)
          ),
          fontWeight = "bold"
        ) %>%
        DT::formatStyle(
          "生命週期",
          backgroundColor = DT::styleEqual(
            c("新客", "主力客", "睡眠客", "半睡客", "沉睡客"),
            c("#e8f5e8", "#e3f2fd", "#fff3e0", "#fce4ec", "#ffebee")
          )
        ) %>%
        DT::formatStyle(
          "ROS分類",
          backgroundColor = DT::styleEqual(
            unique(display_data$ROS分類),
            rainbow(length(unique(display_data$ROS分類)), alpha = 0.3)
          )
        ) %>%
        DT::formatRound(
          columns = c("M值", "F值", "R值", "風險分數", "穩定分數", "總消費"),
          digits = 2
        )
    })
  })
} 