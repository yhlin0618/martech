# Quick Start: Adding 00_principles to Any Project

**Target Audience**: Developers adding 00_principles to a new project
**Time Required**: 15-30 minutes
**Prerequisites**: Git, Git Subrepo (optional but recommended)

---

## TL;DR

```bash
# 1. Copy config template to project root
cp templates/project_config_{type}.yaml /path/to/project/project_config.yaml

# 2. Edit config (set name, owner, entities)
vim /path/to/project/project_config.yaml

# 3. Add core principles as subrepo
cd /path/to/project
mkdir -p global_scripts
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# 4. Create local principles structure
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles

# 5. Test auto-discovery
bash global_scripts/00_principles/utils/detect_project.sh
```

---

## Step-by-Step Guide

### Step 1: Choose Your Project Type

Determine which template matches your project:

- **ai_martech**: Shiny applications with marketing analytics
- **research**: R statistical analysis and academic research
- **python**: Python tools, packages, or data science projects

### Step 2: Copy Configuration Template

```bash
# Navigate to your project root
cd /path/to/your/project

# Copy the appropriate template
# For R Shiny projects:
cp /path/to/templates/project_config_aimartech.yaml project_config.yaml

# For R research projects:
cp /path/to/templates/project_config_research.yaml project_config.yaml

# For Python projects:
cp /path/to/templates/project_config_python.yaml project_config.yaml
```

### Step 3: Customize Configuration

Edit `project_config.yaml` to match your project:

```yaml
project:
  name: "your_project_name"           # REQUIRED: Change this
  type: "r_shiny"                     # REQUIRED: r_shiny | r_analysis | python | mixed
  description: "Your project description"  # REQUIRED: Update this
  owner: "Your Name or Organization"  # REQUIRED: Update this

  principles:
    core_path: "global_scripts/00_principles"       # Default, usually don't change
    local_path: "global_scripts/00_principles_local" # Default, usually don't change
    auto_sync: true

  entities:
    type: "companies"                 # REQUIRED: companies | labs | clients | tools
    list:
      - name: "YourEntity"            # REQUIRED: Update with your entities
        code: "entity_code"
        active: true
        metadata:
          # Add any entity-specific metadata
```

**Key Fields to Update**:
- `project.name`: Your project identifier (lowercase, no spaces)
- `project.description`: Human-readable description
- `project.owner`: Who maintains this project
- `project.entities.type`: Type of entities (companies/labs/tools)
- `project.entities.list`: List your specific entities

### Step 4: Set Up Directory Structure

```bash
# Create global_scripts directory if it doesn't exist
mkdir -p global_scripts

# Create local principles structure
mkdir -p global_scripts/00_principles_local
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles
```

### Step 5: Add Core Principles

**Option A: Using Git Subrepo (Recommended)**

```bash
# Install git-subrepo if not already installed
# macOS:
brew install git-subrepo

# Ubuntu/Debian:
# git clone https://github.com/ingydotnet/git-subrepo /tmp/git-subrepo
# echo "source /tmp/git-subrepo/.rc" >> ~/.bashrc

# Add core principles as subrepo
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles
```

**Option B: Using Git Submodule**

```bash
git submodule add https://github.com/username/00_principles_core.git global_scripts/00_principles
git submodule update --init --recursive
```

**Option C: Manual Copy (Not Recommended)**

```bash
# Clone core principles
git clone https://github.com/username/00_principles_core.git /tmp/00_principles_core

# Copy to your project
cp -r /tmp/00_principles_core/* global_scripts/00_principles/

# Clean up
rm -rf /tmp/00_principles_core
```

### Step 6: Create Local Principles README

```bash
cat > global_scripts/00_principles_local/README.md << 'EOF'
# Local Principles

This directory contains project-specific principles that extend the core 00_principles.

## Structure

- `docs/en/part1_principles/CH08-CH17/`: Project-specific principle chapters
- `parameters_local.yaml`: Local parameter overrides

## Guidelines

- Local principles should reference relevant core principles
- Use `_local` suffix for principle IDs to avoid conflicts
- Do not contradict core principles (CH00-CH07)

## See Also

- Core principles: `../00_principles/`
- Scoping rules: `../00_principles/MIGRATION_GUIDES/PRINCIPLE_SCOPING_RULES.md`
EOF
```

### Step 7: Test Auto-Discovery

**Bash Test**:

```bash
# Should detect your project and display configuration
bash global_scripts/00_principles/utils/detect_project.sh
```

**Expected Output**:
```
[INFO] Detected project at: /path/to/your/project
[INFO] Reading configuration from: /path/to/your/project/project_config.yaml
[INFO] Project detected successfully!

  Project Name:      your_project_name
  Project Type:      r_shiny
  Project Owner:     Your Name
  Project Root:      /path/to/your/project
  Core Principles:   /path/to/your/project/global_scripts/00_principles
  Local Principles:  /path/to/your/project/global_scripts/00_principles_local
```

**R Test**:

```r
source("global_scripts/00_principles/utils/load_config.R")
config <- load_project_config()
print_project_info()
```

**Expected Output**:
```
Detected project at: /path/to/your/project
Loading configuration from: /path/to/your/project/project_config.yaml
Configuration loaded successfully!
  Project: your_project_name (r_shiny)

Project Configuration
=====================

Name:          your_project_name
Type:          r_shiny
Owner:         Your Name
Root:          /path/to/your/project

Principles:
  Core:        /path/to/your/project/global_scripts/00_principles
  Local:       /path/to/your/project/global_scripts/00_principles_local

Entities (companies):
  - YourEntity (entity_code) [active]
```

### Step 8: Create Your First Local Principle

