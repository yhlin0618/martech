# Module 1.1: Customer DNA Implementation Guide for WISER

This guide walks through the step-by-step implementation of the Customer DNA analysis for the WISER project, from data preparation to analysis output.

## Prerequisites

Before starting, ensure you have:

1. **Access to WISER data sources**:
   - Amazon sales data
   - Customer attribute data (if available)

2. **Required R packages**:
   - tidyverse (dplyr, tidyr, ggplot2)
   - lubridate
   - data.table (for performance)
   - DBI and duckdb

3. **Project setup**:
   - Environment initialized
   - Database connections configured

## Implementation Steps

### Step 1: Set Up Project Environment

```r
# Enable verbose initialization for debugging
VERBOSE_INITIALIZATION <- TRUE

# Source initialization script
source(file.path("update_scripts", "global_scripts", "00_principles", "000g_initialization_update_mode.R"))

# Override any WISER-specific parameters
NESbreaks <- c(0, 1, 2, 2.5, Inf)  # NES thresholds
textNESlabel <- c("E0","S1","S2","S3")  # Status labels
```

### Step 2: Establish Database Connections

```r
# Connect to databases
raw_data <- dbConnect_from_list("raw_data", read_only = TRUE)
cleansed_data <- dbConnect_from_list("cleansed_data", read_only = FALSE)
processed_data <- dbConnect_from_list("processed_data", read_only = FALSE)

# Check connections
cat("Connected databases:\n")
cat("- raw_data tables:", length(dbListTables(raw_data)), "\n")
cat("- cleansed_data tables:", length(dbListTables(cleansed_data)), "\n")
cat("- processed_data tables:", length(dbListTables(processed_data)), "\n")
```

### Step 3: Prepare Customer Time Series Data

```r
<<<<<<< HEAD
# Load the enhanced cleansing function
source(file.path("update_scripts", "global_scripts", "15_cleanse", "cleanse_amazon_dta.R"))

# Check if we need to process raw data first
if (!dbExistsTable(cleansed_data, "amazon_sales_dta")) {
  message("Cleansing raw sales data...")
  
  # Check if raw data exists
  if (!dbExistsTable(raw_data, "amazon_sales_dta")) {
    message("Raw amazon_sales_dta table not found. Loading sample data...")
    # For testing purposes, we can load sample data
    source(file.path("update_scripts", "global_scripts", "15_cleanse", "create_sample_data.R"))
    load_sample_data_for_dna(verbose = TRUE)
  } else {
    # Use our custom cleansing function instead of process_amazon_sales
    cleanse_amazon_dta(raw_data, cleansed_data, verbose = TRUE)
  }
}

# Load sales data
message("Loading sales data...")
sales_data <- tbl(cleansed_data, "amazon_sales_dta") %>% collect()

# Validate that we got meaningful data
if (nrow(sales_data) == 0) {
  stop("No sales data found after cleansing. Please check your data source.")
}

# Ensure date/time columns are properly formatted
if (!inherits(sales_data$time, c("POSIXct", "POSIXt", "Date"))) {
  message("Converting time column to proper date format...")
  sales_data$time <- as.POSIXct(sales_data$time)
}

# Ensure we have price data for analysis
if (!"lineproduct_price" %in% names(sales_data)) {
  message("No price data found. Adding default value for analysis...")
  sales_data$lineproduct_price <- 1 # Default value to allow analysis to proceed
=======
# Query sales data
sales_data <- tbl(cleansed_data, "amazon_sales_dta") %>%
  collect()

# Check if we need to process it first
if (!"customer_id" %in% names(sales_data)) {
  message("Need to process sales data first...")
  # Import and process raw data if needed
  raw_sales_data <- tbl(raw_data, "amazon_sales_dta") %>% collect()
  
  # Process using the imported function
  sales_data <- process_amazon_sales(raw_data, cleansed_data, verbose = TRUE)
>>>>>>> origin/main
}

# Transform into customer time series format with IPT calculations
customer_time_data <- sales_data %>%
  arrange(customer_id, time) %>%
  group_by(customer_id) %>%
  mutate(
    times = row_number(),  # Purchase sequence
    ni = n(),              # Total purchases per customer
    IPT = case_when(
      times == 1 ~ as.numeric(NA),  # No IPT for first purchase
      TRUE ~ as.numeric(difftime(time, lag(time), units = "days"))
    )
  ) %>%
  ungroup()

# Check data
head(customer_time_data)
summary(customer_time_data$IPT)
cat("Number of customers:", length(unique(customer_time_data$customer_id)), "\n")
cat("Number of transactions:", nrow(customer_time_data), "\n")
<<<<<<< HEAD

# Print date range safely
tryCatch({
  date_range <- c(min(customer_time_data$time, na.rm = TRUE), max(customer_time_data$time, na.rm = TRUE))
  cat("Date range:", date_range[1], "to", date_range[2], "\n")
}, error = function(e) {
  message("Could not determine date range: ", e$message)
})
=======
cat("Date range:", min(customer_time_data$time), "to", max(customer_time_data$time), "\n")
>>>>>>> origin/main
```

