################################################################################
# Test Script for Upload Complete Score Module
# Purpose: Test the new upload module with sample data
################################################################################

library(shiny)
library(bs4Dash)
library(DT)
library(readxl)
library(dplyr)

# Source the upload module
source("modules/module_upload_complete_score.R")

# Create a simple test app
ui <- bs4DashPage(
  title = "測試上傳已評分資料模組",
  header = bs4DashNavbar(
    title = "上傳已評分資料測試"
  ),
  sidebar = bs4DashSidebar(
    collapsed = TRUE
  ),
  body = bs4DashBody(
    uploadCompleteScoreUI("test_upload")
  )
)

server <- function(input, output, session) {
  # Call the upload module
  upload_result <- uploadCompleteScoreServer("test_upload")

  # Monitor the results
  observe({
    if (!is.null(upload_result$data_ready()) && upload_result$data_ready()) {
      cat("\n=== 上傳完成 ===\n")
      cat("產品數量:", nrow(upload_result$score_data()), "\n")
      cat("屬性數量:", length(upload_result$attribute_columns()), "\n")
      cat("屬性名稱:", paste(upload_result$attribute_columns(), collapse = ", "), "\n")

      # Print field mapping
      mapping <- upload_result$field_mapping()
      if (!is.null(mapping)) {
        cat("\n=== 欄位映射 ===\n")
        cat("產品ID欄位:", mapping$score$product_id_col, "\n")
        cat("產品名稱欄位:", mapping$score$product_name_col, "\n")
        cat("品牌欄位:", mapping$score$brand_col, "\n")
        cat("選擇的屬性:", paste(mapping$score$selected_attributes, collapse = ", "), "\n")
      }
    }
  })

  # When confirm button is clicked
  observeEvent(upload_result$confirm(), {
    showModal(modalDialog(
      title = "資料確認",
      "已成功載入資料，可以進行後續分析。",
      footer = modalButton("關閉")
    ))
  })
}

# Run the test app
cat("啟動測試應用...\n")
cat("請使用以下測試檔案：\n")
cat("data/test_data/product_attribute_scores_20250911.csv\n\n")

shinyApp(ui = ui, server = server)