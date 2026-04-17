# Project-Agnostic 00_principles Architecture

**Document Version**: 1.0
**Date**: 2025-10-03
**Status**: Design Proposal
**Author**: Principle Explorer (Claude Code)

---

## Executive Summary

This document redesigns the 00_principles system to be **project-agnostic**, enabling reuse across any project in the che_workspace ecosystem (ai_martech, research, python_projects, etc.) while maintaining project-specific customizations.

### Key Design Goals

1. **Universal Core**: Shared principles applicable across all projects
2. **Project Extensions**: Project-specific principles and customizations
3. **Auto-Discovery**: Scripts automatically detect project context
4. **Zero Hard-Coding**: All paths and names defined via configuration
5. **Git Subrepo Pattern**: Core principles distributed via subrepo

---

## Current Problems

### Hard-Coded Dependencies

1. **Fixed Paths**:
   ```yaml
   # parameters.yaml (current)
   system:
     base_path: "$HOME/Library/CloudStorage/Dropbox/precision_marketing"
     repository_pattern: "precision_marketing_{company}/precision_marketing_app"
   ```

2. **Company-Specific Assumptions**:
   ```yaml
   companies:
     - KitchenMAMA  # Hard-coded to ai_martech domain
     - WISER
     - MAMBA
   ```

3. **Single-Project Focus**:
   - Documentation assumes ai_martech context
   - Scripts expect fixed directory structure
   - No concept of "project type" (R/Python/Shiny)

### Impact

- Cannot use 00_principles in research projects
- Cannot use in python_projects without modification
- Manual sync required across projects
- Principle updates don't propagate automatically

---

## New Architecture

### Directory Structure

```
che_workspace/
├── shared/
│   └── 00_principles_core/              # Git repository (subrepo source)
│       ├── README.md                     # Core principles documentation
│       ├── INDEX.md                      # Universal principle index
│       ├── docs/
│       │   └── en/
│       │       ├── part1_principles/     # Universal principles
│       │       │   ├── CH00_fundamental_principles/
│       │       │   ├── CH01_structure_organization/
│       │       │   ├── CH02_data_management/
│       │       │   ├── CH03_development_methodology/
│       │       │   └── ...
│       │       └── part2_implementations/ # Implementation templates
│       ├── logical/                      # Formal logic versions (archived in 99_archive)
│       ├── REFERENCES/                   # Universal bibliography
│       ├── utils/                        # Core utility scripts
│       │   ├── detect_project.sh         # Auto-detect project context
│       │   ├── load_config.R             # Load project config
│       │   └── sync_principles.sh        # Sync core to projects
│       └── templates/
│           ├── project_config.yaml       # Project config template
│           └── principles_local/         # Template for local principles
│
├── projects/
│   ├── ai_martech/
│   │   ├── project_config.yaml           # Project-specific config
│   │   ├── global_scripts/
│   │   │   ├── 00_principles/            # Subrepo from core
│   │   │   └── 00_principles_local/      # AI MarTech extensions
│   │   │       ├── README.md
│   │   │       ├── docs/
│   │   │       │   └── en/
│   │   │       │       └── part1_principles/
│   │   │       │           ├── CH08_shiny_applications/     # App-specific
│   │   │       │           ├── CH11_etl_pipelines/          # ETL-specific
│   │   │       │           └── CH10_marketing_analytics/    # Domain-specific
│   │   │       └── parameters_local.yaml # Override parameters
│   │   └── l4_enterprise/MAMBA/...
│   │
│   ├── research/
│   │   ├── project_config.yaml
│   │   ├── global_scripts/
│   │   │   ├── 00_principles/            # Same core subrepo
│   │   │   └── 00_principles_local/      # Research extensions
│   │   │       └── docs/
│   │   │           └── en/
│   │   │               └── part1_principles/
│   │   │                   ├── CH08_statistical_analysis/
│   │   │                   ├── CH09_psychometrics/
│   │   │                   └── CH10_academic_reporting/
│   │   └── kehchunglin_lab/...
│   │
│   └── python_projects/
│       ├── project_config.yaml
│       ├── global_scripts/
│       │   ├── 00_principles/            # Same core subrepo
│       │   └── 00_principles_local/      # Python extensions
│       │       └── docs/
│       │           └── en/
│       │               └── part1_principles/
│       │                   ├── CH08_python_packaging/
│       │                   ├── CH09_data_processing/
│       │                   └── CH10_ml_pipelines/
│       └── pdf_to_latex/...
```

