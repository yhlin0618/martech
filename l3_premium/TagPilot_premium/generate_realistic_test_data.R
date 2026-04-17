# 生成更真實的測試資料（包含新客）
# 目標：確保有真正的「新客」可以被正確識別

library(dplyr)
library(lubridate)

set.seed(42)  # 固定隨機種子以便重現

# 參數設定
n_customers <- 1000
date_range_days <- 730  # 2年資料
today <- Sys.Date()

# 生成不同類型的客戶
customer_profiles <- data.frame(
  customer_id = sprintf("CUST%04d", 1:n_customers),
  profile_type = sample(
    c("newbie", "active", "sleepy", "half_sleepy", "dormant"),
    n_customers,
    replace = TRUE,
    prob = c(0.15, 0.40, 0.20, 0.15, 0.10)  # 確保有15%新客
  )
)

# 為每種類型生成合適的交易記錄
transactions <- lapply(1:n_customers, function(i) {
  customer <- customer_profiles[i, ]

  if (customer$profile_type == "newbie") {
    # 新客：只買一次，且在最近30-60天內
    purchase_date <- today - sample(30:60, 1)
    data.frame(
      customer_id = customer$customer_id,
      transaction_date = purchase_date,
      transaction_amount = runif(1, 50, 500)
    )

  } else if (customer$profile_type == "active") {
    # 主力客：購買頻繁，最近7天內有購買
    n_purchases <- sample(5:20, 1)
    last_purchase <- today - sample(1:7, 1)
    purchase_dates <- sort(last_purchase - cumsum(rpois(n_purchases - 1, 15)), decreasing = TRUE)
    purchase_dates <- c(purchase_dates, last_purchase)

    data.frame(
      customer_id = customer$customer_id,
      transaction_date = purchase_dates,
      transaction_amount = runif(n_purchases, 100, 1000)
    )

  } else if (customer$profile_type == "sleepy") {
    # 瞌睡客：7-14天沒購買
    n_purchases <- sample(3:10, 1)
    last_purchase <- today - sample(8:14, 1)
    purchase_dates <- sort(last_purchase - cumsum(rpois(n_purchases - 1, 20)), decreasing = TRUE)
    purchase_dates <- c(purchase_dates, last_purchase)

    data.frame(
      customer_id = customer$customer_id,
      transaction_date = purchase_dates,
      transaction_amount = runif(n_purchases, 80, 800)
    )

  } else if (customer$profile_type == "half_sleepy") {
    # 半睡客：14-21天沒購買
    n_purchases <- sample(2:8, 1)
    last_purchase <- today - sample(15:21, 1)
    purchase_dates <- sort(last_purchase - cumsum(rpois(n_purchases - 1, 25)), decreasing = TRUE)
    purchase_dates <- c(purchase_dates, last_purchase)

    data.frame(
      customer_id = customer$customer_id,
      transaction_date = purchase_dates,
      transaction_amount = runif(n_purchases, 60, 600)
    )

  } else {  # dormant
    # 沉睡客：超過21天沒購買，或很久以前只買過一次
    if (runif(1) > 0.5) {
      # 類型A：很久以前只買過一次（不是新客）
      purchase_date <- today - sample(100:600, 1)
      data.frame(
        customer_id = customer$customer_id,
        transaction_date = purchase_date,
        transaction_amount = runif(1, 30, 300)
      )
    } else {
      # 類型B：曾經活躍但現在沉睡
      n_purchases <- sample(2:6, 1)
      last_purchase <- today - sample(30:180, 1)
      purchase_dates <- sort(last_purchase - cumsum(rpois(n_purchases - 1, 30)), decreasing = TRUE)
      purchase_dates <- c(purchase_dates, last_purchase)

      data.frame(
        customer_id = customer$customer_id,
        transaction_date = purchase_dates,
        transaction_amount = runif(n_purchases, 50, 500)
      )
    }
  }
}) %>% bind_rows()

# 確保日期在合理範圍內
transactions <- transactions %>%
  filter(transaction_date >= today - date_range_days) %>%
  arrange(customer_id, transaction_date)

# 加入交易ID
transactions <- transactions %>%
  mutate(transaction_id = sprintf("TXN%06d", row_number()))

# 顯示統計資訊
cat("=== 生成的測試資料統計 ===\n")
cat("總交易筆數:", nrow(transactions), "\n")
cat("客戶數:", length(unique(transactions$customer_id)), "\n")
cat("日期範圍:", min(transactions$transaction_date), "到", max(transactions$transaction_date), "\n\n")

# 快速驗證
quick_check <- transactions %>%
  group_by(customer_id) %>%
  summarise(
    n_transactions = n(),
    days_since_first = as.numeric(today - min(transaction_date)),
    days_since_last = as.numeric(today - max(transaction_date)),
    .groups = "drop"
  )

cat("購買次數分佈:\n")
print(table(quick_check$n_transactions))

cat("\n單次購買客戶中，最近購買天數分佈:\n")
single_purchase <- quick_check %>% filter(n_transactions == 1)
if (nrow(single_purchase) > 0) {
  cat("單次購買客戶數:", nrow(single_purchase), "\n")
  cat("距離首次購買天數範圍:", min(single_purchase$days_since_first), "-", max(single_purchase$days_since_first), "天\n")
  cat("30天內的單次購買客戶:", sum(single_purchase$days_since_first <= 30), "\n")
  cat("60天內的單次購買客戶:", sum(single_purchase$days_since_first <= 60), "\n")
  cat("100天內的單次購買客戶:", sum(single_purchase$days_since_first <= 100), "\n")
}

# 儲存資料
output_file <- "test_data/realistic_customer_data.csv"
dir.create("test_data", showWarnings = FALSE)
write.csv(transactions %>% select(customer_id, transaction_date, transaction_amount),
          output_file, row.names = FALSE)

cat("\n✅ 測試資料已儲存至:", output_file, "\n")
cat("請使用此資料檔上傳到應用程式進行測試\n")
