#
# App Builder Example - Declarative App Construction from YAML
#

# Check if initialization has been done, if not initialize in APP_MODE
if (!exists("INITIALIZATION_COMPLETED") || !INITIALIZATION_COMPLETED) {
  # Initialize using APP_MODE - this automatically sources all components
  source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_app_mode.R"))
  
  # Set operation mode explicitly
  OPERATION_MODE <- "APP_MODE"
  message("Running in APP_MODE - Production Environment")
}

# Build app from configuration
app <- buildAppFromConfig("customer_dna_app.yaml")

# Run the app
options(shiny.sanitize.errors = TRUE)  # Hide detailed error messages from users
runApp(app, host = "0.0.0.0", port = 3838, launch.browser = FALSE)