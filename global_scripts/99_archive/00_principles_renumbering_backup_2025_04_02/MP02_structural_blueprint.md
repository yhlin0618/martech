---
id: "MP02"
title: "Structural Blueprint"
type: "meta-principle"
date_created: "2025-04-02"
date_modified: "2025-04-02"
author: "Claude"
derives_from:
  - "MP00": "Axiomatization System"
  - "MP01": "Primitive Terms and Definitions"
influences:
  - "P03": "Project Principles"
  - "P04": "Script Separation"
  - "P07": "App Construction Principles"
  - "R01": "Directory Structure Rules"
  - "R02": "File Naming Convention Rules"
  - "R03": "Principle Documentation"
---

# System Structural Blueprint

This document serves as the authoritative blueprint for the system's structure, defining the fundamental organization and architecture that all code must follow. It bridges conceptual principles with concrete implementation, providing both the logical foundations and physical manifestation of the system design.

## Purpose of this Blueprint

This document:
1. Provides a complete map of the system's organizational structure
2. Serves as a table of contents for navigating the codebase
3. Defines the structural rules that all implementation must adhere to
4. Establishes the architectural patterns that shape the entire system

## Architectural Foundations

### Three-Level Conceptual Framework

The system is organized according to a three-level hierarchy that provides a clear path from abstract reasoning to concrete implementation:

1. **Meta-Principles (WHY)** - Foundational concepts that justify our design decisions
2. **Principles (HOW)** - General guidelines that shape architectural patterns
3. **Rules (WHAT)** - Specific practices that implement principles in code

## Level 1: Meta-Principles (WHY)

These foundational philosophical concepts rarely change and represent the deepest reasoning behind our design decisions.

### Modularity
Systems should be broken into smaller, independent components with well-defined interfaces.

### Separation of Concerns
Different aspects of a problem should be handled by different components.

### Don't Repeat Yourself (DRY)
Each piece of knowledge should have a single, authoritative representation in the system.

### Documentation Centralization
All principle documents, guidelines, and architectural documentation must be placed in the 00_principles directory to ensure a single source of truth.

### Single Responsibility
Each component should have exactly one reason to change.

### Interface Cohesion
Functions should have a clear, focused purpose and expose a coherent interface.

### Abstraction
Implementation details should be hidden behind simpler interfaces.

### Consistency
Similar things should be done in similar ways.

## Level 2: Principles (HOW)

Principles are general guidelines derived from our meta-principles. They shape architectural decisions while allowing flexibility in implementation.

### Function vs. Implementation Separation
Separate reusable functions (global_scripts) from specific implementations (update_scripts).

### Clear Function Boundaries
Functions should have well-defined inputs, outputs, and purpose.

### One Function Per File
Each file should define and export exactly one primary function to ensure clarity and maintainability.

### Hierarchical Organization
Code should be organized into logical hierarchies that group related functionality.

### Component-Based Architecture
Break complex UI and server logic into modular components with clear interfaces.

### Explicit Dependencies
Dependencies between components should be explicitly declared and minimized.

### Standardized Patterns
Use consistent patterns for solving similar problems.

## Level 3: Rules (WHAT)

Specific, concrete practices that implement our principles in daily work.

### Physical Structure Map

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
    └── records/                  # Change records and documentation
```

### Structure and Naming Rules

These foundational rules have been extracted into separate rule documents:

1. **Directory Structure Rules (R01)**
   - Provides detailed guidelines for organizing directories and files
   - Specifies the hierarchical organization of the codebase
   - Defines special directory requirements and maintenance procedures
   - See [R01_directory_structure.md](R01_directory_structure.md) for complete details

2. **File Naming Convention Rules (R02)**
   - Establishes standardized naming patterns for all file types
   - Defines prefix requirements for different file categories
   - Specifies case conventions and descriptive naming practices
   - See [R02_file_naming_convention.md](R02_file_naming_convention.md) for complete details

3. **Principle Documentation Rules (R03)**
   - Defines YAML front matter requirements for principle documents
   - Specifies required sections and content organization
   - Establishes relationship documentation standards
   - See [R03_principle_documentation.md](R03_principle_documentation.md) for complete details

### Code Organization Rules

For code organization rules that were previously included here, refer to the following documents:

- Function and script organization principles are covered in [P04_script_separation.md](P04_script_separation.md)
- Shiny component organization is detailed in [P07_app_construction_principles.md](P07_app_construction_principles.md)
- File naming conventions are specified in [R02_file_naming_convention.md](R02_file_naming_convention.md)

The key rules include:
- Each file must define and export exactly one primary function
- Function filenames must match their primary exported function
- Shiny modules must be split into separate UI and server files
- Functions in global_scripts must not contain company-specific logic
- Update_scripts must call global functions instead of reimplementing logic
- All required packages must be loaded at the top of scripts
- No circular dependencies allowed between modules

## Documentation Requirements

All code must be thoroughly documented according to these specifications:

### Function Documentation Rules
- All functions in global_scripts must have roxygen2 documentation
- Documentation must include @param for each parameter
- Documentation must include @return describing the output
- Documentation must include @examples showing usage

### Structural Documentation Rules
- All principles must be documented in 00_principles
- All structural changes must be recorded in update_scripts/records
- Directory structure must be maintained as specified in this blueprint
- All deviations from this blueprint require explicit justification

### Principle Documentation Rules
- All principle documents must include YAML front matter with:
  - `id`: The principle identifier (e.g., "MP01")
  - `title`: A concise title
  - `type`: Classification as "meta-principle", "principle", or "rule"
  - `date_created`: Creation date
  - `date_modified`: Modification date (when applicable)
  - `author`: Author name
  - Relationship fields as appropriate:
    - `derives_from`: Principles this principle is based on
    - `influences`: Principles this principle affects
    - `implements`: For rules, which principles they implement
    - `extends`: Principles this principle refines or expands upon
    - `related_to`: For more general relationships
- All principles must begin with a concise introduction explaining their purpose
- All principles should include a "Core Concept" section
- All principles should document their relationships to other principles

## Navigation Guide

This blueprint serves as a map for finding specific functionality:

- **Database Operations**: 01_db, 02_db_utils
- **Utility Functions**: 04_utils
- **Data Processing**: 05_data_processing
- **UI Components**: 10_rshinyapp_components
- **Configuration Management**: 03_config, app_configs
- **Application Logic**: app.R, update_scripts

## Implementation Guidance

When implementing new features or modifying existing code:

1. **Locate the appropriate section** in this structural blueprint
2. **Follow the specific rules** for that section
3. **Maintain structural consistency** with existing code
4. **Preserve the hierarchical organization** defined in this document

When facing design decisions:
1. **Start with rules**: Is there a specific rule for this situation?
2. **Consult principles**: If no rule exists, which principles apply?
3. **Refer to meta-principles**: If principles conflict, which meta-principles take precedence?

This blueprint ensures that even as specific implementations evolve, the codebase maintains its architectural integrity and structural coherence.