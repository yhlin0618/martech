library(shiny)
library(markdown)

# ---------- Module ---------- #
summaryUI <- function(id) {
  ns <- NS(id)
  tagList(
    actionButton(ns("refresh"), "更新"),
    htmlOutput(ns("summary_html"))
  )
}

summaryServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    md_text <- reactive({
      req(input$refresh)
      "
### 各 Variation 表現總結

1. **Variation B0000CGQD4**
   - 易於使用：5
2. **Variation B000CRV48I**
   - 清潔方便：5
"
    })
    
    output$summary_html <- renderUI({
      HTML(markdown::markdownToHTML(text = md_text(), fragment.only = TRUE))
    })
  })
}

# ---------- App ---------- #
ui <- fluidPage(
  h2("放在外層："),
  htmlOutput("summary_html_outer"),   # 外層也用 htmlOutput
  tags$hr(),
  h2("放在 module："),
  summaryUI("m1")
)

server <- function(input, output, session) {
  # 外層
  output$summary_html_outer <- renderUI({
    md <- "
### 外層區塊

- 這裡也要正常渲染 **Markdown**
"
    HTML(markdown::markdownToHTML(text = md, fragment.only = TRUE))
  })
  
  # module
  summaryServer("m1")
}

shinyApp(ui, server)
