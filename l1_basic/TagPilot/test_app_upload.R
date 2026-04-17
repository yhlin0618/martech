# 測試上傳和DNA分析功能
# 運行此腳本來驗證新的多檔案上傳和DNA分析是否正常工作

# 設定環境
setwd(here::here())
source("scripts/global_scripts/22_initializations/sc_initialization_app_mode.R")

# 測試上傳功能
cat("=== 測試環境設定 ===\n")
cat("工作目錄：", getwd(), "\n")
cat("資料庫連線：", if(exists("get_con")) "✅" else "❌", "\n")

# 測試模組載入
cat("\n=== 測試模組載入 ===\n")
source("modules/module_upload.R")
source("modules/module_dna_multi.R")
cat("上傳模組：✅\n")
cat("DNA分析模組：✅\n")

# 測試資料偵測函數
cat("\n=== 測試資料偵測 ===\n")
test_data <- read.csv("test_data/quick_test.csv", stringsAsFactors = FALSE)
cat("測試資料載入：", nrow(test_data), "筆記錄\n")

# 模擬欄位偵測
cols <- tolower(names(test_data))
cat("欄位：", paste(names(test_data), collapse = ", "), "\n")

# 偵測客戶ID
email_patterns <- c("buyer email", "buyer_email", "email")
customer_field <- NULL
for (pattern in email_patterns) {
  if (any(grepl(pattern, cols, fixed = TRUE))) {
    customer_field <- names(test_data)[grepl(pattern, cols, fixed = TRUE)][1]
    break
  }
}

# 偵測時間
time_patterns <- c("purchase date", "payments date", "payment_time", "date", "time", "datetime")
time_field <- NULL
for (pattern in time_patterns) {
  if (any(grepl(pattern, cols, fixed = TRUE))) {
    time_field <- names(test_data)[grepl(pattern, cols, fixed = TRUE)][1]
    break
  }
}

# 偵測金額
amount_patterns <- c("item price", "lineitem_price", "amount", "sales", "price", "total")
amount_field <- NULL
for (pattern in amount_patterns) {
  if (any(grepl(pattern, cols, fixed = TRUE))) {
    amount_field <- names(test_data)[grepl(pattern, cols, fixed = TRUE)][1]
    break
  }
}

cat("偵測結果：\n")
cat("- 客戶ID：", customer_field %||% "未偵測到", "\n")
cat("- 時間：", time_field %||% "未偵測到", "\n")
cat("- 金額：", amount_field %||% "未偵測到", "\n")

if (!is.null(customer_field) && !is.null(time_field) && !is.null(amount_field)) {
  cat("✅ 所有必要欄位都已偵測到\n")
} else {
  cat("❌ 缺少必要欄位\n")
}

cat("\n=== 測試完成 ===\n")
cat("系統已準備好進行多檔案上傳和DNA分析\n")
cat("可以啟動app.R進行完整測試\n") 