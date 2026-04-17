# Natural SQL Language (NSQL)

This directory contains the complete specification and implementation components of the Natural SQL Language (NSQL). NSQL serves as the standard language for data transformation operations in the precision marketing system.

## Terminology Conventions

When working with NSQL and discussing code implementation, follow these important terminology distinctions:

### File Name vs. Object Name

Always distinguish between these two concepts:

- **File Name**: The name of a file containing code definitions (e.g., `fn_detect_advanced_metrics_availability.R`)
- **Object Name**: The name of the actual code element defined within that file (e.g., `detect_advanced_metrics_availability`)

### Implementation Pattern 

For R functions:
- Function file names MUST use the `fn_` prefix (e.g., `fn_transform_data.R`)
- Function object names defined inside those files MUST NOT use the `fn_` prefix (e.g., `transform_data`)

This distinction ensures clarity in documentation and prevents confusion when discussing code implementation details.

## Overview

The 16_NSQL_Language directory is the authoritative source for NSQL definition, implementation, and usage guidelines. MP24 in the 00_principles directory provides a high-level overview but refers to this directory for complete details.

## Directory Contents

- **dictionary.yaml**: NSQL dictionary containing terms, functions, and translations
- **grammar.ebnf**: Formal grammar for NSQL in Extended Backus-Naur Form
- **default_rules.md**: Default interpretation rules for NSQL statements
- **reference_resolution_rule.md**: Rules for resolving ambiguous references
- **natural_language_rule.md**: Rules for using accessible language in user questions
- **language_usage_principle.md**: Principles for context-based terminology selection
- **question_sets.yaml**: Standard questions for disambiguating NSQL statements
- **integrated_nsql_guide.md**: Guide to the integrated NSQL framework with all extensions
- **parsers/**: Implementation of NSQL parsers for different target languages
- **translators/**: Implementation of NSQL translators to SQL, dplyr, etc.
- **examples/**: Example NSQL statements and their translations
- **validators/**: Validation tools for NSQL statements
- **extensions/**: Domain-specific extensions to NSQL
  - **graph_representation/**: Graph theory extensions for component relationships
  - **documentation_syntax/**: LaTeX and Markdown-inspired documentation structure
  - **specialized/**: Specialized NSQL (SNSQL) extensions for specific use cases
    - **principle_based_revision.md**: SNSQL for revising components based on principles
- **records/**: Change records for NSQL language evolution

## Usage

NSQL can be used either directly through the defined parsers and translators or through the interactive disambiguation process defined in R22.

For translation:
```
nsql_translate("show sales by region", target="sql")
```

For validation:
```
nsql_validate("transform Sales to SummaryReport as sum(revenue) as total_revenue grouped by region")
```

## Directory Organization

The NSQL implementation is organized into:

- **meta_principles/**: Core meta-principles defining NSQL (including MP24)
- **rules/**: Implementation rules (R21, R22, R23, R59, R60, R61, R62, R63) for NSQL
- **examples/**: Example statements in various NSQL patterns
- **parsers/**, **translators/**, **validators/**: Implementation components
- Core definition files: grammar.ebnf, dictionary.yaml, etc.

## Related Meta-Principles and Rules

- **MP24**: Natural SQL Language - Defines the core language (also in meta_principles/)
- **MP25**: AI Communication Meta-Language - How to indicate NSQL in communications
- **MP26**: R Statistical Query Language - RSQL, which complements NSQL
- **MP27**: Integrated Natural SQL Language - Comprehensive integration of all NSQL components
- **MP28**: NSQL Set Theory Foundations - Mathematical foundations using set theory
- **MP41**: Configuration-Driven UI Composition - UI as a function of configuration
- **MP52**: Unidirectional Data Flow - Formalized in NSQL graph notations
- **MP56**: Connected Component Principle - Implemented through NSQL graph theory extension
- **MP59**: App Dynamics - Documented using NSQL state machine notation
- **R21**: NSQL Dictionary Rule - Dictionary structure and update process (also in rules/)
- **R22**: NSQL Interactive Update Rule - Process for analyzing and adding patterns (also in rules/)
- **R23**: Mathematical Precision - Ensures mathematical rigor in NSQL expressions
- **R59**: Component Effect Propagation Rule - How effects propagate through component hierarchies
- **R60**: UI Component Effect Propagation - Specific rules for UI component effect cascades
- **R61**: NSQL Extensionality Principle - Entities are determined by their elements or behavior
- **R62**: NSQL Similarity Principle - Processes with similar outputs for same inputs are similar
- **R63**: Index Variability Theory - Formalization of how values vary across dimensions
- **P079**: State Management - Formalized using NSQL reactive patterns
- **P090**: Documentation Standards - Implemented through NSQL documentation syntax

## Implementation Status

This is the active, authoritative implementation of the NSQL specification. The MP24 document in 00_principles provides a high-level overview but refers to this directory for complete details.