### Key Design Patterns

#### 1. Core + Local Separation

**Core Principles** (`00_principles/`):
- Universal across ALL projects
- Maintained as Git repository
- Distributed via Git Subrepo
- Read-only in each project
- Examples:
  - CH00: Fundamental Principles
  - CH01: Structure & Organization
  - CH02: Data Management
  - CH03: Development Methodology
  - CH04: UI Components (if applicable)
  - CH05: Testing & Deployment
  - CH06: Integration & Collaboration
  - CH07: Security

**Local Principles** (`00_principles_local/`):
- Project-specific extensions
- Owned by each project
- Not synced across projects
- Examples:
  - ai_martech: Shiny apps, ETL pipelines, marketing analytics
  - research: Statistical methods, psychometrics, academic standards
  - python_projects: Python packaging, ML pipelines, data processing

#### 2. Configuration-Driven Discovery

Every project has `project_config.yaml` at root:

```yaml
# projects/ai_martech/project_config.yaml

project:
  name: "ai_martech"
  type: "r_shiny"                    # r_shiny | r_analysis | python | mixed
  description: "AI-powered marketing technology platform"
  owner: "MAMBA Enterprise"

  # Principle system configuration
  principles:
    core_path: "global_scripts/00_principles"
    local_path: "global_scripts/00_principles_local"
    auto_sync: true
    sync_interval_hours: 24

  # Company/entity configuration (project-specific)
  entities:
    type: "companies"                # companies | labs | clients | projects
    list:
      - name: "MAMBA"
        code: "mamba"
        active: true
      - name: "KitchenMAMA"
        code: "kitchenmama"
        active: true
      - name: "WISER"
        code: "wiser"
        active: false

  # Path patterns for app discovery
  app_discovery:
    tiers: ["l0_research", "l1_basic", "l2_pro", "l3_enterprise", "l4_enterprise"]
    config_file: "app_config.yaml"
    exclude_patterns: ["archive", "test", "temp"]

  # Project-specific parameters
  parameters:
    base_path: "${WORKSPACE_ROOT}/projects/ai_martech"
    data_path: "data"
    database_type: "duckdb"          # duckdb | postgresql | sqlite

  # Environment
  environment:
    required_vars:
      - "PGHOST"
      - "OPENAI_API_KEY"
    optional_vars:
      - "SLACK_WEBHOOK"
```

```yaml
# projects/research/project_config.yaml

project:
  name: "research"
  type: "r_analysis"
  description: "Academic research projects and statistical analyses"
  owner: "Dr. Cheng Che"

  principles:
    core_path: "global_scripts/00_principles"
    local_path: "global_scripts/00_principles_local"
    auto_sync: true
    sync_interval_hours: 24

  entities:
    type: "labs"                     # Different entity type
    list:
      - name: "kehchunglin_lab"
        code: "kcl"
        active: true
      - name: "psychometrics_lab"
        code: "psych"
        active: true

  app_discovery:
    patterns: ["*_lab", "*_study", "*_analysis"]
    config_file: ".project_config"
    exclude_patterns: ["archive", "Literature"]

  parameters:
    base_path: "${WORKSPACE_ROOT}/projects/research"
    output_path: "output"
    data_path: "rawdata"

  environment:
    required_vars:
      - "R_LIBS_USER"
```

