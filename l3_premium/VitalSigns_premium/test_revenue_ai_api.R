# 測試營收脈能 AI 分析是否正確使用 API
library(dplyr)

# 載入相關模組
source("utils/prompt_manager.R")
source("modules/module_wo_b.R")

cat("================================================================================\n")
cat("營收脈能 AI API 測試\n")
cat("================================================================================\n\n")

# 1. 檢查 API Key
api_key <- Sys.getenv("OPENAI_API_KEY")
cat("1. API Key 狀態:\n")
if (nzchar(api_key)) {
  cat("   ✅ OPENAI_API_KEY 已設定 (", nchar(api_key), "字元)\n\n")
} else {
  cat("   ❌ OPENAI_API_KEY 未設定\n\n")
}

# 2. 載入並檢查 prompts
cat("2. Prompt 載入狀態:\n")
prompts_df <- load_prompts()
cat("   總共載入", nrow(prompts_df), "個 prompts\n")

# 檢查營收脈能相關的 prompt
revenue_prompts <- prompts_df[grep("revenue_pulse", prompts_df$var_id), ]
if (nrow(revenue_prompts) > 0) {
  cat("   ✅ 找到營收脈能 prompt:\n")
  for(i in 1:nrow(revenue_prompts)) {
    cat("      -", revenue_prompts$var_id[i], "\n")
    # 顯示 prompt 內容的前 100 字元
    prompt_content <- substr(revenue_prompts$prompt[i], 1, 100)
    cat("        內容預覽:", prompt_content, "...\n")
  }
} else {
  cat("   ❌ 未找到營收脈能 prompt\n")
}
cat("\n")

# 3. 測試 prepare_gpt_messages 函數
cat("3. 測試 prepare_gpt_messages 函數:\n")
test_variables <- list(
  new_customer_aov = 1500,
  core_customer_aov = 4000,
  overall_arpu = 2500,
  customer_count = 200
)

tryCatch({
  messages <- prepare_gpt_messages(
    var_id = "revenue_pulse_aov_analysis",
    variables = test_variables,
    prompts_df = prompts_df
  )
  
  cat("   ✅ 成功準備 GPT 消息\n")
  cat("   System 消息:", substr(messages[[1]]$content, 1, 80), "...\n")
  cat("   User 消息:", substr(messages[[2]]$content, 1, 80), "...\n\n")
  
}, error = function(e) {
  cat("   ❌ 準備消息失敗:", e$message, "\n\n")
})

# 4. 測試實際 API 呼叫（如果有 API Key）
if (nzchar(api_key)) {
  cat("4. 測試實際 API 呼叫:\n")
  
  tryCatch({
    # 使用 execute_gpt_request
    cat("   執行 execute_gpt_request...\n")
    
    result <- execute_gpt_request(
      var_id = "revenue_pulse_aov_analysis",
      variables = test_variables,
      chat_api_function = chat_api,
      model = "gpt-4o-mini",
      prompts_df = prompts_df
    )
    
    if (!is.null(result)) {
      cat("   ✅ API 呼叫成功！\n")
      cat("\n================================================================================\n")
      cat("AI 分析結果:\n")
      cat("================================================================================\n")
      # 顯示結果（限制長度）
      result_display <- substr(result, 1, 500)
      cat(result_display)
      if (nchar(result) > 500) cat("...")
      cat("\n================================================================================\n")
    } else {
      cat("   ⚠️ API 返回空結果\n")
    }
    
  }, error = function(e) {
    cat("   ❌ API 呼叫失敗:\n")
    cat("      錯誤:", e$message, "\n")
  })
  
} else {
  cat("4. 跳過 API 測試（無 API Key）\n")
}

# 5. 檢查營收脈能模組的 AI 功能設定
cat("\n5. 營收脈能模組 AI 功能檢查:\n")
cat("   模組位置: modules/module_revenue_pulse.R\n")
cat("   AI 分析函數:\n")
cat("   - ai_aov_analysis (客單價分析)\n")
cat("   - ai_clv_analysis (CLV 分群分析)\n")
cat("   - ai_trend_analysis (趨勢分析)\n")
cat("\n   注意事項:\n")
cat("   - 需要設定 enable_gpt = TRUE\n")
cat("   - 需要傳入 chat_api 函數\n")
cat("   - 需要載入 prompts_df\n")

cat("\n================================================================================\n")
cat("測試總結:\n")
cat("================================================================================\n")

if (nzchar(api_key)) {
  if (nrow(revenue_prompts) > 0) {
    cat("✅ 營收脈能 AI 分析功能應該可以正常運作\n")
    cat("   - API Key 已設定\n")
    cat("   - Prompt 已載入\n")
    cat("   - 函數調用正確\n")
  } else {
    cat("⚠️ 營收脈能 AI 分析可能有問題\n")
    cat("   - Prompt 可能未正確載入\n")
  }
} else {
  cat("⚠️ 營收脈能 AI 分析將使用預設建議\n")
  cat("   - 未設定 OPENAI_API_KEY\n")
  cat("   - 將不會呼叫 GPT API\n")
}

cat("\n================================================================================\n")