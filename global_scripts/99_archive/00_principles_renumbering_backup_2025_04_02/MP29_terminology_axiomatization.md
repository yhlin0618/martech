---
id: "MP29"
title: "Terminology Axiomatization"
type: "meta-principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "MP00": "Axiomatization System"
  - "MP01": "Primitive Terms and Definitions"
extends:
  - "P23": "Data Source Hierarchy"
influences:
  - "P27": "YAML Configuration"
---

# Terminology Axiomatization Principle

This principle establishes clear definitions for key terminology used throughout the precision marketing application to ensure consistent understanding and implementation.

## Core Concept

Precise terminology is fundamental to system design. By formally defining key terms and their relationships, we create an axiomatized system where all participants share a common understanding of core concepts, reducing ambiguity and implementation errors.

## Terminology Hierarchy

### 1. Data Origin Terms

- **Platform**: The origin system or channel from which raw data is collected (e.g., "Amazon", "Official Website"). Platforms are defined in `app_data/scd_type1/source.xlsx` and accessed via `source_dictionary` in brand-specific parameters. (Note: historically called "source" in the codebase)

- **Raw Data**: Unprocessed data collected directly from platforms, stored in the `raw_data/` directory with minimal modifications from its original form.

- **Raw Data Folder**: The directory (`../rawdata_WISER`) containing raw data organized by platform.

### 2. Data Processing Terms

- **Processed Data**: Data that has undergone transformation, cleaning, and integration, stored in `processed_data/` or similar directories.

- **Cleansed Data**: A subset of processed data that has specifically undergone data cleaning operations to remove errors, inconsistencies, and invalid values.

- **Intermediate Data**: Data in transitional states between raw and final processed forms, typically stored in `intermediate_data/`.

### 3. Data Access Terms

- **Data Source**: A named reference to a specific dataset used by application components. This is an abstract concept that represents accessible data regardless of physical storage location.

- **Data Source Specification**: In YAML configuration, the declaration of which data a component should use. Can follow multiple patterns as defined in the YAML Configuration Principle.

- **Data Table**: A structured collection of records (typically rows and columns) that can be queried, filtered, and manipulated as a unit.

- **View**: A virtual data table defined by a query, presenting data from one or more underlying tables or data sources.

### 4. Component Data Terms

- **Parameters**: Configuration values that control component behavior, distinct from data sources. Parameters do not contain records but rather settings like `show_kpi: true`.

- **Role**: In multi-source configurations, the functional purpose of a data source within a component (e.g., "primary", "history", "reference").

- **Data Role**: The specific relationship between a data source and a component (e.g., a "primary" data role might represent the main dataset for a component).

## Term Relationship Axioms

1. **Platform-Data Relationship**: A Platform generates Raw Data, which is transformed into Processed Data.

2. **Data Source-Component Relationship**: Components consume Data Sources, which represent accessible versions of Processed Data.

3. **Role-Component Relationship**: When a Component uses multiple Data Sources, each source has a specific Role that defines its purpose within the component.

4. **Parameter-Component Relationship**: Parameters configure Component behavior but do not provide record-level data.

## Implementation in YAML Configuration

The YAML Configuration principle establishes patterns that implement these terminology relationships:

```yaml
# Pattern 1: Simple String Format - Direct Data Source Reference
component_name: data_source_name

# Pattern 3: Object Format with Roles - Multiple Data Sources with Specific Roles
component_name:
  role1: data_source1
  role2: data_source2

# Pattern 4a: Single Data Source with Parameters
component_name:
  data_source: data_source_name  # The data source providing records
  parameters:                    # Configuration values (not record data)
    param1: value1
```

## Platform vs. Data Source Distinction

A critical distinction exists between "Platform" and "Data Source":

- **Platform**: The origin system where data was originally collected (e.g., Amazon, Official Website)
- **Data Source**: The processed, accessible data used by application components, typically after ETL processes

For example:
- A **Platform** might be "Amazon" (stored in `source.xlsx`, historically called "source")
- A **Data Source** might be "sales_by_customer_dta" (a processed table or file that contains data from one or more platforms)

## Usage Examples

```r
# Accessing Platform information (raw data origins)
# Note: The file is historically called "source.xlsx" but contains platform information
platform_info <- read_excel(file.path("app_data", "scd_type1", "source.xlsx"))

# Mapping Platform to readable names
# Note: Variables are historically named with "source" but represent platforms
platform_dictionary <- as.list(setNames(source_dtah$source, source_dtah[[paste0("source_", language)]]))

# Accessing a Data Source (processed data for component use)
data <- read_from_app_data("sales_by_customer_dta.rds")

# YAML configuration referencing a Data Source 
# components:
#   micro: sales_by_customer_dta  # 'sales_by_customer_dta' is a Data Source, not a Platform
```

## Best Practices

1. **Be Explicit**: Always use the precise term for the concept being referenced.

2. **Consistent Naming**: Use consistent naming patterns:
   - Platform names should be lowercase with no spaces (e.g., "amazon", "officialwebsite")
   - Data Source names should use snake_case and be descriptive of content (e.g., "sales_by_customer_dta")

3. **Documentation**: When introducing new terms, document them in relation to existing terminology.

4. **Cross-Reference**: When documenting a Data Source, reference which Platform(s) its data originated from.

5. **Avoid Overloading**: Don't use the same term to describe different concepts in different contexts.

6. **Legacy Awareness**: Be aware that historical code uses "source" to refer to what we now call "platform".

## Relationship to Other Principles

This principle formalizes terminology used across other principles:

1. **Data Source Hierarchy Principle** (23_data_source_hierarchy.md): Clarifies where different types of data sources exist in the system hierarchy.

2. **YAML Configuration Principle** (27_app_yaml_configuration.md): Establishes patterns for specifying data sources in configuration.

3. **App Principles** (07_app_principles.md): Uses standardized terminology for application components.

## Conclusion

By axiomatizing our terminology, we create a shared understanding of key concepts that reduces ambiguity, improves communication, and ensures consistent implementation throughout the system. This foundation enables precise discussions about system design and faster onboarding of new team members.