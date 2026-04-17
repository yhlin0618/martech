# ============================================================================
# Poisson 回歸 Debug 測試
# 測試目的：驗證 Sales 資料格式問題的修正
# ============================================================================

# 載入必要套件
library(dplyr)

# 引用修正後的 Poisson regression 函數
source("scripts/global_scripts/07_models/Poisson_Regression.R")

cat("🐛 Poisson 回歸 Debug 測試\n")
cat("==========================\n")

# 測試 1：模擬產生警告的情況（小數 sales 值）
cat("📊 測試 1：小數銷售值（會觸發警告的情況）\n")
problematic_data <- data.frame(
  品質 = c(3.5, 4.2, 2.8, 4.1),
  sales = c(2.07, 2.58, 1.64, 2.96)  # 這些小數值會觸發 dpois 警告
)

cat("原始問題資料：\n")
print(problematic_data)

# 測試修正後的函數
result1 <- tryCatch({
  poisson_regression("品質", problematic_data)
}, warning = function(w) {
  cat("⚠️ 警告：", conditionMessage(w), "\n")
  return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "警告", practical_meaning = "無法分析"))
}, error = function(e) {
  cat("❌ 錯誤：", conditionMessage(e), "\n")
  return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "錯誤", practical_meaning = "無法分析"))
})

if (is.list(result1)) {
  cat("修正後結果：", result1$unit_explanation, "\n")
  cat("商業意義：", result1$practical_meaning, "\n\n")
} else {
  cat("修正後結果：無法分析\n\n")
}

# 測試 2：正確的整數銷售資料
cat("📊 測試 2：正確的整數銷售資料\n")
correct_data <- data.frame(
  品質 = c(3.5, 4.2, 2.8, 4.1, 3.0, 4.5),
  價格 = c(2.1, 3.8, 4.2, 2.9, 3.5, 4.0),
  sales = as.integer(c(150, 200, 80, 180, 120, 220))  # 整數銷售資料
)

cat("正確格式資料：\n")
print(correct_data)

result2 <- tryCatch({
  poisson_regression("品質", correct_data)
}, warning = function(w) {
  cat("⚠️ 警告：", conditionMessage(w), "\n")
  return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "警告", practical_meaning = "無法分析"))
}, error = function(e) {
  cat("❌ 錯誤：", conditionMessage(e), "\n")
  return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "錯誤", practical_meaning = "無法分析"))
})

cat("品質屬性結果：", result2$unit_explanation, "\n")
cat("品質商業意義：", result2$practical_meaning, "\n")

result3 <- tryCatch({
  poisson_regression("價格", correct_data)
}, warning = function(w) {
  cat("⚠️ 警告：", conditionMessage(w), "\n")
  return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "警告", practical_meaning = "無法分析"))
}, error = function(e) {
  cat("❌ 錯誤：", conditionMessage(e), "\n")
  return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "錯誤", practical_meaning = "無法分析"))
})

cat("價格屬性結果：", result3$unit_explanation, "\n")
cat("價格商業意義：", result3$practical_meaning, "\n\n")

# 測試 3：模擬 app.R 中的資料轉換流程
cat("📊 測試 3：模擬 app.R 資料轉換流程\n")
app_simulation_data <- data.frame(
  Variation = c("品牌A", "品牌B", "品牌C"),
  Sales = c(150.7, 200.3, 120.9),  # 模擬可能的小數銷售值
  品質 = c(3.2, 4.1, 2.8),
  價格 = c(3.5, 2.9, 4.2)
)

cat("模擬 app.R 原始資料：\n")
print(app_simulation_data)

# 模擬 app.R 中的資料轉換
analysis_subset <- app_simulation_data %>%
  filter(!is.na(品質), !is.na(Sales)) %>%
  mutate(
    # 確保 Sales 為正數（Poisson 回歸要求非負整數）
    Sales = pmax(0, as.numeric(Sales))
  ) %>%
  rename(sales = Sales)

cat("app.R 轉換後資料：\n")
print(analysis_subset)

result4 <- tryCatch({
  poisson_regression("品質", analysis_subset)
}, warning = function(w) {
  cat("⚠️ 警告：", conditionMessage(w), "\n")
  return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "警告", practical_meaning = "無法分析"))
}, error = function(e) {
  cat("❌ 錯誤：", conditionMessage(e), "\n")
  return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "錯誤", practical_meaning = "無法分析"))
})

cat("app.R 流程結果：", result4$unit_explanation, "\n")
cat("app.R 商業意義：", result4$practical_meaning, "\n\n")

# 驗證資料類型
cat("🔍 資料類型驗證：\n")
cat("• analysis_subset$sales 類型：", class(analysis_subset$sales), "\n")
cat("• analysis_subset$sales 是否為整數：", all(analysis_subset$sales == round(analysis_subset$sales)), "\n")
cat("• analysis_subset$sales 範圍：", paste(range(analysis_subset$sales), collapse = " - "), "\n")

cat("\n✅ Poisson 回歸 Debug 測試完成！\n")
cat("💡 結論：修正後的函數應該能處理小數銷售值並避免 dpois 警告\n") 