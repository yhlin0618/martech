#' @principle MP56 Connected Component Principle
#' @principle MP52 Unidirectional Data Flow
#' @principle MP54 UI-Server Correspondence
#' @principle P22 CSS Component Display Controls

#' Sidebar Union Component
#'
#' Creates a union of filter components for the application sidebar.
#' Manages filter components visibility based on active tab or configuration.
#'
#' @param id The component ID
#' @param app_data_connection Data connection for availability information
#' @param config Optional configuration for initial visibility
#'
#' @return A component with UI and server parts
#' @export
SidebarComponent <- function(id, app_data_connection = NULL, config = NULL, translate = function(x) x) {
  # Load required components
  source("update_scripts/global_scripts/10_rshinyapp_components/filters/CommonFiltersComponent.R")
  
  # Create a unified sidebar using Union
  sidebar_union <- Union(
    id,
    common = CommonFiltersComponent(paste0(id, "_common"), app_data_connection, config, translate),
    config = config
  )
  
  # Create the sidebar container
  sidebar_ui <- function(id) {
    bs4Dash::dashboardSidebar(
      fixed = TRUE,
      skin = "light",
      status = "primary",
      elevation = 3,
      
      # Filters header
      div(
        class = "filters-header app-header",
        h3(
          class = "app-title",
          translate("Application Settings")
        )
      ),
      
      # Include the union filter UI
      sidebar_union$ui$filter(id)
    )
  }
  
  # Sidebar server function
  sidebar_server <- function(input, output, session) {
    # Initialize the union server
    union_server <- sidebar_union$server(id, app_data_connection, session)
    
    # Return the union server for external access to filter values
    return(union_server)
  }
  
  # Return the sidebar component structure
  list(
    ui = sidebar_ui,
    server = sidebar_server,
    defaults = sidebar_union$defaults
  )
}

#' Create extended sidebar with additional filter tabs
#'
#' @param id The component ID 
#' @param app_data_connection Data connection
#' @param active_tab Reactive value tracking active tab
#'
#' @return A sidebar component with UI and server parts
#' @export
ExtendedSidebarComponent <- function(id, app_data_connection = NULL, active_tab = reactiveVal("micro_tab"), translate = function(x) x) {
  # Load required filter components
  source("update_scripts/global_scripts/10_rshinyapp_components/filters/CommonFiltersComponent.R")
  source("update_scripts/global_scripts/10_rshinyapp_components/filters/MicroFiltersComponent.R")
  source("update_scripts/global_scripts/10_rshinyapp_components/filters/MacroFiltersComponent.R")
  
  # Create a unified sidebar using Union
  sidebar_union <- Union(
    id,
    common = CommonFiltersComponent(paste0(id, "_common"), app_data_connection, NULL, translate),
    micro = MicroFiltersComponent(paste0(id, "_micro"), app_data_connection, NULL, translate),
    macro = MacroFiltersComponent(paste0(id, "_macro"), app_data_connection, NULL, translate),
    config = list(
      initial_visibility = list(
        common = TRUE,
        micro = TRUE,   # Initially show micro filters
        macro = FALSE   # Initially hide macro filters
      )
    )
  )
  
  # Create the sidebar container
  sidebar_ui <- function(id) {
    bs4Dash::dashboardSidebar(
      fixed = TRUE,
      skin = "light",
      status = "primary",
      elevation = 3,
      
      # Filters header
      div(
        class = "filters-header app-header",
        h3(
          class = "app-title",
          translate("Application Settings")
        )
      ),
      
      # Include the union filter UI
      sidebar_union$ui$filter(id)
    )
  }
  
  # Sidebar server function
  sidebar_server <- function(input, output, session) {
    # Initialize the union server
    union_server <- sidebar_union$server(id, app_data_connection, session)
    
    # Control visibility based on active tab
    observe({
      current_tab <- active_tab()
      
      # Toggle filter component visibility based on active tab
      if (current_tab == "micro_tab") {
        union_server$component_state$toggle_component("micro", TRUE)
        union_server$component_state$toggle_component("macro", FALSE)
      } else if (current_tab == "macro_tab") {
        union_server$component_state$toggle_component("micro", FALSE)
        union_server$component_state$toggle_component("macro", TRUE)
      }
    })
    
    # Return the union server for external access to filter values
    return(union_server)
  }
  
  # Return the sidebar component structure
  list(
    ui = sidebar_ui,
    server = sidebar_server,
    defaults = sidebar_union$defaults
  )
}