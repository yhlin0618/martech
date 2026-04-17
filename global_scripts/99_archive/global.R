# Global settings and dependencies for MAMBA Precision Marketing App

# Load required packages
library(shiny)
library(bslib)
library(bsicons)
library(dplyr)
library(tidyr)
library(lubridate)
library(ggplot2)
library(plotly)
library(DBI)
library(duckdb)
library(DT)
library(scales)
library(leaflet)
library(treemap)
library(RColorBrewer)
library(shinyjs)
library(sf)
library(psych)
library(openxlsx)
library(patchwork)

# Source local scripts
if (file.exists("local_scripts/init.R")) {
  source("local_scripts/init.R")
}

# Create directories if they don't exist
for (dir in c("update_scripts/global_scripts/config", 
               "update_scripts/global_scripts/utils", 
               "app_data/scd_type1", 
               "app_data/scd_type2")) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
}

# Source utility functions
source_files <- function(dir) {
  files <- list.files(dir, pattern = "\\.R$", full.names = TRUE)
  for (file in files) {
    tryCatch({
      source(file)
    }, error = function(e) {
      warning("Error sourcing ", file, ": ", e$message)
    })
  }
}

# Try to source utility functions
tryCatch({
  source_files("update_scripts/global_scripts/utils")
}, error = function(e) {
  warning("Error sourcing utility functions: ", e$message)
})

# Try to source config files
tryCatch({
  source_files("update_scripts/global_scripts/config")
}, error = function(e) {
  warning("Error sourcing config files: ", e$message)
})

