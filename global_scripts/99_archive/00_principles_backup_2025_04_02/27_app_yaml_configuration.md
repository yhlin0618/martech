---
id: "P27"
title: "YAML Configuration"
type: "principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "MP01": "Primitive Terms and Definitions"
  - "P07": "App Construction Principles"
  - "MP22": "Instance vs. Principle"
related_to:
  - "P17": "App Construction Function"
  - "P23": "Data Source Hierarchy"
  - "MP29": "Terminology Axiomatization"
---

# App YAML Configuration Principle

This principle establishes guidelines for using YAML configuration files in the precision marketing application, enabling declarative app construction and promoting separation of configuration from implementation.

## Core Concept

Application configuration should be externalized in YAML files that define the structure, components, and data sources without requiring code changes. This enables non-developers to modify application behavior and supports a clear separation between configuration (instances) and implementation (principles).

## Configuration Location

All YAML configuration files should be stored in the `app_configs` directory at the project root:

```
precision_marketing_app/
└── app_configs/
    ├── customer_dna_app.yaml   # Main app configuration
    ├── component_config.yaml   # Component-specific configuration
    └── data_sources.yaml       # Data source mappings
```

This follows the Instance vs. Principle Meta-Principle by placing instance-specific configurations outside the global_scripts directory.

## YAML Structure Guidelines

### 1. Basic Structure

Every YAML configuration file should include:

```yaml
# [File Description]
# [Author]
# [Date Created]
title: [Application Title]
version: [Configuration Version]

# Main configuration sections follow...
```

### 2. Standard Format Patterns

The configuration follows five standard patterns for data source and environment specifications. A key principle is: **If there is only one data source, the role is unnecessary; if there are multiple sources, they are discriminated by their roles.**

```yaml
# Pattern 1: Simple String Format
component_name: dataset_name

# Pattern 2: Array Format 
component_name: 
  - dataset1
  - dataset2
  - dataset3

# Pattern 3: Object Format with Roles
component_name:
  role1: dataset1
  role2: dataset2
  role3: dataset3

# Pattern 4a: Single Data Source with Parameters
component_name:
  data_source: dataset_name    # Single data source
  parameters:                  # Component parameters
    param1: value1
    param2: value2

# Pattern 4b: Multiple Data Sources with Roles and Parameters
component_name:
  role1: dataset1              # Multiple data sources with roles
  role2: dataset2
  parameters:                  # Component parameters
    param1: value1
    param2: value2

# Pattern 5: Environment Configuration Pattern
environment_name:
  data_source: "path/to/data"  # Data source path
  parameters:                  # Environment parameters
    param1: value1
    param2: value2
```

### 3. Data Source Specification Formats

These are the specific implementations of the patterns for component data sources:

#### 1. Simple String Format
For components requiring a single data source (no role needed):

```yaml
components:
  macro:
    overview: sales_summary_view
```

#### 2. Array Format
For components requiring multiple tables in a specific order (implicit indexing):

```yaml
components:
  target:
    segmentation:
      - customer_segments
      - segment_definitions
      - segment_metrics
```

#### 3. Object Format
For components requiring multiple tables with specific roles (explicit roles):

```yaml
components:
  micro:
    customer_profile:
      primary: customer_details
      preferences: customer_preferences
      history: customer_history
```

### 4. Comments and Documentation

YAML configurations should be well-documented:

```yaml
# Customer DNA Application Configuration
# This configuration defines the structure and data sources for the Customer DNA app

title: AI行銷科技平台

# Theme settings control the visual appearance
# version: Bootstrap version
# bootswatch: Theme name from the Bootswatch library
theme:
  version: 5  # Using Bootstrap 5
  bootswatch: cosmo  # Clean, modern appearance
```

### 5. Hierarchical Organization

Configuration should be hierarchically organized by category, using the data source formats described above:

```yaml
# App-level settings
title: AI行銷科技平台
theme:
  version: 5
  bootswatch: cosmo
layout: navbar

# Component configuration
components:
  # Section 1 components
  macro:
    # Simple component with single data source (Format 1)
    overview: sales_summary_view
    
    # Component with data source and parameters
    trends:
      data_source: sales_trends  # Single data source
      parameters:                # Component parameters
        show_kpi: true
        refresh_interval: 300
  
  # Section 2 components
  micro:
    # Component with multiple data sources (Format 3)
    customer_profile:
      primary: customer_details        # Multiple data sources with roles
      preferences: customer_preferences
      history: customer_history
      
    # Component with multiple data sources and parameters
    advanced_profile:
      primary: customer_details        # Multiple data sources with roles
      history: customer_history
      parameters:                      # Component parameters
        default_view: "summary"
        enable_export: false
```

## Implementation Guidelines

### 1. YAML Loading

Use the standardized `readYamlConfig` utility to load YAML configurations:

```r
# Load configuration
config <- readYamlConfig("customer_dna_app.yaml")

# Access configuration values with safe fallbacks
app_title <- config$title %||% "Default Title"
theme_settings <- config$theme %||% list(version = 5, bootswatch = "default")
```

### 2. Configuration Validation

Always validate configurations before using them:

```r
# Validate required fields
validateConfig <- function(config) {
  required_fields <- c("title", "components")
  missing_fields <- required_fields[!required_fields %in% names(config)]
  
  if (length(missing_fields) > 0) {
    warning("Configuration missing required fields: ", 
            paste(missing_fields, collapse = ", "))
    return(FALSE)
  }
  
  return(TRUE)
}
```

### 3. Data Source Processing

Use the `processDataSource` utility to handle all data source formats consistently:

