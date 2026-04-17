# BOT Exchange Rate Live Dashboard
# app.R
# -----------------------------------------------------------
# 依賴套件：shiny, httr2, dplyr, later
# -----------------------------------------------------------

# ---- 載入套件 ----
library(shiny)
library(httr2)
library(dplyr)
library(later)

# -----------------------------------------------------------
# 1. 解析 BOT fltxt 文字檔
# -----------------------------------------------------------
parse_bot_txt <- function(txt) {
  # 1) 切成行，剔除空行與表頭
  lines <- strsplit(txt, "\r?\n")[[1]]
  lines <- trimws(lines)
  lines <- lines[lines != ""]
  if (length(lines) < 2) stop("無有效資料行")
  lines <- lines[-1]  # 去掉表頭
  
  # 2) 逐行以 1+ 個空白分割，抽出欄位
  rows <- lapply(lines, function(l) {
    tok <- strsplit(l, "\\s+")[[1]]
    if (length(tok) < 14) return(NULL)  # 資料不足時跳過
    
    data.frame(
      code     = tok[1],
      cashBuy  = as.numeric(tok[3]),
      spotBuy  = as.numeric(tok[4]),
      cashSell = as.numeric(tok[13]),
      spotSell = as.numeric(tok[14]),
      stringsAsFactors = FALSE
    )
  })
  
  bind_rows(rows)
}

# -----------------------------------------------------------
# 2. 下載並整理 fltxt/0/day
# -----------------------------------------------------------
get_bot_rates <- function(url = "https://rate.bot.com.tw/xrt/fltxt/0/day") {
  resp <- request(url) |>
    req_headers(`user-agent` = "Mozilla/5.0") |>
    req_perform()
  
  httr2::resp_check_status(resp)
  
  txt <- resp_body_string(resp)
  df  <- parse_bot_txt(txt)
  
  attr(df, "updateTime") <- format(Sys.time(), "%Y/%m/%d %H:%M:%S")
  df
}

# -----------------------------------------------------------
# 3. Shiny UI
# -----------------------------------------------------------
ui <- fluidPage(
  titlePanel("臺灣銀行即時匯率 (BOT)"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        "curr", "選擇幣別",
        choices = c("USD", "JPY", "EUR", "CNY", "HKD", "GBP", "AUD",
                    "CAD", "SGD", "CHF", "NZD", "ZAR", "SEK", "THB"),
        selected = "USD"
      ),
      helpText("資料來源：臺灣銀行 fltxt/0/day，每 30 秒更新一次")
    ),
    mainPanel(
      tableOutput("rate_tbl"),
      textOutput("update_txt")
    )
  )
)

# -----------------------------------------------------------
# 4. Shiny Server
# -----------------------------------------------------------
server <- function(input, output, session) {
  rates      <- reactiveVal(data.frame())
  last_stamp <- reactiveVal("尚未更新")
  
  # ---- 非阻斷輪詢函式 ----
  fetch_bot <- function() {
    later(function() {
      tryCatch({
        df <- get_bot_rates()
        rates(df)
        last_stamp(attr(df, "updateTime"))
      }, error = function(e) {
        message("[BOT] 抓取失敗：", e$message)
      })
      later(fetch_bot, 30)  # 30 秒排下一輪
    }, delay = 0)
  }
  fetch_bot()  # 啟動
  
  # ---- UI 輸出 ----
  output$rate_tbl <- renderTable({
    req(nrow(rates()) > 0)
    filter(rates(), code == input$curr)
  }, striped = TRUE, spacing = "m")
  
  output$update_txt <- renderText({
    paste("最後更新：", last_stamp())
  })
}

# -----------------------------------------------------------
# 5. 啟動 App
# -----------------------------------------------------------
shinyApp(ui, server)