```yaml
# projects/python_projects/project_config.yaml

project:
  name: "python_projects"
  type: "python"
  description: "Python utility tools and data science projects"
  owner: "Dr. Cheng Che"

  principles:
    core_path: "global_scripts/00_principles"
    local_path: "global_scripts/00_principles_local"
    auto_sync: true
    sync_interval_hours: 24

  entities:
    type: "tools"                    # Different entity type
    list:
      - name: "pdf_to_latex"
        code: "pdf2tex"
        active: true
      - name: "graphiti"
        code: "graphiti"
        active: true

  app_discovery:
    patterns: ["*/setup.py", "*/pyproject.toml"]
    exclude_patterns: ["venv", "__pycache__", ".pytest_cache"]

  parameters:
    base_path: "${WORKSPACE_ROOT}/projects/python_projects"
    venv_path: "venv"

  environment:
    required_vars:
      - "PYTHONPATH"
```

#### 3. Auto-Discovery Scripts

**Script: `utils/detect_project.sh`**

```bash
#!/bin/bash
# Auto-detect which project we're in

# Function to find project root by looking for project_config.yaml
find_project_root() {
    local current_dir="$PWD"

    while [[ "$current_dir" != "/" ]]; do
        if [[ -f "$current_dir/project_config.yaml" ]]; then
            echo "$current_dir"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
    done

    echo "ERROR: No project_config.yaml found in parent directories" >&2
    return 1
}

# Function to extract project info from config
get_project_info() {
    local project_root="$1"
    local config_file="$project_root/project_config.yaml"

    # Extract using yq or python
    if command -v yq &> /dev/null; then
        PROJECT_NAME=$(yq eval '.project.name' "$config_file")
        PROJECT_TYPE=$(yq eval '.project.type' "$config_file")
        PRINCIPLES_CORE=$(yq eval '.project.principles.core_path' "$config_file")
        PRINCIPLES_LOCAL=$(yq eval '.project.principles.local_path' "$config_file")
    else
        # Fallback to simple grep
        PROJECT_NAME=$(grep -A 1 "^project:" "$config_file" | grep "name:" | sed 's/.*name: *"\(.*\)".*/\1/')
        PROJECT_TYPE=$(grep "type:" "$config_file" | head -1 | sed 's/.*type: *"\(.*\)".*/\1/')
    fi

    export PROJECT_ROOT="$project_root"
    export PROJECT_NAME
    export PROJECT_TYPE
    export PRINCIPLES_CORE="$project_root/$PRINCIPLES_CORE"
    export PRINCIPLES_LOCAL="$project_root/$PRINCIPLES_LOCAL"
}

# Main execution
PROJECT_ROOT=$(find_project_root)
if [[ $? -eq 0 ]]; then
    get_project_info "$PROJECT_ROOT"
    echo "Detected project: $PROJECT_NAME ($PROJECT_TYPE)"
    echo "Project root: $PROJECT_ROOT"
    echo "Core principles: $PRINCIPLES_CORE"
    echo "Local principles: $PRINCIPLES_LOCAL"
else
    exit 1
fi
```

**Script: `utils/load_config.R`**

```r
# Load project configuration in R
library(yaml)

detect_project <- function() {
  # Walk up directory tree to find project_config.yaml
  current_dir <- getwd()

  while (current_dir != "/") {
    config_path <- file.path(current_dir, "project_config.yaml")

    if (file.exists(config_path)) {
      return(list(
        root = current_dir,
        config_path = config_path
      ))
    }

    current_dir <- dirname(current_dir)
  }

  stop("No project_config.yaml found in parent directories")
}

load_project_config <- function(config_path = NULL) {
  if (is.null(config_path)) {
    project_info <- detect_project()
    config_path <- project_info$config_path
  }

  config <- yaml::read_yaml(config_path)

  # Resolve environment variables in paths
  resolve_env_vars <- function(path) {
    if (is.null(path)) return(path)

    # Replace ${VAR} with Sys.getenv("VAR")
    gsub("\\$\\{([^}]+)\\}", function(m) {
      var_name <- sub("\\$\\{(.+)\\}", "\\1", m)
      Sys.getenv(var_name, unset = "")
    }, path, perl = TRUE)
  }

  # Resolve all paths
  if (!is.null(config$parameters$base_path)) {
    config$parameters$base_path <- resolve_env_vars(config$parameters$base_path)
  }

  # Add computed paths
  config$project$root <- dirname(config_path)
  config$project$principles_core_full <- file.path(
    config$project$root,
    config$project$principles$core_path
  )
  config$project$principles_local_full <- file.path(
    config$project$root,
    config$project$principles$local_path
  )

  # Set global options for easy access
  options(
    project_config = config,
    project_root = config$project$root,
    project_name = config$project$name,
    project_type = config$project$type
  )

  return(config)
}

# Convenience functions
get_project_name <- function() {
  config <- getOption("project_config")
  if (is.null(config)) {
    config <- load_project_config()
  }
  return(config$project$name)
}

get_project_type <- function() {
  config <- getOption("project_config")
  if (is.null(config)) {
    config <- load_project_config()
  }
  return(config$project$type)
}

get_project_entities <- function() {
  config <- getOption("project_config")
  if (is.null(config)) {
    config <- load_project_config()
  }
  return(config$project$entities$list)
}

# Example usage:
# config <- load_project_config()
# print(config$project$name)
# entities <- get_project_entities()
```

