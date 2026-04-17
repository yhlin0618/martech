# Premium2 Multi-File DNA Analysis Module with T×V Grid Mapping
# TagPilot Premium2 Version - supports T×V Grid Analysis using mapping.csv
# Based on working pro2 module with added T×V Grid Mapping functionality

library(shiny)
library(shinyjs)
library(dplyr)
library(DT)
library(plotly)
library(readxl)
library(later)
library(ggplot2)
library(stringr)
library(bs4Dash)

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

# Load T×V Grid Mapping from mapping.csv (Premium2 Feature)
load_tv_mapping <- function() {
  mapping_file <- "database/mapping.csv"
  
  if (!file.exists(mapping_file)) {
    warning("mapping.csv not found. Using default mapping.")
    return(data.frame(
      segment_name = character(0),
      ros_baseline = character(0),
      script_code = character(0),
      strategy_example = character(0),
      tempo = character(0),
      value = character(0),
      email_frequency = character(0),
      discount_percentage = character(0),
      kpi_tracking = character(0),
      tv_combination = character(0),
      base_segment = character(0),
      stringsAsFactors = FALSE
    ))
  }
  
  tryCatch({
    # Read with proper encoding and header handling
    mapping_data <- read.csv(mapping_file, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
    
    # Handle the case where column names might have Chinese characters
    if (ncol(mapping_data) >= 9) {
      # Extract all relevant columns by position since names might vary
      tv_mapping <- data.frame(
        segment_name = mapping_data[, 1],          # 靜態區隔 column
        ros_baseline = mapping_data[, 2],          # ROS Baseline column  
        script_code = mapping_data[, 3],           # 腳本編號 column
        strategy_example = mapping_data[, 4],      # 主要腳本範例 column
        tempo = mapping_data[, 5],                 # Tempo T column
        value = mapping_data[, 6],                 # Value V column
        email_frequency = mapping_data[, 7],       # 信件接觸顧客的次數 column
        discount_percentage = mapping_data[, 8],   # 折扣百分比 column
        kpi_tracking = mapping_data[, 9],          # KPI 追蹤 column
        stringsAsFactors = FALSE
      )
    } else {
      stop("Mapping file does not have expected structure")
    }
    
    # Clean and standardize the mapping data
    tv_mapping <- tv_mapping %>%
      filter(
        !is.na(segment_name) & segment_name != "",
        !is.na(tempo) & tempo != "",
        !is.na(value) & value != ""
      ) %>%
      mutate(
        # Clean the segment names (remove trailing characters and parentheses)
        segment_name = trimws(gsub("\\s*\\([^)]*\\).*", "", segment_name)),
        # Extract base segment name (remove suffixes like -N, -C, -D, -H, -S)
        base_segment = gsub("[-][NCDHS]$", "", segment_name),
        # Standardize T and V values
        tempo = trimws(tempo),
        value = trimws(value),
        # Create combined T×V identifier
        tv_combination = paste0(tempo, value),
        # Clean other fields
        ros_baseline = trimws(ros_baseline),
        script_code = trimws(script_code),
        strategy_example = trimws(strategy_example),
        email_frequency = trimws(email_frequency),
        discount_percentage = trimws(discount_percentage),
        kpi_tracking = trimws(kpi_tracking)
      )
    
    cat("✅ 成功載入 T×V 映射資料：", nrow(tv_mapping), "筆區隔\n")
    
    # Print mapping summary
    tv_summary <- tv_mapping %>%
      count(tempo, value, tv_combination) %>%
      arrange(tempo, value)
    
    cat("📊 T×V 組合分佈：\n")
    for (i in 1:nrow(tv_summary)) {
      cat("   ", tv_summary$tv_combination[i], ":", tv_summary$n[i], "個區隔\n")
    }
    
    return(tv_mapping)
    
  }, error = function(e) {
    warning(paste("Error loading mapping.csv:", e$message))
    return(data.frame(
      segment_name = character(0),
      ros_baseline = character(0),
      script_code = character(0),
      strategy_example = character(0),
      tempo = character(0),
      value = character(0),
      email_frequency = character(0),
      discount_percentage = character(0),
      kpi_tracking = character(0),
      tv_combination = character(0),
      base_segment = character(0),
      stringsAsFactors = FALSE
    ))
  })
}

# Calculate T×V categories for customers with configurable quantiles (Premium2 Feature)
calculate_tv_categories <- function(dna_data, tempo_q1 = 0.33, tempo_q2 = 0.67, value_q1 = 0.33, value_q2 = 0.67) {
  # Calculate IPT (Inter-Purchase Time) for tempo analysis
  if (!"ipt_mean" %in% names(dna_data) && !"ipt" %in% names(dna_data)) {
    dna_data$ipt_mean <- 30  # Default IPT if not available
  }
  
  dna_data <- dna_data %>%
    mutate(
      # Use ipt_mean if available, otherwise use ipt, otherwise default to 30
      customer_ipt = case_when(
        !is.na(ipt_mean) ~ ipt_mean,
        !is.na(ipt) ~ ipt,
        TRUE ~ 30
      ),
      # Ensure customer_ipt is never NA
      customer_ipt = ifelse(is.na(customer_ipt), 30, customer_ipt)
    )
  
  # Calculate CLV for value analysis  
  if (!"total_spent" %in% names(dna_data)) {
    # If total_spent not available, calculate from m_value and times
    if ("m_value" %in% names(dna_data) && ("times" %in% names(dna_data) || "f_value" %in% names(dna_data))) {
      times_col <- if("times" %in% names(dna_data)) "times" else "f_value"
      dna_data$total_spent <- ifelse(
        is.na(dna_data$m_value) | is.na(dna_data[[times_col]]), 
        100, 
        dna_data$m_value * dna_data[[times_col]]
      )
    } else {
      dna_data$total_spent <- 100  # Default CLV if not available
    }
  } else {
    # Ensure existing total_spent doesn't have NA values
    dna_data$total_spent <- ifelse(is.na(dna_data$total_spent), 100, dna_data$total_spent)
  }
  
  total_customers <- nrow(dna_data)
  cat("🔍 T×V 類別計算：總客戶數 =", total_customers, "\n")
  cat("⚙️ 使用 Quantile 參數：T(", tempo_q1, ",", tempo_q2, ") V(", value_q1, ",", value_q2, ")\n")
  
  # Assign T (Tempo) based on configurable IPT quantiles (T1 = fast, T3 = slow)
  ipt_quantiles <- quantile(dna_data$customer_ipt, probs = c(0, tempo_q1, tempo_q2, 1), na.rm = TRUE)
  
  # Assign V (Value) based on configurable CLV quantiles (V1 = high, V3 = low)  
  clv_quantiles <- quantile(dna_data$total_spent, probs = c(0, value_q1, value_q2, 1), na.rm = TRUE)
  
  cat("📊 IPT Quantiles:", round(ipt_quantiles, 2), "\n")
  cat("💰 CLV Quantiles:", round(clv_quantiles, 2), "\n")
  
  dna_result <- dna_data %>%
    mutate(
      # Tempo assignment (T1 = fast repurchase, T3 = slow repurchase)
      tempo_category = case_when(
        is.na(customer_ipt) ~ "T3",                # Handle NA values
        customer_ipt <= ipt_quantiles[2] ~ "T1",   # First quantile (shortest IPT)
        customer_ipt <= ipt_quantiles[3] ~ "T2",   # Second quantile
        TRUE ~ "T3"                                # Third quantile (longest IPT)
      ),
      
      # Value assignment (V1 = high value, V3 = low value)  
      value_category = case_when(
        is.na(total_spent) ~ "V3",                 # Handle NA values
        total_spent >= clv_quantiles[4] ~ "V1",    # Highest quantile (highest CLV)
        total_spent >= clv_quantiles[3] ~ "V2",    # Second quantile
        TRUE ~ "V3"                                # Lowest quantile (lowest CLV)
      ),
      
      # Combined T×V identifier
      tv_combination = paste0(tempo_category, value_category),
      
      # Descriptive names
      tempo_name = case_when(
        tempo_category == "T1" ~ "高頻復購",
        tempo_category == "T2" ~ "中頻復購", 
        tempo_category == "T3" ~ "低頻復購",
        TRUE ~ "未分類"
      ),
      
      value_name = case_when(
        value_category == "V1" ~ "高價值客",
        value_category == "V2" ~ "中價值客",
        value_category == "V3" ~ "潛力客",
        TRUE ~ "未分類"
      ),
      
      tv_combination_name = paste0(tempo_name, " × ", value_name)
    )
  
  # Diagnostic output
  tv_counts <- dna_result %>%
    count(tempo_category, value_category, tv_combination, tv_combination_name) %>%
    arrange(tempo_category, value_category)
  
  cat("✅ T×V 類別計算結果：\n")
  for (i in seq_len(nrow(tv_counts))) {
    cat("   ", tv_counts$tv_combination[i], " (", tv_counts$tv_combination_name[i], "):", 
        tv_counts$n[i], "人\n")
  }
  
  return(dna_result)
}

# Automatic T×V to Static Segment Mapping (Premium2 Feature)
map_customers_to_static_segments <- function(customer_data, tv_mapping) {
  if (is.null(tv_mapping) || nrow(tv_mapping) == 0) {
    cat("⚠️ 無法進行靜態區隔映射：映射資料為空\n")
    # Add default static_segment column
    customer_data$static_segment <- paste0(customer_data$tempo_category, customer_data$value_category, " 未映射")
    return(customer_data)
  }
  
  # Ensure required columns exist
  required_cols <- c("tempo_category", "value_category")
  missing_cols <- setdiff(required_cols, names(customer_data))
  
  if (length(missing_cols) > 0) {
    cat("⚠️ 缺少必要欄位進行映射:", paste(missing_cols, collapse = ", "), "\n")
    customer_data$static_segment <- "無法映射"
    return(customer_data)
  }
  
  # Create TV combination and map to static segments
  customer_mapped <- customer_data %>%
    mutate(
      tv_combination = paste0(tempo_category, value_category)
    )
  
  # For each unique T×V combination, select the most appropriate static segment
  # Create a simplified mapping (one segment per T×V combination)
  simplified_mapping <- tv_mapping %>%
    group_by(tv_combination) %>%
    # Take the first segment for each T×V combination as default
    slice_head(n = 1) %>%
    ungroup() %>%
    select(tv_combination, segment_name) %>%
    rename(static_segment = segment_name)
  
  # Apply mapping
  customer_mapped <- customer_mapped %>%
    left_join(simplified_mapping, by = "tv_combination") %>%
    mutate(
      # If no mapping found, create a default segment name
      static_segment = ifelse(
        is.na(static_segment), 
        paste0(tv_combination, " 未映射"), 
        static_segment
      )
    )
  
  # Diagnostic output
  segment_counts <- customer_mapped %>%
    count(static_segment, tv_combination) %>%
    arrange(tv_combination)
  
  cat("🎯 客戶靜態區隔自動映射結果：\n")
  for (i in seq_len(nrow(segment_counts))) {
    cat("   ", segment_counts$tv_combination[i], " → ", segment_counts$static_segment[i], ":", 
        segment_counts$n[i], "人\n")
  }
  
  return(customer_mapped)
}

# Load strategy data function (same as pro2)
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

# Filter customers by ROS baseline requirement (same as pro2)
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

# Get strategy details by segment code (same as pro2)
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

# UI Function (Enhanced with T×V Grid features)
dnaMultiPremium2ModuleUI <- function(id) {
  ns <- NS(id)
  
  div(
    # 標題區域
    div(
      style = "padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 10px; margin-bottom: 20px;",
      h3("🔬 TagPilot Premium2: T×V Grid Mapping 客戶網格映射分析", 
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
    
    # T×V Quantile 參數設定 (Premium2 Feature)
    conditionalPanel(
      condition = paste0("output['", ns("has_uploaded_data"), "'] == true"),
      wellPanel(
        style = "background-color: #fff3e0; border: 2px solid #ff9800; border-radius: 10px; padding: 20px; margin-bottom: 20px;",
        h4("⚙️ T×V Quantile 映射參數", style = "color: #ff9800; margin-bottom: 20px;"),
        
        div(style = "background-color: white; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
          p("調整 Tempo (T) 和 Value (V) 的分位數閾值，影響客戶如何被分類到 T1/T2/T3 和 V1/V2/V3 群組：", 
            style = "color: #333; margin-bottom: 10px; font-weight: 500;")
        ),
        
        fluidRow(
          column(6,
            h5("Tempo (T) 分位數設定", style = "color: #4169e1; margin-bottom: 15px;"),
            div(style = "background-color: #f3f8ff; padding: 10px; border-radius: 6px;",
              numericInput(ns("tempo_q1"), "T1/T2 分界點", 
                         value = 0.33, min = 0.1, max = 0.8, step = 0.05, width = "100%"),
              numericInput(ns("tempo_q2"), "T2/T3 分界點", 
                         value = 0.67, min = 0.2, max = 0.9, step = 0.05, width = "100%"),
              helpText("IPT (Inter-Purchase Time) 越短 = T1 (高頻), 越長 = T3 (低頻)", style = "font-size: 0.85em; color: #666;")
            )
          ),
          column(6,
            h5("Value (V) 分位數設定", style = "color: #ff9800; margin-bottom: 15px;"),
            div(style = "background-color: #fff8f0; padding: 10px; border-radius: 6px;",
              numericInput(ns("value_q1"), "V2/V1 分界點", 
                         value = 0.33, min = 0.1, max = 0.8, step = 0.05, width = "100%"),
              numericInput(ns("value_q2"), "V3/V2 分界點", 
                         value = 0.67, min = 0.2, max = 0.9, step = 0.05, width = "100%"),
              helpText("CLV (Customer Lifetime Value) 越高 = V1 (高價值), 越低 = V3 (潛力客)", style = "font-size: 0.85em; color: #666;")
            )
          )
        )
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
          
          # T×V Grid 映射洞察 Tab (Premium2 Feature)
          tabPanel(
            "T×V Grid 映射洞察",
            br(),
            fluidRow(
              column(6,
                bs4Card(
                  title = "📊 T×V Grid 客戶分佈",
                  status = "primary",
                  width = 12,
                  solidHeader = TRUE,
                  plotOutput(ns("tv_grid_distribution_plot"))
                )
              ),
              column(6,
                bs4Card(
                  title = "🗺️ 映射區隔分佈",
                  status = "primary",
                  width = 12,
                  solidHeader = TRUE,
                  plotOutput(ns("mapping_segments_plot"))
                )
              )
            ),
            br(),
            fluidRow(
              column(12,
                bs4Card(
                  title = "📈 T×V 映射統計摘要",
                  status = "info",
                  width = 12,
                  solidHeader = TRUE,
                  DT::dataTableOutput(ns("tv_mapping_summary_table"))
                )
              )
            )
          ),
          
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
                  status = "success",
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
          
          # 客戶資料檢查 Tab (Enhanced with T×V Grid info)
          tabPanel(
            "客戶資料檢查",
            br(),
            fluidRow(
              column(12,
                bs4Card(
                  title = "客戶 DNA + T×V Grid 資料表",
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
                      selectInput(ns("filter_tv_combination"), "T×V 組合:",
                                choices = c("全部" = "all", "T1V1" = "T1V1", "T1V2" = "T1V2", "T1V3" = "T1V3",
                                          "T2V1" = "T2V1", "T2V2" = "T2V2", "T2V3" = "T2V3",
                                          "T3V1" = "T3V1", "T3V2" = "T3V2", "T3V3" = "T3V3"),
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

# Server Function (Based on working pro2 with T×V Grid additions)
dnaMultiPremium2ModuleServer <- function(id, con, user_info, uploaded_dna_data = NULL) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Reactive values
    values <- reactiveValues(
      combined_data = NULL,
      dna_results = NULL,
      ros_data = NULL,
      tv_categories_data = NULL,
      tv_mapping = NULL,
      status_text = "⏳ 等待開始分析..."
    )
    
    # Load T×V mapping on module initialization
    observe({
      values$tv_mapping <- load_tv_mapping()
    })
    
    # ROS 分析函數 (same as pro2)
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
          
          # 生命週期中文描述
          lifecycle_stage_zh = case_when(
            lifecycle_stage == "newbie" ~ "新客",
            lifecycle_stage == "active" ~ "主力客",
            lifecycle_stage == "sleepy" ~ "睡眠客",
            lifecycle_stage == "half_sleepy" ~ "半睡客",
            lifecycle_stage == "dormant" ~ "沉睡客",
            TRUE ~ as.character(lifecycle_stage)
          )
        )
    }
    
    # DNA 分析函數 (same structure as pro2, with T×V Grid additions)
    analyze_data <- function(data, min_transactions, delta_factor, risk_threshold, opportunity_threshold, stability_low, stability_high) {
      tryCatch({
        values$status_text <- "📊 準備分析資料..."
        
        # Ensure customer_id column exists
        if (!"customer_id" %in% names(data)) {
          n_rows <- nrow(data)
          if (is.null(n_rows) || n_rows <= 0) {
            values$status_text <- "❌ 資料為空或格式不正確"
            return(NULL)
          }
          data$customer_id <- paste0("CUST_", seq_len(n_rows))
        }
        
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
        
        # Prepare data for DNA analysis (使用 pro2 的相同邏輯)
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
          # 基本DNA分析作為fallback
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
        
        values$status_text <- "💎 計算 T×V 類別分析..."
        
        # 獲取 quantile 參數
        tempo_q1 <- input$tempo_q1 %||% 0.33
        tempo_q2 <- input$tempo_q2 %||% 0.67
        value_q1 <- input$value_q1 %||% 0.33
        value_q2 <- input$value_q2 %||% 0.67
        
        # 計算 T×V 類別分析 (Premium2 Feature)
        tv_categories_data <- calculate_tv_categories(ros_data, tempo_q1, tempo_q2, value_q1, value_q2)
        
        # 自動映射到靜態區隔
        if (!is.null(values$tv_mapping)) {
          tv_categories_data <- map_customers_to_static_segments(tv_categories_data, values$tv_mapping)
        }
        
        # Static segment based on original logic (for nine-grid analysis)
        tv_categories_data <- tv_categories_data %>%
          mutate(
            original_static_segment = paste0(
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
            # 確保生命週期中文描述欄位存在
            lifecycle_stage_zh = case_when(
              lifecycle_stage == "newbie" ~ "新客",
              lifecycle_stage == "active" ~ "主力客",
              lifecycle_stage == "sleepy" ~ "睡眠客",
              lifecycle_stage == "half_sleepy" ~ "半睡客",
              lifecycle_stage == "dormant" ~ "沉睡客",
              TRUE ~ as.character(lifecycle_stage)
            )
          )
        
        values$dna_results <- dna_result
        values$ros_data <- ros_data
        values$tv_categories_data <- tv_categories_data
        values$status_text <- "✅ DNA、ROS 與 T×V 分析完成！"
        
        return(tv_categories_data)
      }, error = function(e) {
        values$status_text <- paste("❌ 分析錯誤:", e$message)
        return(NULL)
      })
    }
    
    # 偵測並載入上傳的資料 (不自動分析，等按按鈕)
    observe({
      if (!is.null(uploaded_dna_data)) {
        if (is.reactive(uploaded_dna_data)) {
          data <- uploaded_dna_data()
        } else {
          data <- uploaded_dna_data
        }
        
        if (!is.null(data) && nrow(data) > 0) {
          values$combined_data <- data
          values$status_text <- paste("📁 已載入", nrow(data), "筆資料，請點擊「🚀 開始分析」按鈕進行分析")
          # 移除自動分析，等使用者按按鈕
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
      !is.null(values$tv_categories_data)
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
    
    # 移除自動重新分析 - 讓所有分析只在按下按鈕時執行
    # observeEvent for quantile parameters removed - 
    # all analysis will only happen when "開始分析" button is clicked
    
    # T×V Grid Distribution Plot (Premium2 Feature)
    output$tv_grid_distribution_plot <- renderPlot({
      req(values$tv_categories_data)
      
      tv_summary <- values$tv_categories_data %>%
        count(tv_combination, tv_combination_name) %>%
        arrange(desc(n))
      
      if (nrow(tv_summary) == 0) {
        return(ggplot() + geom_text(aes(x = 1, y = 1, label = "無符合的客戶資料"), size = 6) + theme_void())
      }
      
      ggplot(tv_summary, aes(x = reorder(tv_combination_name, n), y = n, fill = tv_combination)) +
        geom_bar(stat = "identity") +
        coord_flip() +
        labs(title = "T×V Grid 客戶分佈", x = "T×V 組合", y = "客戶數量") +
        theme_minimal() +
        theme(legend.position = "none") +
        scale_fill_viridis_d(option = "plasma")
    })
    
    # Mapping Segments Plot (Premium2 Feature)
    output$mapping_segments_plot <- renderPlot({
      req(values$tv_categories_data)
      
      if (!"static_segment" %in% names(values$tv_categories_data)) {
        return(ggplot() + geom_text(aes(x = 1, y = 1, label = "無靜態區隔資料"), size = 6) + theme_void())
      }
      
      segment_summary <- values$tv_categories_data %>%
        count(static_segment) %>%
        arrange(desc(n)) %>%
        slice_head(n = 10)  # Show top 10 segments
      
      if (nrow(segment_summary) == 0) {
        return(ggplot() + geom_text(aes(x = 1, y = 1, label = "無符合的區隔資料"), size = 6) + theme_void())
      }
      
      ggplot(segment_summary, aes(x = reorder(static_segment, n), y = n, fill = static_segment)) +
        geom_bar(stat = "identity") +
        coord_flip() +
        labs(title = "對應的靜態區隔分佈 (Top 10)", x = "靜態區隔", y = "客戶數量") +
        theme_minimal() +
        theme(legend.position = "none") +
        scale_fill_viridis_d(option = "viridis")
    })
    
    # T×V Mapping Summary Table (Premium2 Feature) - 根據 mapping.csv 顯示策略資訊
    output$tv_mapping_summary_table <- DT::renderDataTable({
      req(values$tv_categories_data)
      
      # Show actual customer distribution with mapping.csv strategy information
      if ("static_segment" %in% names(values$tv_categories_data) && !is.null(values$tv_mapping)) {
        # Customer distribution by static segment with strategy details
        customer_distribution <- values$tv_categories_data %>%
          group_by(tv_combination, static_segment) %>%
          summarise(客戶數量 = n(), .groups = "drop") %>%
          arrange(tv_combination, desc(客戶數量))
        
        # Join with mapping.csv for strategy information
        mapping_info <- customer_distribution %>%
          left_join(
            values$tv_mapping %>%
              select(segment_name, ros_baseline, script_code, strategy_example, 
                     email_frequency, discount_percentage, kpi_tracking, tempo, value), 
            by = c("static_segment" = "segment_name")
          ) %>%
          select(
            TV組合 = tv_combination,
            靜態區隔 = static_segment,
            客戶數量,
            ROS基準 = ros_baseline,
            策略範例 = strategy_example,
            腳本編號 = script_code,
            接觸次數 = email_frequency,
            折扣百分比 = discount_percentage,
            KPI追蹤 = kpi_tracking,
            Tempo = tempo,
            Value = value
          )
      } else {
        # Fallback: show T×V combination distribution
        mapping_info <- values$tv_categories_data %>%
          group_by(tv_combination, tempo_category, value_category) %>%
          summarise(客戶數量 = n(), .groups = "drop") %>%
          mutate(
            靜態區隔 = "未映射",
            ROS基準 = "未知",
            策略範例 = "無資料"
          ) %>%
          select(
            TV組合 = tv_combination,
            Tempo = tempo_category,
            Value = value_category,
            靜態區隔,
            客戶數量,
            ROS基準,
            策略範例
          )
      }
      
      DT::datatable(
        mapping_info,
        options = list(
          pageLength = 15,
          scrollX = TRUE,
          searching = FALSE
        ),
        rownames = FALSE
      ) %>%
        DT::formatStyle(
          "TV組合",
          backgroundColor = DT::styleEqual(
            c("T1V1", "T1V2", "T1V3", "T2V1", "T2V2", "T2V3", "T3V1", "T3V2", "T3V3"),
            c("#c8e6c9", "#ffe0b2", "#ffcdd2", "#c8e6c9", "#ffe0b2", "#ffcdd2", "#c8e6c9", "#ffe0b2", "#ffcdd2")
          ),
          fontWeight = "bold"
        )
    })
    
    # 更新篩選器選項
    observe({
      if (!is.null(values$tv_categories_data)) {
        # 更新靜態區隔選項
        if ("static_segment" %in% names(values$tv_categories_data)) {
          static_segments <- unique(values$tv_categories_data$static_segment)
          static_segments <- static_segments[!is.na(static_segments)]
          static_segments <- sort(static_segments)
          static_choices <- c("全部" = "all")
          names(static_choices) <- c("全部")
          for (segment in static_segments) {
            static_choices <- c(static_choices, setNames(segment, segment))
          }
          updateSelectInput(session, "filter_static_segment", choices = static_choices)
        }
        
        # 更新 ROS 分類選項
        if ("ros_segment" %in% names(values$tv_categories_data)) {
          ros_choices <- c("全部" = "all", unique(values$tv_categories_data$ros_segment))
          updateSelectInput(session, "filter_ros_segment", choices = ros_choices)
        }
      }
    })
    
    # 計算九宮格分析結果
    nine_grid_data <- reactive({
      req(values$tv_categories_data, input$lifecycle_stage)
      
      filtered_results <- values$tv_categories_data %>%
        filter(lifecycle_stage == input$lifecycle_stage)
      
      if (nrow(filtered_results) == 0) {
        return(NULL)
      }
      
      return(filtered_results)
    })
    
    # 移除 strategy_data reactive - 現在使用 values$tv_mapping 從 mapping.csv 獲取策略資訊
    
    # Generate grid content - 正確實現根據 mapping.csv 的多區隔篩選和 strategy.csv 策略顯示
    generate_grid_content <- function(value_level, activity_level, df, lifecycle_stage, unused_param = NULL) {
      if (is.null(df)) {
        return(HTML('<div style="text-align: center; padding: 15px;">無此生命週期階段的客戶</div>'))
      }
      
      # Get customers for this grid position
      all_customers <- df[df$value_level == value_level & df$activity_level == activity_level, ]
      
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
      
      if (nrow(all_customers) == 0) {
        return(HTML('<div style="text-align: center; padding: 15px;">無此類型客戶</div>'))
      }
      
      # 載入 strategy 資料
      strategy_data <- load_strategy_data()
      
             # 查找所有以 grid_position 開頭的靜態區隔
       segment_results <- list()
       
       if (!is.null(values$tv_mapping)) {
         # 找到所有符合條件的區隔
         matching_segments <- values$tv_mapping %>%
           filter(str_detect(segment_name, paste0("^", grid_position)))
         
         cat("Grid Analysis -", grid_position, "- Found", nrow(matching_segments), "matching segments\n")
         
         if (nrow(matching_segments) > 0) {
          for (i in 1:nrow(matching_segments)) {
            segment_info <- matching_segments[i, ]
            segment_name <- segment_info$segment_name
            
            # 根據該區隔的 ROS 和 T×V 要求篩選客戶
            filtered_customers <- all_customers
            
            # ROS 篩選
            if (!is.null(segment_info$ros_baseline) && segment_info$ros_baseline != "") {
              filtered_customers <- filter_customers_by_ros_baseline(filtered_customers, segment_info$ros_baseline)
            }
            
            # T×V 篩選
            required_tv <- paste0(segment_info$tempo, segment_info$value)
            if (!is.null(required_tv) && required_tv != "NANA" && nrow(filtered_customers) > 0) {
              filtered_customers <- filtered_customers %>%
                filter(tv_combination == required_tv)
            }
            
                         count_filtered <- nrow(filtered_customers)
             
             cat("  Segment:", segment_name, "- ROS:", segment_info$ros_baseline, "T×V:", required_tv, "- Matched:", count_filtered, "customers\n")
             
             # 獲取該區隔對應的策略
             segment_strategy <- NULL
             if (!is.null(strategy_data)) {
               segment_strategy <- get_strategy_by_segment(segment_name, strategy_data)
             }
            
            # 計算統計資訊
            avg_stats <- ""
            if (count_filtered > 0) {
              avg_m <- round(mean(filtered_customers$m_value, na.rm = TRUE), 2)
              avg_f <- round(mean(filtered_customers$f_value, na.rm = TRUE), 2)
              avg_stats <- sprintf("平均M值: %.2f | 平均F值: %.2f", avg_m, avg_f)
            }
            
            segment_results[[length(segment_results) + 1]] <- list(
              segment_name = segment_name,
              ros_baseline = segment_info$ros_baseline,
              tv_requirement = required_tv,
              script_code = segment_info$script_code,
              strategy_example = segment_info$strategy_example,
              kpi_tracking = segment_info$kpi_tracking,
              count_filtered = count_filtered,
              avg_stats = avg_stats,
              strategy_info = segment_strategy
            )
          }
        }
      }
      
      # 根據不同生命週期階段設定不同的顏色
      stage_color <- switch(lifecycle_stage,
        "newbie" = "#4CAF50",      # 綠色
        "active" = "#2196F3",      # 藍色
        "sleepy" = "#FFC107",      # 黃色
        "half_sleepy" = "#FF9800", # 橙色
        "dormant" = "#F44336"      # 紅色
      )
      
      # 生成每個區隔的內容
      segments_content <- ""
      total_filtered <- 0
      
      if (length(segment_results) > 0) {
        for (segment in segment_results) {
          total_filtered <- total_filtered + segment$count_filtered
          
                     # 策略內容
           strategy_content <- ""
           if (!is.null(segment$strategy_info)) {
             primary_content <- ""
             secondary_content <- ""
             
             # 主要策略
             if (!is.null(segment$strategy_info$primary) && nrow(segment$strategy_info$primary) > 0) {
               primary_content <- sprintf(
                 '<div style="margin: 5px 0; padding: 8px; background: #f0f8ff; border-radius: 4px; border-left: 3px solid #2196f3;"><small><strong>🎯 主要策略 (%s):</strong><br>%s<br><small style="color: #666;">渠道: %s | KPI: %s</small></small></div>',
                 segment$strategy_info$primary_code,
                 segment$strategy_info$primary$core_action[1],
                 segment$strategy_info$primary$channel[1],
                 segment$strategy_info$primary$main_kpi[1]
               )
             }
             
             # 次要策略
             if (!is.null(segment$strategy_info$secondary) && nrow(segment$strategy_info$secondary) > 0) {
               secondary_content <- sprintf(
                 '<div style="margin: 5px 0; padding: 6px; background: #f8f9fa; border-radius: 4px; border-left: 2px solid #adb5bd;"><small><strong>📋 次要策略 (%s):</strong><br>%s<br><small style="color: #666;">渠道: %s | KPI: %s</small></small></div>',
                 segment$strategy_info$secondary_code,
                 segment$strategy_info$secondary$core_action[1],
                 segment$strategy_info$secondary$channel[1],
                 segment$strategy_info$secondary$main_kpi[1]
               )
             }
             
             strategy_content <- paste0(primary_content, secondary_content)
           } else {
             # 顯示 mapping.csv 中的策略範例作為備用
             if (!is.null(segment$strategy_example) && segment$strategy_example != "") {
               strategy_content <- sprintf(
                 '<div style="margin: 5px 0; padding: 8px; background: #fff3e0; border-radius: 4px; border-left: 3px solid #ff9800;"><small><strong>💡 策略範例:</strong><br>%s<br><small style="color: #666;">腳本: %s | KPI: %s</small></small></div>',
                 segment$strategy_example,
                 segment$script_code,
                 segment$kpi_tracking
               )
             }
           }
          
          # 單個區隔的內容
          segment_content <- sprintf(
            '<div style="margin: 10px 0; padding: 10px; background: white; border-radius: 5px; border-left: 4px solid %s;">
              <div style="font-weight: bold; color: #333; margin-bottom: 5px;">📍 %s</div>
              <div style="font-size: 12px; color: #666; margin-bottom: 5px;">
                🎯 ROS: %s | ⚡ T×V: %s
              </div>
              <div style="font-size: 18px; font-weight: bold; color: %s; margin: 5px 0;">
                %d 位符合客戶
              </div>
              %s
              %s
            </div>',
            ifelse(segment$count_filtered > 0, "#4caf50", "#f44336"),
            segment$segment_name,
            segment$ros_baseline,
            segment$tv_requirement,
            ifelse(segment$count_filtered > 0, "#2e7d32", "#d32f2f"),
            segment$count_filtered,
            ifelse(segment$count_filtered > 0, 
                   sprintf('<div style="font-size: 11px; color: #666;">%s</div>', segment$avg_stats),
                   ''),
            strategy_content
          )
          
          segments_content <- paste0(segments_content, segment_content)
        }
      } else {
        segments_content <- '<div style="margin: 10px 0; padding: 8px; background: #fff3cd; border-radius: 4px; border-left: 3px solid #ffc107; color: #856404;"><strong>⚠️ 提醒</strong><br>此區隔暫無對應策略資料</div>'
      }
      
      # 生成完整內容
      HTML(sprintf('
        <div style="text-align: left; padding: 10px; border-left: 4px solid %s; background: #fafafa;">
          <!-- 區隔標題 -->
          <div style="text-align: center; font-size: 16px; font-weight: bold; color: #333; margin-bottom: 10px; padding: 8px; background: white; border-radius: 5px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
            🏷️ %s
          </div>
          
          <!-- 原始人數 vs 篩選後人數 -->
          <div style="text-align: center; margin: 10px 0; padding: 8px; background: #f8f9fa; border-radius: 5px; border: 1px solid #dee2e6;">
            <div style="font-size: 14px; color: #666; margin-bottom: 5px;">📊 人數統計</div>
            <div style="font-size: 18px; font-weight: bold;">
              <span style="color: #6c757d;">原始: %d 人</span> → 
              <span style="color: %s;">篩選後: %d 人</span>
            </div>
          </div>
          
          <!-- 各區隔詳細資訊 -->
          %s
        </div>
      ', stage_color, grid_position, nrow(all_customers), 
         ifelse(total_filtered > 0, "#28a745", "#dc3545"), total_filtered, segments_content))
    }
    
    # 九宮格輸出 - 參照 pro2 的簡潔設計
    output$nine_grid_output <- renderUI({
      req(nine_grid_data())
      
      df <- nine_grid_data()
      lifecycle <- input$lifecycle_stage
      
      # 創建九宮格 - 使用 pro2 的簡潔佈局
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
                    generate_grid_content(value_level, activity_level, df, lifecycle, NULL)
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
      req(values$tv_categories_data)
      
      if (!"ros_segment" %in% names(values$tv_categories_data)) {
        return(ggplot() + geom_text(aes(x = 1, y = 1, label = "無 ROS 分析資料"), size = 6) + theme_void())
      }
      
      ros_summary <- values$tv_categories_data %>%
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
      req(values$tv_categories_data)
      
      if (!"ros_segment" %in% names(values$tv_categories_data)) {
        return(DT::datatable(data.frame(訊息 = "無 ROS 分析資料")))
      }
      
      summary_data <- values$tv_categories_data %>%
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
    
    # 客戶資料表 (Enhanced with T×V Grid information)
    output$customer_data_table <- DT::renderDataTable({
      req(values$tv_categories_data)
      
      cat("Customer Data Check - Original data dimensions:", nrow(values$tv_categories_data), "x", ncol(values$tv_categories_data), "\n")
      cat("Customer Data Check - Available columns:", paste(names(values$tv_categories_data), collapse = ", "), "\n")
      
      filtered_data <- values$tv_categories_data
      
      # Apply additional filters
      if (!is.null(input$filter_static_segment) && input$filter_static_segment != "all") {
        if ("static_segment" %in% names(filtered_data)) {
          filtered_data <- filtered_data %>%
            filter(static_segment == input$filter_static_segment)
        }
      }
      
      if (!is.null(input$filter_tv_combination) && input$filter_tv_combination != "all") {
        if ("tv_combination" %in% names(filtered_data)) {
          filtered_data <- filtered_data %>%
            filter(tv_combination == input$filter_tv_combination)
        }
      }
      
      if (!is.null(input$filter_lifecycle) && input$filter_lifecycle != "all") {
        if ("lifecycle_stage" %in% names(filtered_data)) {
          filtered_data <- filtered_data %>%
            filter(lifecycle_stage == input$filter_lifecycle)
        }
      }
      
      if (!is.null(input$filter_ros_segment) && input$filter_ros_segment != "all") {
        if ("ros_segment" %in% names(filtered_data)) {
          filtered_data <- filtered_data %>%
            filter(ros_segment == input$filter_ros_segment)
        }
      }
      
      # Apply minimum M value filter
      if (!is.null(input$min_m_value) && input$min_m_value > 0) {
        if ("m_value" %in% names(filtered_data)) {
          filtered_data <- filtered_data %>%
            filter(m_value >= input$min_m_value)
        }
      }
      
      cat("Customer Data Check - Filtered data dimensions:", nrow(filtered_data), "x", ncol(filtered_data), "\n")
      
      # 選擇要顯示的欄位 - 修復重複名稱問題
      display_data <- filtered_data
      
      # 檢查可用欄位並安全選擇
      available_cols <- names(filtered_data)
      
      # 建立欄位映射
      column_mapping <- list()
      
      if ("customer_id" %in% available_cols) column_mapping[["客戶ID"]] <- "customer_id"
      if ("static_segment" %in% available_cols) column_mapping[["靜態區隔"]] <- "static_segment"
      if ("lifecycle_stage_zh" %in% available_cols) {
        column_mapping[["生命週期"]] <- "lifecycle_stage_zh"
      } else if ("lifecycle_stage" %in% available_cols) {
        column_mapping[["生命週期"]] <- "lifecycle_stage"
      }
      if ("value_level" %in% available_cols) column_mapping[["價值等級"]] <- "value_level"
      if ("activity_level" %in% available_cols) column_mapping[["活躍等級"]] <- "activity_level"
      # ✅ 修正：優先顯示完整名稱，而非代號
      if ("tv_combination_name" %in% available_cols) {
        column_mapping[["客戶類型標籤"]] <- "tv_combination_name"
      } else if ("tv_combination" %in% available_cols) {
        column_mapping[["T×V組合"]] <- "tv_combination"
      }
      if ("ros_segment" %in% available_cols) column_mapping[["ROS分類"]] <- "ros_segment"
      if ("ros_description" %in% available_cols) column_mapping[["ROS描述"]] <- "ros_description"
      if ("m_value" %in% available_cols) column_mapping[["M值"]] <- "m_value"
      if ("f_value" %in% available_cols) column_mapping[["F值"]] <- "f_value"
      if ("r_value" %in% available_cols) column_mapping[["R值"]] <- "r_value"
      if ("risk_score" %in% available_cols) column_mapping[["風險分數"]] <- "risk_score"
      if ("predicted_tnp" %in% available_cols) column_mapping[["機會天數"]] <- "predicted_tnp"
      if ("stability_score" %in% available_cols) column_mapping[["穩定分數"]] <- "stability_score"
      if ("total_spent" %in% available_cols) column_mapping[["總消費"]] <- "total_spent"
      if ("times" %in% available_cols) column_mapping[["交易次數"]] <- "times"
      
      # 選擇並重命名欄位
      if (length(column_mapping) > 0) {
        display_data <- filtered_data %>%
          select(all_of(unlist(column_mapping))) %>%
          setNames(names(column_mapping)) %>%
          mutate(
            across(any_of(c("M值")), ~ round(as.numeric(.x), 2)),
            across(any_of(c("F值")), ~ round(as.numeric(.x), 0)),
            across(any_of(c("R值")), ~ round(as.numeric(.x), 1)),
            across(any_of(c("風險分數")), ~ round(as.numeric(.x), 3)),
            across(any_of(c("機會天數")), ~ round(as.numeric(.x), 1)),
            across(any_of(c("穩定分數")), ~ round(as.numeric(.x), 3)),
            across(any_of(c("總消費")), ~ round(as.numeric(.x), 2))
          )
      } else {
        # 如果沒有合適的欄位，顯示錯誤訊息
        display_data <- data.frame(
          訊息 = "無可顯示的客戶資料，請檢查分析結果是否正確生成"
        )
      }
      
      # 創建 DataTable 並安全地應用格式化
      dt_output <- DT::datatable(
        display_data,
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          searching = TRUE,
          order = if("M值" %in% names(display_data)) {
            list(list(which(names(display_data) == "M值") - 1, "desc"))
          } else {
            list(list(0, "asc"))
          }
        ),
        rownames = FALSE
      ) %>%
        DT::formatStyle(
          columns = names(display_data),
          fontSize = "85%"
        )
      
      # 如果有 T×V 組合欄位，則添加顏色格式化
      tv_col_index <- which(names(display_data) %in% c("T×V組合"))
      if (length(tv_col_index) > 0) {
        dt_output <- dt_output %>%
          DT::formatStyle(
            columns = tv_col_index,
            backgroundColor = DT::styleEqual(
              c("T1V1", "T1V2", "T1V3", "T2V1", "T2V2", "T2V3", "T3V1", "T3V2", "T3V3"),
              c("#c8e6c9", "#ffe0b2", "#ffcdd2", "#c8e6c9", "#ffe0b2", "#ffcdd2", "#c8e6c9", "#ffe0b2", "#ffcdd2")
            ),
            fontWeight = "bold"
          )
      }
      
      dt_output
    })
    
    # Download Handler - 只下載客戶資料檢查頁面顯示的欄位和篩選後資料
    output$download_customer_data <- downloadHandler(
      filename = function() {
        paste0("tagpilot_premium2_customer_data_", Sys.Date(), ".csv")
      },
      content = function(file) {
        # 使用與客戶資料檢查表格相同的篩選邏輯
        if (!is.null(values$tv_categories_data)) {
          filtered_data <- values$tv_categories_data
          
          # 應用相同的篩選條件
          # 靜態區隔篩選
          if (!is.null(input$filter_static_segment) && input$filter_static_segment != "all") {
            if ("static_segment" %in% names(filtered_data)) {
              filtered_data <- filtered_data %>%
                filter(static_segment == input$filter_static_segment)
            }
          }
          
          # T×V組合篩選
          if (!is.null(input$filter_tv_combination) && input$filter_tv_combination != "all") {
            if ("tv_combination" %in% names(filtered_data)) {
              filtered_data <- filtered_data %>%
                filter(tv_combination == input$filter_tv_combination)
            }
          }
          
          # 生命週期篩選
          if (!is.null(input$filter_lifecycle) && input$filter_lifecycle != "all") {
            if ("lifecycle_stage" %in% names(filtered_data)) {
              filtered_data <- filtered_data %>%
                filter(lifecycle_stage == input$filter_lifecycle)
            }
          }
          
          # ROS分類篩選
          if (!is.null(input$filter_ros_segment) && input$filter_ros_segment != "all") {
            if ("ros_segment" %in% names(filtered_data)) {
              filtered_data <- filtered_data %>%
                filter(ros_segment == input$filter_ros_segment)
            }
          }
          
          # M值篩選
          if (!is.null(input$min_m_value) && input$min_m_value > 0) {
            if ("m_value" %in% names(filtered_data)) {
              filtered_data <- filtered_data %>%
                filter(m_value >= input$min_m_value)
            }
          }
          
          # 使用與客戶資料檢查表格相同的欄位選擇邏輯
          available_cols <- names(filtered_data)
          column_mapping <- list()
          
          if ("customer_id" %in% available_cols) column_mapping[["客戶ID"]] <- "customer_id"
          if ("static_segment" %in% available_cols) column_mapping[["靜態區隔"]] <- "static_segment"
          if ("lifecycle_stage_zh" %in% available_cols) {
            column_mapping[["生命週期"]] <- "lifecycle_stage_zh"
          } else if ("lifecycle_stage" %in% available_cols) {
            column_mapping[["生命週期"]] <- "lifecycle_stage"
          }
          if ("value_level" %in% available_cols) column_mapping[["價值等級"]] <- "value_level"
          if ("activity_level" %in% available_cols) column_mapping[["活躍等級"]] <- "activity_level"
          # ✅ 修正：CSV 也優先顯示完整名稱
          if ("tv_combination_name" %in% available_cols) {
            column_mapping[["客戶類型標籤"]] <- "tv_combination_name"
          } else if ("tv_combination" %in% available_cols) {
            column_mapping[["T×V組合"]] <- "tv_combination"
          }
          if ("ros_segment" %in% available_cols) column_mapping[["ROS分類"]] <- "ros_segment"
          if ("ros_description" %in% available_cols) column_mapping[["ROS描述"]] <- "ros_description"
          if ("m_value" %in% available_cols) column_mapping[["M值"]] <- "m_value"
          if ("f_value" %in% available_cols) column_mapping[["F值"]] <- "f_value"
          if ("r_value" %in% available_cols) column_mapping[["R值"]] <- "r_value"
          if ("risk_score" %in% available_cols) column_mapping[["風險分數"]] <- "risk_score"
          if ("predicted_tnp" %in% available_cols) column_mapping[["機會天數"]] <- "predicted_tnp"
          if ("stability_score" %in% available_cols) column_mapping[["穩定分數"]] <- "stability_score"
          if ("total_spent" %in% available_cols) column_mapping[["總消費"]] <- "total_spent"
          if ("times" %in% available_cols) column_mapping[["交易次數"]] <- "times"
          
          # 選擇並重命名欄位，與顯示表格完全一致
          if (length(column_mapping) > 0) {
            download_data <- filtered_data %>%
              select(all_of(unlist(column_mapping))) %>%
              setNames(names(column_mapping)) %>%
              mutate(
                across(any_of(c("M值")), ~ round(as.numeric(.x), 2)),
                across(any_of(c("F值")), ~ round(as.numeric(.x), 0)),
                across(any_of(c("R值")), ~ round(as.numeric(.x), 1)),
                across(any_of(c("風險分數")), ~ round(as.numeric(.x), 3)),
                across(any_of(c("機會天數")), ~ round(as.numeric(.x), 1)),
                across(any_of(c("穩定分數")), ~ round(as.numeric(.x), 3)),
                across(any_of(c("總消費")), ~ round(as.numeric(.x), 2))
              )

            # ✅ 修正：使用 UTF-8 BOM 確保 Excel 正確顯示中文
            con <- file(file, open = "wb", encoding = "UTF-8")
            writeBin(charToRaw('\ufeff'), con)  # UTF-8 BOM
            write.csv(download_data, con, row.names = FALSE, fileEncoding = "UTF-8")
            close(con)
            cat("Download completed: ", nrow(download_data), " rows, ", ncol(download_data), " columns\n")
          } else {
            # 如果沒有可用欄位，創建空檔案
            con <- file(file, open = "wb", encoding = "UTF-8")
            writeBin(charToRaw('\ufeff'), con)
            write.csv(data.frame(訊息 = "無可下載的資料"), con, row.names = FALSE, fileEncoding = "UTF-8")
            close(con)
          }
        } else {
          # 如果沒有資料，創建空檔案
          con <- file(file, open = "wb", encoding = "UTF-8")
          writeBin(charToRaw('\ufeff'), con)
          write.csv(data.frame(訊息 = "尚未進行分析，無資料可下載"), con, row.names = FALSE, fileEncoding = "UTF-8")
          close(con)
        }
      }
    )
  })
}