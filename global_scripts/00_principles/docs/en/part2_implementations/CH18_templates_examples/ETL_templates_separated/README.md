# ETL Templates for Separated Data Flow Architecture

This directory contains template scripts for implementing the new **ETL Data Flow Separation Architecture** defined by MP104 and DM_R028.

## Overview

These templates solve the critical issue of mixed-type ETL pipelines by providing specialized templates for each data type, ensuring proper separation of concerns while maintaining API efficiency.

## Template Files

### 1. Sales Data Pipeline Template
**File**: `template_ETL_sales_0IM.R`
- **Purpose**: Import sales transaction data
- **Output**: `df_{platform}_sales___raw` table
- **Core Fields**: order_id, customer_id, product_id, quantity, unit_price, total_amount
- **Use Case**: Transaction-level sales data processing

### 2. Customer Data Pipeline Template  
**File**: `template_ETL_customers_0IM.R`
- **Purpose**: Import customer profile data
- **Output**: `df_{platform}_customers___raw` table
- **Core Fields**: customer_id, customer_email, customer_name, registration_date
- **Use Case**: Customer demographics and profile management

### 3. Shared API Import Template
**File**: `template_ETL_shared_0IM.R`
- **Purpose**: Single API call with data distribution to multiple types
- **Output**: Multiple tables (`df_{platform}_{datatype}___raw`)
- **Benefit**: API efficiency while maintaining data type separation
- **Use Case**: When platform API returns multiple data types in one call

## Usage Instructions

### Step 1: Choose Your Template Pattern

#### Pattern A: Independent Data Type Imports
Use individual templates when:
- Platform has efficient data type-specific API endpoints
- Different data types require different processing logic
- Error isolation is critical

**Example**: 
- `cbz_ETL_sales_0IM.R` (from template_ETL_sales_0IM.R)
- `cbz_ETL_customers_0IM.R` (from template_ETL_customers_0IM.R)

#### Pattern B: Shared Import with Distribution
Use shared template when:
- Platform API returns multiple data types in one response
- API rate limiting is a concern
- Network efficiency is prioritized

**Example**:
- `cbz_ETL_shared_0IM.R` (from template_ETL_shared_0IM.R)

### Step 2: Customize Template for Platform

1. **Replace Platform Placeholders**:
   ```bash
   sed 's/{platform}/cbz/g' template_ETL_sales_0IM.R > cbz_ETL_sales_0IM.R
   sed 's/{Platform}/Cyberbiz/g' cbz_ETL_sales_0IM.R > cbz_ETL_sales_0IM.R
   ```

2. **Implement Platform-Specific Functions**:
   - `fetch_{platform}_sales_data()` - API/file data fetching
   - `process_sales_import()` - Data processing and cleaning
   - `validate_sales_import()` - Quality validation

3. **Add Platform-Specific Fields**:
   ```r
   # Replace generic placeholders with actual fields
   {platform}_specific_field1 -> cbz_shop_id
   {platform}_specific_field2 -> cbz_member_level
   ```

### Step 3: Create Complete Pipeline Set

For each data type, create all three phases:

```bash
# Sales pipeline
cbz_ETL_sales_0IM.R   # Import (use template)
cbz_ETL_sales_1ST.R   # Staging (create from template pattern)  
cbz_ETL_sales_2TR.R   # Transform (create from template pattern)

# Customer pipeline
cbz_ETL_customers_0IM.R   # Import (use template)
cbz_ETL_customers_1ST.R   # Staging 
cbz_ETL_customers_2TR.R   # Transform

# Order pipeline (create additional templates as needed)
cbz_ETL_orders_0IM.R
cbz_ETL_orders_1ST.R
cbz_ETL_orders_2TR.R
```

## Template Features

### 1. MP102 Compliance
All templates implement ETL Output Standardization:
- Core schema fields guaranteed across platforms
- Platform-specific extensions clearly marked
- Consistent table naming patterns

### 2. DM_R028 Compliance
All templates enforce ETL Data Type Separation:
- Single responsibility per script
- Proper naming convention: `{platform}_ETL_{datatype}_{phase}.R`
- No mixed data types in single pipeline

### 3. R113 Four-Part Structure
All templates follow the standard script structure:
1. **INITIALIZE**: Setup, connections, function loading
2. **MAIN**: Core processing logic
3. **TEST**: Validation and quality checks
4. **RESULT**: Summary, cleanup, autodeinit

### 4. Built-in Validation
Each template includes:
- Schema compliance checking
- Data type validation
- Record count verification
- Platform ID consistency
- Error handling and reporting

## Migration from Legacy ETLs

### Identify Current Mixed ETLs
```bash
# Find existing mixed-type ETLs
find scripts/update_scripts -name "*ETL*" -type f | grep -E "(ETL01|ETL02)"
```

### Extract Data Type Logic
1. **Analyze current ETL**: Identify what data types it processes
2. **Extract logic**: Separate sales, customer, order processing code
3. **Apply templates**: Use appropriate template for each data type
4. **Test separation**: Ensure each pipeline works independently

### Example Migration: cbz_ETL01 Series

