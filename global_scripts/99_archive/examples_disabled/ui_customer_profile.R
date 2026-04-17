#' Customer Profile UI Module
#'
#' This module provides the UI components for displaying a customer's profile information.
#' It follows the "one function per file" principle and the Shiny module naming convention.
#'
#' @param id The module ID
#'
#' @return A UI component for the customer profile module
#' 
#' @examples
#' # In the main UI
#' fluidPage(
#'   customerProfileUI("customer1")
#' )
#'
#' @export
customerProfileUI <- function(id) {
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