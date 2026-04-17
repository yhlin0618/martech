# RFM Analysis Prototype for Precision Marketing
# This script demonstrates RFM (Recency, Frequency, Monetary) analysis implementation

# Load required libraries
library(dplyr)
library(ggplot2)
library(plotly)
library(lubridate)
library(tibble)
library(DT)
library(shiny)
library(bs4Dash)
library(scales)

# Function to generate sample customer transaction data
generate_sample_data <- function(n_customers = 500, n_transactions = 2000, start_date = "2023-01-01", end_date = "2024-04-01") {
  # Convert date strings to Date objects
  start_date <- as.Date(start_date)
  end_date <- as.Date(end_date)
  
  # Create customer IDs and some attributes
  set.seed(123) # For reproducibility
  customer_data <- tibble(
    customer_id = paste0("CUST", sprintf("%05d", 1:n_customers)),
    signup_date = sample(seq(start_date - years(2), end_date - months(1), by = "day"), n_customers, replace = TRUE),
    age_group = sample(c("18-24", "25-34", "35-44", "45-54", "55+"), n_customers, replace = TRUE, 
                     prob = c(0.15, 0.25, 0.3, 0.2, 0.1)),
    gender = sample(c("M", "F", "Other"), n_customers, replace = TRUE, prob = c(0.48, 0.48, 0.04)),
    region = sample(c("North", "South", "East", "West", "Central"), n_customers, replace = TRUE)
  )
  
  # Create transaction data
  # Some customers will have more transactions than others (power law distribution)
  customer_transaction_counts <- sample(1:15, n_customers, replace = TRUE, 
                                      prob = c(0.3, 0.2, 0.15, 0.1, 0.07, 0.05, 0.03, 0.03, 0.02, 0.02, 0.01, 0.01, 0.005, 0.005, 0.005))
  
  # Generate transaction IDs for all customers based on their transaction counts
  transaction_data <- tibble(
    transaction_id = paste0("TRX", sprintf("%06d", 1:n_transactions)),
    customer_id = sample(customer_data$customer_id, n_transactions, replace = TRUE, 
                       prob = customer_transaction_counts/sum(customer_transaction_counts)),
    transaction_date = sample(seq(start_date, end_date, by = "day"), n_transactions, replace = TRUE),
    amount = round(rlnorm(n_transactions, meanlog = 4, sdlog = 1), 2), # Log-normal distribution for amount
    product_category = sample(
      c("Electronics", "Clothing", "Home", "Beauty", "Food", "Books", "Sports", "Toys"),
      n_transactions, replace = TRUE,
      prob = c(0.2, 0.25, 0.15, 0.1, 0.1, 0.08, 0.07, 0.05)
    ),
    payment_method = sample(
      c("Credit Card", "Debit Card", "PayPal", "Apple Pay", "Google Pay"),
      n_transactions, replace = TRUE,
      prob = c(0.4, 0.3, 0.2, 0.05, 0.05)
    ),
    channel = sample(
      c("Website", "Mobile App", "In-store", "Phone"),
      n_transactions, replace = TRUE,
      prob = c(0.5, 0.3, 0.15, 0.05)
    )
  )
  
  # Order by transaction date
  transaction_data <- transaction_data %>%
    arrange(transaction_date)
  
  # Return both datasets
  list(
    customers = customer_data,
    transactions = transaction_data
  )
}

