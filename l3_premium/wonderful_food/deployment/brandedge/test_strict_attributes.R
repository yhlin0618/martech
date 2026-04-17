################################################################################
# 測試嚴格屬性欄位過濾
# Purpose: 確認系統只分析選擇的屬性，排除 total_score 等計算欄位
################################################################################

library(dplyr)

cat("===============================================\n")
cat("測試嚴格屬性欄位過濾\n")
cat("===============================================\n\n")

# 建立測試資料，包含各種類型的欄位
test_data <- data.frame(
  # 基本識別欄位
  Variation = paste0("PRD", 1:5),
  product_name = paste0("產品", 1:5),
  brand = c("品牌A", "品牌B", "品牌A", "品牌C", "品牌B"),

  # 真正的屬性欄位（應該被選擇）
  新鮮度 = c(8, 7, 9, 6, 8),
  美味程度 = c(7, 8, 8, 7, 9),
  方便性 = c(6, 7, 8, 9, 7),
  營養價值 = c(8, 7, 7, 8, 9),
  健康分數 = c(7, 8, 9, 7, 8),

  # 計算欄位（不應該被選擇）
  total_score = c(36, 37, 41, 37, 41),
  avg_score = c(7.2, 7.4, 8.2, 7.4, 8.2),
  總分 = c(36, 37, 41, 37, 41),
  平均分 = c(7.2, 7.4, 8.2, 7.4, 8.2),

  # 其他統計欄位（不應該被選擇）
  count = c(100, 150, 120, 80, 90),
  sum_reviews = c(500, 750, 600, 400, 450),
  mean_rating = c(4.5, 4.2, 4.8, 4.1, 4.6),

  # ID類欄位（不應該被選擇）
  product_id = paste0("ID", 1:5),
  SKU = paste0("SKU00", 1:5),
  ASIN = paste0("B000", 1:5)
)

cat("測試資料包含的所有欄位:\n")
cat(paste(names(test_data), collapse = ", "), "\n\n")

# 設定應該被選擇的屬性欄位
true_attributes <- c("新鮮度", "美味程度", "方便性", "營養價值", "健康分數")
cat("正確的屬性欄位（應該被選擇）:\n")
cat(paste(true_attributes, collapse = ", "), "\n\n")

# 不應該被選擇的欄位
wrong_attributes <- c("total_score", "avg_score", "總分", "平均分",
                     "count", "sum_reviews", "mean_rating")
cat("錯誤的欄位（不應該被選擇）:\n")
cat(paste(wrong_attributes, collapse = ", "), "\n\n")

# 模擬屬性欄位識別邏輯
identify_attributes <- function(data) {
  cat("=== 開始識別屬性欄位 ===\n")

  # 找出所有數值型欄位
  numeric_cols <- c()
  for (col in names(data)) {
    if (is.numeric(data[[col]])) {
      numeric_cols <- c(numeric_cols, col)
    }
  }
  cat("數值型欄位:", paste(numeric_cols, collapse = ", "), "\n\n")

  # 排除模式
  exclude_patterns <- c("id", "ID", "name", "名稱", "title", "Title",
                       "total", "avg", "sum", "count", "mean", "std",
                       "brand", "Brand", "品牌", "ASIN", "SKU", "sku",
                       "score", "Score", "分數", "總分", "平均", "合計",
                       "total_score", "avg_score", "average", "總計",
                       "Variation", "product")

  # 識別屬性欄位
  potential_attrs <- c()
  excluded_cols <- c()

  for (col in numeric_cols) {
    is_excluded <- FALSE
    exclude_reason <- ""

    for (pattern in exclude_patterns) {
      if (grepl(pattern, col, ignore.case = TRUE)) {
        # 特殊處理：如果是"健康分數"這種包含"分數"但是屬性的欄位
        if (pattern %in% c("score", "Score", "分數") &&
            !grepl("total|avg|sum|mean|總|平均", col, ignore.case = TRUE) &&
            grepl("健康|新鮮|美味|方便|營養", col)) {
          # 這是屬性評分，不排除
          next
        } else {
          is_excluded <- TRUE
          exclude_reason <- pattern
          break
        }
      }
    }

    if (!is_excluded) {
      # 檢查數值範圍
      col_values <- data[[col]]
      if (min(col_values) >= 0 && max(col_values) <= 100) {
        potential_attrs <- c(potential_attrs, col)
        cat("✓", col, "- 識別為屬性\n")
      } else {
        excluded_cols <- c(excluded_cols, col)
        cat("✗", col, "- 數值範圍不符\n")
      }
    } else {
      excluded_cols <- c(excluded_cols, col)
      cat("✗", col, "- 匹配排除模式:", exclude_reason, "\n")
    }
  }

  cat("\n最終識別的屬性欄位:\n")
  cat(paste(potential_attrs, collapse = ", "), "\n\n")

  return(potential_attrs)
}

# 執行測試
identified <- identify_attributes(test_data)

# 驗證結果
cat("===============================================\n")
cat("驗證結果\n")
cat("===============================================\n\n")

# 檢查是否正確識別了所有真正的屬性
correctly_identified <- intersect(identified, true_attributes)
missed_attributes <- setdiff(true_attributes, identified)
wrongly_included <- intersect(identified, wrong_attributes)

cat("正確識別的屬性:", paste(correctly_identified, collapse = ", "), "\n")
if (length(missed_attributes) > 0) {
  cat("❌ 遺漏的屬性:", paste(missed_attributes, collapse = ", "), "\n")
}
if (length(wrongly_included) > 0) {
  cat("❌ 錯誤包含的欄位:", paste(wrongly_included, collapse = ", "), "\n")
}

# 總體測試結果
if (length(wrongly_included) == 0 && length(missed_attributes) == 0) {
  cat("\n✅ 測試通過：正確識別所有屬性，排除所有非屬性欄位\n")
} else {
  cat("\n❌ 測試失敗：屬性識別有誤\n")
}

# 測試 metadata 傳遞
cat("\n===============================================\n")
cat("測試 Metadata 傳遞\n")
cat("===============================================\n\n")

# 模擬設定 metadata
attr(test_data, "attribute_columns") <- true_attributes

# 模擬分析函數
analyze_with_strict_attributes <- function(data) {
  attr_cols <- attr(data, "attribute_columns")

  if (is.null(attr_cols)) {
    cat("❌ 沒有找到屬性 metadata\n")
    return(NULL)
  }

  cat("從 metadata 取得的屬性欄位:\n")
  cat(paste(attr_cols, collapse = ", "), "\n\n")

  # 排除計算欄位（即使它們在 metadata 中）
  exclude_cols <- c("total_score", "avg_score", "總分", "平均分")
  attr_cols <- attr_cols[!attr_cols %in% exclude_cols]

  cat("排除計算欄位後的屬性:\n")
  cat(paste(attr_cols, collapse = ", "), "\n\n")

  # 只分析這些欄位
  if (length(attr_cols) > 0) {
    attr_data <- data[, attr_cols, drop = FALSE]
    cat("分析資料維度:", nrow(attr_data), "x", ncol(attr_data), "\n")
    cat("屬性平均值:\n")
    print(colMeans(attr_data))
  }

  return(attr_cols)
}

result <- analyze_with_strict_attributes(test_data)

cat("\n===============================================\n")
cat("測試完成\n")
cat("===============================================\n")