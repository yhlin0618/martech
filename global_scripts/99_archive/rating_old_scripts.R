autoinit()

# 連線資料庫
dbConnect_from_list("raw_data", read_only = TRUE)
dbConnect_from_list("processed_data", read_only = FALSE)
dbConnect_from_list("app_data", read_only = FALSE)
dbConnect_from_list("comment_property_rating", read_only = FALSE)
dbConnect_from_list("comment_property_rating_results", read_only = FALSE)


# 建立備份資料庫連線，並在全域環境中指定 comment_property_rating_temp
#dbCopyorReadTemp(comment_property_rating)

# library(reticulate)

### 架構 Python 虛擬環境
# setup_python("import openai")
# setup_python("import pandas as pd")
# setup_python("import duckdb")
# setup_python("import pyarrow")

# openai <- import("openai")
# pd <- import("pandas")
# 
# message("openai 套件版本：", openai$`__version__`)
# 
# # 載入 Python 模組 (請確保文件 comment_rating_per.py 在指定路徑中)
# rating_module <- import_from_path("comment_rating_per",
#                                   path = file.path("update_scripts", "global_scripts", "09_python_scripts"))
# cat(rating_module$rate_comment$`__doc__`)
# 
# 
# # 從環境變數取得 GPT API 金鑰
# gpt_key <- Sys.getenv("OPENAI_API_KEY")
# if (gpt_key == "") stop("未取得 GPT API 金鑰，請檢查環境變數。")


# test
# rating_module$rate_comment(
#   title = "Great taste",
#   body  = "This helps my digestion a lot.",
#   product_line_name = "Sympt-X",
#   property_name = "balance",
#   type = "brand personality",
#   gpt_key = gpt_key,
#   model="o4-mini"
# )

dbCopyTable(comment_property_rating, comment_property_rating_results, "df_comment_property_rating_jew___sampled_long", overwrite = TRUE)

sampled_tbl <- tbl(comment_property_rating_results, "df_comment_property_rating_jew___sampled_long")

tbl(comment_property_rating_results,
    "df_comment_property_rating_jew___sampled_long") %>% 
  filter(FALSE) %>%                         # 仍然 0 列
  mutate(gpt_model = sql("CAST(NULL AS VARCHAR)")) %>%  # 指定型別
  compute(
    name      = "df_comment_property_rating_jew___append_long",
    temporary = FALSE,
    overwrite = FALSE     # 若已存在則覆寫
  )

done_tbl    <- tbl(comment_property_rating_results, "df_comment_property_rating_jew___append_long")

cols <- setdiff(sampled_tbl %>% colnames(),"result")

todo <- sampled_tbl %>% 
  anti_join(done_tbl,by=cols) %>%  # 比對所有欄位
  collect()                                         # 拉回 R 做批次評分

# ####
#   
# #建立「安全呼叫」函式（自動重試 & 回傳佔位值）
# library(purrr)
# library(rlang)
# library(retry)
# 
# safe_rate <- function(...) {
#   retry(
#     .f       = ~ py$rate_comment(...),
#     when     = ~ inherits(.x, "error") || grepl("Rate limit", .x),
#     interval = ~ 2 ^ (.x - 1),     # 指數回退：2,4,8,16...
#     max_tries = 5,
#     quiet     = TRUE
#   )
# }
# 
# # helper：包裝參數
# call_gpt <- function(title,
#                      body,
#                      product_line_name,
#                      property_name,
#                      type,
#                      gpt_key = gpt_key,
#                      model = model) {
#   safe_rate(
#     title             = title,
#     body              = body,
#     product_line_name = product_line_name,
#     property_name      = property_name,
#     type      = type,
#     gpt_key           = gpt_key,
#     model             = "o4-mini"
#   )
# }
# 
# call_gpt(
#   title = "Great taste",
#   body  = "This helps my digestion a lot.",
#   product_line_name = "Sympt-X",
#   property_name = "balance",
#   type = "brand personality",
#   gpt_key = gpt_key,
#   model="o4-mini"
# )
# 
# library(furrr)
# parallel::detectCores()
# plan(multisession, workers = 8)    # 依 CPU / Rate Limit 調整
# 
# chunk_size <- 1000                # 每批 1000 列
# todo_chunks <- split(
#   todo,
#   (seq_len(nrow(todo)) - 1) %/% chunk_size
# )
# 
# walk(todo_chunks, function(batch) {
#   # ① GPT 評分（平行）
#   batch <- batch %>%
#     mutate(
#       gpt_resp = future_pmap_chr(
#         list(title, body, product_line_name,
#              property_name, type),
#         call_gpt
#       )
#     )
#   
#   # ② 寫回資料庫；UNIQUE 會擋重複
#   DBI::dbAppendTable(
#     con,
#     "df_comment_property_rating_jew___append_log",
#     batch
#   )
#   
#   cli::cli_alert_success(
#     "{Sys.time()} - 已寫入 {nrow(batch)} 筆；累積 {DBI::dbGetQuery(con, 'SELECT COUNT(*) FROM df_comment_property_rating_jew___append_log')[1,1]} 筆"
#   )
# })
# #
################Pure R version