# Function to calculate RFM metrics
calculate_rfm <- function(transaction_data, customer_data, analysis_date = Sys.Date()) {
  # Convert analysis_date to Date object if it's not already
  analysis_date <- as.Date(analysis_date)
  
  # Calculate RFM metrics for each customer
  rfm_data <- transaction_data %>%
    group_by(customer_id) %>%
    summarise(
      recency = as.numeric(difftime(analysis_date, max(transaction_date), units = "days")),
      frequency = n(),
      monetary = sum(amount),
      avg_order_value = mean(amount),
      first_purchase = min(transaction_date),
      last_purchase = max(transaction_date),
      days_as_customer = as.numeric(difftime(analysis_date, first_purchase, units = "days")),
      purchase_frequency = frequency / (as.numeric(difftime(last_purchase, first_purchase, units = "days")) + 1) * 30, # Monthly frequency
      .groups = "drop"
    )
  
  # Join with customer data to add demographic information
  rfm_data <- rfm_data %>%
    left_join(customer_data, by = "customer_id")
  
  # Calculate RFM scores (1-5 scale, 5 being best)
  # For recency, lower is better
  # For frequency and monetary, higher is better
  rfm_scored <- rfm_data %>%
    mutate(
      r_score = ntile(desc(recency), 5),
      f_score = ntile(frequency, 5),
      m_score = ntile(monetary, 5),
      rfm_score = r_score + f_score + m_score,
      rfm_segment = case_when(
        r_score >= 4 & f_score >= 4 & m_score >= 4 ~ "Champions",
        r_score >= 3 & f_score >= 3 & m_score >= 3 ~ "Loyal Customers",
        r_score >= 3 & f_score >= 1 & m_score >= 2 ~ "Potential Loyalists",
        r_score >= 4 & f_score <= 2 & m_score <= 2 ~ "New Customers",
        r_score <= 2 & f_score >= 3 & m_score >= 3 ~ "At Risk",
        r_score <= 2 & f_score >= 3 & m_score <= 2 ~ "Can't Lose Them",
        r_score <= 2 & f_score <= 2 & m_score <= 2 ~ "Hibernating",
        r_score <= 1 & f_score <= 1 & m_score <= 1 ~ "Lost",
        TRUE ~ "Others"
      )
    )
  
  return(rfm_scored)
}

# Function to create RFM visualizations
create_rfm_visualizations <- function(rfm_data) {
  # 1. RFM Segment Distribution
  segment_plot <- rfm_data %>%
    count(rfm_segment) %>%
    mutate(
      rfm_segment = factor(rfm_segment, levels = c(
        "Champions", "Loyal Customers", "Potential Loyalists", 
        "New Customers", "At Risk", "Can't Lose Them", 
        "Hibernating", "Lost", "Others"
      )),
      percentage = n / sum(n) * 100
    ) %>%
    ggplot(aes(x = reorder(rfm_segment, -n), y = n, fill = rfm_segment)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = paste0(round(percentage, 1), "%")), vjust = -0.5, size = 3.5) +
    scale_fill_brewer(palette = "Set3") +
    labs(title = "Customer Segments Distribution",
         x = "RFM Segment",
         y = "Number of Customers") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # 2. Recency vs Frequency with Monetary as bubble size
  rf_bubble_plot <- rfm_data %>%
    ggplot(aes(x = recency, y = frequency, size = monetary, color = rfm_segment)) +
    geom_point(alpha = 0.7) +
    scale_size_continuous(range = c(2, 10)) +
    scale_color_brewer(palette = "Set3") +
    labs(title = "Recency vs Frequency Bubble Plot",
         x = "Recency (days since last purchase)",
         y = "Frequency (number of purchases)",
         size = "Total Spend") +
    theme_minimal()
  
  # 3. Average Order Value by Segment
  aov_by_segment <- rfm_data %>%
    group_by(rfm_segment) %>%
    summarise(
      avg_order_value = mean(avg_order_value),
      .groups = "drop"
    ) %>%
    mutate(rfm_segment = factor(rfm_segment, levels = c(
      "Champions", "Loyal Customers", "Potential Loyalists", 
      "New Customers", "At Risk", "Can't Lose Them", 
      "Hibernating", "Lost", "Others"
    ))) %>%
    ggplot(aes(x = reorder(rfm_segment, -avg_order_value), y = avg_order_value, fill = rfm_segment)) +
    geom_bar(stat = "identity") +
    scale_fill_brewer(palette = "Set3") +
    scale_y_continuous(labels = scales::dollar_format()) +
    labs(title = "Average Order Value by Customer Segment",
         x = "RFM Segment",
         y = "Average Order Value") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # 4. RFM Heatmap
  rfm_heatmap <- rfm_data %>%
    group_by(r_score, f_score) %>%
    summarise(count = n(), .groups = "drop") %>%
    ggplot(aes(x = factor(r_score), y = factor(f_score), fill = count)) +
    geom_tile() +
    scale_fill_gradient(low = "white", high = "steelblue") +
    geom_text(aes(label = count), color = "black", size = 3) +
    labs(title = "RFM Heatmap (Recency vs Frequency)",
         x = "Recency Score (5 = most recent)",
         y = "Frequency Score (5 = most frequent)",
         fill = "Customer Count") +
    theme_minimal() +
    coord_equal()
  
  # 5. Monetary Distribution by Segment
  monetary_boxplot <- rfm_data %>%
    mutate(rfm_segment = factor(rfm_segment, levels = c(
      "Champions", "Loyal Customers", "Potential Loyalists", 
      "New Customers", "At Risk", "Can't Lose Them", 
      "Hibernating", "Lost", "Others"
    ))) %>%
    ggplot(aes(x = rfm_segment, y = monetary, fill = rfm_segment)) +
    geom_boxplot() +
    scale_fill_brewer(palette = "Set3") +
    scale_y_continuous(labels = scales::dollar_format()) +
    labs(title = "Monetary Value Distribution by Segment",
         x = "RFM Segment",
         y = "Total Spend") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  # Make plots interactive
  segment_plot_interactive <- ggplotly(segment_plot)
  rf_bubble_plot_interactive <- ggplotly(rf_bubble_plot)
  aov_by_segment_interactive <- ggplotly(aov_by_segment)
  rfm_heatmap_interactive <- ggplotly(rfm_heatmap)
  monetary_boxplot_interactive <- ggplotly(monetary_boxplot)
  
  # Return list of plots
  list(
    segment_plot = segment_plot_interactive,
    rf_bubble_plot = rf_bubble_plot_interactive,
    aov_by_segment = aov_by_segment_interactive,
    rfm_heatmap = rfm_heatmap_interactive,
    monetary_boxplot = monetary_boxplot_interactive
  )
}

