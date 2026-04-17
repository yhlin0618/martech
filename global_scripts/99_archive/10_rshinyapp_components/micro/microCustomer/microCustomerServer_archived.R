# THIS FILE HAS BEEN ARCHIVED FOLLOWING R28 ARCHIVING STANDARD
# Date archived: 2025-04-07
# Reason: Combined into microCustomer.R under P15 Debug Efficiency Exception
# Replacement: microCustomer.R (contains UI, server, and defaults)

#' Micro Customer Server Component
#'
#' This component provides server-side logic for displaying detailed customer analytics
#' metrics and visualizations in the micro-level view of the application.
#'
#' IMPORTANT: This server component fulfills all outputs defined in the matching
#' microCustomerUI() function. According to the UI-Server Pairing Rule, both components
#' must always be used together in the application along with the defaults_micro_customer.R
#' file that defines default values.
#'
#' @param id The module ID
#' @param data_source The data source specification, which can be:
#'   - NULL: Will use defaults
#'   - String: A table/query name (e.g., "sales_by_customer")
#'   - Array: Multiple related tables in specific order
#'   - Object: Multiple tables with specific roles (e.g., {primary: "sales_by_customer"})
#'
#' @return None (server component with side effects)
#' @export
microCustomerServer <- function(id, data_source = NULL) {
  moduleServer(id, function(input, output, session) {
    # Reference data for labels - defined within module scope to ensure availability
    textRlabel <- c("極近", "近期", "一般", "久遠", "非常久遠")
    textFlabel <- c("極低", "低", "一般", "高", "非常高")
    textMlabel <- c("極低", "低", "一般", "高", "非常高")
    textCAIlabel <- c("不活躍", "低度活躍", "一般活躍", "活躍", "非常活躍")
    
    # Get default values for all outputs
    defaults <- microCustomerDefaults()
    
    # Helper function to render defaults from the defaults list
    renderDefaultsFromList <- function() {
      for (id in names(defaults)) {
        local({
          local_id <- id
          output[[local_id]] <- renderText({ defaults[[local_id]] })
        })
      }
    }
    
    # Initialize outputs with default values
    renderDefaultsFromList()
    
    # Process data source using the utility function
    # Define a function to get tables from the data_source
    get_table <- function(table_name) {
      tryCatch({
        if (is.null(data_source)) {
          return(data.frame())
        } else if (is.function(data_source[[table_name]])) {
          return(data_source[[table_name]]())
        } else {
          return(data.frame())
        }
      }, error = function(e) {
        message("Error retrieving table ", table_name, ": ", e$message)
        return(data.frame())
      })
    }
    
    # Use the processDataSource utility to standardize data access
    tables <- reactive({
      processDataSource(
        data_source = data_source, 
        table_names = c("primary", "sales_by_customer", "customers"),
        get_table_func = get_table
      )
    })
    
    # Customer data for dropdown list with validation
    customer_data <- reactive({
      # Access the data through the processed tables
      data <- tables()$sales_by_customer
      
      # If that's empty, try the primary table instead
      if (is.null(data) || nrow(data) == 0) {
        data <- tables()$primary
      }
      
      # Ensure we have valid data
      if (is.null(data) || nrow(data) == 0) {
        return(data.frame())
      }
      
      return(data)
    })
    
    # This component now relies on customer selection from the sidebar
    # The customer_search field in sidebarHybridUI component is used instead of a local selector
    
    # Safe value access helper function
    safeValue <- function(data, field, default = NA) {
      if (is.null(data) || nrow(data) == 0 || !field %in% names(data)) {
        return(default)
      }
      value <- data[[field]][1]
      if (is.null(value) || is.na(value)) {
        return(default)
      }
      return(value)
    }
    
    # Selected customer data directly using the first customer in the data
    # In a real app, this would be connected to the sidebar's customer selection
    selected_customer_data <- reactive({
      # Check if we have valid customer data first
      if (nrow(customer_data()) == 0 || !"customer_name" %in% names(customer_data())) {
        return(NULL)
      }
      
      # Simply use the first customer in the data (since we removed the selector)
      # In production, this would be connected to the sidebar's customer search
      customers <- customer_data()
      result <- head(customers, 1)
      
      return(result)
    })
    
    # Render customer DNA outputs with safe access
    observe({
      # Invalidate this observer when selected customer changes
      customer <- selected_customer_data()
      
      if (!is.null(customer) && nrow(customer) > 0) {
        # Customer history metrics - with safe access
        output$dna_time_first <- renderText({ 
          time_first <- safeValue(customer, "time_first", default = NA)
          if (is.na(time_first)) return(defaults$dna_time_first)
          format(time_first, "%Y-%m-%d") 
        })
        
        output$dna_time_first_tonow <- renderText({ 
          safeValue(customer, "time_first_tonow", default = defaults$dna_time_first_tonow) 
        })
        
        # RFM metrics with safe access
        output$dna_rlabel <- renderText({ 
          rlabel <- safeValue(customer, "rlabel", default = NA)
          if (is.na(rlabel) || rlabel < 1 || rlabel > length(textRlabel)) return(defaults$dna_rlabel)
          textRlabel[rlabel] 
        })
        
        output$dna_rvalue <- renderText({ 
          safeValue(customer, "rvalue", default = defaults$dna_rvalue) 
        })
        
        output$dna_flabel <- renderText({ 
          flabel <- safeValue(customer, "flabel", default = NA)
          if (is.na(flabel) || flabel < 1 || flabel > length(textFlabel)) return(defaults$dna_flabel)
          textFlabel[flabel] 
        })
        
        output$dna_fvalue <- renderText({ 
          safeValue(customer, "fvalue", default = defaults$dna_fvalue) 
        })
        
        output$dna_mlabel <- renderText({ 
          mlabel <- safeValue(customer, "mlabel", default = NA)
          if (is.na(mlabel) || mlabel < 1 || mlabel > length(textMlabel)) return(defaults$dna_mlabel)
          textMlabel[mlabel] 
        })
        
        output$dna_mvalue <- renderText({ 
          mvalue <- safeValue(customer, "mvalue", default = NA)
          if (is.na(mvalue)) return(defaults$dna_mvalue)
          round(mvalue, 2) 
        })
        
        # Customer activity metrics
        output$dna_cailabel <- renderText({ 
          cailabel <- safeValue(customer, "cailabel", default = NA)
          if (is.na(cailabel) || cailabel < 1 || cailabel > length(textCAIlabel)) return(defaults$dna_cailabel)
          textCAIlabel[cailabel] 
        })
        
        output$dna_cai <- renderText({ 
          cai <- safeValue(customer, "cai", default = NA)
          if (is.na(cai)) return(defaults$dna_cai)
          round(cai, 2) 
        })
        
        output$dna_ipt_mean <- renderText({ 
          ipt_mean <- safeValue(customer, "ipt_mean", default = NA)
          if (is.na(ipt_mean)) return(defaults$dna_ipt_mean)
          round(ipt_mean, 1) 
        })
        
        # Value metrics
        output$dna_pcv <- renderText({ 
          pcv <- safeValue(customer, "pcv", default = NA)
          if (is.na(pcv)) return(defaults$dna_pcv)
          round(pcv, 2) 
        })
        
        output$dna_clv <- renderText({ 
          clv <- safeValue(customer, "clv", default = NA)
          if (is.na(clv)) return(defaults$dna_clv)
          round(clv, 2) 
        })
        
        output$dna_cri <- renderText({ 
          cri <- safeValue(customer, "cri", default = NA)
          if (is.na(cri)) return(defaults$dna_cri)
          round(cri, 2) 
        })
        
        # Prediction metrics
        output$dna_nrec <- renderText({ 
          nrec <- safeValue(customer, "nrec", default = NA)
          if (is.na(nrec)) return(defaults$dna_nrec)
          ifelse(nrec > 0.5, "高", "低") 
        })
        
        output$dna_nrec_onemin_prob <- renderText({ 
          nrec <- safeValue(customer, "nrec", default = NA)
          if (is.na(nrec)) return(defaults$dna_nrec_onemin_prob)
          scales::percent(nrec, accuracy = 0.1) 
        })
        
        # Status metrics
        output$dna_nesstatus <- renderText({ 
          safeValue(customer, "nesstatus", default = defaults$dna_nesstatus) 
        })
        
        # Transaction metrics
        output$dna_nt <- renderText({ 
          nt <- safeValue(customer, "nt", default = NA)
          if (is.na(nt)) return(defaults$dna_nt)
          round(nt, 2) 
        })
        
        output$dna_e0t <- renderText({ 
          e0t <- safeValue(customer, "e0t", default = NA)
          if (is.na(e0t)) return(defaults$dna_e0t)
          round(e0t, 2) 
        })
      } else {
        # If no valid customer data, reset to defaults
        renderDefaultsFromList()
      }
    })
  })
}