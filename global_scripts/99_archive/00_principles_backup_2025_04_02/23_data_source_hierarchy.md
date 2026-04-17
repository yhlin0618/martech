# Data Source Hierarchy Principle

This document establishes the principle for data source hierarchy in the precision marketing application, defining how data sources are prioritized and accessed across the application.

## Core Concept

The application should follow a clear hierarchy of data sources, with well-defined access patterns and explicit exceptions. This ensures data consistency, improves maintainability, and provides clear guidance on where specific types of data should be stored and accessed.

## Comprehensive Data Source Catalog

Data sources in the precision marketing ecosystem can be categorized into the following types:

1. **App-Specific Data (App Layer)**
   - `app_data/` directory (file-based app-specific data)
   - `Data.duckdb` (database-based app-specific data)
   - `app_configs/` (application configuration files)

2. **Project Data (Processing Layer)**
   - `processed_data/` (data that has been processed but isn't in final app form)
   - `cleansed_data/` (data that has been cleaned but needs further processing)
   - `raw_data/` (raw data imported from external sources)
   - `intermediate_data/` (data in intermediate processing stages)

3. **Shared Resources (Global Layer)**
   - `update_scripts/global_scripts/30_global_data/` (cross-project shared data)
   - `reference_data/` (stable reference tables used across projects)

4. **Development Resources (Development Layer)**
   - `test_data/` (data used for testing)
   - `mock_data/` (synthetic data for development)
   - Temporary files and directories

5. **External Sources (External Layer)**
   - External APIs
   - External databases
   - Cloud storage
   - FTP sites

## Data Access Hierarchy

For application operation, data sources should be prioritized in this order:

1. App-Specific Data (for application functionality)
2. Shared Resources (for common cross-project needs)
3. Project Data (for data updates and maintenance)
4. External Sources (as needed for data refreshes)

## Mode-Specific Data Access Scope

The application's operating modes (as defined in 18_operating_modes.md) have different data access permissions and scopes:

| Data Source | APP_MODE | UPDATE_MODE | GLOBAL_MODE |
|-------------|----------|-------------|-------------|
| **App Layer** |||
| `app_data/` | Read only | Read/Write | Read/Write |
| `Data.duckdb` | Read only | Read/Write | Read/Write |
| `app_configs/` | Read only | Read/Write | Read/Write |
| **Processing Layer** |||
| `processed_data/` | No access | Read/Write | Read/Write |
| `cleansed_data/` | No access | Read/Write | Read/Write |
| `raw_data/` | No access | Read/Write | Read/Write |
| `intermediate_data/` | No access | Read/Write | Read/Write |
| **Global Layer** |||
| X_global_data/` | Read only (subset) | Read only | Read/Write |
| `reference_data/` | Read only | Read only | Read/Write |
| **Development Layer** |||
| `test_data/` | No access | Full access | Full access |
| `mock_data/` | No access | Full access | Full access |
| **External Layer** |||
| External sources | No access | Read only | Read only |

### APP_MODE Data Access Scope
- **Purpose**: Production application execution
- **Access Pattern**: Minimal, read-only access to final data products
- **Accessible Data**:
  - Read-only access to app_data directory
  - Read-only access to app database (Data.duckdb)
  - Read-only access to a curated subset of 30_global_data
  - No access to processing layer data
  - No access to development resources
  - No access to external sources
- **Enforcement**:
  - All database connections forced to read-only
  - Access to processing data directories blocked
  - Limited file system visibility

### UPDATE_MODE Data Access Scope
- **Purpose**: Data processing and application development
- **Access Pattern**: Full access to project data, controlled access to shared resources
- **Accessible Data**:
  - Read-write access to all app-specific data
  - Read-write access to all processing layer data
  - Read-only access to global shared resources
  - Full access to development resources
  - Read-only access to external sources
- **Enforcement**:
  - App database connections allow read-write
  - Global resource connections forced to read-only
  - External source access monitored and logged

### GLOBAL_MODE Data Access Scope
- **Purpose**: Shared resource maintenance and cross-project management
- **Access Pattern**: Full access to all data layers
- **Accessible Data**:
  - Full access to all data layers
  - Read-write access to global shared resources
  - Read-write access to reference data
  - Administrative access to cross-project resources
- **Enforcement**:
  - Access to global resources logged and documented
  - Changes to shared resources require documentation
  - Modifications to reference data tracked in version control

## Implementation Guidelines

### 1. App-Specific Data Sources

App-specific data should be the primary data source whenever possible:

- **File-based data**: Store in `app_data/` directory
  - Structured by data type in subdirectories (e.g., `app_data/scd_type1/`, `app_data/scd_type2/`)
  - Used for configuration files, lookup tables, and other static data
  
- **Database-based data**: Store in `Data.duckdb`
  - Used for relational data that requires query capabilities
  - Appropriate for larger datasets and those requiring indexes
  - Suitable for data that needs transaction support

### 2. Shared Resource Data

The `update_scripts/global_scripts/30_global_data/` directory contains data that is shared across multiple projects:

- Should only be used for truly cross-project resources
- Access must be read-only by default within applications
- Modification should follow strict change management
- Changes must be documented and communicated to all dependent projects
- Versioning is required for shared data files

### 3. External Data Sources

External data sources should be used with caution and require:

- Explicit documentation of dependencies
- Error handling for unavailability
- Caching strategies to reduce external dependencies
- Version tracking of external data schema

## Access Patterns

### 1. Explicit Source Identification

All data access should explicitly identify the source:

```r
# Correct - explicitly identifies data source
customer_data <- read_from_app_data("customer_segments.csv")
sales_data <- dbGetQuery(db_connection, "SELECT * FROM sales")
reference_data <- load_from_global_data("industry_codes.rds")

# Incorrect - source is ambiguous
data <- read.csv("data.csv")  # Where is this file located?
```

### 2. Source Function Pattern

Implement source-specific access functions:

```r
# App-specific data access functions
read_from_app_data <- function(file_name, subdir = NULL) {
  path <- if (is.null(subdir)) {
    file.path("app_data", file_name)
  } else {
    file.path("app_data", subdir, file_name)
  }
  
  # Appropriate reading function based on file extension
  if (endsWith(file_name, ".csv")) {
    return(read.csv(path))
  } else if (endsWith(file_name, ".rds")) {
    return(readRDS(path))
  } else {
    # Additional formats...
  }
}

# Global shared data access
load_from_global_data <- function(file_name, version = "current") {
  path <- file.path("update_scripts", "global_scripts", "30_global_data", 
                   if (version == "current") file_name else file.path(version, file_name))
  
  # Appropriate reading function based on file extension
  # Similar implementation as above
}
```

### 3. Configuration-Based Data Source Mapping

Use the YAML configuration to explicitly map components to data sources:

```yaml
components:
  micro:
    customer_profile:
      primary: "app_data/customer_details.csv"  # App-specific data
      preferences: X_global_data/customer_preferences.rds"  # Shared data
```

### 4. Documentation of Source Exceptions

When accessing shared data, document the exception and rationale:

```r
# Access to shared resource with documentation
# EXCEPTION: Using 30_global_data shared resource because this
# reference data is maintained centrally for all projects
industry_codes <- load_from_global_data("industry_codes.rds")
```

## Best Practices

### 1. Source Isolation

- Components should ideally depend on a single data source type
- When multiple sources are needed, clearly separate their usage
- Consider creating unified views across multiple sources

### 2. Default Values

- All components should handle missing data gracefully
- Provide sensible defaults when data sources are unavailable
- Use the UI-Server-Defaults Triple Rule for Shiny components

### 3. Data Source Documentation

- Document all data sources in a central data catalog
- Include source, update frequency, and dependencies
- Clearly mark shared resources and their cross-project impact

### 4. Testing with Mock Data

- Design components that can function with mock data
- Create test data that mirrors production schemas
- Use the same access patterns for test and production data

## Source Priority Rules

When the same data could be available from multiple sources, follow these priorities:

1. **Primary Rule**: Use app-specific data over shared data when possible
2. **Exception Rule**: Use shared data when standardization across projects is required
3. **Update Rule**: App-specific data may override shared data, but this must be explicit
4. **Documentation Rule**: All exceptions to the primary rule must be documented

## Conclusion

By establishing a clear data source hierarchy and consistent access patterns, we ensure that our application's data dependencies are explicit, maintainable, and properly isolated. The exceptions for shared resources in `30_global_data` are recognized as an important cross-project resource while maintaining the primacy of app-specific data for most use cases.