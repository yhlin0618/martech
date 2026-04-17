# 測試新客判斷邏輯
# 此腳本獨立於 Shiny app，直接測試新客邏輯

library(dplyr)
library(lubridate)

# 載入測試資料（使用新的真實資料）
test_data <- read.csv("test_data/realistic_customer_data.csv", stringsAsFactors = FALSE)
test_data$transaction_date <- as.Date(test_data$transaction_date)

cat("\n=== 測試資料摘要 ===\n")
cat("總交易筆數:", nrow(test_data), "\n")
cat("客戶數:", length(unique(test_data$customer_id)), "\n")
cat("日期範圍:", min(test_data$transaction_date), "到", max(test_data$transaction_date), "\n\n")

# 計算每位客戶的統計指標（模擬 DNA 分析）
customer_summary <- test_data %>%
  group_by(customer_id) %>%
  summarise(
    ni = n(),  # 購買次數
    m_value = sum(transaction_amount),  # 總消費金額
    first_purchase_date = min(transaction_date),
    last_purchase_date = max(transaction_date),
    r_value = as.numeric(Sys.Date() - max(transaction_date)),  # Recency
    .groups = "drop"
  ) %>%
  mutate(
    # 計算客戶年齡（天數）
    customer_age_days = as.numeric(Sys.Date() - first_purchase_date),

    # 計算 IPT（購買間隔時間）
    ipt_value = if_else(ni > 1,
                        customer_age_days / (ni - 1),
                        customer_age_days)
  )

# 計算平均 IPT（使用中位數）
avg_ipt <- median(customer_summary$ipt_value, na.rm = TRUE)

cat("=== 關鍵統計指標 ===\n")
cat("平均購買週期 (avg_ipt - 中位數):", round(avg_ipt, 2), "天\n\n")

# 判斷新客
customer_summary <- customer_summary %>%
  mutate(
    lifecycle_stage = case_when(
      is.na(r_value) ~ "unknown",
      # 新客：只買一次 + 60天內首次購買（GAP-001修復）
      ni == 1 & customer_age_days <= 60 ~ "newbie",
      # 主力客：R值 <= 7天
      r_value <= 7 ~ "active",
      # 瞌睡客：7 < R <= 14
      r_value <= 14 ~ "sleepy",
      # 半睡客：14 < R <= 21
      r_value <= 21 ~ "half_sleepy",
      # 沉睡客：R > 21 或 單次購買但超過平均週期
      TRUE ~ "dormant"
    )
  )

# 顯示除錯資訊
cat("=== 新客判斷除錯資訊 ===\n")
cat("總客戶數:", nrow(customer_summary), "\n")
cat("單次購買客戶數 (ni==1):", sum(customer_summary$ni == 1, na.rm = TRUE), "\n")

newbie_candidates <- customer_summary %>% filter(ni == 1)
if (nrow(newbie_candidates) > 0) {
  cat("\n單次購買客戶統計:\n")
  cat("  客戶數:", nrow(newbie_candidates), "\n")
  cat("  customer_age_days 範圍:",
      round(min(newbie_candidates$customer_age_days, na.rm = TRUE), 2), "-",
      round(max(newbie_candidates$customer_age_days, na.rm = TRUE), 2), "天\n")
  cat("  平均 customer_age_days:", round(mean(newbie_candidates$customer_age_days, na.rm = TRUE), 2), "天\n")
  cat("  中位數 customer_age_days:", round(median(newbie_candidates$customer_age_days, na.rm = TRUE), 2), "天\n")

  cat("\n符合新客條件 (ni==1 & customer_age_days <= 60):\n")
  newbie_count <- sum(newbie_candidates$customer_age_days <= 60, na.rm = TRUE)
  cat("  客戶數:", newbie_count, "\n")
  cat("  百分比:", round(newbie_count / nrow(customer_summary) * 100, 2), "%\n")

  # 顯示前 10 位單次購買客戶的詳細資訊
  cat("\n前 10 位單次購買客戶詳情:\n")
  print(head(newbie_candidates %>%
               select(customer_id, ni, customer_age_days, r_value, lifecycle_stage) %>%
               arrange(customer_age_days), 10))
}

cat("\n各生命週期階段分佈:\n")
lifecycle_dist <- customer_summary %>%
  group_by(lifecycle_stage) %>%
  summarise(count = n(), percentage = round(n() / nrow(customer_summary) * 100, 2))
print(lifecycle_dist)

cat("\n=== 診斷結論 ===\n")
if (sum(customer_summary$lifecycle_stage == "newbie", na.rm = TRUE) == 0) {
  cat("⚠️ 問題：沒有客戶被判定為新客！\n\n")
  cat("可能原因:\n")
  cat("1. 所有單次購買客戶的 customer_age_days > avg_ipt\n")
  cat("   - 即：所有只買過一次的客戶，距離首次購買的時間都超過平均購買週期\n")
  cat("   - 這表示他們都是「很久以前」買過一次後就再也沒回購的客戶\n\n")
  cat("2. 測試資料特性:\n")
  cat("   - 平均購買週期:", round(avg_ipt, 2), "天\n")
  cat("   - 最年輕的單次購買客戶:",
      if(nrow(newbie_candidates) > 0) round(min(newbie_candidates$customer_age_days), 2) else "N/A", "天\n")
  cat("   - 如果最年輕的單次購買客戶都 >", round(avg_ipt, 2), "天，則沒有客戶符合新客條件\n\n")
  cat("建議解決方案:\n")
  cat("1. 放寬新客定義（例如：1.5 倍或 2 倍 avg_ipt）\n")
  cat("2. 使用固定時間窗口（例如：30天或60天）\n")
  cat("3. 使用更符合實際業務的測試資料\n")
} else {
  cat("✅ 新客判斷正常運作\n")
  cat("新客數量:", sum(customer_summary$lifecycle_stage == "newbie", na.rm = TRUE), "\n")
}

cat("\n========================\n")