```bash
# Create a project-specific principle chapter
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH08_your_domain

# Create a sample principle
cat > global_scripts/00_principles_local/docs/en/part1_principles/CH08_your_domain/CH08_P001_sample_principle_local.md << 'EOF'
# CH08_P001: Sample Project-Specific Principle

**Type**: Principle
**Chapter**: CH08 (Project-Specific Domain)
**Status**: Active
**Version**: 1.0
**Date**: 2025-10-03

## Extends

- CH03_P015: Modularity
- CH01_R021: One Function One File

## Principle Statement

[Describe your principle here]

## Rationale

[Explain why this principle exists for your project]

## Examples

### Good Example

```r
# Show example following the principle
```

### Bad Example

```r
# Show anti-pattern
```

## Related Principles

- Core: CH03 Development Methodology
- Local: [Other local principles if any]

---

*This is a local principle specific to [your_project_name]*
EOF
```

### Step 9: Update Initialization Scripts (R Projects)

If you have initialization scripts, update them to use project config:

```r
# In your init.R or setup.R
source(file.path("global_scripts", "00_principles", "utils", "load_config.R"))
config <- load_project_config()

# Now you can use project configuration
project_name <- config$project$name
entities <- get_project_entities()

# Load global scripts based on config
global_scripts_path <- file.path(
  config$project$root,
  config$parameters$global_scripts$base_path %||% "global_scripts"
)
```

### Step 10: Commit Changes

```bash
# Add all new files
git add project_config.yaml
git add global_scripts/

# Commit
git commit -m "Add 00_principles architecture

- Add project_config.yaml for project configuration
- Add core principles as subrepo
- Create local principles structure
- Configure auto-discovery
"

# Push (if using remote)
git push origin main
```

---

## Verification Checklist

After setup, verify everything works:

- [ ] `project_config.yaml` exists in project root
- [ ] `global_scripts/00_principles/` contains core principles
- [ ] `global_scripts/00_principles_local/` exists
- [ ] `bash global_scripts/00_principles/utils/detect_project.sh` works
- [ ] Can load config in R: `load_project_config()`
- [ ] Can retrieve entities: `get_project_entities()`
- [ ] Git subrepo is properly configured (if using subrepo)

---

## Common Issues

### Issue 1: "No project_config.yaml found"

**Cause**: Working directory is not within project

**Solution**:
```bash
cd /path/to/your/project  # Navigate to project root
bash global_scripts/00_principles/utils/detect_project.sh
```

### Issue 2: "Core principles directory not found"

**Cause**: Git subrepo not cloned properly

**Solution**:
```bash
# Re-clone the subrepo
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# Or update existing subrepo
git subrepo pull global_scripts/00_principles
```

### Issue 3: "Invalid configuration: project.name is not set"

**Cause**: Configuration file is incomplete

**Solution**:
```bash
# Edit config and ensure required fields are set
vim project_config.yaml

# Verify YAML is valid
python3 -c "import yaml; yaml.safe_load(open('project_config.yaml'))"
```

### Issue 4: YAML parsing fails

**Cause**: Invalid YAML syntax

**Solution**:
```bash
# Install yq for better YAML validation
brew install yq  # macOS
# or
sudo apt install yq  # Ubuntu

# Validate YAML
yq eval '.' project_config.yaml
```

### Issue 5: "Package 'yaml' is required"

**Cause**: R yaml package not installed

**Solution**:
```r
install.packages("yaml")
```

---

## Next Steps

After basic setup:

1. **Read Core Principles**: Review CH00-CH07 in `global_scripts/00_principles/docs/en/part1_principles/`

2. **Define Local Principles**: Create CH08+ chapters for your project-specific needs

3. **Update Documentation**: Document your project's principles in local README

4. **Configure Auto-Sync**: Set up cron job or GitHub Action to sync core principles

5. **Train Team**: Share principle documentation with team members

---

## Project-Specific Guides

### For ai_martech Projects

```bash
# 1. Use ai_martech template
cp templates/project_config_aimartech.yaml project_config.yaml

# 2. Define companies
# Edit entities.list in project_config.yaml

# 3. Create Shiny-specific local principles
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH08_shiny_applications
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH11_etl_pipelines
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH10_marketing_analytics

# 4. Configure bs4Dash defaults
# Edit parameters.bs4dash in project_config.yaml
```

### For Research Projects

```bash
# 1. Use research template
cp templates/project_config_research.yaml project_config.yaml

# 2. Define labs/studies
# Edit entities.list in project_config.yaml

# 3. Create statistical local principles
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH08_statistical_analysis
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH09_psychometrics
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH10_academic_reporting

# 4. Configure IRB and reproducibility settings
# Edit parameters.academic in project_config.yaml
```

### For Python Projects

```bash
# 1. Use python template
cp templates/project_config_python.yaml project_config.yaml

# 2. Define tools/packages
# Edit entities.list in project_config.yaml

# 3. Create Python-specific local principles
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH08_python_packaging
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles/CH09_data_processing

# 4. Configure package metadata
# Edit parameters.packaging in project_config.yaml

# 5. Create Python config loader (if needed)
cp global_scripts/00_principles/utils/load_config.py src/config.py
```

---

## Resources

- **Architecture Document**: `MIGRATION_GUIDES/PROJECT_AGNOSTIC_ARCHITECTURE.md`
- **Scoping Rules**: `MIGRATION_GUIDES/PRINCIPLE_SCOPING_RULES.md`
- **Configuration Templates**: `MIGRATION_GUIDES/templates/`
- **Utility Scripts**: `utils/detect_project.sh`, `utils/load_config.R`

---

## Support

If you encounter issues:

1. Check the [Common Issues](#common-issues) section
2. Review the full architecture document
3. Consult the scoping rules for principle guidance
4. Open an issue in the core principles repository

---

**End of Quick Start Guide**
