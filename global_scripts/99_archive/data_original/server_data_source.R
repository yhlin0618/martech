#' Generic Data Source Server Component
#'
#' @param id The ID of the module
#' @return A reactive data source
#' @export
dataSourceServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    # In a real application, this would load data from a database or file
    # For this example, we'll just create some sample data
    
    # Create a reactive value to hold our data
    data <- reactiveVal(
      data.frame(
        customer_id = 1:100,
        name = paste0("Customer ", 1:100),
        segment = sample(c("High Value", "Medium Value", "Low Value"), 100, replace = TRUE),
        revenue = round(runif(100, 100, 10000), 2),
        transactions = sample(1:50, 100, replace = TRUE),
        last_purchase = as.Date("2023-01-01") + sample(0:365, 100, replace = TRUE),
        stringsAsFactors = FALSE
      )
    )
    
    # Return the reactive data value
    return(data)
  })
}