# Generate segment recommendations
generate_recommendations <- function(rfm_data) {
  segment_strategies <- list(
    "Champions" = list(
      description = "Your best customers who bought recently, buy often, and spend the most.",
      strategies = c(
        "Reward them with loyalty programs, exclusive offers, and VIP treatment",
        "Use them as brand advocates and seek referrals",
        "Gather feedback on products and services",
        "Consider them for early product releases and beta testing"
      )
    ),
    "Loyal Customers" = list(
      description = "Customers who buy regularly and are responsive to promotions.",
      strategies = c(
        "Upsell higher-value products",
        "Increase purchase frequency with targeted offers",
        "Create cross-selling opportunities",
        "Implement loyalty programs"
      )
    ),
    "Potential Loyalists" = list(
      description = "Recent customers with average frequency and monetary values.",
      strategies = c(
        "Increase engagement through personalized email marketing",
        "Encourage more frequent purchases with targeted promotions",
        "Create membership or subscription options",
        "Recommend complementary products"
      )
    ),
    "New Customers" = list(
      description = "Customers who made purchases recently but not frequently.",
      strategies = c(
        "Welcome programs and onboarding experiences",
        "Educational content about your products/services",
        "Early follow-up to ensure satisfaction",
        "Acquisition-to-second-purchase conversion campaigns"
      )
    ),
    "At Risk" = list(
      description = "Customers who haven't purchased recently, but had high frequency and spending.",
      strategies = c(
        "Reactivation campaigns with personalized offers",
        "Gather feedback on why they stopped purchasing",
        "Consider win-back promotions or discounts",
        "Re-engagement through new product announcements"
      )
    ),
    "Can't Lose Them" = list(
      description = "Previous high-value customers who haven't purchased recently.",
      strategies = c(
        "Create targeted win-back campaigns",
        "Aggressive reactivation offers",
        "Direct outreach for high-value accounts",
        "New product information that addresses potential issues"
      )
    ),
    "Hibernating" = list(
      description = "Customers who purchased infrequently and long ago with low spend.",
      strategies = c(
        "Reactivation campaigns with strong incentives",
        "Reminder of your value proposition",
        "Consider surveys to understand their needs better",
        "Remove from regular communications if no response"
      )
    ),
    "Lost" = list(
      description = "Customers who haven't purchased in a long time and had low engagement.",
      strategies = c(
        "Final attempt win-back campaign with significant offer",
        "Consider removing from regular communications",
        "Analyze for patterns to prevent future customer loss",
        "Request feedback on why they left"
      )
    )
  )
  
  # Calculate segment metrics for recommendations
  segment_metrics <- rfm_data %>%
    group_by(rfm_segment) %>%
    summarise(
      count = n(),
      percentage = n() / nrow(rfm_data) * 100,
      avg_recency = mean(recency),
      avg_frequency = mean(frequency),
      avg_monetary = mean(monetary),
      avg_rfm_score = mean(rfm_score),
      total_revenue = sum(monetary),
      revenue_percentage = sum(monetary) / sum(rfm_data$monetary) * 100,
      avg_days_as_customer = mean(days_as_customer),
      .groups = "drop"
    )
  
  # Create recommendations table
  recommendations <- tibble(
    segment = character(),
    customers = integer(),
    pct_customers = numeric(),
    avg_spend = numeric(),
    pct_revenue = numeric(),
    description = character(),
    strategies = character()
  )
  
  for (segment in names(segment_strategies)) {
    if (segment %in% segment_metrics$rfm_segment) {
      metrics <- segment_metrics %>% filter(rfm_segment == segment)
      
      recommendations <- recommendations %>%
        add_row(
          segment = segment,
          customers = metrics$count,
          pct_customers = round(metrics$percentage, 1),
          avg_spend = round(metrics$avg_monetary, 2),
          pct_revenue = round(metrics$revenue_percentage, 1),
          description = segment_strategies[[segment]]$description,
          strategies = paste(segment_strategies[[segment]]$strategies, collapse = "; ")
        )
    }
  }
  
  return(list(
    segment_metrics = segment_metrics,
    recommendations = recommendations
  ))
}

