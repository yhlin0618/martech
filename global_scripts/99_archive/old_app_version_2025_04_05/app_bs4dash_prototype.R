# Precision Marketing bs4Dash Prototype
# Based on the original app.R structure but using bs4Dash components


# Load the YAML config function first
source(file.path("update_scripts", "global_scripts", "11_rshinyapp_utils", "fn_load_app_config.R"))

# Load configuration BEFORE initialization (needed for translations)
yaml_path <- "app_config.yaml"
config <- load_app_config(yaml_path,verbose = T)

# Now that config is loaded, reset initialization flags
if(exists("INITIALIZATION_COMPLETED")) {
  # Reset initialization flags to allow re-initialization
  rm(INITIALIZATION_COMPLETED, envir = .GlobalEnv)
}

# Source initialization script (with config already available)
init_script_path <- file.path("update_scripts", "global_scripts", "00_principles", 
                            "sc_initialization_app_mode.R")
source(init_script_path)

# The initialization script should have loaded core packages (shiny, readxl, etc.)

# Load bs4Dash package - this is specific to this UI framework and may not be in the standard initialization
if(!requireNamespace("bs4Dash", quietly = TRUE)) {
  install.packages("bs4Dash")
}
library(bs4Dash)

# Load shinyWidgets for enhanced UI components
if(!requireNamespace("shinyWidgets", quietly = TRUE)) {
  install.packages("shinyWidgets")
}
library(shinyWidgets)

# Verify configuration was loaded successfully
if (length(config) == 0) {
  stop("Failed to load configuration from ", yaml_path)
}

# Translation and locale handling is now done in fn_load_app_config.R
# following R34_ui_text_standardization and R36_available_locales rules

# Print some diagnostic information
message("Language setting from config: ", config$brand$language)
if (exists("available_locales")) {
  message("Available locales: ", paste(available_locales, collapse = ", "))
}
if (exists("ui_dictionary")) {
  message("Translation dictionary loaded with ", length(ui_dictionary), " entries")
} else {
  message("Warning: No translation dictionary loaded")
}

# Create fallback translation function if it doesn't exist (should never happen if initialization worked)
if (!exists("translate")) {
  translate <- function(text) { text }
  message("Warning: Translation function not available, using default text")
}
# Create simple versions of the UI components for the prototype
# These would normally be in separate files

