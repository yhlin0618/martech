# 測試提示系統
# Test Hint System

library(shiny)
library(bs4Dash)

# 載入提示系統
source("utils/hint_system.R")

# 測試載入提示資料
hints_df <- load_hints()
print("載入的提示資料：")
print(hints_df)

# 測試取得特定提示
test_hint <- get_hint("upload_button")
print(paste("upload_button 的提示：", test_hint))

test_hint2 <- get_hint("num_attributes")
print(paste("num_attributes 的提示：", test_hint2))

# 測試 UI
ui <- bs4DashPage(
  title = "提示系統測試",
  header = bs4DashNavbar(
    title = "Hint System Test"
  ),
  sidebar = bs4DashSidebar(
    disable = TRUE
  ),
  body = bs4DashBody(
    fluidRow(
      column(6,
        bs4Card(
          title = "測試提示功能",
          status = "primary",
          width = 12,
          
          h4("以下元素應該有提示："),
          br(),
          
          # 測試上傳按鈕提示
          add_hint(
            fileInput("test_file", "測試檔案上傳"),
            var_id = "upload_button",
            enable_hints = TRUE
          ),
          
          br(),
          
          # 測試滑桿提示
          add_hint(
            sliderInput("test_slider", "測試滑桿", 
                       min = 1, max = 10, value = 5),
            var_id = "num_attributes",
            enable_hints = TRUE
          ),
          
          br(),
          
          # 測試按鈕提示
          add_hint(
            actionButton("test_button", "測試按鈕"),
            var_id = "brand_select",
            enable_hints = TRUE
          )
        )
      ),
      column(6,
        bs4Card(
          title = "提示內容",
          status = "info",
          width = 12,
          verbatimTextOutput("hint_display")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  output$hint_display <- renderPrint({
    hints_df
  })
}

# 執行測試應用
shinyApp(ui, server)