### Step 4: Apply DNA Analysis

```r
# Calculate NES median if not previously set
if (!exists("Amazon_NESmedian")) {
  # Use default or calculate from data
  message("Setting NES median...")
  Amazon_NESmedian <- 2.9  # Default value
}

# Choose the appropriate DNA function based on data size
data_size <- nrow(customer_time_data)
message("Data size: ", data_size, " rows")

# Use data.table version for large datasets, dplyr for smaller ones
if (data_size > 500000) {
  message("Using data.table implementation for large dataset...")
  # Convert to data.table
  customer_time_dt <- as.data.table(customer_time_data)
  # Apply data.table version
  dna_results <- DNA_Function_data.table(customer_time_dt, 
                                         Skip.within.Subject = FALSE,
                                         replace_NESmedian = TRUE)
} else {
  message("Using dplyr implementation...")
  dna_results <- DNA_Function_dplyr(customer_time_data, 
                                   Skip.within.Subject = FALSE,
                                   replace_NESmedian = TRUE)
}

# Extract results
customer_dna <- dna_results$Data_byCustomer
nrec_accuracy <- dna_results$NrecAccu

message("DNA analysis complete.")
message("Accuracy of churn prediction: ", nrec_accuracy)
message("Number of customers analyzed: ", nrow(customer_dna))
```

### Step 5: Analyze and Enhance Customer DNA

```r
# Analyze distribution of customer statuses
nes_distribution <- customer_dna %>%
  group_by(NESstatus) %>%
  summarize(
    count = n(),
    percentage = n() / nrow(customer_dna) * 100,
    avg_clv = mean(CLV, na.rm = TRUE),
    avg_pcv = mean(PCV, na.rm = TRUE),
    avg_ipt = mean(IPT_mean, na.rm = TRUE)
  )

# Print summary
print(nes_distribution)

# Add any WISER-specific enhancements to the DNA
# For example, joining with product category preference data
if (dbExistsTable(cleansed_data, "customer_preferences")) {
  preferences <- tbl(cleansed_data, "customer_preferences") %>% collect()
  
  customer_dna <- customer_dna %>%
    left_join(preferences, by = "customer_id") %>%
    mutate(
      primary_category = ifelse(is.na(primary_category), "Unknown", primary_category)
    )
  
  message("Enhanced DNA with customer preferences")
}
```

### Step 6: Store the Results

```r
# Save to database
dbWriteTable(processed_data, "customer_dna", customer_dna, overwrite = TRUE)

# Create indexes for performance
dbExecute(processed_data, "CREATE INDEX IF NOT EXISTS idx_customer_id ON customer_dna (customer_id)")
dbExecute(processed_data, "CREATE INDEX IF NOT EXISTS idx_nesstatus ON customer_dna (NESstatus)")

message("Saved customer DNA to processed_data database")

# Optionally, save to RDS for faster loading in Shiny
output_path <- file.path("data", "processed", "customer_dna.rds")
saveRDS(customer_dna, output_path)
message("Saved customer DNA to ", output_path)
```

### Step 7: Generate Basic Visualizations