# Sidebar UI Component - Simplified version for prototype
createSidebar <- function(id, active_module) {
  ns <- NS(id)
  
  # Instead of trying to make menuproduct work, let's use basic bs4Dash boxes
  # Create a list to hold all sidebar elements
  sidebar_products <- list()
  
  # Marketing Channel Section with h2 heading
  sidebar_products[[1]] <- div(
    class = "marketing-channel-section",
    style = "margin-bottom: 15px;",
    h2(
      class = "sidebar-section-title",
      translate("Marketing Channel")
    ),
    shinyWidgets::prettyRadioButtons(
      inputId = ns("distribution_channel"),
      label = NULL,
      choices = list(
        "Amazon" = "amazon",
        "Official Website" = "officialwebsite"
      ),
      selected = "amazon",
      status = "primary",
      animation = "smooth"
    )
  )
  
  # Product Category Section
  sidebar_products[[2]] <- div(
    class = "sidebar-filter-section",
    style = "margin-bottom: 15px;",
    h2(
      class = "sidebar-section-title",
      translate("Product Category")
    ),
    shinyWidgets::pickerInput(
      inputId = ns("product_category"),
      label = NULL,
      choices = NULL,
      width = "100%",
      options = list(`live-search` = TRUE)
    )
  )
  
  # Region Section
  sidebar_products[[3]] <- div(
    class = "sidebar-filter-section",
    style = "margin-bottom: 15px;",
    h2(
      class = "sidebar-section-title",
      translate("Region")
    ),
    selectizeInput(
      inputId = ns("geographic_region"),
      label = NULL,
      choices = NULL,
      multiple = FALSE,
      options = list(plugins = list('remove_button', 'drag_drop'))
    )
  )
  
  # Add module-specific products
  if (active_module == "micro") {
    # Customer Filters Section
    sidebar_products[[4]] <- div(
      class = "sidebar-filter-section",
      style = "margin-bottom: 15px;",
      h2(
        class = "sidebar-section-title",
        translate("Customer Filters")
      ),
      shiny::textInput(
        inputId = ns("customer_search"),
        label = translate("Customer Search"),
        placeholder = translate("Enter Customer ID or Name"),
        width = "100%"
      ),
      shiny::sliderInput(
        inputId = ns("recency_filter"),
        label = translate("Recency (R)"),
        min = 0,
        max = 365,
        value = c(0, 365),
        step = 1,
        width = "100%"
      )
    )
  } else if (active_module == "macro") {
    # Create choices with proper names
    choices <- list(
      "product_category" = "product_category",
      "region" = "region",
      "channel" = "channel",
      "customer_segment" = "customer_segment"
    )
    choices_names <- c("Product Category", "Region", "Channel", "Customer Segment")
    names(choices) <- translate(choices_names)
    
    # Aggregation Section
    sidebar_products[[4]] <- div(
      class = "sidebar-filter-section",
      style = "margin-bottom: 15px;",
      h2(
        class = "sidebar-section-title",
        translate("Aggregation")
      ),
      shinyWidgets::pickerInput(
        inputId = ns("aggregation_level"),
        label = translate("Aggregation Level"),
        choices = choices,
        selected = "product_category",
        width = "100%"
      ),
      shinyWidgets::prettyCheckbox(
        inputId = ns("enable_comparison"),
        label = translate("Enable Comparison"),
        value = FALSE,
        status = "primary",
        animation = "smooth"
      )
    )
  } else if (active_module == "target") {
    # Campaign Section
    sidebar_products[[4]] <- div(
      class = "sidebar-filter-section",
      style = "margin-bottom: 15px;",
      h2(
        class = "sidebar-section-title",
        translate("Campaign")
      ),
      shinyWidgets::pickerInput(
        inputId = ns("campaign_selector"),
        label = translate("Select Campaign"),
        choices = NULL,
        width = "100%",
        options = list(`live-search` = TRUE)
      ),
      bs4Dash::actionButton(
        inputId = ns("new_campaign"),
        label = translate("Create New Campaign"),
        icon = icon("plus"),
        width = "100%",
        class = "btn-success mb-3"
      )
    )
  }
  
  # Apply Filters Button
  sidebar_products[[length(sidebar_products) + 1]] <- bs4Dash::actionButton(
    inputId = ns("apply_filters"),
    label = translate("Apply Filters"),
    width = "100%",
    class = "btn-primary mt-3"
  )
  
  # Return the sidebar products as a div containing all elements
  return(sidebar_products)
}

# Micro Customer Component - Placeholder
microCustomerUI <- function(id) {
  ns <- NS(id)
  
  bs4Dash::tabBox(
    width = 12,
    side = "right",
    title = translate("Customer Analysis"),
    elevation = 2,
    shiny::tabPanel(
      title = translate("Profile"),
      icon = icon("user"),
      bs4Dash::box(
        title = translate("Customer Profile"),
        width = 12,
        status = "primary",
        solidHeader = TRUE,
        collapsible = TRUE,
        bs4Dash::valueBoxOutput(ns("lifetime_value_box"), width = 6),
        bs4Dash::valueBoxOutput(ns("recency_box"), width = 6),
        plotOutput(ns("purchase_history_plot"), height = "300px")
      )
    ),
    shiny::tabPanel(
      title = translate("Segments"),
      icon = icon("users"),
      bs4Dash::box(
        title = translate("Customer Segmentation"),
        width = 12,
        status = "info",
        solidHeader = TRUE,
        collapsible = TRUE,
        plotOutput(ns("segment_plot"), height = "300px")
      )
    )
  )
}

