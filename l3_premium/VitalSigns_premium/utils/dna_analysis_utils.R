# DNA 分析工具函數
# 從 module_dna_multi.R 抽取的可重用函數

library(dplyr)
library(tidyr)

# ============================================================================
# 資料檢測與標準化函數
# ============================================================================

#' 偵測並標準化欄位名稱
#' @param df 資料框架
#' @return 標準化後的資料框架
detect_and_standardize_fields <- function(df) {
  # 客戶 ID 欄位偵測
  customer_id_patterns <- c(
    "buyer email", "buyer_email", "buyer-email",
    "customer_id", "customer id", "customer",
    "buyer_id", "buyer id", "buyer",
    "user_id", "user id", "user",
    "email", "e-mail", "mail"
  )
  
  # 時間欄位偵測
  time_patterns <- c(
    "purchase date", "purchase_date", "purchase-date",
    "payments date", "payments_date", "payments-date",
    "payment_time", "payment time",
    "date", "time", "datetime",
    "transaction_date", "transaction date"
  )
  
  # 金額欄位偵測
  price_patterns <- c(
    "item price", "item_price", "item-price",
    "lineitem_price", "lineitem price",
    "amount", "sales", "price", "total",
    "revenue", "payment", "value"
  )
  
  # 轉換欄位名稱為小寫並移除空格
  names_lower <- tolower(names(df))
  names_lower <- gsub("[[:space:]]+", " ", names_lower)
  names_lower <- trimws(names_lower)
  
  # 偵測欄位
  customer_col <- NULL
  time_col <- NULL
  price_col <- NULL
  
  for (pattern in customer_id_patterns) {
    idx <- which(names_lower == pattern)
    if (length(idx) > 0) {
      customer_col <- names(df)[idx[1]]
      break
    }
  }
  
  for (pattern in time_patterns) {
    idx <- which(names_lower == pattern)
    if (length(idx) > 0) {
      time_col <- names(df)[idx[1]]
      break
    }
  }
  
  for (pattern in price_patterns) {
    idx <- which(names_lower == pattern)
    if (length(idx) > 0) {
      price_col <- names(df)[idx[1]]
      break
    }
  }
  
  # 標準化欄位名稱
  if (!is.null(customer_col)) {
    names(df)[names(df) == customer_col] <- "customer_id"
  }
  if (!is.null(time_col)) {
    names(df)[names(df) == time_col] <- "payment_time"
  }
  if (!is.null(price_col)) {
    names(df)[names(df) == price_col] <- "lineitem_price"
  }
  
  return(list(
    data = df,
    detected_fields = list(
      customer = customer_col,
      time = time_col,
      price = price_col
    )
  ))
}

# ============================================================================
# 數值計算工具函數
# ============================================================================

#' 標準化數值到 0-1 區間
#' @param x 數值向量
#' @return 標準化後的數值向量
normalize_01 <- function(x) {
  x <- as.numeric(x)
  x[is.na(x) | is.infinite(x)] <- 0
  
  if (length(unique(x)) == 1) {
    return(rep(0.5, length(x)))
  }
  
  min_x <- min(x, na.rm = TRUE)
  max_x <- max(x, na.rm = TRUE)
  
  if (max_x == min_x) {
    return(rep(0.5, length(x)))
  }
  
  (x - min_x) / (max_x - min_x)
}

