---
id: "R10_archived"
title: "Database Table Naming"
type: "archived_rule"
date_created: "2024-12-01"
date_archived: "2025-04-04"
author: "Data Team"
replaced_by:
  - "R19": "Object Naming Convention"
  - "R27": "Data Frame Creation Strategy"
reason_for_archiving: "Functionality merged into R19 (naming conventions) and R27 (implementation strategy)"
archiving_record: "2025_04_04_r10_database_table_naming_archive.md"
---

# Database Table Naming Convention (Archived)

> **IMPORTANT: This rule has been archived.** The functionality has been split between R19 (Object Naming Convention) and R27 (Data Frame Creation Strategy). Please refer to those documents for current guidelines.

## Original Content (For Historical Reference)

This rule establishes a consistent naming convention for database tables in the precision marketing system, ensuring clear identification of table purpose, type, and relationships.

## Core Pattern

All database tables must follow this pattern:

```
[entity]_[qualifier]_[type]
```

Where:
- `entity`: The primary entity represented in the table (e.g., customer, product, order)
- `qualifier`: Additional specification or filtering (e.g., active, verified, monthly)
- `type`: Table type identifier (e.g., dim for dimension, fct for fact, dta for data)

### Examples

- `customer_active_dta`: Data table of active customers
- `product_bestseller_fct`: Fact table of bestseller products
- `order_monthly_agg`: Aggregation table of monthly orders
- `store_location_dim`: Dimension table of store locations

## Table Type Codes

| Code | Type | Description |
|------|------|-------------|
| dta | Data | Raw or lightly processed data |
| dim | Dimension | Descriptive attributes for entities |
| fct | Fact | Measures and metrics |
| agg | Aggregation | Pre-aggregated data |
| lkp | Lookup | Reference data |
| tmp | Temporary | Temporary table |
| stg | Staging | Intermediate processing |
| arc | Archive | Historical data |
| jnc | Junction | Many-to-many relationship |

## Implementation Strategy

Tables should be created using a consistent strategy pattern:

```r
# Strategy Registry
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

### Implementations

```r
# Standard table creator
standard_table_creator <- function(table_name, data) {
  con <- dbConnect(duckdb::duckdb(), "app_data.duckdb")
  on.exit(dbDisconnect(con), add = TRUE)
  
  # Drop table if it exists
  if (dbExistsTable(con, table_name)) {
    dbExecute(con, sprintf("DROP TABLE %s", table_name))
  }
  
  # Create new table
  dbWriteTable(con, table_name, data)
  
  return(TRUE)
}

# Register standard creator
register_table_creator("standard", standard_table_creator)
```

## Usage Examples

```r
# Create a customer dimension table
customer_data <- read_csv("path/to/customer_data.csv")
create_or_replace_table("customer_active_dim", customer_data)

# Create a product fact table with a specialized creator
register_table_creator("indexed", indexed_table_creator)
create_or_replace_table("product_sales_fct", product_sales_data, "indexed")

# Create a temporary calculation table
create_or_replace_table("calculation_daily_tmp", daily_calcs, "temporary")
```

## Querying Conventions

When querying tables, use the same naming convention in SQL queries:

```sql
SELECT 
  c.customer_id,
  c.customer_name,
  p.product_name,
  o.order_total
FROM 
  customer_active_dim c
JOIN 
  order_recent_fct o ON c.customer_id = o.customer_id
JOIN 
  product_catalog_dim p ON o.product_id = p.product_id
WHERE 
  o.order_date >= '2023-01-01'
```

## Transition Strategy

When renaming existing tables to follow this convention:

1. Create a new table with the correct name
2. Copy data from the old table
3. Verify data integrity
4. Create a view with the old name pointing to the new table temporarily
5. Update all references to use the new name
6. Remove the compatibility view

```r
# Create transition view
dbExecute(con, "CREATE VIEW old_customer_table AS SELECT * FROM customer_active_dim")
```

## Benefits

This naming convention:
1. Clearly identifies the purpose of each table
2. Makes table relationships more intuitive
3. Facilitates consistency across the data model
4. Improves query readability and maintenance

## Relationship to Other Principles

This rule is related to:
- File Naming Convention (R01)
- Platform Neutral Code (R03)
- Object Naming Convention (R23)
- Object-File Name Translation (R27)

## Legacy Code and Transition

As this rule has been archived, please use the appropriate rules (R19 and R27) for current implementation. This document is preserved for historical reference only.