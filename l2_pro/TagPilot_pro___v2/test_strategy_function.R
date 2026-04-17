# 測試策略載入和顯示功能
# Test Strategy Loading and Display Functions

cat("=================================================\n")
cat("測試策略載入和顯示功能\n")
cat("=================================================\n\n")

# 載入必要套件
library(dplyr)

# 載入模組中的策略函數
source("modules/module_dna_multi_pro2.R")

cat("1. 測試策略資料載入：\n")
strategy_data <- load_strategy_data()

if (!is.null(strategy_data)) {
  cat("   ✅ 策略資料載入成功\n")
  cat("   Mapping 欄位:", paste(names(strategy_data$mapping), collapse = ", "), "\n")
  cat("   Strategy 欄位:", paste(names(strategy_data$strategy), collapse = ", "), "\n\n")
  
  # 顯示mapping的前幾筆資料
  cat("2. Mapping 資料預覽：\n")
  print(head(strategy_data$mapping[, 1:4], 3))
  
  cat("\n3. Strategy 資料預覽：\n")
  print(head(strategy_data$strategy, 3))
  
  cat("\n4. 測試區段策略查詢：\n")
  test_segments <- c("A1C", "A3N", "B3N", "C3S")
  
  for (segment in test_segments) {
    cat("\n--- 測試區段:", segment, "---\n")
    strategy_info <- get_strategy_by_segment(segment, strategy_data)
    
    if (!is.null(strategy_info)) {
      cat("   ✅ 找到策略資料\n")
      if (!is.null(strategy_info$primary) && nrow(strategy_info$primary) > 0) {
        cat("   主要策略:", strategy_info$primary$core_action[1], "\n")
      }
      if (!is.null(strategy_info$secondary) && nrow(strategy_info$secondary) > 0) {
        cat("   次要策略:", strategy_info$secondary$core_action[1], "\n")
      }
    } else {
      cat("   ❌ 找不到策略資料\n")
    }
  }
  
} else {
  cat("   ❌ 策略資料載入失敗\n")
}

cat("\n=================================================\n")
cat("測試完成\n")
cat("=================================================\n") 