#' 計算分位數分組
#' @param x 數值向量
#' @param n_groups 分組數量（默認3）
#' @return 分組標籤
calculate_quantile_groups <- function(x, n_groups = 3) {
  if (n_groups == 3) {
    # 三分位數分組
    quantiles <- quantile(x, probs = c(0.33, 0.67), na.rm = TRUE)
    
    if (quantiles[1] == quantiles[2]) {
      # 如果分位數相同，使用平均值分割
      mean_val <- mean(x, na.rm = TRUE)
      return(ifelse(x <= mean_val, "低", "高"))
    }
    
    return(cut(x, 
               breaks = c(-Inf, quantiles[1], quantiles[2], Inf),
               labels = c("低", "中", "高"),
               include.lowest = TRUE))
  } else if (n_groups == 2) {
    # 二分位數（中位數）分組
    median_val <- median(x, na.rm = TRUE)
    return(ifelse(x <= median_val, "低", "高"))
  } else {
    # 自定義分組數
    probs <- seq(0, 1, length.out = n_groups + 1)
    quantiles <- quantile(x, probs = probs, na.rm = TRUE)
    return(cut(x, breaks = quantiles, include.lowest = TRUE))
  }
}

#' 計算 80/20 法則分組
#' @param x 數值向量
#' @param cumsum_threshold 累積閾值（默認0.8）
#' @return 分組標籤（高價值/低價值）
calculate_pareto_groups <- function(x, cumsum_threshold = 0.8) {
  # 排序並計算累積百分比
  sorted_idx <- order(x, decreasing = TRUE)
  sorted_x <- x[sorted_idx]
  cumsum_pct <- cumsum(sorted_x) / sum(sorted_x, na.rm = TRUE)
  
  # 找出貢獻80%的客戶
  high_value_idx <- which(cumsum_pct <= cumsum_threshold)
  
  # 創建分組標籤
  groups <- rep("低價值", length(x))
  groups[sorted_idx[high_value_idx]] <- "高價值"
  
  return(groups)
}

# ============================================================================
# 分群計算函數
# ============================================================================

#' 計算 RFM 分群
#' @param data 包含 r_value, f_value, m_value 的資料框架
#' @return 添加了分群標籤的資料框架
calculate_rfm_segments <- function(data) {
  # R 分群（最近購買時間）
  if ("r_value" %in% names(data)) {
    r_values <- data$r_value
    if (length(unique(r_values)) > 2) {
      r_quantiles <- quantile(r_values, c(0.33, 0.67), na.rm = TRUE)
      if (r_quantiles[1] == r_quantiles[2]) {
        r_mean <- mean(r_values, na.rm = TRUE)
        data$segment_r <- ifelse(data$r_value <= r_mean, "高活躍", "低活躍")
      } else {
        data$segment_r <- cut(data$r_value,
                              breaks = c(-Inf, r_quantiles[1], r_quantiles[2], Inf),
                              labels = c("高活躍", "中活躍", "低活躍"),
                              include.lowest = TRUE)
      }
    } else {
      data$segment_r <- ifelse(data$r_value <= median(r_values), "高活躍", "低活躍")
    }
  }
  
  # F 分群（購買頻率）
  if ("f_value" %in% names(data)) {
    f_values <- data$f_value
    if (length(unique(f_values)) > 2) {
      f_quantiles <- quantile(f_values, c(0.33, 0.67), na.rm = TRUE)
      if (f_quantiles[1] == f_quantiles[2]) {
        f_mean <- mean(f_values, na.rm = TRUE)
        data$segment_f <- ifelse(data$f_value >= f_mean, "高頻", "低頻")
      } else {
        data$segment_f <- cut(data$f_value,
                              breaks = c(-Inf, f_quantiles[1], f_quantiles[2], Inf),
                              labels = c("低頻", "中頻", "高頻"),
                              include.lowest = TRUE)
      }
    } else {
      data$segment_f <- ifelse(data$f_value >= median(f_values), "高頻", "低頻")
    }
  }
  
  # M 分群（購買金額） - 使用 80/20 法則
  if ("m_value" %in% names(data)) {
    data$total_spent <- data$m_value * data$f_value
    sorted_idx <- order(data$total_spent, decreasing = TRUE)
    sorted_total <- data$total_spent[sorted_idx]
    cumsum_pct <- cumsum(sorted_total) / sum(sorted_total, na.rm = TRUE)
    
    threshold_idx <- which(cumsum_pct <= 0.8)
    data$segment_m <- "低價值"
    if (length(threshold_idx) > 0) {
      data$segment_m[sorted_idx[threshold_idx]] <- "高價值"
    }
  }
  
  return(data)
}