#### 4. Git Subrepo Distribution

**Setup Core Repository**:

```bash
# 1. Create core principles repository
cd ~/repos
git init 00_principles_core
cd 00_principles_core

# 2. Copy universal principles from ai_martech
# (only CH00-CH07, exclude project-specific CH08-CH17)
cp -r /path/to/ai_martech/global_scripts/00_principles/docs/en/part1_principles/CH00* .
# ... repeat for CH01-CH07

# 3. Add core utilities
mkdir utils
# Add detect_project.sh, load_config.R, etc.

# 4. Commit and push
git add .
git commit -m "Initial core principles repository"
git remote add origin https://github.com/username/00_principles_core.git
git push -u origin main
```

**Add to Each Project**:

```bash
# In ai_martech
cd projects/ai_martech
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# In research
cd projects/research
mkdir -p global_scripts
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# In python_projects
cd projects/python_projects
mkdir -p global_scripts
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles
```

**Update All Projects**:

```bash
# When core principles are updated
cd projects/ai_martech
git subrepo pull global_scripts/00_principles

cd projects/research
git subrepo pull global_scripts/00_principles

cd projects/python_projects
git subrepo pull global_scripts/00_principles
```

---

## Principle Scoping Rules

### Universal Principles (Core)

Located in `00_principles/`, applicable to ALL projects:

**CH00: Fundamental Principles**
- MP001: Axiomatization System
- MP002: Primitive Terms and Definitions
- MP003: Default Deny
- Applies to: All projects

**CH01: Structure & Organization**
- File organization patterns
- Naming conventions
- Directory structure
- Applies to: All projects

**CH02: Data Management**
- Data flow principles
- State management
- Data validation
- Applies to: All projects (adapt to language)

**CH03: Development Methodology**
- DRY, SOLID principles
- Functional programming
- Code organization
- Applies to: All projects

**CH04: UI Components** (conditional)
- UI/UX principles
- Component design
- Applies to: Projects with UI (ai_martech, some research)
- Skipped in: CLI-only python projects

**CH05: Testing & Deployment**
- Testing strategies
- CI/CD patterns
- Deployment checklists
- Applies to: All projects (adapt to context)

**CH06: Integration & Collaboration**
- API design
- Version control
- Team workflows
- Applies to: All projects

**CH07: Security**
- Authentication patterns
- Data protection
- Environment variables
- Applies to: All projects

### Project-Specific Principles (Local)

Located in `00_principles_local/`, extends core:

**ai_martech Extensions** (`CH08-CH17`):
- CH08: Shiny Application Architecture
- CH09: ETL Pipeline Design
- CH10: Marketing Analytics Patterns
- CH11: Templates & Examples
- CH12: Database Specifications (DuckDB/PostgreSQL)
- CH13: OpenAI Integration
- CH14: bs4Dash Components
- CH15: Reactive Programming
- CH16: NSQL Language
- CH17: AIMETA Language

**research Extensions** (`CH08-CH10`):
- CH08: Statistical Analysis Standards
- CH09: Psychometric Methods
- CH10: Academic Reporting & Reproducibility