```r
# In server component
data_tables <- reactive({
  processDataSource(
    data_source = config$components$micro$customer_profile,
    table_names = c("primary", "preferences", "history")
  )
})

# Then access the standardized structure
customer_data <- reactive({ data_tables()$primary })
preferences_data <- reactive({ data_tables()$preferences })
```

### 4. Environment-Specific Configuration

Environment configurations should combine data path assignment with parameters:

```yaml
# App-wide environment-specific configurations
environments:
  development:
    data_source: "development_data/"  # Data source path
    parameters:                       # Environment parameters
      debug: true
  production:
    data_source: "app_data/"          # Data source path
    parameters:                       # Environment parameters
      debug: false
```

This approach follows the pattern where each environment specifies its data source path directly while keeping configuration parameters separate in a parameters object.

## Complete Configuration Example

```yaml
# Customer DNA Analysis Dashboard Configuration
title: AI行銷科技平台
theme:
  version: 5
  bootswatch: cosmo
layout: navbar

# Components with their data sources - demonstrates all three formats
components:
  macro:
    # Format 1: Simple string format (single data source, no role needed)
    overview: sales_summary_view
    
    # Component with single data source and parameters
    trends:
      data_source: sales_trends      # Single data source
      parameters:                    # Component parameters
        show_kpi: true
        refresh_interval: 300
  
  micro:
    # Format 3: Object format with named roles (multiple data sources)
    customer_profile:
      primary: customer_details
      preferences: customer_preferences
      history: customer_history
    
    # Format 1: Simple string format again (single data source)
    transactions: transaction_history
  
  target:
    # Format 2: Array format for ordered tables (multiple sources with implicit ordering)
    segmentation:
      - customer_segments
      - segment_definitions
      - segment_metrics
    
    # Format 3 with parameters (multiple sources with explicit roles)
    advanced_segmentation:
      primary: customer_segments      # Primary data source
      reference: segment_definitions  # Reference data source
      parameters:                     # Component parameters
        visualization_type: "tree"
        max_depth: 3

# Environment-specific configurations
environments:
  development:
    data_source: "development_data/"  # Data source path
    parameters:                       # Environment parameters
      debug: true
  production:
    data_source: "app_data/"          # Data source path
    parameters:                       # Environment parameters
      debug: false
```

## Benefits

1. **Separation of Concerns**: Configurations are separate from implementation code
2. **Non-Developer Access**: Non-developers can modify app behavior through configuration
3. **Environment Flexibility**: Different configurations for different environments
4. **Reduced Code Changes**: App modifications without code changes
5. **Self-Documentation**: YAML format with comments provides clear documentation
6. **Consistency**: Standardized configuration format across applications

## Relationship to Other Principles

This principle works in conjunction with:

1. **App Construction Function Principle** (17_app_construction_function.md): Uses YAML configurations to build apps
2. **Instance vs. Principle Meta-Principle** (22_instance_vs_principle.md): Configurations are instances, separate from implementation principles
3. **App Principles** (07_app_principles.md): Follows the Component Reuse Rule and Bottom-Up Construction Rule
4. **Data Source Hierarchy Principle** (23_data_source_hierarchy.md): Respects the data source hierarchy in configurations
5. **Platform-Neutral Code Principle** (26_platform_neutral_code.md): Ensures configurations work across platforms

## Best Practices

1. **Validate Configurations**: Always validate configuration files before use
2. **Provide Defaults**: Include sensible defaults for missing configuration elements
3. **Document with Comments**: Use YAML comments to explain configuration options
4. **Version Control**: Track configuration changes in version control when appropriate
5. **Test Different Formats**: Ensure components work with all data source formats
6. **Use Platform-Neutral Paths**: Follow platform-neutral path construction in configurations
7. **Keep Configurations DRY**: Avoid redundancy in configurations
8. **Use Environment-Specific Sections**: Support different environments with dedicated sections
9. **Follow the Role Necessity Principle**: Only use roles for data sources when multiple sources are present; avoid unnecessary roles for single data sources

## Structural Rules and Patterns

The YAML configuration follows specific structural rules that maintain consistency and clarity:

1. **Component Structure Rule**: Components can only contain:
   - A direct dataset reference (string format)
   - An array of dataset references (array format)
   - Named dataset references with roles (object format)
   - A data_source field with an optional parameters object

2. **Role Assignment Rule**: Roles are only used when there are multiple data sources that need to be distinguished by their function. A single data source should never have a role assigned.

3. **Parameter Encapsulation Rule**: All configuration parameters must be contained within a dedicated `parameters` object, which is a sibling to data source definitions.

4. **Structure Simplification Rule**: Use the simplest form possible for data source specification:
   - One data source → Simple string format
   - Multiple ordered data sources → Array format
   - Multiple data sources with specific roles → Object format

5. **Hierarchy Containment Rule**: All component-specific configuration must remain within its component definition block, while app-wide configurations (like environments) stay at the root level.

6. **Consistency Pattern**: Similar components should follow similar patterns for data source specification and parameter definition.

7. **Mutually Exclusive Rule**: Within a component, data sources and parameters are mutually exclusive concepts - parameters configure how a component behaves, while data sources specify what data the component uses.

These structural rules ensure that YAML configurations remain consistent, maintainable, and easy to understand for both developers and non-technical users.

## Future Directions

1. **Configuration Editor**: Develop a UI for non-technical users to modify configurations
2. **Schema Validation**: Implement JSON Schema validation for YAML configurations
3. **Template Gallery**: Create a library of example configurations for common use cases
4. **Configuration Inheritance**: Support inheritance to reduce duplication in related configurations