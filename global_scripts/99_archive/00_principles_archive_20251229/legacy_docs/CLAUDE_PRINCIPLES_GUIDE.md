# Claude Principles Workflow Guide

> **Purpose**: This document provides Claude Code with step-by-step workflows for working with the MAMBA principles system.

---

## 🎯 Core Philosophy

The 00_principles directory contains **275 active principles** that govern all MAMBA development. These are NOT just documentation - they are **executable rules** that Claude MUST follow.

**Key Insight**: You don't need to read all 746 .qmd files. Use the index system strategically.

---

## 📚 Three-Tier Documentation System

### Tier 1: Quick Reference (THIS IS YOUR PRIMARY TOOL)
**File**: `QUICK_REFERENCE.md`
**Purpose**: Fast lookup by number, topic, or scenario
**When to use**: Start here for every task

### Tier 2: Index
**File**: `INDEX.md`
**Purpose**: High-level overview and recent changes
**When to use**: Check recent updates, understand system evolution

### Tier 3: Principle Files
**Location**: `natural/en/part1_principles/`
**Purpose**: Detailed principle specifications
**When to use**: After identifying relevant principles in QUICK_REFERENCE.md

---

## 🔄 Standard Claude Workflows

### Workflow A: Starting a New Task

```
Step 1: Identify Task Category
├─ ETL development?
├─ UI component creation?
├─ Database operation?
├─ Testing/debugging?
└─ Documentation?

Step 2: Consult QUICK_REFERENCE.md
├─ Search by topic (Ctrl+F: "ETL", "UI", etc.)
├─ Check "Common Scenarios" section
└─ Identify 3-5 relevant principle numbers

Step 3: Read Principle Details
├─ Navigate to natural/en/part1_principles/
├─ Read the .qmd files for identified principles
└─ Understand requirements and constraints

Step 4: Verify No Conflicts
├─ Check "Principle Relationships" section
├─ Ensure approach doesn't violate any principles
└─ Document planned approach

Step 5: Implement with Documentation
├─ Write code following identified principles
├─ Comment which principles each section follows
└─ Prepare CHANGELOG entry citing principles
```

**Example:**
```
User asks: "Create a new derivation for customer segmentation"

Step 1: Task = Derivation development
Step 2: QUICK_REFERENCE.md → "Scenario 2: Creating a Derivation Script"
Step 3: Read DM_R044, DM_R042, MP029, DM_R002
Step 4: Check no conflicts with existing derivations
Step 5: Implement using template, document in CHANGELOG/
```

---

### Workflow B: Debugging an Issue

```
Step 1: Create Debug Script
├─ Location per SO_R034: temporary debug script
├─ Follow MP046: Debug Code Tracing
└─ Use MP093: Data Visualization Debugging

Step 2: Root Cause Analysis
├─ Apply MP050: Root Cause Resolution
├─ Check DEV_R035: Code Compliance Tracking
└─ Verify principle violations

Step 3: Fix with Minimal Changes
├─ Follow DEV_R008: Minimal Modification
├─ Apply DEV_R016: Evolution Over Replacement
└─ Document which principles fix follows

Step 4: Document & Archive
├─ Create debug report in CHANGELOG/ per SO_R030
├─ Use template from SO_R032
└─ Archive debug script per SO_R034
```

---

### Workflow C: Code Review

```
Step 1: Architecture Review
├─ Check MP064 (ETL/Derivation Separation) compliance
├─ Verify MP108 (ETL Phase Sequence) if ETL
└─ Validate UI_R001 (Triple Pattern) if Shiny module

Step 2: Data Integrity Check
├─ CRITICAL: Verify MP029 (No Fake Data)
├─ Check DM_R002 (tbl2 usage) for DB access
└─ Validate DM_R047 (Multi-Platform Sync) if multi-platform

Step 3: Code Quality Check
├─ SO_R007: One Function One File?
├─ MP071: Type-prefix naming correct?
├─ DEV_R020: Objects initialized before use?
└─ DEV_R030: Explicit namespacing in Shiny?

Step 4: Security Check
├─ SEC_R001: No hardcoded credentials?
├─ SEC_R002: Environment variables used?
└─ SEC_R003: .gitignore configured?

Step 5: Documentation Check
├─ MP012: Changes documented in CHANGELOG/?
├─ SO_R030: Docs in correct location?
└─ Principle compliance documented?
```

