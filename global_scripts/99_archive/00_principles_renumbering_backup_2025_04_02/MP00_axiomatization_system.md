---
id: "MP00"
title: "Axiomatization System"
type: "meta-meta-principle"
date_created: "2025-04-02"
author: "Claude"
influences:
  - "MP01": "Primitive Terms and Definitions"
  - "MP02": "Structural Blueprint"
  - "MP22": "Instance vs. Principle"
  - "MP28": "Documentation Organization"
extends:
  - "MP28": "Documentation Organization Meta-Principle"
---

# Axiomatization System

This meta-principle establishes a formal axiomatic system for organizing principles, creating a consistent logical framework for the entire precision marketing system.

## Core Concept

Principles should form a coherent axiomatic system where foundational concepts are explicitly defined, relationships between concepts are formalized as axioms, and derived principles follow through logical inference. This enables verification of consistency, derivation of new principles, and rigorous reasoning about system design.

## Axiomatic Structure

### 1. Elements of the Axiomatic System

- **Primitive Terms**: Fundamental concepts that cannot be defined in terms of simpler concepts.
- **Axioms**: Self-evident or assumed statements about primitive terms.
- **Inference Rules**: Logical methods for deriving new statements from axioms.
- **Theorems**: Derived principles that follow logically from axioms and inference rules.
- **Corollaries**: Direct consequences of theorems that require minimal additional proof.

### 2. Three-Level Conceptual Framework

All principles are organized in a three-level conceptual framework that categorizes them based on their role and scope:

| Level | Code | Purpose | Nature | Example |
|-------|------|---------|--------|---------|
| **Meta-Principles** | MP | Govern principles | Abstract, foundational | Axiomatization System, Primitive Terms |
| **Principles** | P | Guide implementation | Practical, broad | Project Principles, Data Integrity |
| **Rules** | R | Define specific implementations | Concrete, specific | Roxygen Guide, YAML Configuration |

Each level in the framework serves a distinct purpose:

#### Meta-Principles (MP)
- **Purpose**: Govern how principles themselves are structured and related
- **Nature**: Abstract, conceptual, foundational
- **Scope**: System-wide architecture and organizational concepts
- **Examples**: Axiomatization system, primitive terms, structural blueprint
- **Identification**: Prefix "MP" followed by number (e.g., MP01)

#### Principles (P)
- **Purpose**: Provide core guidance for implementation
- **Nature**: Conceptual but practical, actionable guidelines
- **Scope**: Broad implementation patterns and approaches
- **Examples**: Project principles, script separation, data integrity
- **Identification**: Prefix "P" followed by number (e.g., P03) 

#### Rules (R)
- **Purpose**: Define specific implementation details
- **Nature**: Concrete, specific, directly applicable
- **Scope**: Narrow implementation techniques and specific patterns
- **Examples**: Bottom-up construction guide, roxygen documentation, YAML configuration
- **Identification**: Prefix "R" followed by number (e.g., R16)

### 3. Mapping MP/P/R to Axiomatic Concepts

The MP/P/R system maps to traditional axiomatic concepts in the following way:

| MP/P/R Classification | Axiomatic Role | Description | Example |
|-----------------------|----------------|-------------|---------|
| **MP** (Meta-Principles) | **Primitive Terms & Axioms** | Foundational definitions and principles | MP01 (Primitive Terms), MP23 (Data Source Hierarchy) |
| **MP** (Meta-Principles) | **Inference Rules** | Logic for deriving other principles | MP19 (Mode Hierarchy) |
| **P** (Principles) | **Theorems** | Derived principles from axioms | P04 (Script Separation), P05 (Data Integrity) |
| **R** (Rules) | **Corollaries** | Specific implementation guidelines | R16 (Bottom-Up Construction), R27 (YAML Configuration) |

This mapping allows us to understand how our practical MP/P/R classification relates to the formal concepts in axiomatic systems while maintaining a simpler and more intuitive classification for everyday use.

### 4. Principle Dependencies

Every principle (except primitive terms and axioms) must explicitly document:
- **Derives From**: The principles this principle is based on
- **Influences**: The principles this principle affects
- **Implements**: For rules, which principles they implement
- **Extends**: Principles this principle refines or expands upon

## Implementation Guidelines

### 1. Document Structure

Each principle document should follow a consistent structure that includes these elements:

```markdown
---
id: "MP01"             # Principle identifier (MP, P, or R with number)
title: "Short Title"   # Concise title
type: "meta-principle" # Classification (meta-principle, principle, or rule)
date_created: "2025-04-02"
author: "Claude"
derives_from:          # What this principle is based on
  - "MP00": "Axiomatization System"
influences:            # What this principle affects
  - "MP02": "Structural Blueprint"
implements:            # For Rules, which principles they implement
  - "P07": "App Construction Principles"
extends:               # What this principle expands upon
  - "MP28": "Documentation Organization"
---

# Principle Title

## Core Concept
[Brief explanation of the principle's central idea]

## [Main Content Sections]
[Detailed explanation, guidelines, examples]

## Relationship to Other Principles
[Explanation of how this principle relates to others]

## [Additional Sections as Needed]
[Implementation guidelines, best practices, etc.]
```

