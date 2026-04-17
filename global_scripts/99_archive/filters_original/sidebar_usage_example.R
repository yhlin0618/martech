#' Example usage of the Sidebar Component with Union pattern
#' This file demonstrates how to implement and use the sidebar components
#' in a Shiny application.

library(shiny)
library(shinyjs)
library(bs4Dash)

# Load required components
source("update_scripts/global_scripts/10_rshinyapp_components/unions/Union.R")
source("update_scripts/global_scripts/10_rshinyapp_components/filters/SidebarComponent.R")

#' Mock data connection
create_mock_connection <- function() {
  list(
    channel_availability = list(
      email = TRUE,
      sms = TRUE,
      web = FALSE,
      social = TRUE
    ),
    marketing_channels = c(
      "Email Marketing" = "email",
      "SMS Campaigns" = "sms",
      "Web Advertising" = "web",
      "Social Media" = "social"
    ),
    product_categories = c(
      "All Categories" = "all",
      "Electronics" = "electronics",
      "Clothing" = "clothing",
      "Home & Kitchen" = "home"
    )
  )
}

#' UI Definition
ui <- bs4Dash::dashboardPage(
  title = "Marketing Platform",
  fullscreen = TRUE,
  dark = FALSE,
  help = FALSE,
  
  # Dashboard header
  header = bs4Dash::dashboardHeader(
    title = "Marketing Platform",
    titleWidth = 300,
    skin = "light",
    status = "white",
    border = TRUE,
    
    # User menu
    right_ui = bs4Dash::userOutput("user")
  ),
  
  # Sidebar will be initialized in server
  sidebar = uiOutput("sidebar_container"),
  
  # Main body
  body = bs4Dash::dashboardBody(
    useShinyjs(),
    
    # Navigation tabs
    div(
      class = "tab-buttons",
      actionButton("micro_tab", "Micro Analysis", class = "tab-button active"),
      actionButton("macro_tab", "Macro Analysis", class = "tab-button")
    ),
    
    # Content containers
    div(
      id = "micro_content",
      h2("Micro Analysis Content"),
      p("This is where micro analysis content would be displayed.")
    ),
    
    div(
      id = "macro_content",
      style = "display: none;",
      h2("Macro Analysis Content"),
      p("This is where macro analysis content would be displayed.")
    )
  )
)

#' Server Definition
server <- function(input, output, session) {
  # Initialize shinyjs
  shinyjs::useShinyjs()
  
  # Create mock connection
  app_data_connection <- reactive({
    create_mock_connection()
  })
  
  # Create a reactive value to track the active tab
  active_tab <- reactiveVal("micro_tab")
  
  # Create the sidebar with the Union pattern
  sidebar_component <- ExtendedSidebarComponent(
    id = "app_sidebar", 
    app_data_connection = app_data_connection,
    active_tab = active_tab,
    translate = function(x) x  # Identity translation function
  )
  
  # Render the sidebar
  output$sidebar_container <- renderUI({
    sidebar_component$ui("app_sidebar")
  })
  
  # Initialize the sidebar server
  sidebar_server <- sidebar_component$server(input, output, session)
  
  # Tab navigation handling
  observeEvent(input$micro_tab, {
    active_tab("micro_tab")
    # Update tab buttons
    shinyjs::removeClass(selector = ".tab-button", class = "active")
    shinyjs::addClass(id = "micro_tab", class = "active")
    
    # Update content visibility
    shinyjs::hide("macro_content")
    shinyjs::show("micro_content")
  })
  
  observeEvent(input$macro_tab, {
    active_tab("macro_tab")
    # Update tab buttons
    shinyjs::removeClass(selector = ".tab-button", class = "active")
    shinyjs::addClass(id = "macro_tab", class = "active")
    
    # Update content visibility
    shinyjs::hide("micro_content")
    shinyjs::show("macro_content")
  })
  
  # Access filter values
  observe({
    # Get all filter values from the sidebar components
    filter_values <- list(
      common = sidebar_server$server_outputs$common(),
      micro = if (active_tab() == "micro_tab") sidebar_server$server_outputs$micro() else NULL,
      macro = if (active_tab() == "macro_tab") sidebar_server$server_outputs$macro() else NULL
    )
    
    # Print filter values for demonstration
    print(filter_values)
    
    # In a real application, you would use these filter values to update visualizations
    # e.g., filtered_data <- get_filtered_data(app_data_connection(), filter_values)
  })
  
  # User information
  output$user <- bs4Dash::renderUser({
    bs4Dash::dashboardUser(
      name = "Demo User",
      image = "https://picsum.photos/id/1/100/100",
      title = "Marketing Analyst"
    )
  })
}

# Run the application 
shinyApp(ui = ui, server = server)