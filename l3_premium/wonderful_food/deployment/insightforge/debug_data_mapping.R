# 資料對應關係調試腳本
# 此腳本幫助您診斷評分資料與銷售資料的對應問題

# 載入必要的程式庫
library(DT)
library(dplyr)
library(jsonlite)

# 設定工作目錄
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# 調試函數
debug_data_mapping <- function() {
  cat("🔍 開始調試資料對應關係...\n\n")
  
  # 1. 檢查評分資料
  cat("📊 Step 1: 檢查評分資料\n")
  if (file.exists("temp_scored_data.RDS")) {
    scored_data <- readRDS("temp_scored_data.RDS")
    cat("✅ 評分資料存在\n")
    cat("資料列數:", nrow(scored_data), "\n")
    cat("資料欄位:", paste(names(scored_data), collapse = ", "), "\n")
    
    if ("Variation" %in% names(scored_data)) {
      eval_variations <- unique(scored_data$Variation)
      cat("評分變體:", paste(eval_variations, collapse = ", "), "\n")
      cat("評分變體數量:", length(eval_variations), "\n")
    } else {
      cat("❌ 評分資料中沒有 'Variation' 欄位\n")
      return(FALSE)
    }
  } else {
    cat("❌ 找不到評分資料文件\n")
    return(FALSE)
  }
  
  cat("\n")
  
  # 2. 檢查銷售資料
  cat("📈 Step 2: 檢查銷售資料\n")
  if (file.exists("temp_sales_data.RDS")) {
    sales_data <- readRDS("temp_sales_data.RDS")
    cat("✅ 銷售資料存在\n")
    cat("資料列數:", nrow(sales_data), "\n")
    cat("資料欄位:", paste(names(sales_data), collapse = ", "), "\n")
    
    if ("Variation" %in% names(sales_data)) {
      sales_variations <- unique(sales_data$Variation)
      cat("銷售變體:", paste(sales_variations, collapse = ", "), "\n")
      cat("銷售變體數量:", length(sales_variations), "\n")
    } else {
      cat("❌ 銷售資料中沒有 'Variation' 欄位\n")
      return(FALSE)
    }
  } else {
    cat("❌ 找不到銷售資料文件\n")
    return(FALSE)
  }
  
  cat("\n")
  
  # 3. 分析對應關係
  cat("🔗 Step 3: 分析對應關係\n")
  common_vars <- intersect(eval_variations, sales_variations)
  cat("直接匹配的變體:", paste(common_vars, collapse = ", "), "\n")
  cat("直接匹配數量:", length(common_vars), "\n")
  
  if (length(common_vars) > 0) {
    cat("✅ 可以使用直接匹配策略\n")
    strategy <- "direct"
  } else {
    cat("⚠️ 需要使用智能對應策略\n")
    strategy <- "mapping"
    
    # 智能對應分析
    min_length <- min(length(eval_variations), length(sales_variations))
    
    if (length(eval_variations) <= length(sales_variations)) {
      mapping_table <- data.frame(
        評分變體 = eval_variations,
        對應銷售變體 = sales_variations[1:length(eval_variations)],
        stringsAsFactors = FALSE
      )
    } else {
      mapping_table <- data.frame(
        評分變體 = eval_variations[1:length(sales_variations)],
        對應銷售變體 = sales_variations,
        stringsAsFactors = FALSE
      )
    }
    
    cat("智能對應表:\n")
    print(mapping_table)
  }
  
  cat("\n")
  
  # 4. 資料品質檢查
  cat("🧪 Step 4: 資料品質檢查\n")
  
  # 檢查評分資料的數值欄位
  score_cols <- names(scored_data)[!names(scored_data) %in% "Variation"]
  numeric_cols <- score_cols[sapply(scored_data[score_cols], is.numeric)]
  cat("數值評分欄位:", paste(numeric_cols, collapse = ", "), "\n")
  cat("數值評分欄位數量:", length(numeric_cols), "\n")
  
  # 檢查銷售資料的必要欄位
  required_sales_cols <- c("Variation", "Time", "Sales")
  missing_cols <- setdiff(required_sales_cols, names(sales_data))
  if (length(missing_cols) > 0) {
    cat("❌ 銷售資料缺少必要欄位:", paste(missing_cols, collapse = ", "), "\n")
  } else {
    cat("✅ 銷售資料包含所有必要欄位\n")
  }
  
  # 檢查銷售數據的有效性
  valid_sales <- sum(!is.na(sales_data$Sales) & sales_data$Sales >= 0)
  cat("有效銷售記錄數:", valid_sales, "/", nrow(sales_data), "\n")
  
  cat("\n")
  
  # 5. 總結和建議
  cat("📋 Step 5: 總結和建議\n")
  
  if (strategy == "direct" && length(numeric_cols) > 0 && length(missing_cols) == 0) {
    cat("✅ 資料對應成功！建議:\n")
    cat("   - 使用直接匹配策略\n")
    cat("   - 可以進行", length(numeric_cols), "個屬性的分析\n")
    cat("   - 有", valid_sales, "筆有效銷售記錄\n")
  } else if (strategy == "mapping" && length(numeric_cols) > 0 && length(missing_cols) == 0) {
    cat("⚠️ 需要智能對應，建議:\n")
    cat("   - 使用智能對應策略\n")
    cat("   - 將配對", min_length, "個變體\n")
    cat("   - 可以進行", length(numeric_cols), "個屬性的分析\n")
    cat("   - 有", valid_sales, "筆有效銷售記錄\n")
  } else {
    cat("❌ 發現問題，需要修復:\n")
    if (length(numeric_cols) == 0) {
      cat("   - 評分資料缺少數值欄位\n")
    }
    if (length(missing_cols) > 0) {
      cat("   - 銷售資料缺少必要欄位:", paste(missing_cols, collapse = ", "), "\n")
    }
    if (valid_sales == 0) {
      cat("   - 沒有有效的銷售記錄\n")
    }
  }
  
  return(TRUE)
}

# 執行調試
if (interactive()) {
  debug_data_mapping()
} 