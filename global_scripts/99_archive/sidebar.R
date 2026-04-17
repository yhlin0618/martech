# Sidebar Module
# Contains common filter controls used across different modules

#' Sidebar UI Function
#'
#' @param id The module ID
#'
#' @return A sidebar UI component
#'
sidebarUI <- function(id) {
  ns <- NS(id)
  
  sidebar(
    title = "選項",
    radioButtons(
      inputId = ns("distribution_channel"),
      label = "行銷通路",
      choices = list(
        "Amazon" = "amazon",
        "Official Website" = "officialwebsite"
      ),
      selected = "officialwebsite",
      width = "100%"
    ),
    radioButtons(
      inputId = ns("product_category"),
      label = "商品種類",
      choices = product_line_dictionary,
      selected = "001",
      width = "100%"
    ),
    conditionalPanel(
      condition = "input.tabset !== 'profile-track'",
      selectInput(
        inputId = ns("time_scale_profile"),
        label = "時間尺度",
        choices = list(
          "year" = "year", 
          "quarter" = "quarter", 
          "month" = "month"
        ),
        selected = "quarter"
      )
    ),
    conditionalPanel(
      condition = "input.tabset !== 'profile-track'",
      selectizeInput(
        inputId = ns("Geo_Macro_Profile"), 
        label = "地區（州或全部）",
        choices = setNames(
          as.list(state_dictionary$abbreviation), 
          state_dictionary$name
        ),
        multiple = FALSE,
        options = list(plugins = list('remove_button', 'drag_drop'))
      )
    )
  )
}

#' Sidebar Server Function
#'
#' @param id The module ID
#' @param data_source The data source reactive list
#'
#' @return None
#'
sidebarServer <- function(id, data_source) {
  moduleServer(id, function(input, output, session) {
    # Store filter values in session for access by all modules
    observe({
      session$userData$filters <- list(
        distribution_channel = input$distribution_channel,
        product_category = input$product_category,
        time_scale_profile = input$time_scale_profile,
        geo = input$Geo_Macro_Profile
      )
    })
  })
}