# Create a Shiny UI for RFM analysis
rfm_ui <- function() {
  bs4Dash::tabBox(
    width = 12,
    side = "right",
    title = "RFM Analysis",
    id = "rfm_tabs",
    status = "primary",
    elevation = 3,
    
    # Overview tab
    bs4Dash::tabPanel(
      tabName = "Overview",
      icon = icon("chart-pie"),
      fluidRow(
        bs4Dash::valueBoxOutput("total_customers_box", width = 3),
        bs4Dash::valueBoxOutput("total_revenue_box", width = 3),
        bs4Dash::valueBoxOutput("avg_order_value_box", width = 3),
        bs4Dash::valueBoxOutput("customer_retention_box", width = 3)
      ),
      fluidRow(
        column(
          width = 8,
          bs4Dash::box(
            title = "Customer Segments Distribution",
            width = NULL,
            solidHeader = TRUE,
            status = "primary",
            plotlyOutput("segment_plot", height = "400px")
          )
        ),
        column(
          width = 4,
          bs4Dash::box(
            title = "RFM Score Distribution",
            width = NULL,
            solidHeader = TRUE,
            status = "info",
            plotlyOutput("rfm_score_plot", height = "400px")
          )
        )
      ),
      fluidRow(
        bs4Dash::box(
          title = "Segment Metrics",
          width = 12,
          solidHeader = TRUE,
          status = "primary",
          DT::DTOutput("segment_metrics_table")
        )
      )
    ),
    
    # Detailed Analysis tab
    bs4Dash::tabPanel(
      tabName = "Detailed Analysis",
      icon = icon("microscope"),
      fluidRow(
        column(
          width = 6,
          bs4Dash::box(
            title = "Recency vs Frequency Analysis",
            width = NULL,
            solidHeader = TRUE,
            status = "primary",
            plotlyOutput("rf_bubble_plot", height = "400px")
          )
        ),
        column(
          width = 6,
          bs4Dash::box(
            title = "RFM Heatmap",
            width = NULL,
            solidHeader = TRUE,
            status = "info",
            plotlyOutput("rfm_heatmap", height = "400px")
          )
        )
      ),
      fluidRow(
        column(
          width = 6,
          bs4Dash::box(
            title = "Average Order Value by Segment",
            width = NULL,
            solidHeader = TRUE,
            status = "success",
            plotlyOutput("aov_segment_plot", height = "400px")
          )
        ),
        column(
          width = 6,
          bs4Dash::box(
            title = "Monetary Distribution by Segment",
            width = NULL,
            solidHeader = TRUE,
            status = "warning",
            plotlyOutput("monetary_boxplot", height = "400px")
          )
        )
      )
    ),
    
    # Customer List tab
    bs4Dash::tabPanel(
      tabName = "Customer List",
      icon = icon("users"),
      fluidRow(
        bs4Dash::box(
          title = "RFM Customer Data",
          width = 12,
          solidHeader = TRUE,
          status = "primary",
          collapsible = TRUE,
          DT::DTOutput("customer_table")
        )
      )
    ),
    
    # Marketing Recommendations tab
    bs4Dash::tabPanel(
      tabName = "Marketing Recommendations",
      icon = icon("bullseye"),
      fluidRow(
        bs4Dash::box(
          title = "Segment-Based Marketing Strategies",
          width = 12,
          solidHeader = TRUE,
          status = "primary",
          collapsible = TRUE,
          DT::DTOutput("recommendations_table")
        )
      ),
      fluidRow(
        column(
          width = 6,
          bs4Dash::box(
            title = "Revenue by Segment",
            width = NULL,
            solidHeader = TRUE,
            status = "success",
            plotlyOutput("revenue_segment_plot", height = "300px")
          )
        ),
        column(
          width = 6,
          bs4Dash::box(
            title = "Customer Distribution by Segment",
            width = NULL,
            solidHeader = TRUE,
            status = "info",
            plotlyOutput("customer_segment_plot", height = "300px")
          )
        )
      )
    )
  )
}

