# NSQL Language Specification v3

## Overview

NSQL (Natural SQL Language) is a specialized documentation language for describing data operations, transformations, and flows in reactive applications. It combines SQL's declarative clarity with additional syntax for documenting UI components, reactive dependencies, visualizations, graph relationships, and testing requirements.

## Core Principles

1. **Clarity**: Expressions must clearly indicate source, transformation, and destination
2. **Precision**: Syntax must eliminate ambiguity in data operation descriptions
3. **Alignment**: Documentation must align with implementation patterns
4. **Completeness**: All aspects of data flow must be documentable
5. **Visualization**: Support for generating flow diagrams and visualizations
6. **Hierarchical Organization**: Provide clear structural hierarchy for documentation
7. **Graph Representation**: Support formal representation of component relationships
8. **Integration**: Seamlessly blend with existing documentation systems
9. **Radical Translation**: Enable transformation between representation systems while preserving semantics (see [MP0065](MP065_radical_translation_in_nsql.md))

## NSQL Integration Model

NSQL now integrates five major component systems:

1. **Core NSQL**: Data operation and transformation syntax
2. **Graph Theory Extension**: Component relationship and flow visualization
3. **LaTeX/Markdown Terminology**: Document structure and formatting
4. **Roxygen2-Inspired Annotations**: Function and component documentation
5. **Radical Translation System**: Cross-language and cross-paradigm transformation

For complete documentation on all integrated components, see:
- Core specification in `16_NSQL_Language/README.md`
- Graph theory extensions in `16_NSQL_Language/extensions/graph_representation/`
- Documentation syntax in `16_NSQL_Language/extensions/documentation_syntax/`
- Radical translation in `00_principles/MP065_radical_translation_in_nsql.md`
- Integrated guide in `16_NSQL_Language/integrated_nsql_guide.md`
- Complete reference in `00_principles/MP027_integrated_natural_sql_language.md`

## Basic Syntax

### Data Operation Expression

The fundamental unit of NSQL is the Data Operation Expression:

```
OPERATION(SOURCE → TRANSFORM → DESTINATION)
```

Example:
```sql
FILTER(transactions → WHERE date > '2023-01-01' → recent_transactions)
```

### Component Documentation

UI components are documented with their data sources and operations:

```sql
-- COMPONENT: component_name
-- Type: component_type
-- Data Source: data_source_name
-- Operation: operation_description
-- SQL Query:
SELECT ...
```

Example:
```sql
-- COMPONENT: product_sales_chart
-- Type: barChart
-- Data Source: sales_data
-- Operation: Display top 10 products by revenue
-- SQL Query:
SELECT product_name, SUM(amount) AS revenue
FROM sales_data
GROUP BY product_name
ORDER BY revenue DESC
LIMIT 10
```

### Data Flow Documentation

Document complete reactive data flows:

```sql
DATA_FLOW(name: "flow_name") {
  SOURCE: source_1, source_2
  BRANCH: "branch_name_1" {
    TRANSFORM(source → operation → destination)
    DISPLAY(destination → component)
  }
  BRANCH: "branch_name_2" {
    TRANSFORM(source → operation → destination)
    DISPLAY(destination → component)
  }
}
```

## NSQL Elements

### 1. Data Sources

```sql
-- Simple source
SOURCE: customers

-- Multiple sources
SOURCE: customers, transactions, products

-- Source with metadata
SOURCE: customers {
  Primary: true
  Update_Frequency: "Daily"
  Fields: [
    { Name: "customer_id", Type: "INTEGER", Key: true },
    { Name: "name", Type: "VARCHAR(255)" },
    { Name: "email", Type: "VARCHAR(255)" }
  ]
}
```

### 2. Operations

```sql
-- Filter operation
FILTER(customers → WHERE status = 'active' → active_customers)

-- Join operation
JOIN(orders → WITH customers ON orders.customer_id = customers.id → order_details)

-- Aggregate operation
AGGREGATE(sales → GROUP BY product_id | SUM(amount) AS total → product_totals)

-- Transform operation
TRANSFORM(raw_data → CLEAN DUPLICATES | FORMAT DATES → clean_data)

-- Extract operation
EXTRACT(transactions → DISTINCT customer_id → unique_customers)
```

### 3. Flow Control

