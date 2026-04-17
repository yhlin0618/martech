---
id: "R01"
title: "Directory Structure"
type: "rule"
date_created: "2025-04-02"
author: "Claude"
implements:
  - "MP02": "Structural Blueprint"
related_to:
  - "R02": "File Naming Convention"
  - "R03": "Principle Documentation"
---

# Directory Structure Rules

This rule establishes specific guidelines for organizing files and directories in the precision marketing codebase, ensuring consistent structure across the project.

## Core Concept

The codebase must follow a standardized directory structure that clearly indicates the purpose and loading order of different components, maintains proper separation of concerns, and facilitates navigation and maintenance.

## Directory Hierarchy

The system is organized into these primary directories:

```
precision_marketing_app/
├── app.R                         # Main application entry point
├── app_configs/                  # Application configuration files
├── app_data/                     # Application-specific data
│   ├── scd_type1/                # Static reference data
│   └── scd_type2/                # Semi-static reference data
├── data/                         # Application data files
│   └── processed/                # Processed data ready for use
├── rsconnect/                    # Deployment configuration
└── update_scripts/               # Implementation scripts
    ├── global_scripts/           # Reusable functions and principles
    │   ├── 00_principles/        # System principles and documentation
    │   ├── 01_db/                # Database creation functions
    │   ├── 02_db_utils/          # Database utility functions
    │   ├── 03_config/            # Configuration utilities
    │   ├── 04_utils/             # General utility functions
    │   ├── 05_data_processing/   # Data processing functions
    │   ├── 06_queries/           # Data query functions
    │   ├── 07_models/            # Statistical models
    │   ├── 08_ai/                # AI-related functions
    │   ├── 09_python_scripts/    # Python integration scripts
    │   ├── 10_rshinyapp_components/ # Shiny component definitions
    │   └── 11_rshinyapp_utils/   # Shiny utility functions
    ├── records/                  # Change records and documentation
    └── 99_archive/               # Archived files and versions
```

## Specific Rules

### Global Scripts Organization

1. **Numbered Directories**
   - Global script directories must use numeric prefixes (00_, 01_, etc.)
   - The number indicates the loading order and dependency hierarchy
   - Lower-numbered directories should not depend on higher-numbered ones

2. **Functional Grouping**
   - Each directory must contain functionally related scripts
   - Database utilities must be in 01_db or 02_db_utils
   - General utilities must be in 04_utils
   - Shiny components must be in 10_rshinyapp_components and 11_rshinyapp_utils

3. **Component Structure**
   - 10_rshinyapp_components must be organized by application section:
     ```
     10_rshinyapp_components/
     ├── common/             # Common components used across sections
     ├── data/               # Data source components
     ├── macro/              # Macro overview components
     ├── micro/              # Micro customer components
     └── target/             # Target profiling components
     ```

4. **Minimal Nesting**
   - Directory structure should remain as flat as possible
   - No more than 3 levels of nesting within global_scripts
   - Each directory should have a clear, singular purpose

### Special Directory Rules

1. **Principles Directory (00_principles)**
   - Must contain all system principles and documentation
   - Must have the lowest number (00) to indicate its foundational role
   - Must include a README.md explaining the principles organization

2. **Documentation Directories**
   - Records of changes must be in update_scripts/records/
   - Records must use the date-prefix naming convention: YYYY-MM-DD_description.md
   - Archives must be in update_scripts/99_archive/

3. **Data Directories**
   - All application-specific data must be in app_data/
   - Configuration files must be in app_configs/
   - Slowly changing dimension data must be organized by type:
     - Static reference data in app_data/scd_type1/
     - Semi-static reference data in app_data/scd_type2/

## Directory Creation Rules

1. When creating new directories:
   - Verify the directory doesn't already exist
   - Choose the appropriate location based on the content's purpose
   - Use the correct numeric prefix if in global_scripts
   - Document the directory's purpose in its README.md

2. New top-level directories in global_scripts:
   - Must be approved and documented in MP02 (Structural Blueprint)
   - Must follow the numeric prefix pattern
   - Must have a clear, distinct purpose not covered by existing directories

## Implementation Examples

### Example 1: Adding a New Utility

When adding a new utility function for data processing:

```
# Place in 04_utils if it's a general utility
update_scripts/global_scripts/04_utils/fn_process_data.R

# Place in 05_data_processing if it's specific to data processing
update_scripts/global_scripts/05_data_processing/fn_process_customer_data.R
```

### Example 2: Adding a New Shiny Component

When adding a new Shiny component for the micro customer section:

```
# UI component
update_scripts/global_scripts/10_rshinyapp_components/micro/ui_micro_customer_profile.R

# Server component
update_scripts/global_scripts/10_rshinyapp_components/micro/server_micro_customer_profile.R

# Default values
update_scripts/global_scripts/10_rshinyapp_components/micro/defaults_micro_customer_profile.R
```

## Maintenance Guidelines

1. Periodically review directory structure for:
   - Unused or deprecated directories
   - Directories that have grown too large and need subdivision
   - Inconsistencies with these rules

2. When reorganizing:
   - Document changes in update_scripts/records/
   - Update references in affected files
   - Maintain backward compatibility when possible

## Relationship to Other Rules

This rule implements MP02 (Structural Blueprint) and works in conjunction with:
- R02 (File Naming Convention): Ensures consistent file naming within directories
- R03 (Principle Documentation): Establishes how principles are documented within the directory structure

## Conclusion

Following these directory structure rules ensures a consistent, navigable, and maintainable codebase. The structure provides clear logical organization, facilitates discovery of functionality, and enforces proper separation of concerns throughout the project.