**python_projects Extensions** (`CH08-CH10`):
- CH08: Python Packaging & Distribution
- CH09: Data Processing Pipelines
- CH10: Machine Learning Workflows

### Inheritance & Override Rules

1. **Core principles are immutable** within each project
   - Projects consume core via subrepo (read-only)
   - Updates come from upstream core repository

2. **Local principles extend, never override**
   - Local principles can specialize core principles
   - Cannot contradict core principles
   - Must reference core principle if related

3. **Conflict resolution**:
   ```yaml
   # In principles_local/parameters_local.yaml
   overrides:
     # Allowed: Extend entity list
     entities:
       additional:
         - name: "NewCompany"

     # NOT allowed: Change core principle
     # core_principles:
     #   MP001: "Modified..."  # FORBIDDEN
   ```

4. **Principle numbering**:
   - Core: `{CHAPTER}_{TYPE}{NUMBER}` (e.g., `CH02_P005`)
   - Local: `{CHAPTER}_{TYPE}{NUMBER}_local` (e.g., `CH08_P001_local`)
   - Prevents collisions with core

---

## Migration Guide

### Step 1: Set Up Core Repository

```bash
# 1. Create core repo
mkdir ~/repos/00_principles_core
cd ~/repos/00_principles_core
git init

# 2. Copy universal principles from existing ai_martech
# Only CH00-CH07 (universal chapters)
cp -r /path/to/ai_martech/global_scripts/00_principles/docs/en/part1_principles/CH0[0-7]* docs/en/part1_principles/

# 3. Add core utilities
mkdir -p utils
# Copy detect_project.sh, load_config.R, sync_principles.sh

# 4. Add templates
mkdir -p templates
# Copy project_config.yaml template
# Copy principles_local/ template structure

# 5. Update README for core-specific guidance
# 6. Commit and push
git add .
git commit -m "Initial core principles repository"
git remote add origin https://github.com/username/00_principles_core.git
git push -u origin main
```

### Step 2: Migrate ai_martech

```bash
cd /path/to/ai_martech

# 1. Create project_config.yaml at root
# (use template from Step 1)

# 2. Backup current 00_principles
mv global_scripts/00_principles global_scripts/00_principles_backup

# 3. Add core principles as subrepo
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# 4. Create local principles
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles

# 5. Move project-specific principles (CH08-CH17) to local
mv global_scripts/00_principles_backup/docs/en/part1_principles/CH{08..17}* \
   global_scripts/00_principles_local/docs/en/part1_principles/

# 6. Create parameters_local.yaml
# (only project-specific overrides)

# 7. Test auto-discovery
bash global_scripts/00_principles/utils/detect_project.sh

# 8. Update initialization scripts to use load_config.R
# 9. Commit changes
```

### Step 3: Add to Research Project

```bash
cd /path/to/research

# 1. Create project_config.yaml
# (use research template)

# 2. Add core principles
mkdir -p global_scripts
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# 3. Create research-specific local principles
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH08_statistical_analysis
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH09_psychometrics
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH10_academic_reporting

# 4. Document research-specific principles
# 5. Test auto-discovery
```

### Step 4: Add to Python Projects

```bash
cd /path/to/python_projects

# 1. Create project_config.yaml
# (use python template)

# 2. Add core principles
mkdir -p global_scripts
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# 3. Create python-specific local principles
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH08_python_packaging
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH09_data_processing

# 4. Test auto-discovery
```

### Step 5: Update Sync Workflows

Create workspace-wide sync script:

```bash
#!/bin/bash
# sync_all_projects.sh

WORKSPACE_ROOT="${HOME}/Library/CloudStorage/Dropbox/che_workspace"
PROJECTS=("ai_martech" "research" "python_projects")

for project in "${PROJECTS[@]}"; do
    PROJECT_DIR="${WORKSPACE_ROOT}/projects/${project}"

    if [[ -d "$PROJECT_DIR/global_scripts/00_principles" ]]; then
        echo "Syncing $project..."
        cd "$PROJECT_DIR"
        git subrepo pull global_scripts/00_principles
    else
        echo "Skipping $project (no principles found)"
    fi
done

echo "All projects synced!"
```

