# 診斷 VitalSigns 中 times 欄位問題
cat("=== VitalSigns times 欄位診斷 ===\n")

library(dplyr)

# 1. 檢查 fn_analysis_dna.R 是否存在
analysis_dna_path <- "scripts/global_scripts/04_utils/fn_analysis_dna.R"
if (file.exists(analysis_dna_path)) {
  cat("✅ fn_analysis_dna.R 檔案存在\n")
  source(analysis_dna_path)
} else {
  cat("❌ fn_analysis_dna.R 檔案不存在於:", analysis_dna_path, "\n")
  stop("無法找到 analysis_dna 函數")
}

# 2. 創建測試資料（模擬 module_dna_multi.R 的資料結構）
cat("\n📊 創建測試資料...\n")

# 模擬 sales_by_customer 資料
sales_by_customer <- data.frame(
  customer_id = c(1, 2, 3),
  total_spent = c(65.98, 52.98, 29.99),
  times = c(2, 2, 1),
  first_purchase = as.POSIXct(c("2024-01-01", "2024-01-10", "2024-01-20")),
  last_purchase = as.POSIXct(c("2024-01-15", "2024-02-01", "2024-01-20")),
  ipt = c(14, 22, 1),
  r_value = c(50, 30, 40),
  f_value = c(2, 2, 1),
  m_value = c(32.99, 26.49, 29.99),
  ni = c(2, 2, 1),
  platform_id = "upload",
  stringsAsFactors = FALSE
)

# 模擬 sales_by_customer_by_date 資料
sales_by_customer_by_date <- data.frame(
  customer_id = c(1, 1, 2, 2, 3),
  date = as.Date(c("2024-01-01", "2024-01-15", "2024-01-10", "2024-02-01", "2024-01-20")),
  sum_spent_by_date = c(29.99, 35.99, 12.99, 39.99, 29.99),
  count_transactions_by_date = c(1, 1, 1, 1, 1),
  payment_time = as.POSIXct(c("2024-01-01", "2024-01-15", "2024-01-10", "2024-02-01", "2024-01-20")),
  platform_id = "upload",
  stringsAsFactors = FALSE
)

# 3. 檢查資料結構
cat("\n📋 檢查資料結構:\n")
cat("sales_by_customer 類型:", class(sales_by_customer), "\n")
cat("sales_by_customer 欄位:", paste(names(sales_by_customer), collapse = ", "), "\n")
cat("'times' 欄位存在:", "times" %in% names(sales_by_customer), "\n")

# 4. 測試直接欄位提取（模擬 analysis_dna 內部行為）
cat("\n🔍 測試欄位提取:\n")
tryCatch({
  # 模擬 analysis_dna 第 287 行的操作
  test_extract <- sales_by_customer[, c("customer_id", "ipt", "total_spent", "times")]
  cat("✅ 直接提取成功 - 欄位:", paste(names(test_extract), collapse = ", "), "\n")
}, error = function(e) {
  cat("❌ 直接提取失敗:", e$message, "\n")
})

# 5. 測試 analysis_dna 函數
cat("\n🧬 測試 analysis_dna 函數:\n")
tryCatch({
  # 設定全域參數
  global_params <- list(
    delta = 0.1,
    ni_threshold = 2,
    cai_breaks = c(0, 0.1, 0.9, 1),
    text_cai_label = c("逐漸不活躍", "穩定", "日益活躍"),
    f_breaks = c(-0.0001, 1.1, 2.1, Inf),
    text_f_label = c("低頻率", "中頻率", "高頻率"),
    r_breaks = c(-0.0001, 0.1, 0.9, 1.0001),
    text_r_label = c("長期不活躍", "中期不活躍", "近期購買"),
    m_breaks = c(-0.0001, 0.1, 0.9, 1.0001),
    text_m_label = c("低價值", "中價值", "高價值"),
    nes_breaks = c(0, 1, 2, 2.5, Inf),
    text_nes_label = c("E0", "S1", "S2", "S3")
  )
  
  # 執行 analysis_dna
  dna_results <- analysis_dna(
    df_sales_by_customer = sales_by_customer,
    df_sales_by_customer_by_date = sales_by_customer_by_date,
    skip_within_subject = FALSE,
    verbose = TRUE,
    global_params = global_params
  )
  
  cat("✅ analysis_dna 執行成功！\n")
  cat("結果包含客戶數:", nrow(dna_results$data_by_customer), "\n")
  
}, error = function(e) {
  cat("❌ analysis_dna 執行失敗!\n")
  cat("錯誤訊息:", e$message, "\n")
  cat("\n詳細追蹤:\n")
  traceback()
})

# 6. 檢查可能的問題
cat("\n⚠️ 可能的問題檢查:\n")

# 檢查是否有 tibble 相關問題
if ("tibble" %in% loadedNamespaces()) {
  cat("- tibble 套件已載入，可能影響資料處理\n")
}

# 檢查是否有其他同名函數
if (exists("times")) {
  cat("- 發現全域環境中有 'times' 物件，可能造成衝突\n")
}

cat("\n💡 解決建議:\n")
cat("1. 確保 sales_by_customer 是 data.frame 而非 tibble\n")
cat("2. 在 analysis_dna 呼叫前加上: sales_by_customer <- as.data.frame(sales_by_customer)\n")
cat("3. 檢查是否有其他套件覆蓋了標準函數\n")
cat("4. 使用 verbose = TRUE 來獲得更詳細的錯誤訊息\n") 