# Precision Marketing Principles

This directory contains the fundamental principles and guidelines that govern the precision marketing framework. These principles establish consistent patterns, standards, and best practices across the project.

## About Principles

Principles are conceptual, reusable guidelines that apply across the project. They are distinct from instances (specific implementations) as defined in the Instance vs. Principle Meta-Principle (MP22_instance_vs_principle.md).

## Principle Coding System

The principles follow a formal coding system that categorizes them into three types:

1. **Meta-Principles (MP)**: Principles about principles that govern how principles are structured, organized, and related
2. **Principles (P)**: Core principles that provide guidance for implementation
3. **Rules (R)**: Specific implementation guidelines that derive from principles

This coding system is reflected in both the filenames and the YAML front matter within each file:

```yaml
---
id: "MP01"             # Principle identifier
title: "Short Title"   # Concise title
type: "meta-principle" # Classification
date_created: "2025-04-02"
author: "Claude"
derives_from:          # What this principle is based on
  - "MP00": "Axiomatization System"
influences:            # What this principle affects
  - "P02": "Structural Blueprint"
---
```

## Recent Updates

**2025-04-02**: 
- Implemented the MP/P/R principle coding system across all principles
- Renamed all principle files to follow the MP/P/R naming convention
- Added YAML front matter to document relationships between principles
- Established a formal axiomatic system as defined in MP00_axiomatization_system.md
- Reclassified P27 (YAML Configuration) to R27 as it defines specific implementation rules
- Reclassified R16 (Bottom-Up Construction) to P16 (App Bottom-Up Construction) as it defines a broader methodology rather than specific implementation rules
- Added "app_" prefix to P16 to indicate it's specific to app construction, following naming convention recommendations
- Extracted directory structure rules from MP02 into R01_directory_structure.md
- Extracted file naming convention rules from MP02 into R02_file_naming_convention.md
- Extracted principle documentation rules from MP02 into R03_principle_documentation.md
- Updated MP02 to reference these new rule documents instead of containing the rules directly
- Created P08_naming_principles.md to document naming guidelines and numerical sequence management
- Created P06_debug_principles.md to document systematic debugging and troubleshooting principles
- Created P09_data_visualization.md to document data visualization standards and best practices
- Identified and documented missing principle files in 2025-04-02_missing_principles_documentation.md
- Original versions of the files are archived in 99_archive/00_principles_backup_2025_04_02
- Detailed documentation of this reorganization is available in update_scripts/records/2025-04-02_*.md

## Three-Level Conceptual Framework

The MP/P/R coding system represents a three-level conceptual framework for organizing our guidelines:

### 1. Meta-Principles (MP)
- **Purpose**: Govern how principles themselves are structured and related
- **Nature**: Abstract, conceptual, foundational
- **Scope**: System-wide architecture and organizational concepts
- **Examples**: Axiomatization system, primitive terms, structural blueprint
- **Identification**: Prefix "MP" followed by number (e.g., MP01)

### 2. Principles (P)
- **Purpose**: Provide core guidance for implementation
- **Nature**: Conceptual but practical, actionable guidelines
- **Scope**: Broad implementation patterns and approaches
- **Examples**: Project principles, script separation, data integrity
- **Identification**: Prefix "P" followed by number (e.g., P03) 

### 3. Rules (R)
- **Purpose**: Define specific implementation details
- **Nature**: Concrete, specific, directly applicable
- **Scope**: Narrow implementation techniques and specific patterns
- **Examples**: Bottom-up construction guide, roxygen documentation, YAML configuration
- **Identification**: Prefix "R" followed by number (e.g., R16)

This three-level framework allows principles to be organized hierarchically, with Meta-Principles establishing the foundation, Principles providing general guidance, and Rules offering specific implementation details.

## Principles by Category

### Meta-Principles (MP)

