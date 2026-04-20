# AI MarTech Principles Quick Reference

> **For Claude Code**: This is your primary lookup index for the AI MarTech principles system.
>
> **Total Principles**: 351 principle files (English) | 197 (Chinese mirror)
>
> **Updated: 2026-03-06**
>
> **Note**: Chapter ranges and paths below are current; category counts may lag the live inventory.
>
> | Category | Count | ID Pattern |
> |----------|-------|------------|
> | Meta-Principles | 134 | MP001-MP142 |
> | Structure Organization Rules | 35 | SO_R001-SO_R035 |
> | Structure Organization Principles | 19 | SO_P001-SO_P019 |
> | Data Management Rules | 51 | DM_R001-DM_R051 |
> | Data Management Principles | 6 | DM_P001-DM_P006 |
> | Development Rules | 36 | DEV_R001-DEV_R036 |
> | Development Principles | 21 | DEV_P001-DEV_P021 |
> | UI Component Rules | 22 | UI_R001-UI_R024 |
> | UI Component Principles | 11 | UI_P001-UI_P011 |
> | Testing/Deployment Rules | 5 | TD_R001-TD_R005 |
> | Testing/Deployment Principles | 3 | TD_P001-TD_P003 |
> | Security Rules | 3 | SEC_R001-SEC_R003 |
> | ETL Pipeline Rules | 5 | R116-R120 |
> | Integration/Collaboration Rules | 6 | IC_R001-IC_R009 |
> | NSQL Extensions | 2 | NSQL_EXT01-EXT02 |
> | Terminology Rules | 1 | TS_R003 |

---

## 🚀 Quick Start for Claude

### When to Use This Reference

**BEFORE any architectural change:**
1. Search this file for relevant principle numbers
2. Read the principle details in `docs/en/part1_principles/`
3. Verify your approach aligns with principles
4. Document which principles you're following

**Common Workflows:**
- **New feature** → Check MP029 (No Fake Data), DM_R044 (Derivation Standards)
- **ETL work** → Check MP064, MP108, DM_R028, DM_R041-R047
- **UI components** → Check UI_R001-R024, MP017, MP025
- **Database** → Check DM_R001-R027, MP052-MP062
- **Testing** → Check MP047, TD_R001-R005

### How to Navigate

1. **By Number**: Use Ctrl+F to search "MP029", "DM_R041", etc.
2. **By Topic**: Browse topic sections below (ETL, Naming, Testing, etc.)
3. **By Scenario**: Check "Common Scenarios" section
4. **By Chapter**: Follow chapter organization matching directory structure

---

## 📑 Table of Contents

