---
id: R078
type: Rule
category: naming_conventions
title: Column Naming Convention for Operations
status: active
version: 1.0.0
created: 2025-11-02
updated: 2025-11-02
related:
  - R069_function_file_naming
  - R070_ntuple_delimiter
  - MP002_primitive_terms_and_definitions
applies_to:
  - data_transformation
  - feature_engineering
  - aggregation_operations
  - temporal_analysis
---

# R078: Column Naming Convention for Operations

## Statement

When creating derived columns through operations (aggregation, transformation, calculation), column names MUST follow the pattern:

```
operation__columnname_by_at
```

Where:
- `operation`: The operation performed (sum, count, mean, ratio, etc.)
- `__`: Double underscore separator (distinguishes operation from base column name)
- `columnname`: The target column or metric name
- `_by` or `_at`: Suffix indicating grouping context or temporal context
  - `_by`: Indicates grouping dimension (e.g., `_by_customer`, `_by_region`)
  - `_at`: Indicates temporal dimension (e.g., `_at_month`, `_at_year`)

## Rationale

### 1. Clarity of Origin
The double underscore separator clearly distinguishes:
- **Derived columns** (with operation prefix): `sum__revenue_by_region`
- **Base columns** (no operation): `revenue`

This prevents confusion about whether a column is raw data or computed.

### 2. Self-Documenting Code
The pattern embeds critical information in the column name:
- **What** was done: The operation type
- **To what**: The target column/metric
- **In what context**: The grouping or temporal dimension

Example: `mean__purchase_value_by_customer` immediately tells you this is the mean purchase value calculated per customer.

### 3. Consistent Query Patterns
When multiple operations are performed on the same data, the pattern creates visual alignment:

```r
# Clear visual structure
sum__revenue_by_month
mean__revenue_by_month
count__orders_by_month
ratio__conversion_by_month
```

### 4. Prevents Name Collisions
Without a standard pattern, derived columns risk colliding with base columns:

```r
# BAD: Ambiguous
revenue              # Is this total revenue or revenue per customer?
customer_revenue     # Base column or aggregated?

# GOOD: Unambiguous
revenue              # Base column
sum__revenue_by_customer  # Clearly derived
```

## Pattern Specification

### Basic Structure

```
{operation}__{metric}_{context}
```

### Operation Types

Common operations include:
- Aggregations: `sum`, `mean`, `median`, `min`, `max`, `count`, `stddev`
- Ratios: `ratio`, `pct`, `rate`
- Rankings: `rank`, `percentile`, `ntile`
- Transformations: `log`, `sqrt`, `diff`, `cumsum`
- Windows: `lag`, `lead`, `rolling_mean`

### Context Suffixes

#### Grouping Context (`_by`)
Use `_by_{dimension}` when the operation is performed within groups:

```r
sum__revenue_by_customer      # Revenue summed per customer
count__orders_by_region       # Order count per region
mean__basket_size_by_store    # Average basket size per store
```

#### Temporal Context (`_at`)
Use `_at_{timeunit}` when the operation is performed over time periods:

```r
sum__sales_at_month          # Sales summed by month
mean__traffic_at_day         # Traffic averaged by day
count__visits_at_week        # Visits counted by week
```

#### Combined Context
For multi-dimensional aggregations, combine both:

```r
sum__revenue_by_customer_at_month   # Revenue per customer per month
mean__spend_by_region_at_quarter    # Average spend per region per quarter
```

## Examples

### Correct Usage

#### Basic Aggregation Operations
```r
# Customer-level aggregations
data %>%
  group_by(customer_id) %>%
  summarize(
    sum__revenue_by_customer = sum(revenue),
    count__orders_by_customer = n(),
    mean__basket_size_by_customer = mean(basket_size),
    max__purchase_date_by_customer = max(purchase_date)
  )

# Regional aggregations
data %>%
  group_by(region) %>%
  summarize(
    sum__sales_by_region = sum(sales),
    count__stores_by_region = n_distinct(store_id),
    mean__aov_by_region = mean(average_order_value)
  )
```

#### Temporal Operations
```r
# Monthly time series
data %>%
  group_by(year_month) %>%
  summarize(
    sum__revenue_at_month = sum(revenue),
    count__transactions_at_month = n(),
    mean__basket_at_month = mean(basket_size)
  )

# Daily metrics
data %>%
  group_by(date) %>%
  summarize(
    sum__visitors_at_day = sum(visitors),
    ratio__conversion_at_day = sum(conversions) / sum(visitors)
  )
```

