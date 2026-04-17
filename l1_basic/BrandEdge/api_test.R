# 1. 安裝並載入必要套件（只要一開始做一次）

library(httr2)
dotenv::load_dot_env(file = ".env")
# 2. 定義 chat_api() 函式
library(httr2)
backoff_exponential <- function(base = 1, factor = 2, max = Inf) {
  function(retry_number) {
    # retry_number 从 1 开始：base * factor^(n-1)，并取最大值上限
    pmin(base * factor^(retry_number - 1), max)
  }
}
library(httr2)

chat_api <- function(messages,
                     model       = "o4-mini",
                     api_key     = Sys.getenv("OPENAI_API_KEY"),
                     api_url     = "https://api.openai.com/v1/chat/completions",
                     timeout_sec = 60) {
  if (!nzchar(api_key)) stop("🔑 OPENAI_API_KEY is missing")
  
  # Debug: 印出 body
  body <- list(
    model       = model,
    messages    = messages,
    temperature = 0.3,
    max_tokens  = 512
  )
  cat("Request body:\n", jsonlite::toJSON(body, auto_unbox=TRUE, pretty=TRUE), "\n")
  
  req <- request(api_url) |>
    req_auth_bearer_token(api_key) |>
    req_headers(`Content-Type`="application/json") |>
    req_body_json(body) |>
    req_timeout(timeout_sec)
  
  resp <- req_perform(req)
  
  # 如果非 2xx，就印詳細錯誤
  if (resp_status(resp) >= 400) {
    err <- resp_body_string(resp)
    stop(sprintf("Chat API error %s:\n%s", resp_status(resp), err))
  }
  
  content <- resp_body_json(resp)
  return(trimws(content$choices[[1]]$message$content))
}

# 3. 確認你已經在 ~/.Renviron 或 .env 裡設定
#    OPENAI_API_KEY=sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 4. 準備測試訊息
messages <- list(
  list(role="system", content="You are a helpful assistant."),
  list(role="user",   content="Hello, what is 2 + 2?")
)

# 5. 呼叫並印出結果
result <- chat_api(messages)
cat("GPT 回覆：", result, "\n")
