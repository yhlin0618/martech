---
id: "R03"
title: "Principle Documentation"
type: "rule"
date_created: "2025-04-02"
author: "Claude"
implements:
  - "MP02": "Structural Blueprint"
related_to:
  - "R01": "Directory Structure"
  - "R02": "File Naming Convention"
  - "MP00": "Axiomatization System"
---

# Principle Documentation Rules

This rule establishes the required format, structure, and content for documenting principles, meta-principles, and rules in the precision marketing codebase, ensuring comprehensive and consistent documentation across all conceptual elements.

## Core Concept

All principles, meta-principles, and rules must be thoroughly documented using a standardized format that includes clear metadata, properly structured content, and explicit relationships to other principles, facilitating understanding, navigation, and maintenance of the system's conceptual framework.

## YAML Front Matter Requirements

Every principle document must begin with YAML front matter that includes the following required metadata:

```yaml
---
id: "TYPE##"          # Required: Principle identifier (e.g., "MP01")
title: "Title"        # Required: Concise descriptive title
type: "type"          # Required: One of "meta-principle", "principle", or "rule"
date_created: "YYYY-MM-DD" # Required: Creation date
date_modified: "YYYY-MM-DD" # Optional: Last modification date
author: "Name"        # Required: Original author
derives_from:         # Optional: Principles this principle is based on
  - "ID1": "Title1"   # ID and title of source principle
  - "ID2": "Title2"
influences:           # Optional: Principles this principle affects
  - "ID3": "Title3"
  - "ID4": "Title4"
implements:           # Optional: For rules, which principles they implement
  - "ID5": "Title5"
extends:              # Optional: Principles this principle refines
  - "ID6": "Title6"
related_to:           # Optional: For more general relationships
  - "ID7": "Title7"
---
```

### Front Matter Rules

1. **Required Fields**
   - `id`: Must match the file name prefix and follow MP/P/R classification
   - `title`: Must be descriptive and concise (3-5 words recommended)
   - `type`: Must be one of "meta-principle", "principle", or "rule"
   - `date_created`: Must use YYYY-MM-DD format
   - `author`: Must identify the principle's creator

2. **Relationship Fields**
   - At least one relationship field is required for all documents except MP00
   - Relationship values must include both ID and title, formatted as shown above
   - IDs must be valid and reference existing principles
   - The relationship type must accurately reflect the nature of the connection:
     - `derives_from`: Foundational principles that informed this one
     - `influences`: Principles that this principle affects or shapes
     - `implements`: For rules, the principles they put into practice
     - `extends`: Principles this one builds upon or refines
     - `related_to`: For more general or bidirectional relationships

3. **Consistency Requirements**
   - If principle A lists principle B in its `influences` field, principle B should list principle A in its `derives_from` field
   - If a rule lists a principle in its `implements` field, that principle should list the rule in its `influences` field
   - All relationships should be bidirectional and consistent

## Document Structure Requirements

All principle documents must follow this general structure:

```markdown
---
YAML front matter as specified above
---

# Title of the Principle

Brief introduction explaining the principle's purpose and importance (1-3 sentences).

## Core Concept

Concise explanation of the fundamental idea that the principle embodies (1-2 paragraphs).

## Additional Sections as Needed

Content organized in logical sections that fully explain the principle.

## Relationship to Other Principles

Explicit description of how this principle relates to others referenced in the front matter.

## Additional Optional Sections

Implementation examples, historical context, or other relevant information.
```

### Section Requirements

1. **Title and Introduction**
   - Must begin with a level-1 heading matching the title in front matter
   - Must provide a brief, clear introduction explaining the principle's purpose
   - Introduction should be 1-3 sentences and appear before any section headings

2. **Core Concept Section**
   - Required for all principles
   - Must be the first main section after the introduction
   - Must concisely explain the central idea of the principle
   - Should be 1-2 paragraphs in length

3. **Content Sections**
   - Must use logical organization with clear section headings
   - Must use level-2 headings (##) for main sections
   - Must use level-3 headings (###) for subsections
   - All code examples must be properly formatted in code blocks
   - All lists must use consistent formatting
   - Content should be comprehensive but concise

4. **Relationship Section**
   - Required for all principles that have relationships
   - Must explain how the principle relates to others referenced in front matter
   - May be omitted only if the principle has no relationships (rare)

## Document Content Guidelines

### Meta-Principles (MP)

Meta-principles must include:
1. Philosophical justification for the principle
2. Abstract reasoning that explains WHY the principle exists
3. Broad implications for system design
4. How it influences derived principles

### Principles (P)

Principles must include:
1. Practical guidelines that explain HOW to implement the meta-principle
2. Architectural patterns related to the principle
3. Design considerations when applying the principle
4. Examples of the principle in practice

### Rules (R)

Rules must include:
1. Specific implementation details that explain WHAT to do
2. Concrete practices and standards
3. Specific examples or code patterns
4. Clear criteria for compliance with the rule

## Implementation Examples

### Example 1: Meta-Principle Document

```markdown
---
id: "MP02"
title: "Structural Blueprint"
type: "meta-principle"
date_created: "2025-04-02"
author: "Claude"
derives_from:
  - "MP00": "Axiomatization System"
influences:
  - "P04": "Script Separation"
  - "R01": "Directory Structure"
---

# Structural Blueprint

This document serves as the authoritative blueprint for the system's structure, defining the fundamental organization and architecture.

## Core Concept

Systems must be organized according to a consistent structure that facilitates navigation, maintainability, and comprehension. This structure must reflect the system's logical components and their relationships.

...
```

### Example 2: Rule Document

```markdown
---
id: "R01"
title: "Directory Structure"
type: "rule"
date_created: "2025-04-02"
author: "Claude"
implements:
  - "MP02": "Structural Blueprint"
related_to:
  - "R02": "File Naming Convention"
---

# Directory Structure Rules

This rule establishes specific guidelines for organizing files and directories in the precision marketing codebase.

## Core Concept

The codebase must follow a standardized directory structure that clearly indicates the purpose and loading order of different components.

...
```

## Document Maintenance Rules

1. **Update Requirements**
   - When modifying a principle, update the `date_modified` field
   - When adding new relationships, update both principles to maintain consistency
   - When reclassifying a principle, update all references in other principles

2. **Version Control**
   - Document significant changes in `update_scripts/records/`
   - Include the reason for changes and their impact

3. **Consistency Checks**
   - Periodically review all principles for relationship consistency
   - Ensure all referenced principles exist
   - Verify that bidirectional relationships are properly maintained

## Relationship to Other Rules

This rule implements MP02 (Structural Blueprint) and works in conjunction with:
- R01 (Directory Structure): Ensures principles are properly organized in the directory structure
- R02 (File Naming Convention): Establishes how principle documents are named
- MP00 (Axiomatization System): Provides the foundational framework for principles organization

## Conclusion

Thorough and consistent documentation of principles is essential for maintaining a clear conceptual framework that guides the entire system. These documentation rules ensure that all principles are properly described, related, and organized, facilitating understanding and consistent application throughout the codebase.