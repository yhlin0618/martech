#' @principle MP56 Connected Component Principle
#' @principle MP52 Unidirectional Data Flow
#' @principle MP54 UI-Server Correspondence
#' @principle R88 Shiny Module ID Handling

#' Common Filters Component
#'
#' Creates a component with marketing channel and product category filters
#' used across different parts of the application.
#'
#' @param id The component ID
#' @param app_data_connection Data connection for availability information
#' @param config Optional configuration
#'
#' @return A component with UI and server parts
#' @export
CommonFiltersComponent <- function(id, app_data_connection = NULL, config = NULL, translate = function(x) x) {
  # Create UI filter part
  ui_filter <- function(id) {
    ns <- NS(id)
    
    div(
      id = ns("common_filters"),
      class = "common-filters sidebar-filters sidebar-section",
      
      # Title
      h4(translate("Common Filters"), class = "sidebar-section-title"),
      
      # Marketing Channel filter
      uiOutput(ns("channel_filter")),
      
      # Product Category filter
      selectizeInput(
        ns("category"),
        translate("Select Category:"),
        choices = product_categories,
        selected = product_categories[1]
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
    ns <- session$ns
    
    # Get channel availability information from connection
    channel_availability <- reactive({
      # Extract from app_data_connection if available
      if (is.reactive(app_data_connection)) {
        conn <- app_data_connection()
        if (is.list(conn) && !is.null(conn$channel_availability)) {
          return(conn$channel_availability)
        }
      } else if (is.list(app_data_connection) && !is.null(app_data_connection$channel_availability)) {
        return(app_data_connection$channel_availability)
      }
      
      # Default: all channels available
      setNames(rep(TRUE, length(marketing_channels)), unname(marketing_channels))
    })
    
    # Create channel filter UI with availability indicators
    output$channel_filter <- renderUI({
      availability <- channel_availability()
      
      # Determine which channel is available and select the first available one as default
      available_channels <- names(marketing_channels)[sapply(marketing_channels, function(ch) {
        !is.null(availability[[ch]]) && availability[[ch]]
      })]
      
      default_channel <- if (length(available_channels) > 0) {
        marketing_channels[available_channels[1]] 
      } else {
        marketing_channels[1]
      }
      
      # Create choice names with availability indicators
      choice_names <- lapply(names(marketing_channels), function(name) {
        channel_id <- marketing_channels[[name]]
        is_available <- !is.null(availability[[channel_id]]) && availability[[channel_id]]
        
        if (!is_available) {
          HTML(paste(name, '<span class="unavailable-tag"> (No Data)</span>'))
        } else {
          name
        }
      })
      
      # Create radio buttons with availability indicators
      radioButtons(
        inputId = ns("channel"),
        label = translate("Select Channel:"),
        choiceNames = choice_names,
        choiceValues = unname(marketing_channels),
        selected = default_channel
      )
    })
    
    # Return reactive with all filter values
    return(reactive({
      list(
        channel = input$channel,
        category = input$category
      )
    }))
  }
  
  # Default values
  defaults <- function() {
    list(
      channel = marketing_channels[1],
      category = product_categories[1]
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