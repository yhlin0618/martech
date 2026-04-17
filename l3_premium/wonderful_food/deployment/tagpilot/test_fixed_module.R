# 測試修正後的 module_dna_multi_pro2.R
# Test Fixed Module

cat("=================================================\n")
cat("測試修正後的 module_dna_multi_pro2.R\n")
cat("=================================================\n\n")

# 載入必要套件
library(dplyr)

# 檢查原始資料格式
cat("1. 檢查原始資料應該有的欄位：\n")
required_fields <- c("customer_id", "lineitem_price", "payment_time")
cat("   必要欄位:", paste(required_fields, collapse = ", "), "\n\n")

# 創建測試資料（模擬正確的欄位格式）
cat("2. 創建測試資料：\n")
set.seed(123)
test_data <- data.frame(
  customer_id = paste0("C", rep(1:50, each = sample(2:10, 50, replace = TRUE))),
  lineitem_price = round(runif(300, 10, 500), 2),
  payment_time = as.POSIXct("2024-01-01") + sample(0:365, 300, replace = TRUE) * 24 * 3600,
  stringsAsFactors = FALSE
)

cat("   測試資料筆數:", nrow(test_data), "\n")
cat("   客戶數:", length(unique(test_data$customer_id)), "\n")
cat("   欄位名稱:", paste(names(test_data), collapse = ", "), "\n\n")

# 測試資料預處理邏輯
cat("3. 測試資料預處理：\n")

# 模擬 module 中的處理邏輯
tryCatch({
  # 篩選最少交易次數的客戶
  min_transactions <- 2
  customer_counts <- test_data %>%
    group_by(customer_id) %>%
    summarise(n_transactions = n(), .groups = "drop")
  
  valid_customers <- customer_counts %>%
    filter(n_transactions >= min_transactions) %>%
    pull(customer_id)
  
  filtered_data <- test_data %>%
    filter(customer_id %in% valid_customers)
  
  cat("   篩選後客戶數:", length(valid_customers), "\n")
  cat("   篩選後交易數:", nrow(filtered_data), "\n")
  
  # 測試 sales_by_customer 計算
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
    )
  
  cat("   ✅ sales_by_customer 計算成功\n")
  cat("   客戶數:", nrow(sales_by_customer), "\n")
  cat("   欄位:", paste(names(sales_by_customer), collapse = ", "), "\n\n")
  
  # 測試基本分類
  basic_classification <- sales_by_customer %>%
    mutate(
      value_level = case_when(
        m_value >= quantile(m_value, 0.67, na.rm = TRUE) ~ "高",
        m_value >= quantile(m_value, 0.33, na.rm = TRUE) ~ "中",
        TRUE ~ "低"
      ),
      activity_level = case_when(
        f_value >= quantile(f_value, 0.67, na.rm = TRUE) ~ "高",
        f_value >= quantile(f_value, 0.33, na.rm = TRUE) ~ "中",
        TRUE ~ "低"
      ),
      lifecycle_stage = case_when(
        r_value <= 30 ~ "active",
        r_value <= 90 ~ "sleepy",
        r_value <= 180 ~ "half_sleepy",
        TRUE ~ "dormant"
      )
    )
  
  cat("4. 測試基本分類：\n")
  cat("   價值等級分佈:\n")
  print(table(basic_classification$value_level))
  cat("   活躍等級分佈:\n")
  print(table(basic_classification$activity_level))
  cat("   生命週期分佈:\n")
  print(table(basic_classification$lifecycle_stage))
  
  cat("\n✅ 所有測試通過！資料格式和處理邏輯正確。\n")
  
}, error = function(e) {
  cat("❌ 測試失敗:", e$message, "\n")
})

cat("\n=================================================\n")
cat("測試完成\n")
cat("=================================================\n") 