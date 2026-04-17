# WISER Customer DNA Shiny App Implementation Guide

This document explains the development and implementation of the Shiny app created to visualize and interact with the Customer DNA analysis results for the WISER project.

## Overview

The Customer DNA Shiny app provides a user-friendly interface to explore customer segmentation data, analyze individual customer profiles, and visualize segment distributions. The app serves as a dashboard to make analytical insights accessible to business stakeholders.

The implementation is designed to match the KitchenMAMA app structure and styling, using brand-specific parameters from local scripts to ensure consistency with other WISER applications.

## App Structure

The app follows a modular architecture with three main components that match the KitchenMAMA app structure:

### 1. Macro Overview (總覽)

The Macro Overview panel provides high-level metrics and distributions:

- **Key Metrics**: Total customers, active customers, sleeping customers, new customers with percentage metrics
- **Status Distribution**: Visualization of NES status (新客戶, 活躍客戶, 初期靜止客戶, etc.)
- **Value and Loyalty**: Distribution of value segments and loyalty tiers in Chinese
- **Comparative Charts**: Relationship between loyalty tiers and value segments

### 2. Micro Customer View (微觀)

The Micro Customer view enables exploration of individual customer profiles:

- **Customer Selection**: Dropdown to choose specific customers with comprehensive filtering
- **RFM Metrics**: Display of Recency, Frequency, and Monetary metrics with Chinese labels
- **Customer Value**: CLV (Customer Lifetime Value) and historical purchasing data
- **Timeline Data**: First purchase date, tenure, and last purchase information
- **Segmentation**: NES status, loyalty tier, and value segment in Chinese

### 3. Target Profiling (目標群組)

The Target Profiling panel provides advanced segmentation analysis:

- **Scatter Plots**: Frequency vs. Recency and Monetary vs. Frequency with tooltips
- **Segment Heatmap**: Distribution of customers across NES status and loyalty tiers
- **Segment Metrics**: Average CLV, frequency, and recency by different segment dimensions
- **Interactive Visualizations**: All charts support interactivity for deeper exploration

## Technical Implementation

### Data Flow

1. **Data Loading**:
   - Primarily loads from RDS file in `data/processed/wiser_customer_dna.rds`
   - Falls back to DuckDB database if RDS is unavailable
   - Can generate sample data if no data sources are accessible

2. **Reactivity Chain**:
   - Main data is stored in a reactive value (`customer_data`)
   - Filter changes trigger recalculation of derived metrics
   - Dashboard components observe filtered data and update accordingly

3. **Component Design**:
   - Each panel is implemented as a Shiny component with separate UI and server files
   - Components follow the naming convention `ui_[section]_[component].R` and `server_[section]_[component].R`
   - Located in the `10_rshinyapp_components` directory
   - Examples include `ui_macro_overview.R`, `ui_micro_customer_profile.R`, and `ui_target_segmentation.R`
   - Components receive data from the parent app and handle their own reactivity
   - Consistent styling and interaction patterns across components

### Visualization Strategy

1. **Overall Distribution Plots**:
   - Bar charts for NES status, value segments, and loyalty tiers
   - Interactive elements show specific counts and percentages
   - Consistent color schemes identify segment types

2. **Customer Profile Cards**:
   - Value boxes display key metrics for selected customers
   - Clean layout organizes metrics in logical groups
   - Contextual indicators show whether values are good or concerning

3. **Analytical Plots**:
   - Scatter plots position customers in RFM space
   - Heatmaps show segment concentrations
   - Bar charts compare average metrics across segments

## Adaptation for WISER

The app has been customized specifically for the WISER project with:

1. **WISER-Specific Segmentation with Chinese Labels**:
   - NES status categories with Chinese labels (新客戶, 活躍客戶, 初期靜止客戶, 中期靜止客戶, 長期靜止客戶)
   - Value segments with Chinese labels (高價值客戶, 中高價值客戶, 中價值客戶, 一般價值客戶)
   - Loyalty tiers with Chinese labels (白金會員, 黃金會員, 白銀會員, 青銅會員)

