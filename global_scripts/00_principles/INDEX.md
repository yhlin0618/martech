# Principles Index

> **Updated: 2026-03-06**
>
> **Recent Changes:**
> - 2026-03-06: Renumbered active docs chapters to remove CH07 collisions and synced downstream references
> - 2026-02-28: Added IC_R008 under CH06 Integration & Collaboration

This index reflects the current active documentation structure.

## Entry Points

- Human navigation: `NAVIGATION.md`
- AI/LLM navigation: `llm/index.yaml`
- English source of truth: `docs/en/`
- Chinese mirror: `docs/zh/`

## Current Active Structure

### Part 1: Principles

```text
docs/en/part1_principles/
├── CH00_fundamental_principles/
├── CH01_structure_organization/
├── CH02_data_management/
├── CH03_development_methodology/
├── CH04_ui_components/
├── CH05_testing_deployment/
├── CH06_integration_collaboration/
├── CH07_security/
├── CH08_user_experience/
└── CH09_etl_pipelines/
```

Important:
- `CH07_security` is the only active `CH07` directory
- User experience now lives at `CH08_user_experience`
- Use the full directory name in paths and references; do not write bare chapter numbers

### Part 2: Implementations

```text
docs/en/part2_implementations/
├── CH10_database_specifications/
├── CH11_data_flow_architecture/
├── CH12_etl_pipelines/
├── CH13_derivations/
├── CH14_modules_tools/
├── CH15_functions_reference/
├── CH16_apis_external_integration/
├── CH17_connections/
├── CH18_templates_examples/
├── CH19_solutions_patterns/
└── CH20_app_architecture/
```

### Part 3: Domain Knowledge

```text
docs/en/part3_domain_knowledge/
├── CH21_marketing_analytics/
├── CH22_statistics/
├── CH23_system_architecture/
└── CH24_ai_assisted_development/
```

Note:
- `CH24_ai_assisted_development` currently exists in `docs/en/` only

## What This File Does Not Do

- It does not maintain a root-level `MP001-MP030` file list
- It does not treat old root `MP*.md` paths as active
- It does not guarantee hard-coded counts stay current

If you need exact live inventory, inspect `docs/` directly.

## Search Tips

### Find by ID

```bash
find docs/en/part1_principles -name "*UI_R022*"
find docs/en/part1_principles -name "*MP064*"
```

### Find by Topic

```bash
rg "translation|locale|language fallback" docs/en/part1_principles
rg "ETL|0IM|1ST|2TR" docs/en/part1_principles docs/en/part2_implementations
```

### Find LLM Chapter Guides

```bash
ls llm
```

## Historical Material

- Active implementation history lives in `changelog/`
- Older archived material may live in `99_archive/`
- Do not rely on historical paths unless you are explicitly auditing legacy material