---

### Workflow D: Architectural Changes

```
⚠️ STOP: Architectural changes require extra diligence

Step 1: Principle System Check
├─ Read MP097: Principle-Implementation Separation
├─ Check if change requires NEW principle
└─ Verify change doesn't violate existing principles

Step 2: Consult Meta-Principles
├─ MP001-MP008: Foundation principles
├─ MP064, MP108: Core architecture (if data-related)
└─ MP018: Functor-Module Correspondence (if modular)

Step 3: Document Architecture Decision
├─ Create ADR (Architecture Decision Record) in CHANGELOG/
├─ Cite all relevant principles
├─ Explain why change is necessary
└─ Get user approval before proceeding

Step 4: Update Principles if Needed
├─ Draft new principle if pattern is reusable
├─ Update QUICK_REFERENCE.md
├─ Update INDEX.md
└─ Create CHANGELOG entry for principle update
```

---

## 🔍 Search Strategies

### Strategy 1: Known Principle Number

```bash
# Direct lookup in QUICK_REFERENCE.md
Ctrl+F: "MP029"
Ctrl+F: "DM_R041"

# Read principle file
Read: natural/en/part1_principles/.../MP029_discrepancy_principle.qmd
```

### Strategy 2: Topic-Based Search

```bash
# Search QUICK_REFERENCE.md topic sections
Ctrl+F: "ETL & Data Pipelines"
Ctrl+F: "Naming Conventions"
Ctrl+F: "Shiny UI Components"

# Browse principle list in that section
# Read relevant principle files
```

### Strategy 3: Scenario-Based Search

```bash
# Look up common scenario in QUICK_REFERENCE.md
Navigate to: "Common Scenarios"
Find: "Scenario 1: Building a New ETL Pipeline"

# Follow checklist with principle numbers
# Read each principle file mentioned
```

### Strategy 4: Relationship-Based Search

```bash
# Find principle family in QUICK_REFERENCE.md
Navigate to: "Principle Relationships"
Find: "MP029 (No Fake Data) Family"

# Read all related principles
# Understand the hierarchy
```

---

## ⚡ Quick Decision Trees

### Decision Tree: Data Access

```
Need to access database table?
│
├─ YES → Use DM_R002 (tbl2 pattern)
│   │
│   ├─ Multi-platform? → Check DM_R047
│   ├─ Need to filter? → Check DM_R010, DM_R018
│   └─ Working with IDs? → Check DM_R015, DM_R019, DM_R020
│
└─ NO → Creating new data?
    │
    └─ CHECK MP029 - NO FAKE DATA! ⚠️
```

### Decision Tree: ETL Development

```
Building ETL pipeline?
│
├─ Understand MP064 (ETL vs Derivation)
│
├─ Is this ETL or DRV?
│   │
│   ├─ ETL (External data) → Follow MP108 (Phase Sequence)
│   │   │
│   │   ├─ Use DM_R041 (Directory: scripts/update_scripts/ETL/)
│   │   ├─ Apply DM_R037 (Company prefix: cbz_, eby_)
│   │   └─ Follow DM_R028 (Data type separation)
│   │
│   └─ DRV (Derived data) → Follow DM_R044 (Derivation Standard)
│       │
│       ├─ Use DM_R042 (Numbering: D01, D02, D03...)
│       ├─ Place in scripts/derivations/
│       └─ Follow template in part2_implementations/CH13_derivations/
│
└─ ALWAYS check MP029 (No Fake Data)
```

### Decision Tree: UI Component

