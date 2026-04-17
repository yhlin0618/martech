# Migration Guides - Project-Agnostic 00_principles

**Version**: 1.0
**Date**: 2025-10-03
**Status**: Design Specification

---

## Overview

This directory contains the complete redesign of the 00_principles system to be **project-agnostic**, enabling reuse across any project in the che_workspace ecosystem.

## Documents

### 1. Architecture Document
**File**: `PROJECT_AGNOSTIC_ARCHITECTURE.md`

**Purpose**: Complete architectural redesign specification

**Contents**:
- Current problems with hard-coded dependencies
- New multi-project architecture design
- Core + Local principle separation pattern
- Configuration-driven discovery system
- Git Subrepo distribution pattern
- Step-by-step migration guide
- API reference for scripts and configs

**Audience**: Architects, lead developers, principle maintainers

**Read This**: When you need to understand the overall system design

---

### 2. Quick Start Guide
**File**: `QUICKSTART_MIGRATION.md`

**Purpose**: Fast track to adding 00_principles to a new project

**Contents**:
- TL;DR setup (5 commands)
- Step-by-step setup instructions
- Configuration customization guide
- Testing and verification steps
- Common issues and solutions
- Project-specific guides (ai_martech, research, python)

**Audience**: Developers adding principles to a new project

**Read This**: When you want to set up 00_principles in < 30 minutes

---

### 3. Principle Scoping Rules
**File**: `PRINCIPLE_SCOPING_RULES.md`

**Purpose**: Define boundaries between universal and project-specific principles

**Contents**:
- Core vs Local principle types
- Chapter allocation (CH00-CH07 universal, CH08+ local)
- Scoping rules (5 key rules)
- Inheritance and override patterns
- Conflict resolution procedures
- Principle numbering conventions
- Maintenance workflows

**Audience**: Principle authors, developers implementing features

**Read This**: When creating new principles or resolving conflicts

---

## Templates

### Configuration Templates

Located in `templates/`:

1. **`project_config_aimartech.yaml`**
   - For R Shiny marketing applications
   - Includes: Company entities, bs4Dash config, ETL settings
   - Use when: Building Shiny apps with marketing analytics

2. **`project_config_research.yaml`**
   - For R statistical analysis and academic research
   - Includes: Lab entities, IRB settings, reproducibility config
   - Use when: Academic research, statistical modeling

3. **`project_config_python.yaml`**
   - For Python tools, packages, and data science
   - Includes: Tool entities, packaging config, ML settings
   - Use when: Python development, data processing

### Utility Scripts

Located in `utils/`:

1. **`detect_project.sh`**
   - Auto-detects project by finding `project_config.yaml`
   - Exports environment variables
   - Validates configuration
   - Supports: yq, Python, grep fallback

2. **`load_config.R`**
   - Loads project configuration in R
   - Provides convenience functions
   - Sets global options
   - Validates environment variables

---

## Quick Reference

### For New Projects

```bash
# 1. Copy template
cp templates/project_config_{type}.yaml /path/to/project/project_config.yaml

# 2. Customize config
vim /path/to/project/project_config.yaml

# 3. Add core principles
cd /path/to/project
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# 4. Create local structure
mkdir -p global_scripts/00_principles_local/docs/en/part1_principles

# 5. Test
bash global_scripts/00_principles/utils/detect_project.sh
```

### For Existing Projects (Migration)

```bash
# 1. Backup current principles
mv global_scripts/00_principles global_scripts/00_principles_backup

# 2. Add project config
# (Create project_config.yaml at root)

# 3. Add core as subrepo
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles

# 4. Move project-specific principles to local
mv global_scripts/00_principles_backup/docs/en/part1_principles/CH{08..17}* \
   global_scripts/00_principles_local/docs/en/part1_principles/

# 5. Test and validate
```

---

## Key Concepts

### Core Principles (Universal)
- **Location**: `00_principles/` (Git subrepo)
- **Scope**: ALL projects
- **Chapters**: CH00-CH07
- **Maintenance**: Central repository, updated via subrepo pull
- **Examples**: File organization, data management, security

### Local Principles (Project-Specific)
- **Location**: `00_principles_local/` (Project-owned)
- **Scope**: Specific project only
- **Chapters**: CH08+
- **Maintenance**: Each project independently
- **Examples**: Shiny architecture (ai_martech), statistical methods (research)

### Project Configuration
- **File**: `project_config.yaml` at project root
- **Purpose**: Define project metadata, entities, paths
- **Auto-Discovery**: Scripts walk up tree to find config
- **Validation**: Required fields checked on load

---

## Architecture Patterns

### Pattern 1: Core + Local Separation

```
project/
├── project_config.yaml               # Project configuration
├── global_scripts/
│   ├── 00_principles/                # Core (subrepo, read-only)
│   │   ├── docs/en/part1_principles/
│   │   │   ├── CH00_fundamental/     # Universal
│   │   │   ├── CH01_structure/       # Universal
│   │   │   └── ...CH07_security/     # Universal
│   │   └── utils/                    # Auto-discovery scripts
│   └── 00_principles_local/          # Local (project-owned)
│       └── docs/en/part1_principles/
│           ├── CH08_domain_specific/ # Project-specific
│           └── CH09_more_specific/   # Project-specific
```

### Pattern 2: Configuration-Driven Discovery

```r
# R script automatically finds project context
source("global_scripts/00_principles/utils/load_config.R")
config <- load_project_config()  # Auto-detects project_config.yaml

# Access configuration
project_name <- config$project$name
entities <- get_project_entities()
core_path <- get_principle_path("core")
```

