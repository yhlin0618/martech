# Main Precision Marketing Application
# Configuration loaded from YAML file in app_configs directory
# Following Platform-Neutral Code, Data Source Hierarchy, and YAML Configuration Principles

# Initialize APP_MODE environment - default starting mode
if(exists("INITIALIZATION_COMPLETED")) {
  # Reset initialization flags to allow re-initialization
  rm(INITIALIZATION_COMPLETED, envir = .GlobalEnv)
}

# Use platform-neutral path construction
init_script_path <- file.path("update_scripts", "global_scripts", "00_principles", 
                            "sc_initialization_app_mode.R")
source(init_script_path)

# Set operation mode explicitly
OPERATION_MODE <- "APP_MODE"
message("Running in APP_MODE - Production Environment")
message("Deploying Shiny application in APP_MODE with YAML configuration")

# All required components already loaded by sc_initialization_app_mode.R

# Load configuration
yaml_path <- "app_config.yaml"
config <- readYamlConfig(yaml_path)

# Verify configuration was loaded successfully
if (length(config) == 0) {
  stop("Failed to load configuration from ", yaml_path)
}

# Determine environment settings
current_env <- Sys.getenv("R_ENV", "development")
env_config <- config$environments[[current_env]]
debug_mode <- FALSE

if (!is.null(env_config) && !is.null(env_config$parameters$debug)) {
  debug_mode <- env_config$parameters$debug
  message("Environment: ", current_env, ", Debug mode: ", debug_mode)
}

# Directly load the UI terminology dictionary to ensure translations are available
tryCatch({
  # Debug information
  message("Language setting from config: ", config$brand$language)
  
  dictionary_path <- file.path("app_data", "parameters", "ui_terminology_dictionary.xlsx")
  message("Looking for dictionary at: ", dictionary_path)
  
  if (file.exists(dictionary_path)) {
    message("Dictionary file exists, attempting to load...")
    ui_data <- readxl::read_excel(dictionary_path)
    message("Dictionary columns: ", paste(names(ui_data), collapse=", "))
    
    # Create translation dictionary 
    target_language <- config$brand$language
    
    # Find case-insensitive match for language column
    available_columns <- names(ui_data)
    language_column <- NULL
    
    for (col in available_columns) {
      if (tolower(col) == tolower(target_language)) {
        language_column <- col
        break
      }
    }
    
    if (!is.null(language_column) && "English" %in% available_columns) {
      message("Found both English and ", language_column, " columns (matched from ", target_language, ")")
      
      ui_dictionary <- setNames(
        ui_data[[language_column]],
        ui_data[["English"]]
      )
      assign("ui_dictionary", as.list(ui_dictionary), envir = .GlobalEnv)
      
      # Create translation function
      # Following P05: Case Sensitivity Principle
      # - UI is case-sensitive (preserve translation capitalization exactly)
      # - Lookup is case-sensitive for exact matches but falls back to case-insensitive if needed
      translate <- function(text, default_lang = "English") {
        if (is.null(text)) return(text)
        
        # If it's a vector, translate each element
        if (length(text) > 1) {
          return(sapply(text, translate, default_lang = default_lang))
        }
        
        # Check if dictionary exists and has the key
        if (!exists("ui_dictionary") || !is.list(ui_dictionary) || length(ui_dictionary) == 0) {
          # No dictionary available, return original text
          message("Dictionary unavailable for translation of: ", text)
          return(text)
        }
        
        # Safe lookup - handle missing keys gracefully
        tryCatch({
          # Try exact match first (case-sensitive)
          result <- ui_dictionary[[text]]
          
          # If exact match fails, try case-insensitive match
          if (is.null(result)) {
            # Find case-insensitive match
            text_lower <- tolower(text)
            for (key in names(ui_dictionary)) {
              if (tolower(key) == text_lower) {
                result <- ui_dictionary[[key]]
                break
              }
            }
          }
          
          # Return original text if no translation found
          if (is.null(result)) {
            # Track missing translations
            if (!exists("missing_translations")) {
              assign("missing_translations", character(0), envir = .GlobalEnv)
            }
            
            # Only log each missing term once
            if (!(text %in% missing_translations)) {
              missing_translations <<- c(missing_translations, text)
              message("Missing translation for: ", text)
            }
            
            return(text)
          }
          
          return(result)
        }, error = function(e) {
          # If any error occurs, return original text
          message("Error in translation: ", e$message, " for text: ", text)
          return(text)
        })
      }
      
      assign("translate", translate, envir = .GlobalEnv)
      message(paste("Loaded", length(ui_dictionary), "translations for", target_language))
      
      # Debug: Show available translations (limited to first 10 for brevity)
      message("Sample translations (first 10):")
      keys <- names(ui_dictionary)
      for (i in 1:min(10, length(keys))) {
        message("  ", keys[i], " -> ", ui_dictionary[[keys[i]]])
      }
      message("Total translations available: ", length(keys))
    } else {
      message("Required columns not found. Need: English and a column matching ", target_language, " (case-insensitive)")
      message("Found columns: ", paste(names(ui_data), collapse=", "))
    }
  } else {
    message("UI terminology dictionary not found: ", dictionary_path)
  }
}, error = function(e) {
  message("Error loading translations: ", e$message)
  message("Stack trace:")
  print(sys.calls())
})

