# 測試營收脈能所有 AI 分析功能
library(dplyr)

# 載入必要的模組
source("utils/prompt_manager.R")
source("modules/module_wo_b.R")

cat("================================================================================\n")
cat("營收脈能完整 AI 分析測試\n")
cat("================================================================================\n\n")

# 檢查 API Key
api_key <- Sys.getenv("OPENAI_API_KEY")
cat("🔑 API Key 狀態: ")
if (nzchar(api_key)) {
  cat("✅ 已設定 (", nchar(api_key), "字元)\n\n")
} else {
  cat("❌ 未設定\n\n")
}

# 載入 prompts
prompts_df <- load_prompts()
cat("📋 Prompts 載入狀態:\n")

# 檢查三個營收脈能 prompts
prompt_ids <- c("revenue_pulse_aov_analysis", 
                "revenue_pulse_clv_analysis", 
                "revenue_pulse_trend_analysis")

for(id in prompt_ids) {
  if(id %in% prompts_df$var_id) {
    cat("   ✅", id, "\n")
  } else {
    cat("   ❌", id, "- 未找到\n")
  }
}

cat("\n================================================================================\n")
cat("測試三個 AI 分析功能\n")
cat("================================================================================\n\n")

# 1. 測試客單價分析
cat("1️⃣ 客單價分析 (AOV Analysis)\n")
cat("   用途: 比較新客與主力客單價，提供行銷策略\n")
if("revenue_pulse_aov_analysis" %in% prompts_df$var_id) {
  test_aov <- list(
    new_customer_aov = 1500,
    core_customer_aov = 4500,
    overall_arpu = 2800,
    customer_count = 250
  )
  
  if(nzchar(api_key)) {
    tryCatch({
      result <- execute_gpt_request(
        var_id = "revenue_pulse_aov_analysis",
        variables = test_aov,
        chat_api_function = chat_api,
        model = "gpt-4o-mini",
        prompts_df = prompts_df
      )
      cat("   ✅ API 呼叫成功\n")
      cat("   回應預覽:", substr(result, 1, 100), "...\n")
    }, error = function(e) {
      cat("   ❌ API 呼叫失敗:", e$message, "\n")
    })
  } else {
    cat("   ⚠️ 將使用預設建議（無 API Key）\n")
  }
}
cat("\n")

# 2. 測試 CLV 分群分析
cat("2️⃣ CLV 分群分析 (Customer Lifetime Value)\n")
cat("   用途: 80/20法則分析，制定差異化策略\n")
if("revenue_pulse_clv_analysis" %in% prompts_df$var_id) {
  test_clv <- list(
    high_value_count = 50,
    high_value_pct = 20,
    high_value_revenue_pct = 75,
    high_value_avg_clv = 8500,
    mid_value_count = 75,
    mid_value_pct = 30,
    mid_value_revenue_pct = 20,
    mid_value_avg_clv = 2500,
    low_value_count = 125,
    low_value_pct = 50,
    low_value_revenue_pct = 5,
    low_value_avg_clv = 500
  )
  
  if(nzchar(api_key)) {
    tryCatch({
      result <- execute_gpt_request(
        var_id = "revenue_pulse_clv_analysis",
        variables = test_clv,
        chat_api_function = chat_api,
        model = "gpt-4o-mini",
        prompts_df = prompts_df
      )
      cat("   ✅ API 呼叫成功\n")
      cat("   回應預覽:", substr(result, 1, 100), "...\n")
    }, error = function(e) {
      cat("   ❌ API 呼叫失敗:", e$message, "\n")
    })
  } else {
    cat("   ⚠️ 將使用預設建議（無 API Key）\n")
  }
}
cat("\n")

# 3. 測試趨勢分析
cat("3️⃣ 營收趨勢分析 (Revenue Trend)\n")
cat("   用途: 分析成長趨勢，預測未來方向\n")
if("revenue_pulse_trend_analysis" %in% prompts_df$var_id) {
  test_trend <- list(
    avg_growth = 5.2,
    recent_growth = 8.5,
    trend_direction = "上升",
    max_growth = 15.3,
    min_growth = -2.1
  )
  
  if(nzchar(api_key)) {
    tryCatch({
      result <- execute_gpt_request(
        var_id = "revenue_pulse_trend_analysis",
        variables = test_trend,
        chat_api_function = chat_api,
        model = "gpt-4o-mini",
        prompts_df = prompts_df
      )
      cat("   ✅ API 呼叫成功\n")
      cat("   回應預覽:", substr(result, 1, 100), "...\n")
    }, error = function(e) {
      cat("   ❌ API 呼叫失敗:", e$message, "\n")
    })
  } else {
    cat("   ⚠️ 將使用預設建議（無 API Key）\n")
  }
}

cat("\n================================================================================\n")
cat("測試總結\n")
cat("================================================================================\n\n")

all_prompts_exist <- all(prompt_ids %in% prompts_df$var_id)

if(nzchar(api_key) && all_prompts_exist) {
  cat("✅ 營收脈能 AI 分析功能完整配置\n")
  cat("   • 所有 prompts 已載入\n")
  cat("   • API Key 已設定\n")
  cat("   • 三個分析都能呼叫 GPT API\n")
} else if(!nzchar(api_key)) {
  cat("⚠️ 營收脈能將使用預設分析\n")
  cat("   • 未設定 OPENAI_API_KEY\n")
  cat("   • 建議設定 API Key 以獲得更好的分析結果\n")
} else if(!all_prompts_exist) {
  cat("❌ 部分 prompts 缺失\n")
  cat("   • 請檢查 database/prompt.csv 檔案\n")
}

cat("\n💡 提醒：\n")
cat("   1. 客單價分析會自動執行（資料載入後）\n")
cat("   2. CLV 分析會自動執行（資料載入後）\n")
cat("   3. 趨勢分析需要時間序列資料\n")
cat("   4. 無 API Key 時會使用預設建議\n")

cat("\n================================================================================\n")