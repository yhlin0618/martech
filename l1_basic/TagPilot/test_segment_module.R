#!/usr/bin/env Rscript
# 測試客戶區隔模組的資料傳遞

# 載入必要套件
library(shiny)
library(dplyr)

# 載入模組
source("modules/module_customer_segment.R")

# 模擬上傳資料
test_data <- data.frame(
  customer_id = c("A001", "A002", "A003", "A001", "A002"),
  amount = c(100, 200, 150, 300, 250),
  payments_date = Sys.Date() - c(1, 2, 3, 5, 10),
  stringsAsFactors = FALSE
)

cat("=== 測試客戶區隔模組 ===\n")
cat("測試資料：\n")
print(test_data)

# 測試資料處理邏輯
cat("\n=== 測試資料聚合 ===\n")

# 模擬模組中的處理邏輯
col_names <- names(test_data)

amount_col <- if("amount" %in% col_names) {
  "amount"
} else if("lineitem_price" %in% col_names) {
  "lineitem_price"
} else if("total_amount" %in% col_names) {
  "total_amount"
} else {
  NULL
}

cat("偵測到金額欄位：", amount_col, "\n")

if ("customer_id" %in% col_names && !is.null(amount_col)) {
  result <- test_data %>%
    filter(!is.na(customer_id)) %>%
    group_by(customer_id) %>%
    summarise(
      customer_email = first(customer_id),
      platform_id = 0,
      platform_name = "Unknown",
      segment = "待分析",
      recency = 0,
      frequency = n(),
      monetary = sum(as.numeric(get(amount_col)), na.rm = TRUE),
      calculated_at = Sys.Date(),
      segment_chinese = "待分析",
      customer_value = round(sum(as.numeric(get(amount_col)), na.rm = TRUE), 2),
      .groups = 'drop'
    )
  
  cat("\n聚合結果：\n")
  print(result)
  
  # 測試九宮格分類
  if (nrow(result) > 0) {
    cat("\n=== 測試九宮格分類 ===\n")
    
    # 計算分位數
    m_quantiles <- quantile(result$customer_value, probs = c(0.2, 0.8), na.rm = TRUE)
    f_quantiles <- quantile(result$frequency, probs = c(0.2, 0.8), na.rm = TRUE)
    
    cat("價值分位數：", m_quantiles, "\n")
    cat("頻率分位數：", f_quantiles, "\n")
    
    # 處理分位數相同的情況
    if (length(unique(m_quantiles)) < 2 || diff(m_quantiles) < 0.001) {
      m_min <- min(result$customer_value, na.rm = TRUE)
      m_max <- max(result$customer_value, na.rm = TRUE)
      if (m_max - m_min < 0.001) {
        m_breaks <- c(m_min - 0.001, m_min, m_min + 0.001, m_max + 0.001)
      } else {
        m_breaks <- c(m_min - 0.001, 
                     m_min + (m_max - m_min) * 0.33, 
                     m_min + (m_max - m_min) * 0.67, 
                     m_max + 0.001)
      }
    } else {
      m_breaks <- c(min(result$customer_value, na.rm = TRUE) - 0.001,
                   m_quantiles[1], m_quantiles[2],
                   max(result$customer_value, na.rm = TRUE) + 0.001)
    }
    
    if (length(unique(f_quantiles)) < 2 || diff(f_quantiles) < 0.001) {
      f_min <- min(result$frequency, na.rm = TRUE)
      f_max <- max(result$frequency, na.rm = TRUE)
      if (f_max - f_min < 0.001) {
        f_breaks <- c(f_min - 0.001, f_min, f_min + 0.001, f_max + 0.001)
      } else {
        f_breaks <- c(f_min - 0.001,
                     f_min + (f_max - f_min) * 0.33,
                     f_min + (f_max - f_min) * 0.67,
                     f_max + 0.001)
      }
    } else {
      f_breaks <- c(min(result$frequency, na.rm = TRUE) - 0.001,
                   f_quantiles[1], f_quantiles[2],
                   max(result$frequency, na.rm = TRUE) + 0.001)
    }
    
    # 確保 breaks 是唯一且遞增的
    m_breaks <- sort(unique(m_breaks))
    f_breaks <- sort(unique(f_breaks))
    
    # 如果仍然沒有足夠的分割點，使用預設值
    if (length(m_breaks) < 4) {
      m_breaks <- c(0, 100, 500, max(result$customer_value, na.rm = TRUE) + 1)
    }
    if (length(f_breaks) < 4) {
      f_breaks <- c(0, 1, 3, max(result$frequency, na.rm = TRUE) + 1)
    }
    
    # 分類客戶
    result$value_level <- cut(result$customer_value,
                             breaks = m_breaks,
                             labels = c("低", "中", "高"),
                             include.lowest = TRUE,
                             right = FALSE)
    
    result$activity_level <- cut(result$frequency,
                                breaks = f_breaks,
                                labels = c("低", "中", "高"),
                                include.lowest = TRUE,
                                right = FALSE)
    
    # 使用與九宮格相同的命名系統
    result$segment_chinese <- with(result, {
      ifelse(value_level == "高" & activity_level == "高", "A1C 王者引擎-C",
      ifelse(value_level == "高" & activity_level == "中", "A2C 王者穩健-C",
      ifelse(value_level == "高" & activity_level == "低", "A3C 王者休眠-C",
      ifelse(value_level == "中" & activity_level == "高", "B1C 成長火箭-C",
      ifelse(value_level == "中" & activity_level == "中", "B2C 成長常規-C",
      ifelse(value_level == "中" & activity_level == "低", "B3C 成長停滯-C",
      ifelse(value_level == "低" & activity_level == "高", "C1C 潛力新芽-C",
      ifelse(value_level == "低" & activity_level == "中", "C2C 潛力維持-C",
      ifelse(value_level == "低" & activity_level == "低", "C3C 清倉邊緣-C",
      "未分類")))))))))
    })
    
    cat("\n最終分類結果：\n")
    print(result[, c("customer_id", "customer_value", "frequency", "value_level", "activity_level", "segment_chinese")])
    
    # 分類統計
    segment_summary <- table(result$segment_chinese)
    cat("\n分類統計：\n")
    print(segment_summary)
  }
} else {
  cat("❌ 資料缺少必要欄位\n")
}

cat("\n✅ 測試完成！\n")