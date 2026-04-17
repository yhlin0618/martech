---
id: "MP22"
title: "Instance vs. Principle"
type: "meta-principle"
date_created: "2025-03-15"
author: "Claude"
derives_from:
  - "MP00": "Axiomatization System"
influences:
  - "MP28": "Documentation Organization"
  - "P02": "Structural Blueprint"
---

# Instance vs. Principle Meta-Principle

This document establishes the meta-principle that distinguishes between instances (specific artifacts) and principles (reusable guidelines) in our documentation and file organization.

## Core Concept

A clear separation should be maintained between **principles** (conceptual guidelines) and **instances** (specific implementations, reports, or artifacts). This separation guides both storage location and version control decisions.

## Definitions

### Principles

Principles are:
- Abstract, conceptual guidelines that can be applied across multiple situations
- Reusable patterns, conventions, or standards
- Generally stable over time
- Applicable across different projects
- Foundational to the development process

**Examples**: Coding standards, naming conventions, architectural patterns, workflow processes

### Instances

Instances are:
- Specific implementations, reports, or artifacts
- Tied to a particular point in time
- Often project-specific or context-dependent
- May be generated as outputs of processes
- Subject to frequent change
- May contain data specific to a single execution

**Examples**: Analysis reports, execution logs, generated artifacts, one-time scripts

## Implementation Guidelines

### 1. Storage Location

The distinction between principles and instances should be reflected in where files are stored:

| Content Type | Storage Location | Version Control |
|--------------|-----------------|-----------------|
| Principles | `/update_scripts/global_scripts/00_principles/` | Git repository |
| Implementation Code | `/update_scripts/global_scripts/` (appropriate subdirectory) | Git repository |
| Instances/Reports | `/update_scripts/records/` | Dropbox only |
| Generated Artifacts | `/update_scripts/artifacts/` | Dropbox only |
| Execution Logs | `/update_scripts/logs/` | Dropbox only |
| Configuration Files | `/app_configs/` | Dropbox only |

### 2. Naming Conventions

File naming should clearly indicate whether something is a principle or an instance:

- **Principles**: `XX_principle_name.md` where XX is a sequence number
- **Records/Reports**: `YYYY-MM-DD_description.md` with date prefix, stored in `/update_scripts/records/`
- **Logs**: `YYYY-MM-DD_HHMMSS_process_name.log` with datetime prefix
- **Configuration**: `component_name.yaml` for app configurations, stored in `/app_configs/`

### 3. Documentation Style

The writing style should also reflect the distinction:

#### Principle Documentation Style
- Use present tense and imperative mood
- Focus on "what should be done" and "why"
- Provide conceptual examples
- Reference related principles
- Minimal references to specific implementation details

#### Instance Documentation Style
- Use past tense to describe what was done
- Include specific dates, times, and metrics
- Reference specific files and data sources
- Document specific findings and observations
- May include recommendations for specific cases

## Application Examples

### Example 1: Analysis of Null References

- **Principle**: `21_referential_integrity_principle.md` in `/update_scripts/global_scripts/00_principles/`
  - Outlines the general approach to maintaining referential integrity
  - Establishes best practices for preventing null references
  - Remains in version control

- **Instance**: `2025-04-02_null_references_report.md` in `/update_scripts/records/`
  - Contains findings from a specific analysis
  - References specific files and issues found
  - Includes recommendations specific to current codebase
  - Stored in Dropbox but not in Git

### Example 2: Directory Structure Changes

- **Principle**: `17_app_construction_function.md` in `/update_scripts/global_scripts/00_principles/`
  - Establishes the standard directory structure for the application
  - Defines how configuration should be separated from implementation
  - Tracked in version control

- **Instance**: `2025-04-02_app_directory_changes.md` in `/update_scripts/records/`
  - Documents specific changes (e.g., renaming local_scripts to app_configs)
  - Records the rationale and impact of each change
  - Includes specific command used to implement the change
  - Dropbox storage only

## Meta-Principle Hierarchy

This Instance vs. Principle distinction sits near the top of our meta-principle hierarchy:

1. **Mode Hierarchy Principle**
2. **Instance vs. Principle Meta-Principle**
3. **Package Consistency Principle**
4. **Referential Integrity Principle**

## Best Practices

1. **Regular Reviews**: Periodically review instances to identify patterns that should be promoted to principles

2. **Clear Referencing**: When an instance references a principle, include the principle's filename

3. **Boundary Cases**: When in doubt about whether something is a principle or instance, ask:
   - Does it apply generally across projects?
   - Will it remain relevant for an extended period?
   - Does it guide future work rather than document past work?

4. **Evolution Path**: Recognize that instances can evolve into principles:
   ```
   Specific Observation → Repeated Pattern → Best Practice → Principle
   ```

## Conclusion

The Instance vs. Principle Meta-Principle provides a clear framework for organizing our documentation and code. By maintaining this distinction, we ensure that our principles remain focused on reusable guidelines while allowing instances to document specific implementations and findings without cluttering our version control system.