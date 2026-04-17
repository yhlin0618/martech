# company-examples-cookbook Specification

## Purpose

TBD - created by archiving change 'add-company-examples-cookbook'. Update Purpose after archive.

## Requirements

### Requirement: Chapter 29 SHALL Exist as Cookbook for Company-Specific Code

The system SHALL provide a directory `shared/global_scripts/29_company_examples/` that serves as a cookbook for company-specific code, lessons-learned notes, and onboarding templates. The chapter SHALL coexist with the generic numbered chapters (00-28, 30+) without altering their generic semantics.

#### Scenario: Chapter 29 directory exists

- **WHEN** a developer lists `shared/global_scripts/`
- **THEN** a directory named `29_company_examples` SHALL be present
- **AND** it SHALL contain at minimum a `README.md` and a `_template/` subdirectory

#### Scenario: Chapter 29 README explains cookbook semantics

- **WHEN** a developer reads `29_company_examples/README.md`
- **THEN** the document SHALL state that this chapter is a cookbook (read-and-adapt) and not a shared library (import-and-reuse)
- **AND** it SHALL list the existing company namespaces and their READMEs


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: Each Company SHALL Have Its Own Namespace Directory

The chapter SHALL contain one subdirectory per onboarded company, named with the lowercase company code (e.g., `mamba/`, `qef_design/`, `d_racing/`). Each company subdirectory SHALL be self-contained — code, notes, and README within its own namespace.

#### Scenario: MAMBA namespace exists with its content

- **WHEN** a developer lists `29_company_examples/mamba/`
- **THEN** the directory SHALL contain at minimum `README.md` and `02_db_utils/`
- **AND** the `02_db_utils/` subdirectory SHALL contain `fn_ensure_tunnel.R` and `fn_ensure_tunnel_enhanced.R`

#### Scenario: Company namespace name uses lowercase company code

- **WHEN** a new company namespace is created
- **THEN** the directory name SHALL be the lowercase form of the company code (e.g., `MAMBA` → `mamba`)


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: Company Namespace Internal Structure SHALL Mirror Numbered Chapters

Inside a company namespace, code files SHALL be organized into subdirectories whose names mirror the root-level numbered chapter directories (e.g., `02_db_utils/`, `04_utils/`, `08_ai/`). A file at `29_company_examples/mamba/02_db_utils/fn_x.R` SHALL conceptually correspond to the generic location `02_db_utils/fn_x.R`.

#### Scenario: Mirrored directory naming

- **WHEN** a MAMBA-specific replacement for a function in `02_db_utils/` is added
- **THEN** the file SHALL live in `29_company_examples/mamba/02_db_utils/`
- **AND** SHALL NOT be placed in a flat `mamba/` directory

#### Scenario: Empty mirrored directories not created

- **WHEN** a company namespace has no files for a given chapter (e.g., MAMBA has no special `04_utils/` files)
- **THEN** the corresponding mirrored subdirectory SHALL NOT be created (avoid empty directories)


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: Each Company Namespace SHALL Have a README

Every company subdirectory SHALL contain a `README.md` describing the company's special characteristics, environment dependencies, known issues, and overview of files in this namespace.

#### Scenario: README content sections

