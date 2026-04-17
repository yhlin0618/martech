#' @principle MP56 Connected Component Principle
#' @principle MP52 Unidirectional Data Flow
#' @principle MP54 UI-Server Correspondence
#' @principle R88 Shiny Module ID Handling

#' Micro Filters Component
#'
#' Creates a component with filters specific to micro-level analysis
#' such as customer search, top customers, and region filters.
#'
#' @param id The component ID
#' @param app_data_connection Data connection for customer data
#' @param config Optional configuration
#'
#' @return A component with UI and server parts
#' @export
MicroFiltersComponent <- function(id, app_data_connection = NULL, config = NULL, translate = function(x) x) {
  # Create UI filter part
  ui_filter <- function(id) {
    ns <- NS(id)
    
    div(
      class = "micro-filters-section sidebar-section",
      
      # Tab header
      div(
        class = "sidebar-title",
        h4(translate("Micro Analysis Filters"), class = "sidebar-section-title")
      ),
      
      # Customer search using selectizeInput
      div(
        selectizeInput(
          ns("customer_search"),
          translate("Search Customer:"),
          choices = NULL, # Will be populated server-side
          selected = NULL,
          multiple = FALSE,
          options = list(
            placeholder = translate("Type name or email..."),
            searchField = c("label", "value"),
            valueField = "value",
            labelField = "label",
            create = FALSE,
            maxproducts = 1,
            maxOptions = 10,
            openOnFocus = TRUE,
            loadThrottle = 300,
            render = I("{
              option: function(product, escape) {
                return '<div title=\"' + escape(product.label) + '\">' + escape(product.label) + '</div>';
              }
            }")
          )
        ),
        
        # Helper text
        tags$small(
          class = "text-muted helper-text",
          translate("Type at least 2 characters to search")
        )
      ),
      
      # Top customers selector
      selectizeInput(
        ns("customer_top"), 
        translate("Top Customers:"),
        choices = c(
          "All Customers" = "all",
          "Top 10 by Value" = "top10_value",
          "Top 10 by Frequency" = "top10_freq", 
          "Recent Customers" = "recent",
          "At Risk Customers" = "at_risk"
        ),
        selected = "all"
      ),
      
      # Region filter
      selectizeInput(
        ns("region"), 
        translate("Select Region:"), 
        choices = c("All Regions" = "000", "North America" = "001", "Europe" = "002", "Asia" = "003"),
        selected = "000"
      ),
      
      # Note
      helpText(
        class = "data-note",
        translate("Filters apply automatically")
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
    # Initialize customer search data
    observe({
      # Try to get customer data from the connection
      connection <- if (is.reactive(app_data_connection)) {
        app_data_connection()
      } else {
        app_data_connection
      }
      
      if (is.null(connection)) {
        return()
      }
      
      # Use universal_data_accessor to get customer profile data
      customer_data <- tryCatch({
        universal_data_accessor(connection, "customer_profile", log_level = 0)
      }, error = function(e) {
        message("Error getting customer data for search: ", e$message)
        return(NULL)
      })
      
      if (is.null(customer_data) || nrow(customer_data) == 0) {
        return()
      }
      
      # Create search data
      if (all(c("customer_id", "buyer_name", "email") %in% colnames(customer_data))) {
        customer_search_data <- data.frame(
          id = customer_data$customer_id,
          name = customer_data$buyer_name,
          email = customer_data$email,
          label = sapply(1:nrow(customer_data), function(i) {
            name <- customer_data$buyer_name[i]
            email <- customer_data$email[i]
            
            # Truncate if too long
            if (nchar(name) > 20) name <- paste0(substr(name, 1, 17), "...")
            if (nchar(email) > 25) email <- paste0(substr(email, 1, 22), "...")
            
            paste0(name, " (", email, ")")
          }),
          stringsAsFactors = FALSE
        )
        
        # Update selectize with the top customers
        if (nrow(customer_search_data) > 0) {
          top_customers <- head(customer_search_data, 20)
          initial_choices <- setNames(top_customers$id, top_customers$label)
          
          updateSelectizeInput(
            session = session,
            inputId = "customer_search",
            choices = initial_choices
          )
        }
      }
    })
    
    # Return reactive with all filter values
    return(reactive({
      list(
        customer_search = input$customer_search,
        customer_top = input$customer_top,
        region = input$region
      )
    }))
  }
  
  # Default values
  defaults <- function() {
    list(
      customer_top = "all",
      region = "000"
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