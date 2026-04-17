# ── 改寫為 httr2 版本 ─────────────────────────────────────────────
library(httr2)

model_id <- "o4-mini"        # ← 換成你帳號實際可用的 model

answer <-
  request("https://api.openai.com/v1/chat/completions") |>
  req_auth_bearer_token(app_configs$OPENAI_API_KEY) |>
  req_body_json(list(
    model    = model_id,
    messages = list(
      list(role = "user", content = "Hello!")
    )
  )) |>
  req_perform() |>
  resp_body_json() |>
  (\(x) x$choices[[1]]$message$content)()   # 取出回覆文字

cat(answer)