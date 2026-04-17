#
# App Constructor Example - Demonstrates declarative app creation
#

# Source the app constructor function
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "examples", "fn_app_constructor.R"))

# Define app configuration
app_config <- list(
  title = "Customer DNA Dashboard",
  sections = c("macro", "micro"),
  components = list(
    macro = c("overview"),
    micro = c("customer_profile")
  ),
  data_sources = c("source"),
  layout = "navbar",
  theme = list(
    version = 5,
    bootswatch = "default"
  )
)

# Create the app using the constructor
app <- create_app(app_config)

# Run the app
shinyApp(app$ui, app$server)