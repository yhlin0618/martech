---
id: "R10"
title: "Database Table Naming and Creation Rule [ARCHIVED]"
type: "archived_rule"
date_created: "2025-04-02"
date_archived: "2025-04-04"
author: "Claude"
archived_reason: "Functionality split between R23 (Object Naming Convention) and R31 (Data Frame Creation Strategy)"
implements:
  - "P02": "Data Integrity"
  - "P11": "Similar Functionality Management Principle"
derives_from:
  - "MP06": "Data Source Hierarchy"
  - "MP18": "Don't Repeat Yourself Principle"
related_to:
  - "MP16": "Modularity Principle"
  - "R04": "App YAML Configuration"
  - "R23": "Object Naming Convention"
  - "R31": "Data Frame Creation Strategy"
---

# Database Table Naming and Creation Rule [ARCHIVED]

This rule has been archived. Its functionality has been split between:

1. **R23 (Object Naming Convention)**: Handles naming conventions for all objects, including database tables
2. **R31 (Data Frame Creation Strategy)**: Implements the Strategy Pattern for data frame creation and storage

Please refer to these rules for current guidance.

For historical reference, the original rule content is preserved below.

---

# Database Table Naming and Creation Rule

This rule establishes that data tables connecting to app_data.duckdb must maintain consistent naming between the data source reference and the physical table name, and specifies the Strategy Pattern for implementing table creation functions.

## Core Requirement

Data tables referenced in application code must have the same name as their corresponding physical tables in the app_data.duckdb database, ensuring direct traceability and eliminating the need for name mapping.

[Original content follows...]