# Global Principles Documentation Structure

## Company-Agnostic Design

This principles system applies to all company projects that consume
`scripts/global_scripts/00_principles/`.

When shared via symlinks from standalone repos in `shared/`, this directory appears
inside each company project as:

```text
{tier}/{companyname}/scripts/global_scripts/00_principles/
```

Examples:
- `l1_basic/VitalSigns/scripts/global_scripts/00_principles/`
- `l4_enterprise/MAMBA/scripts/global_scripts/00_principles/`
- `l4_enterprise/kitchenMAMA/scripts/global_scripts/00_principles/`
- `l3_premium/BrandEdge_premium/scripts/global_scripts/00_principles/`

## Primary Entry Points

- Human readers: `NAVIGATION.md`
- AI/LLM readers: `llm/index.yaml`
- Canonical language source: `docs/en/`
- Chinese mirror: `docs/zh/` (helpful reference, but may lag behind English)

## Directory Organization

```text
00_principles/
├── docs/
│   ├── en/
│   │   ├── part1_principles/
│   │   ├── part2_implementations/
│   │   └── part3_domain_knowledge/
│   └── zh/
├── llm/
├── changelog/
├── .claude/
├── INDEX.md
├── NAVIGATION.md
├── QUICK_REFERENCE.md
├── QUICK_REFERENCE_ZH.md
└── README.md
```

## Current Structure

### Part 1: Principles

Principles live under `docs/{lang}/part1_principles/`:

- `CH00_fundamental_principles`
- `CH01_structure_organization`
- `CH02_data_management`
- `CH03_development_methodology`
- `CH04_ui_components`
- `CH05_testing_deployment`
- `CH06_integration_collaboration`
- `CH07_security`
- `CH08_user_experience`
- `CH09_etl_pipelines`

Important:
- `CH07_security` is the only active `CH07` directory
- User experience now lives at `CH08_user_experience`; do not reference it as bare `CH07`
- When referencing files, use the full directory name, not bare chapter numbers

### Part 2: Implementations

Implementation guides live under `docs/{lang}/part2_implementations/`:

- `CH10_database_specifications`
- `CH11_data_flow_architecture`
- `CH12_etl_pipelines`
- `CH13_derivations`
- `CH14_modules_tools`
- `CH15_functions_reference`
- `CH16_apis_external_integration`
- `CH17_connections`
- `CH18_templates_examples`
- `CH19_solutions_patterns`
- `CH20_app_architecture`

### Part 3: Domain Knowledge

Domain knowledge lives under `docs/{lang}/part3_domain_knowledge/`:

- `CH21_marketing_analytics`
- `CH22_statistics`
- `CH23_system_architecture`
- `CH24_ai_assisted_development` (English source currently)

## Naming Conventions

- Principle and rule documents use Quarto files: `.qmd`
- Canonical references use the full ID prefix:
  `MP`, `SO_P`, `SO_R`, `DM_P`, `DM_R`, `DEV_P`, `DEV_R`, `UI_P`, `UI_R`,
  `TD_P`, `TD_R`, `IC_P`, `IC_R`, `SEC_R`, `UX_P`
- Use the real directory name in file paths, for example:
  `CH07_security` rather than ambiguous `CH07`

## Finding Documents

### Human Navigation

Start with:
1. `NAVIGATION.md`
2. `INDEX.md`
3. `QUICK_REFERENCE.md` or `QUICK_REFERENCE_ZH.md`

### Search Examples

```bash
# Find a principle by ID
find docs/en/part1_principles -name "*MP064*"

# Search by topic
rg "translation|locale|UI text" docs/en/part1_principles

# List implementation chapters
find docs/en/part2_implementations -maxdepth 1 -type d | sort
```

## Historical Material

- Active issue and implementation history is stored under `changelog/`
- Older archived principle material may live outside this directory in
  `99_archive/`; do not assume root-level `MP*.md` files still exist here

## Contributor Notes

When the structure changes:
1. Update `NAVIGATION.md` for humans
2. Update `llm/index.yaml` for AI readers
3. Update `README.md`, `INDEX.md`, and quick references so chapter numbers and
   paths stay aligned
4. Avoid hard-coding counts unless they are regenerated as part of the change

---

*Last updated: 2026-03-06*
