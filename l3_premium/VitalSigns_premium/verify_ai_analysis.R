# 驗證營收脈能 AI 分析功能
# 檢查 API 是否正確調用

library(dplyr)

# 載入必要的模組
source("utils/prompt_manager.R")
source("modules/module_wo_b.R")

cat("================================================================================\n")
cat("營收脈能 AI 分析驗證\n")
cat("================================================================================\n\n")

# 1. 檢查 API Key
api_key <- Sys.getenv("OPENAI_API_KEY")
if (nzchar(api_key)) {
  cat("✅ OPENAI_API_KEY 已設定\n")
  cat("   Key 長度:", nchar(api_key), "字元\n\n")
} else {
  cat("❌ OPENAI_API_KEY 未設定\n\n")
}

# 2. 載入 prompts
prompts_df <- load_prompts()
cat("📋 已載入 prompts 數量:", nrow(prompts_df), "\n")

# 檢查營收相關 prompt
revenue_prompts <- prompts_df[grep("revenue_pulse", prompts_df$var_id), ]
if (nrow(revenue_prompts) > 0) {
  cat("✅ 找到營收脈能 prompt:\n")
  for(i in 1:nrow(revenue_prompts)) {
    cat("   -", revenue_prompts$var_id[i], "\n")
  }
} else {
  cat("❌ 未找到營收脈能 prompt\n")
}
cat("\n")

# 3. 測試 AI 分析功能
if (nzchar(api_key)) {
  cat("🤖 測試 AI 分析功能...\n\n")
  
  # 準備測試數據
  test_metrics <- list(
    new_customer_aov = 1200,
    core_customer_aov = 3500,
    overall_arpu = 2200,
    customer_count = 150
  )
  
  cat("測試數據:\n")
  cat("  新客平均客單價: $", test_metrics$new_customer_aov, "\n")
  cat("  主力客平均客單價: $", test_metrics$core_customer_aov, "\n")
  cat("  整體 ARPU: $", test_metrics$overall_arpu, "\n")
  cat("  客戶總數:", test_metrics$customer_count, "\n\n")
  
  # 測試 execute_gpt_request
  tryCatch({
    cat("執行 GPT 分析...\n")
    
    result <- execute_gpt_request(
      var_id = "revenue_pulse_aov_analysis",
      variables = test_metrics,
      chat_api_function = chat_api,
      model = "gpt-4o-mini",
      prompts_df = prompts_df
    )
    
    if (!is.null(result)) {
      cat("\n✅ AI 分析成功！\n")
      cat("================================================================================\n")
      cat("AI 分析結果:\n")
      cat("================================================================================\n")
      cat(result, "\n")
      cat("================================================================================\n")
    } else {
      cat("⚠️ AI 分析返回空結果\n")
    }
    
  }, error = function(e) {
    cat("\n❌ AI 分析失敗:\n")
    cat("   錯誤訊息:", e$message, "\n")
  })
  
} else {
  cat("⚠️ 跳過 AI 分析測試（無 API Key）\n")
}

cat("\n")
cat("================================================================================\n")
cat("驗證要點:\n")
cat("================================================================================\n")
cat("1. AI 分析應該自動執行，不需按鈕\n")
cat("2. 有 API Key 時使用 GPT 分析\n")
cat("3. 無 API Key 時使用預設建議\n")
cat("4. 營收成長曲線應正確顯示\n")
cat("================================================================================\n")