# Create fallback translation function if it doesn't exist
if (!exists("translate")) {
  translate <- function(text) { text }
  message("Warning: Translation function not available, using default text")
}

# UI Definition - Using configuration values with translations
ui <- page_navbar(
  title = translate("AI Martech"),  # Use translate instead of YAML setting
  theme = bs_theme(version = config$theme$version, bootswatch = config$theme$bootswatch),
  navbar_options = navbar_options(bg = "#f8f9fa"),
  
  # Using the hybrid sidebar pattern with the micro customer component
  nav_panel(
    title = translate("Micro Analysis"),
    value = "micro",
    page_sidebar(
      sidebar = sidebarHybridUI("app_sidebar", active_module = "micro"),
      microCustomerUI("customer_module")
    )
  ),
  
  nav_panel(
    title = translate("Macro Analysis"),
    value = "macro",
    page_sidebar(
      sidebar = sidebarHybridUI("macro_sidebar", active_module = "macro"),
      # Placeholder for macro components
      card(
        card_header(translate("Macro Analysis")),
        card_body(translate("Macro analysis components will be placed here."))
      )
    )
  ),
  
  nav_panel(
    title = translate("Target Marketing"),
    value = "target",
    page_sidebar(
      sidebar = sidebarHybridUI("target_sidebar", active_module = "target"),
      # Placeholder for target marketing components
      card(
        card_header(translate("Target Marketing")),
        card_body(translate("Target marketing components will be placed here."))
      )
    )
  )
)

# Server logic
server <- function(input, output, session) {
  # Example: Processing data sources using the standard patterns
  
  # Pattern 3: Object format with roles
  customer_data_source <- config$components$micro$customer_profile
  message("Using customer profile configuration with multiple data sources:")
  lapply(names(customer_data_source), function(role) {
    message("- ", role, ": ", customer_data_source[[role]])
  })
  
  # Pattern 4a: Single data source with parameters
  trends_config <- config$components$macro$trends
  if (!is.null(trends_config$parameters)) {
    message("Trends component configuration:")
    message("- Data source: ", trends_config$data_source)
    message("- Refresh interval: ", trends_config$parameters$refresh_interval)
  }
  
  # Initialize sidebars for each navigation panel
  # Micro module sidebar - data comes from configuration, not hardcoded defaults
  sidebarHybridServer(
    "app_sidebar", 
    active_module = "micro",
    data_source = reactive({
      # Data source from configuration
      config$components$micro$sidebar_data
    })
  )
  
  # Macro module sidebar
  sidebarHybridServer(
    "macro_sidebar", 
    active_module = "macro",
    data_source = reactive({
      # Data source from configuration
      config$components$macro$sidebar_data
    })
  )
  
  # Target module sidebar
  sidebarHybridServer(
    "target_sidebar", 
    active_module = "target",
    data_source = reactive({
      # Data source from configuration
      config$components$target$sidebar_data
    })
  )
  
  # Create a reactive data source that includes the customer filter from sidebar
  filtered_customer_data <- reactive({
    # This connects the sidebar's customer search with the microCustomer component
    # Instead of having separate customer selection in both components
    sidebar_customer_search <- input$app_sidebar_customer_search
    
    # Log the currently selected customer for debugging
    if (!is.null(sidebar_customer_search) && sidebar_customer_search != "") {
      message("Using customer filter from sidebar: ", sidebar_customer_search)
    }
    
    # Return the data source with added context about the selected customer
    customer_data_source
  })
  
  # Use microCustomerServer with the configured data source
  microCustomerServer(
    "customer_module", 
    data_source = filtered_customer_data()
  )
  
  # Handle navigation panel changes
  observeEvent(input$nav, {
    # Log module change
    message("Module changed to: ", input$nav)
  })
}

# Set environment-specific options
options(shiny.sanitize.errors = !debug_mode)  # Hide detailed errors except in debug mode

# Create and run the app
message("Launching app with YAML configuration from ", yaml_path)
shinyApp(ui, server, options = list(
  host = "0.0.0.0",    # Make app available on all network interfaces
  port = 4847,         # Using alternate port to avoid conflicts
  launch.browser = TRUE
))