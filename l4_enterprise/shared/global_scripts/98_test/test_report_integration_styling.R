#' Test Report Integration Styling
#' @description Test script to verify Report Center UI styling matches other modules
#' @principle MP014 Company Centered Design
#' @principle R09 UI-Server-Defaults Triple
#' @principle R72 Component ID Consistency

# Load required libraries
library(shiny)
library(bs4Dash)

# Source the report integration component
source("scripts/global_scripts/10_rshinyapp_components/report/reportIntegration/reportIntegration.R")

# Create a minimal test app to verify styling
ui <- bs4DashPage(
  header = bs4DashNavbar(
    title = "Report Integration Styling Test"
  ),
  sidebar = bs4DashSidebar(
    collapsed = TRUE
  ),
  body = bs4DashBody(
    fluidRow(
      # Column 1: Report Integration Component
      column(
        width = 4,
        h3("Report Integration Component"),
        reportIntegrationComponent("report_test")$ui$filter
      ),

      # Column 2: Standard wellPanel for comparison
      column(
        width = 4,
        h3("Standard Component (for comparison)"),
        wellPanel(
          class = "filter-panel",
          style = "padding: 15px;",
          h4("Standard Module", icon("chart-line")),
          tags$hr(),

          actionButton(
            "standard_button",
            "Generate Analysis",
            icon = icon("magic"),
            class = "btn-primary btn-block",
            width = "100%"
          ),

          tags$hr(),
          p("Module features:", style = "color: #666; font-size: 12px; margin-top: 10px;"),
          tags$ul(
            style = "font-size: 11px; color: #666; margin-left: -15px;",
            tags$li("Feature 1"),
            tags$li("Feature 2"),
            tags$li("Feature 3"),
            tags$li("Feature 4")
          ),

          tags$div(
            style = "margin-top: 15px; padding: 10px; background: #f8f9fa; border-radius: 5px;",
            tags$small(
              "Status: ",
              tags$span(
                "✓ Ready",
                style = "color: #28a745;"
              )
            )
          )
        )
      ),

      # Column 3: Comparison notes
      column(
        width = 4,
        h3("Styling Verification"),
        wellPanel(
          h4("Checklist:"),
          tags$ul(
            tags$li("✓ No purple/blue gradient background"),
            tags$li("✓ Standard padding (15px)"),
            tags$li("✓ Standard text colors (#666)"),
            tags$li("✓ Standard button class (btn-primary)"),
            tags$li("✓ Light background for status (#f8f9fa)"),
            tags$li("✓ Consistent with bs4Dash framework")
          ),
          br(),
          p("Both panels should look identical in styling.",
            style = "font-weight: bold; color: #2c3e50;")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Initialize report integration server (minimal setup)
  reportIntegrationServer("report_test")
}

# Run the test app
cat("\n========================================\n")
cat("Report Integration Styling Test\n")
cat("========================================\n")
cat("Opening test app to verify styling...\n")
cat("Both panels should have identical styling.\n")
cat("The Report Center should NOT have a purple/blue gradient.\n")
cat("========================================\n\n")

shinyApp(ui = ui, server = server)