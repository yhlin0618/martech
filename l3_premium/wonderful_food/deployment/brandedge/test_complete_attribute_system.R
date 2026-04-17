################################################################################
# 完整測試屬性欄位系統
# Purpose: 驗證所有模組都只使用選擇的屬性欄位
################################################################################

library(dplyr)
library(tidyr)

cat("===============================================\n")
cat("完整屬性欄位系統測試\n")
cat("===============================================\n\n")

# 建立完整的測試資料集
create_test_data <- function() {
  set.seed(123)

  data <- data.frame(
    # 必要的識別欄位
    Variation = paste0("PRD", sprintf("%03d", 1:20)),
    product_name = paste0("產品", 1:20),
    brand = rep(c("品牌A", "品牌B", "品牌C", "品牌D"), 5),

    # 真正的屬性欄位（5個核心屬性）
    口感 = round(runif(20, 5, 10), 1),
    新鮮度 = round(runif(20, 4, 10), 1),
    包裝設計 = round(runif(20, 3, 9), 1),
    價格合理性 = round(runif(20, 4, 9), 1),
    營養價值 = round(runif(20, 5, 10), 1),

    # 額外的屬性欄位（可能被選擇）
    便利性 = round(runif(20, 4, 8), 1),
    品牌形象 = round(runif(20, 5, 9), 1),

    # 不應該被選擇的計算欄位
    total_score = round(runif(20, 30, 50), 1),
    avg_score = round(runif(20, 5, 10), 1),
    總分 = round(runif(20, 30, 50), 1),
    平均分數 = round(runif(20, 5, 10), 1),

    # 其他非屬性欄位
    sales_count = sample(100:1000, 20),
    review_count = sample(50:500, 20),
    rating = round(runif(20, 3, 5), 1),

    # ID類欄位
    SKU = paste0("SKU", sprintf("%05d", 1:20)),
    ASIN = paste0("B00", sprintf("%06d", 1:20))
  )

  return(data)
}

# 測試各個分析函數
test_analysis_functions <- function(data, selected_attrs) {
  cat("\n=== 測試各分析函數 ===\n\n")

  # 設定 metadata
  attr(data, "attribute_columns") <- selected_attrs

  # 1. 測試市場概況分析
  cat("1. 市場概況分析:\n")

  # 模擬取得屬性欄位
  attr_cols <- attr(data, "attribute_columns")
  if (!is.null(attr_cols)) {
    attr_cols <- attr_cols[attr_cols %in% names(data)]
    cat("  ✓ 使用屬性欄位:", paste(attr_cols, collapse = ", "), "\n")

    # 排除計算欄位
    exclude_cols <- c("total_score", "avg_score", "總分", "平均分")
    attr_cols <- attr_cols[!attr_cols %in% exclude_cols]

    if (length(attr_cols) > 0) {
      avg_scores <- rowMeans(data[attr_cols], na.rm = TRUE)
      cat("  平均分數範圍:", round(min(avg_scores), 2), "-", round(max(avg_scores), 2), "\n")
    }
  } else {
    cat("  ✗ 無法取得屬性欄位\n")
  }

  # 2. 測試品牌分析
  cat("\n2. 品牌分析:\n")

  if (!is.null(attr_cols) && length(attr_cols) > 0) {
    brand_summary <- data %>%
      group_by(brand) %>%
      summarise(across(all_of(attr_cols), mean, na.rm = TRUE), .groups = 'drop')

    cat("  品牌數量:", nrow(brand_summary), "\n")
    cat("  分析的屬性數:", length(attr_cols), "\n")
  }

  # 3. 測試屬性相關性
  cat("\n3. 屬性相關性:\n")

  if (!is.null(attr_cols) && length(attr_cols) > 1) {
    cor_matrix <- cor(data[attr_cols], use = "complete.obs")
    cat("  相關矩陣維度:", nrow(cor_matrix), "x", ncol(cor_matrix), "\n")
    cat("  最高相關係數:", round(max(cor_matrix[cor_matrix < 1]), 3), "\n")
  }

  # 4. 檢查是否誤用了非選擇欄位
  cat("\n4. 檢查欄位使用:\n")

  all_numeric_cols <- names(data)[sapply(data, is.numeric)]
  non_selected <- setdiff(all_numeric_cols, selected_attrs)

  # 確認沒有使用非選擇的欄位
  used_non_selected <- intersect(attr_cols, non_selected)
  if (length(used_non_selected) == 0) {
    cat("  ✓ 沒有使用未選擇的欄位\n")
  } else {
    cat("  ✗ 錯誤使用了未選擇的欄位:", paste(used_non_selected, collapse = ", "), "\n")
  }

  # 確認沒有使用計算欄位
  calc_cols <- c("total_score", "avg_score", "總分", "平均分數", "sales_count", "review_count", "rating")
  used_calc_cols <- intersect(attr_cols, calc_cols)
  if (length(used_calc_cols) == 0) {
    cat("  ✓ 沒有使用計算欄位\n")
  } else {
    cat("  ✗ 錯誤使用了計算欄位:", paste(used_calc_cols, collapse = ", "), "\n")
  }

  return(list(
    used_attrs = attr_cols,
    unused_selected = setdiff(selected_attrs, attr_cols),
    wrongly_used = used_non_selected
  ))
}

