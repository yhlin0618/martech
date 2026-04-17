---
id: "P08"
title: "Naming Principles"
type: "principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "MP01": "Primitive Terms and Definitions"
  - "MP02": "Structural Blueprint"
influences:
  - "R02": "File Naming Convention"
  - "R03": "Principle Documentation"
related_to:
  - "P03": "Project Principles"
  - "P04": "Script Separation"
---

# Naming Principles

This document establishes fundamental principles for creating, assigning, and managing names throughout the precision marketing system, ensuring consistency, clarity, and maintainability across all naming practices.

## Core Concept

Proper naming is foundational to system comprehension and navigation. Names should be consistent, meaningful, and follow structured patterns that convey purpose, relationships, and hierarchies while avoiding ambiguity and unnecessary complexity.

## General Naming Principles

### 1. Clarity and Self-Documentation

Names should be self-explanatory and communicate their purpose clearly without requiring additional context:

- **Prefer Descriptive Over Cryptic**: Names should describe what something is or does
- **Avoid Abbreviations Unless Universal**: Only use abbreviations that are widely understood in the domain
- **Length Proportional to Scope**: Longer names for broader-scoped entities, shorter for limited scope

### 2. Consistency and Predictability

Names should follow consistent patterns that create predictable structures:

- **Consistent Prefixes**: Use consistent prefixes for similar types (fn_, ui_, etc.)
- **Consistent Word Order**: Place modifiers in consistent positions
- **Consistent Separators**: Use consistent word separators (snake_case, kebab-case, etc.)

### 3. Appropriate Specificity

Names should be specific enough to distinguish between similar items:

- **Qualified When Necessary**: Add qualifiers to distinguish between similar items
- **Domain-Specific Prefixes**: Include domain prefixes for specialized items
- **Avoid Generic Names**: Prefer specific names over generic ones like "utils" or "helper"

## Numerical Sequence Principles

### 1. Sequential Numbering

When using numerical identifiers in a classification system:

- **Sequential Assignment**: Numbers should be assigned sequentially to minimize gaps
- **Gap Awareness**: Track and document existing numbers to avoid unintentional gaps
- **Gap Filling**: When creating new items, fill existing gaps before assigning new numbers
- **Migration Strategy**: If reorganizing, consider renumbering to eliminate gaps

### 2. Gap Management

Gaps in numerical sequences create confusion and maintenance challenges:

- **Document All Gaps**: Maintain a record of intentional gaps and their reasons
- **Intentional Gaps**: Only create gaps for planned future additions in well-defined groupings
- **Regular Audits**: Periodically review and consolidate numbering to eliminate unintended gaps

## Implementation in the MP/P/R System

The current MP/P/R system shows several numbering gaps (e.g., MP03-MP17, P01-P02, etc.) that should be addressed:

### Current Gaps in Meta-Principles
- MP03-MP17: No documented meta-principles
- MP24-MP27: No documented meta-principles

### Current Gaps in Principles
- P01-P02: No documented principles
- P08: This document fills this gap
- P11-P13: No documented principles
- P18-P23: No documented principles

### Current Gaps in Rules
- R04-R07: No documented rules
- R09-R10: No documented rules
- R14-R25: No documented rules

### Improvement Plan

1. **Documentation**: Create a master tracking document listing all assigned numbers
2. **Consolidation**: When appropriate, consider renumbering to eliminate large gaps
3. **Assignment Strategy**: When creating new principles or rules:
   - First check for appropriate gaps to fill
   - Next assign sequential numbers
   - Document the assignment in the master tracking list

## Naming Anti-Patterns to Avoid

### 1. Inconsistent Capitalization
- Mixing camelCase, PascalCase, and snake_case
- Inconsistent acronym capitalization (JSON vs Json vs json)

### 2. Misleading Names
- Names that imply different functionality than provided
- Names that are too generic for their specific purpose

### 3. Redundant Information
- Repeating information from the container (e.g., Customer.customer_id)
- Redundant type information (e.g., customer_string, customer_int)

### 4. Cryptic Naming
- Single-letter variables outside of limited contexts like loop indices
- Undocumented abbreviations that aren't universally understood

## Examples

### Good Naming Examples

```
# Sequential principle numbers with semantic grouping
MP00_axiomatization_system.md
MP01_primitive_terms_and_definitions.md
MP02_structural_blueprint.md

# Function names with consistent prefixing
fn_query_customer_data()
fn_transform_sales_figures()
fn_create_or_replace_customer_table()

# UI components with section and purpose
ui_micro_customer_profile.R
ui_macro_performance_chart.R
```

### Poor Naming Examples

```
# Inconsistent patterns
getData.R vs. process_sales.R vs. CreateUserTable.R

# Non-sequential numbering with gaps
P01 -> P04 -> P09 -> P23

# Cryptic abbreviations
calc_ctr_for_prd()  # What is ctr? What is prd?
```

## Relationship to Other Principles

This principle influences and is implemented by:
- R02 (File Naming Convention): Implements these naming principles for files
- R03 (Principle Documentation): Specifies how principles themselves are named

This principle derives from:
- MP01 (Primitive Terms and Definitions): Provides the foundation for consistent terminology
- MP02 (Structural Blueprint): Establishes the need for structured naming

## Conclusion

Consistent, meaningful, and structured naming is essential for system comprehension, maintenance, and evolution. By adhering to these naming principles, we ensure that the system remains navigable and understandable as it grows and changes over time.