```
Creating Shiny component?
│
├─ Apply UI_R001 (UI-Server-Defaults Triple)
│   │
│   ├─ Create componentUI.R
│   ├─ Create componentServer.R
│   └─ Create componentDefaults.R
│
├─ Has data access? → Use DEV_R022 (Pass connection, not data)
│
├─ Has AI/OpenAI call? → MUST add UI_R019 (Progress notification)
│
├─ Using ShinyJS? → Follow DEV_R036 (Module namespace)
│
└─ Check UI_R010 (ID consistency across triple)
```

---

## 📋 Principle Compliance Checklist

Use this checklist before committing any code:

### General (Always Check)
- [ ] **MP029**: No fake/sample/mock data in production
- [ ] **SO_R007**: One function per file (fn_*.R)
- [ ] **MP071**: Type-prefix naming used
- [ ] **MP012**: Changes documented in CHANGELOG/
- [ ] **DEV_R035**: Principle compliance tracked

### Data Operations
- [ ] **DM_R002**: Used tbl2() for database access
- [ ] **MP054**: No fake data (double-check)
- [ ] **DM_R047**: Multi-platform sync if needed
- [ ] **R119**: df_ prefix for all dataframes

### ETL/Derivations
- [ ] **MP064**: Correct ETL vs DRV classification
- [ ] **MP108**: ETL phase sequence followed
- [ ] **DM_R041**: Files in correct directory
- [ ] **DM_R044**: Derivation template used
- [ ] **DM_R037**: Company prefix correct

### UI Components
- [ ] **UI_R001**: UI-Server-Defaults triple complete
- [ ] **DEV_R022**: Passing connection not data
- [ ] **UI_R019**: AI notification if >2 sec operation
- [ ] **UI_R010**: Component ID consistency
- [ ] **DEV_R036**: ShinyJS namespace if used

### Security
- [ ] **SEC_R001**: No hardcoded credentials
- [ ] **SEC_R002**: Environment variables used
- [ ] **SEC_R003**: .gitignore configured

### Documentation
- [ ] **SO_R030**: Docs in CHANGELOG/ directory
- [ ] **SO_R032**: Documentation template used
- [ ] **SO_R034**: Debug scripts archived
- [ ] **MP012**: Principle numbers cited

---

## 🎓 Progressive Learning Path

### Phase 1: Critical Principles (Week 1)
**Read these first - they affect 80% of daily work:**

1. **MP029** - No Fake Data (ABSOLUTE REQUIREMENT)
2. **MP064** - ETL/Derivation Separation (Core architecture)
3. **DM_R002** - tbl2 Universal Access (Every database query)
4. **SO_R007** - One Function One File (Code organization)
5. **MP071** - Type-Prefix Naming (Naming everything)
6. **MP012** - Change Tracking (Documentation requirement)
7. **SO_R030** - Operational Docs Location (Where to put docs)

**Practice**: Create a simple derivation script following all 7 principles.

---

### Phase 2: Architecture Understanding (Week 2)
**Understand the system structure:**

1. **MP108** - ETL Phase Sequence (1ST → 2TR → 3RD)
2. **DM_R041** - ETL Directory Structure
3. **DM_R044** - Derivation Implementation Standard
4. **UI_R001** - UI-Server-Defaults Triple
5. **MP018** - Functor-Module Correspondence
6. **DEV_R022** - Module Data Connection

**Practice**: Build a complete ETL pipeline and a Shiny module.

---

### Phase 3: Advanced Patterns (Week 3)
**Master complex scenarios:**

1. **DM_R047** - Multi-Platform Synchronization
2. **UI_R019** - AI Process Notification
3. **MP123** - AI Prompt Configuration
4. **DEV_R036** - ShinyJS Module Namespace
5. **MP093** - Data Visualization Debugging
6. **DEV_R035** - Code Compliance Tracking

**Practice**: Create a multi-platform feature with AI integration.

---

### Phase 4: Security & Quality (Week 4)
**Production-ready development:**

1. **SEC_R001-003** - Security principles
2. **TD_R001-005** - Testing/Deployment
3. **MP136** - Configuration-Init Pattern
4. **MP050** - Root Cause Resolution
5. **DEV_R016** - Evolution Over Replacement

**Practice**: Deploy an application with full security compliance.

---