```sql
-- Simple flow
FLOW: input.date_range 
  → FILTER(transactions BY date BETWEEN input.date_range.start AND input.date_range.end) 
  → display_table

-- Branching flow
FLOW: "Dashboard Update" {
  TRIGGER: input.refresh_button
  BRANCH: "Sales Data" {
    FILTER(transactions → RECENT 30 DAYS → recent_sales)
    DISPLAY(recent_sales → sales_chart)
  }
  BRANCH: "Customer Data" {
    FILTER(customers → ACTIVE STATUS → active_customers)
    COUNT(active_customers → total_active)
    DISPLAY(total_active → customer_counter)
  }
}
```

### 4. Component Mapping

```sql
-- Input component
COMPONENT: date_filter {
  Type: dateRangeInput
  Default: [CURRENT_DATE - 30 DAYS, CURRENT_DATE]
  Label: "Select Date Range"
  Effects: [
    TRIGGER: FILTER(transactions BY date BETWEEN input.date_filter.start AND input.date_filter.end)
  ]
}

-- Output component
COMPONENT: sales_summary {
  Type: valueBox
  Data_Source: filtered_transactions
  Operation: AGGREGATE(SUM(amount) AS total_sales)
  Format: "$#,##0.00"
  Icon: "dollar-sign"
  Color: "success"
}
```

### 5. Reactive Dependencies

```sql
-- Simple reactive dependency
REACTIVE: filtered_customers {
  DEPENDS_ON: [input.status_filter, input.date_range]
  OPERATION: FILTER(customers → WHERE status = input.status_filter AND 
                   date BETWEEN input.date_range.start AND input.date_range.end)
}

-- Complex reactive chain
REACTIVE_CHAIN: "Customer Analysis" {
  STEP 1: filtered_customers {
    DEPENDS_ON: [input.status_filter]
    OPERATION: FILTER(customers → WHERE status = input.status_filter)
  }
  
  STEP 2: customer_metrics {
    DEPENDS_ON: [filtered_customers]
    OPERATION: JOIN(filtered_customers → WITH transactions ON customer_id)
  }
  
  STEP 3: summary_statistics {
    DEPENDS_ON: [customer_metrics]
    OPERATION: AGGREGATE(customer_metrics → GROUP BY status | AVG(amount) AS avg_spend)
  }
  
  OUTPUT: DISPLAY(summary_statistics → summary_table)
}
```

### 6. Table Creation and Database Structure

NSQL provides syntax for defining and documenting database tables and their relationships. This allows for clear specification of data structures that can be implemented in various database systems.

```sql
-- Create a new table at a specific database connection
CREATE df_customer_profile AT app_data
===
CREATE OR REPLACE TABLE df_customer_profile (
  customer_id INTEGER,
  buyer_name VARCHAR,
  email VARCHAR,
  platform_id INTEGER NOT NULL,
  display_name VARCHAR GENERATED ALWAYS AS (buyer_name || ' (' || email || ')') VIRTUAL,
  PRIMARY KEY (customer_id, platform_id)
);

CREATE INDEX IF NOT EXISTS idx_df_customer_profile_platform_id_df_customer_profile 
ON df_customer_profile(platform_id);
===

-- Create a table in a specific schema
CREATE sales_history AT processed_data.archive
===
CREATE TABLE sales_history (
  id INTEGER PRIMARY KEY,
  transaction_date DATE NOT NULL,
  amount DECIMAL(10,2) NOT NULL,
  product_id INTEGER REFERENCES products(id)
);
===

-- Create a temporary table
CREATE temp_results AT app_data.temp
===
CREATE TEMPORARY TABLE temp_results (
  query_id INTEGER,
  result_data JSON,
  processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
===
```

The CREATE syntax uses a three-part format:
1. A high-level statement of intent: `CREATE table_name AT connection[.schema]`
2. Delimiter markers: `===`
3. The actual SQL implementation between the delimiters

This provides both human-readable intent and the precise SQL needed for implementation.

### 7. Radical Translation

NSQL supports radical translation between different representation systems while preserving semantic equivalence. This enables transforming data operations between different languages and paradigms.

