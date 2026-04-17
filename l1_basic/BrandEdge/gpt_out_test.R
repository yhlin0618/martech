# app.R -------------------------------------------------------------
library(shiny)
library(shinyjs)
library(DBI)
library(RSQLite)
library(bcrypt)
library(readxl)
library(jsonlite)
library(httr)
library(DT)
library(dplyr)
library(GGally)
library(tidyverse)
library(stringr)
library(bslib)

library(dotenv)
library(plotly)
library(DT)
library(DBI)
library(duckdb)
library(httr2)
library(future)
library(furrr)
library(markdown) 
library(shinycssloaders) # withSpinner()

plan(multisession, workers = parallel::detectCores() - 1)  # Windows 也適用
options(future.rng.onMisuse = "ignore")  # 關閉隨機種子警告
library(stringr)
strip_code_fence <- function(txt) {
  str_replace_all(
    txt,
    regex("^```[A-Za-z0-9]*[ \\t]*\\r?\\n|\\r?\\n```[ \\t]*$", multiline = TRUE),
    ""
  )
}
dotenv::load_dot_env(file = ".env")

## ---- 0.（可選）模擬 chat_api() -----------------------------------
## 若你已經寫好真正的 chat_api()，請把下面這段註解掉 / 刪除，
## 並在全域載入正確版本即可。
chat_api <- function(messages,
                     model       = "gpt-4o-mini",
                     api_key     = Sys.getenv("OPENAI_API_KEY"),
                     api_url     = "https://api.openai.com/v1/chat/completions",
                     timeout_sec = 60) {
  if (!nzchar(api_key)) stop("🔑 OPENAI_API_KEY is missing")
  
  # Debug: 印出 body
  body <- list(
    model       = model,
    messages    = messages,
    temperature = 0.3,
    max_tokens  = 1024
  )
  # cat("Request body:\n", jsonlite::toJSON(body, auto_unbox=TRUE, pretty=TRUE), "\n")
  
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
## ------------------------------------------------------------------

# ---- 1. 模擬 position_dta -----------------------------------------
position_dta <- data.frame(
  Variation = c("B0000CGQD4", "B000CRV48I"),
  易用性    = c(5, 4.5),
  價格合理  = c(3, NA),
  耐用性    = c(NA, 4),
  清潔方便  = c(NA, 5),
  設計不良  = c(1, 3),
  stringsAsFactors = FALSE
)
# -------------------------------------------------------------------

# ---- 2. UI --------------------------------------------------------
# ------------------- UI -----------------------------------------
ui <- fluidPage(
  titlePanel("GPT markdown 測試 App"),
  sidebarLayout(
    sidebarPanel(
      actionButton("refresh_key_factor", "重新產生 GPT 總結")
    ),
    mainPanel(
      # 用 shinycssloaders 包起來 → 計算中顯示 Spinner
      withSpinner(
        htmlOutput("key_factor_gpt"),
        type  = 6,       # 內建多種 spinner 型號 1–8
        color = "#0d6efd" # Bootstrap 主題色
      )
    )
  )
)

# ------------------- Server -------------------------------------
server <- function(input, output, session) {
  
  md_text_key_fac <- reactive({
    req(input$refresh_key_factor)
    
    # Progress bar（上方小灰條）+ Spinner（主畫面）
    withProgress(message = "分析中，請稍候…", value = 0, {
      incProgress(0.3)
      
      position_txt <- toJSON(position_dta,
                             dataframe  = "rows",
                             auto_unbox = TRUE)
      sys <- list(role  = "system",
                  content = "你是一位數據分析師，請用繁體中文回答。")
      usr <- list(
        role = "user",
        content = paste0(
          "以下為不同Variation的各屬性分數…請回覆為markdown，200字內。\n資料:",
          position_txt
        )
      )
      
      # 呼叫 GPT
      txt <- chat_api(list(sys, usr))
      incProgress(0.9)
      txt                 # 傳回 Markdown 字串
    })
  })
  
  output$key_factor_gpt <- renderUI({
    md <- md_text_key_fac()
    
    # --- 若 GPT 可能包了 ```code fence```，可先剝除 ----------------
    md <- sub("^```[A-Za-z0-9]*[ \\t]*\\r?\\n", "", md)
    md <- sub("\\r?\\n```[ \\t]*$", "", md)
    # ----------------------------------------------------------------
    
    html <- markdownToHTML(
      text          = md,
      fragment.only = TRUE,
      encoding      = "UTF-8"
    )
    HTML(html)
  })
}

shinyApp(ui, server)
