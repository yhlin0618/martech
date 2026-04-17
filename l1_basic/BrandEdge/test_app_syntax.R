# 簡單的語法測試腳本
tryCatch({
  cat("正在檢查 app.R 語法...\n")
  source("app.R", local = new.env())
  cat("✅ app.R 語法檢查通過！\n")
}, error = function(e) {
  cat("❌ app.R 語法錯誤:\n")
  cat(e$message, "\n")
}) 