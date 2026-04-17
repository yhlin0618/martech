#
# App Constructor from YAML Example - Production-ready implementation using APP_MODE
#

# Check if initialization has been done, if not initialize in APP_MODE
if (!exists("INITIALIZATION_COMPLETED") || !INITIALIZATION_COMPLETED) {
  # Initialize using APP_MODE - this automatically sources all components
  # from 10_rshinyapp_components and 11_rshinyapp_utils
  source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_app_mode.R"))
  
  # Set operation mode explicitly
  OPERATION_MODE <- "APP_MODE"
  message("Running in APP_MODE - Production Environment")
}

message("Deploying Shiny application in APP_MODE - Production Environment")

# The APP_MODE initialization has already loaded all necessary components
# from 10_rshinyapp_components and 11_rshinyapp_utils, following the
# UI-Server-Defaults triple pattern. No need to source them individually.

# Define UI using existing components following the Component Reuse Rule
ui <- page_navbar(
  title = "Customer DNA Analysis Dashboard (APP_MODE)",
  theme = bs_theme(version = 5, bootswatch = "cosmo"),
  navbar_options = navbar_options(bg = "#f8f9fa"),
  
  # Add production mode indicator
  header = tags$div(
    class = "container-fluid bg-success text-white py-1",
    tags$div(
      class = "d-flex justify-content-between align-products-center",
      tags$span(icon("check-circle"), "PRODUCTION ENVIRONMENT"),
      tags$span(class = "small", paste("Operating Mode:", "APP_MODE"))
    )
  ),
  
  # Using the micro customer component directly - implementing Component Reuse Rule
  microCustomerUI("customer_module")
)

# Server logic to connect the components
server <- function(input, output, session) {
  # Load configuration from YAML in app_configs folder
  config <- readYamlConfig("customer_dna_app.yaml")
  
  # Example: Using processDataSource with config from YAML
  customer_data_source <- config$components$micro$customer_profile
  
  # Use microCustomerServer with the configured data source
  # The server component now uses processDataSource internally
  # to handle various data source formats
  microCustomerServer(
    "customer_module", 
    data_source = customer_data_source
  )
}

# Display production mode notification
message("Launching production app in APP_MODE")

# Set production-specific options
options(shiny.sanitize.errors = TRUE)  # Hide detailed error messages from users

# Create and run the app
shinyApp(ui, server, options = list(
  host = "0.0.0.0",    # Make app available on all network interfaces
  port = 3838,         # Standard Shiny Server port
  launch.browser = FALSE
))