# Define UI using bs4Dash components
# Include external CSS in the UI
css_dependencies <- tags$head(
  tags$link(rel = "stylesheet", type = "text/css", href = "custom.css")
)

ui <- bs4Dash::dashboardPage(
  title = translate("AI Marketing Technology Platform"),
  fullscreen = TRUE,
  dark = FALSE,
  help = FALSE,
  
  # Dashboard header with navbar
  header = bs4Dash::dashboardHeader(
    title = bs4Dash::dashboardBrand(
      title = shiny::div(
        class = "centered-title",
        translate("AI Martech")
      ),
      color = "primary",
      href = "#"
    ),
    fixed = TRUE,
    leftUi = NULL,
    rightUi = bs4Dash::dropdownMenu(
      type = "notifications",
      badgeStatus = "success",
      bs4Dash::notificationproduct(
        text = "Welcome to Precision Marketing",
        icon = icon("info"),
        status = "primary"
      )
    )
  ),
  
  # Sidebar with main menu and filters
  sidebar = bs4Dash::dashboardSidebar(
    fixed = TRUE,
    skin = "light",
    status = "primary",
    elevation = 3,
    bs4Dash::sidebarMenu(
      id = "main_sidebar",
      bs4Dash::menuproduct(
        text = translate("Micro Analysis"),
        tabName = "micro",
        icon = icon("user-check")
      ),
      bs4Dash::menuproduct(
        text = translate("Macro Analysis"),
        tabName = "macro",
        icon = icon("chart-line")
      ),
      bs4Dash::menuproduct(
        text = translate("Target Marketing"),
        tabName = "target",
        icon = icon("bullseye")
      ),
      bs4Dash::menuproduct(
        text = translate("Settings"),
        tabName = "settings",
        icon = icon("cogs")
      )
    ),
    # Add a divider
    hr(style = "border-color: #3c8dbc; margin-top: 20px; margin-bottom: 20px;"),
    # Dynamic sidebar filters based on current tab
    conditionalPanel(
      condition = "input.main_sidebar === 'micro'",
      div(
        class = "sidebar-filters",
        style = "padding: 10px 15px;",
        uiOutput("micro_sidebar_products")
      )
    ),
    conditionalPanel(
      condition = "input.main_sidebar === 'macro'",
      div(
        class = "sidebar-filters",
        style = "padding: 10px 15px;",
        uiOutput("macro_sidebar_products")
      )
    ),
    conditionalPanel(
      condition = "input.main_sidebar === 'target'",
      div(
        class = "sidebar-filters",
        style = "padding: 10px 15px;",
        uiOutput("target_sidebar_products")
      )
    )
  ),
  
  # Main body with tabproducts corresponding to menu products
  body = bs4Dash::dashboardBody(
    # Include CSS dependencies
    css_dependencies,
    bs4Dash::tabproducts(
      # Micro Analysis Tab
      bs4Dash::tabproduct(
        tabName = "micro",
        fluidRow(
          column(
            width = 12,
            microCustomerUI("customer_module")
          )
        )
      ),
      
      # Macro Analysis Tab
      bs4Dash::tabproduct(
        tabName = "macro",
        fluidRow(
          column(
            width = 12,
            bs4Dash::box(
              title = translate("Macro Analysis"),
              width = NULL,
              status = "primary",
              solidHeader = TRUE,
              collapsible = TRUE,
              plotOutput("macro_plot", height = "300px"),
              tags$p(translate("Macro analysis components will be placed here."))
            )
          )
        )
      ),
      
      # Target Marketing Tab
      bs4Dash::tabproduct(
        tabName = "target",
        fluidRow(
          column(
            width = 12,
            bs4Dash::box(
              title = translate("Target Marketing"),
              width = NULL,
              status = "primary",
              solidHeader = TRUE,
              collapsible = TRUE,
              plotOutput("target_plot", height = "300px"),
              tags$p(translate("Target marketing components will be placed here."))
            )
          )
        )
      ),
      
      # Settings Tab
      bs4Dash::tabproduct(
        tabName = "settings",
        bs4Dash::box(
          title = translate("Application Settings"),
          width = 12,
          status = "primary",
          solidHeader = TRUE,
          collapsible = TRUE,
          fluidRow(
            column(
              width = 6,
              shinyWidgets::pickerInput(
                "app_language",
                translate("Language"),
                choices = list(
                  "English (US)" = "en_US.UTF-8", 
                  "中文 (繁體)" = "zh_TW.UTF-8"
                ),
                selected = config$brand$language,
                width = "100%"
              )
            ),
            column(
              width = 6,
              shinyWidgets::pickerInput(
                "app_theme",
                translate("Theme"),
                choices = list(
                  "Default" = "default",
                  "Blue" = "blue",
                  "Purple" = "purple",
                  "Red" = "red",
                  "Green" = "green"
                ),
                selected = "default",
                width = "100%"
              )
            )
          )
        )
      )
    )
  ),
  
  # Optional: Control sidebar for additional settings/filters
  controlbar = bs4Dash::dashboardControlbar(
    id = "controlbar",
    skin = "light",
    pinned = FALSE,
    overlay = TRUE,
    bs4Dash::controlbarMenu(
      id = "controlbarMenu",
      bs4Dash::controlbarproduct(
        title = translate("Display"),
        icon = icon("sliders-h"),
        selectInput(
          "display_density",
          translate("Display Density"),
          choices = c("Compact", "Comfortable", "Spacious"),
          selected = "Comfortable"
        ),
        shiny::sliderInput(
          "chart_height",
          translate("Chart Height"),
          min = 200,
          max = 800,
          value = 400,
          step = 50,
          width = "100%"
        )
      ),
      bs4Dash::controlbarproduct(
        title = translate("Data"),
        icon = icon("database"),
        shinyWidgets::prettyCheckbox(
          "show_raw_data",
          translate("Show Raw Data"),
          value = FALSE,
          status = "primary",
          animation = "smooth"
        ),
        shinyWidgets::prettyRadioButtons(
          "data_refresh",
          translate("Data Refresh"),
          choices = c("Manual", "Automatic"),
          selected = "Manual",
          status = "primary",
          animation = "smooth"
        )
      )
    )
  ),
  
  # Footer with version information
  footer = bs4Dash::dashboardFooter(
    fixed = FALSE,
    left = paste("Precision Marketing App", format(Sys.Date(), "%Y")),
    right = paste("Version", "1.0.0")
  )
)