```sql
-- SQL to R Translation Example
TRANSLATION: "Customer Table Schema" {
  SOURCE: SQL {
    CREATE TABLE customers (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
  }
  
  TARGET: R {
    generate_create_table_query(
      con = con,
      target_table = "customers",
      column_defs = list(
        list(name = "id", type = "INTEGER", not_null = TRUE),
        list(name = "name", type = "TEXT", not_null = TRUE),
        list(name = "email", type = "TEXT", unique = TRUE),
        list(name = "created_at", type = "TIMESTAMP", default = "CURRENT_TIMESTAMP")
      ),
      primary_key = "id"
    )
  }
  
  PROPERTIES_PRESERVED: [
    "structure",
    "constraints",
    "data_types",
    "defaults"
  ]
}

-- Natural Language to SQL Translation
TRANSLATION: "Customer Segmentation" {
  SOURCE: NATURAL_LANGUAGE {
    "Find all customers who have made at least 3 purchases with 
     an average order value above $100 in the last 6 months."
  }
  
  TARGET: SQL {
    SELECT c.id, c.name, c.email, 
           COUNT(o.id) AS order_count,
           AVG(o.total) AS avg_order_value
    FROM customers c
    JOIN orders o ON c.id = o.customer_id
    WHERE o.order_date >= DATE_SUB(CURRENT_DATE, INTERVAL 6 MONTH)
    GROUP BY c.id, c.name, c.email
    HAVING COUNT(o.id) >= 3 AND AVG(o.total) > 100
  }
}
```

For more details on radical translation principles and implementation, see [MP0065](MP065_radical_translation_in_nsql.md).

### 7. Testing and Validation

```sql
-- Simple test
TEST: "Active Customers Filter" {
  OPERATION: FILTER(customers → WHERE status = 'active')
  EXPECT: result.count > 0
  EXPECT: NOT EXISTS (SELECT 1 FROM result WHERE status != 'active')
}

-- Test with specific inputs
TEST: "Date Range Filter" {
  INPUTS: {
    date_range: ["2023-01-01", "2023-01-31"]
  }
  OPERATION: FILTER(transactions → WHERE date BETWEEN inputs.date_range[0] AND inputs.date_range[1])
  EXPECT: COUNT(*) = (SELECT COUNT(*) FROM transactions WHERE date BETWEEN '2023-01-01' AND '2023-01-31')
  EXPECT: MIN(date) >= '2023-01-01'
  EXPECT: MAX(date) <= '2023-01-31'
}
```

### 7. Visualization

```sql
-- Flow diagram
VISUALIZE: "Customer Acquisition Flow" {
  NODES: [
    { id: "marketing", label: "Marketing Campaigns", type: "source" },
    { id: "leads", label: "Leads Generated", type: "transform" },
    { id: "customers", label: "Converted Customers", type: "destination" }
  ]
  
  EDGES: [
    { from: "marketing", to: "leads", label: "Generate" },
    { from: "leads", to: "customers", label: "Convert", condition: "qualified = true" }
  ]
}

-- Entity relationship
ENTITY_DIAGRAM: "Sales Database" {
  ENTITIES: [
    {
      name: "customers",
      attributes: [
        { name: "customer_id", type: "INTEGER", key: "PRIMARY" },
        { name: "name", type: "VARCHAR(255)" },
        { name: "email", type: "VARCHAR(255)" }
      ]
    },
    {
      name: "transactions",
      attributes: [
        { name: "transaction_id", type: "INTEGER", key: "PRIMARY" },
        { name: "customer_id", type: "INTEGER", key: "FOREIGN" },
        { name: "amount", type: "DECIMAL(10,2)" },
        { name: "date", type: "DATE" }
      ]
    }
  ]
  
  RELATIONSHIPS: [
    { entity1: "customers", entity2: "transactions", type: "one-to-many", 
      join: "customers.customer_id = transactions.customer_id" }
  ]
}
```

### 8. Metadata Annotations

```sql
-- Column metadata
METADATA: transactions.amount {
  Type: "DECIMAL(10,2)"
  Constraints: ["NOT NULL", "CHECK (amount > 0)"]
  Business_Rules: "Negative amounts should be in refunds table"
  Statistics: {
    Min: 0.01,
    Max: 50000.00,
    Avg: 120.50,
    StdDev: 85.30
  }
  Missing_Value_Rate: 0.001
}

-- Table metadata
METADATA: customers {
  Primary_Key: "customer_id"
  Row_Count: ~500000
  Update_Frequency: "Daily at 3AM"
  Data_Owner: "CRM Team"
  Data_Quality: {
    Completeness: 99.8%,
    Accuracy: 98.5%,
    Consistency: 97.2%
  }
}
```

