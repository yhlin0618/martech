# Function Reference Guide

**IMPORTANT: This document must be updated whenever functions are modified or added to the codebase.**

This reference provides a comprehensive list of functions available in the project, organized by category. Use this guide to discover existing functionality before creating new functions.

## Database Functions

### Connection Management

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `dbConnect_from_list(dataset, path_list=db_path_list, read_only=FALSE, create_dir=TRUE, verbose=TRUE)` | Connects to a database from the predefined list | `dataset`: Database name<br>`path_list`: List of database paths<br>`read_only`: Whether to open in read-only mode<br>`create_dir`: Whether to create directories if needed<br>`verbose`: Whether to show connection info | 02_db_utils/100g_dbConnect_from_list.R |
| `dbDisconnect_all(verbose=TRUE, remove_vars=FALSE)` | Disconnects all active database connections | `verbose`: Whether to show disconnect info<br>`remove_vars`: Whether to remove connection variables | 02_db_utils/103g_dbDisconnect_all.R |
| `get_default_db_paths(base_dir=NULL)` | Gets the default database paths | `base_dir`: Base directory to use | 02_db_utils/100g_dbConnect_from_list.R |
| `set_db_paths(custom_paths, base_dir=NULL, reset=FALSE)` | Updates the global database path list | `custom_paths`: List of custom paths<br>`base_dir`: Base directory for relative paths<br>`reset`: Whether to reset to defaults first | 02_db_utils/100g_dbConnect_from_list.R |

### Database Operations

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `dbCopyTable(conn, name, value, ..., temporary=FALSE, overwrite=FALSE)` | Copies a data frame to a database table | `conn`: Database connection<br>`name`: Table name<br>`value`: Data frame to copy<br>`temporary`: Whether to create a temporary table<br>`overwrite`: Whether to overwrite existing table | 02_db_utils/102g_dbCopyTable.R |
| `dbOverwrite(conn, table_name, data)` | Overwrites a database table with new data | `conn`: Database connection<br>`table_name`: Table name<br>`data`: Data frame with new data | 02_db_utils/104g_dbOverwrite.R |
| `dbDeletedb(db_path, force=FALSE)` | Deletes a database file | `db_path`: Path to database file<br>`force`: Whether to force deletion | 02_db_utils/105g_dbDeletedb.R |

## UI Module Functions

### Common UI Components

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `sidebarUI(id)` | Creates the sidebar UI component with filters | `id`: Module ID | 10_rshinyapp_modules/common/sidebar.R |
| `createKpiBox(ns, title, value_id, diff_id, perc_id)` | Creates a KPI value box | `ns`: Namespace function<br>`title`: Box title<br>`value_id`: Value output ID<br>`diff_id`: Difference indicator output ID<br>`perc_id`: Percentage change output ID | 10_rshinyapp_modules/macro/macro_overview.R |

### Main Panel UI Components

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `macroOverviewUI(id)` | Creates the macro overview UI panel | `id`: Module ID | 10_rshinyapp_modules/macro/macro_overview.R |
| `microCustomerUI(id)` | Creates the micro customer UI panel | `id`: Module ID | 10_rshinyapp_modules/micro/micro_customer.R |
| `targetProfilingUI(id)` | Creates the target profiling UI panel | `id`: Module ID | 10_rshinyapp_modules/marketing/target_profiling.R |

## Server Module Functions

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `sidebarServer(id, data_source)` | Server logic for the sidebar module | `id`: Module ID<br>`data_source`: Data source reactive list | 10_rshinyapp_modules/common/sidebar.R |
| `macroOverviewServer(id, data_source)` | Server logic for the macro overview | `id`: Module ID<br>`data_source`: Data source reactive list | 10_rshinyapp_modules/macro/macro_overview.R |
| `microCustomerServer(id, data_source)` | Server logic for the micro customer panel | `id`: Module ID<br>`data_source`: Data source reactive list | 10_rshinyapp_modules/micro/micro_customer.R |
| `targetProfilingServer(id, data_source)` | Server logic for the target profiling panel | `id`: Module ID<br>`data_source`: Data source reactive list | 10_rshinyapp_modules/marketing/target_profiling.R |

## Utility Functions

### Data Processing

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `safe_get(name, path="app_data")` | Safely loads an RDS file with error handling | `name`: File name without extension<br>`path`: Directory containing the file | 11_rshinyapp_utils/helpers.R |
| `make_names(x)` | Cleans column names to ensure they're valid R variable names | `x`: Vector of column names | 11_rshinyapp_utils/helpers.R |
| `clean_column_names_remove_english(column_names)` | Removes English text from Chinese column names | `column_names`: Vector of column names | 11_rshinyapp_utils/clean_column_names_remove_english.R |
| `getDynamicOptions(list, dta, invariable, outvariable)` | Gets unique values based on a filter | `list`: Filter values<br>`dta`: Data frame<br>`invariable`: Variable to filter on<br>`outvariable`: Variable to extract values from | 11_rshinyapp_utils/helpers.R |
| `CreateChoices(dta, variable)` | Creates a list of unique values from a column | `dta`: Data frame<br>`variable`: Column to extract values from | 11_rshinyapp_utils/helpers.R |
| `remove_elements(vector, elements)` | Removes specified elements from a vector | `vector`: Input vector<br>`elements`: Elements to remove | 11_rshinyapp_utils/helpers.R |

