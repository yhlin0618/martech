#
# Minimal Shiny App Template following Bottom-Up Construction Principle
#

# Load required packages
library(shiny)
library(bslib)

# Source components (only what's necessary)
# First: data acquisition components
source("update_scripts/global_scripts/10_rshinyapp_components/data/ui_data_source.R")
source("update_scripts/global_scripts/10_rshinyapp_components/data/server_data_source.R")

# Second: one functional component
source("update_scripts/global_scripts/10_rshinyapp_components/micro/ui_micro_customer_profile.R") 
source("update_scripts/global_scripts/10_rshinyapp_components/micro/server_micro_customer_profile.R")

# Define minimalist UI
ui <- page_fluid(
  title = "Minimal App Template",
  theme = bs_theme(version = 5),
  
  # Start with just the essential UI components
  h1("Customer Profile Demo"),
  p("This minimal app demonstrates the Bottom-Up Construction principle."),
  
  # Data source UI (may be empty)
  dataSourceUI("data"),
  
  # Add just one functional component
  microCustomerProfileUI("customer_profile")
)

# Define server logic
server <- function(input, output, session) {
  # Initialize data source first
  data_source <- dataSourceServer("data")
  
  # Then add only the functional component we need
  microCustomerProfileServer("customer_profile", data_source)
}

# Run the app
shinyApp(ui = ui, server = server)