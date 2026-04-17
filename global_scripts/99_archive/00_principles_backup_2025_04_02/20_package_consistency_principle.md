# Package Consistency Principle

This document establishes the "Package Consistency Principle" as a meta-principle that takes precedence over our standard naming conventions when working with external packages.

## Core Concept

When integrating with external packages or ecosystems, maintaining consistency with their established conventions takes precedence over our internal naming standards. This reduces cognitive load, improves readability, and facilitates easier integration with those ecosystems.

## Principle Hierarchy

The Package Consistency Principle sits at a higher level in our principle hierarchy:

1. **Package Consistency Principle** (highest)
2. Mode Hierarchy Principle
3. Standard Naming Conventions (snake_case)
4. Other style and organization principles

## Key Applications

### 1. Shiny Module Naming

Shiny modules conventionally use camelCase with UI/Server suffixes:

```r
# CORRECT: Following Shiny ecosystem conventions
moduleNameUI <- function(id) { ... }
moduleNameServer <- function(id, ...) { ... }

# Examples from our codebase:
microCustomerUI <- function(id) { ... }
microCustomerServer <- function(id, data_source = NULL) { ... }
```

Even though our file names use snake_case (`ui_micro_customer.R`), the function names follow Shiny's convention.

### 2. Database Interface Functions

Functions that wrap DBI functionality maintain DBI's naming conventions:

```r
# CORRECT: Following DBI ecosystem conventions
dbConnect <- function(...) { ... }
dbGetQuery <- function(conn, query) { ... }

# Examples from our 02_db_utils:
dbFetchAll <- function(query, conn = NULL) { ... }
```

### 3. Other Package Integrations

The same principle applies to other package integrations:

| Package | Naming Convention | Our Implementation |
|---------|-------------------|-------------------|
| ggplot2 | snake_case and dots (`geom_point()`) | Use `geom_*` naming |
| dplyr | snake_case verbs | Maintain verb-first style |
| data.table | camelCase with dots (`data[, .N, by=group]`) | Use data.table syntax in data.table contexts |

## Implementation Guidelines

### 1. Clear Package Context

When implementing functions that integrate with external packages:

- Clearly document which package's conventions you're following
- Use consistent prefixes or namespaces where appropriate
- Include the package in Imports or Depends

### 2. Interface Boundaries

- Maintain package consistency at the interface boundary
- Internal implementations can follow our standard conventions
- Consider wrapper functions if conventions conflict significantly

### 3. Documentation

- Document any deviations from our standard naming conventions
- Explain which package's conventions are being followed
- Provide examples of the correct usage pattern

## Examples of Correct Implementation

### Shiny Module Implementation

```r
#' Micro Customer UI Component
#'
#' This follows Shiny module conventions with camelCase naming.
#' The file name follows our standard snake_case: ui_micro_customer.R
#' 
#' @param id The module ID
#' @return A UI component
#' @export
microCustomerUI <- function(id) {
  ns <- NS(id)
  # Implementation
}
```

### Database Function Implementation

```r
#' Execute Query with Error Handling
#'
#' This follows DBI naming conventions with dbPrefix.
#' 
#' @param query SQL query string
#' @param conn Database connection
#' @return Query results
#' @export
dbSafeExecute <- function(query, conn = default_connection) {
  # Implementation
}
```

## Conclusion

The Package Consistency Principle helps us balance internal consistency with the practical reality of working with external packages. By prioritizing consistency with established ecosystems at interface boundaries, we create code that is more intuitive and requires less context-switching for developers familiar with those ecosystems.

When in doubt, ask:
1. Is this function primarily interacting with an external package's API?
2. Does that package have strong naming conventions?
3. Would following our internal conventions create confusion?

If the answers are "yes," follow the external package's conventions.