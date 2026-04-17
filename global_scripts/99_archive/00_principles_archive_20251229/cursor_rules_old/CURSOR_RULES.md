# Cursor Rules - Precision Marketing App

This document contains Cursor IDE specific rules and guidelines for this R Shiny precision marketing application.

## R Code Style Guidelines

### 1. Function Parameter Specification (MP081)
- Always use named parameters for function calls, especially UI components
- Example: `radioButtons(inputId = "platform", label = NULL, choices = list, selected = value)`

### 2. Data Access Patterns (R116)
- Always check for NULL and NA values before operations
- Use tryCatch for robust error handling in reactive contexts
- Example: `if (!is.null(x) && !is.na(x) && as.numeric(x) > 0)`

### 3. File Organization
- Follow the existing directory structure under `update_scripts/global_scripts/`
- Use numbered prefixes for scripts (e.g., `01_db/`, `02_db_utils/`)
- Store reusable functions in appropriate utility directories

### 4. Shiny Module Patterns
- Use consistent module structure with separate UI and Server functions
- Follow the existing naming conventions: `componentNameUI.R`, `componentNameServer.R`
- Always handle reactive values safely within modules

### 5. Database Connections
- Use the existing database utility functions in `02_db_utils/`
- Always use DBI-compliant patterns for database operations
- Follow the connection factory pattern established in the codebase

### 6. Global Scripts Integration
- Source global scripts using the established patterns in `03_config/`
- Use the `global_parameters.R` for application-wide settings
- Follow the dependency-based sourcing principle (R103)

## Project-Specific Context

### Database Structure
- Main database: `app_data.duckdb`
- Raw data: `raw_data.duckdb`
- Comment analysis results: stored in `scd_type2/` directory

### Key Principles Files Reference
- MP081: Explicit Parameter Specification
- R116: Enhanced Data Access (tbl2 pattern)
- MP068: Language as Index
- R115: dplyr Rules
- All principles are documented in `00_principles/` directory

### Component Architecture
- Macro-level analysis modules in `modules/macro/`
- Micro-level analysis modules in `modules/micro/`
- Reusable UI components in `components/`
- Union-based filtering system in `components/unions/`

## AI Assistant Guidelines

When working on this codebase:
1. Always reference existing principles files in `00_principles/`
2. Follow the established patterns in similar components
3. Use the existing utility functions rather than recreating functionality
4. Maintain consistency with the naming conventions used throughout the project
5. Test changes using the existing test patterns in `update_scripts/tests/` 