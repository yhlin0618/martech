# Simple test to verify the upload module works

library(shiny)
library(bs4Dash)

# Source the module
source("modules/module_upload_complete_score.R")

# Simple test UI
ui <- bs4DashPage(
  title = "Test Upload Module",
  header = bs4DashNavbar(title = "Test"),
  sidebar = bs4DashSidebar(collapsed = TRUE),
  body = bs4DashBody(
    uploadCompleteScoreUI("test")
  )
)

# Simple test server
server <- function(input, output, session) {
  result <- uploadCompleteScoreServer("test")

  observe({
    if (!is.null(result$data_ready()) && result$data_ready()) {
      cat("Data processed successfully!\n")
      cat("Products:", nrow(result$score_data()), "\n")
      cat("Attributes:", length(result$attribute_columns()), "\n")
    }
  })
}

# Run
cat("Starting test app...\n")
cat("Use test file: data/test_data/product_attribute_scores_20250911.csv\n\n")
shinyApp(ui, server)