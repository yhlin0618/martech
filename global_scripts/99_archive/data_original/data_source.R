# Data Source Module
# Centralized data connection and fetching logic

#' Data Source Module Server Function
#'
#' This module handles database connections and provides reactive datasets
#' that can be accessed by other modules
#'
#' @param id The module ID
#'
#' @return A list of reactive values and functions
#'
dataSourceServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Initialize database connection
    connection <- reactive({
      conn <- dbConnect(duckdb(), dbdir = file.path("app_data.duckdb"), read_only = TRUE)
      return(conn)
    })
    
    # Helper function to get filters from inputs
    getFilters <- reactive({
      list(
        distribution_channel = req(session$userData$filters$distribution_channel),
        product_category = req(session$userData$filters$product_category),
        geo = req(session$userData$filters$geo),
        time_scale_profile = req(session$userData$filters$time_scale_profile)
      )
    })
    
    # NES Trend Data
    nes_trend <- reactive({
      filters <- getFilters()
      
      dta <- tbl(connection(), "nes_trend") %>% 
        filter(source_filter == filters$distribution_channel,
               product_line_id_filter == filters$product_category,
               state_filter == filters$geo) %>%
        select(-any_of(ends_with("filter")), time_condition_filter) %>% 
        collect()
      
      req(nrow(dta) > 0)  # Ensure data is not empty
      return(dta)
    })
    
    # DNA Trend Data
    dna_trend <- reactive({
      filters <- getFilters()
      
      dta <- tbl(connection(), "dna_trend") %>% 
        filter(source_filter == filters$distribution_channel,
               product_line_id_filter == filters$product_category,
               state_filter == filters$geo) %>%
        select(-any_of(ends_with("filter")), time_condition_filter) %>% 
        collect()
      
      req(nrow(dta) > 0)  # Ensure data is not empty
      return(dta)
    })
    
    # Competitor Sales Data
    competiter_sales_dta <- reactive({
      filters <- getFilters()
      
      dta <- tbl(connection(), "amazon_competitor_sales_dta") %>% 
        left_join(
          tbl(connection(), "asin_to_product_dictionary"), 
          by = join_by(asin, product_line_id), 
          copy = TRUE
        ) %>%
        filter(product_line_id == filters$product_category) %>%
        collect()
      
      req(nrow(dta) > 0)  # Ensure data is not empty
      return(dta)
    })
    
    # Sales by Time and State
    sales_by_time_state <- reactive({
      filters <- getFilters()
      
      dta <- tbl(connection(), "sales_by_time_state") %>% 
        filter(source_filter == filters$distribution_channel,
               product_line_id_filter == filters$product_category,
               time_condition_filter == "now") %>%
        select(-source_filter, -product_line_id_filter, -time_condition_filter) %>% 
        group_by(state_filter, time_scale = floor_date(time_scale, unit = filters$time_scale_profile)) %>% 
        summarise_all(sum, na.rm = TRUE) %>% 
        collect()
      
      req(nrow(dta) > 0)  # Ensure data is not empty
      
      # Get date range
      date_range <- tbl(connection(), "sales_by_time_state") %>% 
        filter(source_filter == filters$distribution_channel) %>%
        summarise(
          start_date = min(time_scale, na.rm = TRUE),
          end_date = max(time_scale, na.rm = TRUE)
        ) %>% 
        collect()
      
      start_date <- date_range$start_date
      end_date <- date_range$end_date 
      
      # Create complete time series
      complete_time_scale <- seq.Date(
        from = floor_date(start_date, filters$time_scale_profile),
        to = floor_date(end_date - days(1), filters$time_scale_profile),
        by = filters$time_scale_profile
      )
      
      # Complete data for missing time periods
      dta2 <- dta %>%
        complete(
          time_scale = complete_time_scale,
          fill = list(new_customers = 0, num_customers = 0)
        ) %>% 
        arrange(state_filter, time_scale)
      
      # Calculate derived metrics
      dta3 <- dta2 %>% 
        mutate(cum_customers = cumsum(new_customers)) %>% 
        mutate(
          last_cum_customers = lag(cum_customers, default = NA),
          last_new_customers = lag(new_customers, default = NA),
          total_difference = total - lag(total, default = NA),
          total_change_rate = ifelse(
            (total_difference / lag(total, default = NA)) > 1.5, 
            1.5, 
            (total_difference / lag(total, default = NA))
          ),
          customer_acquisition_rate = ifelse(
            (new_customers / last_cum_customers) > 1.5, 
            1.5, 
            (new_customers / last_cum_customers)
          ),
          customer_retention_rate = ifelse(
            cum_customers == new_customers, 
            NA,
            (cum_customers - new_customers) / cum_customers
          ),
          average = total / num_customers
        ) %>% 
        select(-last_cum_customers, -last_new_customers) %>%
        mutate(time_interval_label = formattime(time_scale, filters$time_scale_profile)) %>% 
        ungroup()
      
      return(dta3)
    })
    
    # Sales by Time and ZIP
    sales_by_time_zip <- reactive({
      filters <- getFilters()
      
      dta <- tbl(connection(), "sales_by_time_zip") %>% 
        filter(source_filter == filters$distribution_channel,
               product_line_id_filter == filters$product_category,
               time_condition_filter == "now") %>%
        select(-source_filter, -product_line_id_filter, -time_condition_filter) %>% 
        group_by(zipcode, time_scale = floor_date(time_scale, unit = filters$time_scale_profile)) %>% 
        summarise_all(sum, na.rm = TRUE) %>% 
        collect()
      
      req(nrow(dta) > 0)  # Ensure data is not empty
      
      # Get date range
      date_range <- tbl(connection(), "sales_by_time_zip") %>% 
        filter(source_filter == filters$distribution_channel) %>% 
        summarise(
          start_date = min(time_scale, na.rm = TRUE),
          end_date = max(time_scale, na.rm = TRUE)
        ) %>% 
        collect()
      
      start_date <- date_range$start_date
      end_date <- date_range$end_date
      
      # Create complete time series
      complete_time_scale <- seq.Date(
        from = floor_date(start_date, filters$time_scale_profile),
        to = floor_date(end_date - days(1), filters$time_scale_profile),
        by = filters$time_scale_profile
      )
      
      # Get all unique ZIP codes
      all_zipcodes <- dta %>% select(zipcode) %>% unique() %>% pull()
      
      # Create expanded grid with all combinations
      expanded_data <- expand_grid(
        zipcode = all_zipcodes,
        time_scale = tail(complete_time_scale, n = 2)
      )
      
      # Join and fill missing values
      dta2 <- expanded_data %>%
        left_join(dta, by = c("zipcode", "time_scale")) %>%
        mutate(
          new_customers = tidyr::replace_na(new_customers, 0),
          num_customers = tidyr::replace_na(num_customers, 0),
          total = tidyr::replace_na(total, 0)
        ) %>% 
        group_by(zipcode) %>% 
        arrange(zipcode, time_scale)
      
      # Calculate derived metrics
      dta3 <- dta2 %>% 
        mutate(cum_customers = cumsum(new_customers)) %>% 
        mutate(
          last_cum_customers = lag(cum_customers, default = NA),
          last_new_customers = lag(new_customers, default = NA),
          total_difference = total - lag(total, default = NA),
          total_change_rate = ifelse(
            (total_difference / lag(total, default = NA)) > 1.5, 
            1.5, 
            (total_difference / lag(total, default = NA))
          ),
          customer_acquisition_rate = ifelse(
            (new_customers / last_cum_customers) > 1.5, 
            1.5, 
            (new_customers / last_cum_customers)
          ),
          customer_retention_rate = ifelse(
            cum_customers == new_customers, 
            NA,
            (cum_customers - new_customers) / cum_customers
          ),
          average = total / num_customers
        ) %>% 
        select(-last_cum_customers, -last_new_customers) %>%
        mutate(time_interval_label = formattime(time_scale, filters$time_scale_profile)) %>% 
        filter(time_scale == last(complete_time_scale)) %>% 
        ungroup()
      
      return(dta3)
    })
    
    # Sales by Customer
    sales_by_customer <- reactive({
      filters <- getFilters()
      
      # Base query with filters
      dta <- tbl(connection(), "sales_by_customer_dta") %>% 
        filter(
          source_filter == filters$distribution_channel,
          product_line_id_filter == filters$product_category,
          time_condition_filter == "now",
          state_filter == filters$geo
        ) %>%
        select(-any_of(ends_with("filter")))
      
      # Add customer names depending on source
      if (filters$distribution_channel == "amazon") {
        dta2 <- dta %>% mutate(customer_name = customer_id) %>% collect()
      } else if (filters$distribution_channel == "officialwebsite") {
        dta2 <- dta %>% 
          left_join(
            tbl(connection(), "customer_id_name_dictionary"), 
            by = join_by(customer_id), 
            copy = TRUE
          ) %>% 
          collect()
      } else {
        dta2 <- NULL
      }
      
      req(nrow(dta2) > 0)  # Ensure data is not empty
      return(dta2)
    })
    
    # Map data (for geographic visualizations)
    map_dta <- reactive({
      filters <- getFilters()
      geo_map <- req(input$geo_map)
      time_scale_map <- req(input$time_scale_map)
      
      # Select appropriate table based on geographic level
      table_name <- ifelse(geo_map == "state", "sales_by_customer_state_dta", "sales_by_customer_zip_dta")
      
      # Query data
      data <- tbl(connection(), table_name) %>% 
        filter(
          product_line_id_filter == filters$product_category, 
          source_filter == filters$distribution_channel,
          time_condition_filter == time_scale_map
        ) %>% 
        collect()
      
      return(data)
    })
    
    # Customer Transition Matrix (NES)
    nes_transition <- reactive({
      filters <- getFilters()
      
      # Get current customer data
      sales_by_customer_now <- tbl(connection(), "sales_by_customer_dta") %>% 
        filter(
          source_filter == filters$distribution_channel,
          product_line_id_filter == filters$product_category,
          time_condition_filter == "now",
          state_filter == filters$geo
        ) %>%
        select(-any_of(ends_with("filter")))
      
      # Get past customer data based on selected time scale
      time_scale_profile_selected2 <- Recode_time_TraceBack(filters$time_scale_profile)
      
      sales_by_customer_past <- tbl(connection(), "sales_by_customer_dta") %>% 
        filter(
          source_filter == filters$distribution_channel,
          product_line_id_filter == filters$product_category,
          time_condition_filter == time_scale_profile_selected2,
          state_filter == filters$geo
        ) %>%
        select(-any_of(ends_with("filter")))    
      
      # Create contingency table
      contingency_table <- left_join(
        sales_by_customer_past,
        sales_by_customer_now,
        by = join_by(customer_id),
        copy = TRUE
      ) %>% 
        select(nesstatus.x, nesstatus.y) %>% 
        collect() %>%  
        table()
      
      # Convert to data frame and calculate percentages
      df_long <- as.data.frame(contingency_table)
      colnames(df_long) <- c("nesstatus_pre", "nesstatus_now", "count")
      
      df_long <- df_long %>%
        group_by(nesstatus_pre) %>%
        mutate(activation_rate = count / sum(count))
      
      return(df_long)
    })
    
    # Return all reactive datasets
    return(list(
      connection = connection,
      getFilters = getFilters,
      nes_trend = nes_trend,
      dna_trend = dna_trend,
      competiter_sales_dta = competiter_sales_dta,
      sales_by_time_state = sales_by_time_state,
      sales_by_time_zip = sales_by_time_zip,
      sales_by_customer = sales_by_customer,
      map_dta = map_dta,
      nes_transition = nes_transition
    ))
  })
}