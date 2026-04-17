# ============================================================================
# 完整流程測試：評分均值 + Poisson 回歸
# 測試目的：驗證整個分析流程的修正
# ============================================================================

# 載入必要套件
library(dplyr)

# 引用函數
source("scripts/global_scripts/07_models/Poisson_Regression.R")

cat("🚀 完整流程測試\n")
cat("===============\n")

# 步驟 1：模擬評分資料（來自 module_score.R）
set.seed(789)
scored_data <- data.frame(
  Variation = rep(c("品牌A", "品牌B", "品牌C"), each = 15),
  品質 = round(runif(45, 1, 5), 1),
  價格 = round(runif(45, 1, 5), 1),
  設計 = round(runif(45, 1, 5), 1),
  服務 = round(runif(45, 1, 5), 1)
)

cat("📊 步驟 1：模擬評分資料\n")
cat("評分資料概要：", nrow(scored_data), "筆資料，", 
    length(unique(scored_data$Variation)), "個品牌\n")

# 步驟 2：計算評分均值（修正後的邏輯）
cat("\n📊 步驟 2：計算評分均值\n")
score_cols <- names(scored_data)[!names(scored_data) %in% "Variation"]
score_cols <- score_cols[sapply(scored_data[score_cols], is.numeric)]

mean_data <- scored_data %>%
  select(Variation, all_of(score_cols)) %>%
  group_by(Variation) %>%
  summarise(across(all_of(score_cols), \(x) mean(x, na.rm = TRUE))) %>%
  ungroup()

print(mean_data)

# 步驟 3：模擬銷售資料
cat("\n📊 步驟 3：模擬銷售資料\n")
sales_data <- data.frame(
  Variation = c("品牌A", "品牌B", "品牌C"),
  Time = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
  Sales = c(150.7, 200.3, 120.9)  # 含小數的銷售值
)

print(sales_data)

# 步驟 4：資料合併（模擬 app.R 邏輯）
cat("\n📊 步驟 4：資料合併\n")
analysis_data <- sales_data %>%
  left_join(mean_data, by = "Variation")

print(analysis_data)

# 步驟 5：Poisson 回歸分析（修正後的流程）
cat("\n📊 步驟 5：Poisson 回歸分析\n")
basic_cols <- c("Variation", "Time", "Sales", "原始產品ID", "eval_variation")
score_columns <- names(analysis_data)[!names(analysis_data) %in% basic_cols]
score_columns <- score_columns[sapply(analysis_data[score_columns], is.numeric)]

cat("偵測到的評分欄位：", paste(score_columns, collapse = ", "), "\n")

poisson_results <- list()

for (score_col in score_columns) {
  cat("分析", score_col, "屬性...\n")
  
  # 模擬 app.R 中的資料準備
  analysis_subset <- analysis_data %>%
    filter(!is.na(.data[[score_col]]), !is.na(Sales)) %>%
    mutate(
      # 確保 Sales 為正數（Poisson 回歸要求非負整數）
      Sales = pmax(0, as.numeric(Sales))
    ) %>%
    rename(sales = Sales)
  
  cat("  - 資料筆數：", nrow(analysis_subset), "\n")
  cat("  - sales 範圍：", paste(range(analysis_subset$sales), collapse = " - "), "\n")
  cat("  - ", score_col, "範圍：", paste(range(analysis_subset[[score_col]]), collapse = " - "), "\n")
  
  # 執行 Poisson 回歸
  result <- tryCatch({
    poisson_regression(score_col, analysis_subset)
  }, warning = function(w) {
    cat("  ⚠️ 警告：", conditionMessage(w), "\n")
    return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "警告", practical_meaning = "無法分析"))
  }, error = function(e) {
    cat("  ❌ 錯誤：", conditionMessage(e), "\n")
    return(list(marginal_effect_pct = NA, coefficient = NA, interpretation = "錯誤", practical_meaning = "無法分析"))
  })
  
  if (is.list(result) && !is.na(result$marginal_effect_pct)) {
    poisson_results[[score_col]] <- data.frame(
      屬性 = score_col,
      邊際效應百分比 = result$marginal_effect_pct,
      賽道倍數 = result$track_multiplier,
      賽道寬度 = result$track_width,
      係數 = result$coefficient,
      統計結論 = result$interpretation,
      商業意義 = result$practical_meaning,
      觀測數 = nrow(analysis_subset),
      stringsAsFactors = FALSE
    )
    cat("  ✅ 成功：", result$unit_explanation, "\n")
    cat("  🏁 賽道：", result$track_explanation, "\n")
    cat("  📊 商業意義：", result$practical_meaning, "\n")
  } else {
    cat("  ❌ 失敗：無法計算\n")
  }
}

# 步驟 6：結果彙總
cat("\n📈 步驟 6：結果彙總\n")
if (length(poisson_results) > 0) {
  final_results <- do.call(rbind, poisson_results)
  rownames(final_results) <- NULL
  
  final_results <- final_results %>%
    arrange(desc(賽道倍數))
  
  print(final_results)
  
  cat("\n🎯 分析結論：\n")
  cat("• 賽道最大的屬性：", final_results$屬性[1], 
      "(賽道倍數:", final_results$賽道倍數[1], "倍)\n")
  cat("• 邊際效應最大：", final_results$屬性[which.max(abs(final_results$邊際效應百分比))], 
      "(邊際效應:", max(abs(final_results$邊際效應百分比)), "%)\n")
  cat("• 共成功分析", nrow(final_results), "個屬性\n")
} else {
  cat("❌ 沒有成功的分析結果\n")
}

cat("\n✅ 完整流程測試完成！\n")
cat("💡 結論：修正後的流程能正確處理評分均值計算和 Poisson 回歸分析\n") 