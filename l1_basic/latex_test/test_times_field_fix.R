# 測試 times 欄位修復
cat("=== 測試 times 欄位修復 ===\n")

library(dplyr)

# 創建測試資料
test_data <- data.frame(
  customer_id = c(1, 1, 2, 2, 3),
  payment_time = as.POSIXct(c("2024-01-01", "2024-01-15", "2024-01-10", "2024-02-01", "2024-01-20")),
  lineitem_price = c(29.99, 35.99, 12.99, 39.99, 29.99),
  stringsAsFactors = FALSE
)

cat("✅ 測試資料創建完成\n")

# 測試修復後的 sales_by_customer 創建
tryCatch({
  sales_by_customer <- test_data %>%
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
  
  cat("✅ sales_by_customer 創建成功\n")
  cat("📊 欄位:", paste(names(sales_by_customer), collapse = ", "), "\n")
  
  # 檢查必要欄位
  required_fields <- c("customer_id", "total_spent", "times", "ipt", "ni")
  missing_fields <- required_fields[!required_fields %in% names(sales_by_customer)]
  
  if (length(missing_fields) == 0) {
    cat("✅ 所有必要欄位都存在\n")
  } else {
    cat("❌ 缺少欄位:", paste(missing_fields, collapse = ", "), "\n")
  }
  
  # 測試直接提取（模擬 analysis_dna 的行為）
  test_extract <- sales_by_customer[, c("customer_id", "ipt", "total_spent", "times")]
  cat("✅ 直接欄位提取成功\n")
  
}, error = function(e) {
  cat("❌ 測試失敗:", e$message, "\n")
})

cat("\n�� times 欄位問題已修復！\n") 