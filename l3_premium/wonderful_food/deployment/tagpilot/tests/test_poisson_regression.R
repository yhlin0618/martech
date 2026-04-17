# ============================================================================
# Poisson Regression 功能測試
# ============================================================================

# 載入必要套件
library(dplyr)

# 引用 global_scripts 中的 Poisson regression 函數
source("scripts/global_scripts/07_models/Poisson_Regression.R")

# 創建測試資料
set.seed(123)
n <- 100

# 模擬評分資料
test_data <- data.frame(
  Variation = rep(c("品牌A", "品牌B", "品牌C"), length.out = n),
  Score_品質 = rnorm(n, mean = 7, sd = 1.5),
  Score_價格 = rnorm(n, mean = 6, sd = 2),
  Score_設計 = rnorm(n, mean = 8, sd = 1),
  # 使用 Poisson 分佈模擬銷售資料，讓它與評分有關聯
  sales = rpois(n, lambda = exp(1 + 0.3 * rnorm(n, mean = 7, sd = 1.5)))
)

cat("🧪 測試 Poisson Regression 功能\n")
cat("===============================\n")

# 測試 1：基本功能測試
cat("📊 測試 1：品質評分對銷售的影響\n")
result_quality <- poisson_regression("Score_品質", test_data)
cat("影響程度：", result_quality$unit_explanation, "\n")
cat("賽道效應：", result_quality$track_explanation, "\n")
cat("商業意義：", result_quality$practical_meaning, "\n")

# 測試 2：價格評分對銷售的影響
cat("📊 測試 2：價格評分對銷售的影響\n")
result_price <- poisson_regression("Score_價格", test_data)
cat("影響程度：", result_price$unit_explanation, "\n")
cat("賽道效應：", result_price$track_explanation, "\n")
cat("商業意義：", result_price$practical_meaning, "\n")

# 測試 3：設計評分對銷售的影響
cat("📊 測試 3：設計評分對銷售的影響\n")
result_design <- poisson_regression("Score_設計", test_data)
cat("影響程度：", result_design$unit_explanation, "\n")
cat("賽道效應：", result_design$track_explanation, "\n")
cat("商業意義：", result_design$practical_meaning, "\n")

# 測試 4：組合所有結果
cat("\n📈 組合分析結果：\n")
all_results <- data.frame(
  屬性 = c("品質", "價格", "設計"),
  邊際效應百分比 = c(result_quality$marginal_effect_pct, result_price$marginal_effect_pct, result_design$marginal_effect_pct),
  賽道倍數 = c(result_quality$track_multiplier, result_price$track_multiplier, result_design$track_multiplier),
  係數 = c(result_quality$coefficient, result_price$coefficient, result_design$coefficient),
  商業意義 = c(result_quality$practical_meaning, result_price$practical_meaning, result_design$practical_meaning)
) %>%
  arrange(desc(賽道倍數))

print(all_results)

cat("\n✅ Poisson Regression 測試完成！\n")
if (!is.na(all_results$賽道倍數[1])) {
  cat("💡 建議：重點改善「", all_results$屬性[1], "」屬性，賽道倍數最大 (", all_results$賽道倍數[1], "倍)\n")
  cat("💡 邊際效應最大的是「", all_results$屬性[which.max(abs(all_results$邊際效應百分比))], "」(", max(abs(all_results$邊際效應百分比)), "%)\n")
} else {
  cat("💡 建議：需要更多資料進行分析\n")
} 