### Pattern 3: Git Subrepo Distribution

```bash
# Core principles maintained separately
cd ~/repos/00_principles_core
# Update universal principles (CH00-CH07)

# Distribute to all projects
cd ~/projects/ai_martech
git subrepo pull global_scripts/00_principles

cd ~/projects/research
git subrepo pull global_scripts/00_principles
# All projects now have updated core principles
```

---

## Scoping Rules Summary

1. **Core Principles Are Immutable**: Projects consume core as-is via subrepo
2. **Local Principles Extend, Never Override**: Can specialize but not contradict
3. **Principle Numbering Avoids Collisions**: Local uses `_local` suffix
4. **Local References Core**: Always cite related core principles
5. **Project Type Determines Applicability**: UI principles skip if no UI

---

## Benefits

### For ai_martech
- ✅ Clear separation of universal vs Shiny-specific principles
- ✅ Easier to identify which principles apply to new features
- ✅ Reduced confusion about scope of principles

### For research
- ✅ Reuse universal development principles
- ✅ Add statistical/academic-specific guidance
- ✅ Maintain consistency with other projects

### For python_projects
- ✅ Same core principles as R projects
- ✅ Python-specific extensions clearly scoped
- ✅ Easier cross-language consistency

### For Workspace
- ✅ Single source of truth for universal principles
- ✅ Automatic updates via subrepo sync
- ✅ Reduced duplication and drift
- ✅ Clear ownership (core vs project)

---

## Implementation Roadmap

### Phase 1: Core Repository Setup (Week 1)
- [ ] Create `00_principles_core` repository
- [ ] Extract CH00-CH07 from ai_martech
- [ ] Add auto-discovery utilities
- [ ] Create configuration templates
- [ ] Publish to GitHub

### Phase 2: ai_martech Migration (Week 2)
- [ ] Add `project_config.yaml` to ai_martech
- [ ] Replace `00_principles` with subrepo
- [ ] Move CH08-CH17 to `00_principles_local`
- [ ] Update initialization scripts
- [ ] Test all applications

### Phase 3: Research Project Addition (Week 3)
- [ ] Add `project_config.yaml` to research
- [ ] Clone core principles subrepo
- [ ] Create research-specific local principles
- [ ] Document statistical/academic principles
- [ ] Test analysis workflows

### Phase 4: Python Projects Addition (Week 4)
- [ ] Add `project_config.yaml` to python_projects
- [ ] Clone core principles subrepo
- [ ] Create Python-specific local principles
- [ ] Create Python config loader
- [ ] Test package builds

### Phase 5: Workspace Automation (Week 5)
- [ ] Create `sync_all_projects.sh` script
- [ ] Set up cron job for auto-sync
- [ ] Create GitHub Actions for CI
- [ ] Document maintenance workflows
- [ ] Train team on new system

---

## Maintenance

### Updating Core Principles

```bash
# 1. Update core repository
cd ~/repos/00_principles_core
git checkout main
# Edit CH00-CH07 only
git commit -m "Update CH03: Add functional programming guidance"
git push origin main

# 2. Sync to projects (manual or automated)
cd ~/workspace/projects/ai_martech
git subrepo pull global_scripts/00_principles

cd ~/workspace/projects/research
git subrepo pull global_scripts/00_principles
```

### Updating Local Principles

```bash
# Each project maintains independently
cd ~/workspace/projects/ai_martech
# Edit global_scripts/00_principles_local/
git commit -m "Update CH08: Add Shiny reactivity patterns"
git push
```

### Adding New Project

```bash
# Follow Quick Start Guide
cd ~/workspace/projects/new_project
cp ~/00_principles_core/templates/project_config_template.yaml project_config.yaml
# Edit config
git subrepo clone https://github.com/username/00_principles_core.git global_scripts/00_principles
mkdir -p global_scripts/00_principles_local
```

---

## Support and Resources

### Documentation
- **Architecture**: `PROJECT_AGNOSTIC_ARCHITECTURE.md` (complete design)
- **Quick Start**: `QUICKSTART_MIGRATION.md` (30-min setup)
- **Scoping Rules**: `PRINCIPLE_SCOPING_RULES.md` (principle boundaries)

### Tools
- **Bash**: `utils/detect_project.sh` (project detection)
- **R**: `utils/load_config.R` (config loading)
- **Templates**: `templates/*.yaml` (project configs)

### Community
- **GitHub Issues**: Report bugs, request features
- **Discussions**: Ask questions, share patterns
- **Pull Requests**: Contribute improvements

---

## FAQ

### Q: Do I need to migrate existing projects immediately?

A: No. Existing projects can continue using their current 00_principles setup. Migrate when ready or when starting new projects.

### Q: Can I use this without Git Subrepo?

A: Yes. You can use Git Submodules or manual copying, but subrepo is recommended for easier updates.

### Q: What if my project doesn't fit the templates?

A: Templates are starting points. Customize `project_config.yaml` to match your needs. The schema is flexible.

### Q: Can I have both core and local principles for the same chapter?

A: No. CH00-CH07 are reserved for core. CH08+ are for local. This prevents conflicts.

### Q: How do I propose a change to core principles?

A: Open an issue or PR in the `00_principles_core` repository. Changes should be universally applicable.

### Q: What if local principle contradicts core?

A: This violates scoping rules. Either revise local principle or propose core amendment. See `PRINCIPLE_SCOPING_RULES.md`.

---

## Version History

| Version | Date       | Changes                                      |
|---------|------------|----------------------------------------------|
| 1.0     | 2025-10-03 | Initial release of project-agnostic design  |

---

**End of Migration Guides README**
