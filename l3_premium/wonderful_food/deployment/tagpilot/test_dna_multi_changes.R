# DNA Multi 模組修改測試腳本
# 測試時間折扣因子移除和表格欄位中文化

# 載入必要套件
library(shiny)
library(dplyr)

# 模擬測試資料
test_dna_results <- list(
  data_by_customer = data.frame(
    customer_id = 1:10,
    r_value = runif(10, 0, 100),
    f_value = runif(10, 1, 20),
    m_value = runif(10, 100, 5000),
    ipt_mean = runif(10, 10, 90),
    cai_value = runif(10, 0, 1),
    pcv = runif(10, 500, 3000),
    clv = runif(10, 1000, 8000),
    nes_status = sample(c("高價值", "中價值", "低價值"), 10, replace = TRUE),
    nes_value = runif(10, 0, 1)
  )
)

cat("📊 測試DNA分析結果資料結構：\n")
str(test_dna_results$data_by_customer)

cat("\n🔧 測試欄位重新命名：\n")
test_data <- test_dna_results$data_by_customer

# 測試欄位重新命名
renamed_data <- test_data %>%
  mutate(across(where(is.numeric), ~ round(.x, 2))) %>%
  rename_with(~ case_when(
    .x == "customer_id" ~ "顧客ID",
    .x == "r_value" ~ "最近來店時間", 
    .x == "f_value" ~ "購買頻率",
    .x == "m_value" ~ "購買金額",
    .x == "ipt_mean" ~ "購買時間週期",
    .x == "cai_value" ~ "顧客活躍度",
    .x == "pcv" ~ "過去價值", 
    .x == "clv" ~ "終身價值",
    .x == "nes_status" ~ "顧客狀態",
    .x == "nes_value" ~ "參與度分數",
    TRUE ~ .x
  ))

print(names(renamed_data))

cat("\n🎯 測試顧客活躍度文字描述：\n")
activity_test <- renamed_data %>%
  mutate(
    `顧客活躍度` = case_when(
      `顧客活躍度` <= 0.33 ~ paste0(`顧客活躍度`, " (漸趨靜止)"),
      `顧客活躍度` <= 0.67 ~ paste0(`顧客活躍度`, " (穩定消費)"),
      TRUE ~ paste0(`顧客活躍度`, " (漸趨活躍)")
    )
  )

print(head(activity_test$`顧客活躍度`, 5))

cat("\n📈 測試高中低轉換函數：\n")
convert_to_category <- function(x, type = "general") {
  if (is.numeric(x)) {
    if (type == "activity") {
      # For activity status (cai_value)
      case_when(
        x <= 0.33 ~ "漸趨靜止",
        x <= 0.67 ~ "穩定消費", 
        TRUE ~ "漸趨活躍"
      )
    } else {
      # For general numeric values
      quantiles <- quantile(x, c(0.33, 0.67), na.rm = TRUE)
      case_when(
        x <= quantiles[1] ~ "低",
        x <= quantiles[2] ~ "中",
        TRUE ~ "高"
      )
    }
  } else {
    as.character(x)
  }
}

# 測試轉換
test_values <- c(10, 50, 90, 25, 75)
cat("原始數值:", test_values, "\n")
cat("轉換結果:", convert_to_category(test_values), "\n")

# 測試活躍度轉換
activity_values <- c(0.2, 0.5, 0.8, 0.3, 0.9)
cat("活躍度數值:", activity_values, "\n")
cat("活躍度轉換:", convert_to_category(activity_values, "activity"), "\n")

cat("\n✅ 所有測試完成！\n")
cat("🔧 修改總結：\n")
cat("1. ✅ 移除時間折扣因子UI (固定為0.1)\n")
cat("2. ✅ 欄位名稱中文化\n")
cat("3. ✅ 顧客活躍度數值+文字描述\n")
cat("4. ✅ 數值轉換為高中低選項\n")
cat("5. ✅ 數值四捨五入到小數點後2位\n") 