#### Complex Operations
```r
# RFM analysis
customers %>%
  summarize(
    max__purchase_date_by_customer = max(purchase_date),  # Recency
    count__orders_by_customer = n(),                      # Frequency
    sum__revenue_by_customer = sum(revenue)               # Monetary
  ) %>%
  mutate(
    # Derived from derived columns
    diff__days_since_purchase = as.numeric(today() - max__purchase_date_by_customer),
    mean__order_value_by_customer = sum__revenue_by_customer / count__orders_by_customer
  )

# Multi-level aggregation
data %>%
  group_by(customer_id, month) %>%
  summarize(
    sum__revenue_by_customer_at_month = sum(revenue),
    count__orders_by_customer_at_month = n()
  )
```

#### Window Functions
```r
# Ranking operations
data %>%
  group_by(category) %>%
  mutate(
    rank__sales_by_category = rank(-sales),
    percentile__sales_by_category = percent_rank(sales),
    ntile__sales_by_category = ntile(sales, 10)
  )

# Lag/lead operations
data %>%
  group_by(customer_id) %>%
  arrange(date) %>%
  mutate(
    lag__revenue_by_customer = lag(revenue, 1),
    lead__revenue_by_customer = lead(revenue, 1),
    diff__revenue_by_customer = revenue - lag__revenue_by_customer
  )
```

### Incorrect Usage

```r
# BAD: No operation prefix
revenue_by_customer        # Unclear if this is derived or base
customer_revenue           # Ambiguous naming

# BAD: Single underscore separator
sum_revenue_by_customer    # Hard to distinguish operation from column name

# BAD: No context suffix
sum__revenue               # Missing grouping/temporal context
mean__basket               # What level is this aggregated at?

# BAD: Inconsistent naming
total_revenue_customer     # Different pattern
customer_order_count       # Different pattern
avg_basket_size            # Different pattern

# GOOD: Consistent pattern
sum__revenue_by_customer
count__orders_by_customer
mean__basket_size_by_customer
```

## When to Apply This Rule

### Required Contexts

1. **Aggregation operations**: Any `summarize()` or `aggregate()` operation
2. **Group-wise transformations**: Operations within `group_by()` contexts
3. **Window functions**: `mutate()` operations that depend on group structure
4. **Feature engineering**: Derived metrics for modeling
5. **Reporting calculations**: Any computed column in reports or dashboards

### Optional Contexts

This rule is optional for:
- **Intermediate calculations** within a function (temporary variables)
- **Base column renaming** without operations (use simple descriptive names)
- **Foreign keys** and **identifiers** (use standard `_id` suffix)

### Exceptions

Do NOT apply this pattern to:
1. **Base table columns**: Original data columns keep their native names
2. **Primary/Foreign keys**: Use `table_id` convention (per database naming rules)
3. **Boolean flags**: Use `is_` or `has_` prefix (e.g., `is_active`, `has_purchased`)
4. **Categorical encodings**: Use descriptive names (e.g., `customer_segment`, `product_category`)

## Related Principles

- **R069 - Function File Naming**: Similar pattern for function files (`fn_verb_object.R`)
- **R070 - N-Tuple Delimiter**: Double underscore as structural separator
- **MP002 - Primitive Terms**: Defines terminology for operations and contexts
- **R091 - Universal Data Access Pattern**: Consistent data manipulation patterns

## Enforcement

### Automated Checks
Code review and linting tools should verify:
1. Aggregation operations produce columns with operation prefix
2. Double underscore separator is used
3. Context suffix (`_by` or `_at`) is present

### Manual Review
During code review, check:
1. Column names self-document their derivation
2. Similar operations follow consistent naming
3. No ambiguity between base and derived columns

## Implementation Checklist

When creating derived columns:
- [ ] Identify the operation type (sum, mean, count, etc.)
- [ ] Use double underscore `__` after operation name
- [ ] Include the target column/metric name
- [ ] Add `_by_{dimension}` for grouping operations
- [ ] Add `_at_{timeunit}` for temporal operations
- [ ] Verify no name collision with base columns
- [ ] Ensure consistency with existing derived columns

## Benefits

1. **Immediate Comprehension**: Column names self-document their origin
2. **Reduced Cognitive Load**: No need to trace back through code to understand derivation
3. **Easier Debugging**: Clear distinction between base and derived data
4. **Better Collaboration**: Team members instantly understand column meaning
5. **Simplified Documentation**: Column names serve as inline documentation
6. **Query Optimization**: Database engines can better optimize operations with clear naming

---

**Version History**:
- 1.0.0 (2025-11-02): Initial principle definition based on ISSUE_004 resolution