# Server function
server <- function(input, output, session) {
  # Render sidebar products for each module
  output$micro_sidebar_products <- renderUI({
    createSidebar("micro_sidebar", "micro")
  })
  
  output$macro_sidebar_products <- renderUI({
    createSidebar("macro_sidebar", "macro")
  })
  
  output$target_sidebar_products <- renderUI({
    createSidebar("target_sidebar", "target")
  })
  
  # Customer module placeholder outputs
  output$lifetime_value_box <- bs4Dash::renderValueBox({
    bs4Dash::valueBox(
      value = "$1,250",
      subtitle = translate("Customer Lifetime Value"),
      icon = icon("dollar-sign"),
      color = "primary"
    )
  })
  
  output$recency_box <- bs4Dash::renderValueBox({
    bs4Dash::valueBox(
      value = "14 days",
      subtitle = translate("Days Since Last Purchase"),
      icon = icon("calendar-alt"),
      color = "info"
    )
  })
  
  output$purchase_history_plot <- renderPlot({
    # Placeholder plot
    plot(1:10, 1:10, type = "l", main = translate("Purchase History"),
         xlab = translate("Time"), ylab = translate("Amount"))
  })
  
  output$segment_plot <- renderPlot({
    # Placeholder plot
    pie(c(55, 30, 15), 
        labels = translate(c("Regular Customers", "New Customers", "VIP")),
        main = translate("Customer Segments"))
  })
  
  # Macro module placeholder outputs
  output$macro_plot <- renderPlot({
    # Placeholder plot
    barplot(c(23, 35, 18, 25), 
            names.arg = translate(c("Q1", "Q2", "Q3", "Q4")),
            main = translate("Quarterly Sales"))
  })
  
  # Target module placeholder outputs
  output$target_plot <- renderPlot({
    # Placeholder plot
    barplot(c(65, 35), 
            names.arg = translate(c("Targeted", "Regular")),
            main = translate("Campaign Performance"),
            col = c("steelblue", "gray"))
  })
  
  # Handle sidebar filtering
  observeEvent(input$micro_sidebar_apply_filters, {
    showToast(
      title = translate("Filters Applied"),
      message = translate("Customer filters have been updated"),
      options = list(autohide = TRUE, delay = 2000)
    )
  })
  
  # Handle theme changes
  observeEvent(input$app_theme, {
    theme <- input$app_theme
    showToast(
      title = translate("Theme Changed"),
      message = paste(translate("Theme updated to"), theme),
      options = list(autohide = TRUE, delay = 2000)
    )
  })
  
  # Handle language changes
  observeEvent(input$app_language, {
    newLang <- input$app_language
    showToast(
      title = translate("Language Changed"),
      message = paste(translate("Language updated to"), newLang),
      options = list(autohide = TRUE, delay = 2000)
    )
    
    # Update the configuration and reload translations
    tryCatch({
      # Create a backup of current config
      current_config <- config
      
      # Update language in config
      current_config$brand$language <- newLang
      
      # Reload translations
      dictionary_path <- file.path("app_data", "parameters", "ui_terminology_dictionary.xlsx")
      if (file.exists(dictionary_path)) {
        ui_data <- readxl::read_excel(dictionary_path)
        
        # Find case-insensitive match for new language column
        available_columns <- names(ui_data)
        language_column <- NULL
        
        for (col in available_columns) {
          if (tolower(col) == tolower(newLang)) {
            language_column <- col
            break
          }
        }
        
        if (!is.null(language_column)) {
          # Find the English/default column - first try en_US.UTF-8, then English, then first column
          english_column <- NULL
          if ("en_US.UTF-8" %in% available_columns) {
            english_column <- "en_US.UTF-8"
          } else if ("English" %in% available_columns) {
            english_column <- "English"
          } else {
            english_column <- available_columns[1]
          }
          
          ui_dictionary <- setNames(
            ui_data[[language_column]],
            ui_data[[english_column]]
          )
          
          # Make sure we have non-NA values
          ui_dictionary <- ui_dictionary[!is.na(names(ui_dictionary)) & !is.na(ui_dictionary)]
          
          assign("ui_dictionary", as.list(ui_dictionary), envir = .GlobalEnv)
          message(paste("Reloaded", length(ui_dictionary), "translations for", newLang))
          
          # Update UI without reloading (session$reload() causes infinite reloads)
          # Instead, we'll rely on reactivity to update the UI with the new translations
        } else {
          showToast(
            title = translate("Language Error"),
            message = paste("Could not find language column for", newLang),
            options = list(autohide = TRUE, delay = 3000)
          )
        }
      }
    }, error = function(e) {
      showToast(
        title = translate("Error"),
        message = paste("Failed to reload translations:", e$message),
        options = list(autohide = TRUE, delay = 3000)
      )
    })
  })
  
  # Helper function for toast messages
  showToast <- function(title, message, options = list()) {
    bs4Dash::toast(
      title = title,
      body = message,
      options = options
    )
  }
}

# Run the app
shinyApp(ui, server, options = list(
  host = "0.0.0.0",
  port = 4848,  # Using a different port than the main app
  launch.browser = TRUE
))
