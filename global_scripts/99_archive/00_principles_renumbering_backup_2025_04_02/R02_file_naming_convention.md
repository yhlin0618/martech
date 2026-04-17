---
id: "R02"
title: "File Naming Convention"
type: "rule"
date_created: "2025-04-02"
author: "Claude"
implements:
  - "MP02": "Structural Blueprint"
related_to:
  - "R01": "Directory Structure"
  - "R03": "Principle Documentation"
---

# File Naming Convention Rules

This rule establishes a standardized system for naming files across the precision marketing codebase, ensuring consistency, clarity, and ease of navigation.

## Core Concept

All files must follow a consistent naming pattern that clearly indicates the file's purpose, type, and content. Names should be descriptive, follow consistent prefixing conventions, and use standardized case formatting.

## General Naming Rules

1. **Snake Case Requirement**
   - All filenames must use snake_case (lowercase with underscores)
   - Words are separated by underscores
   - No spaces, hyphens, or camelCase allowed in filenames

2. **Descriptive Names**
   - Names must clearly describe the file's purpose or content
   - Names should be concise but complete enough to be self-explanatory
   - Avoid abbreviations unless they are widely understood (e.g., db for database)

3. **File Extensions**
   - R code files must use the `.R` extension
   - Documentation files must use the `.md` extension
   - Configuration files must use `.yml` or `.yaml` extension

## Function Library Naming

1. **Function File Prefix**
   - All function library files must use the `fn_` prefix
   - Example: `fn_dbConnect_from_list.R`

2. **Function Purpose Indicators**
   - Query functions must start with `fn_query_`
   - Database structure functions must start with `fn_create_or_replace_`
   - Transformation functions should include `_transform_` in their name
   - Analysis functions should include `_analyze_` in their name

3. **Function Naming Pattern**
   ```
   fn_<action>_<subject>[_<qualifiers>].R
   ```
   
   Examples:
   - `fn_query_customer_data.R`
   - `fn_transform_sales_data_to_monthly.R`
   - `fn_create_or_replace_customer_table.R`

## Execution Script Naming

1. **Script File Prefix**
   - All execution scripts must use the `sc_` prefix
   - Example: `sc_update_customer_data.R`

2. **Script Naming Pattern**
   ```
   sc_<action>_<subject>[_<qualifiers>].R
   ```
   
   Examples:
   - `sc_update_all_tables.R`
   - `sc_download_latest_sales_data.R`
   - `sc_generate_monthly_report.R`

## Shiny Component Naming

1. **UI Component Prefix**
   - All Shiny UI module files must use the `ui_` prefix
   - Example: `ui_customer_dashboard.R`

2. **Server Component Prefix**
   - All Shiny server module files must use the `server_` prefix
   - Example: `server_customer_dashboard.R`

3. **Default Values Prefix**
   - Default values for UI components must use the `defaults_` prefix
   - Example: `defaults_customer_dashboard.R`

4. **Component Section Indicators**
   - Components must include their section in the name
   - Format: `<prefix>_<section>_<component>[_<qualifier>].R`
   
   Examples:
   - `ui_macro_performance_chart.R`
   - `server_micro_customer_profile.R`
   - `defaults_target_demographics.R`

## Principle Document Naming

1. **Classification Prefix**
   - Meta-Principles must use the `MP` prefix followed by a number
   - Principles must use the `P` prefix followed by a number
   - Rules must use the `R` prefix followed by a number

2. **Principle Domain Indicators**
   - Domain-specific principles must include the domain prefix after the number
   - Example: `P16_app_bottom_up_construction.md` for app-specific principles

3. **Principle Naming Pattern**
   ```
   <type><number>_[<domain>_]<description>.md
   ```
   
   Examples:
   - `MP02_structural_blueprint.md`
   - `P05_data_integrity.md`
   - `R27_app_yaml_configuration.md`

## Parameter and Variable Naming

1. **Parameter Names**
   - Must be consistent across related functions
   - Must use snake_case (lowercase with underscores)
   - Must be descriptive of the parameter's purpose

2. **Variable Names**
   - Must use snake_case for consistency
   - Must be descriptive and clear
   - Must avoid single-letter names except in limited contexts (e.g., loop indices)

3. **Constants**
   - Must be in ALL_CAPS with underscores
   - Example: `MAX_RETRY_ATTEMPTS`

## Implementation Examples

### Example 1: Function Library Files

```
# Database connection function
fn_dbConnect_from_list.R

# Query function for customer data
fn_query_customer_data.R

# Function to create database tables
fn_create_or_replace_customer_table.R
```

### Example 2: Shiny Component Files

```
# UI module for the customer profile in the micro section
ui_micro_customer_profile.R

# Server logic for the customer profile
server_micro_customer_profile.R

# Default values for the customer profile
defaults_micro_customer_profile.R
```

### Example 3: Principle Documents

```
# Meta-principle for structural blueprint
MP02_structural_blueprint.md

# Principle for data integrity
P05_data_integrity.md

# Rule for app-specific YAML configuration
R27_app_yaml_configuration.md
```

## Refactoring Legacy Files

When encountering files that do not follow these conventions:

1. Create a record in `update_scripts/records/` documenting the renaming
2. Update all references to the file in other code
3. Rename the file according to these conventions
4. Test thoroughly to ensure the rename doesn't break functionality

## Relationship to Other Rules

This rule implements MP02 (Structural Blueprint) and works in conjunction with:
- R01 (Directory Structure): Ensures files are properly organized within directories
- R03 (Principle Documentation): Establishes how principles are documented within the file naming system

## Conclusion

Consistent file naming conventions are essential for maintaining a clean, navigable, and maintainable codebase. These rules ensure that all team members can quickly understand a file's purpose and content from its name alone, reducing cognitive load and improving development efficiency.