## 🚨 Critical Mistakes to Avoid

### Mistake 1: Skipping QUICK_REFERENCE.md
**Wrong approach:**
```
User: "Create ETL for eBay data"
Claude: *Directly starts writing ETL code*
```

**Correct approach:**
```
User: "Create ETL for eBay data"
Claude: *Reads QUICK_REFERENCE.md → "Scenario 1: Building ETL"*
Claude: *Identifies MP064, MP108, DM_R041, DM_R037*
Claude: *Reads those 4 principle files*
Claude: *Then writes code following principles*
```

---

### Mistake 2: Not Checking MP029
**Wrong approach:**
```r
# Creating sample data for testing
test_customers <- data.frame(
  customer_id = 1:100,
  purchase_amount = rnorm(100, mean = 50, sd = 10)
)
```
❌ **VIOLATES MP029 - NEVER CREATE FAKE DATA**

**Correct approach:**
```r
# Using real data from database per MP029 and DM_R002
test_customers <- tbl2(con, "df_customer") %>%
  filter(created_date >= '2024-01-01') %>%
  collect()
```
✅ **Follows MP029, DM_R002**

---

### Mistake 3: Using tbl() Instead of tbl2()
**Wrong approach:**
```r
customers <- tbl(con, "customers") %>% collect()
```
❌ **VIOLATES DM_R002**

**Correct approach:**
```r
customers <- tbl2(con, "df_customer") %>% collect()
```
✅ **Follows DM_R002, R119**

---

### Mistake 4: Multiple Functions in One File
**Wrong approach:**
```r
# File: customer_analysis.R
analyze_customer <- function() { ... }
segment_customer <- function() { ... }
score_customer <- function() { ... }
```
❌ **VIOLATES SO_R007**

**Correct approach:**
```
fn_analyze_customer.R  → analyze_customer()
fn_segment_customer.R  → segment_customer()
fn_score_customer.R    → score_customer()
```
✅ **Follows SO_R007, SO_R026**

---

### Mistake 5: Shiny Module Without Triple
**Wrong approach:**
```r
# Only creating customerUI.R and customerServer.R
```
❌ **VIOLATES UI_R001**

**Correct approach:**
```
customerUI.R        → UI definition
customerServer.R    → Server logic
customerDefaults.R  → Default values/config
```
✅ **Follows UI_R001, SO_R027**

---

### Mistake 6: Documentation in Wrong Location
**Wrong approach:**
```
project_root/
├─ ETL_FIX_REPORT.md          ❌
├─ DEBUG_CUSTOMER_ISSUE.md    ❌
└─ IMPLEMENTATION_NOTES.md    ❌
```
❌ **VIOLATES SO_R030**

**Correct approach:**
```
CHANGELOG/
├─ 2025-11-30_etl_fix_report.md        ✅
├─ 2025-11-30_debug_customer_issue.md  ✅
└─ 2025-11-30_implementation_notes.md  ✅
```
✅ **Follows SO_R030, SO_R032**

---

## 💡 Power User Tips

### Tip 1: Principle Number Memory Aids
**Core principles by frequency:**
- **MP029**: "No Fake Data" - MOST CRITICAL
- **MP064**: "ETL/Derivation Separation" - Architecture foundation
- **MP108**: "ETL Phase Sequence" - 1ST, 2TR, 3RD
- **DM_R002**: "tbl2 everywhere" - Database access
- **SO_R007**: "One file one function" - Code organization
- **UI_R001**: "Triple pattern" - Shiny modules

**Remember: 029, 064, 108, R002, R007, R001**

---

### Tip 2: Quick Grep Patterns
```bash
# Find all principles about ETL
grep -r "ETL" QUICK_REFERENCE.md

# Find all DM_R principles
grep "DM_R" QUICK_REFERENCE.md

# Find all security principles
grep "SEC_R\|MP11[0-8]" QUICK_REFERENCE.md
```

---

### Tip 3: Principle Relationship Shortcuts

When you see one principle, check its family:
- **MP029** → Also check MP054, MP047, TD_R001
- **MP064** → Also check MP108, DM_R041, DM_R044
- **UI_R001** → Also check SO_R027, UI_R010, DEV_R022

