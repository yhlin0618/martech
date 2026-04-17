#' Micro Customer Profile Server Component
#'
#' This component provides the server-side logic for displaying a customer's profile information
#' in the Micro section of the app. It follows the "one function per file" principle and
#' the section_component Shiny naming convention.
#'
#' @param id The component ID
#' @param data_source A reactive data source containing customer information
#'
#' @return A server function for the micro customer profile component
#' 
#' @examples
#' # In the server function
#' microCustomerProfileServer("customer1", reactive({customer_data}))
#'
#' @export
microCustomerProfileServer <- function(id, data_source) {
  moduleServer(id, function(input, output, session) {
    # Load customer data for selector
    observe({
      customers <- data_source()
      
      if (!is.null(customers) && nrow(customers) > 0) {
        updateSelectizeInput(
          session,
          "customer_id", 
          choices = unique(customers$customer_id),
          selected = customers$customer_id[1]
        )
      }
    })
    
    # Get selected customer data
    selected_customer <- reactive({
      req(input$customer_id)
      
      customers <- data_source()
      customers %>% filter(customer_id == input$customer_id)
    })
    
    # Render customer profile details
    output$profile_details <- renderUI({
      customer <- selected_customer()
      
      req(nrow(customer) > 0)
      
      tagList(
        h4(customer$customer_name),
        
        div(
          class = "profile-details",
          
          div(
            class = "detail-product",
            p(strong("Email:"), customer$email)
          ),
          
          div(
            class = "detail-product",
            p(strong("First Order:"), format(customer$first_order_date, "%Y-%m-%d"))
          ),
          
          div(
            class = "detail-product",
            p(strong("Total Orders:"), customer$order_count)
          ),
          
          div(
            class = "detail-product",
            p(strong("Total Spend:"), paste0("$", format(customer$total_spend, big.mark = ",")))
          )
        )
      )
    })
  })
}