---

## API Reference

### Configuration Schema

```yaml
# Full project_config.yaml schema

project:
  name: string                          # REQUIRED: Project identifier
  type: enum                            # REQUIRED: r_shiny | r_analysis | python | mixed
  description: string                   # REQUIRED: Human-readable description
  owner: string                         # REQUIRED: Owner/maintainer
  version: string                       # OPTIONAL: Semantic version

  principles:
    core_path: string                   # REQUIRED: Relative path to core principles
    local_path: string                  # REQUIRED: Relative path to local principles
    auto_sync: boolean                  # REQUIRED: Enable automatic sync
    sync_interval_hours: integer        # OPTIONAL: Hours between syncs (default: 24)

  entities:
    type: enum                          # REQUIRED: companies | labs | clients | projects | tools
    list:                               # REQUIRED: List of entities
      - name: string                    # Entity display name
        code: string                    # Entity code (lowercase, no spaces)
        active: boolean                 # Is entity currently active
        metadata: object                # OPTIONAL: Additional entity data

  app_discovery:                        # OPTIONAL: For projects with sub-apps
    tiers: array<string>                # Directory tiers to scan
    patterns: array<string>             # File patterns to match
    config_file: string                 # Config filename to look for
    exclude_patterns: array<string>     # Patterns to exclude

  parameters:                           # Project-specific parameters
    base_path: string                   # Base path (can use ${ENV_VAR})
    # ... any project-specific params

  environment:
    required_vars: array<string>        # REQUIRED environment variables
    optional_vars: array<string>        # OPTIONAL environment variables
```

### R Functions

```r
# Core functions in utils/load_config.R

detect_project() -> list
  # Returns: list(root = path, config_path = path)
  # Throws: Error if no config found

load_project_config(config_path = NULL) -> list
  # Returns: Full config as nested list
  # Side effects: Sets global options

get_project_name() -> string
  # Returns: Current project name

get_project_type() -> string
  # Returns: Current project type

get_project_entities() -> list
  # Returns: List of entities for current project

get_principle_path(type = "core") -> string
  # Args: type in c("core", "local")
  # Returns: Full path to principles directory
```

### Shell Functions

```bash
# Core functions in utils/detect_project.sh

find_project_root()
  # Returns: Project root path
  # Exit code: 0 = success, 1 = not found

get_project_info(project_root)
  # Side effects: Exports PROJECT_* variables
  # Exports: PROJECT_ROOT, PROJECT_NAME, PROJECT_TYPE,
  #          PRINCIPLES_CORE, PRINCIPLES_LOCAL
```

---

## Examples

### Example 1: Using Principles in ai_martech App

```r
# In ai_martech/l1_basic/MyApp/app.R

# Load project configuration
source(file.path("..", "..", "global_scripts", "00_principles", "utils", "load_config.R"))
config <- load_project_config()

# Access project info
project_name <- config$project$name        # "ai_martech"
entities <- config$project$entities$list   # List of companies

# Load core utilities (DRY principle from CH03)
core_utils <- file.path(config$project$principles_core_full, "utils")

# Load project-specific utilities
local_utils <- file.path(config$project$principles_local_full, "utils")

# Reference principle in code
# Per CH02_P005_data_source_hierarchy, always use tbl2()
source(file.path("..", "..", "global_scripts", "02_db_utils", "fn_tbl2.R"))
data <- tbl2(con, "sales")
```

### Example 2: Using Principles in Research Project

```r
# In research/kehchunglin_lab/analysis.R

# Load project configuration
source(file.path("..", "global_scripts", "00_principles", "utils", "load_config.R"))
config <- load_project_config()

# Access lab info
labs <- config$project$entities$list       # List of labs
current_lab <- labs[[1]]$name              # "kehchunglin_lab"

# Follow CH10_academic_reporting principles
# Set random seed for reproducibility
set.seed(config$parameters$random_seed %||% 42)

# Use standardized output paths
output_dir <- file.path(config$parameters$base_path, "output")
```

