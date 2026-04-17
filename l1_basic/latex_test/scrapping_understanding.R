library(httr)
library(rvest)
library(jsonlite)
library(stringr)
library(dplyr)
library(DT)
library(readr)
library(dotenv)

# Load environment variables
dotenv::load_dot_env(file = ".env")
# --------- 1. 抓取商品資訊 ---------
asin <- "B07FVQLBL3"
url <- paste0("https://www.amazon.com/dp/", asin)

# 使用 User-Agent 模擬瀏覽器
page <- read_html(GET(url, add_headers(`User-Agent` = "Mozilla/5.0")))

# 商品標題
title <- page %>%
  html_node("#productTitle") %>%
  html_text(trim = TRUE)

# 商品特色 (About this item 區塊)
features <- page %>%
  html_nodes("#feature-bullets li span") %>%
  html_text(trim = TRUE) %>%
  paste(collapse = "; ")

# 商品描述（部分商品有）
description <- page %>%
  html_node("#productDescription") %>%
  html_text(trim = TRUE)

# 圖片：從 <img> tags 抓出主要圖片（簡化）
img_links <- page %>%
  html_nodes("img") %>%
  html_attr("src") %>%
  .[str_detect(., "media-amazon")]

img_links <- unique(img_links)

# --------- 2. Dummy coding via GPT API ---------
gpt_api_key <- Sys.getenv("OPENAI_API_KEY_LIN")  # <- 你要放入你自己的 OpenAI API key

gpt_prompt <- paste0("
根據以下 Amazon 商品敘述與特色，請根據這些特徵進行 dummy coding，輸出為 JSON 格式，值為 0 或 1：
特徵：
1. 是否防水 (waterproof)
2. 是否具備藍牙 (bluetooth)
3. 是否內建電池 (battery included)
4. 是否為智慧裝置 (smart device)

商品標題：", title, "
商品特色：", features, "
商品描述：", description
)

body <- list(
  model = "gpt-4",
  messages = list(
    list(role = "user", content = gpt_prompt)
  )
)

response <- POST(
  url = "https://api.openai.com/v1/chat/completions",
  add_headers(Authorization = paste("Bearer", gpt_api_key)),
  content_type_json(),
  body = body,
  encode = "json"
)

result <- content(response, as = "text", encoding = "UTF-8")
json_output <- fromJSON(result)$choices[[1]]$message$content

cat("🔍 Dummy Coding 結果：\n", json_output, "\n")