### SCD Data Functions

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `read_product_line()` | Reads product line parameters from SCD Type 1 | None | 11_rshinyapp_utils/brand_specific_parameters.R |
| `read_sources()` | Reads source parameters from SCD Type 1 | None | 11_rshinyapp_utils/brand_specific_parameters.R |
| `effective_parameters(parameter_table, query_date = Sys.Date())` | Gets parameters effective on a specific date | `parameter_table`: SCD Type 2 table with date columns<br>`query_date`: Date to check for active parameters | 11_rshinyapp_utils/scd_utils.R |
| `load_geographical_boundaries(level = "state")` | Loads geographical boundaries from SCD Type 0 | `level`: Geographic level (state, county) | 11_rshinyapp_utils/geo_utils.R |
| `connect_global_scd(read_only = TRUE)` | Connects to the global SCD Type 1 database | `read_only`: Whether to open in read-only mode | 11_rshinyapp_utils/scd_utils.R |

### Time Formatting

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `formattime(time_scale, case)` | Formats a date based on time scale | `time_scale`: Date to format<br>`case`: Time scale (year, quarter, month) | 11_rshinyapp_utils/formattime.R |
| `Recode_time_TraceBack(profile)` | Converts a time scale to historical scale | `profile`: Time scale to convert | 11_rshinyapp_utils/Recode_time_TraceBack.R |

### Sales Data Processing

| Function | Description | Parameters | Source File |
|----------|-------------|------------|------------|
| `process_sales_data(SalesPattern, time_scale_profile)` | Processes and summarizes sales data | `SalesPattern`: Sales data frame<br>`time_scale_profile`: Time scale to use | 11_rshinyapp_utils/process_sales_data.R |

## Example Usage

### Database Connection Example

```r
# Source required functions
source("update_scripts/global_scripts/02_db_utils/100g_dbConnect_from_list.R")
source("update_scripts/global_scripts/02_db_utils/103g_dbDisconnect_all.R")

# Connect to app database
app_data <- dbConnect_from_list("app_data", read_only = TRUE)

# Use the connection
customer_data <- dbGetQuery(app_data, "SELECT * FROM customer_table")

# Close all connections when done
dbDisconnect_all()
```

### SCD Data Example

```r
# Reading SCD Type 0 data (constant reference data)
us_states <- jsonlite::read_json("global_scripts/30_global_data/scd_type0/gz_2010_us_040_00_500k.json")
us_counties <- jsonlite::read_json("global_scripts/30_global_data/scd_type0/gz_2010_us_050_00_500k.json")

# Reading SCD Type 1 parameters
product_line <- readxl::read_excel("app_data/scd_type1/product_line.xlsx")
sources <- readxl::read_excel("app_data/scd_type1/source.xlsx")

# Converting to dictionaries for UI elements
product_line_dictionary <- product_line %>%
  select(product_line_id, product_line_name) %>%
  deframe()

# Accessing global SCD Type 1 database
global_scd <- dbConnect(duckdb::duckdb(), 
                      "global_scripts/30_global_data/global_scd_type1.duckdb", 
                      read_only = TRUE)
standard_regions <- dbGetQuery(global_scd, "SELECT * FROM standard_regions")
dbDisconnect(global_scd)

# Using the effective_parameters function with SCD Type 2 data
if (file.exists("app_data/scd_type2/pricing_parameters.rds")) {
  pricing_parameters <- readRDS("app_data/scd_type2/pricing_parameters.rds")
  
  # Get parameters effective on a specific date
  current_parameters <- effective_parameters(
    parameter_table = pricing_parameters,
    query_date = as.Date("2024-03-30")
  )
}
```

### UI Module Example

```r
# Define UI using module functions
ui <- page_navbar(
  title = "AI行銷科技平台",
  sidebar = sidebarUI("sidebar"),
  
  # Add main panels
  nav_panel(
    title = "儀表板",
    macroOverviewUI("overview"),
    microCustomerUI("customer"),
    targetProfilingUI("segmentation")
  )
)
```

### Server Module Example

```r
# Define server logic
server <- function(input, output, session) {
  # Initialize data source
  data_sources <- data_source_function()
  
  # Initialize modules
  sidebarServer("sidebar", data_sources)
  macroOverviewServer("overview", data_sources)
  microCustomerServer("customer", data_sources)
  targetProfilingServer("segmentation", data_sources)
}
```

## Best Practices

1. **Always check this reference** before creating new functions to avoid duplication
2. **Update this document** whenever you add or modify functions
3. **Follow naming conventions** for new functions:
   - Use camelCase or snake_case consistently
   - Include descriptive prefix for function category
4. **Include proper documentation** in your function code:
   - Function purpose
   - Parameter descriptions
   - Return value description
   - Usage examples