## Comprehensive Examples

### Example 1: Customer Dashboard Data Flow

```sql
-- Module: Customer Analysis Dashboard
-- Purpose: Analyze customer behavior and metrics
-- Author: Data Analytics Team
-- Last Updated: 2023-05-15

-- COMPONENT: date_range_input
-- Type: dateRangeInput
-- Default: [CURRENT_DATE - 90 DAYS, CURRENT_DATE]
-- Label: "Select Date Range:"

-- COMPONENT: customer_segment_filter
-- Type: selectInput
-- Data Source: customer_segments
-- SQL Query:
SELECT segment_id AS value, segment_name AS label FROM customer_segments

-- COMPONENT: status_filter
-- Type: checkboxGroupInput
-- Choices: ["Active", "Inactive", "New", "Churned"]
-- Default: ["Active", "New"]

DATA_FLOW(name: "Customer Dashboard") {
  SOURCE: customers, transactions, customer_segments
  
  REACTIVE(filtered_transactions) {
    DEPENDS_ON: [input.date_range_input, input.status_filter]
    OPERATION: FILTER(
      transactions 
      → WHERE 
          date BETWEEN input.date_range_input[0] AND input.date_range_input[1]
          AND status IN input.status_filter
      → current_transactions
    )
  }
  
  REACTIVE(customer_metrics) {
    DEPENDS_ON: [filtered_transactions, input.customer_segment_filter]
    OPERATION: TRANSFORM(
      filtered_transactions
      → JOIN(WITH customers ON transactions.customer_id = customers.id)
      → FILTER(WHERE segment_id = input.customer_segment_filter)
      → GROUP BY customer_id
      → AGGREGATE(
          COUNT(*) AS transaction_count,
          SUM(amount) AS total_spend,
          AVG(amount) AS avg_order_value,
          MAX(date) AS last_purchase_date
        )
      → customer_summary
    )
  }
  
  BRANCH: "Overview Metrics" {
    TRANSFORM(
      customer_metrics
      → AGGREGATE(
          COUNT(DISTINCT customer_id) AS customer_count,
          SUM(total_spend) AS total_revenue,
          AVG(avg_order_value) AS overall_aov,
          AVG(transaction_count) AS avg_transactions_per_customer
        )
      → dashboard_summary
    )
    
    DISPLAY(dashboard_summary.customer_count → customer_count_box)
    DISPLAY(dashboard_summary.total_revenue → revenue_box)
    DISPLAY(dashboard_summary.overall_aov → aov_box)
    DISPLAY(dashboard_summary.avg_transactions_per_customer → frequency_box)
  }
  
  BRANCH: "Customer Table" {
    TRANSFORM(
      customer_metrics
      → JOIN(WITH customers ON customer_metrics.customer_id = customers.id)
      → SELECT(
          customers.id,
          customers.name,
          customers.email,
          customer_metrics.transaction_count,
          customer_metrics.total_spend,
          customer_metrics.avg_order_value,
          customer_metrics.last_purchase_date
        )
      → ORDER BY total_spend DESC
      → customer_details_table
    )
    
    DISPLAY(customer_details_table → customer_table)
  }
  
  BRANCH: "Purchase Timeline" {
    TRANSFORM(
      filtered_transactions
      → GROUP BY DATE_TRUNC('week', date)
      → AGGREGATE(
          COUNT(*) AS transaction_count,
          COUNT(DISTINCT customer_id) AS customer_count,
          SUM(amount) AS weekly_revenue
        )
      → timeline_data
    )
    
    DISPLAY(timeline_data → timeline_chart)
  }
}

-- SQL equivalent for customer_metrics
-- SELECT
--   t.customer_id,
--   COUNT(*) AS transaction_count,
--   SUM(t.amount) AS total_spend,
--   AVG(t.amount) AS avg_order_value,
--   MAX(t.date) AS last_purchase_date
-- FROM transactions t
-- JOIN customers c ON t.customer_id = c.id
-- WHERE 
--   t.date BETWEEN :date_range_start AND :date_range_end
--   AND t.status IN (:status_filter)
--   AND c.segment_id = :segment_filter
-- GROUP BY t.customer_id

TEST: "Filter Validation" {
  INPUTS: {
    date_range_input: ["2023-01-01", "2023-01-31"],
    status_filter: ["Active"],
    customer_segment_filter: "Premium"
  }
  
  REACTIVE: filtered_transactions
  EXPECT: COUNT(*) > 0
  EXPECT: MIN(date) >= '2023-01-01'
  EXPECT: MAX(date) <= '2023-01-31'
  EXPECT: NOT EXISTS (SELECT 1 FROM result WHERE status NOT IN ('Active'))
  
  REACTIVE: customer_metrics
  EXPECT: NOT EXISTS (SELECT 1 FROM result r JOIN customers c ON r.customer_id = c.id WHERE c.segment_id != 'Premium')
}

VISUALIZE: "Dashboard Data Flow" {
  NODES: [
    { id: "input1", label: "Date Range", type: "input" },
    { id: "input2", label: "Status Filter", type: "input" },
    { id: "input3", label: "Segment Filter", type: "input" },
    { id: "data1", label: "Filtered Transactions", type: "data" },
    { id: "data2", label: "Customer Metrics", type: "data" },
    { id: "viz1", label: "Overview Metrics", type: "output" },
    { id: "viz2", label: "Customer Table", type: "output" },
    { id: "viz3", label: "Timeline Chart", type: "output" }
  ]
  
  EDGES: [
    { from: "input1", to: "data1" },
    { from: "input2", to: "data1" },
    { from: "data1", to: "data2" },
    { from: "input3", to: "data2" },
    { from: "data2", to: "viz1" },
    { from: "data2", to: "viz2" },
    { from: "data1", to: "viz3" }
  ]
}
```

