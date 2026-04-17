################################################################################
# 測試動態欄位選擇功能
# Purpose: 確認系統只使用上傳時選擇的屬性欄位
################################################################################

library(shiny)
library(dplyr)

cat("===============================================\n")
cat("測試動態欄位選擇功能\n")
cat("===============================================\n\n")

# 測試用資料
test_data <- data.frame(
  product_id = paste0("PRD", 1:10),
  product_name = paste0("產品", 1:10),
  brand = rep(c("品牌A", "品牌B"), 5),
  新鮮 = sample(1:10, 10, replace = TRUE),
  美味 = sample(1:10, 10, replace = TRUE),
  方便 = sample(1:10, 10, replace = TRUE),
  營養 = sample(1:10, 10, replace = TRUE),
  健康 = sample(1:10, 10, replace = TRUE),
  # 這些欄位不應該被選擇
  extra_col1 = sample(100:200, 10),
  extra_col2 = sample(1000:2000, 10)
)

cat("測試資料欄位:\n")
cat(paste(names(test_data), collapse = ", "), "\n\n")

# 模擬選擇的屬性欄位
selected_attrs <- c("新鮮", "美味", "方便", "營養", "健康")
cat("選擇的屬性欄位:\n")
cat(paste(selected_attrs, collapse = ", "), "\n\n")

# 將選擇的屬性加入資料屬性
attr(test_data, "attribute_columns") <- selected_attrs

# 測試屬性識別函數
get_attributes <- function(data) {
  # 優先使用 metadata 中的屬性欄位
  attr_cols <- attr(data, "attribute_columns")

  if (is.null(attr_cols)) {
    cat("警告：沒有找到屬性欄位資訊，使用啟發式方法\n")
    # 備選方案
    non_attr_cols <- c("product_id", "product_name", "brand", "Variation",
                       "total_score", "avg_score")
    attr_cols <- names(data)[!names(data) %in% non_attr_cols]
  } else {
    cat("成功：使用 metadata 中的屬性欄位\n")
  }

  # 確保屬性欄位存在
  attr_cols <- attr_cols[attr_cols %in% names(data)]

  return(attr_cols)
}

# 測試屬性識別
detected_attrs <- get_attributes(test_data)
cat("\n識別到的屬性欄位:\n")
cat(paste(detected_attrs, collapse = ", "), "\n\n")

# 驗證結果
if (identical(sort(detected_attrs), sort(selected_attrs))) {
  cat("✓ 測試通過：正確識別選擇的屬性欄位\n")
} else {
  cat("✗ 測試失敗：屬性欄位不匹配\n")
  cat("  期望:", paste(selected_attrs, collapse = ", "), "\n")
  cat("  實際:", paste(detected_attrs, collapse = ", "), "\n")
}

# 測試計算平均分
cat("\n測試計算平均分:\n")
test_scores <- test_data %>%
  select(all_of(detected_attrs)) %>%
  rowMeans(na.rm = TRUE)

cat("前5個產品的平均分:\n")
print(round(test_scores[1:5], 2))

cat("\n===============================================\n")
cat("測試完成\n")
cat("===============================================\n")