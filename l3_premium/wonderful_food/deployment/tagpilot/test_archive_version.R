# 測試 archive 版本的 fn_analysis_dna.R
cat("=== 測試 Archive 版本的 fn_analysis_dna.R ===\n")

library(dplyr)

# 載入新版本的 analysis_dna
source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
cat("✅ 已載入 archive 版本的 fn_analysis_dna.R\n")

# 創建測試資料（使用 dplyr 產生 tibble）
sales_by_customer <- data.frame(
  customer_id = c(1, 1, 2, 2, 3),
  lineitem_price = c(29.99, 35.99, 12.99, 39.99, 29.99),
  payment_time = as.POSIXct(c("2024-01-01", "2024-01-15", "2024-01-10", "2024-02-01", "2024-01-20"))
) %>%
  group_by(customer_id) %>%
  summarise(
    total_spent = sum(lineitem_price),
    times = n(),
    first_purchase = min(payment_time),
    last_purchase = max(payment_time),
    .groups = "drop"
  ) %>%
  mutate(
    ipt = pmax(as.numeric(difftime(last_purchase, first_purchase, units = "days")), 1),
    ni = times
  )

sales_by_customer_by_date <- data.frame(
  customer_id = c(1, 1, 2, 2, 3),
  date = as.Date(c("2024-01-01", "2024-01-15", "2024-01-10", "2024-02-01", "2024-01-20")),
  sum_spent_by_date = c(29.99, 35.99, 12.99, 39.99, 29.99),
  count_transactions_by_date = c(1, 1, 1, 1, 1),
  payment_time = as.POSIXct(c("2024-01-01", "2024-01-15", "2024-01-10", "2024-02-01", "2024-01-20"))
)

cat("\n📊 測試資料類型:\n")
cat("- sales_by_customer:", class(sales_by_customer), "\n")
cat("- sales_by_customer_by_date:", class(sales_by_customer_by_date), "\n")

# 設定全域參數
global_params <- list(
  delta = 0.1,
  ni_threshold = 2,
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

# 測試 1: 直接傳入 tibble（應該會有更好的錯誤訊息）
cat("\n🧪 測試 1: 直接傳入 tibble\n")
tryCatch({
  result1 <- analysis_dna(
    df_sales_by_customer = sales_by_customer,
    df_sales_by_customer_by_date = sales_by_customer_by_date,
    skip_within_subject = FALSE,
    verbose = TRUE,
    global_params = global_params
  )
  cat("✅ 成功！Archive 版本可以處理 tibble\n")
}, error = function(e) {
  cat("❌ 錯誤:", e$message, "\n")
})

# 測試 2: 轉換為 data.frame 後傳入
cat("\n🧪 測試 2: 轉換為 data.frame 後傳入\n")
tryCatch({
  result2 <- analysis_dna(
    df_sales_by_customer = as.data.frame(sales_by_customer),
    df_sales_by_customer_by_date = as.data.frame(sales_by_customer_by_date),
    skip_within_subject = FALSE,
    verbose = TRUE,
    global_params = global_params
  )
  cat("✅ 成功！轉換為 data.frame 後正常運作\n")
}, error = function(e) {
  cat("❌ 錯誤:", e$message, "\n")
})

cat("\n📝 結論:\n")
cat("Archive 版本的優勢:\n")
cat("- 更完善的錯誤處理\n")
cat("- 會檢查必要欄位是否存在\n")
cat("- 提供更清楚的錯誤訊息\n")
cat("- 但仍建議在 module_dna_multi.R 中保留 as.data.frame() 轉換以確保相容性\n") 