# Create sample data if it doesn't exist
if (!file.exists("app_data/mamba_data.duckdb")) {
  # Sample product dictionary
  product_line_dictionary <- list(
    "001" = "Sports Apparel",
    "002" = "Athletic Footwear",
    "003" = "Fitness Equipment",
    "004" = "Sports Nutrition",
    "005" = "Team Gear"
  )
  
  # Save to global environment
  assign("product_line_dictionary", product_line_dictionary, envir = .GlobalEnv)
  
  # Create sample sales data
  create_sample_data <- function() {
    # Create connection
    con <- dbConnect(duckdb::duckdb(), dbdir = "app_data/mamba_data.duckdb")
    
    # Create sample tables
    set.seed(123)
    
    # Customer data
    customers <- data.frame(
      customer_id = paste0("CUST", 1000:1999),
      first_name = sample(c("John", "Jane", "Michael", "Emily", "David", "Sarah", "Robert", "Lisa"), 1000, replace = TRUE),
      last_name = sample(c("Smith", "Johnson", "Williams", "Brown", "Jones", "Miller", "Davis", "Garcia"), 1000, replace = TRUE),
      email = paste0("customer", 1000:1999, "@example.com"),
      state = sample(state.abb, 1000, replace = TRUE),
      zip = sample(10000:99999, 1000, replace = TRUE),
      gender = sample(c("M", "F"), 1000, replace = TRUE, prob = c(0.48, 0.52)),
      age_group = sample(c("18-24", "25-34", "35-44", "45-54", "55-64", "65+"), 1000, replace = TRUE),
      signup_date = sample(seq(as.Date('2020-01-01'), as.Date('2023-12-31'), by = "day"), 1000, replace = TRUE)
    )
    dbWriteTable(con, "customers", customers, overwrite = TRUE)
    
    # Product data
    products <- data.frame(
      product_id = paste0("PROD", 100:199),
      product_line_id = sample(names(product_line_dictionary), 100, replace = TRUE),
      product_name = paste("MAMBA", sample(c("Pro", "Elite", "Performance", "Signature", "Team"), 100, replace = TRUE), 
                          sample(c("Shoes", "Shirt", "Shorts", "Jacket", "Bag", "Hat", "Socks"), 100, replace = TRUE)),
      base_price = round(runif(100, 19.99, 199.99), 2),
      category = sample(c("Apparel", "Footwear", "Equipment", "Accessories", "Nutrition"), 100, replace = TRUE),
      subcategory = sample(c("Men's", "Women's", "Unisex", "Youth", "Professional"), 100, replace = TRUE),
      launch_date = sample(seq(as.Date('2020-01-01'), as.Date('2023-12-31'), by = "day"), 100, replace = TRUE)
    )
    dbWriteTable(con, "products", products, overwrite = TRUE)
    
    # Sales data
    # Generate sales over 3 years
    dates <- seq(as.Date('2021-01-01'), as.Date('2023-12-31'), by = "day")
    sales <- data.frame()
    
    for (date in dates) {
      # Generate more sales for certain days (weekends, holidays)
      day_factor <- ifelse(weekdays(date) %in% c("Saturday", "Sunday"), 1.5, 1.0)
      month_factor <- ifelse(month(date) %in% c(11, 12), 1.8, 1.0) # Higher sales in Nov/Dec
      
      # Random number of sales for this day
      num_sales <- rpois(1, lambda = 10 * day_factor * month_factor)
      
      if (num_sales > 0) {
        day_sales <- data.frame(
          sale_id = paste0("SALE", sample(100000:999999, num_sales)),
          sale_date = date,
          customer_id = sample(customers$customer_id, num_sales, replace = TRUE),
          product_id = sample(products$product_id, num_sales, replace = TRUE),
          quantity = sample(1:5, num_sales, replace = TRUE, prob = c(0.7, 0.15, 0.1, 0.03, 0.02)),
          sales_channel = sample(c("amazon", "officialwebsite", "ebay"), num_sales, replace = TRUE, prob = c(0.6, 0.3, 0.1)),
          discount_pct = sample(c(0, 10, 15, 20, 25, 30), num_sales, replace = TRUE, prob = c(0.7, 0.1, 0.1, 0.05, 0.03, 0.02))
        )
        
        sales <- rbind(sales, day_sales)
      }
    }
    
    # Join with product data to get price
    sales <- merge(sales, products[, c("product_id", "base_price", "product_line_id")], by = "product_id")
    
    # Calculate sale amount with discount
    sales$unit_price <- sales$base_price * (1 - sales$discount_pct/100)
    sales$total_amount <- sales$unit_price * sales$quantity
    
    # Add some random shipping and tax
    sales$shipping <- ifelse(sales$total_amount > 100, 0, sample(c(4.99, 6.99, 8.99), nrow(sales), replace = TRUE))
    sales$tax <- round(sales$total_amount * 0.08, 2)
    sales$grand_total <- sales$total_amount + sales$shipping + sales$tax
    
    # Add some states and zip codes
    sales <- merge(sales, customers[, c("customer_id", "state", "zip")], by = "customer_id")
    
    # Write to database
    dbWriteTable(con, "sales", sales, overwrite = TRUE)
    
    # Marketing campaigns
    campaigns <- data.frame(
      campaign_id = paste0("CAMP", 100:149),
      campaign_name = paste("MAMBA", sample(c("Spring", "Summer", "Fall", "Winter", "Holiday"), 50, replace = TRUE), 
                            sample(c("Sale", "Promotion", "Launch", "Event", "Discount"), 50, replace = TRUE)),
      start_date = sample(seq(as.Date('2021-01-01'), as.Date('2023-12-31'), by = "day"), 50, replace = TRUE),
      channel = sample(c("Email", "Social", "Display", "Search", "Affiliate"), 50, replace = TRUE),
      budget = round(runif(50, 1000, 50000), 2),
      target_audience = sample(c("All", "Men", "Women", "Youth", "Athletes"), 50, replace = TRUE)
    )
    
    # Set end dates 14-60 days after start
    campaigns$end_date <- campaigns$start_date + sample(14:60, nrow(campaigns), replace = TRUE)
    
    dbWriteTable(con, "campaigns", campaigns, overwrite = TRUE)
    
    # Campaign performance data
    campaign_performance <- data.frame()
    
    for (i in 1:nrow(campaigns)) {
      # Daily performance metrics
      days <- seq(campaigns$start_date[i], campaigns$end_date[i], by = "day")
      
      daily_performance <- data.frame(
        campaign_id = campaigns$campaign_id[i],
        date = days,
        impressions = round(runif(length(days), 1000, 10000)),
        clicks = NA,
        conversions = NA,
        revenue = NA
      )
      
      # Calculate dependent metrics with some randomness
      daily_performance$clicks <- round(daily_performance$impressions * runif(nrow(daily_performance), 0.01, 0.08))
      daily_performance$conversions <- round(daily_performance$clicks * runif(nrow(daily_performance), 0.02, 0.15))
      daily_performance$revenue <- round(daily_performance$conversions * runif(nrow(daily_performance), 50, 200), 2)
      
      campaign_performance <- rbind(campaign_performance, daily_performance)
    }
    
    dbWriteTable(con, "campaign_performance", campaign_performance, overwrite = TRUE)
    
    # Customer segments
    segments <- data.frame(
      segment_id = c("NEW", "ACTIVE", "AT_RISK", "DORMANT", "LOST"),
      segment_name = c("New Customers", "Active Customers", "At Risk", "Dormant", "Lost Customers"),
      description = c(
        "First purchase within last 30 days",
        "Multiple purchases, last purchase within 90 days",
        "Previously active, no purchase in 90-180 days",
        "No purchase in 180-365 days",
        "No purchase in over 365 days"
      )
    )
    
    dbWriteTable(con, "segments", segments, overwrite = TRUE)
    
    # Assign customers to segments
    customer_segments <- data.frame(
      customer_id = customers$customer_id,
      segment_id = sample(segments$segment_id, nrow(customers), replace = TRUE, 
                          prob = c(0.15, 0.35, 0.2, 0.15, 0.15)),
      assigned_date = as.Date('2024-03-01')
    )
    
    dbWriteTable(con, "customer_segments", customer_segments, overwrite = TRUE)
    
    # Close the connection
    dbDisconnect(con)
    
    message("Sample data created successfully")
  }
  
  # Create sample data
  create_sample_data()
}

