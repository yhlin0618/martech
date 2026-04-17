# App Construction Resources Guide

This document serves as a reference index for all app construction resources across the project. When working on app development, refer to these resources in the specified directories to ensure adherence to project principles.

## Overview

App construction information is distributed across three key directories:

1. **00_principles**: Authoritative principles and guidelines
2. **10_rshinyapp_components**: Code examples and templates
3. **13_claude_prompts**: Claude AI instructions for app building

## 1. Principle Documents (00_principles)

The authoritative source for all app construction principles:

| Document | Description | Key Topics |
|----------|-------------|------------|
| [07_app_principles.md](07_app_principles.md) | Core app construction rules | Content Treatment, Scroll-Free UI, Brand Protection, Component Reuse, Bottom-Up Construction |
| [16_bottom_up_construction_guide.md](16_bottom_up_construction_guide.md) | Incremental development approach | Data foundation, Component building, Integration techniques |
| [17_app_construction_function.md](17_app_construction_function.md) | Declarative app creation | Configuration-driven assembly, Code-free development, Standardized integration |
| [18_operating_modes.md](18_operating_modes.md) | Environment-specific behavior | App Mode, Update Mode, Global Mode, Environment detection |
| [15_working_directory_guide.md](15_working_directory_guide.md) | Working directory conventions | Project structure, Path patterns, Initialization |
| [08_interactive_filtering_principles.md](08_interactive_filtering_principles.md) | Filter implementation guidelines | Direct interaction, Visual feedback, Progressive disclosure |
| [09_data_visualization_principles.md](09_data_visualization_principles.md) | Visualization best practices | Chart selection, Context provision, Design consistency |
| [10_responsive_design_principles.md](10_responsive_design_principles.md) | Multi-device considerations | Adaptive layouts, Touch interactions, Content prioritization |
| [03_script_separation_principles.md](03_script_separation_principles.md) | Code organization | Component naming conventions, File structure patterns |

## 2. Code Examples (10_rshinyapp_components)

Implementation examples and templates:

| Directory/File | Description | Purpose |
|----------------|-------------|---------|
| [examples/README.md](../10_rshinyapp_components/examples/README.md) | Component examples overview | Documentation of available examples |
| [examples/app_minimal_template.R](../10_rshinyapp_components/examples/app_minimal_template.R) | Minimal app template | Starting point demonstrating Bottom-Up principle |
| [examples/app_complete_template.R](../10_rshinyapp_components/examples/app_complete_template.R) | Complete app template | Full app structure with all sections |
| [examples/ui_micro_customer_profile.R](../10_rshinyapp_components/examples/ui_micro_customer_profile.R) | UI component example | Example of UI component implementation |
| [examples/server_micro_customer_profile.R](../10_rshinyapp_components/examples/server_micro_customer_profile.R) | Server component example | Example of server component implementation |
| [macro/ui_macro_overview.R](../10_rshinyapp_components/macro/ui_macro_overview.R) | Macro overview UI | Implementation of macro overview panel |
| [macro/server_macro_overview.R](../10_rshinyapp_components/macro/server_macro_overview.R) | Macro overview server | Server logic for macro overview panel |
| [macro/fn_create_kpi_box.R](../10_rshinyapp_components/macro/fn_create_kpi_box.R) | KPI box helper function | Example of component helper function |

## 3. AI Instructions (13_claude_prompts)

Claude-specific documentation for app implementation:

| Directory/File | Description | Purpose |
|----------------|-------------|---------|
| [WISER/customer_dna_shinyapp.md](../13_claude_prompts/WISER/customer_dna_shinyapp.md) | Customer DNA app guide | Specific instructions for implementing the Customer DNA app |
| [WISER/module_mapping.md](../13_claude_prompts/WISER/module_mapping.md) | Module mapping | Connections between conceptual modules and implementation files |
| [global/module0_procedure.md](../13_claude_prompts/global/module0_procedure.md) | Global procedures | Standard procedures for implementation across all apps |

## When to Use Each Resource

### Use 00_principles when:
- Establishing new app construction principles
- Modifying existing architecture guidelines
- Creating new rules for component organization
- Need authoritative reference for decision-making

### Use 10_rshinyapp_components when:
- Implementing specific components
- Need example code for reference
- Testing practical applications of principles
- Creating new templates or patterns

### Use 13_claude_prompts when:
- Providing instructions for Claude AI
- Documenting app-specific implementation details
- Creating examples specific to a particular project
- Developing guidelines for AI-assisted development

## Recommended Workflow

When implementing a new app:

1. **Start with principles**:
   - Review [07_app_principles.md](07_app_principles.md) for core rules
   - Study [16_bottom_up_construction_guide.md](16_bottom_up_construction_guide.md) for development approach

2. **Follow code examples**:
   - Use [app_minimal_template.R](../10_rshinyapp_components/examples/app_minimal_template.R) as a starting point
   - Refer to component examples as needed

3. **Apply project-specific guidance**:
   - Refer to relevant files in 13_claude_prompts for project-specific details
   - Follow module mapping for consistency with existing code

4. **Implement incrementally**:
   - Start with data components
   - Add UI and server components one by one
   - Test thoroughly as you go

## Maintaining This Guide

This reference guide should be updated whenever:
- New principle documents related to app construction are added
- New example components are created
- New Claude prompts for app development are established

Last updated: 2025-04-01