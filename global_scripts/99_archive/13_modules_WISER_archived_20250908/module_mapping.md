# Module to Script Mapping

This document provides a mapping between conceptual modules in the precision marketing system and their corresponding implementation scripts. This helps maintain a clear understanding of where specific functionality is implemented across the codebase.

## Script Naming Convention

Update scripts should follow the structured naming convention:

```
AABB_C_D_E_description.R
```

Where:
- **AA**: Bundle group identifier (00-99) - groups related scripts together
- **BB**: Serial number within the bundle (00-99) - defines execution order within a bundle
- **C**: Sub-script identifier (0-9) - allows decomposition of a script into multiple components
- **D_E**: Module reference (e.g., 0_1) - connects script to its corresponding module in documentation
- **description**: Brief descriptive text explaining the script's purpose

For example: `0000_0_0_1_connect_databases.R` (First script (00) in bundle 00, main script (0), related to module 0.1)

## How to Use This Document

1. When looking for specific functionality, find the relevant module
2. Check the associated script paths to locate the implementation
3. When updating scripts, update this mapping if necessary
4. When adding new modules, add them to this mapping

## Module Mappings

### Module 0: System Initialization and Configuration

| Module ID | Description | Current Implementation | Proposed Implementation |
|-----------|-------------|------------------------|-------------------------|
| 0_1 | Environment Setup | `/update_scripts/global_scripts/00_principles/000g_initialization_update_mode.R` | `/update_scripts/global_scripts/00_principles/sc_initialization_update_mode.R` |
| 0_2 | Configuration Management | `/update_scripts/global_scripts/03_config/global_parameters.R`<br>`/update_scripts/global_scripts/03_config/global_path_settings.R` | `/update_scripts/global_scripts/03_config/fn_global_parameters.R`<br>`/update_scripts/global_scripts/03_config/fn_global_path_settings.R` |
| 0_3 | Database Connection | `/update_scripts/global_scripts/02_db_utils/100g_dbConnect_from_list.R`<br>`/update_scripts/global_scripts/02_db_utils/103g_dbDisconnect_all.R` | `/update_scripts/global_scripts/02_db_utils/fn_dbConnect_from_list.R`<br>`/update_scripts/global_scripts/02_db_utils/fn_dbDisconnect_all.R` |

### Module 1: Customer Analysis

| Module ID | Description | Implementation Files |
|-----------|-------------|----------------------|
| 1.1 | Customer DNA | `/update_scripts/global_scripts/05_data_processing/common/DNA_Function_dplyr.R`<br>`/update_scripts/global_scripts/05_data_processing/common/DNA_Function_data.table.R` |
| 1.2 | RFM Analysis | *Functions within the DNA modules* |
| 1.3 | Customer Status (NES) | *Functions within the DNA modules* |
| 1.4 | Customer Lifetime Value | *Functions within the DNA modules* |

### Module 2: Data Import and Processing

| Module ID | Description | Implementation Files |
|-----------|-------------|----------------------|
| 2.1 | Amazon Sales Import | `/update_scripts/global_scripts/05_data_processing/import_amazon_sales.R` |
| 2.2 | Amazon Sales Processing | `/update_scripts/global_scripts/05_data_processing/amazon/205g_process_amazon_sales.R` |
| 2.3 | Amazon Review Processing | `/update_scripts/global_scripts/05_data_processing/amazon/203g_process_amazon_review.R` |
| 2.4 | Website Sales Import | `/update_scripts/global_scripts/05_data_processing/officialwebsite/300g_import_website_km_sales.R` |

### Module 3: Database Management

