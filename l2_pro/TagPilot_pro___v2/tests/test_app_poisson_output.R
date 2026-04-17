# ============================================================================
# App.R Poisson 輸出格式測試
# 測試目的：驗證 app.R 中新版 Poisson 回歸輸出是否正確顯示
# ============================================================================

# 載入必要套件
library(dplyr)

# 引用新版 Poisson regression 函數
source("scripts/global_scripts/07_models/Poisson_Regression.R")

cat("🧪 測試 App.R 新版 Poisson 輸出格式\n")
cat("====================================\n")

# 模擬 app.R 中的分析流程
set.seed(456)

# 模擬評分資料
scored_data <- data.frame(
  Variation = rep(c("品牌A", "品牌B", "品牌C"), each = 10),
  品質 = round(runif(30, 1, 5), 1),
  價格 = round(runif(30, 1, 5), 1),
  設計 = round(runif(30, 1, 5), 1),
  服務 = round(runif(30, 1, 5), 1)
)

# 計算評分均值（模擬 app.R 邏輯）
score_cols <- names(scored_data)[!names(scored_data) %in% "Variation"]
score_cols <- score_cols[sapply(scored_data[score_cols], is.numeric)]

mean_data <- scored_data %>%
  select(Variation, all_of(score_cols)) %>%
  group_by(Variation) %>%
  summarise(across(all_of(score_cols), \(x) mean(x, na.rm = TRUE))) %>%
  ungroup()

# 模擬銷售資料
sales_data <- data.frame(
  Variation = c("品牌A", "品牌B", "品牌C"),
  Time = as.Date(c("2024-01-01", "2024-01-02", "2024-01-03")),
  Sales = c(150.7, 200.3, 120.9)
)

# 合併資料（模擬 app.R 合併邏輯）
analysis_data <- sales_data %>%
  left_join(mean_data, by = "Variation") %>%
  filter(!is.na(Sales))

cat("📊 合併後的分析資料：\n")
print(analysis_data)

# 模擬 app.R 中的 Poisson 回歸分析
cat("\n🔍 執行 Poisson 回歸分析...\n")

basic_cols <- c("Variation", "Time", "Sales", "原始產品ID", "eval_variation")
score_columns <- names(analysis_data)[!names(analysis_data) %in% basic_cols]
score_columns <- score_columns[sapply(analysis_data[score_columns], is.numeric)]

poisson_results <- list()

for (score_col in score_columns) {
  # 模擬 app.R 中的資料準備
  analysis_subset <- analysis_data %>%
    filter(!is.na(.data[[score_col]]), !is.na(Sales)) %>%
    mutate(
      # 確保 Sales 為正數（Poisson 回歸要求非負整數）
      Sales = pmax(0, as.numeric(Sales))
    ) %>%
    rename(sales = Sales)
  
  if (nrow(analysis_subset) >= 3) {  # 降低觀測值要求以便測試
    result <- tryCatch({
      poisson_regression(score_col, analysis_subset)
    }, error = function(e) {
      list(marginal_effect_pct = NA, track_multiplier = NA, interpretation = "錯誤", practical_meaning = "無法分析")
    })
    
    # 解析結果（新版函數返回 list 格式）
    if (is.list(result) && !is.na(result$marginal_effect_pct)) {
      poisson_results[[score_col]] <- data.frame(
        屬性 = score_col,
        邊際效應百分比 = result$marginal_effect_pct,
        賽道倍數 = result$track_multiplier,
        係數 = result$coefficient,
        統計結論 = result$interpretation,
        商業意義 = result$practical_meaning,
        觀測數 = nrow(analysis_subset),
        stringsAsFactors = FALSE
      )
      
      cat("✅ ", score_col, " 分析成功\n")
      cat("   邊際效應: ", result$marginal_effect_pct, "%\n")
      cat("   賽道倍數: ", result$track_multiplier, "倍\n")
      cat("   商業意義: ", result$practical_meaning, "\n")
    } else {
      cat("❌ ", score_col, " 分析失敗\n")
    }
  }
}

# 模擬 app.R 中的結果處理
if (length(poisson_results) > 0) {
  cat("\n📈 最終分析結果：\n")
  
  # 合併結果
  final_results <- do.call(rbind, poisson_results)
  rownames(final_results) <- NULL
  
  # 按賽道倍數排序（主要指標）
  final_results <- final_results %>%
    arrange(desc(賽道倍數))
  
  print(final_results)
  
  # 生成新版解讀（模擬 app.R 中的解讀邏輯）
  top_track_attr <- final_results$屬性[1]
  top_track_multiplier <- final_results$賽道倍數[1]
  top_marginal_idx <- which.max(abs(final_results$邊際效應百分比))
  top_marginal_attr <- final_results$屬性[top_marginal_idx]
  top_marginal_effect <- final_results$邊際效應百分比[top_marginal_idx]
  
  interpretation <- paste0(
    "🎯 產品屬性影響力分析報告\n\n",
    "📊 分析概要：\n",
    "• 成功分析了 ", nrow(final_results), " 個評分屬性\n\n",
    
    "🏁 賽道冠軍（戰略重點）：\n",
    "• ", top_track_attr, " - 賽道倍數 ", top_track_multiplier, " 倍\n",
    "• 意義：從最低到最高的總體影響潛力最大\n",
    "• 建議：適合制定長期戰略改進計劃\n\n",
    
    "⚡ 邊際效應冠軍（日常優化）：\n",
    "• ", top_marginal_attr, " - 每提升1單位影響 ", abs(top_marginal_effect), "%\n",
    "• 意義：小幅改進就能看到明顯效果\n",
    "• 建議：適合日常運營的快速優化\n\n",
    
    "📈 決策指南：\n",
    "• 賽道倍數 > 2.0：極重要因素，核心競爭力\n",
    "• 賽道倍數 1.2-2.0：重要影響因素，應重點關注\n",
    "• 邊際效應 > 50%：強烈影響，小改進大效果\n",
    "• 邊際效應 20-50%：中等影響，穩定改進策略\n\n",
    "💡 行動建議：結合賽道倍數和邊際效應，制定「戰略+戰術」雙重優化策略"
  )
  
  cat("\n", interpretation, "\n")
  
} else {
  cat("\n❌ 沒有成功的分析結果\n")
}

cat("\n✅ App.R Poisson 輸出格式測試完成！\n")
cat("💡 結論：新版輸出格式更易理解，提供戰略和戰術雙重建議\n") 