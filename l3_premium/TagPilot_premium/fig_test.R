source("config/packages.R")    # 載入套件管理
source("config/config.R")      # 載入配置設定
# install.packages(c("httr2", "jsonlite"))
library(httr2)
library(jsonlite)
# install.packages(c("httr", "jsonlite"))
library(httr)
library(jsonlite)

api_key <- Sys.getenv("OPENAI_API_KEY")
img_path <- "C:/Users/User/Pictures/win_page.jpg"

# 1) 上傳圖片
up <- POST(
  url = "https://api.openai.com/v1/files",
  add_headers(Authorization = paste("Bearer", api_key)),
  body = list(
    purpose = "vision",
    file = upload_file(img_path)
  ),
  encode = "multipart"
)
stop_for_status(up)
file_id <- content(up, as="parsed", type="application/json")$id
cat("file_id:", file_id, "\n")

# 2) 呼叫 Responses API
payload <- list(
  model = "o4-mini",
  input = list(list(
    role = "user",
    content = list(
      list(type = "input_text", text = "幫我摘要這張圖片重點，幫我提供這個的風格以及不同風格的評分"),
      list(type = "input_image", file_id = file_id)  # ← 這裡改成 file_id
    )
  ))
)


resp <- POST(
  url = "https://api.openai.com/v1/responses",
  add_headers(
    Authorization = paste("Bearer", api_key),
    "Content-Type" = "application/json"
  ),
  body = toJSON(payload, auto_unbox = TRUE)
)
stop_for_status(resp)
out <- content(resp, as="parsed", type="application/json")
cat(out$output[[2]]$content[[1]]$text, "\n")

out$output[[2]]


#hyperlink ----

# install.packages(c("httr2", "jsonlite"))
library(httr2)
library(jsonlite)

api_key <- Sys.getenv("OPENAI_API_KEY")  # 請先在環境變數設定你的 API Key
img_url <-"https://upload.wikimedia.org/wikipedia/commons/3/3a/Cat03.jpg"

payload <- list(
  model = "o4-mini",   # 也可用 gpt-4o / gpt-4.1 等支援 vision 的模型
  input = list(list(
    role = "user",
    content = list(
      list(type = "input_text",  text = "請說明這張圖片的重點與可見文字"),
      list(type = "input_image", image_url = img_url)  # 用網址提供圖片
    )
  ))
)

resp <- POST(
  url = "https://api.openai.com/v1/responses",
  add_headers(
    Authorization = paste("Bearer", api_key),
    "Content-Type" = "application/json"
  ),
  body = toJSON(payload, auto_unbox = TRUE)
)
stop_for_status(resp)

out <- content(resp, as = "parsed", type = "application/json")
cat(out$output[[2]]$content[[1]]$text, "\n")

