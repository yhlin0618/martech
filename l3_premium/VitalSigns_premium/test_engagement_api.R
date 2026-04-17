# 測試活躍轉化模組 API 功能
library(shiny)
library(dplyr)

# 載入必要模組
source("modules/module_wo_b.R")  # 載入 chat_api 函數
source("utils/prompt_manager.R")

cat("================================================================================\n")
cat("活躍轉化模組 API 測試\n")
cat("================================================================================\n\n")

# 1. 檢查 API Key
api_key <- Sys.getenv("OPENAI_API_KEY")
cat("1. API Key 狀態:\n")
if (nzchar(api_key)) {
  cat("   ✅ OPENAI_API_KEY 已設定 (", nchar(api_key), "字元)\n")
  cat("   前10字元:", substr(api_key, 1, 10), "...\n\n")
} else {
  cat("   ❌ OPENAI_API_KEY 未設定\n")
  cat("   請設定環境變數: Sys.setenv(OPENAI_API_KEY = 'your-api-key')\n\n")
}

# 2. 檢查 chat_api 函數
cat("2. chat_api 函數狀態:\n")
if (exists("chat_api")) {
  cat("   ✅ chat_api 函數存在\n")
  cat("   函數類型:", class(chat_api), "\n")
  cat("   函數參數:", paste(names(formals(chat_api)), collapse = ", "), "\n\n")
} else {
  cat("   ❌ chat_api 函數不存在\n\n")
}

# 3. 載入 prompts
cat("3. Prompt 載入狀態:\n")
prompts_df <- load_prompts()
cat("   總共載入", nrow(prompts_df), "個 prompts\n")

# 檢查活躍轉化相關的 prompt
activity_prompts <- prompts_df[grep("activity_", prompts_df$var_id), ]
if (nrow(activity_prompts) > 0) {
  cat("   ✅ 找到活躍轉化 prompts:\n")
  for(i in 1:nrow(activity_prompts)) {
    cat("      -", activity_prompts$var_id[i], "\n")
  }
} else {
  cat("   ❌ 未找到活躍轉化 prompts\n")
}
cat("\n")

# 4. 測試 API 呼叫
if (nzchar(api_key) && exists("chat_api")) {
  cat("4. 測試 API 呼叫:\n")
  
  # 測試購買頻率分析
  test_prompt <- "activity_purchase_frequency_analysis"
  if (test_prompt %in% prompts_df$var_id) {
    cat("   測試", test_prompt, "...\n")
    
    tryCatch({
      result <- execute_gpt_request(
        var_id = test_prompt,
        variables = list(
          avg_frequency = 3.5,
          frequency_distribution = "1次: 100人, 2-3次: 50人, 4-5次: 30人"
        ),
        chat_api_function = chat_api,
        model = "gpt-4o-mini",
        prompts_df = prompts_df
      )
      
      if (!is.null(result) && nchar(result) > 0) {
        cat("   ✅ API 呼叫成功\n")
        cat("   回應長度:", nchar(result), "字元\n")
        cat("   回應預覽:", substr(result, 1, 100), "...\n")
      } else {
        cat("   ⚠️ API 回應為空\n")
      }
    }, error = function(e) {
      cat("   ❌ API 呼叫失敗:", e$message, "\n")
    })
  }
} else {
  cat("4. 跳過 API 測試（API Key 未設定或 chat_api 不存在）\n")
}

# 5. 驗證模組中的使用
cat("\n5. 模組設定建議:\n")
cat("   在 app.R 中確保以下設定：\n")
cat("   1. source('modules/module_wo_b.R') - 載入 chat_api 函數\n")
cat("   2. 傳遞 chat_api 給模組：\n")
cat("      engagement_mod <- engagementFlowModuleServer(\n")
cat("        'engagement_flow1', con_global, user_info, dna_mod,\n")
cat("        enable_hints = TRUE, enable_gpt = TRUE, chat_api = chat_api\n")
cat("      )\n")
cat("   3. 設定 OPENAI_API_KEY 環境變數\n")

cat("\n================================================================================\n")
cat("測試完成\n")
cat("================================================================================\n")