#' Micro Customer Profile UI Component
#'
#' This component provides the UI elements for displaying a customer's profile information
#' in the Micro section of the app. It follows the "one function per file" principle and 
#' the section_component Shiny naming convention.
#'
#' @param id The component ID
#'
#' @return A UI component for the micro customer profile
#' 
#' @examples
#' # In the main UI
#' fluidPage(
#'   microCustomerProfileUI("customer1")
#' )
#'
#' @export
microCustomerProfileUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    h3("Customer Profile"),
    
    # Customer selection input
    selectizeInput(
      inputId = ns("customer_id"),
      label = "Select Customer",
      choices = NULL,
      multiple = FALSE,
      options = list(plugins = list('remove_button'))
    ),
    
    # Profile display area
    div(
      class = "customer-profile-container",
      uiOutput(ns("profile_details"))
    )
  )
}