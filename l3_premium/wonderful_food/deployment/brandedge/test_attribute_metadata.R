################################################################################
# 測試屬性欄位 metadata 傳遞功能
# Purpose: 確認系統正確使用上傳時選擇的屬性欄位
################################################################################

library(dplyr)

cat("===============================================\n")
cat("測試屬性欄位 metadata 傳遞\n")
cat("===============================================\n\n")

# 測試用資料
test_data <- data.frame(
  Variation = paste0("PRD", 1:10),          # 產品ID
  product_name = paste0("產品", 1:10),      # 產品名稱
  brand = rep(c("品牌A", "品牌B"), 5),      # 品牌
  新鮮 = sample(1:10, 10, replace = TRUE),   # 屬性1
  美味 = sample(1:10, 10, replace = TRUE),   # 屬性2
  方便 = sample(1:10, 10, replace = TRUE),   # 屬性3
  營養 = sample(1:10, 10, replace = TRUE),   # 屬性4
  健康 = sample(1:10, 10, replace = TRUE),   # 屬性5
  # 這些欄位不應該被使用
  extra_col1 = sample(100:200, 10),
  extra_col2 = sample(1000:2000, 10),
  total_score = sample(30:50, 10),
  avg_score = sample(5:10, 10, replace = TRUE)
)

cat("測試資料欄位:\n")
cat(paste(names(test_data), collapse = ", "), "\n\n")

# 模擬選擇的屬性欄位（只有這些應該被分析）
selected_attrs <- c("新鮮", "美味", "方便", "營養", "健康")
cat("選擇的屬性欄位:\n")
cat(paste(selected_attrs, collapse = ", "), "\n\n")

# 將選擇的屬性加入資料屬性
attr(test_data, "attribute_columns") <- selected_attrs

# 測試函數：模擬模組中的屬性識別邏輯
analyze_with_metadata <- function(data) {
  cat("=== 分析函數開始 ===\n")

  # 從 metadata 取得屬性欄位
  attr_cols <- attr(data, "attribute_columns")

  if (is.null(attr_cols)) {
    cat("❌ 錯誤：未找到屬性欄位 metadata\n")
    return(NULL)
  } else {
    cat("✓ 成功取得屬性欄位 metadata\n")
  }

  # 確保屬性欄位存在於資料中
  existing_attrs <- attr_cols[attr_cols %in% names(data)]
  missing_attrs <- setdiff(attr_cols, existing_attrs)

  if (length(missing_attrs) > 0) {
    cat("⚠ 警告：以下屬性欄位不存在:", paste(missing_attrs, collapse = ", "), "\n")
  }

  # 確保是數值型欄位
  numeric_attrs <- existing_attrs[sapply(data[existing_attrs], is.numeric)]
  non_numeric_attrs <- setdiff(existing_attrs, numeric_attrs)

  if (length(non_numeric_attrs) > 0) {
    cat("⚠ 警告：以下屬性欄位非數值型:", paste(non_numeric_attrs, collapse = ", "), "\n")
  }

  cat("\n最終使用的屬性欄位:\n")
  cat(paste(numeric_attrs, collapse = ", "), "\n")

  # 計算統計資訊
  if (length(numeric_attrs) > 0) {
    attr_data <- data[, numeric_attrs, drop = FALSE]

    # 計算每個產品的平均分
    avg_scores <- rowMeans(attr_data, na.rm = TRUE)

    # 計算每個屬性的平均分
    attr_means <- colMeans(attr_data, na.rm = TRUE)

    cat("\n屬性平均分:\n")
    for (i in seq_along(attr_means)) {
      cat(sprintf("  %s: %.2f\n", names(attr_means)[i], attr_means[i]))
    }

    cat("\n前3個產品的綜合評分:\n")
    for (i in 1:min(3, length(avg_scores))) {
      cat(sprintf("  %s: %.2f\n", data$Variation[i], avg_scores[i]))
    }
  }

  return(numeric_attrs)
}

# 執行測試
cat("\n===============================================\n")
cat("執行分析測試\n")
cat("===============================================\n\n")

result <- analyze_with_metadata(test_data)

# 驗證結果
cat("\n===============================================\n")
cat("驗證結果\n")
cat("===============================================\n\n")

if (!is.null(result)) {
  if (identical(sort(result), sort(selected_attrs))) {
    cat("✅ 測試通過：正確識別並使用選擇的屬性欄位\n")
  } else {
    cat("❌ 測試失敗：屬性欄位不匹配\n")
    cat("  期望:", paste(selected_attrs, collapse = ", "), "\n")
    cat("  實際:", paste(result, collapse = ", "), "\n")
  }
} else {
  cat("❌ 測試失敗：無法取得屬性欄位\n")
}

# 測試沒有 metadata 的情況
cat("\n===============================================\n")
cat("測試無 metadata 的錯誤處理\n")
cat("===============================================\n\n")

test_data_no_meta <- test_data
attr(test_data_no_meta, "attribute_columns") <- NULL
result2 <- analyze_with_metadata(test_data_no_meta)

cat("\n===============================================\n")
cat("測試完成\n")
cat("===============================================\n")