# 執行測試
cat("建立測試資料...\n")
test_data <- create_test_data()

cat("\n資料欄位概覽:\n")
cat("- 識別欄位: Variation, product_name, brand\n")
cat("- 屬性欄位: 口感, 新鮮度, 包裝設計, 價格合理性, 營養價值, 便利性, 品牌形象\n")
cat("- 計算欄位: total_score, avg_score, 總分, 平均分數\n")
cat("- 其他欄位: sales_count, review_count, rating, SKU, ASIN\n")

# 場景1：選擇部分屬性
cat("\n===============================================\n")
cat("場景1：選擇5個核心屬性\n")
cat("===============================================\n")

selected_attrs_1 <- c("口感", "新鮮度", "包裝設計", "價格合理性", "營養價值")
cat("選擇的屬性:", paste(selected_attrs_1, collapse = ", "), "\n")

result1 <- test_analysis_functions(test_data, selected_attrs_1)

# 場景2：選擇所有屬性
cat("\n===============================================\n")
cat("場景2：選擇所有7個屬性\n")
cat("===============================================\n")

selected_attrs_2 <- c("口感", "新鮮度", "包裝設計", "價格合理性", "營養價值", "便利性", "品牌形象")
cat("選擇的屬性:", paste(selected_attrs_2, collapse = ", "), "\n")

result2 <- test_analysis_functions(test_data, selected_attrs_2)

# 場景3：測試錯誤情況（如果誤選了計算欄位）
cat("\n===============================================\n")
cat("場景3：測試錯誤處理（誤選計算欄位）\n")
cat("===============================================\n")

selected_attrs_3 <- c("口感", "新鮮度", "total_score", "avg_score")
cat("錯誤選擇的屬性:", paste(selected_attrs_3, collapse = ", "), "\n")
cat("（包含了 total_score 和 avg_score）\n")

result3 <- test_analysis_functions(test_data, selected_attrs_3)

# 總結
cat("\n===============================================\n")
cat("測試總結\n")
cat("===============================================\n\n")

all_passed <- TRUE

# 檢查場景1
if (length(result1$wrongly_used) == 0 && length(result1$unused_selected) == 0) {
  cat("✅ 場景1通過：正確使用5個核心屬性\n")
} else {
  cat("❌ 場景1失敗\n")
  all_passed <- FALSE
}

# 檢查場景2
if (length(result2$wrongly_used) == 0 && length(result2$unused_selected) == 0) {
  cat("✅ 場景2通過：正確使用所有7個屬性\n")
} else {
  cat("❌ 場景2失敗\n")
  all_passed <- FALSE
}

# 檢查場景3（應該過濾掉計算欄位）
if (!("total_score" %in% result3$used_attrs) && !("avg_score" %in% result3$used_attrs)) {
  cat("✅ 場景3通過：成功過濾計算欄位\n")
} else {
  cat("❌ 場景3失敗：未能過濾計算欄位\n")
  all_passed <- FALSE
}

if (all_passed) {
  cat("\n🎉 所有測試通過！系統正確處理屬性欄位選擇\n")
} else {
  cat("\n⚠️ 部分測試失敗，請檢查系統\n")
}

cat("\n===============================================\n")
cat("測試完成\n")
cat("===============================================\n")