2. **WISER-Specific Filters**:
   - Product category options from WISER product_line.xlsx in app_data/scd_type1
   - Distribution channels from source.xlsx in app_data/scd_type1
   - Geographic filters using state_dictionary from global parameters
   - Time period selection (年, 季度, 月) for historical analysis

3. **WISER Branding and Terminology**:
   - Dynamic app title using brand_name parameter from local_scripts/brand_specific_parameters.R
   - Chinese labels for all metrics and visualizations
   - Interface language set to match language parameter ("chinese") from brand_specific_parameters.R

## Installation and Usage

### Requirements

- R (version 4.0+)
- Required packages: shiny, bslib, dplyr, ggplot2, plotly, DBI, duckdb

### Setup

1. Clone the repository
2. Ensure the customer DNA data is available (run analysis script if needed)
3. Install required packages:
   ```r
   install.packages(c("shiny", "bslib", "dplyr", "ggplot2", 
                     "plotly", "DBI", "duckdb", "lubridate"))
   ```

### Running the App

From the project directory:
```r
shiny::runApp()
```

Or using the R command line:
```
R -e "shiny::runApp()"
```

### Deployment Options

For team access, the app can be deployed to:
- Shiny Server
- shinyapps.io
- RStudio Connect
- A containerized solution (Docker)

## Extending the App

The app can be extended in several ways:

1. **Additional Visualizations**:
   - Customer journey mapping
   - Predictive churn visualization
   - Segment migration tracking

2. **Enhanced Interactivity**:
   - Scenario planning tools
   - Marketing campaign targeting
   - Customer segment simulation

3. **Integration Options**:
   - Export to marketing platforms
   - Integration with CRM systems
   - Automated insight generation

## Code Structure

The app.R file contains the complete application with several main sections:

1. **Setup and Global Parameters**:
   - Package loading
   - Configuration variables
   - Helper functions

2. **UI Components**:
   - Main page structure with sidebar
   - Module UI functions for each panel
   - Layout and styling definitions

3. **Server Logic**:
   - Data loading and processing
   - Module server functions
   - Reactivity and event handling

4. **Module Implementation**:
   - Overview module
   - Customer details module
   - Segmentation module

## App Construction Principles

### Core Implementation Principle

**IMPORTANT:** The app follows a critical construction principle:

- **Content Treatment Rule:** 
  - If content is treated as a constant (not a variable), preserve it exactly as in the reference KitchenMAMA app
  - If content is treated as a variable, it may be modified to match WISER-specific requirements

This principle ensures that the app's structure, layout, and behavior remain identical to the KitchenMAMA app, while only WISER-specific data elements (like product categories, distribution channels, and brand-specific terminology) are adapted.

Examples:
- **Preserve (constants)**: Panel structure, UI layout, component types, visualization techniques
- **Adapt (variables)**: Product categories, distribution channels, specific text labels, data fields

### Other Best Practices

1. **Code Organization**:
   - Modular design for maintainability
   - Clear separation of UI and server logic
   - Consistent naming conventions

2. **Performance Optimization**:
   - Reactive values to minimize recalculation
   - Data filtering at the appropriate level
   - Efficient plotting with plotly

3. **User Experience**:
   - Consistent layout and interaction patterns matching KitchenMAMA
   - Clear labeling and instructions
   - Responsive design for different screen sizes

4. **Error Handling**:
   - Graceful fallbacks for missing data
   - Informative error messages
   - Data validation before visualization

## Conclusion

The WISER Customer DNA Shiny app transforms complex analytical results into an accessible, interactive dashboard that facilitates data-driven decision making. By providing both high-level overviews and detailed customer insights, the app enables the WISER team to leverage their customer DNA analysis for targeted marketing strategies and enhanced customer engagement.