library(httr2)
library(jsonlite)

gpt_key <- Sys.getenv("OPENAI_API_KEY")

rate_comment_httr2 <- function(title, body,
                               product_line_name,
                               property_name,
                               type,
                               model = "o4-mini") {
  
  prompt <- glue(
    "The following is a comment on a {product_line_name} product:\n",
    "Title: {title}\nBody: {body}\n",
    "Evaluate the comment regarding the product's '{property_name}', ",
    "which is categorized as a {type} feature.\n\n",
    "Use the following rules to respond:\n",
    "1. If the comment does not demonstrate the stated characteristic ",
    "in any way, reply exactly [NaN,NaN] without any additional reasoning ",
    "or explanation.\n",
    "2. Otherwise, rate your agreement with the statement on a scale from 1 to 5:\n",
    "- ‘5’ for Strongly Agree\n- ‘4’ for Agree\n- ‘3’ for Neither Agree nor Disagree\n",
    "- ‘2’ for Disagree\n- ‘1’ for Strongly Disagree\n",
    "Provide your rationale in the format: [Score, Reason]."
  )
  
  openai_after <- function(resp) {
    retry_after <- resp_header(resp, "Retry-After")
    if (!is.na(retry_after)) {
      return(as.numeric(retry_after))
    }
    reset_unix <- resp_header(resp, "x-ratelimit-reset-requests")
    if (!is.na(reset_unix)) {
      return(as.numeric(reset_unix) - unclass(Sys.time()))
    }
    NA  # → 交給 backoff()
  }
  
  req <- request("https://api.openai.com/v1/chat/completions") |>
    req_headers(
      Authorization = paste("Bearer", gpt_key),
      `Content-Type` = "application/json"
    ) |>
    req_body_json(list(
      model    = model,
      messages = list(
        list(role = "system",
             content = "Forget any previous information."),
        list(role = "user", content = prompt)
      )
    )) |>
    req_retry(
      is_transient = \(resp) resp_status(resp) %in% c(429, 500:599),
      after        = openai_after,                 # 精準睡眠
      backoff      = \(n) min(2^(n - 1), 30),      # 2,4,8,16,30...
      max_tries    = 6,
      max_seconds  = 180
    ) |>
    req_timeout(60)
  
  resp <- try(req_perform(req), silent = TRUE)
  
  if (inherits(resp, "try-error"))
    return("[NaN,Connection_error]")
  
  if (resp_status(resp) != 200)
    return(paste0("[NaN,HTTP_", resp_status(resp), "]"))
  
  out <- resp_body_json(resp, simplifyVector = FALSE)
  
  if (!is.null(out$choices))
    return(trimws(out$choices[[1]]$message$content))
  if (!is.null(out$error))
    return(paste0("[NaN,API_error:", out$error$message, "]"))
  
  "[NaN,Unknown_format]"
}


# rate_comment_httr2(
#   title = "Great taste",
#   body  = "This helps my digestion a lot.",
#   product_line_name = "Sympt-X",
#   property_name = "balance",
#   type = "brand personality",
#   model="o4-mini"
# )


library(furrr)
library(dplyr)
library(duckdb)
library(cli)

parallel::detectCores()
plan(multisession, workers = 8)    # 依 CPU / Rate Limit 調整

todo_chunks <- split(todo, (seq_len(nrow(todo)) - 1) %/% 20)  # 每 1000 筆一批

walk(todo_chunks, function(batch) {
  batch <- batch |>
    mutate(
      result = future_pmap_chr(
        list(title,
             body,
             product_line_name_english,
             property_name,   # ← 改名
             type),  # ← 改名
        rate_comment_httr2,
        .options = furrr::furrr_options(seed = TRUE)
      ),
      gpt_model = "o4-mini"
    )
  
  dbAppendTable(comment_property_rating_results, "df_comment_property_rating_jew___append_long", batch)
  cli::cli_alert_success("{Sys.time()} 已寫入 {nrow(batch)} 筆")
})

## 假設連線物件是 con
DBI::dbGetQuery(
  comment_property_rating_results,
  "PRAGMA table_info('df_comment_property_rating_jew___append_long');"
)



# 
#  ai_review_ratings_estimate(raw_data = raw_data,
#                            comment_property_rating_temp = comment_property_rating_temp,
#                            vec_product_line_id_noall = vec_product_line_id_noall,
#                            max_nreviews_per_asin = max_nreviews_per_asin,
#                            rating_module = rating_module,
#                            gpt_key = gpt_key,
#                            openai = openai)
# 
# ai_review_ratings(raw_data = raw_data,
#                   comment_property_rating_temp = comment_property_rating_temp,
#                   vec_product_line_id_noall = vec_product_line_id_noall,
#                   max_nreviews_per_asin = max_nreviews_per_asin,
#                   rating_module = rating_module,
#                   gpt_key = gpt_key,
#                   openai = openai)
# 
# 


autodeinit()

#######################










