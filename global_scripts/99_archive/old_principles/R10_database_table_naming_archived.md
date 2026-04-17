---
id: "R10"
title: "Database Table Naming and Creation Rule [ARCHIVED]"
type: "archived_rule"
date_created: "2025-04-02"
date_archived: "2025-04-04"
author: "Claude"
archived_reason: "Functionality split between R23 (Object Naming Convention) and R31 (Data Frame Creation Strategy)"
implements:
  - "P02": "Data Integrity"
  - "P11": "Similar Functionality Management Principle"
derives_from:
  - "MP06": "Data Source Hierarchy"
  - "MP18": "Don't Repeat Yourself Principle"
related_to:
  - "MP16": "Modularity Principle"
  - "R04": "App YAML Configuration"
  - "R23": "Object Naming Convention"
  - "R31": "Data Frame Creation Strategy"
---

# Database Table Naming and Creation Rule

This rule establishes that data tables connecting to app_data.duckdb must maintain consistent naming between the data source reference and the physical table name, and specifies the Strategy Pattern for implementing table creation functions.

## Core Requirement

Data tables referenced in application code must have the same name as their corresponding physical tables in the app_data.duckdb database, ensuring direct traceability and eliminating the need for name mapping.

## Naming Consistency

### 1. Naming Requirements

#### 1.1 Direct Name Correspondence
- The table name referenced in R code must exactly match the table name in DuckDB
- No translation or mapping between application names and database names is permitted
- All references to a table must use the canonical name defined in the database schema

#### 1.2 Naming Convention
- Table names must use snake_case (lowercase with underscores)
- Table names must be descriptive and reflect their content
- Entity tables should use singular nouns (e.g., `customer`, not `customers`)
- Junction tables should name both entities with singular nouns (e.g., `customer_product`)
- Derived view tables should include a suffix describing their purpose (e.g., `customer_segmented`)

#### 1.3 Name Structure
- Tables should follow the pattern: `[entity]_[qualifier]_[type]`
  - `entity`: The primary subject of the table (e.g., `customer`, `product`, `order`)
  - `qualifier`: Optional description of the specific subset (e.g., `active`, `historical`)
  - `type`: Optional indicator of table type (e.g., `dta` for data tables, `dim` for dimensions)
- Example: `customer_active_dta`, `product_catalog_dim`

### 2. Implementation in Code

#### 2.1 Table References
When referencing tables in code, always use the exact physical table name:

```r
# Correct: Using the exact table name
customer_data <- read_table("customer_active_dta")

# Incorrect: Using a different name or alias
customer_data <- read_table("active_customers") # Wrong: name mismatch
```

#### 2.2 YAML Configuration
In YAML configuration files, data source names must match physical table names:

```yaml
# Correct: Configuration using exact table names
components:
  customer_profile:
    primary: customer_active_dta
    history: customer_history_dta

# Incorrect: Using different names
components:
  customer_profile:
    primary: active_customers  # Wrong: name mismatch
    history: customer_history  # Wrong: missing suffix
```

#### 2.3 Query Construction
When constructing SQL queries, table names must match physical tables:

```r
# Correct: Using exact table names in queries
query <- "SELECT * FROM customer_active_dta WHERE signup_date > '2024-01-01'"

# Incorrect: Using different names
query <- "SELECT * FROM customers WHERE signup_date > '2024-01-01'" # Wrong: name mismatch
```

## Table Creation Strategy Pattern

### 1. Pattern Selection Rationale

The Strategy Pattern was selected as the most appropriate design pattern for table creation after careful evaluation:

#### 1.1 Pattern Comparison for Table Creation

| Pattern | Suitability | Rationale |
|---------|------------|-----------|
| **Strategy Pattern** | **Excellent** | Cleanly separates table type logic, supports runtime selection, easily extensible for new table types |
| Function Consolidation | Poor | Would result in a large function with complex conditionals, difficult to maintain as table types grow |
| Higher-Order Functions | Fair | Less suitable since table creation isn't a multi-step pipeline process |
| Abstraction Layers | Excessive | Unnecessary complexity for this specific use case |

#### 1.2 Why Strategy Pattern Excels Here

The Strategy Pattern is particularly well-suited for table creation because:

1. **Varying Table Types**: Different tables require specialized creation logic (standard, indexed, partitioned, time-series)
2. **Runtime Selection**: The exact strategy isn't always known until runtime
3. **Separation of Concerns**: Cleanly separates table creation mechanics from business logic
4. **Extensibility**: New table types can be added without modifying existing code
5. **Configuration-Driven**: Table creation strategies can be specified in configuration rather than code