1. [Top 20 Most Critical Principles](#top-20-most-critical-principles)
2. [Quick Lookup by Number](#quick-lookup-by-number)
   - [Meta-Principles (MP001-MP136)](#meta-principles-mp001-mp136)
   - [Structure Organization (SO_R001-SO_R035)](#structure-organization-so_r001-so_r035)
   - [Data Management (DM_R001-DM_R048)](#data-management-dm_r001-dm_r048)
   - [Development (DEV_R001-DEV_R036)](#development-dev_r001-dev_r036)
   - [UI Components (UI_R001-UI_R024)](#ui-components-ui_r001-ui_r024)
   - [Testing/Deployment (TD_R001-TD_R005)](#testingdeployment-td_r001-td_r005)
   - [Security (SEC_R001-SEC_R003)](#security-sec_r001-sec_r003)
3. [Topic-Based Index](#topic-based-index)
4. [Common Scenarios](#common-scenarios)
5. [Principle Relationships](#principle-relationships)
6. [Part 2: Implementations (CH10-CH20)](#-part-2-implementations-ch10-ch20)
7. [Part 3: Domain Knowledge (CH21-CH24)](#-part-3-domain-knowledge-ch21-ch24)

---

## 🔥 Top 20 Most Critical Principles

These principles are referenced most frequently and have the highest impact:

| Rank | ID | Title | Why Critical | When to Use |
|------|-----|-------|--------------|-------------|
| 1 | **MP029** | No Fake Data | MANDATORY for all data operations | Every data creation/modification |
| 2 | **MP064** | ETL/Derivation Separation | Core architecture principle | Any ETL or derivation work |
| 3 | **MP108** | ETL Phase Sequence | Defines ETL pipeline structure | Building/modifying ETL |
| 4 | **DM_R041** | ETL Directory Structure | File organization standard | Creating ETL scripts |
| 5 | **DM_R044** | Derivation Implementation | How to write derivations | Writing D*.R scripts |
| 6 | **MP071** | Type-Prefix Naming | Naming convention foundation | Naming any code entity |
| 7 | **SO_R007** | One Function One File | Code organization core | Creating R functions |
| 8 | **DM_R002** | Universal Data Access (tbl2) | Database access pattern | All database reads |
| 9 | **MP012** | Change Tracking | Documentation requirement | Any code change |
| 10 | **UI_R001** | UI-Server-Defaults Triple | Shiny module structure | Building UI components |
| 11 | **MP018** | Functor-Module Correspondence | Module organization | Creating new modules |
| 12 | **DEV_R022** | Module Data Connection | Data flow pattern | Passing data to modules |
| 13 | **MP054** | No Fake Data (Data Mgmt) | Reinforces MP029 | Data validation |
| 14 | **DM_R028** | ETL Data Type Separation | ETL/DRV distinction | ETL architecture |
| 15 | **SO_R030** | Operational Docs Location | Where to put reports | Creating documentation |
| 16 | **MP097** | Principle-Implementation Separation | System organization | Understanding structure |
| 17 | **DM_R047** | Multi-Platform Sync | Cross-platform consistency | Multi-platform features |
| 18 | **MP136** | Configuration-Init Pattern | App initialization | App startup code |
| 19 | **UI_R019** | AI Process Notification | UX for long processes | OpenAI/async operations |
| 20 | **DEV_R036** | ShinyJS Module Namespace | Shiny module best practice | Using shinyjs in modules |

---

## 📋 Quick Lookup by Number

### Meta-Principles (MP001-MP136)

**Foundation & System Architecture (MP001-MP008)**
- **MP001**: Axiomatization System - Principle hierarchy and foundation
- **MP002**: Primitive Terms/Definitions - Core terminology
- **MP003**: Structural Blueprint - System architecture framework
- **MP004**: Sensible Defaults - Default behavior principle
- **MP005**: Statute Law Analogy - Principle interpretation
- **MP006**: Parsimony - Simplicity principle
- **MP007**: Cognitive Distinction - Clear mental models
- **MP008**: Replicability Principle - Reproducible workflows

**Structure Organization (MP009-MP026)**
- **MP009**: Default Deny - Security-first approach
- **MP010**: Operating Modes - Dev/Prod mode system
- **MP011**: Documentation Organization - Doc structure
- **MP012**: Change Tracking - CHANGELOG requirements ⭐
- **MP013**: Currency Principle - Data freshness
- **MP014**: Modularity - Component independence
- **MP015**: Package Consistency - External package standards
- **MP016**: Concept Documents - Abstract documentation
- **MP017**: Config-Driven UI Composition - YAML-based UI
- **MP018**: Functor-Module Correspondence - Module naming ⭐
- **MP019**: Neighborhood Principle - Related code proximity
- **MP020**: UI-Server Correspondence - Shiny structure
- **MP021**: Computation Allocation - Where to compute
- **MP022**: Connected Component Principle - Dependency management
- **MP023**: Package Documentation - External package docs
- **MP024**: App Dynamics - Reactive programming
- **MP025**: UI Separation - UI/logic separation
- **MP026**: Interactive Visualization Preference - Plotly over static

**Development Methodology (MP027-MP051)**
- **MP027**: Construction Methodology - How to build
- **MP028**: Instance vs Principle - Concrete vs abstract
- **MP029**: Discrepancy Principle (No Fake Data) - CRITICAL ⭐⭐⭐
- **MP030**: Company-Centered Design - Multi-tenant architecture
- **MP031**: Separation of Concerns - Functional boundaries
- **MP032**: Don't Repeat Yourself - Code reuse
- **MP033**: Avoid Self-Reference - No circular dependencies
- **MP034**: Archive Immutability - Archives are read-only
- **MP035**: Vectorization Principle - Prefer vectorized ops
- **MP036**: Initialization First - Init before use
- **MP037**: Principle-Guided Modifications - Change process
- **MP038**: Deinitialization Final - Cleanup pattern
- **MP039**: Comment Only Temporary/Uncertain - When to comment
- **MP040**: Incremental Single Feature Release - Release strategy
- **MP041**: One Time at Start - Initialization timing
- **MP042**: Deterministic Codebase Transformations - Reproducible changes
- **MP043**: Runnable First - Code must work before optimization
- **MP044**: Functional Programming - FP patterns preferred
- **MP045**: Universal Initialization - Standard init pattern
- **MP046**: Debug Code Tracing - Debugging methodology
- **MP047**: Test Data Design - How to create test data ⭐
- **MP048**: Feedback Loop - User feedback integration
- **MP049**: App Dynamics - (duplicate?) Application behavior
- **MP050**: Root Cause Resolution - Fix causes not symptoms
- **MP051**: Explicit Parameter Specification - No implicit params

**Data Management (MP052-MP065)**
- **MP052**: Data Source Hierarchy - Data priority order
- ~~MP053~~: → **DM_P007** Information Flow Transparency - Data lineage
- **MP054**: No Fake Data - Reinforces MP029 ⭐⭐⭐
- **MP055**: All-Category Special Treatment - Handle "All" option
- **MP056**: Null Special Treatment - NULL handling
- **MP057**: Database Documentation - DB schema docs
- **MP058**: Automatic Data Availability Detection - Dynamic data checking
- **MP059**: Unidirectional Data Flow - Reactive data flow
- **MP060**: Database Table Creation Strategy - Table design
- **MP061**: Database Synchronization - Multi-DB sync
- **MP062**: Key Selection Principle - Primary key standards
- **MP063**: Data Processing Trinity - ETL + Derivation + Application
- **MP064**: ETL/Derivation Separation - CRITICAL architecture ⭐⭐⭐
- **MP065**: Platform Configuration Management - Multi-platform config

**Terminology Standards (MP063-MP082)**
- **MP063**: Terminology Axiomatization - Term definitions
- **MP064**: Principle Language Versions - Multi-language docs
- **MP065**: Formal Logic Language - Logic notation
- **MP066**: Pseudocode Conventions - Pseudocode style
- **MP067**: Language Preferences - Doc language choices
- **MP068**: Package Documentation - (duplicate?)
- **MP069**: Language as Index - Language as navigation
- **MP070**: AI-Friendly Formats - Plain text preferred
- **MP071**: Type-Prefix Naming - Naming convention foundation ⭐⭐
- **MP072**: Capitalization Convention - UPPERCASE = NSQL
- **MP073**: Logic Document Creation - Formal logic docs
- **MP074**: Module Implementation Naming - Module file naming
- **MP075**: Package Consistency Naming - Follow package conventions
- **MP076**: Language Standard Adherence - Follow language specs
- **MP077**: Pseudocode Standard Adherence - Strict pseudocode
- **MP078**: Object Naming Convention - Dot notation standard
- **MP079**: Object File Name Translation - Dots to underscores
- **MP080**: Terminology Synonym Mapping - Concept mapping
- **MP081**: Aggregate Variable Naming - Aggregation prefixes
- **MP082**: Lowercase Variable Naming - snake_case standard

**Languages (MP083-MP090)**
- **MP083**: Natural SQL Language - NSQL foundation
- **MP084**: AI Communication Meta Language - AIMETA
- **MP085**: R Statistical Query Language - RSQL
- **MP086**: Specialized Natural SQL - SNSQL variants
- **MP087**: NSQL Detailed Specification - NSQL grammar
- **MP088**: Graph Theory in NSQL - Graph operations
- **MP089**: NSQL Set Theory Foundations - Set operations
- **MP090**: Radical Translation in NSQL - Translation theory

**System Integration (MP091-MP110)**
- **MP092**: Platform ID Standard - Multi-platform_id
- **MP093**: Script Separation Principle - ETL/DRV/APP separation
- **MP093**: Data Visualization Debugging - Debug with viz (duplicate number!)
- **MP094**: Platform API Architecture - API design
- **MP095**: Claude Code-Driven Changes - AI-driven development
- **MP096**: Data Storage Selection Strategy - DB choice logic
- **MP097**: Principle-Implementation Separation - Docs vs code ⭐
- **MP098**: Generality Over Specificity - General solutions
- **MP099**: Realtime Progress Reporting - Progress feedback
- **MP100**: UTF8 Encoding Standard - UTF-8 everywhere
- **MP101**: Global Environment Access Pattern - Global vars
- **MP102**: ETL Output Standardization - ETL result format
- **MP103**: Autodeinit Behavior - Automatic cleanup
- **MP104**: Script Organization Evolution - Script structure history
- **MP104**: ETL Data Flow Separation - (duplicate number!)
- **MP105**: Principle Documentation Lifecycle - Doc evolution
- ~~MP106~~: → **DEV_P022** Console Output Transparency - Visible logging
- **MP107**: ETL Pipeline Independence - Independent ETL
- **MP108**: ETL Phase Sequence - ETL execution order ⭐⭐⭐
- **MP109**: Derived Data Pipelines - DRV architecture
- **MP110**: Application Data Consolidation - App-level data
- **MP110**: Security Credentials Management - (duplicate number!)

**Security (MP110-MP118)**
- **MP110**: Security Credentials Management - Credential handling
- **MP111**: Data Privacy Protection - Privacy standards
- **MP112**: Access Control Authorization - Access rules
- **MP113**: Secure Communication - Communication security
- **MP114**: Input Validation/Sanitization - Input safety
- **MP115**: Audit Logging/Monitoring - Audit trails
- **MP116**: Dependency Vulnerability Management - Dependency security
- **MP117**: Backup/Disaster Recovery - Backup strategy
- **MP118**: Development Security Practices - Secure coding

**Advanced Architecture (MP119-MP142)**
- **MP119**: UI Block Separation - UI component organization
- **MP120**: Theme Consistency - UI theming
- **MP121**: Issue Authorization Control - Issue management
- **MP122**: Quad-Track Shared Symlink Architecture - Framework (shared/) + Scripts (shared/) + NSQL (shared/) + Config ⭐⭐
- **MP123**: AI Prompt Configuration Management - AI config ⭐
- **MP135**: Analytics Temporal Classification - Type A/B analytics
- **MP136**: Configuration-Init Pattern - App config loading ⭐
- **MP137**: No Hardcoded Project-Specific Content - Externalize all variable content ⭐⭐
- **MP140**: Pipeline Orchestration - On-demand execution with declarative dependencies ⭐⭐⭐ (NEW)
- **MP141**: Scheduled Execution Pattern - Manual + scheduled modes with observability ⭐⭐ (NEW)
- **MP142**: Configuration-Driven Pipeline - Centralized YAML configuration ⭐⭐ (NEW)

---

### Structure Organization (SO_R001-SO_R035)

**Structure Organization Principles (SO_P001-SO_P019)**
- **SO_P010**: Config-Driven Customization - All company-specific content from config ⭐
- **SO_P015**: No Hardcoded Lookup Tables - Mapping tables externalized to DB/config ⭐⭐
- **SO_P016**: Configuration Scope Hierarchy - Config at appropriate scope: Universal/Company/App ⭐⭐
- **SO_P017**: Platform-Specific Feature Gating - Enable/disable features per platform via config
- **SO_P018**: Directory Structure Governance - Strict control over directory creation in core folders
- **SO_P019**: Domain Knowledge Classification - CH13-CH18 chapters for part3_domain_knowledge ⭐ (NEW)
  - CH13: Marketing Analytics (MK prefix) - Marketing-specific methodologies
  - CH14: Statistics (ST prefix) - General statistical methods
  - CH15: Project Management (PM prefix) - Project management knowledge
  - CH16: Data Science (DS prefix) - Data science techniques
  - CH17: E-commerce (EC prefix) - E-commerce domain knowledge
  - CH18: Operations Research (OR prefix) - OR methods and optimization

**Directory & File Structure (SO_R001-SO_R009)**
- **SO_R001**: Directory Structure - Standard directory layout
- **SO_R002**: File Naming Convention - File naming rules
- **SO_R003**: App Structure Standard - Shiny app organization
- **SO_R004**: Principle Documentation - How to document principles
- **SO_R005**: App YAML Configuration - app_config.yaml standard
- **SO_R006**: Archiving Standard - Archive procedures
- **SO_R007**: One Function One File - fn_*.R pattern ⭐⭐
- **SO_R008**: App Mode Naming Simplicity - Mode naming
- **SO_R009**: Two-Tier Directory Structure - Max 2 levels

**Code Organization (SO_R010-SO_R022)**
- **SO_R010**: Implementation Naming Convention - Implementation files
- **SO_R011**: Folder Structure DSM Nodes - Module structure
- **SO_R012**: Path Modification - setwd() rules
- **SO_R013**: Initialization Imports Only - Init file contents
- **SO_R014**: Source Directories - source() pattern
- **SO_R015**: Component Folder Organization - Component structure
- **SO_R016**: Folder-Based Sourcing - Source by folder
- **SO_R017**: Function Location - Where to put functions
- **SO_R018**: Configuration Requirement - Config files required
- **SO_R019**: Dependency-Based Sourcing - Source order
- **SO_R020**: Supplemental Description Notation - Comment style
- **SO_R021**: Module Naming Convention - Module file naming
- **SO_R022**: Temporary File Handling - Temp file management

**Configuration & Documentation (SO_R023-SO_R035)**
- **SO_R023**: YAML Parameter Configuration - YAML standards
- **SO_R024**: Update Script Naming - Script naming pattern
- **SO_R025**: Global Parameter Organization - Parameter storage
- **SO_R026**: Function File Naming - fn_ prefix rule
- **SO_R027**: N-Tuple Delimiter - Triple separators (UI-Server-Defaults)
- **SO_R028**: .env File Standard - Environment variable files
- **SO_R029**: CHANGELOG Organization - Changelog structure
- **SO_R030**: Operational Documentation Location - Where to put docs ⭐⭐
- **SO_R031**: Backup File Management - Backup lifecycle
- **SO_R032**: Documentation Template System - Doc templates
- **SO_R033**: Test Script Location - Test file placement ⭐
- **SO_R034**: Debug Script Management - Debug script lifecycle
- **SO_R035**: Temp File/Log Management - Temp data handling

---

### Data Management (DM_R001-DM_R048)

**Core Data Access (DM_R001-DM_R014)**
- **DM_R001**: Data Frame Creation Strategy - When to create df
- **DM_R002**: Universal Data Access - Use tbl2() pattern for reads ⭐⭐⭐
- **DM_R003**: Database Access via tbl - tbl() pattern
- **DM_R004**: Data Storage Organization - Data directory structure
- **DM_R005**: ID Relationship Validation - ID integrity checks
- **DM_R006**: Cross-Platform Data Structure - Multi-platform data
- **DM_R007**: Multiple Selection Delimiter - Multi-select separator
- **DM_R008**: Platform ID Reference - Platform identifier
- **DM_R009**: Special ID Conventions - ID special cases
- **DM_R010**: Filtering Logic Patterns - Filter implementation
- **DM_R011**: Unified tbl Data Access - Consistent tbl usage
- **DM_R012**: tbl Pattern Rationale - Why tbl pattern
- **DM_R013**: dplyr Usage - dplyr best practices
- **DM_R014**: tbl2 Enhanced Data Access - Advanced tbl2 features

**ID & Key Management (DM_R015-DM_R022)**
- **DM_R015**: Dynamic Combined ID Pattern - Composite keys
- **DM_R016**: Lowercase Natural Key - Key naming
- **DM_R017**: Memory-Resident Parameters - In-memory params
- **DM_R018**: Filter Variable Naming - Filter var naming
- **DM_R019**: ID Extraction Guidelines - How to extract IDs
- **DM_R020**: Unified Product ID - Product ID standard
- **DM_R021**: Integer ID Type Conversion - ID type handling
- **DM_R022**: Platform Numbering Convention - Platform ID format

**Database Technology (DM_R023-DM_R027)**
- **DM_R023**: Universal DBI Approach - DBI connection pattern (reads via tbl2)
- **DM_R024**: List Column Handling - R list in DB
- **DM_R025**: Type Conversion R-DuckDB - R/DuckDB types
- **DM_R026**: JSON Serialization Strategy - JSON handling
- **DM_R027**: ETL Schema Validation - Schema checks

**ETL Architecture (DM_R028-DM_R048)**
- **DM_R028**: ETL Data Type Separation - ETL vs DRV data ⭐⭐
- **DM_R035**: Script Placement Rule - Where to put ETL scripts
- **DM_R036**: ETL Return Values - What ETL should return
- **DM_R037**: Company-Specific ETL Naming - Company prefixes (cbz_, eby_)
- **DM_R038**: Company Suffix Scope Limitation - When to use suffix
- **DM_R039**: Database Connection Pattern - DB connection standard
- **DM_R040**: Structural Join Pattern - Join standards for dimension tables
- **DM_R060**: ETL Independence Requirements - Independent ETL pipelines
- **DM_R041**: ETL Directory Structure - ETL file organization ⭐⭐⭐
- **DM_R042**: DRV Sequential Numbering - D01, D02, etc. naming
- **DM_R043**: Predictor Data Classification - Type A/B/C data
- **DM_R044**: Derivation Implementation Standard - How to write derivations ⭐⭐⭐
- **DM_R045**: Database File Naming Standard - Database filename rules
- **DM_R046**: Variable Display Name Metadata - display_name_* tables
- **DM_R047**: Multi-Platform Synchronization - Cross-platform sync ⭐⭐
- **DM_R048**: Derivation Timestamp Standard - DRV output metadata ⭐⭐
- **DM_R049**: Derivation Consumer Documentation - UI module consumer tracking ⭐⭐
- **DM_R050**: Derivation Documentation Structure - Single-file vs directory for derivation docs ⭐⭐
- **DM_R051**: Single Task per Derivation Step - Each D{nn}_{seq} performs ONE business module ⭐⭐

---

### Development (DEV_R001-DEV_R036)

**Functional Programming (DEV_R001-DEV_R008)**
- **DEV_R001**: Apply Over Loops - Use apply family
- **DEV_R002**: Functional Encapsulation - Functions over scripts
- **DEV_R003**: Platform-Neutral Code - Avoid platform-specific code
- **DEV_R004**: Recursive Sourcing - Source recursively
- **DEV_R005**: AI-Locked Files - Files AI shouldn't modify
- **DEV_R006**: Package Documentation Reference - How to doc packages
- **DEV_R007**: Package Function Reference - Package function usage
- **DEV_R008**: Minimal Modification - Change minimally

**Initialization & Sourcing (DEV_R009-DEV_R014)**
- **DEV_R009**: Initialization Sourcing - Init source pattern
- **DEV_R010**: AI Parameter Modification - AI can modify params
- **DEV_R011**: Derivation Platform Independence - Platform-neutral DRV
- **DEV_R012**: Verify Existing Functions - Check before creating
- **DEV_R013**: Switch Over If-Else - Use switch() when appropriate
- **DEV_R014**: data.table Vectorization - Vectorized data.table ops

**Code Quality (DEV_R015-DEV_R023)**
- **DEV_R015**: Commented Code Cleanup - Remove dead code
- **DEV_R016**: Evolution Over Replacement - Evolve don't rewrite
- **DEV_R017**: Explicit Over Implicit Evaluation - Be explicit
- **DEV_R018**: AI-Guided Structure Modification - AI-driven refactoring
- **DEV_R019**: app.R Function Prohibition - No functions in app.R
- **DEV_R020**: Object Initialization - Initialize before use
- **DEV_R021**: app.R Change Permissions - When to modify app.R
- **DEV_R022**: Module Data Connection - Pass connections not data ⭐⭐⭐
- **DEV_R023**: Roxygen2 Function Examples - Document with examples

**R Package Development (DEV_R024-DEV_R031)**
- **DEV_R024**: Import Requirements - Package imports
- **DEV_R025**: File Lock Notation - Lock file syntax
- **DEV_R026**: Shiny Reactive Observation - Reactive best practices
- **DEV_R027**: Package Function Reference - (duplicate?)
- **DEV_R028**: S4 Class Handling - S4 object patterns
- **DEV_R029**: Function Deployment - Deploy functions properly
- **DEV_R030**: Explicit Namespace in Shiny - pkg::function in Shiny
- **DEV_R031**: Comment-Code Spacing - Code formatting

**Advanced Patterns (DEV_R032-DEV_R036)**
- **DEV_R032**: Update Script Structure - Script organization
- **DEV_R033**: Localized Activation - Activation scope
- **DEV_R034**: Shiny Reactive Gateways - Reactive pattern
- **DEV_R035**: Code Compliance Tracking - Track principle compliance
- **DEV_R036**: ShinyJS Module Namespace - shinyjs in modules ⭐

---

### UI Components (UI_R001-UI_R024)

**Core UI Architecture (UI_R001-UI_R010)**
- **UI_R001**: UI-Server-Defaults N-tuple - Triple pattern ⭐⭐⭐
- **UI_R002**: Shiny Module ID Handling - Module ID management
- **UI_R003**: Integrated Component Pattern - Component integration
- **UI_R004**: Hybrid Sidebar Pattern - Sidebar design
- **UI_R005**: UI Hierarchy - UI structure levels
- **UI_R006**: Defaults from Triple - How to handle defaults
- **UI_R007**: UI Text Standardization - Consistent UI text
- **UI_R008**: Default Selection Conventions - Default values
- **UI_R009**: Enhanced Input Components - Custom inputs
- **UI_R010**: Component ID Consistency - Consistent IDs across triple

**Framework Standards (UI_R011-UI_R018)**
- **UI_R011**: bs4Dash Structure Adherence - bs4Dash patterns
- **UI_R012**: bs4Dash Navbar Navigation - Navigation structure
- **UI_R013**: Database Status Display - Show DB connection status
- **UI_R014**: CSS Organization - CSS file structure
- **UI_R015**: RShiny App Templates - Template usage
- **UI_R016**: Selectize Input Usage - When to use selectizeInput
- **UI_R017**: bs4Dash Namespace - bs4Dash module namespacing
- **UI_R018**: Table Download Button Placement - Download button location

**UX Patterns (UI_R019-UI_R024)**
- **UI_R019**: AI Process Notification - Progress for AI operations ⭐⭐
- **UI_R020**: CSV UTF8-BOM Standard - CSV encoding
- **UI_R021**: Dual Download Buttons Statistical - Two download formats
- **UI_R024**: Metadata Display Steady-State - Type B analytics UI

---

### Testing/Deployment (TD_R001-TD_R007, DEV_R054)

- **TD_R001**: Shiny Test Data - Test data for Shiny apps
- **TD_R002**: Test App Building - How to build test apps
- **TD_R003**: Test Script Initialization - Test script setup
- **TD_R004**: Standard Mock Database - Mock DB for testing
- **TD_R005**: Docker Deployment Standard - Docker standards
- **TD_R006**: Deployment Driver Orchestration - Enforce sync → deploy order
- **TD_R007**: E2E Testing Standard - shinytest2 automated browser testing ⭐⭐
- **DEV_R054**: DEBUG_MODE Dashboard Logging - All render*() must log output when DEBUG_MODE=TRUE ⭐

---

### Security (SEC_R001-SEC_R003)

- **SEC_R001**: No Hardcoded Credentials - Never hardcode secrets
- **SEC_R002**: Environment Variable Standards - .env file usage
- **SEC_R003**: .gitignore Security Requirements - What to ignore

---

### Integration/Collaboration (IC_R001-IC_R009)

- **IC_R001**: Global Scripts Synchronization - Sync across projects
- **IC_R002**: Available Locales - Language/locale support
- **IC_R006**: Shared Repo Completeness - All functional files must be git-tracked (implements MP122)
- **IC_R007**: GitHub Issue Attachments - Issue evidence must be attached to the shared repo issue
- **IC_R008**: GitHub Issue Scope Governance - Active issues must use the correct scope label
- **IC_R009**: Bidirectional Commit-Issue Traceability - Every commit references an issue; every issue has a resolving commit

---

## 🏷️ Topic-Based Index

### ETL & Data Pipelines

**Critical Principles:**
- MP064: ETL/Derivation Separation - Fundamental architecture
- MP108: ETL Phase Sequence - Execution order (0IM → 1ST → 2TR → 3PR → 4CL → 5NM)
- MP149: Data Transaction Integrity - 0IM must be auditable and transactional (rollback on mismatch)
- MP107: ETL Pipeline Independence - Each ETL is independent
- DM_R041: ETL Directory Structure - Where files go
- DM_R044: Derivation Implementation Standard - How to write D*.R
- DM_R028: ETL Data Type Separation - ETL vs DRV data
- **MP140**: Pipeline Orchestration - On-demand execution ⭐⭐⭐ (NEW)
- **MP141**: Scheduled Execution Pattern - Scheduling and observability ⭐⭐ (NEW)
- **MP142**: Configuration-Driven Pipeline - YAML configuration ⭐⭐ (NEW)

**Supporting Principles:**
- MP102: ETL Output Standardization
- MP104: ETL Data Flow Separation
- MP109: Derived Data Pipelines
- DM_R027: ETL Schema Validation
- DM_R035: Script Placement Rule
- DM_R036: ETL Return Values
- DM_R037: Company-Specific ETL Naming
- DM_R042: DRV Sequential Numbering
- DM_R049: Derivation Consumer Documentation - UI module consumers ⭐⭐
- DM_R050: Derivation Documentation Structure - Single-file vs directory ⭐⭐
- DM_R051: Single Task per Derivation Step - One module per task file ⭐⭐
- DEV_R011: Derivation Platform Independence

**File Paths:**
```
docs/en/part1_principles/CH00_fundamental_principles/04_data_management/
docs/en/part1_principles/CH02_data_management/rules/
```

---

### Naming Conventions

**Type-Prefix System (MP071):**
- `df_` - DataFrames (R119)
- `fn_` - Functions (SO_R007, SO_R026)
- `sc_` - Scripts
- `tbl_` - Database tables
- `list_` - List objects
- `vec_` - Vectors

**Case Conventions:**
- MP082: Lowercase Variable Naming (snake_case)
- MP072: Capitalization Convention (UPPERCASE = NSQL)
- MP078: Object Naming Convention (dot.notation)
- MP079: Object File Name Translation (dots → underscores)

**Special Naming:**
- MP081: Aggregate Variable Naming (prefix with function)
- DM_R018: Filter Variable Naming
- DM_R037: Company-Specific Naming (cbz_, eby_)
- SO_R002: File Naming Convention
- SO_R024: Update Script Naming

---

### Database Operations

**Core Access Patterns:**
- DM_R002: Universal Data Access - **ALWAYS use tbl2() for reads**
- DM_R003: Database Access via tbl - Legacy pattern
- DM_R011: Unified tbl Data Access
- DM_R014: tbl2 Enhanced Data Access
- DM_R023: Universal DBI Approach - No raw SQL reads (dbGetQuery/dbSendQuery)

**Data Integrity:**
- DM_R005: ID Relationship Validation
- DM_R015: Dynamic Combined ID Pattern
- DM_R019: ID Extraction Guidelines
- DM_R020: Unified Product ID
- DM_R021: Integer ID Type Conversion

**Database Technology:**
- DM_R024: List Column Handling
- DM_R025: Type Conversion R-DuckDB
- DM_R026: JSON Serialization Strategy
- DM_R039: Database Connection Pattern
- DM_R045: Database File Naming Standard

**Data Synchronization:**
- MP061: Database Synchronization
- DM_R047: Multi-Platform Synchronization
- DM_R006: Cross-Platform Data Structure

---

### Shiny UI Components

**Core Architecture:**
- UI_R001: UI-Server-Defaults Triple - **MANDATORY pattern**
- UI_R002: Shiny Module ID Handling
- UI_R010: Component ID Consistency
- MP020: UI-Server Correspondence
- SO_R027: N-Tuple Delimiter

**Framework Standards:**
- UI_R011: bs4Dash Structure Adherence
- UI_R012: bs4Dash Navbar Navigation
- UI_R017: bs4Dash Namespace
- MP017: Config-Driven UI Composition
- MP025: UI Separation

**UX & Feedback:**
- UI_R019: AI Process Notification - For long operations
- UI_R013: Database Status Display
- MP099: Realtime Progress Reporting
- UI_R007: UI Text Standardization

**Advanced Patterns:**
- DEV_R026: Shiny Reactive Observation
- DEV_R030: Explicit Namespace in Shiny
- DEV_R034: Shiny Reactive Gateways
- DEV_R036: ShinyJS Module Namespace

---

### Testing & Validation

**Test Data:**
- MP029: No Fake Data - **CRITICAL**
- MP047: Test Data Design
- MP054: No Fake Data (Data Mgmt reinforcement)
- TD_R001: Shiny Test Data
- TD_R004: Standard Mock Database

**Test Organization:**
- SO_R033: Test Script Location - `98_test/` or component `tests/`
- TD_R002: Test App Building
- TD_R003: Test Script Initialization

**E2E Testing (NEW):**
- TD_R007: E2E Testing Standard - shinytest2 + testthat ⭐⭐
- DEV_R054: DEBUG_MODE Dashboard Logging - Detect blank panels via log ⭐

**Debugging:**
- MP046: Debug Code Tracing
- MP093: Data Visualization Debugging
- SO_R034: Debug Script Management - Temporary scripts

---

### Documentation & Change Management

**Documentation Location:**
- SO_R030: Operational Documentation Location - **Use CHANGELOG/**
- MP011: Documentation Organization
- SO_R029: CHANGELOG Organization
- SO_R032: Documentation Template System

**Change Tracking:**
- MP012: Change Tracking - **Required for all changes**
- MP016: Concept Documents
- SO_R004: Principle Documentation
- DEV_R035: Code Compliance Tracking

**Documentation Principles (NEW):**
- DOC_P001: Documentation System Architecture - Three-layer system (Wiki/Principles/Issues)
- DOC_R001: Wiki Link Syntax - `[[display|page]]` format
- DOC_R002: Wiki Content Standards - Customer-facing writing guidelines
- DOC_R003: Formula Cross-Verification - Wiki formulas must match code
- DOC_R004: Changelog and Reporting Format - Report file naming
- DOC_R005: Wiki Math Formula Syntax - KaTeX rules for GitHub Wiki
- DOC_R006: Wiki Synchronization Trigger - Hook reminds when Wiki needs update
- DOC_R007: Claude Rules Writing Convention - Rules files must be brief, reference .qmd ⭐
- DOC_R008: Wiki Term Page R Code Section - Term pages must end with R code block (excerpt + explanation + source)
- DOC_R009: Principle Triple-Layer Synchronization - .qmd → llm/*.yaml → .claude/rules/*.md must stay in sync

**Backup & Archive:**
- SO_R031: Backup File Management
- MP034: Archive Immutability
- SO_R006: Archiving Standard

---

### Security & Credentials

**Credentials:**
- SEC_R001: No Hardcoded Credentials
- SEC_R002: Environment Variable Standards
- SO_R028: .env File Standard
- MP110: Security Credentials Management

**Data Protection:**
- MP111: Data Privacy Protection
- MP112: Access Control Authorization
- MP114: Input Validation/Sanitization

**Infrastructure:**
- MP113: Secure Communication
- MP115: Audit Logging/Monitoring
- MP116: Dependency Vulnerability Management
- MP117: Backup/Disaster Recovery

---

### Configuration Management

**No Hardcoded Content (NEW - 2025-12-14):**
- **MP137**: No Hardcoded Project-Specific Content - **UMBRELLA PRINCIPLE** ⭐⭐
- **SO_P010**: Config-Driven Customization - Company-specific content (derives from MP137)
- **SO_P015**: No Hardcoded Lookup Tables - Mapping tables to DB/config ⭐⭐ (NEW)

**App Configuration:**
- MP136: Configuration-Init Pattern
- SO_R005: App YAML Configuration
- SO_R018: Configuration Requirement
- MP065: Platform Configuration Management

**AI Configuration:**
- MP123: AI Prompt Configuration Management
- MP070: AI-Friendly Formats
- MP084: AI Communication Meta Language

**Multi-Platform:**
- DM_R006: Cross-Platform Data Structure
- DM_R047: Multi-Platform Synchronization
- DEV_R003: Platform-Neutral Code

---

## 🎯 Common Scenarios

### Scenario 1: Building a New ETL Pipeline

**Step-by-step principle checklist:**

1. **Architecture Understanding**
   - Read MP064 (ETL/Derivation Separation)
   - Read MP108 (ETL Phase Sequence)
   - Understand 1ST → 2TR → 3RD flow

2. **File Organization**
   - Apply DM_R041 (ETL Directory Structure)
   - Use DM_R037 (Company-Specific Naming: cbz_ETL_*, eby_ETL_*)
   - Follow SO_R007 (One Function One File)

3. **Data Handling**
   - **CRITICAL**: Follow MP029 (No Fake Data)
   - Use DM_R002 (tbl2 for reads)
   - Apply DM_R028 (ETL Data Type Separation)

4. **Implementation**
   - Return standardized output (DM_R036)
   - Validate schema (DM_R027)
   - Ensure independence (MP107, DM_R060)

5. **Documentation**
   - Document in CHANGELOG/ (SO_R030)
   - Track changes (MP012)
   - Update principles if needed

**Key principle numbers:** MP029, MP064, MP108, DM_R041, DM_R037, DM_R002

---

### Scenario 2: Creating a Derivation Script

**Step-by-step principle checklist:**

1. **Naming & Location**
   - Use DM_R042 (Sequential numbering: D01, D02...)
   - Place in `scripts/derivations/`
   - Follow SO_R007 (One function one file)

2. **Implementation Standard**
   - Follow DM_R044 (Derivation Implementation Standard)
   - Use template from `docs/en/part2_implementations/CH13_derivations/`
   - Platform-independent (DEV_R011)

3. **Data Access**
   - Use tbl2() for reads (DM_R002)
   - Follow MP071 (Type-prefix naming: df_*)
   - Apply R119 (Universal df_ prefix)

4. **Validation**
   - **NO FAKE DATA** (MP029, MP054)
   - Document metadata (DM_R046)
   - Test with real data

**Key principle numbers:** DM_R044, DM_R042, MP029, DM_R002

---

### Scenario 3: Building a Shiny UI Component

**Step-by-step principle checklist:**

1. **Component Structure**
   - Use UI_R001 (UI-Server-Defaults Triple)
   - Create 3 files: componentUI.R, componentServer.R, componentDefaults.R
   - Organize in folder (SO_R015)

2. **Module Pattern**
   - Apply UI_R002 (Module ID handling)
   - Ensure UI_R010 (Component ID consistency)
   - Use DEV_R036 (ShinyJS namespace if needed)

3. **Data Flow**
   - Pass connection not data (DEV_R022)
   - Follow MP059 (Unidirectional data flow)
   - Apply DEV_R034 (Reactive gateways)

4. **UX Requirements**
   - Add AI process notification (UI_R019) if >2 seconds
   - Follow UI_R007 (Text standardization)
   - Apply MP026 (Interactive viz preference)

5. **Framework Compliance**
   - Use bs4Dash standards (UI_R011)
   - Follow UI_R012 (Navbar navigation)
   - Apply MP017 (Config-driven composition)

**Key principle numbers:** UI_R001, DEV_R022, UI_R019, MP026

---

### Scenario 4: Debugging an Application Issue

**Step-by-step principle checklist:**

1. **Initial Investigation**
   - Create debug script in appropriate location (SO_R034)
   - Use data visualization (MP093)
   - Apply debug tracing (MP046)

2. **Root Cause Analysis**
   - Follow MP050 (Root cause resolution)
   - Check principle compliance (DEV_R035)
   - Verify data flow (DM_P007, MP059)

3. **Fix Implementation**
   - Minimal modification (DEV_R008)
   - Evolution over replacement (DEV_R016)
   - Document which principles fix follows (MP012)

4. **Documentation**
   - Create debug report in CHANGELOG/ (SO_R030)
   - Use documentation template (SO_R032)
   - Archive debug script after resolution (SO_R034)

5. **Validation**
   - Test with real data (MP029)
   - Verify no principle violations
   - Update tests (TD_R001-TD_R003)

**Key principle numbers:** MP050, MP046, SO_R034, SO_R030

---

### Scenario 5: Adding OpenAI/AI Integration

**Step-by-step principle checklist:**

1. **Configuration**
   - Apply MP123 (AI Prompt Configuration)
   - Use YAML for prompts (SO_R023)
   - Follow SEC_R002 (Environment variables for API keys)

2. **UX Implementation**
   - **MANDATORY**: Add UI_R019 (AI Process Notification)
   - Show stage-based progress
   - Real-time feedback (MP099)

3. **Error Handling**
   - Plan for timeouts
   - Provide user feedback
   - Log appropriately (DEV_P022)

4. **Data Handling**
   - Never send fake data (MP029)
   - Validate inputs (MP114)
   - Follow data privacy (MP111)

**Key principle numbers:** MP123, UI_R019, MP029, SEC_R002

---

### Scenario 6: Deploying to Production

**Step-by-step principle checklist:**

1. **Pre-Deployment**
   - Verify no fake data (MP029)
   - Check credentials not hardcoded (SEC_R001)
   - Review .gitignore (SEC_R003)

2. **Configuration**
   - Use environment variables (SEC_R002)
   - Apply configuration pattern (MP136)
   - Validate app_config.yaml (SO_R005)

3. **Docker Deployment**
   - Follow TD_R005 (Docker standard)
   - Apply MP091 (Docker-based deployment)
   - Test in staging first

4. **Documentation**
   - Document deployment (SO_R030)
   - Update CHANGELOG (MP012)
   - Archive old versions (MP034)

**Key principle numbers:** MP029, SEC_R001, TD_R005, MP136

---

### Scenario 7: Setting Up Pipeline Configuration

**Step-by-step principle checklist:**

1. **Understand the Three-Layer Architecture (SO_P016)**
   - Layer 1 (Universal): `global_scripts/templates/_targets_config.base.yaml`
   - Layer 2 (Company): `app_config.yaml > pipeline:` section
   - Layer 3 (Generated): `{project_root}/_targets_config.yaml`

2. **Configure Company Settings**
   - Add `pipeline:` section to `app_config.yaml`
   - Enable required platforms (MP142)
   - Set execution parameters (workers, timeouts)

3. **Merge Configuration**
   ```bash
   cd scripts/update_scripts
   make config-merge      # Merge base + company config
   make config-scan       # Optional: auto-discover scripts
   make config-validate   # Validate configuration
   ```

4. **Add Script Dependency Markers (MP140)**
   - Add to each DRV script header:
   ```r
   #####
   # CONSUMES: df_table_name
   # PRODUCES: df_output_name
   # DEPENDS_ON_ETL: platform_ETL_datatype_2TR
   # DEPENDS_ON_DRV: platform_D01_03
   #####
   ```

5. **Run Pipeline**
   - Manual: `make run TARGET=cbz_D04_02`
   - Scheduled: Configure launchd/cron (MP141)
   - Dry-run: `make dry-run TARGET=cbz_D04_02`

6. **Document Configuration Changes**
   - Update CHANGELOG (MP012)
   - Follow SO_R030 for operational docs

**Key principle numbers:** MP140, MP141, MP142, SO_P016, MP122, MP064

**Related files:**
- `global_scripts/templates/_targets_config.base.yaml` (base template)
- `global_scripts/04_utils/fn_merge_pipeline_config.R` (merge function)
- `update_scripts/Makefile` (CLI commands)
- `update_scripts/_targets.R` (main orchestration)

---

## 🔗 Principle Relationships

### Principle Hierarchies

**MP029 (No Fake Data) Family:**
- MP029: Discrepancy Principle (No Fake Data) - Core meta-principle
- MP054: No Fake Data (Data Management) - Specific implementation
- MP047: Test Data Design - How to create valid test data
- TD_R001: Shiny Test Data - Shiny-specific test data
- TD_R004: Standard Mock Database - Mock DB for testing

**ETL Architecture Family:**
- MP064: ETL/Derivation Separation - Core separation principle
- MP108: ETL Phase Sequence - Execution order
- MP107: ETL Pipeline Independence - Independence requirement
- MP102: ETL Output Standardization - Output format
- MP104: ETL Data Flow Separation - Data flow rules
- MP109: Derived Data Pipelines - Derivation architecture
- **MP140**: Pipeline Orchestration - On-demand execution with dependencies ⭐ NEW
- **MP141**: Scheduled Execution Pattern - Manual + scheduled modes ⭐ NEW
- **MP142**: Configuration-Driven Pipeline - Three-layer YAML config ⭐ NEW
- DM_R028: ETL Data Type Separation - ETL vs DRV data
- DM_R041: ETL Directory Structure - File organization
- DM_R044: Derivation Implementation Standard - Implementation details
- **DM_R049**: Derivation Consumer Documentation - UI module consumers ⭐ NEW
- **DM_R050**: Derivation Documentation Structure - Single-file vs directory ⭐ NEW
- **DM_R051**: Single Task per Derivation Step - One module per D{nn}_{seq} ⭐ NEW

**UI Component Family:**
- MP020: UI-Server Correspondence - Shiny architecture
- UI_R001: UI-Server-Defaults Triple - **Implementation pattern**
- UI_R002: Shiny Module ID Handling - Module IDs
- UI_R010: Component ID Consistency - ID across triple
- SO_R027: N-Tuple Delimiter - Triple separators
- DEV_R022: Module Data Connection - Data flow pattern

**Naming Convention Family:**
- MP071: Type-Prefix Naming - Foundation principle
- MP082: Lowercase Variable Naming - Case convention
- MP078: Object Naming Convention - Dot notation
- MP079: Object File Name Translation - Dots to underscores
- MP081: Aggregate Variable Naming - Aggregation prefixes
- R119: Universal df_ Prefix - DataFrame naming

**Documentation Family:**
- MP012: Change Tracking - Change documentation requirement
- MP011: Documentation Organization - Doc structure
- SO_R030: Operational Documentation Location - Doc placement
- SO_R029: CHANGELOG Organization - Changelog structure
- SO_R032: Documentation Template System - Templates
- DEV_R035: Code Compliance Tracking - Track principle compliance

**No Hardcoded Content Family (Updated 2025-12-15):**
- MP137: No Hardcoded Project-Specific Content - **UMBRELLA PRINCIPLE**
- SO_P010: Config-Driven Customization - Company-specific content (derives from MP137)
- SO_P015: No Hardcoded Lookup Tables - Mapping tables externalized ⭐⭐
- SO_P016: Configuration Scope Hierarchy - Config at appropriate scope ⭐⭐ (NEW)
- MP098: Generality Over Specificity - Prefer general solutions
- SEC_R001: No Hardcoded Credentials - Never hardcode secrets

---

### Common Principle Combinations

**ETL Development:**
```
MP029 (No Fake Data)
  ↓
MP064 (ETL/Derivation Separation)
  ↓
MP108 (ETL Phase Sequence)
  ↓
DM_R041 (Directory Structure)
  ↓
DM_R037 (Company Naming)
  ↓
DM_R002 (tbl2 Access)
```

**Shiny Module Creation:**
```
UI_R001 (Triple Pattern)
  ↓
SO_R007 (One Function One File)
  ↓
DEV_R022 (Module Data Connection)
  ↓
UI_R019 (AI Notifications if needed)
  ↓
MP071 (Type-Prefix Naming)
```

**Database Operations:**
```
DM_R002 (tbl2 Universal Access)
  ↓
DM_R023 (Universal DBI)
  ↓
DM_R047 (Multi-Platform Sync if needed)
  ↓
MP071 (Type-Prefix: df_)
  ↓
R119 (Universal df_ prefix)
```

---

## 📂 Chapter-Based Navigation

Principles are organized in the file system by chapters:

### CH00_fundamental_principles/
- **01_general_principles/** - MP001-MP008, MP097, MP100
- **02_structure_organization/** - MP009-MP026, MP093, MP103-MP104, MP119-MP122
- **03_development_methodology/** - MP027-MP051, MP093, MP098-MP099, MP105, MP136, MP150
- **04_data_management/** - MP052-MP065, MP092, MP094-MP096, MP101-MP104, MP107-MP110, MP123
- **05_terminology_standards/** - MP063-MP082
- **06_languages/** - MP083-MP090
- **07_security/** - MP110-MP118

### CH01_structure_organization/
- **rules/** - SO_R001-SO_R035, R119 (Universal df_ prefix)

### CH02_data_management/
- **rules/** - DM_R001-DM_R048
- **principles/** - (if any P-level principles exist)

### CH03_development_methodology/
- **rules/** - DEV_R001-DEV_R036

### CH04_ui_components/
- **rules/** - UI_R001-UI_R021, UI_R024
- **principles/** - (if any P-level principles exist)

### CH05_testing_deployment/
- **rules/** - TD_R001-TD_R005

### CH06_integration_collaboration/
- **rules/** - IC_R001, IC_R002, IC_R006-IC_R009

### CH07_security/
- **rules/** - SEC_R001-SEC_R003

### CH08_user_experience/
- **principles/** - UX_P001-UX_P002 (Lazy initialization, fast query rendering)

### CH09_etl_pipelines/
- **rules/** - R116-R118, R120 (Currency, Time Series, Statistical Significance, Variable Range Metadata)

---

## 📘 Part 2: Implementations (CH10-CH20)

Implementation guides are organized in `docs/{lang}/part2_implementations/`:

### CH10_database_specifications/
### CH11_data_flow_architecture/
### CH12_etl_pipelines/
### CH13_derivations/
### CH14_modules_tools/
### CH15_functions_reference/
### CH16_apis_external_integration/
### CH17_connections/
### CH18_templates_examples/
### CH19_solutions_patterns/
### CH20_app_architecture/
- **appendix/** - Supporting references

---

## 📚 Part 3: Domain Knowledge (CH21-CH24)

Domain knowledge articles are organized by discipline in `docs/{lang}/part3_domain_knowledge/`:

### CH21_marketing_analytics/ (MK prefix)
Marketing-specific methodologies and frameworks:
- **MK01**: IPT Theoretical Framework - Ideal Point Theory foundations
- **MK02**: IPT Calculation Methodology - Implementation details
- **MK03**: Ideal Point Calculation - Practical calculation methods

### CH22_statistics/ (ST prefix)
General statistical methods applicable across domains:
- **ST01**: Univariate Poisson Regression - Sales drivers analysis methodology

### CH23_system_architecture/ (SA prefix)
System architecture paradigms:
- **SA01**: Blocking vs Async - R/Shiny blocking vs Node.js async
- **SA02**: Data Storage Comparison - DuckDB vs Parquet vs Supabase

### CH24_ai_assisted_development/ (AD prefix)
AI-assisted development guidance:
- **AD01**: Transparency vs Feedback Principle - Use AI assistance without obscuring system behavior

**Naming Convention:** `{PREFIX}{NN}_{descriptive_name}.qmd`
- Example: `ST01_univariate_poisson_regression.qmd`
- Example: `MK03_ideal_point_calculation.qmd`
- Example: `SA02_data_storage_comparison.qmd`

---

## 🔍 Search Tips for Claude

### By Principle Number
```bash
# Search in this file first
Ctrl+F: "MP029"

# Then read the principle file
Read: docs/en/part1_principles/CH00_fundamental_principles/03_development_methodology/MP029_discrepancy_principle.qmd
```

### By Topic Keyword
```bash
# Search this file for topic sections
Ctrl+F: "ETL", "Naming", "Security", etc.

# Or search principle files directly
Grep: "pattern" "ETL" in docs/en/part1_principles/
```

### By Scenario
```bash
# Browse "Common Scenarios" section above
# Each scenario lists relevant principles

# Example: "Building ETL" → MP064, MP108, DM_R041, etc.
```

### By Chapter
```bash
# Navigate to chapter directory
ls docs/en/part1_principles/CH02_data_management/rules/

# Read all rules in a category
Read: CH02_data_management/rules/DM_R041*.qmd
```

---

## 📖 Claude Workflow Recommendations

### Workflow 1: Before Starting Any Task

```
1. Identify task type (ETL, UI, Database, etc.)
2. Search QUICK_REFERENCE.md topic section
3. Read Top 20 if task is common
4. Check "Common Scenarios" section
5. Read 3-5 most relevant principle .qmd files
6. Document which principles you're following
7. Begin implementation
```

### Workflow 2: When Debugging

```
1. Check MP050 (Root Cause Resolution)
2. Apply MP046 (Debug Code Tracing)
3. Use MP093 (Data Visualization)
4. Create debug script per SO_R034
5. Document findings in CHANGELOG/ per SO_R030
6. Archive debug script after resolution
```

### Workflow 3: During Code Review

```
1. Check DEV_R035 (Code Compliance Tracking)
2. Verify MP029 (No Fake Data)
3. Check naming against MP071, MP082
4. Verify documentation per MP012
5. Check security principles (SEC_R001-R003)
```

---

## 🚨 Critical Reminders for Claude

### ABSOLUTE REQUIREMENTS (Always Check)

1. **MP029**: NEVER create fake/sample/mock data in production code
2. **DM_R002**: ALWAYS use tbl2() for database reads, never direct tbl()
3. **SO_R007**: ONE function per file, named fn_*.R
4. **UI_R001**: Shiny modules MUST have UI-Server-Defaults triple
5. **SO_R030**: Operational docs go in CHANGELOG/, not root
6. **MP012**: Document ALL changes with principle references
7. **SEC_R001**: NEVER hardcode credentials

### BEFORE ANY CODE CHANGE

- [ ] Read relevant principles from this reference
- [ ] Verify approach doesn't violate any principles
- [ ] Document which principles you're following
- [ ] Update CHANGELOG if architectural change

### COMMON MISTAKES TO AVOID

❌ Creating sample data for testing (violates MP029)
❌ Using `tbl()` instead of `tbl2()` (violates DM_R002)
❌ Using dbGetQuery/dbSendQuery for reads (violates DM_R023)
❌ Multiple functions in one file (violates SO_R007)
❌ Skipping UI-Server-Defaults triple (violates UI_R001)
❌ Putting debug reports in root (violates SO_R030)
❌ Not documenting changes (violates MP012)

---

## 📝 Principle File Structure

All principle .qmd files follow this YAML frontmatter:

```yaml
---
title: "MP029: Discrepancy Principle"
subtitle: "Brief description"
chapter: "CH00"
category: "meta-principle"
number: "MP029"
date-created: "YYYY-MM-DD"
date-modified: "YYYY-MM-DD"
author: "Author Name"
type: "meta-principle|rule"
---
```

**File Locations:**
- Meta-Principles: `docs/en/part1_principles/CH00_fundamental_principles/`
- Rules: `docs/en/part1_principles/CH01-CH09_*/rules/`
- Implementations: `docs/en/part2_implementations/`

---

## 🔄 Keeping This Reference Updated

When new principles are added:

1. Update the count at the top
2. Add to appropriate "Quick Lookup" section
3. Add to relevant "Topic-Based Index" sections
4. Add to "Common Scenarios" if applicable
5. Update "Principle Relationships" if part of a family
6. Update INDEX.md with changes

**Last Updated**: 2025-12-24
**Principles Count**: 351 principle files (English) | 197 (Chinese)
**Maintainer**: AI MarTech Development Team

---

## 🎓 Learning Path for New Developers

### Week 1: Core Foundations
1. MP029 (No Fake Data)
2. MP064 (ETL/Derivation Separation)
3. MP071 (Type-Prefix Naming)
4. SO_R007 (One Function One File)
5. DM_R002 (tbl2 Universal Access)

### Week 2: Architecture Understanding
1. MP108 (ETL Phase Sequence)
2. DM_R041 (ETL Directory Structure)
3. DM_R044 (Derivation Implementation)
4. UI_R001 (UI-Server-Defaults Triple)
5. MP012 (Change Tracking)

### Week 3: Advanced Patterns
1. DEV_R022 (Module Data Connection)
2. DM_R047 (Multi-Platform Sync)
3. UI_R019 (AI Process Notification)
4. MP123 (AI Prompt Configuration)
5. DEV_R036 (ShinyJS Module Namespace)

### Week 4: Security & Deployment
1. SEC_R001-SEC_R003 (Security principles)
2. TD_R001-TD_R005 (Testing/Deployment)
3. MP136 (Configuration-Init Pattern)
4. SO_R030 (Documentation Location)

---

**END OF QUICK REFERENCE**

For detailed principle content, always read the original .qmd files in:
`docs/en/part1_principles/`

For implementation examples, see:
`docs/en/part2_implementations/`

---

## 📋 Pipeline Orchestration Family (NEW 2025-12-23)

**Core Principles:**
- **MP140**: Pipeline Orchestration - On-demand execution with declarative dependencies ⭐⭐⭐
- **MP141**: Scheduled Execution Pattern - Manual + scheduled modes with observability ⭐⭐
- **MP142**: Configuration-Driven Pipeline - Centralized YAML configuration ⭐⭐

**Related Principles:**
- MP064: ETL/Derivation Separation - Physical directory separation
- MP107: ETL Pipeline Independence - Horizontal independence
- MP108: ETL Phase Sequence - 6-layer symmetric sequence (ETL 3 + DRV 3)
- MP109: Derived Data Pipelines - DRV flexibility patterns
- DM_R042: DRV Sequential Numbering - Group numbering standard

**Usage:**
```bash
# On-demand execution
make run TARGET=cbz_D04_02    # Auto-resolves dependencies

# Scheduling
make schedule                  # Weekly automation
make status                    # Check progress
make vis                       # DAG visualization
```