- **WHEN** a developer reads `29_company_examples/mamba/README.md`
- **THEN** the document SHALL contain sections describing:
  - Brand and business context
  - Special environment (MSSQL via SSH tunnel, ERP integration, etc.)
  - Known schema drift or quirks (referencing GitHub issues such as #371, #373)
  - Overview of files in the namespace and their purpose

#### Scenario: README required for new companies

- **WHEN** a new company namespace is created
- **THEN** a `README.md` SHALL be created in the namespace before any code files are added


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: Notes Subdirectory SHALL Use Dated Filenames

A `notes/` subdirectory MAY exist within each company namespace for lessons-learned documents. Notes SHALL use the filename pattern `YYYY-MM-DD_topic.md` to preserve chronological ordering and align with GitHub Issue creation dates.

#### Scenario: Notes filename format

- **WHEN** a lessons-learned document is added for an event on 2026-04-13 about Supabase schema drift
- **THEN** the file SHALL be named `2026-04-13_supabase_schema_drift.md`
- **AND** SHALL be placed in `29_company_examples/{company}/notes/`


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: MAMBA-Specific db Helpers SHALL Be Migrated from Generic Chapter

The files `02_db_utils/fn_ensure_mamba_tunnel.R` and `02_db_utils/fn_ensure_mamba_tunnel_enhanced.R` SHALL be moved from the generic `02_db_utils/` chapter to `29_company_examples/mamba/02_db_utils/`. The new filenames SHALL drop the `mamba_` prefix because the namespace already encodes company identity.

#### Scenario: Original files removed from generic chapter

- **WHEN** a developer lists `shared/global_scripts/02_db_utils/`
- **THEN** the files `fn_ensure_mamba_tunnel.R` and `fn_ensure_mamba_tunnel_enhanced.R` SHALL NOT be present

#### Scenario: Renamed files exist in cookbook

- **WHEN** a developer lists `29_company_examples/mamba/02_db_utils/`
- **THEN** the files `fn_ensure_tunnel.R` and `fn_ensure_tunnel_enhanced.R` SHALL be present
- **AND** their content SHALL be functionally equivalent to the originals

#### Scenario: All source() references updated

- **WHEN** any R script invokes `source(...)` for the moved files
- **THEN** the path SHALL refer to the new location under `29_company_examples/mamba/02_db_utils/`
- **AND** no script SHALL still reference the old path under generic `02_db_utils/`


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: Template Directory SHALL Provide Onboarding Skeleton

A `_template/` subdirectory SHALL exist under chapter 29 containing a minimal starter set for new companies: a placeholder `README.md` with required section headings, an empty `notes/` directory marker, and a placeholder `02_db_utils/` marker.

#### Scenario: Template README has placeholder sections

- **WHEN** a developer reads `29_company_examples/_template/README.md`
- **THEN** the file SHALL contain placeholder section headings for: Brand info, Special environment, Known issues, File overview
- **AND** SHALL include a TODO comment indicating which sections must be filled by new company onboarders

#### Scenario: Template provides notes directory marker

- **WHEN** a developer lists `29_company_examples/_template/`
- **THEN** the directory SHALL contain a `notes/` subdirectory (may be empty or contain `.gitkeep`)


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: SO_P018 Governance SHALL Permit Chapter 29

The `SO_P018_governance_spec.yaml` file SHALL include `29_company_examples` in the list of allowed chapter directories under `shared/global_scripts/`. The textual rule documents SHALL describe the chapter's cookbook semantics.

#### Scenario: SO_P018 spec includes chapter 29

- **WHEN** a developer reads `00_principles/docs/en/part1_principles/CH01_structure_organization/principles/SO_P018_governance_spec.yaml`
- **THEN** the allowed-directory list SHALL contain `29_company_examples`
- **AND** the explanatory text SHALL note its cookbook (read-and-adapt) semantics

#### Scenario: Three-layer sync completed

- **WHEN** the SO_P018 spec is updated to include chapter 29
- **THEN** in the same change, `00_principles/llm/CH01_structure.yaml` SHALL be updated to reflect the new chapter
- **AND** `00_principles/.claude/rules/07-directory-governance.md` SHALL be updated with the new chapter and its semantics


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: /new-company Skill SHALL Auto-Create Company Namespace

The `/new-company` skill at `.claude/skills/new-company/SKILL.md` SHALL include a step that copies `29_company_examples/_template/` into a new directory `29_company_examples/{lowercase_company_code}/` and prompts the user to fill the README placeholder sections.

#### Scenario: New company skill creates namespace

- **WHEN** the `/new-company` skill is invoked for a new company "ACME"
- **THEN** the skill SHALL create directory `29_company_examples/acme/` by copying `29_company_examples/_template/`
- **AND** the skill SHALL prompt the user to populate the placeholder README sections before completing onboarding

#### Scenario: Existing company namespace not overwritten

- **WHEN** the `/new-company` skill is invoked for a company whose namespace already exists in chapter 29
- **THEN** the skill SHALL detect the existing directory and SHALL NOT overwrite it
- **AND** the skill SHALL inform the user the namespace already exists


<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->

---
### Requirement: Cookbook Code SHALL NOT Be Sourced by Other Companies

Code files inside a company namespace (e.g., `29_company_examples/mamba/...`) SHALL NOT be `source()`-d by R scripts belonging to other companies. The cookbook is read-and-adapt, not import-and-reuse. Sharing code across companies requires promoting the helper to a generic chapter through a separate refactor.

#### Scenario: Cross-company source() reference is forbidden

- **WHEN** a developer adds an R script for company QEF_DESIGN
- **THEN** the script SHALL NOT include `source(".../29_company_examples/mamba/...")`
- **AND** if the QEF_DESIGN script needs similar functionality, the code SHALL be copied (with attribution comment) into `29_company_examples/qef_design/` or promoted to a generic chapter

<!-- @trace
source: add-company-examples-cookbook
updated: 2026-04-13
code:
  - .agents/skills/spectra-discuss/SKILL.md
  - CLAUDE.md
  - shared/update_scripts
  - .agents/skills/spectra-propose/SKILL.md
  - shared/handbook
  - .agents/skills/spectra-apply/SKILL.md
  - .agents/skills/spectra-debug/SKILL.md
  - .playwright-mcp/console-2026-03-06T00-49-10-858Z.log
  - .agents/skills/spectra-ingest/SKILL.md
  - .agents/skills/spectra-ask/SKILL.md
  - .claude
  - AGENTS.md
  - QEF_DESIGN
  - .spectra.yaml
  - .playwright-mcp/console-2026-03-06T00-49-19-181Z.log
  - .agents/skills/spectra-audit/SKILL.md
  - shared/global_scripts
  - .agents/skills/spectra-archive/SKILL.md
  - MAMBA
  - shared/nsql
-->