#' 計算進階指標分群（CAI, PCV, CRI, NES）
#' @param data 包含進階指標的資料框架
#' @return 添加了進階分群標籤的資料框架
calculate_advanced_segments <- function(data) {
  # CAI 分群（活躍度）
  if ("cai_value" %in% names(data) || "cai" %in% names(data)) {
    cai_col <- if ("cai_value" %in% names(data)) "cai_value" else "cai"
    cai_values <- data[[cai_col]]
    
    data$segment_cai <- case_when(
      cai_values > 0.1 ~ "漸趨活躍",
      cai_values < -0.1 ~ "漸趨靜止",
      TRUE ~ "穩定"
    )
  }
  
  # PCV 分群（過去價值） - 使用 80/20 法則
  if ("pcv" %in% names(data)) {
    sorted_idx <- order(data$pcv, decreasing = TRUE)
    sorted_pcv <- data$pcv[sorted_idx]
    cumsum_pct <- cumsum(sorted_pcv) / sum(sorted_pcv, na.rm = TRUE)
    
    threshold_idx <- which(cumsum_pct <= 0.8)
    data$segment_pcv <- "低價值"
    if (length(threshold_idx) > 0) {
      data$segment_pcv[sorted_idx[threshold_idx]] <- "高價值"
    }
  }
  
  # CRI 分群（參與度）
  if ("cri" %in% names(data)) {
    cri_quantiles <- quantile(data$cri, c(0.33, 0.67), na.rm = TRUE)
    data$segment_cri <- cut(data$cri,
                            breaks = c(-Inf, cri_quantiles[1], cri_quantiles[2], Inf),
                            labels = c("低參與", "中參與", "高參與"),
                            include.lowest = TRUE)
  }
  
  # NES 分群（客戶狀態）
  if ("nes_status" %in% names(data)) {
    data$segment_nes <- case_when(
      data$nes_status == "N" ~ "新客戶",
      data$nes_status == "E0" ~ "主力客戶",
      data$nes_status %in% c("S1", "S2") ~ "風險客戶",
      data$nes_status == "S3" ~ "流失客戶",
      TRUE ~ "其他"
    )
  }
  
  return(data)
}

# ============================================================================
# 統計計算函數
# ============================================================================

#' 計算描述性統計
#' @param x 數值向量
#' @param digits 小數位數
#' @return 統計摘要列表
calculate_descriptive_stats <- function(x, digits = 2) {
  x <- as.numeric(x)
  x <- x[!is.na(x) & !is.infinite(x)]
  
  if (length(x) == 0) {
    return(list(
      mean = NA,
      median = NA,
      sd = NA,
      q25 = NA,
      q75 = NA,
      min = NA,
      max = NA,
      count = 0
    ))
  }
  
  list(
    mean = round(mean(x, na.rm = TRUE), digits),
    median = round(median(x, na.rm = TRUE), digits),
    sd = round(sd(x, na.rm = TRUE), digits),
    q25 = round(quantile(x, 0.25, na.rm = TRUE), digits),
    q75 = round(quantile(x, 0.75, na.rm = TRUE), digits),
    min = round(min(x, na.rm = TRUE), digits),
    max = round(max(x, na.rm = TRUE), digits),
    count = length(x)
  )
}

#' 計算分群統計
#' @param data 資料框架
#' @param group_col 分群欄位名稱
#' @param value_cols 要計算統計的數值欄位
#' @return 分群統計摘要
calculate_segment_stats <- function(data, group_col, value_cols) {
  if (!group_col %in% names(data)) {
    return(NULL)
  }
  
  available_cols <- intersect(value_cols, names(data))
  if (length(available_cols) == 0) {
    return(NULL)
  }
  
  data %>%
    filter(!is.na(!!sym(group_col))) %>%
    group_by(!!sym(group_col)) %>%
    summarise(
      count = n(),
      pct = round(n() / nrow(data) * 100, 1),
      across(all_of(available_cols), 
             list(mean = ~round(mean(., na.rm = TRUE), 2),
                  median = ~round(median(., na.rm = TRUE), 2)),
             .names = "{.col}_{.fn}"),
      .groups = "drop"
    ) %>%
    arrange(desc(count))
}

