#' App Construction Function
#'
#' Creates a Shiny app from a declarative configuration object.
#' This function enables building standardized Shiny applications
#' without writing boilerplate code.
#'
#' @param config List containing app configuration:
#'   \productize{
#'     \product title: App title string
#'     \product sections: Vector of section names to include
#'     \product components: Named list mapping sections to components
#'     \product data_sources: Vector of data source names to load
#'     \product layout: Layout type (navbar, sidebar, fillable)
#'     \product theme: Optional theme settings
#'   }
#'
#' @return Shiny app object
#'
#' @examples
#' app_config <- list(
#'   title = "Customer DNA App",
#'   sections = c("macro", "micro"),
#'   components = list(
#'     macro = c("overview"),
#'     micro = c("customer_profile")
#'   ),
#'   data_sources = c("customer_data"),
#'   layout = "navbar",
#'   theme = list(version = 5, bootswatch = "default")
#' )
#' app <- create_app(app_config)
#' @export
create_app <- function(config) {
  # Validate configuration
  validate_config(config)
  
  # Load required libraries
  library(shiny)
  library(bslib)
  
  # Source all required components
  component_info <- source_components(config)
  
  # Build UI based on layout type
  ui <- build_ui(config, component_info)
  
  # Create server function
  server <- build_server(config, component_info)
  
  # Return the Shiny app
  shinyApp(ui, server)
}

#' Validate App Configuration
#'
#' Validates that the app configuration contains all required elements
#' and that the values are valid.
#'
#' @param config The app configuration list
#'
#' @return Nothing, but throws an error if validation fails
#'
#' @noRd
validate_config <- function(config) {
  # Check for required fields
  required <- c("title", "sections", "components", "data_sources", "layout")
  missing <- setdiff(required, names(config))
  if (length(missing) > 0) {
    stop("Missing required config elements: ", paste(missing, collapse = ", "))
  }
  
  # Validate sections and components match
  invalid_sections <- setdiff(names(config$components), config$sections)
  if (length(invalid_sections) > 0) {
    stop("Components specified for undefined sections: ", paste(invalid_sections, collapse = ", "))
  }
  
  # Validate layout type
  valid_layouts <- c("navbar", "sidebar", "fillable")
  if (!config$layout %in% valid_layouts) {
    stop("Invalid layout type: ", config$layout, 
         ". Must be one of: ", paste(valid_layouts, collapse = ", "))
  }
}

#' Source Required Components
#'
#' Sources all the UI and server components required by the app configuration.
#'
#' @param config The app configuration list
#'
#' @return A list with information about the sourced components
#'
#' @noRd
source_components <- function(config) {
  components_info <- list(
    data_sources = list(),
    components = list()
  )
  
  # Helper to capitalize first letter
  capitalize <- function(x) {
    paste0(toupper(substr(x, 1, 1)), substr(x, 2, nchar(x)))
  }
  
  # Source data components
  for (data_source in config$data_sources) {
    ui_path <- file.path("update_scripts", "global_scripts", "10_rshinyapp_components", 
                         "data", paste0("ui_data_", data_source, ".R"))
    server_path <- file.path("update_scripts", "global_scripts", "10_rshinyapp_components", 
                             "data", paste0("server_data_", data_source, ".R"))
    
    # Check if files exist
    if (!file.exists(ui_path)) {
      message("Data source UI file not found: ", ui_path)
      message("Falling back to ui_data_source.R")
      ui_path <- file.path("update_scripts", "global_scripts", "10_rshinyapp_components", 
                           "data", "ui_data_source.R")
    }
    if (!file.exists(server_path)) {
      message("Data source server file not found: ", server_path)
      message("Falling back to server_data_source.R")
      server_path <- file.path("update_scripts", "global_scripts", "10_rshinyapp_components", 
                               "data", "server_data_source.R")
    }
    
    source(ui_path)
    source(server_path)
    
    # Determine function names based on availability
    if (exists(paste0("data", capitalize(gsub("_", "", data_source)), "UI"))) {
      ui_function <- paste0("data", capitalize(gsub("_", "", data_source)), "UI")
    } else {
      ui_function <- "dataSourceUI"
    }
    
    if (exists(paste0("data", capitalize(gsub("_", "", data_source)), "Server"))) {
      server_function <- paste0("data", capitalize(gsub("_", "", data_source)), "Server")
    } else {
      server_function <- "dataSourceServer"
    }
    
    components_info$data_sources[[data_source]] <- list(
      ui_function = ui_function,
      server_function = server_function
    )
  }
  
  # Source UI/server components
  for (section in config$sections) {
    if (section %in% names(config$components)) {
      for (component in config$components[[section]]) {
        ui_path <- file.path("update_scripts", "global_scripts", "10_rshinyapp_components", 
                             section, paste0("ui_", section, "_", component, ".R"))
        server_path <- file.path("update_scripts", "global_scripts", "10_rshinyapp_components", 
                                 section, paste0("server_", section, "_", component, ".R"))
        
        # Check if files exist
        if (!file.exists(ui_path)) {
          stop("Component UI file not found: ", ui_path)
        }
        if (!file.exists(server_path)) {
          stop("Component server file not found: ", server_path)
        }
        
        source(ui_path)
        source(server_path)
        
        comp_name <- paste0(section, "_", component)
        components_info$components[[comp_name]] <- list(
          ui_function = paste0(section, capitalize(gsub("_", "", component)), "UI"),
          server_function = paste0(section, capitalize(gsub("_", "", component)), "Server")
        )
      }
    }
  }
  
  return(components_info)
}