**Before (Mixed)**:
```
cbz_ETL01_0IM.R  # Imports sales + customers + orders (VIOLATION)
cbz_ETL01_1ST.R  # Only processes sales (orphans other data)
cbz_ETL01_2TR.R  # Only processes sales (orphans other data)
```

**After (Separated)**:
```
# Sales pipeline
cbz_ETL_sales_0IM.R  # Sales import only
cbz_ETL_sales_1ST.R  # Sales staging only  
cbz_ETL_sales_2TR.R  # Sales transform only

# Customer pipeline  
cbz_ETL_customers_0IM.R  # Customer import only
cbz_ETL_customers_1ST.R  # Customer staging only
cbz_ETL_customers_2TR.R  # Customer transform only

# Order pipeline
cbz_ETL_orders_0IM.R  # Order import only
cbz_ETL_orders_1ST.R  # Order staging only
cbz_ETL_orders_2TR.R  # Order transform only
```

## Orchestration Patterns

### Sequential Execution
```r
# Execute all data types for a platform
execute_cbz_etl_complete <- function() {
  # Phase 1: Import all data types
  cbz_ETL_sales_0IM()
  cbz_ETL_customers_0IM()
  cbz_ETL_orders_0IM()
  
  # Phase 2: Stage all data types
  cbz_ETL_sales_1ST()
  cbz_ETL_customers_1ST()
  cbz_ETL_orders_1ST()
  
  # Phase 3: Transform all data types
  cbz_ETL_sales_2TR()
  cbz_ETL_customers_2TR()
  cbz_ETL_orders_2TR()
}
```

### Parallel Execution  
```r
# Execute data types in parallel for efficiency
execute_cbz_etl_parallel <- function() {
  # Import phase (parallel)
  future_map(c("sales", "customers", "orders"), ~{
    func_name <- sprintf("cbz_ETL_%s_0IM", .x)
    do.call(func_name, list())
  })
  
  # Continue with staging and transform phases
}
```

### Error Isolation
```r
# Execute with error isolation per data type
execute_with_isolation <- function(pipeline_name, pipeline_func) {
  tryCatch({
    result <- pipeline_func()
    log_success(pipeline_name)
    return(TRUE)
  }, error = function(e) {
    log_error(pipeline_name, e$message)
    # Other pipelines continue
    return(FALSE)
  })
}
```

## Validation and Quality Assurance

### Template Compliance Check
```r
# Validate template customization
validate_template_compliance <- function(script_path) {
  # Check naming convention
  if (!grepl("^[a-z]{3}_ETL_[a-z_]+_(0IM|1ST|2TR)\\.R$", basename(script_path))) {
    stop("Script name violates DM_R028 naming convention")
  }
  
  # Check single responsibility
  validate_single_responsibility(script_path)
  
  # Check MP102 schema compliance
  validate_mp102_compliance(script_path)
  
  return(TRUE)
}
```

### Output Schema Validation
```r
# Validate output against MP102 standards
validate_etl_output_schema <- function(con, table_name, platform, datatype) {
  # Check core fields exist
  required_core_fields <- get_required_core_fields(datatype)
  actual_fields <- dbListFields(con, table_name)
  
  missing_fields <- setdiff(required_core_fields, actual_fields)
  if (length(missing_fields) > 0) {
    stop(sprintf("Missing core fields: %s", paste(missing_fields, collapse = ", ")))
  }
  
  # Check platform_id consistency
  platform_ids <- dbGetQuery(con, sprintf("SELECT DISTINCT platform_id FROM %s", table_name))
  if (nrow(platform_ids) != 1 || platform_ids$platform_id[1] != platform) {
    stop("Platform ID inconsistency detected")
  }
  
  return(TRUE)
}
```

## Benefits of This Architecture

### 1. Clear Separation of Concerns
- Each script handles exactly one data type
- No mixing of sales, customer, order processing
- Clear boundaries for debugging and maintenance

### 2. API Efficiency Options
- **Shared Import**: Single API call with distribution
- **Independent Import**: Specialized API calls per data type
- Choose based on platform characteristics

### 3. Parallel Processing Capability
- Data types can be processed concurrently
- Faster overall ETL execution
- Better resource utilization

### 4. Error Isolation
- Failures in one data type don't affect others
- Easier debugging and troubleshooting
- More resilient data processing

### 5. Maintenance Simplicity
- Changes isolated to relevant data type
- Easier to add new data types
- Clear testing boundaries

## Support Functions Required

When implementing these templates, ensure these support functions exist:

### Data Type-Specific Functions
- `fetch_{platform}_{datatype}_data()`
- `process_{datatype}_import()`
- `validate_{datatype}_import()`

### General ETL Utilities
- `dbConnectDuckdb()` 
- `write_etl_output()`
- `validate_etl_output()`

### Platform-Specific Extraction (for shared import)
- `extract_sales_data()`
- `extract_customers_data()`
- `extract_orders_data()`
- `extract_products_data()`

## Conclusion

These templates provide a solid foundation for implementing the new ETL Data Flow Separation Architecture. They ensure compliance with MAMBA principles while providing the flexibility to handle platform-specific requirements and API characteristics.

Use these templates to migrate away from mixed-type ETL pipelines and towards a clean, maintainable, and scalable data processing architecture.