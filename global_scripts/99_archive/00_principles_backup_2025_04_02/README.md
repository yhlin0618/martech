# Precision Marketing Principles

This directory contains the fundamental principles and guidelines that govern the precision marketing framework. These principles establish consistent patterns, standards, and best practices across the project.

## About Principles

Principles are conceptual, reusable guidelines that apply across the project. They are distinct from instances (specific implementations) as defined in the Instance vs. Principle Meta-Principle (22_instance_vs_principle.md).

All principle documents follow the Documentation Organization Meta-Principle (28_documentation_organization_meta_principle.md), using a flat structure with numbered prefixes and topic indicators.

## Principles by Topic

### Axiomatic Foundation

- [00_axiomatization_system_meta_principle.md](00_axiomatization_system_meta_principle.md) - Meta-meta-principle establishing the formal axiomatic system
- [01_primitive_terms_and_definitions.md](01_primitive_terms_and_definitions.md) - Fundamental vocabulary and primitive terms
- [02_structural_blueprint.md](02_structural_blueprint.md) - Authoritative blueprint of system structure

### Core Organization

- [03_project_principles.md](03_project_principles.md) - Core project guidelines (formerly 02)
- [04_script_separation_principles.md](04_script_separation_principles.md) - Guidelines for script separation (formerly 03)
- [22_instance_vs_principle.md](22_instance_vs_principle.md) - Meta-principle for separating instances from principles
- [28_documentation_organization_meta_principle.md](28_documentation_organization_meta_principle.md) - Documentation organization guidelines

### Data Management

- [04_data_integrity_principles.md](04_data_integrity_principles.md) - Data integrity guidelines
- [23_data_source_hierarchy.md](23_data_source_hierarchy.md) - Hierarchy and access patterns for data sources
- [29_terminology_axiomatization.md](29_terminology_axiomatization.md) - Formal definitions of key terminology

### App Development

- [07_app_principles.md](07_app_principles.md) - Core app construction principles
- [08_interactive_filtering_principles.md](08_interactive_filtering_principles.md) - Guidelines for interactive filters
- [09_data_visualization_principles.md](09_data_visualization_principles.md) - Data visualization guidelines
- [10_responsive_design_principles.md](10_responsive_design_principles.md) - Responsive design principles
- [16_bottom_up_construction_guide.md](16_bottom_up_construction_guide.md) - Bottom-up app construction approach
- [17_app_construction_function.md](17_app_construction_function.md) - App construction function guidelines
- [24_deployment_patterns.md](24_deployment_patterns.md) - Application deployment patterns
- [27_app_yaml_configuration.md](27_app_yaml_configuration.md) - YAML configuration guidelines

### Environment Management

- [15_working_directory_guide.md](15_working_directory_guide.md) - Working directory guidelines
- [18_operating_modes.md](18_operating_modes.md) - Operating modes (APP, UPDATE, GLOBAL)
- [19_mode_hierarchy_principle.md](19_mode_hierarchy_principle.md) - Hierarchy of operating modes
- [25_authentic_context_testing.md](25_authentic_context_testing.md) - Testing in authentic contexts
- [26_platform_neutral_code.md](26_platform_neutral_code.md) - Cross-platform_id guidelines

### Development Practices

- [05_debug_principles.md](05_debug_principles.md) - Debugging guidelines
- [06_function_reference.md](06_function_reference.md) - Function reference principles
- [11_roxygen2_guide.md](11_roxygen2_guide.md) - Roxygen documentation standards
- [12_roxygen_document_generation.md](12_roxygen_document_generation.md) - Documentation generation
- [13_package_creation_guide.md](13_package_creation_guide.md) - Package creation guidelines
- [14_claude_interaction_principles.md](14_claude_interaction_principles.md) - AI assistant interaction guidelines
- [20_package_consistency_principle.md](20_package_consistency_principle.md) - Package naming consistency
- [21_referential_integrity_principle.md](21_referential_integrity_principle.md) - Referential integrity in code

## Initialization Scripts

The directory also contains initialization scripts that set up the environment for different operating modes:

- `sc_initialization_app_mode.R` - Initializes APP_MODE environment
- `sc_initialization_update_mode.R` - Initializes UPDATE_MODE environment
- `sc_initialization_global_mode.R` - Initializes GLOBAL_MODE environment
- `sc_deinitialization_update_mode.R` - Cleans up after UPDATE_MODE
- `sc_generate_function_docs.R` - Generates function documentation

## Using Principles

When implementing or modifying code:

1. Review relevant principles first
2. Apply guideline consistently across related files
3. Reference specific principles in code comments when implementing them
4. If conflicts arise between principles, document the decision and rationale

## Adding New Principles

When adding new principles:

1. Use the next available number in the sequence
2. Include a topic indicator in the filename (e.g., `app_`, `data_`)
3. Follow the established document format with clear sections
4. Reference related principles
5. Update this README.md to include the new principle in the appropriate topic section