#' Build the App UI
#'
#' Builds the UI for the app based on the layout type and component information.
#'
#' @param config The app configuration list
#' @param component_info Information about the sourced components
#'
#' @return A UI definition
#'
#' @noRd
build_ui <- function(config, component_info) {
  # Build UI based on layout type
  if (config$layout == "navbar") {
    # Create base arguments for page_navbar
    ui_args <- list(
      title = config$title
    )
    
    # Add theme if specified
    if (!is.null(config$theme)) {
      ui_args$theme <- do.call(bs_theme, config$theme)
    }
    
    # Add data source UI components (if any are visible)
    for (data_name in names(component_info$data_sources)) {
      data_info <- component_info$data_sources[[data_name]]
      ui_fn <- get(data_info$ui_function)
      ui_args[[length(ui_args) + 1]] <- ui_fn(data_name)
    }
    
    # Add section components as nav panels
    for (section in config$sections) {
      if (section %in% names(config$components)) {
        for (component in config$components[[section]]) {
          comp_name <- paste0(section, "_", component)
          comp_info <- component_info$components[[comp_name]]
          
          # Get UI function and call it
          ui_fn <- get(comp_info$ui_function)
          ui_args[[length(ui_args) + 1]] <- ui_fn(comp_name)
        }
      }
    }
    
    # Build the navbar UI
    ui <- do.call(page_navbar, ui_args)
  }
  else if (config$layout == "sidebar") {
    # Implementation for sidebar layout
    # Similar approach but using page_sidebar
    ui <- page_sidebar(
      title = config$title,
      theme = if (!is.null(config$theme)) do.call(bs_theme, config$theme) else bs_theme(),
      sidebar = sidebar(
        # Add data source UI components to sidebar
        lapply(names(component_info$data_sources), function(data_name) {
          data_info <- component_info$data_sources[[data_name]]
          ui_fn <- get(data_info$ui_function)
          ui_fn(data_name)
        })
      ),
      # Add section components to main area
      lapply(config$sections, function(section) {
        if (section %in% names(config$components)) {
          lapply(config$components[[section]], function(component) {
            comp_name <- paste0(section, "_", component)
            comp_info <- component_info$components[[comp_name]]
            ui_fn <- get(comp_info$ui_function)
            ui_fn(comp_name)
          })
        }
      })
    )
  }
  else if (config$layout == "fillable") {
    # Implementation for fillable layout
    ui <- page_fillable(
      title = config$title,
      theme = if (!is.null(config$theme)) do.call(bs_theme, config$theme) else bs_theme(),
      # Add data source UI components
      lapply(names(component_info$data_sources), function(data_name) {
        data_info <- component_info$data_sources[[data_name]]
        ui_fn <- get(data_info$ui_function)
        ui_fn(data_name)
      }),
      # Add section components
      lapply(config$sections, function(section) {
        if (section %in% names(config$components)) {
          lapply(config$components[[section]], function(component) {
            comp_name <- paste0(section, "_", component)
            comp_info <- component_info$components[[comp_name]]
            ui_fn <- get(comp_info$ui_function)
            ui_fn(comp_name)
          })
        }
      })
    )
  }
  
  return(ui)
}

#' Build the App Server
#'
#' Builds the server function for the app based on the component information.
#'
#' @param config The app configuration list
#' @param component_info Information about the sourced components
#'
#' @return A server function
#'
#' @noRd
build_server <- function(config, component_info) {
  server <- function(input, output, session) {
    # Initialize data sources
    data_sources <- list()
    for (data_name in names(component_info$data_sources)) {
      data_info <- component_info$data_sources[[data_name]]
      server_fn <- get(data_info$server_function)
      data_sources[[data_name]] <- server_fn(data_name)
    }
    
    # Initialize components
    for (comp_name in names(component_info$components)) {
      comp_info <- component_info$components[[comp_name]]
      server_fn <- get(comp_info$server_function)
      
      # Determine which data source(s) this component needs
      # This is simplified - in a real implementation, you would have
      # a mapping of which components need which data sources or pass all sources
      # For now, we'll pass the first data source
      data_source <- data_sources[[names(data_sources)[1]]]  # Default to first data source
      
      # Call the server function with appropriate data source
      server_fn(comp_name, data_source)
    }
  }
  
  return(server)
}

#' Build App from Configuration File
#'
#' Loads an app configuration from a JSON or YAML file and creates a Shiny app.
#'
#' @param config_path Path to the configuration file (JSON or YAML)
#'
#' @return A Shiny app object
#'
#' @examples
#' # Using YAML (recommended)
#' app <- build_app_from_file("app_configs/customer_dna_app.yaml")
#' 
#' # Using JSON (alternative)
#' app <- build_app_from_file("app_configs/customer_dna_app.json")
#' @export
build_app_from_file <- function(config_path) {
  # Detect file type and load appropriately
  ext <- tools::file_ext(config_path)
  
  if (ext %in% c("yml", "yaml")) {
    # YAML is the preferred format
    if (!requireNamespace("yaml", quietly = TRUE)) {
      stop("The yaml package is required to load YAML configuration files.",
           "\nInstall it with install.packages(\"yaml\")")
    }
    config <- yaml::read_yaml(config_path)
    message("Loaded YAML configuration from: ", config_path)
  } else if (ext == "json") {
    # JSON is supported as an alternative
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("The jsonlite package is required to load JSON configuration files.",
           "\nInstall it with install.packages(\"jsonlite\")")
    }
    config <- jsonlite::fromJSON(config_path)
    message("Loaded JSON configuration from: ", config_path, 
            "\nNote: YAML is the preferred format as it supports comments and is more readable")
  } else {
    stop("Unsupported config file format: ", ext, 
         "\nPlease use YAML (.yml/.yaml) or JSON (.json) files")
  }
  
  # Build app using config
  create_app(config)
}