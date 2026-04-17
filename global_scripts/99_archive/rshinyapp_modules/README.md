# Precision Marketing Shiny Application Modules

This directory contains the modular components for the Precision Marketing KitchenMAMA Shiny application.

## Directory Structure

- **common/** - Shared UI components
  - `sidebar.R` - Application sidebar module

- **data/** - Data connection and access
  - `data_source.R` - Centralized data source module

- **macro/** - Macro-level analysis
  - `macro_overview.R` - High-level KPI overview module

- **micro/** - Micro-level analysis
  - `micro_customer.R` - Customer-level analysis module

- **marketing/** - Marketing analysis modules
  - (Future modules will be added here)

- **positioning/** - Positioning analysis modules
  - (Future modules will be added here)

## Usage

These modules are designed to be used within a Shiny application following the modular pattern. Each module file contains both UI and server components:

```r
# In app.R
source("global_scripts/rshinyapp_modules/data/data_source.R")
source("global_scripts/rshinyapp_modules/macro/macro_overview.R")

# UI
ui <- page_fillable(
  titlePanel("Precision Marketing Dashboard"),
  
  # Use the module's UI function
  macroOverviewUI("overview")
)

# Server
server <- function(input, output, session) {
  # Initialize the data source
  data <- dataSourceServer("data")
  
  # Use the module's server function with the data source
  macroOverviewServer("overview", data)
}

shinyApp(ui, server)
```

## Modules Overview

### Data Source Module

The data source module centralizes all database connections and provides reactive datasets to other modules. It handles:
- Database connections
- Data filtering
- Common data transformations
- Data aggregation

### Macro Overview Module

Provides high-level KPIs and metrics across the entire customer base, including:
- Sales metrics
- Customer metrics
- Retention and acquisition rates
- Customer segmentation metrics

### Micro Customer Module

Provides detailed analysis of individual customer behavior and purchasing patterns.

### Common Modules

Contains shared UI components like navigation sidebars and filter panels.

## Dependencies

These modules depend on the utility functions in the `rshinyapp_utils` directory.