# Create a Shiny server function for RFM analysis
rfm_server <- function(input, output, session) {
  # Generate sample data
  data <- reactive({
    generate_sample_data(
      n_customers = 500,
      n_transactions = 2000,
      start_date = "2023-01-01",
      end_date = "2024-04-01"
    )
  })
  
  # Calculate RFM metrics
  rfm_data <- reactive({
    calculate_rfm(
      transaction_data = data()$transactions,
      customer_data = data()$customers,
      analysis_date = "2024-04-01"
    )
  })
  
  # Create visualizations
  visualizations <- reactive({
    create_rfm_visualizations(rfm_data())
  })
  
  # Generate recommendations
  recommendations <- reactive({
    generate_recommendations(rfm_data())
  })
  
  # Value boxes in Overview tab
  output$total_customers_box <- bs4Dash::renderValueBox({
    bs4Dash::valueBox(
      value = format(nrow(rfm_data()), big.mark = ","),
      subtitle = "Total Customers",
      icon = icon("users"),
      color = "primary",
      elevation = 2
    )
  })
  
  output$total_revenue_box <- bs4Dash::renderValueBox({
    bs4Dash::valueBox(
      value = dollar(sum(rfm_data()$monetary)),
      subtitle = "Total Revenue",
      icon = icon("dollar-sign"),
      color = "success",
      elevation = 2
    )
  })
  
  output$avg_order_value_box <- bs4Dash::renderValueBox({
    bs4Dash::valueBox(
      value = dollar(mean(rfm_data()$avg_order_value)),
      subtitle = "Avg. Order Value",
      icon = icon("shopping-cart"),
      color = "info",
      elevation = 2
    )
  })
  
  output$customer_retention_box <- bs4Dash::renderValueBox({
    # Customers who purchased in the last 90 days
    active_customers <- sum(rfm_data()$recency <= 90)
    retention_rate <- round(active_customers / nrow(rfm_data()) * 100, 1)
    
    bs4Dash::valueBox(
      value = paste0(retention_rate, "%"),
      subtitle = "90-Day Retention Rate",
      icon = icon("user-check"),
      color = "warning",
      elevation = 2
    )
  })
  
  # Plots in Overview tab
  output$segment_plot <- renderPlotly({
    visualizations()$segment_plot
  })
  
  output$rfm_score_plot <- renderPlotly({
    rfm_data() %>%
      count(rfm_score) %>%
      mutate(percentage = n / sum(n) * 100) %>%
      ggplot(aes(x = factor(rfm_score), y = n, fill = factor(rfm_score))) +
      geom_bar(stat = "identity") +
      geom_text(aes(label = paste0(round(percentage, 1), "%")), vjust = -0.5, size = 3.5) +
      scale_fill_viridis_d() +
      labs(title = "RFM Score Distribution",
           x = "RFM Score (3-15)",
           y = "Number of Customers") +
      theme_minimal() %>%
      ggplotly()
  })
  
  # Tables in Overview tab
  output$segment_metrics_table <- DT::renderDT({
    recommendations()$segment_metrics %>%
      select(
        rfm_segment, count, percentage, avg_recency, avg_frequency, 
        avg_monetary, avg_rfm_score, total_revenue, revenue_percentage
      ) %>%
      rename(
        "Segment" = rfm_segment,
        "Customer Count" = count,
        "% of Customers" = percentage,
        "Avg. Recency (days)" = avg_recency,
        "Avg. Frequency" = avg_frequency,
        "Avg. Monetary" = avg_monetary,
        "Avg. RFM Score" = avg_rfm_score,
        "Total Revenue" = total_revenue,
        "% of Revenue" = revenue_percentage
      ) %>%
      mutate(
        "Avg. Monetary" = dollar(`Avg. Monetary`),
        "Total Revenue" = dollar(`Total Revenue`),
        "% of Customers" = paste0(round(`% of Customers`, 1), "%"),
        "% of Revenue" = paste0(round(`% of Revenue`, 1), "%"),
        "Avg. Recency (days)" = round(`Avg. Recency (days)`, 0),
        "Avg. Frequency" = round(`Avg. Frequency`, 1),
        "Avg. RFM Score" = round(`Avg. RFM Score`, 1)
      ) %>%
      DT::datatable(
        options = list(
          pageLength = 9,
          autoWidth = TRUE,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE,
        filter = "top",
        class = "compact stripe hover"
      )
  })
  
  # Plots in Detailed Analysis tab
  output$rf_bubble_plot <- renderPlotly({
    visualizations()$rf_bubble_plot
  })
  
  output$rfm_heatmap <- renderPlotly({
    visualizations()$rfm_heatmap
  })
  
  output$aov_segment_plot <- renderPlotly({
    visualizations()$aov_by_segment
  })
  
  output$monetary_boxplot <- renderPlotly({
    visualizations()$monetary_boxplot
  })
  
  # Customer table
  output$customer_table <- DT::renderDT({
    rfm_data() %>%
      select(
        customer_id, recency, frequency, monetary, r_score, f_score, m_score, 
        rfm_score, rfm_segment, first_purchase, last_purchase, avg_order_value,
        age_group, gender, region
      ) %>%
      rename(
        "Customer ID" = customer_id,
        "Recency (days)" = recency,
        "Frequency" = frequency,
        "Monetary" = monetary,
        "R Score" = r_score,
        "F Score" = f_score,
        "M Score" = m_score,
        "RFM Score" = rfm_score,
        "Segment" = rfm_segment,
        "First Purchase" = first_purchase,
        "Last Purchase" = last_purchase,
        "AOV" = avg_order_value,
        "Age Group" = age_group,
        "Gender" = gender,
        "Region" = region
      ) %>%
      mutate(
        "Monetary" = dollar(`Monetary`),
        "AOV" = dollar(`AOV`),
        "First Purchase" = as.character(`First Purchase`),
        "Last Purchase" = as.character(`Last Purchase`)
      ) %>%
      DT::datatable(
        options = list(
          pageLength = 10,
          autoWidth = TRUE,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE,
        filter = "top",
        class = "compact stripe hover"
      )
  })
  
  # Recommendations tab
  output$recommendations_table <- DT::renderDT({
    recommendations()$recommendations %>%
      rename(
        "Segment" = segment,
        "Customers" = customers,
        "% of Customers" = pct_customers,
        "Avg. Spend" = avg_spend,
        "% of Revenue" = pct_revenue,
        "Description" = description,
        "Recommended Strategies" = strategies
      ) %>%
      mutate(
        "% of Customers" = paste0(`% of Customers`, "%"),
        "% of Revenue" = paste0(`% of Revenue`, "%"),
        "Avg. Spend" = dollar(`Avg. Spend`)
      ) %>%
      DT::datatable(
        options = list(
          pageLength = 8,
          autoWidth = TRUE,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE,
        filter = "top",
        class = "compact stripe hover"
      )
  })
  
  # Additional plots for Recommendations tab
  output$revenue_segment_plot <- renderPlotly({
    recommendations()$segment_metrics %>%
      ggplot(aes(x = reorder(rfm_segment, -revenue_percentage), y = revenue_percentage, fill = rfm_segment)) +
      geom_bar(stat = "identity") +
      geom_text(aes(label = paste0(round(revenue_percentage, 1), "%")), vjust = -0.5, size = 3.5) +
      scale_fill_brewer(palette = "Set3") +
      labs(title = "Revenue Contribution by Segment",
           x = "RFM Segment",
           y = "Percentage of Revenue") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) %>%
      ggplotly()
  })
  
  output$customer_segment_plot <- renderPlotly({
    recommendations()$segment_metrics %>%
      ggplot(aes(x = "", y = percentage, fill = rfm_segment)) +
      geom_bar(stat = "identity", width = 1) +
      coord_polar("y", start = 0) +
      scale_fill_brewer(palette = "Set3") +
      labs(title = "Customer Distribution by Segment",
           fill = "Segment") +
      theme_minimal() +
      theme(
        axis.title.x = element_blank(),
        axis.title.y = element_blank(),
        panel.border = element_blank(),
        panel.grid = element_blank(),
        axis.ticks = element_blank(),
        axis.text.x = element_blank()
      ) %>%
      ggplotly()
  })
}

# Create a standalone app for testing
if (interactive()) {
  ui <- bs4Dash::dashboardPage(
    title = "RFM Analysis Dashboard",
    header = bs4Dash::dashboardHeader(
      title = bs4Dash::dashboardBrand(
        title = "RFM Analysis",
        color = "primary",
        href = "#"
      )
    ),
    sidebar = bs4Dash::dashboardSidebar(
      skin = "light",
      bs4Dash::sidebarMenu(
        id = "menu",
        bs4Dash::menuproduct(
          text = "RFM Analysis",
          icon = icon("chart-bar"),
          startExpanded = TRUE,
          bs4Dash::menuSubproduct(
            text = "Overview",
            tabName = "rfm_overview"
          ),
          bs4Dash::menuSubproduct(
            text = "Detailed Analysis",
            tabName = "rfm_detailed"
          ),
          bs4Dash::menuSubproduct(
            text = "Customer List",
            tabName = "rfm_customers"
          ),
          bs4Dash::menuSubproduct(
            text = "Recommendations",
            tabName = "rfm_recommendations"
          )
        )
      )
    ),
    body = bs4Dash::dashboardBody(
      rfm_ui()
    ),
    footer = bs4Dash::dashboardFooter(
      left = paste("RFM Analysis Prototype", format(Sys.Date(), "%Y")),
      right = "v1.0.0"
    )
  )
  
  # Run the standalone app
  shinyApp(ui, rfm_server)
}

# Functions for integration with main app
get_rfm_ui <- function() {
  rfm_ui()
}

get_rfm_server <- function(id) {
  moduleServer(id, rfm_server)
}