| Module ID | Description | Implementation Files |
|-----------|-------------|----------------------|
| 3.1 | Table Creation | `/update_scripts/global_scripts/01_db/105g_create_or_replace_amazon_sales_dta.R`<br>*Other table creation scripts in 01_db/* |
| 3.2 | Database Operations | `/update_scripts/global_scripts/02_db_utils/101g_dbCopyorReadTemp.R`<br>`/update_scripts/global_scripts/02_db_utils/102g_dbCopyTable.R`<br>`/update_scripts/global_scripts/02_db_utils/104g_dbOverwrite.R`<br>`/update_scripts/global_scripts/02_db_utils/105g_dbDeletedb.R` |
| 3.3 | SQL Utilities | *Scripts in 14_sql_utils/* |

### Module 4: Data Analysis and Modeling

| Module ID | Description | Implementation Files |
|-----------|-------------|----------------------|
| 4.1 | Design Matrix Generation | `/update_scripts/global_scripts/07_models/Design_matrix_Generation_Poisson.R`<br>`/update_scripts/global_scripts/07_models/Design_matrix_Generation_Poisson2.R` |
| 4.2 | Poisson Regression | `/update_scripts/global_scripts/07_models/Poisson_Regression.R` |
| 4.3 | Choice Modeling | `/update_scripts/global_scripts/07_models/choice_model_lik.R`<br>`/update_scripts/global_scripts/07_models/choice_model_optimization.R` |
| 4.4 | Price Optimization | `/update_scripts/global_scripts/07_models/Optimal Pricing.R`<br>`/update_scripts/global_scripts/07_models/Sort_Optimal_Pricing_Forluma.R` |

### Module 5: AI Integration

| Module ID | Description | Implementation Files |
|-----------|-------------|----------------------|
| 5.1 | AI Setup | `/update_scripts/global_scripts/08_ai/510g_setup_python.R` |
| 5.2 | Review Rating Analysis | `/update_scripts/global_scripts/08_ai/601g_ai_review_rating.R`<br>`/update_scripts/global_scripts/08_ai/603g_ai_review_ratings_estimate.R` |
| 5.3 | Result Decoding | `/update_scripts/global_scripts/08_ai/701g_decode_ai_review_ratings.R` |
| 5.4 | Python Integration | `/update_scripts/global_scripts/09_python_scripts/comment_rating.py`<br>`/update_scripts/global_scripts/09_python_scripts/gender_prediction.py` |

### Module 6: ShinyApp Components

| Module ID | Description | Implementation Files |
|-----------|-------------|----------------------|
| 6.1 | Data Source | `/update_scripts/global_scripts/10_rshinyapp_components/data/ui_data_source.R`<br>`/update_scripts/global_scripts/10_rshinyapp_components/data/server_data_source.R` |
| 6.2 | Macro Analysis | `/update_scripts/global_scripts/10_rshinyapp_components/macro/ui_macro_overview.R`<br>`/update_scripts/global_scripts/10_rshinyapp_components/macro/server_macro_overview.R` |
| 6.3 | Micro Customer Analysis | `/update_scripts/global_scripts/10_rshinyapp_components/micro/ui_micro_customer.R`<br>`/update_scripts/global_scripts/10_rshinyapp_components/micro/server_micro_customer.R` |
| 6.4 | Marketing Analysis | `/update_scripts/global_scripts/10_rshinyapp_components/marketing/ui_marketing_sales.R`<br>`/update_scripts/global_scripts/10_rshinyapp_components/marketing/server_marketing_sales.R`<br>`/update_scripts/global_scripts/10_rshinyapp_components/marketing/ui_marketing_campaign.R`<br>`/update_scripts/global_scripts/10_rshinyapp_components/marketing/server_marketing_campaign.R`<br>`/update_scripts/global_scripts/10_rshinyapp_components/marketing/ui_marketing_target.R`<br>`/update_scripts/global_scripts/10_rshinyapp_components/marketing/server_marketing_target.R` |

### Module 7: Utility Functions

| Module ID | Description | Implementation Files |
|-----------|-------------|----------------------|
| 7.1 | String Processing | `/update_scripts/global_scripts/04_utils/caesar_cipher.R`<br>`/update_scripts/global_scripts/04_utils/clean_column_names.R`<br>`/update_scripts/global_scripts/04_utils/replace_spaces.R` |
| 7.2 | Data Cleaning | `/update_scripts/global_scripts/04_utils/handle_na.R`<br>`/update_scripts/global_scripts/04_utils/remove_na_columns.R`<br>`/update_scripts/global_scripts/04_utils/remove_na_rows_in_columns.R`<br>`/update_scripts/global_scripts/04_utils/remove_na_strings.R` |
| 7.3 | Type Conversion | `/update_scripts/global_scripts/04_utils/string_to_numeric.R`<br>`/update_scripts/global_scripts/04_utils/replace_non_numeric.R` |
| 7.4 | Data Joining | `/update_scripts/global_scripts/04_utils/left_join_remove_duplicate.R`<br>`/update_scripts/global_scripts/04_utils/left_join_remove_duplicate2.R` |

## Project-Specific Implementations

Since each project may have customized implementations of these modules, you should check the following locations for project-specific variations:

1. `/local_scripts/` - For completely custom implementations specific to the project
2. Project's update_scripts directory - For modified versions of the global scripts
3. Configuration files that may adjust parameters for each module

## Maintenance Guidelines

1. **Adding new scripts**: Add them to the appropriate module in this mapping
2. **Renaming scripts**: Update the corresponding paths in this mapping
3. **Refactoring modules**: Update both the module descriptions and the implementation files
4. **Reviewing**: Periodically review this mapping to ensure it remains accurate

## Global Script Naming Convention

Global scripts should use descriptive names with prefixes that distinguish between function libraries, execution scripts, and Shiny modules:

```
[prefix]_[name].R
```

Where the prefix indicates the file type:
- `fn_` - Function libraries that contain reusable functions
- `sc_` - Scripts that execute processes or workflows
- `ui_` - Shiny UI module components
- `server_` - Shiny server module components

### Function Library Rules

Function libraries (`fn_` files) must follow the "one function per file" principle:

```
fn_[function_name].R  # Contains function_name() as its primary export
```

**Key principles:**
1. Each file should export exactly one primary function
2. The filename should match the primary exported function name
3. Helper functions can be included but should be internal (not exported)

For example, a file named `fn_dbConnect_from_list.R` should contain and export only the `dbConnect_from_list()` function. This ensures clear one-to-one mapping between files and their exported functions.

### Shiny Module Rules

Shiny modules should be split into UI and server files:

```
ui_[module_name].R      # Contains the UI component function
server_[module_name].R  # Contains the server component function
```

Each file should export a single function following Shiny module conventions.

### General Naming Rules

Follow these rules for all global scripts:
1. Use lowercase with underscores for word separation
2. Name should clearly describe the function's purpose
3. Replace the "g" suffix and numeric prefixes (like "100g_") with the appropriate prefix
4. Maintain the domain-based directory structure
5. For function libraries, the name after the prefix should match the exported function name

### Examples:

Current naming:
- `100g_dbConnect_from_list.R`
- `205g_process_amazon_sales.R`
- `300g_import_website_km_sales.R`

Proposed naming:
- Function libraries:
  - `fn_dbConnect_from_list.R` (contains `dbConnect_from_list()` function)
  - `fn_dbCopyTable.R` (contains `dbCopyTable()` function)
  - `fn_string_to_numeric.R` (contains `string_to_numeric()` function)

- Execution scripts:
  - `sc_process_amazon_sales.R`
  - `sc_import_website_sales.R` 
  - `sc_analyze_reviews.R`

This approach:
1. Clearly distinguishes between function libraries and execution scripts at a glance
2. Creates a clear one-to-one mapping between function files and their exported functions
3. Maintains organization within directories
4. Aligns with standard R package development practices
5. Improves code clarity and maintainability
6. Supports future transition to a package structure

## Script Naming Convention Implementation

The table below shows suggested update script names for each module following the new naming convention:

| Module ID | Suggested Update Script |
|-----------|------------------------|
| 0.1 | `0000_0_0_1_setup_environment.R` |
| 0.2 | `0100_0_0_2_configure_parameters.R` |
| 0.3 | `0200_0_0_3_connect_databases.R` |
| 1.1 | `1000_0_1_1_calculate_customer_dna.R` |
| 1.2 | `1100_0_1_2_analyze_rfm.R` |
| 1.3 | `1200_0_1_3_evaluate_customer_status.R` |
| 1.4 | `1300_0_1_4_calculate_customer_ltv.R` |
| 2.1 | `2000_0_2_1_import_amazon_sales.R` |
| 2.2 | `2100_0_2_2_process_amazon_sales.R` |
| 2.3 | `2200_0_2_3_process_amazon_reviews.R` |
| 2.4 | `2300_0_2_4_import_website_sales.R` |
| 3.1 | `3000_0_3_1_create_tables.R` |
| 3.2 | `3100_0_3_2_perform_db_operations.R` |
| 3.3 | `3200_0_3_3_execute_sql_utils.R` |
| 4.1 | `4000_0_4_1_generate_design_matrix.R` |
| 4.2 | `4100_0_4_2_run_poisson_models.R` |
| 4.3 | `4200_0_4_3_build_choice_models.R` |
| 4.4 | `4300_0_4_4_optimize_pricing.R` |
| 5.1 | `5000_0_5_1_setup_ai_environment.R` |
| 5.2 | `5100_0_5_2_analyze_review_ratings.R` |
| 5.3 | `5200_0_5_3_decode_ai_results.R` |
| 5.4 | `5300_0_5_4_run_python_integration.R` |
| 6.1 | `6000_0_6_1_configure_data_sources.R` |
| 6.2 | `6100_0_6_2_build_macro_analysis.R` |
| 6.3 | `6200_0_6_3_build_micro_analysis.R` |
| 6.4 | `6300_0_6_4_analyze_marketing.R` |
| 7.1 | `7000_0_7_1_process_strings.R` |
| 7.2 | `7100_0_7_2_clean_data.R` |
| 7.3 | `7200_0_7_3_convert_types.R` |
| 7.4 | `7300_0_7_4_join_data.R` |

The implementation of this naming convention provides:
1. Clear execution ordering through the bundle and serial number
2. Direct connection to module documentation
3. Support for breaking complex tasks into multiple related scripts
4. Improved self-documentation and maintainability
5. Consistent organization across all projects

## Version Information

Last updated: 2025-04-01 (Updated to include fn/sc prefixes)