# Principle Scoping Rules

**Version**: 1.0
**Date**: 2025-10-03
**Status**: Design Specification

---

## Overview

This document defines the scoping rules for principles in the multi-project 00_principles architecture. It establishes clear boundaries between **universal principles** (applicable to all projects) and **project-specific principles** (extensions for particular domains).

---

## Principle Types

### Core Principles (Universal)

**Location**: `00_principles/` (Git subrepo, read-only in projects)

**Scope**: Apply to ALL projects regardless of language, domain, or purpose

**Characteristics**:
- Language-agnostic where possible
- Focus on fundamental concepts
- Maintained centrally
- Updated via subrepo pull
- Cannot be overridden by projects

**Examples**:
- File organization patterns
- Naming conventions
- DRY/SOLID principles
- Testing strategies
- Security patterns

### Local Principles (Project-Specific)

**Location**: `00_principles_local/` (Project-owned, writable)

**Scope**: Apply only to specific project or domain

**Characteristics**:
- Domain-specific implementations
- Language-specific patterns
- Project-owned and maintained
- Can reference/extend core principles
- Must not contradict core principles

**Examples**:
- Shiny application architecture (ai_martech)
- Statistical reporting standards (research)
- Python packaging conventions (python_projects)

---

## Chapter Allocation

### Universal Chapters (CH00-CH07)

These chapters are part of the **core principles** and apply universally:

#### CH00: Fundamental Principles

**Scope**: ALL projects

**Contents**:
- MP001: Axiomatization System
- MP002: Primitive Terms and Definitions
- MP003: Default Deny
- MP004: Structural Blueprint
- MP005: Operating Modes
- MP006: Mode Hierarchy
- MP007: Instance vs Principle

**Rationale**: Foundational concepts that underpin all development

**Applies to**:
- ✅ ai_martech
- ✅ research
- ✅ python_projects
- ✅ ANY future project

---

#### CH01: Structure & Organization

**Scope**: ALL projects

**Contents**:
- File organization patterns
- Directory structure conventions
- Naming conventions for files/functions
- Module organization
- One-function-one-file rule (R21)

**Rationale**: Code organization is universal across languages

**Applies to**:
- ✅ ai_martech: R/Shiny project structure
- ✅ research: R analysis project structure
- ✅ python_projects: Python package structure

**Adaptations**:
- R projects: `fn_function_name.R`
- Python projects: `function_name.py`
- Same principle, different extension

---

#### CH02: Data Management

**Scope**: ALL projects with data operations

**Contents**:
- Data flow principles
- State management patterns
- Data validation rules
- Data source hierarchy (MP008)
- Universal data access patterns (R091)

**Rationale**: Data handling is fundamental regardless of implementation

**Applies to**:
- ✅ ai_martech: Database queries with tbl2()
- ✅ research: Statistical data management
- ✅ python_projects: pandas/numpy data handling

**Language-Specific Implementation**:
```r
# R implementation (ai_martech, research)
data <- tbl2(con, "table") %>% filter(...)

# Python equivalent (python_projects)
data = pd.read_sql("SELECT * FROM table", con)
```

---

#### CH03: Development Methodology

**Scope**: ALL projects

