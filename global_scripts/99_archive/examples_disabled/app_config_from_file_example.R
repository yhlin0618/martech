#
# App Constructor from File Example - Demonstrates loading from external configuration
#

# Source the app constructor function
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "examples", "fn_app_constructor.R"))

# Create app from JSON configuration file
app <- build_app_from_file(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", 
                                    "examples", "app_configs", "customer_dna_app.json"))

# Run the app
shinyApp(app$ui, app$server)