The YAML front matter at the beginning of each file is essential, as it formally documents the principle's classification and relationships in a machine-readable format.

### 2. Cross-Referencing System

Principles should be cross-referenced using the MP/P/R notation:

- **MP<number>**: References a Meta-Principle (e.g., MP23 refers to the Data Source Hierarchy Meta-Principle)
- **P<number>**: References a Principle (e.g., P04 refers to the Script Separation Principle)
- **R<number>**: References a Rule (e.g., R16 refers to the Bottom-Up Construction Guide Rule)

For more specific references within a principle, you can use section numbers:

- **MP23.4**: References section 4 of Meta-Principle 23
- **P04.3.2**: References section 3.2 of Principle 04

### 3. Derivation Documentation

For Principles (P) and Rules (R), include a formal derivation section in the YAML front matter using the `derives_from` field:

```yaml
---
id: "P04"
title: "Script Separation"
type: "principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "MP02": "Structural Blueprint"
  - "P03": "Project Principles"
  - "MP01": "Primitive Terms and Definitions"
influences:
  - "P07": "App Construction Principles"
  - "P17": "App Construction Function"
---
```

For Rules that implement specific Principles, use the `implements` field:

```yaml
---
id: "R16"
title: "Bottom-Up Construction Guide"
type: "rule"
date_created: "2025-04-02"
author: "Claude"
implements:
  - "P07": "App Construction Principles"
related_to:
  - "P17": "App Construction Function"
---
```

Within the body of the document, you can also include a more detailed derivation section:

```markdown
## Derivation

This principle derives from:
1. MP23 (Data Source Hierarchy): Establishes the primary data source patterns
2. P07 (App Construction Principles): Defines core implementation approaches

Through application of:
1. Hierarchical composition (inference rule I1)
2. Scope limitation (inference rule I2)
```

## Inference Rules

The system establishes these fundamental inference rules:

### I1. Hierarchical Composition

If X applies to scope S, and Y is contained within S, then X applies to Y unless explicitly excluded.

### I2. Scope Limitation

A principle may restrict the scope of another principle if it explicitly states the limitation.

### I3. Specificity Precedence

When two principles conflict, the more specific principle takes precedence over the more general one.

### I4. Explicit Override

A principle may explicitly override another principle if it states the override and provides rationale.

## Verification Process

### 1. Consistency Checking

Periodically verify that the principle system is internally consistent:

1. No principle contradicts an axiom without explicit override
2. No two axioms contradict each other
3. All derived principles have valid derivation paths from axioms

### 2. Completeness Analysis

Identify gaps in the axiomatic system:

1. Concepts used without definition
2. Assumptions made without axiomatic foundation
3. Areas of the system not covered by principles

## Axiomatization Roadmap

### Phase 1: Classification

1. Review existing principles and classify as axioms, theorems, or corollaries
2. Identify and document primitive terms used across principles
3. Formalize implicit axioms that underlie existing principles

### Phase 2: Formalization

1. Update principle documentation to include axiomatic elements
2. Add cross-references between related principles
3. Document derivation chains for theorems and corollaries

### Phase 3: Verification

1. Check for consistency across the principle system
2. Resolve any contradictions or ambiguities
3. Identify and fill gaps in the axiomatic coverage

## Benefits of Axiomatization

1. **Logical Consistency**: Ensures all principles work together harmoniously
2. **Derivation Power**: Enables derivation of new principles when needed
3. **Formal Verification**: Provides mechanisms to prove design correctness
4. **Knowledge Transfer**: Creates clearer documentation for onboarding
5. **Completeness Assessment**: Identifies gaps in principle coverage

## Relationship to Other Principles

This meta-principle builds upon:

1. **Documentation Organization Meta-Principle** (MP28): Extends organizational guidelines to include axiomatic structure
2. **Terminology Axiomatization** (MP29): Provides primitive terms and baseline axioms for the system
3. **Instance vs. Principle** (MP22): Clarifies scope of axiomatic system (principles, not instances)

## Example Application

Let's consider how this applies to three existing principles:

1. **Data Source Hierarchy** (MP23) is classified as a **Meta-Principle** because it:
   - Establishes fundamental relationships between data sources
   - Defines architectural concepts that govern other principles
   - Introduces primitive terms (App Layer, Processing Layer, etc.)

2. **Data Integrity** (P05) is classified as a **Principle** because it:
   - Provides broad implementation guidance
   - Defines practical approaches to handling data
   - Is conceptual but actionable

3. **Platform-Neutral Code** (R26) is classified as a **Rule** because it:
   - Follows directly from higher-level principles like Mode Hierarchy (MP19)
   - Provides specific implementation techniques
   - Is concrete and directly applicable to coding

## Conclusion

By transforming the principles into a formal axiomatic system, we create a more rigorous foundation for system design and development. This meta-principle guides the evolution of the principle documentation toward greater precision, consistency, and derivation power, enabling formal reasoning about system properties and requirements.