### Example 2: Customer Selection Module

```sql
-- Module: Customer Selection
-- Purpose: Filter and select individual customers for detailed analysis
-- Author: UI Team
-- Last Updated: 2023-06-10

-- COMPONENT: customer_filter
-- Type: selectizeInput
-- Label: "Select Customer:"
-- Data Source: customers
-- SQL Query:
SELECT customer_id AS value, CONCAT(name, ' (', email, ')') AS label
FROM customers
WHERE customer_id IN (SELECT DISTINCT customer_id FROM dna_data)

DATA_FLOW(component: customer_filter) {
  SOURCE: dna_data, customer_profiles
  
  INITIALIZE: {
    EXTRACT(dna_data → DISTINCT customer_id → valid_ids)
    FILTER(customer_profiles → WHERE customer_id IN valid_ids → dropdown_options)
  }
  
  ON_SELECT: {
    value = customer_filter.selected
    FILTER(customer_profiles → WHERE customer_id = value → customer_detail)
    FILTER(dna_data → WHERE customer_id = value → customer_metrics)
  }
}

REACTIVE(customer_detail) {
  DEPENDS_ON: [input.customer_filter]
  OPERATION: FILTER(
    customer_profiles
    → WHERE customer_id = as.integer(input.customer_filter)
    → customer_profile_data
  )
}

REACTIVE(customer_metrics) {
  DEPENDS_ON: [input.customer_filter]
  OPERATION: FILTER(
    dna_data
    → WHERE customer_id = as.integer(input.customer_filter)
    → customer_dna_data
  )
}

REACTIVE(customer_transactions) {
  DEPENDS_ON: [input.customer_filter, input.date_range]
  OPERATION: FILTER(
    transactions
    → WHERE 
        customer_id = as.integer(input.customer_filter)
        AND date BETWEEN input.date_range.start AND input.date_range.end
    → customer_transaction_history
  )
}

DISPLAY(components: customer_detail) {
  OUTPUT: customer_name_display {
    Type: "textOutput"
    Value: customer_detail.name
  }
  
  OUTPUT: customer_email_display {
    Type: "textOutput"
    Value: customer_detail.email
  }
  
  OUTPUT: customer_since_display {
    Type: "textOutput"
    Value: format(customer_detail.first_purchase_date, "%Y-%m-%d")
  }
}

DISPLAY(components: customer_metrics) {
  OUTPUT: customer_metrics_display {
    Type: "valueBoxes"
    products: [
      {
        Value: customer_metrics.total_purchases
        Label: "Total Purchases"
        Icon: "shopping-cart"
        Color: "primary"
      },
      {
        Value: format(customer_metrics.total_spend, "$%.2f")
        Label: "Total Spend"
        Icon: "dollar-sign"
        Color: "success"
      },
      {
        Value: format(customer_metrics.avg_order_value, "$%.2f")
        Label: "Average Order"
        Icon: "calculator"
        Color: "info"
      }
    ]
  }
}

TEST: "Customer Filter Validation" {
  SETUP: {
    sample_customer_id = 12345
    add_test_data(
      customer_profiles = data.frame(
        customer_id = c(12345, 12346),
        name = c("Test Customer", "Another Customer"),
        email = c("test@example.com", "another@example.com")
      ),
      dna_data = data.frame(
        customer_id = c(12345, 12346),
        total_purchases = c(5, 8),
        total_spend = c(500, 800),
        avg_order_value = c(100, 100)
      )
    )
  }
  
  ACTION: {
    set_input(customer_filter = sample_customer_id)
  }
  
  EXPECT: {
    customer_detail$customer_id == sample_customer_id
    customer_metrics$customer_id == sample_customer_id
    customer_metrics$total_purchases == 5
    customer_metrics$total_spend == 500
  }
}

ENTITY_DIAGRAM: "Customer Data Model" {
  ENTITIES: [
    {
      name: "customers",
      attributes: [
        { name: "customer_id", type: "INTEGER", key: "PRIMARY" },
        { name: "name", type: "VARCHAR(255)" },
        { name: "email", type: "VARCHAR(255)" },
        { name: "first_purchase_date", type: "DATE" }
      ]
    },
    {
      name: "dna_data",
      attributes: [
        { name: "customer_id", type: "INTEGER", key: "FOREIGN" },
        { name: "total_purchases", type: "INTEGER" },
        { name: "total_spend", type: "DECIMAL(10,2)" },
        { name: "avg_order_value", type: "DECIMAL(10,2)" }
      ]
    }
  ]
  
  RELATIONSHIPS: [
    { entity1: "customers", entity2: "dna_data", type: "one-to-one", 
      join: "customers.customer_id = dna_data.customer_id" }
  ]
}
```