# ============================================================================
# 中文欄位對應函數
# ============================================================================

#' 創建中文欄位對應表
#' @return 欄位對應列表
get_chinese_column_mapping <- function() {
  list(
    # 基本欄位
    "customer_id" = "客戶ID",
    "segment" = "客群分組",
    
    # RFM 欄位
    "r_value" = "最近購買(天)",
    "f_value" = "購買頻率(次)",
    "m_value" = "平均金額($)",
    
    # 進階指標
    "cai_value" = "活躍度",
    "cai" = "活躍度",
    "pcv" = "過去價值($)",
    "total_spent" = "總消費($)",
    "cri" = "參與度分數",
    "times" = "購買次數",
    "nes_status" = "客戶狀態",
    "clv" = "終身價值($)",
    
    # 分群欄位
    "segment_r" = "R分群",
    "segment_f" = "F分群",
    "segment_m" = "M分群",
    "segment_cai" = "活躍度分群",
    "segment_pcv" = "價值分群",
    "segment_cri" = "參與度分群",
    "segment_nes" = "狀態分群"
  )
}

#' 將資料框架欄位名稱轉換為中文
#' @param data 資料框架
#' @param mapping 欄位對應表（可選）
#' @return 中文欄位名稱的資料框架
convert_to_chinese_columns <- function(data, mapping = NULL) {
  if (is.null(mapping)) {
    mapping <- get_chinese_column_mapping()
  }
  
  # 創建副本
  data_chinese <- data
  
  # 轉換欄位名稱
  for (old_name in names(mapping)) {
    if (old_name %in% names(data_chinese)) {
      new_name <- mapping[[old_name]]
      # 避免重複的欄位名稱
      if (!new_name %in% names(data_chinese)) {
        names(data_chinese)[names(data_chinese) == old_name] <- new_name
      }
    }
  }
  
  return(data_chinese)
}

# ============================================================================
# 資料驗證函數
# ============================================================================

#' 驗證 DNA 分析所需的欄位
#' @param data 資料框架
#' @return 驗證結果列表
validate_dna_data <- function(data) {
  required_fields <- c("customer_id", "payment_time", "lineitem_price")
  missing_fields <- setdiff(required_fields, names(data))
  
  validation_result <- list(
    is_valid = length(missing_fields) == 0,
    missing_fields = missing_fields,
    row_count = nrow(data),
    customer_count = length(unique(data$customer_id)),
    has_duplicates = any(duplicated(data))
  )
  
  # 檢查資料品質
  if (validation_result$is_valid) {
    validation_result$data_quality <- list(
      na_customer = sum(is.na(data$customer_id)),
      na_time = sum(is.na(data$payment_time)),
      na_price = sum(is.na(data$lineitem_price)),
      negative_price = sum(data$lineitem_price < 0, na.rm = TRUE)
    )
  }
  
  return(validation_result)
}

#' 清理並準備 DNA 分析資料
#' @param data 原始資料框架
#' @return 清理後的資料框架
clean_dna_data <- function(data) {
  data %>%
    # 移除缺失值
    filter(!is.na(customer_id),
           !is.na(payment_time),
           !is.na(lineitem_price)) %>%
    # 移除負值
    filter(lineitem_price > 0) %>%
    # 確保時間格式正確
    mutate(payment_time = as.POSIXct(payment_time)) %>%
    # 移除重複資料
    distinct() %>%
    # 排序
    arrange(customer_id, payment_time)
}