#' @principle MP56 Connected Component Principle
#' @principle MP52 Unidirectional Data Flow
#' @principle MP54 UI-Server Correspondence
#' @principle R88 Shiny Module ID Handling

#' Macro Filters Component
#'
#' Creates a component with filters specific to macro-level analysis
#' such as aggregation level, comparison options, and date ranges.
#'
#' @param id The component ID
#' @param app_data_connection Data connection
#' @param config Optional configuration
#'
#' @return A component with UI and server parts
#' @export
MacroFiltersComponent <- function(id, app_data_connection = NULL, config = NULL, translate = function(x) x) {
  # Create UI filter part
  ui_filter <- function(id) {
    ns <- NS(id)
    
    div(
      class = "macro-filters-section sidebar-section",
      
      # Tab header
      div(
        class = "sidebar-title",
        h4(translate("Macro Analysis Filters"), class = "sidebar-section-title")
      ),
      
      # Aggregation filter
      selectizeInput(
        ns("aggregation"), 
        translate("Aggregation Level:"), 
        choices = c("Product Category", "Region", "Channel", "Customer Segment"),
        selected = "Product Category"
      ),
      
      # Comparison toggle
      checkboxInput(
        ns("comparison"),
        translate("Enable Comparison"),
        value = FALSE
      ),
      
      # Date range
      dateRangeInput(
        ns("daterange"),
        translate("Select Period:"),
        start = Sys.Date() - 90,
        end = Sys.Date()
      ),
      
      # Note
      helpText(
        class = "data-note",
        translate("Changes apply automatically")
      )
    )
  }
  
  # Create UI display part (empty for sidebar filters)
  ui_display <- function(id) {
    # No display needed for sidebar filters
    div()
  }
  
  # Create server logic
  server <- function(input, output, session) {
    # Return reactive with all filter values
    return(reactive({
      list(
        aggregation = input$aggregation,
        comparison = input$comparison,
        daterange = input$daterange
      )
    }))
  }
  
  # Default values
  defaults <- function() {
    list(
      aggregation = "Product Category",
      comparison = FALSE,
      daterange = c(Sys.Date() - 90, Sys.Date())
    )
  }
  
  # Return component structure
  list(
    ui = list(
      filter = ui_filter,
      display = ui_display
    ),
    server = server,
    defaults = defaults
  )
}