## Documentation Mapping to Implementation

The following table shows how NSQL elements map to implementation patterns in different frameworks:

| NSQL Element | R Shiny | React | Vue.js |
|--------------|---------|-------|--------|
| COMPONENT | UI function (e.g., `selectInput`) | Component (e.g., `<Select>`) | Component (e.g., `<v-select>`) |
| REACTIVE | `reactive()`, `reactiveVal()` | `useState()`, `useEffect()` | `ref()`, `computed()` |
| FILTER | `filter()` | `filter()` | `filter()` |
| AGGREGATE | `summarize()` | `reduce()` | `reduce()` |
| DISPLAY | `renderUI()`, `renderTable()` | `render()` | `template` |
| DEPENDS_ON | `observe()`, `observeEvent()` | `useEffect([deps])` | `watch()` |

## Best Practices

1. **Be explicit about data types**:
   ```sql
   -- GOOD
   FILTER(customers → WHERE customer_id = as.integer(input.customer_filter))
   
   -- BAD
   FILTER(customers → WHERE customer_id = input.customer_filter)
   ```

2. **Document all reactive dependencies**:
   ```sql
   -- GOOD
   REACTIVE(filtered_data) {
     DEPENDS_ON: [input.filter_a, input.filter_b, source_data]
     ...
   }
   
   -- BAD
   REACTIVE(filtered_data) {
     DEPENDS_ON: [input.filter_a] -- Missing dependencies
     ...
   }
   ```

3. **Use clear operation expressions**:
   ```sql
   -- GOOD
   TRANSFORM(source → operation → destination)
   
   -- BAD
   process the data and show it
   ```

4. **Include validation expectations**:
   ```sql
   -- GOOD
   FILTER(transactions → WHERE amount > 0)
   EXPECT: COUNT(*) = (SELECT COUNT(*) FROM transactions WHERE amount > 0)
   
   -- BAD
   FILTER(transactions → WHERE amount > 0)
   ```

5. **Document UI component interactions**:
   ```sql
   -- GOOD
   COMPONENT: status_filter {
     Effects: [TRIGGER: FILTER(data → WHERE status = input.status_filter)]
   }
   
   -- BAD
   COMPONENT: status_filter
   ```

## Related Principles

- MP27: Specialized Natural SQL Language (v2)
- MP24: Natural SQL Language
- MP52: Unidirectional Data Flow
- P73: Server-to-UI Data Flow
- P79: State Management
- P81: Tidyverse-Shiny Terminology Alignment