- [MP00_axiomatization_system.md](MP00_axiomatization_system.md) - Meta-meta-principle establishing the formal axiomatic system
- [MP01_primitive_terms_and_definitions.md](MP01_primitive_terms_and_definitions.md) - Fundamental vocabulary and primitive terms
- [MP02_structural_blueprint.md](MP02_structural_blueprint.md) - Authoritative blueprint of system structure
- [MP18_operating_modes.md](MP18_operating_modes.md) - Operating modes for the system
- [MP19_mode_hierarchy.md](MP19_mode_hierarchy.md) - Hierarchy of operating modes
- [MP20_package_consistency.md](MP20_package_consistency.md) - Consistency with package conventions
- [MP21_referential_integrity.md](MP21_referential_integrity.md) - Integrity of references between components
- [MP22_instance_vs_principle.md](MP22_instance_vs_principle.md) - Distinction between instances and principles
- [MP23_data_source_hierarchy.md](MP23_data_source_hierarchy.md) - Hierarchy of data sources
- [MP28_documentation_organization.md](MP28_documentation_organization.md) - Documentation organization guidelines
- [MP29_terminology_axiomatization.md](MP29_terminology_axiomatization.md) - Formal definitions of key terminology

### Principles (P)

- [P03_project_principles.md](P03_project_principles.md) - Core project principles
- [P04_script_separation.md](P04_script_separation.md) - Separation of script responsibilities
- [P05_data_integrity.md](P05_data_integrity.md) - Data integrity guidelines
- [P06_debug_principles.md](P06_debug_principles.md) - Debugging guidelines
- [P07_app_principles.md](P07_app_principles.md) - Core app construction principles
- [P08_naming_principles.md](P08_naming_principles.md) - Naming guidelines and sequence management
- [P09_data_visualization.md](P09_data_visualization.md) - Data visualization guidelines
- [P10_responsive_design.md](P10_responsive_design.md) - Responsive design principles
- [P14_claude_interaction.md](P14_claude_interaction.md) - Claude interaction principles
- [P15_working_directory.md](P15_working_directory.md) - Working directory guidelines
- [P16_app_bottom_up_construction.md](P16_app_bottom_up_construction.md) - App bottom-up construction methodology
- [P17_app_construction_function.md](P17_app_construction_function.md) - App construction function
- [P24_deployment_patterns.md](P24_deployment_patterns.md) - Deployment patterns
- [P25_authentic_context_testing.md](P25_authentic_context_testing.md) - Testing in authentic contexts

### Rules (R)

- [R01_directory_structure.md](R01_directory_structure.md) - Directory structure organization rules
- [R02_file_naming_convention.md](R02_file_naming_convention.md) - File naming convention rules
- [R03_principle_documentation.md](R03_principle_documentation.md) - Principle documentation requirements
- [R08_interactive_filtering.md](R08_interactive_filtering.md) - Interactive filtering implementation
- [R11_roxygen2_guide.md](R11_roxygen2_guide.md) - Roxygen2 documentation guide
- [R12_roxygen_document_generation.md](R12_roxygen_document_generation.md) - Roxygen document generation
- [R13_package_creation_guide.md](R13_package_creation_guide.md) - Package creation guide
- [R26_platform_neutral_code.md](R26_platform_neutral_code.md) - Cross-platform_id guidelines
- [R27_app_yaml_configuration.md](R27_app_yaml_configuration.md) - YAML configuration implementation

## Using Principles

When implementing or modifying code:

1. Review relevant principles first
2. Apply guideline consistently across related files
3. Reference specific principles in code comments when implementing them (using the MP/P/R code)
4. If conflicts arise between principles, document the decision and rationale

## Adding New Principles

When adding new principles:

1. Determine the appropriate classification (MP, P, or R) based on the Three-Level Conceptual Framework
2. Assign the next available number for that classification
3. Add YAML front matter with id, type, and relationships
4. Follow the established document format with clear sections
5. Reference related principles
6. Update this README.md to include the new principle in the appropriate category