### 2. Strategy Pattern Implementation

Table creation functions should be implemented using the Strategy Pattern to ensure consistency while supporting different table types:

#### 1.1 Strategy Registry

```r
# Central registry for table creation strategies
table_creators <- list()

# Registration function
register_table_creator <- function(table_type, creator_fn) {
  table_creators[[table_type]] <- creator_fn
}

# Dispatch function
create_or_replace_table <- function(table_name, data, table_type = "standard") {
  # Get the correct strategy
  creator <- table_creators[[table_type]]
  
  if (is.null(creator)) {
    stop("No table creator registered for type: ", table_type)
  }
  
  # Execute the strategy
  return(creator(table_name, data))
}
```

#### 1.2 Strategy Implementations

```r
# Register standard table creator
register_table_creator("standard", function(table_name, data) {
  # Connect to the database
  con <- dbConnect(duckdb::duckdb(), "app_data.duckdb")
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Create or replace the table
  if (dbExistsTable(con, table_name)) {
    dbRemoveTable(con, table_name)
  }
  
  # Write the table
  dbWriteTable(con, table_name, data)
  
  # Return confirmation
  return(list(success = TRUE, table_name = table_name, rows = nrow(data)))
})

# Register partitioned table creator
register_table_creator("partitioned", function(table_name, data) {
  # Connect to the database
  con <- dbConnect(duckdb::duckdb(), "app_data.duckdb")
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Create or replace with partitioning
  if (dbExistsTable(con, table_name)) {
    dbRemoveTable(con, table_name)
  }
  
  # Create partitioned table
  dbExecute(con, sprintf(
    "CREATE TABLE %s AS SELECT * FROM data PARTITION BY date_month", 
    table_name
  ))
  
  # Return confirmation
  return(list(success = TRUE, table_name = table_name, rows = nrow(data)))
})

# Register indexed table creator
register_table_creator("indexed", function(table_name, data, index_columns) {
  # Connect to the database
  con <- dbConnect(duckdb::duckdb(), "app_data.duckdb")
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Create or replace the table
  if (dbExistsTable(con, table_name)) {
    dbRemoveTable(con, table_name)
  }
  
  # Write the table
  dbWriteTable(con, table_name, data)
  
  # Create indexes
  for (col in index_columns) {
    index_name <- paste0(table_name, "_", col, "_idx")
    dbExecute(con, sprintf(
      "CREATE INDEX %s ON %s(%s)",
      index_name, table_name, col
    ))
  }
  
  # Return confirmation
  return(list(success = TRUE, table_name = table_name, rows = nrow(data), indexes = index_columns))
})
```

#### 1.3 Using the Strategy Pattern

```r
# Create a standard table
create_or_replace_table("customer_active_dta", customer_data)

# Create a partitioned table
create_or_replace_table("sales_history_dta", sales_data, "partitioned")

# Create an indexed table
create_or_replace_table("product_catalog_dim", product_data, "indexed", 
                        index_columns = c("product_id", "category"))
```

### 2. Table Creation Functions

Table creation functions should:

#### 2.1 Function Naming Convention

Table creation functions should follow a consistent naming pattern:

```r
# Pattern: create_or_replace_[entity]_[qualifier]_[type]
create_or_replace_customer_active_dta <- function(data) {
  return(create_or_replace_table("customer_active_dta", data))
}

create_or_replace_product_catalog_dim <- function(data) {
  return(create_or_replace_table("product_catalog_dim", data, "indexed", 
                               index_columns = c("product_id", "category")))
}
```

#### 2.2 Function Documentation

Each table creation function should include consistent documentation:

```r
#' Create or Replace Customer Active Data Table
#'
#' @param data A data frame containing customer data to be stored
#' @return A list with success status, table name, and row count
#' @details Creates or replaces the customer_active_dta table in app_data.duckdb
#'   This table contains current active customer records.
#'   Table structure follows standard customer schema.
create_or_replace_customer_active_dta <- function(data) {
  return(create_or_replace_table("customer_active_dta", data))
}
```

## Table Reference and Retrieval

### 1. Table Retrieval Functions

Consistent functions should be used to retrieve data from tables:

```r
# Standard function for retrieving a table
get_table <- function(table_name) {
  con <- dbConnect(duckdb::duckdb(), "app_data.duckdb")
  on.exit(dbDisconnect(con), add = TRUE)
  
  if (!dbExistsTable(con, table_name)) {
    stop("Table does not exist: ", table_name)
  }
  
  data <- dbReadTable(con, table_name)
  return(data)
}
```

### 2. Table-Specific Retrieval Functions

Use specific functions for commonly accessed tables:

```r
# Pattern: get_[entity]_[qualifier]_[type]
get_customer_active_dta <- function() {
  return(get_table("customer_active_dta"))
}

get_product_catalog_dim <- function() {
  return(get_table("product_catalog_dim"))
}
```

## Implementation Examples

### Example 1: Standard Table Creation

```r
# Create customer active data table
customer_data <- read_csv("path/to/customer_data.csv")
create_or_replace_table("customer_active_dta", customer_data)

# Reference in application code
customers <- get_table("customer_active_dta")

# Reference in YAML configuration
# components:
#   customer_profile:
#     primary: customer_active_dta
```

### Example 2: Creating a Table with Custom Strategy

```r
# Create sales history with custom partitioning strategy
sales_data <- read_parquet("path/to/sales_history.parquet")
create_or_replace_table("sales_history_dta", sales_data, "partitioned")

# Custom retrieval with filtering
get_sales_history <- function(date_from, date_to) {
  con <- dbConnect(duckdb::duckdb(), "app_data.duckdb")
  on.exit(dbDisconnect(con), add = TRUE)
  
  query <- sprintf(
    "SELECT * FROM sales_history_dta WHERE sale_date >= '%s' AND sale_date <= '%s'",
    date_from, date_to
  )
  
  return(dbGetQuery(con, query))
}
```

### Example 3: Complete Table Management

```r
# Register custom strategy for time-series tables
register_table_creator("time_series", function(table_name, data) {
  # Connect to the database
  con <- dbConnect(duckdb::duckdb(), "app_data.duckdb")
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Ensure date column is properly formatted
  data$date <- as.Date(data$date)
  
  # Create or replace with time-series optimizations
  if (dbExistsTable(con, table_name)) {
    dbRemoveTable(con, table_name)
  }
  
  # Write table
  dbWriteTable(con, table_name, data)
  
  # Add time-series specific indexes
  dbExecute(con, sprintf(
    "CREATE INDEX %s_date_idx ON %s(date)",
    table_name, table_name
  ))
  
  # Return confirmation
  return(list(success = TRUE, table_name = table_name, rows = nrow(data), type = "time_series"))
})

# Create specific function using the strategy
create_or_replace_marketing_performance_time_series <- function(data) {
  # Validate required columns
  required_cols <- c("date", "channel", "impressions", "clicks", "conversions")
  missing_cols <- setdiff(required_cols, names(data))
  
  if (length(missing_cols) > 0) {
    stop("Missing required columns: ", paste(missing_cols, collapse = ", "))
  }
  
  # Create using time-series strategy
  return(create_or_replace_table("marketing_performance_time_series", data, "time_series"))
}
```

## Benefits of This Rule

Implementing this rule provides several benefits:

1. **Direct Traceability**: Clear connection between code and database
2. **Reduced Cognitive Load**: No need to remember mapping between names
3. **Self-Documenting Code**: Table references directly indicate their source
4. **Improved Maintainability**: Changes to table structure don't require name mapping updates
5. **Consistent Implementation**: Strategy Pattern ensures tables are created consistently
6. **Extensibility**: New table types can be added without modifying existing code
7. **Separation of Concerns**: Table creation logic is separated from table usage

## Relationship to Other Principles

This rule:

1. **Implements P02 (Data Integrity)**: Ensures consistent and reliable data storage
2. **Derives from MP06 (Data Source Hierarchy)**: Aligns with the data source hierarchy principles
3. **Follows MP18 (DRY Principle)**: Eliminates the need for name mapping tables
4. **Implements P11 (Similar Functionality Management)**: Uses Strategy Pattern for table creation
5. **Relates to R04 (App YAML Configuration)**: Ensures YAML configurations use consistent table names

## Conclusion

The Database Table Naming and Creation Rule ensures that all references to data tables in app_data.duckdb use consistent names, creating a direct mapping between application code and physical database structures. By implementing table creation using the Strategy Pattern, we ensure both consistency and flexibility in how different types of tables are created and managed. This rule eliminates the need for name translation layers, reducing complexity and improving maintainability.