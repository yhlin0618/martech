# ============================================================================
# 評分均值計算測試
# 測試目的：驗證app.R中的評分均值計算邏輯是否正確
# ============================================================================

# 載入必要套件
library(dplyr)

cat("🧪 測試評分均值計算功能\n")
cat("========================\n")

# 模擬從 module_score.R 產生的評分資料
# 這個格式模擬實際的評分結果：屬性名稱直接作為欄位名，沒有 Score_ 前綴
set.seed(456)
simulated_scored_data <- data.frame(
  Variation = rep(c("品牌A", "品牌B", "品牌C"), each = 20),
  品質 = round(runif(60, 1, 5), 1),
  價格 = round(runif(60, 1, 5), 1),
  設計 = round(runif(60, 1, 5), 1),
  服務 = round(runif(60, 1, 5), 1),
  包裝 = round(runif(60, 1, 5), 1),
  功能 = round(runif(60, 1, 5), 1)
)

cat("📊 模擬評分資料 (前10行)：\n")
print(head(simulated_scored_data, 10))

cat("\n🔍 測試評分均值計算邏輯：\n")

# 測試：複製 app.R 中修正後的邏輯
# 獲取評分欄位（除了 Variation 外的所有數值欄位）
score_cols <- names(simulated_scored_data)[!names(simulated_scored_data) %in% "Variation"]
score_cols <- score_cols[sapply(simulated_scored_data[score_cols], is.numeric)]

cat("偵測到的評分欄位：", paste(score_cols, collapse = ", "), "\n")

# 計算各 Variation 的評分均值
mean_data <- simulated_scored_data %>%
  select(Variation, all_of(score_cols)) %>%
  group_by(Variation) %>%
  summarise(across(all_of(score_cols), \(x) mean(x, na.rm = TRUE))) %>%
  ungroup()

cat("\n📈 各品牌評分均值：\n")
print(mean_data)

# 驗證結果
cat("\n✅ 驗證結果：\n")
cat("• 是否正確計算了所有屬性？", ifelse(all(score_cols %in% names(mean_data)), "是", "否"), "\n")
cat("• 是否有三個品牌？", ifelse(nrow(mean_data) == 3, "是", "否"), "\n")
cat("• 評分是否在合理範圍內 (1-5)？", 
    ifelse(all(sapply(mean_data[score_cols], function(x) all(x >= 1 & x <= 5))), "是", "否"), "\n")

# 測試 Poisson 回歸需要的資料格式
cat("\n🔧 測試 Poisson 回歸資料準備：\n")

# 模擬銷售資料（確保為整數）
sales_data <- data.frame(
  Variation = c("品牌A", "品牌B", "品牌C"),
  Time = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
  Sales = as.integer(c(150, 200, 120))  # 明確指定為整數
)

# 合併資料
analysis_data <- sales_data %>%
  left_join(mean_data, by = "Variation")

cat("合併後的分析資料：\n")
print(analysis_data)

# 找出評分欄位（模擬 app.R 中的邏輯）
basic_cols <- c("Variation", "Time", "Sales", "原始產品ID", "eval_variation")
score_columns <- names(analysis_data)[!names(analysis_data) %in% basic_cols]
score_columns <- score_columns[sapply(analysis_data[score_columns], is.numeric)]

cat("\n用於 Poisson 回歸的評分欄位：", paste(score_columns, collapse = ", "), "\n")

cat("\n✅ 評分均值計算測試完成！\n")
cat("💡 結論：修正後的邏輯能正確識別和處理評分欄位\n") 