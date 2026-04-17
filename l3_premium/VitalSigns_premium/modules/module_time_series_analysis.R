# 時間序列分析模組 (Time Series Analysis Module)
# 提供時間序列數據處理和趨勢分析功能

library(shiny)
library(dplyr)
library(tidyr)
library(lubridate)

# 載入提示系統
source("utils/hint_system.R")

# UI Function
timeSeriesAnalysisUI <- function(id, enable_hints = TRUE) {
  ns <- NS(id)
  
  # 載入提示資料
  hints_df <- if(enable_hints) load_hints() else NULL
  
  # 此模組主要提供數據處理功能，不需要 UI
  # 但可以添加提示系統初始化
  tagList(
    # 初始化提示系統
    if(enable_hints) init_hint_system() else NULL
  )
}

# Server Function
timeSeriesAnalysisServer <- function(id, raw_data, enable_hints = TRUE) {
  moduleServer(id, function(input, output, session) {
    
    # 如果啟用提示，定期觸發提示初始化
    if(enable_hints) {
      observe({
        trigger_hint_init(session)
      })
    }
    
    # 時間序列聚合函數
    aggregate_time_series <- function(data, period = "month", metrics = c("revenue", "customers", "transactions")) {
      if (is.null(data) || nrow(data) == 0) {
        return(NULL)
      }
      
      # 確保必要欄位存在
      required_cols <- c("payment_time", "lineitem_price", "customer_id")
      if (!all(required_cols %in% colnames(data))) {
        return(NULL)
      }
      
      # 處理時間欄位
      data <- data %>%
        mutate(
          date = as.Date(payment_time),
          period_date = case_when(
            period == "daily" ~ date,
            period == "weekly" ~ floor_date(date, "week"),
            period == "monthly" ~ floor_date(date, "month"),
            period == "quarterly" ~ floor_date(date, "quarter"),
            period == "yearly" ~ floor_date(date, "year"),
            TRUE ~ date
          )
        )
      
      # 聚合數據
      aggregated <- data %>%
        group_by(period_date) %>%
        summarise(
          revenue = sum(lineitem_price, na.rm = TRUE),
          transactions = n(),
          customers = n_distinct(customer_id),
          avg_transaction_value = mean(lineitem_price, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        arrange(period_date)
      
      # 計算成長指標
      aggregated <- aggregated %>%
        mutate(
          revenue_growth = (revenue - lag(revenue)) / lag(revenue) * 100,
          customer_growth = (customers - lag(customers)) / lag(customers) * 100,
          transaction_growth = (transactions - lag(transactions)) / lag(transactions) * 100,
          # 移動平均
          revenue_ma3 = zoo::rollmean(revenue, k = 3, fill = NA, align = "right"),
          # 同比增長（如果有足夠數據）
          revenue_yoy = case_when(
            period == "monthly" ~ (revenue - lag(revenue, 12)) / lag(revenue, 12) * 100,
            period == "quarterly" ~ (revenue - lag(revenue, 4)) / lag(revenue, 4) * 100,
            TRUE ~ NA_real_
          )
        )
      
      return(aggregated)
    }
    
    # 計算趨勢分析
    calculate_trend <- function(data, metric = "revenue") {
      if (is.null(data) || nrow(data) < 2) {
        return(list(
          trend_direction = "insufficient_data",
          trend_strength = 0,
          forecast = NULL
        ))
      }
      
      # 簡單線性趨勢
      x <- seq_len(nrow(data))
      y <- data[[metric]]
      
      if (all(is.na(y))) {
        return(list(
          trend_direction = "no_data",
          trend_strength = 0,
          forecast = NULL
        ))
      }
      
      # 移除 NA 值
      valid_indices <- !is.na(y)
      x_valid <- x[valid_indices]
      y_valid <- y[valid_indices]
      
      if (length(x_valid) < 2) {
        return(list(
          trend_direction = "insufficient_data",
          trend_strength = 0,
          forecast = NULL
        ))
      }
      
      # 計算線性趨勢
      lm_model <- lm(y_valid ~ x_valid)
      slope <- coef(lm_model)[2]
      r_squared <- summary(lm_model)$r.squared
      
      # 判斷趨勢方向
      trend_direction <- case_when(
        slope > 0.05 ~ "positive",
        slope < -0.05 ~ "negative",
        TRUE ~ "stable"
      )
      
      # 簡單預測（未來3期）
      future_periods <- max(x) + 1:3
      forecast <- predict(lm_model, newdata = data.frame(x_valid = future_periods))
      
      return(list(
        trend_direction = trend_direction,
        trend_strength = r_squared,
        slope = slope,
        forecast = forecast
      ))
    }
    
    # Reactive: 日度數據
    daily_data <- reactive({
      req(raw_data)
      aggregate_time_series(raw_data(), period = "daily")
    })
    
    # Reactive: 週度數據
    weekly_data <- reactive({
      req(raw_data)
      aggregate_time_series(raw_data(), period = "weekly")
    })
    
    # Reactive: 月度數據
    monthly_data <- reactive({
      req(raw_data)
      aggregate_time_series(raw_data(), period = "monthly")
    })
    
    # Reactive: 季度數據
    quarterly_data <- reactive({
      req(raw_data)
      aggregate_time_series(raw_data(), period = "quarterly")
    })
    
    # Reactive: 年度數據
    yearly_data <- reactive({
      req(raw_data)
      aggregate_time_series(raw_data(), period = "yearly")
    })
    
    # Reactive: 收入趨勢分析
    revenue_trend <- reactive({
      data <- monthly_data()
      if (is.null(data)) return(NULL)
      calculate_trend(data, "revenue")
    })
    
    # Reactive: 客戶趨勢分析
    customer_trend <- reactive({
      data <- monthly_data()
      if (is.null(data)) return(NULL)
      calculate_trend(data, "customers")
    })
    
    # 計算關鍵指標摘要
    metrics_summary <- reactive({
      data <- monthly_data()
      if (is.null(data) || nrow(data) == 0) {
        return(list(
          total_revenue = 0,
          avg_monthly_revenue = 0,
          revenue_growth_rate = 0,
          total_customers = 0,
          avg_monthly_customers = 0,
          customer_growth_rate = 0,
          total_transactions = 0,
          avg_transaction_value = 0
        ))
      }
      
      list(
        total_revenue = sum(data$revenue, na.rm = TRUE),
        avg_monthly_revenue = mean(data$revenue, na.rm = TRUE),
        revenue_growth_rate = mean(data$revenue_growth, na.rm = TRUE),
        total_customers = sum(data$customers, na.rm = TRUE),
        avg_monthly_customers = mean(data$customers, na.rm = TRUE),
        customer_growth_rate = mean(data$customer_growth, na.rm = TRUE),
        total_transactions = sum(data$transactions, na.rm = TRUE),
        avg_transaction_value = mean(data$avg_transaction_value, na.rm = TRUE)
      )
    })
    
    # 返回所有分析結果
    return(list(
      daily_data = daily_data,
      weekly_data = weekly_data,
      monthly_data = monthly_data,
      quarterly_data = quarterly_data,
      yearly_data = yearly_data,
      revenue_trend = revenue_trend,
      customer_trend = customer_trend,
      metrics_summary = metrics_summary,
      # 輔助函數
      aggregate_time_series = aggregate_time_series,
      calculate_trend = calculate_trend
    ))
  })
}