**Use "Principle Relationships" section in QUICK_REFERENCE.md**

---

### Tip 4: Scenario Template Reuse

**Save time by using scenario templates:**
1. QUICK_REFERENCE.md → "Common Scenarios"
2. Copy relevant scenario checklist
3. Adapt to specific task
4. Check off each principle as you apply it

---

## 🔧 Advanced Techniques

### Technique 1: Principle-Driven Debugging

When debugging, work backwards from principles:

```
Problem: ETL script fails
↓
Check MP108: Is phase sequence correct?
↓
Check DM_R041: Are files in right directory?
↓
Check MP029: Is fake data causing issues?
↓
Check DM_R002: Is tbl2 used correctly?
```

---

### Technique 2: Pre-Implementation Principle Audit

Before writing code, create a principle compliance plan:

```markdown
## Principle Compliance Plan

### Task: Create customer RFM derivation

### Identified Principles:
- DM_R044: Derivation Implementation Standard
- DM_R042: Use D03 numbering (after D01, D02)
- MP029: Use real customer data
- DM_R002: Access via tbl2()
- SO_R007: Create fn_calculate_rfm.R
- R119: Output table named df_customer_rfm

### Implementation Steps:
1. Create D03_customer_rfm.R per DM_R042
2. Use derivation template per DM_R044
3. Read df_customer via tbl2() per DM_R002
4. No fake data per MP029
5. Output to df_customer_rfm per R119
6. Document in CHANGELOG/ per SO_R030
```

---

### Technique 3: Principle Conflict Resolution

If two principles seem to conflict:

```
Step 1: Check principle hierarchy
MP > SO_R/DM_R/DEV_R/UI_R > specific rules

Step 2: Check "Principle Relationships" section
Are they meant to work together?

Step 3: Read both principles in detail
Often apparent conflict is complementary

Step 4: Consult user if still unclear
Document the ambiguity
```

---

## 📊 Principle Usage Statistics

**Most Referenced Principles (by scenario):**

| Rank | Principle | Usage % | Category |
|------|-----------|---------|----------|
| 1 | MP029 | 95% | Data Integrity |
| 2 | DM_R002 | 85% | Database Access |
| 3 | SO_R007 | 80% | Code Organization |
| 4 | MP064 | 75% | Architecture |
| 5 | MP071 | 70% | Naming |
| 6 | MP012 | 65% | Documentation |
| 7 | UI_R001 | 60% | UI Development |
| 8 | MP108 | 55% | ETL Development |
| 9 | DM_R041 | 50% | File Organization |
| 10 | DEV_R022 | 45% | Data Flow |

**Implication**: Master the top 10, and you'll handle most tasks correctly.

---

## 🎯 Final Checklist for Every Task

Before you respond to any user request:

### Pre-Work Checklist
- [ ] Identified task category (ETL, UI, Database, Testing, etc.)
- [ ] Searched QUICK_REFERENCE.md for relevant principles
- [ ] Read 3-5 most critical principle .qmd files
- [ ] Checked "Common Scenarios" for similar task
- [ ] Verified no principle conflicts

### During-Work Checklist
- [ ] Following identified principles step-by-step
- [ ] Documenting which principle each code section follows
- [ ] Checking MP029 (No Fake Data) continuously
- [ ] Using correct naming conventions (MP071)
- [ ] Organizing files correctly (SO_R007, DM_R041)

### Post-Work Checklist
- [ ] All principles documented in code comments
- [ ] CHANGELOG entry created in correct location (SO_R030)
- [ ] Principle numbers cited in CHANGELOG
- [ ] No security violations (SEC_R001-003)
- [ ] Ready to explain principle compliance to user

---

**Remember**: Principles are not suggestions. They are **mandatory rules** that ensure MAMBA system integrity, maintainability, and scalability.

**When in doubt**: Read the principle file. If still unclear, ask the user.

---

**Last Updated**: 2025-11-30
**Maintainer**: MAMBA Development Team
