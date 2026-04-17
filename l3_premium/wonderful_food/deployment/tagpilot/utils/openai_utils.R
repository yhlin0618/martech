################################################################################
# OpenAI 工具函數
################################################################################

library(httr2)
library(jsonlite)

#' 呼叫 OpenAI Chat API
#' @param messages 訊息列表，包含 system 和 user 角色
#' @param model GPT 模型名稱
#' @param api_key OpenAI API 金鑰
#' @param api_url API 端點
#' @param timeout_sec 超時秒數
#' @return API 回應的內容文字
chat_api <- function(messages,
                     model       = "gpt-4o-mini",
                     api_key     = Sys.getenv("OPENAI_API_KEY"),
                     api_url     = "https://api.openai.com/v1/chat/completions",
                     timeout_sec = 60) {
  
  if (!nzchar(api_key)) {
    stop("🔑 OPENAI_API_KEY 未設定")
  }
  
  # 準備請求 body
  body <- list(
    model       = model,
    messages    = messages,
    temperature = 0.3,
    max_tokens  = 1024
  )
  
  # 建立請求
  req <- request(api_url) |>
    req_auth_bearer_token(api_key) |>
    req_headers(`Content-Type` = "application/json") |>
    req_body_json(body) |>
    req_timeout(timeout_sec)
  
  # 執行請求
  resp <- req_perform(req)
  
  # 錯誤處理
  if (resp_status(resp) >= 400) {
    err <- resp_body_string(resp)
    stop(sprintf("Chat API error %s:\n%s", resp_status(resp), err))
  }
  
  # 解析回應
  content <- resp_body_json(resp)
  return(trimws(content$choices[[1]]$message$content))
}

# 匯出函數供其他模組使用
openai_utils_exports <- list(
  chat_api = chat_api
)