```r
# Plot NES distribution
nes_plot <- ggplot(nes_distribution, aes(x = NESstatus, y = percentage, fill = NESstatus)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = sprintf("%.1f%%", percentage)), vjust = -0.5) +
  labs(title = "Customer Status Distribution",
       x = "NES Status",
       y = "Percentage of Customers") +
  theme_minimal()

# Plot CLV by status
clv_plot <- ggplot(customer_dna, aes(x = NESstatus, y = CLV, fill = NESstatus)) +
  geom_boxplot() +
  labs(title = "Customer Lifetime Value by Status",
       x = "NES Status",
       y = "Customer Lifetime Value (CLV)") +
  theme_minimal() +
  scale_y_continuous(labels = scales::dollar_format())

# Save plots
ggsave(file.path("output", "wiser_nes_distribution.png"), nes_plot, width = 8, height = 6)
ggsave(file.path("output", "wiser_clv_by_status.png"), clv_plot, width = 8, height = 6)

message("Saved visualization plots to output directory")
```

### Step 8: Clean Up

```r
# Disconnect from databases
dbDisconnect_all()

# De-initialize if needed
source(file.path("update_scripts", "global_scripts", "00_principles", "001g_deinitialization_update_mode.R"))

message("Customer DNA analysis workflow complete")
```

## Customization Notes for WISER

For the WISER project, consider these specific customizations:

1. **NES Thresholds**: The WISER customer base has shown different dormancy patterns than other projects. Consider adjusting `NESbreaks` if too many customers fall into S3.

2. **CLV Calculation**: The CLV calculation for WISER may need adjustment based on the specific product lifecycle and purchase patterns:
   ```r
   # Custom CLV calculation for WISER
   customer_dna$CLV_adjusted <- customer_dna$CLV * 1.2  # Example adjustment
   ```

3. **Additional Segments**: WISER may benefit from additional segmentation beyond NES:
   ```r
   # Create high-value segment
   customer_dna <- customer_dna %>%
     mutate(value_segment = case_when(
       CLV > quantile(CLV, 0.9, na.rm = TRUE) ~ "High Value",
       CLV > quantile(CLV, 0.7, na.rm = TRUE) ~ "Medium-High Value",
       CLV > quantile(CLV, 0.5, na.rm = TRUE) ~ "Medium Value",
       TRUE ~ "Standard Value"
     ))
   ```

## Troubleshooting Common Issues

### Missing IPT Values
If you see warnings about missing IPT values, ensure that:
- First purchases have NA for IPT (which is correct)
- Check for data quality issues like duplicate timestamps

### Extreme CLV Values
If CLV calculations seem unrealistic:
- Verify that the delta parameter (discount rate) is appropriate
- Check for outlier transaction values that may be skewing calculations

### Performance Issues
For very large datasets:
- Always use the data.table implementation
- Consider partitioning data by time periods
- Process only the most recent 2-3 years of data

<<<<<<< HEAD
### Data Structure Issues
If you encounter issues with the data structure:
- Run the diagnostic script: `source(file.path("update_scripts", "global_scripts", "98_debug", "test_amazon_sales_import.R"))`
- Check column names in the raw data to ensure they match expected patterns
- Consider using the sample data generator to test the pipeline: `source(file.path("update_scripts", "global_scripts", "15_cleanse", "create_sample_data.R"))`

### Missing Buyer Email
If the buyer_email column is missing:
- The enhanced cleansing function will attempt to find alternative customer identifiers
- Check the available columns in the raw data with `colnames(tbl(raw_data, "amazon_sales_dta") %>% head(1) %>% collect())`
- Update the cleansing function to use an appropriate identifier (order_id, customer_id, etc.)

=======
>>>>>>> origin/main
## Next Steps

After completing the customer DNA implementation, consider these follow-up actions:

1. **Create Marketing Segments**: Use the DNA to define actionable marketing segments
2. **Integrate with Dashboards**: Connect the DNA data to WISER dashboards
3. **Setup Automated Updates**: Schedule regular updates of the DNA analysis
4. **Validate with Business**: Review the DNA segments with business stakeholders