# Connect to database
tryCatch({
  con <- dbConnect(duckdb::duckdb(), dbdir = "app_data/mamba_data.duckdb")
  
  # Load product dictionary from database if it doesn't exist in global environment
  if (!exists("product_line_dictionary")) {
    products <- dbGetQuery(con, "SELECT DISTINCT product_line_id FROM products")
    product_names <- dbGetQuery(con, "SELECT DISTINCT product_line_id, category FROM products")
    
    # Create product line dictionary
    product_line_dictionary <- setNames(
      as.list(unique(product_names$category)),
      unique(product_names$product_line_id)
    )
    
    # Save to global environment
    assign("product_line_dictionary", product_line_dictionary, envir = .GlobalEnv)
  }
  
  # Store connection in global environment
  assign("db_connection", con, envir = .GlobalEnv)
  
  # Clean up on app exit
  onStop(function() {
    if (exists("db_connection")) {
      dbDisconnect(db_connection)
    }
  })
  
}, error = function(e) {
  message("Error connecting to database: ", e$message)
})

# Create a function for safe database queries
safe_query <- function(query, conn = db_connection) {
  tryCatch({
    dbGetQuery(conn, query)
  }, error = function(e) {
    warning("Error executing query: ", e$message)
    return(NULL)
  })
}

# Global app settings
app_settings <- list(
  title = "MAMBA Precision Marketing Platform",
  version = "1.0.0",
  company = "MAMBA Analytics",
  theme = bs_theme(
    version = 5,
    bootswatch = "cerulean",
    primary = "#004d99",  # MAMBA primary color
    secondary = "#ff7700", # MAMBA secondary color
    base_font = font_google("Noto Sans TC"),
    heading_font = font_google("Noto Sans TC")
  ),
  date_range = c(as.Date("2021-01-01"), as.Date("2023-12-31"))
)

# Set global theme
bs_theme_set(app_settings$theme)