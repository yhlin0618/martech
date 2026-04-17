# AI MarTech Principles Navigation

This is the main human-facing entry point for the active principles system.

## Start Here

### For AI Agents

Read `llm/index.yaml` first.

Recommended flow:
1. Read `llm/index.yaml`
2. Read `llm/CH00_meta.yaml`
3. Follow the scenario mapping in `llm/index.yaml` for additional chapter files

### For Human Developers

Start with this file, then jump to the relevant chapter below.

## Quick Start

### Core Principles to Know

| Priority | ID | Name | One-liner |
|----------|----|------|-----------|
| 1 | MP029 | No Fake Data | Never generate fake or placeholder business data in production flows |
| 2 | MP064 | ETL-Derivation Separation | ETL prepares data; derivations contain business logic |
| 3 | MP108 | ETL Phase Sequence | ETL phases follow 0IM → 1ST → 2TR |
| 4 | DM_R041 | ETL Directory Structure | ETL and DRV files must live in the expected directory layout |
| 5 | SO_R007 | One Function One File | Each function lives in its own file |
| 6 | UI_P004 | Component N-Tuple Pattern | UI components are organized as UI + Server + Defaults |
| 7 | UI_R001 | UI-Server-Defaults N-Tuple | Apply the concrete Shiny module naming and file pattern |
| 8 | UI_R022 | UI Text Translation Pattern | UI text must follow the translation dictionary pattern |
| 9 | IC_R008 | GitHub Issue Scope Governance | Active issue tracking must use the shared GitHub repo with scope labels |

## Find Principles by Scenario

### Building ETL

Read:
- `MP064`
- `MP108`
- `DM_R041`
- `CH11_etl.yaml` in `llm/` for implementation guides

### Building Derivations

Read:
- `MP064`
- `DM_R042`
- `DM_R044`
- `CH12_derivations.yaml` in `llm/`

### UI / Shiny Work

Read:
- `UI_P004`
- `UI_R001`
- `UI_R022`
- `UX_P001` / `UX_P002` when startup or rendering performance matters

### Security / Credentials

Read:
- `CH07_security`
- `SEC_R001`
- `SEC_R002`
- `SEC_R003`

### Issue Tracking / Collaboration

Read:
- `CH06_integration_collaboration`
- `IC_R007`
- `IC_R008`

## Directory Map

### Part 1: Principles

| Directory | Scope |
|-----------|-------|
| `CH00_fundamental_principles` | Meta-principles |
| `CH01_structure_organization` | Structure and organization |
| `CH02_data_management` | Data management |
| `CH03_development_methodology` | Development methodology |
| `CH04_ui_components` | UI principles and rules |
| `CH05_testing_deployment` | Testing and deployment |
| `CH06_integration_collaboration` | Integration and collaboration |
| `CH07_security` | Security rules |
| `CH08_user_experience` | UX principles |
| `CH09_etl_pipelines` | ETL-specific rules |

Important:
- `CH07_security` is the only active `CH07` directory
- User experience now lives at `CH08_user_experience`
- Use the full directory name in file paths and references

### Part 2: Implementations

| Directory | Scope |
|-----------|-------|
| `CH10_database_specifications` | Database specifications |
| `CH11_data_flow_architecture` | Data flow architecture |
| `CH12_etl_pipelines` | ETL implementation guides |
| `CH13_derivations` | Derivation workflows |
| `CH14_modules_tools` | Utility modules |
| `CH15_functions_reference` | Function reference |
| `CH16_apis_external_integration` | API integration |
| `CH17_connections` | Component connections |
| `CH18_templates_examples` | Templates and examples |
| `CH19_solutions_patterns` | Proven solution patterns |
| `CH20_app_architecture` | App architecture |

### Part 3: Domain Knowledge

| Directory | Scope |
|-----------|-------|
| `CH21_marketing_analytics` | Marketing methodology |
| `CH22_statistics` | Statistical concepts |
| `CH23_system_architecture` | System architecture paradigms |
| `CH24_ai_assisted_development` | AI-assisted development principles (English source currently) |

## File Location Summary

```text
00_principles/
├── NAVIGATION.md
├── INDEX.md
├── README.md
├── QUICK_REFERENCE.md
├── QUICK_REFERENCE_ZH.md
├── llm/
│   ├── index.yaml
│   ├── CH00_meta.yaml
│   ├── CH01_structure.yaml
│   ├── CH02_data.yaml
│   ├── CH03_development.yaml
│   ├── CH04_ui.yaml
│   ├── CH05_testing.yaml
│   ├── CH06_ic.yaml
│   └── CH07_ux.yaml
└── docs/
    └── en/
        ├── part1_principles/
        ├── part2_implementations/
        └── part3_domain_knowledge/
```

## FAQ

### Do I need to read everything?

No. Start with:
1. `llm/index.yaml` if you are an agent
2. The relevant chapter directory for your task
3. The specific `.qmd` file by ID

### English or Chinese?

Use `docs/en/` as the source of truth.
Use `docs/zh/` as a mirror/reference when helpful.

### Where is the LLM entry point?

It is `llm/index.yaml`.
Do not use the old `PRINCIPLES_LLM/` name in new documentation.

### How do I add or reorganize chapters?

When chapter structure changes:
1. Update `README.md`
2. Update `INDEX.md`
3. Update `NAVIGATION.md`
4. Update `QUICK_REFERENCE_ZH.md` if the change affects Chinese navigation
5. Update `llm/index.yaml`

---

*Last Updated: 2026-03-06*
