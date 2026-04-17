# DM_R040: Schema Definition Pattern for Column Aliasing

## Statement
Database schemas shall be defined using R list structures with support for virtual column aliasing to maintain backward compatibility while evolving data structures.

## Rationale
As data schemas evolve, column names may change to better reflect their purpose (e.g., `item_id` to `product_id`). Rather than breaking existing code that depends on old column names, we use virtual column aliasing to provide both names simultaneously. This ensures backward compatibility while allowing gradual migration to new naming conventions.

## Implementation

### Schema Definition Structure
```r
get_[table_name]_schema <- function() {
  list(
    table_name = "table_name",
    column_defs = list(
      # Physical columns
      list(name = "actual_column", type = "VARCHAR", not_null = TRUE),

      # Virtual alias columns
      list(
        name = "alias_column",
        type = "VARCHAR",
        generated_as = "actual_column",
        generated_type = "VIRTUAL"
      )
    ),
    primary_key = c("key_columns"),
    indexes = list(
      list(columns = "indexed_column", name = "idx_name")
    ),
    documentation = list(
      aliases = list(
        alias_column = "Description of why this alias exists"
      )
    )
  )
}
```

### Location Convention
Schema definitions should be placed in:
`/scripts/global_scripts/00_principles/natural/en/part2_implementations/CH17_database_specifications/etl_schemas/r_definitions/`

### File Naming
Schema definition files should follow the pattern: `get_[table_name]_schema.R`

## Examples

### Example 1: Product Positioning Table
```r
# File: get_df_position_schema.R
get_df_position_schema <- function() {
  list(
    table_name = "df_position",
    column_defs = list(
      list(name = "item_id", type = "VARCHAR", not_null = TRUE),
      # Virtual alias for backward compatibility
      list(name = "product_id", type = "VARCHAR",
           generated_as = "item_id",
           generated_type = "VIRTUAL")
    ),
    documentation = list(
      aliases = list(
        product_id = "Alias for item_id to maintain compatibility with components expecting product_id"
      )
    )
  )
}
```

### Example 2: Customer Table with Display Name
```r
get_df_customer_schema <- function() {
  list(
    table_name = "df_customer",
    column_defs = list(
      list(name = "first_name", type = "VARCHAR"),
      list(name = "last_name", type = "VARCHAR"),
      list(name = "email", type = "VARCHAR"),
      # Generated display column
      list(name = "display_name", type = "VARCHAR",
           generated_as = "first_name || ' ' || last_name || ' <' || email || '>'",
           generated_type = "VIRTUAL")
    )
  )
}
```

## Benefits

1. **Backward Compatibility**: Existing code continues to work with old column names
2. **Zero Storage Overhead**: Virtual columns don't consume additional storage
3. **Query Transparency**: Applications can use either name interchangeably
4. **Self-Documenting**: Schema definitions include documentation about aliases
5. **Type Safety**: R list structures provide compile-time checking
6. **Programmatic Access**: Schemas can be validated and tested programmatically

## Related Principles

- **MP058**: Database Table Creation Strategy
- **DM_R023**: Universal DBI Approach (formerly R092)
- **R091**: Universal Data Access Pattern
- **MP044**: Functor-Module Correspondence

## Validation

Schemas should include a validation function:
```r
validate_[table_name]_schema <- function(con, verbose = TRUE) {
  schema <- get_[table_name]_schema()
  # Check table existence
  if (!DBI::dbExistsTable(con, schema$table_name)) {
    return(FALSE)
  }
  # Verify column aliases work
  # Return validation status
  return(TRUE)
}
```

## Migration Path

When transitioning from old to new column names:
1. Add virtual alias in schema definition
2. Update components gradually to use new names
3. Monitor usage of old names via query logs
4. Remove alias only after full migration confirmed

## Database Support

This pattern is supported by:
- **DuckDB**: GENERATED columns (VIRTUAL and STORED)
- **PostgreSQL**: GENERATED columns (from version 12+)
- **SQLite**: GENERATED columns (from version 3.31.0+)
- **MySQL**: GENERATED columns
- **SQL Server**: Computed columns

For databases without native support, consider using views as an alternative implementation.

---

**Category**: Data Management Rule
**Created**: 2024-01-28
**Status**: Active