# Module 1.1 Extension: Customer DNA Visualization with Shiny

This guide explains how the Customer DNA analysis is integrated with a Shiny app for interactive visualization as an extension of Module 1.1.

## Integration with Customer DNA Analysis

The Customer DNA analysis workflow now includes a visualization layer using Shiny:

1. **Data Processing Pipeline**:
   - Raw data collection and cleaning
   - Customer DNA analysis (RFM, NES, segments)
   - Results stored in database and RDS formats
   - Shiny app for visualization and exploration

## Key Components

### 1. Data Handoff

The customer DNA analysis outputs data in formats readily consumable by the Shiny app:

```r
# In the analysis script
# Save to database for persistence
dbWriteTable(processed_data, "customer_dna", customer_dna, overwrite = TRUE)

# Save to RDS for faster Shiny app loading
output_path <- file.path("data", "processed", "wiser_customer_dna.rds")
saveRDS(customer_dna, output_path)
```

### 2. Data Loading in Shiny

The Shiny app implements a robust data loading approach:

```r
# In the Shiny app
load_customer_dna <- function() {
  # Try RDS file first (faster)
  rds_path <- file.path("data", "processed", "wiser_customer_dna.rds")
  
  if (file.exists(rds_path)) {
    return(readRDS(rds_path))
  } else {
    # Try database as fallback
    tryCatch({
      conn <- dbConnect(duckdb(), dbdir = "Data.duckdb")
      if (dbExistsTable(conn, "processed_data.customer_dna")) {
        data <- dbReadTable(conn, "processed_data.customer_dna")
        dbDisconnect(conn)
        return(data)
      } else {
        # Run the analysis if data doesn't exist
        source(file.path("update_scripts", "basic_customer_dna.R"))
        return(readRDS(rds_path))
      }
    }, error = function(e) {
      # Return sample data if all else fails
      # ...sample data generation code...
    })
  }
}
```

## Visualization Features

The Shiny app provides several views of the customer DNA data:

### 1. Overview Dashboard

Displays aggregate metrics and distributions:
- Customer status breakdown
- Value segment distribution
- Loyalty tier composition
- Key performance indicators

### 2. Customer Details

Provides individual customer profiles:
- Complete RFM metrics
- Segmentation details
- Historical purchase pattern
- Customer lifetime value

### 3. Segmentation Analysis

Enables deeper segment analysis:
- Segment relationship visualization
- Performance comparison across segments
- Segment size and value analysis
- Segment targeting insights

## Usage in WISER Workflow

The Shiny app can be used in several ways within the WISER workflow:

### 1. Analysis Exploration

Data scientists and analysts can explore the DNA results to:
- Validate segmentation logic
- Discover patterns and relationships
- Identify outliers or special cases
- Test hypotheses about customer behavior

### 2. Business Presentations

Marketing and business teams can use the app to:
- Present customer insights to stakeholders
- Justify marketing strategies with data
- Track customer segment evolution
- Demonstrate the value of analytical approaches

### 3. Decision Support

Decision-makers can leverage the app for:
- Identifying high-value customer segments
- Prioritizing marketing initiatives
- Setting realistic customer acquisition/retention goals
- Measuring the success of customer strategies

## Integration with Existing Systems

The app can be integrated with other WISER systems:

1. **Marketing Automation**:
   - Export segments for targeted campaigns
   - Track campaign impact on segments
   - Refine targeting based on segment performance

2. **CRM Integration**:
   - Import customer interaction data
   - Enhance DNA with engagement metrics
   - Provide segment context for customer service

3. **Business Intelligence**:
   - Feed segment KPIs to executive dashboards
   - Include DNA metrics in business reporting
   - Align customer metrics with financial outcomes

## Running the App

The app can be launched in several ways:

1. **Development Mode**:
   From R or RStudio:
   ```r
   shiny::runApp()
   ```

2. **Command Line**:
   ```bash
   R -e "shiny::runApp()"
   ```

3. **Scheduled Updates**:
   ```r
   # Run analysis and launch app
   source("update_scripts/basic_customer_dna.R")
   shiny::runApp()
   ```

## Extending the Visualization

The visualization layer can be extended in several ways:

1. **Additional Metrics**:
   - Customer acquisition cost analysis
   - Lifetime value prediction
   - Churn probability visualization

2. **Advanced Visualizations**:
   - Customer journey mapping
   - Segment migration flows
   - Predictive modeling results

3. **Interactive Features**:
   - What-if scenario modeling
   - Custom segment creation
   - Targeted campaign simulation

## Conclusion

The Shiny app visualization extends the value of the Customer DNA analysis by making the insights accessible and actionable across the organization. By providing both high-level summaries and detailed drill-downs, the app enables data-driven decision-making based on customer segmentation insights.