**Contents**:
- DRY (Don't Repeat Yourself) - MP020
- Modularity - MP018
- Separation of Concerns - MP019
- Functional programming principles
- Code reuse strategies

**Rationale**: Software engineering best practices are universal

**Applies to**:
- ✅ ai_martech: Modular Shiny components
- ✅ research: Reusable analysis functions
- ✅ python_projects: Python modules and packages

---

#### CH04: UI Components

**Scope**: Projects with user interfaces

**Contents**:
- UI/UX design principles
- Component architecture
- Reactive programming patterns
- Accessibility standards

**Rationale**: UI principles apply regardless of framework

**Applies to**:
- ✅ ai_martech: bs4Dash Shiny apps
- ⚠️  research: Some interactive analysis tools
- ❌ python_projects: Mostly CLI tools (skip if not applicable)

**Conditional Application**:
- Projects without UI can skip this chapter
- Projects with minimal UI use subset of principles

---

#### CH05: Testing & Deployment

**Scope**: ALL projects

**Contents**:
- Testing strategies
- Test data design
- CI/CD patterns
- Deployment checklists
- Environment configuration

**Rationale**: Quality assurance is universal

**Applies to**:
- ✅ ai_martech: Shiny app testing, Posit Connect deployment
- ✅ research: Statistical test validation, reproducibility
- ✅ python_projects: pytest, PyPI publishing

**Language-Specific Adaptation**:
```yaml
# ai_martech: testthat
testing:
  framework: "testthat"

# python_projects: pytest
testing:
  framework: "pytest"
```

---

#### CH06: Integration & Collaboration

**Scope**: ALL projects

**Contents**:
- API design principles
- Version control strategies
- Team collaboration patterns
- External system integration
- Documentation standards

**Rationale**: Collaboration is universal in software development

**Applies to**:
- ✅ ai_martech: OpenAI API integration, Git workflows
- ✅ research: Collaboration with statisticians, Git for reproducibility
- ✅ python_projects: Python package APIs, PyPI publishing

---

#### CH07: Security

**Scope**: ALL projects

**Contents**:
- Authentication/authorization
- Data protection
- Environment variable management
- Secret handling
- Security best practices

**Rationale**: Security is non-negotiable across all projects

**Applies to**:
- ✅ ai_martech: Database credentials, API keys
- ✅ research: Participant data privacy
- ✅ python_projects: API tokens, credential management

---

### Project-Specific Chapters (CH08+)

These chapters are part of **local principles** and vary by project:

#### ai_martech Local Principles (CH08-CH17)

**CH08: Shiny Application Architecture**
- bs4Dash framework
- Reactive programming
- Module patterns
- Component n-tuple (UI-Server-Defaults)

**CH09: ETL Pipeline Design**
- Data ingestion patterns
- Transformation workflows
- DuckDB/PostgreSQL integration
- Schema management

**CH10: Marketing Analytics Patterns**
- Customer DNA analysis
- RFM segmentation
- Positioning analysis
- Attribution modeling

**CH11: Templates & Examples**
- Application templates
- Code generators
- Standard configurations

**CH12: Database Specifications**
- DuckDB schemas
- PostgreSQL migrations
- Connection pooling
- Query optimization

**CH13: OpenAI Integration**
- API usage patterns
- Prompt engineering
- Response handling
- Error management

**CH14: bs4Dash Components**
- Custom components
- Theme management
- Layout patterns

**CH15: Reactive Programming**
- Reactive flows
- Observer patterns
- Event handling

**CH16: NSQL Language**
- Natural SQL syntax
- Query translation
- Validation rules

**CH17: AIMETA Language**
- AI communication standards
- Message formats
- Protocol specifications

---

#### research Local Principles (CH08-CH10)

**CH08: Statistical Analysis Standards**
- Reproducibility requirements
- Random seed management
- Session info recording
- Analysis script organization (000_, 001_, etc.)

**CH09: Psychometric Methods**
- IRT model specifications
- Factor analysis patterns
- Model comparison standards
- Validity/reliability reporting

**CH10: Academic Reporting & Reproducibility**
- Manuscript preparation
- Figure/table standards
- Citation management
- Data archival (OSF, etc.)
- IRB compliance

---

#### python_projects Local Principles (CH08-CH10)

**CH08: Python Packaging & Distribution**
- setup.py/pyproject.toml structure
- Version management
- PyPI publishing
- Dependencies specification

**CH09: Data Processing Pipelines**
- pandas conventions
- numpy best practices
- Data validation
- Pipeline orchestration

**CH10: Machine Learning Workflows**
- Model training patterns
- Experiment tracking
- Model versioning
- Deployment patterns

---

## Scoping Rules

### Rule 1: Core Principles Are Immutable Within Projects

```yaml
# FORBIDDEN: Modifying core principles in local context
# File: 00_principles_local/docs/en/part1_principles/CH02_data_management/override.md
---
# This violates scoping rules!
MP008_data_source_hierarchy: "Modified version..."  # ❌ Cannot override core
```

**Correct Approach**: Reference and extend
```yaml
# ALLOWED: Extending core principles
# File: 00_principles_local/docs/en/part1_principles/CH08_statistical_analysis/CH08_P001_data_loading.md

# Data Loading for Statistical Analysis
# References: CH02 Data Management, MP008 Data Source Hierarchy

## Principle
Statistical analysis data loading extends MP008 by adding:
- Automatic data type inference
- Missing data handling
- Outlier detection on load
```

---

### Rule 2: Local Principles Must Not Contradict Core

```yaml
# FORBIDDEN: Contradicting core principle
# Core says: "One function per file"
# Local says: "Multiple functions in one file for statistical utilities"  # ❌

# ALLOWED: Specifying exceptions with justification
# Local says: "Statistical helper functions may be grouped when they form
# a cohesive unit < 50 lines total, per CH03 modularity exception for
# tightly coupled utilities"  # ✅
```

---

### Rule 3: Principle Numbering Must Avoid Collisions

**Core Principle Numbering**:
```
{CHAPTER}_{TYPE}{NUMBER}
CH02_P005   # Chapter 02, Principle 005
CH03_R012   # Chapter 03, Rule 012
CH07_MP003  # Chapter 07, Meta-Principle 003
```

**Local Principle Numbering**:
```
{CHAPTER}_{TYPE}{NUMBER}_local
CH08_P001_local   # Local principle, won't conflict with core CH08_P001
CH09_R005_local   # Local rule
CH10_MP001_local  # Local meta-principle
```

**Rationale**: Prevents future collisions if core expands to CH08+

---

### Rule 4: Local Principles Should Reference Core Where Applicable

**Good Example**:
```markdown
# CH08_P003_shiny_module_structure_local.md

## Principle: Shiny Module Structure

**Extends**: CH03_P015 (Modularity), CH04_P002 (Component Architecture)

Shiny modules MUST follow the component n-tuple pattern:
- UI function: `moduleNameUI()`
- Server function: `moduleNameServer()`
- Defaults function: `moduleNameDefaults()`

This extends the general modularity principle (CH03_P015) with
Shiny-specific implementation details...
```

**Bad Example**:
```markdown
# CH08_P003_shiny_module_structure_local.md

## Principle: Shiny Module Structure

Shiny modules should be organized nicely.  # ❌ No reference to core principles
Use good names.  # ❌ Vague, doesn't reference naming conventions
```

---

### Rule 5: Project Types Determine Applicable Core Chapters

```yaml
# project_config.yaml determines which chapters apply

# ai_martech: r_shiny type
project:
  type: "r_shiny"
  applicable_core_chapters:
    - CH00  # ✅ Fundamental (always)
    - CH01  # ✅ Structure (always)
    - CH02  # ✅ Data Management (always)
    - CH03  # ✅ Development (always)
    - CH04  # ✅ UI Components (has UI)
    - CH05  # ✅ Testing (always)
    - CH06  # ✅ Integration (always)
    - CH07  # ✅ Security (always)

# python_projects: python type (CLI tools)
project:
  type: "python"
  applicable_core_chapters:
    - CH00  # ✅ Fundamental
    - CH01  # ✅ Structure
    - CH02  # ✅ Data Management
    - CH03  # ✅ Development
    - CH04  # ❌ UI Components (skip - no UI)
    - CH05  # ✅ Testing
    - CH06  # ✅ Integration
    - CH07  # ✅ Security
```

---

## Inheritance & Override Patterns

### Valid Extension: Specialization

```markdown
# Core Principle (CH02_P010_data_validation)
All data inputs MUST be validated before processing.

# Local Extension (CH08_P005_statistical_data_validation_local)
Statistical data validation extends CH02_P010 by requiring:
1. Distributional assumption checks
2. Outlier detection (IQR method)
3. Missing data pattern analysis
4. Variable type validation (numeric/factor/character)
```

**Result**: ✅ Local principle adds specificity without contradiction

---

### Valid Extension: Adaptation

```markdown
# Core Principle (CH01_R021_one_function_one_file)
Each function MUST be in its own file.

# Local Adaptation (CH08_R010_statistical_helper_grouping_local)
Exception to R021: Statistical helper functions MAY be grouped in one file when:
- Total file length < 50 lines
- Functions are tightly coupled (e.g., forward/backward selection helpers)
- File name indicates grouping: `fn_helpers_selection.R`

Rationale: Statistical workflows often use small helper functions that
are only called together. Grouping reduces file proliferation while
maintaining clarity.
```

**Result**: ✅ Local rule specifies valid exception with clear boundaries

---

### Invalid Override: Contradiction

```markdown
# Core Principle (CH07_P001_environment_variables)
Secrets MUST be stored in environment variables, never in code.

# Local Override (FORBIDDEN)
For research projects, API keys MAY be stored in config files
for reproducibility.  # ❌ VIOLATES SECURITY PRINCIPLE
```

**Result**: ❌ Security principles cannot be overridden

---

## Conflict Resolution

### Scenario 1: Core Principle Seems Inapplicable

**Problem**: Core principle doesn't fit project context

**Solution**: Document exception in local principles with justification

```markdown
# 00_principles_local/EXCEPTIONS.md

## Exception: CH04 UI Components

**Core Chapter**: CH04 UI Components
**Project**: python_projects
**Reason**: This project contains CLI tools without graphical interfaces
**Resolution**: CH04 principles are not applicable and are skipped
**Alternative**: CLI interaction follows CH06_P015 (CLI Design Patterns) instead
```

---

### Scenario 2: Local Principle Conflicts with Core

**Problem**: Local principle inadvertently contradicts core

**Resolution Process**:
1. **Review Core Principle**: Understand the rationale
2. **Revise Local Principle**: Align with core or document valid exception
3. **Update Documentation**: Clarify relationship to core
4. **If Core Is Wrong**: Propose core principle amendment via GitHub issue

**Example**:
```markdown
# Initial local principle (conflicts)
CH08_P010_data_caching_local: Cache all database queries for performance

# Core principle
CH02_P025_data_freshness: Always fetch fresh data for analytics

# Resolution: Revise local principle
CH08_P010_data_caching_local: Cache database queries only for:
- Static reference data (updated < daily)
- Expensive aggregations with timestamp tracking
- User session data (cleared on logout)

Always fetch fresh data for:
- Transactional queries
- Real-time analytics
- Financial calculations

References CH02_P025 for freshness requirements.
```

---

### Scenario 3: Multiple Local Principles for Similar Concepts

**Problem**: Different projects have overlapping local principles

**Solution**: Promote common pattern to core principles

**Example**:
- ai_martech has: CH08_P020_api_rate_limiting_local
- python_projects has: CH08_P015_api_throttling_local

**Resolution**: Create core principle CH06_P030_api_rate_limiting

---

## Principle Discovery Process

### For Developers

When starting work on a feature:

1. **Load Project Config**:
   ```r
   source("global_scripts/00_principles/utils/load_config.R")
   config <- load_project_config()
   ```

2. **Identify Applicable Core Principles**:
   - Check `00_principles/docs/en/part1_principles/`
   - Review CH00-CH07 for relevant principles

3. **Check Local Extensions**:
   - Check `00_principles_local/docs/en/part1_principles/`
   - Review CH08+ for domain-specific guidance

4. **Apply Scoping Rules**:
   - Core principles are mandatory
   - Local principles provide specialization
   - Document any exceptions

---

### For Principle Authors

When creating a new principle:

1. **Determine Scope**:
   - Universal → Core principle (CH00-CH07)
   - Project-specific → Local principle (CH08+)

2. **Check for Existing Principles**:
   - Search core principles for similar concepts
   - Reference existing principles where applicable

3. **Use Correct Numbering**:
   - Core: `{CHAPTER}_{TYPE}{NUMBER}`
   - Local: `{CHAPTER}_{TYPE}{NUMBER}_local`

4. **Document Relationships**:
   - Extends: Which core principle does this build upon?
   - Conflicts: Does this contradict any core principle?
   - References: What related principles should readers know about?

---

## Maintenance Workflow

### Updating Core Principles

```bash
# 1. Update core repository
cd ~/repos/00_principles_core
git checkout main
# Make changes to CH00-CH07 only

git add .
git commit -m "Update CH03: Add functional programming guidance"
git push origin main

# 2. Sync to all projects
cd ~/che_workspace/projects/ai_martech
git subrepo pull global_scripts/00_principles

cd ~/che_workspace/projects/research
git subrepo pull global_scripts/00_principles

cd ~/che_workspace/projects/python_projects
git subrepo pull global_scripts/00_principles
```

### Updating Local Principles

```bash
# Each project maintains its own local principles
cd ~/che_workspace/projects/ai_martech

# Edit local principles
vim global_scripts/00_principles_local/docs/en/part1_principles/CH08_shiny_applications/...

# Commit to project repository
git add global_scripts/00_principles_local/
git commit -m "Add Shiny reactivity guidance to CH08"
git push
```

---

## Summary

**Core Principles (CH00-CH07)**:
- ✅ Universal across all projects
- ✅ Maintained centrally
- ✅ Updated via Git subrepo
- ❌ Cannot be overridden
- ❌ Cannot be contradicted

**Local Principles (CH08+)**:
- ✅ Project-specific
- ✅ Maintained by project
- ✅ Can extend core principles
- ✅ Can specify valid exceptions
- ❌ Cannot contradict core principles

**Scoping Rules**:
1. Core principles are immutable within projects
2. Local principles must not contradict core
3. Principle numbering must avoid collisions
4. Local principles should reference core where applicable
5. Project types determine applicable core chapters

**Conflict Resolution**:
- Document exceptions clearly
- Justify deviations from core
- Propose core amendments when appropriate

---

**End of Document**
