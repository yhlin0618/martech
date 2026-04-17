# handbook-layer Specification

## Purpose

TBD - created by archiving change 'add-handbook-penta-track'. Update Purpose after archive.

## Requirements

### Requirement: Handbook Layer is a Git Submodule

The system SHALL provide a git submodule at `shared/handbook/` as Track 5 of the MP122 Penta-Track Subrepo Architecture.

#### Scenario: Cloning l4_enterprise includes handbook

- **WHEN** a developer clones `l4_enterprise` with `git clone --recurse-submodules`
- **THEN** the directory `shared/handbook/` exists and is populated with the handbook repository contents

#### Scenario: .gitmodules declares handbook entry

- **WHEN** the `.gitmodules` file at `l4_enterprise` root is inspected
- **THEN** it contains a `[submodule "shared/handbook"]` section with a `url` field pointing to the handbook GitHub repository


<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->

---
### Requirement: Handbook Uses Private GitHub Repository

The handbook repository SHALL be hosted as a private repository on GitHub under the `kiki830621` account, consistent with all existing submodules in the l4_enterprise project.

#### Scenario: Repository visibility is private

- **WHEN** the handbook repository metadata is queried via `gh repo view kiki830621/ai_martech_handbook --json visibility`
- **THEN** the returned `visibility` field is `PRIVATE`


<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->

---
### Requirement: Handbook Targets Interns and New Staff

The handbook SHALL declare interns and new staff as its primary audience in its root `README.md`.

#### Scenario: README declares audience explicitly

- **WHEN** `handbook/README.md` is read
- **THEN** it contains an explicit audience statement identifying interns and new staff (not senior engineers, not customers, not business stakeholders)


<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->

---
### Requirement: Content is Operational Guidance Only

Handbook content SHALL be limited to operational guidance — that is, step-by-step instructions for executing common development tasks (git workflow, running pipelines, debugging procedures, onboarding milestones). Handbook content SHALL NOT include architectural rationale, framework code internals, or business terminology definitions.

#### Scenario: No framework code internals

- **WHEN** any handbook document is reviewed for content type
- **THEN** it MUST NOT contain direct references to internal R function source paths inside `shared/global_scripts/` nor expose framework-internal implementation details

#### Scenario: Content describes HOW not WHY

- **WHEN** a handbook document describes a practice
- **THEN** it MUST describe concrete steps, commands, and expected outputs rather than the architectural reasoning behind the practice (reasoning belongs to `00_principles/docs/`)


<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->

---
### Requirement: Content is Non-Overlapping with Existing Documentation Systems

Handbook content SHALL NOT duplicate content from `shared/global_scripts/00_principles/docs/` (Quarto principles) or `shared/global_scripts/00_principles/docs/wiki/` (GitHub Wiki for dashboard terminology).

#### Scenario: No principle text copied verbatim

- **WHEN** handbook content is compared against MP, P, or R principle `.qmd` files
- **THEN** no principle rule text, rationale, or example is copy-pasted into the handbook

#### Scenario: No dashboard term copied verbatim

- **WHEN** handbook content is compared against GitHub Wiki `Term-*.md` files
- **THEN** no dashboard term definition, formula, or example is duplicated into the handbook


<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->

---
### Requirement: Uses Pure Markdown Without Build System

The handbook SHALL consist of plain markdown files rendered directly by GitHub's native markdown renderer. It SHALL NOT depend on any site generator (Quarto, MkDocs, Docusaurus, GitHub Pages build, or equivalent).

#### Scenario: No build configuration files present

- **WHEN** the handbook root directory is inspected
- **THEN** it MUST NOT contain `_quarto.yml`, `mkdocs.yml`, `docusaurus.config.js`, `package.json` for a site generator, or any equivalent build configuration file

#### Scenario: Direct GitHub rendering works

- **WHEN** a handbook markdown file is opened in the GitHub web interface
- **THEN** it renders correctly without requiring any build, preprocessing, or external tooling


<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->

---
### Requirement: Initial Directory Structure

The handbook SHALL contain a defined initial directory structure comprising two root-level meta files and three topical category directories.

#### Scenario: Required root files exist

- **WHEN** the handbook repository root is inspected
- **THEN** both `README.md` and `CONTRIBUTING.md` MUST exist at the root

#### Scenario: Required category directories exist

- **WHEN** the handbook repository root is inspected
- **THEN** three directories MUST exist: `coding-standards/`, `workflows/`, `onboarding/`


<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->

---
### Requirement: Handbook is Declared as Track 5 in MP122

The MP122 meta-principle SHALL declare Handbook Layer as the fifth track of the Penta-Track Subrepo Architecture across all three synchronization layers (per DOC_R009).

#### Scenario: MP122 .qmd file lists five tracks

- **WHEN** `shared/global_scripts/00_principles/docs/en/part1_principles/CH00_fundamental_principles/02_structure_organization/MP122_penta_track_subrepo_architecture.qmd` is read
- **THEN** it enumerates five tracks: Framework Layer, Scripts Layer, Language Layer, Configuration Layer, Handbook Layer

#### Scenario: llm yaml index reflects five tracks

- **WHEN** the MP122 entry in `shared/global_scripts/00_principles/llm/CH00_meta.yaml` is inspected
- **THEN** the `rule_formal` field references `five_tracks` and lists `handbook` as one of the tracks

#### Scenario: .claude rules reference Penta-Track

- **WHEN** `shared/global_scripts/00_principles/.claude/rules/04-pipeline.md` is inspected
- **THEN** any reference to MP122 MUST use the Penta-Track naming (not Quad-Track)


<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->

---
### Requirement: Readable Without Framework Knowledge

The handbook SHALL be comprehensible by readers who have no prior knowledge of the l4_enterprise framework code, principles system, or internal architecture.

#### Scenario: Framework terminology is explained inline

- **WHEN** a handbook document uses framework-specific terminology such as "DRV", "ETL phase", or "DuckDB layer"
- **THEN** the term MUST be explained inline on first use, or linked to a glossary entry within the handbook itself (not to external principles documentation)

#### Scenario: No assumed prior knowledge

- **WHEN** a reviewer with zero framework knowledge reads any onboarding document
- **THEN** the document MUST be understandable using only the handbook's own content plus widely known tools (git, bash, GitHub, R basics)

<!-- @trace
source: add-handbook-penta-track
updated: 2026-04-12
code:
  - .claude
  - .agents/skills/spectra-apply/SKILL.md
  - MAMBA
  - shared/nsql
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-ask/SKILL.md
  - CLAUDE.md
  - shared/handbook
  - .agents/skills/spectra-audit/SKILL.md
  - .agents/skills/spectra-propose/SKILL.md
  - AGENTS.md
  - QEF_DESIGN
  - .agents/skills/spectra-ingest/SKILL.md
  - .gitmodules
  - shared/update_scripts
  - .agents/skills/spectra-debug/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .spectra.yaml
  - .agents/skills/spectra-discuss/SKILL.md
-->