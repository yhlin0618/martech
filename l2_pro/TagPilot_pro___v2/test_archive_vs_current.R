# 比較 archive 版本和當前版本的 times 欄位處理差異

cat("=== Archive 版本 vs 當前版本比較測試 ===\n")

library(dplyr)

# 測試 dplyr 管道操作的結果類型
test_data <- data.frame(
  customer_id = c(1, 1, 2, 2, 3),
  lineitem_price = c(29.99, 35.99, 12.99, 39.99, 29.99)
)

cat("\n📊 原始資料類型:", class(test_data), "\n")

# 模擬 module_dna_multi.R 中的處理過程
result <- test_data %>%
  group_by(customer_id) %>%
  summarise(
    total_spent = sum(lineitem_price),
    times = n(),
    .groups = "drop"
  )

cat("📊 dplyr 處理後的類型:", class(result), "\n")

# 測試子集操作
cat("\n🔍 測試欄位提取:\n")

# 方法 1: 使用 [] 直接提取（可能會失敗）
tryCatch({
  test1 <- result[, c("customer_id", "times")]
  cat("✅ 直接 [] 提取成功\n")
}, error = function(e) {
  cat("❌ 直接 [] 提取失敗:", e$message, "\n")
})

# 方法 2: 轉換為 data.frame 後提取
tryCatch({
  result_df <- as.data.frame(result)
  test2 <- result_df[, c("customer_id", "times")]
  cat("✅ 轉換為 data.frame 後提取成功\n")
}, error = function(e) {
  cat("❌ 轉換為 data.frame 後提取失敗:", e$message, "\n")
})

# 比較檔案大小
cat("\n📁 檢查檔案版本:\n")
archive_file <- "archive/VitalSigns_archive/modules/module_dna_multi.R"
current_file <- "modules/module_dna_multi.R"

if (file.exists(archive_file)) {
  archive_info <- file.info(archive_file)
  cat("Archive 版本大小:", archive_info$size, "bytes\n")
  cat("Archive 版本修改時間:", format(archive_info$mtime, "%Y-%m-%d %H:%M:%S"), "\n")
} else {
  cat("❌ Archive 檔案不存在\n")
}

if (file.exists(current_file)) {
  current_info <- file.info(current_file)
  cat("當前版本大小:", current_info$size, "bytes\n")
  cat("當前版本修改時間:", format(current_info$mtime, "%Y-%m-%d %H:%M:%S"), "\n")
} else {
  cat("❌ 當前檔案不存在\n")
}

# 結論
cat("\n💡 分析結論:\n")
cat("1. dplyr 的 summarise() 會返回 tibble 而非 data.frame\n")
cat("2. tibble 的 [] 操作可能不支援字元向量的欄位選擇\n")
cat("3. archive 版本可能沒有問題是因為:\n")
cat("   - 使用的 R/套件版本不同\n")
cat("   - 或者 archive 版本當時測試的資料恰好沒觸發這個問題\n")
cat("4. 建議的修復方式是在呼叫 analysis_dna 前轉換為 data.frame\n") 