### Example 3: Using Principles in Python Project

```python
# In python_projects/pdf_to_latex/main.py

import yaml
import os
from pathlib import Path

def find_project_config():
    """Walk up directory tree to find project_config.yaml"""
    current = Path.cwd()
    while current != current.parent:
        config_path = current / "project_config.yaml"
        if config_path.exists():
            return config_path
        current = current.parent
    raise FileNotFoundError("No project_config.yaml found")

def load_config():
    config_path = find_project_config()
    with open(config_path) as f:
        return yaml.safe_load(f)

# Load configuration
config = load_config()
project_name = config['project']['name']  # "python_projects"

# Follow CH08_python_packaging principles
# Use project-standard directory structure
output_dir = Path(config['parameters']['base_path']) / 'output'
```

---

## Benefits

### For ai_martech
- Cleaner separation of universal vs domain-specific principles
- Easier to identify which principles apply to new features
- Project-specific principles (Shiny, ETL, marketing) clearly scoped

### For research
- Reuse universal principles (testing, organization, documentation)
- Add statistical/academic-specific principles
- Consistent methodology across lab projects

### For python_projects
- Same core development principles as R projects
- Python-specific extensions for packaging, ML, etc.
- Easier to maintain consistency across languages

### For Workspace
- Single source of truth for universal principles
- Automatic propagation of updates
- Clear principle ownership (core vs local)
- Reduced duplication across projects

---

## Next Steps

1. **Create Core Repository**:
   - Extract CH00-CH07 from ai_martech
   - Add auto-discovery utilities
   - Create templates
   - Publish to GitHub

2. **Migrate ai_martech**:
   - Add project_config.yaml
   - Replace 00_principles with subrepo
   - Move CH08-CH17 to local
   - Update scripts to use auto-discovery

3. **Add to Research**:
   - Create research-specific config
   - Add subrepo
   - Document statistical principles

4. **Add to Python Projects**:
   - Create python-specific config
   - Add subrepo
   - Document Python principles

5. **Workspace-Wide Sync**:
   - Create sync_all_projects.sh
   - Set up cron job for auto-sync
   - Document update workflow

---

## Appendix

### A. Template Files

See `shared/00_principles_core/templates/` for:
- `project_config.yaml` - Full configuration template
- `principles_local/README.md` - Local principles guide
- `parameters_local.yaml` - Local parameter overrides

### B. Principle Numbering Convention

**Core Principles**:
```
{CHAPTER}_{TYPE}{NUMBER}
CH02_P005  # Chapter 02, Principle 005
CH03_R012  # Chapter 03, Rule 012
```

**Local Principles**:
```
{CHAPTER}_{TYPE}{NUMBER}_local
CH08_P001_local  # Local principle, won't conflict with core
CH09_R005_local  # Local rule
```

### C. Chapter Allocation

**Universal (Core)**:
- CH00: Fundamental Principles
- CH01: Structure & Organization
- CH02: Data Management
- CH03: Development Methodology
- CH04: UI Components
- CH05: Testing & Deployment
- CH06: Integration & Collaboration
- CH07: Security

**Project-Specific (Local)**:
- CH08-CH17: Allocated by each project
- Recommended: Use CH08-CH10 for most projects
- Reserve CH11-CH17 for complex projects (like ai_martech)

### D. Migration Checklist

- [ ] Create core repository
- [ ] Extract universal principles (CH00-CH07)
- [ ] Add auto-discovery utilities
- [ ] Create configuration templates
- [ ] Publish core to GitHub
- [ ] Add project_config.yaml to ai_martech
- [ ] Migrate ai_martech to subrepo pattern
- [ ] Create ai_martech local principles
- [ ] Test ai_martech auto-discovery
- [ ] Add principles to research project
- [ ] Add principles to python_projects
- [ ] Create workspace sync script
- [ ] Document maintenance workflow
- [ ] Update CLAUDE.md references

---

**End of Architecture Document**
