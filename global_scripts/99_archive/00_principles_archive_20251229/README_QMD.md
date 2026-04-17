# Principles QMD Documentation System

This directory contains the QMD (Quarto Markdown) version of the AI MarTech development principles, designed for enhanced cross-referencing and AI readability.

## Quick Start

### 1. Install Quarto

```bash
# macOS (with Homebrew)
brew install quarto

# Or download from https://quarto.org/docs/get-started/
```

### 2. Build the Documentation

```bash
cd /path/to/00_principles
quarto render
```

### 3. Preview the Site

```bash
quarto preview
```

The documentation will be available at `http://localhost:3000`

## Structure

```
00_principles/
├── _quarto.yml                 # Quarto configuration
├── index.qmd                   # Main landing page
├── styles.css                  # Custom styling
├── principles_qmd/             # QMD principle files
│   ├── MP018_dont_repeat_yourself.qmd
│   ├── MP044_functor_module_correspondence.qmd
│   ├── R067_functional_encapsulation.qmd
│   └── D00_data_processing_overview.qmd
├── principles/                 # Original .md files (preserved)
└── _site/                      # Generated documentation (auto-created)
```

## Cross-Reference System

### Principle References

Use the `@` symbol followed by the principle ID:

- `@mp018` → Links to MP018: Don't Repeat Yourself
- `@mp044` → Links to MP044: Functor-Module Correspondence  
- `@r067` → Links to R067: Functional Encapsulation
- `@d01` → Links to D01: DNA Analysis

### Section References

Reference specific sections within documents:

- `@sec-dry` → Links to the DRY section
- `@sec-framework` → Links to the framework section

### Benefits for AI Reading

1. **Semantic Linking**: AI can understand principle relationships through `@` references
2. **Structured Navigation**: Clear hierarchy and cross-references
3. **Enhanced Context**: Rich metadata in YAML front matter
4. **Executable Examples**: Code blocks can be executed and validated

## Key Features

### 1. Enhanced Cross-References

```qmd
## Related Principles

This principle works with:
- @mp018 for eliminating duplication
- @r067 for function extraction
- @mp044 for module organization

See @sec-implementation for details.
```

### 2. Rich Callouts

```qmd
::: {.callout-warning}
## Critical Issue
Code duplication violates @mp018
:::

::: {.callout-tip}
## Best Practice
Apply @r067 to extract reusable functions
:::
```

### 3. Executable Code

```qmd
```{r}
#| label: example-code
#| eval: false

# Code examples that can be executed and validated
process_data <- function(input) {
  # Implementation following @mp018
}
```
```

### 4. Interactive Tables

```qmd
```{r}
#| echo: false
#| eval: true

library(DT)
datatable(principles_summary)
```
```

## Adding New Principles

### 1. Create QMD File

```bash
touch principles_qmd/MP999_new_principle.qmd
```

### 2. Use Standard Template

```qmd
---
title: "MP999: New Principle"
subtitle: "Brief description"
id: mp999
type: meta-principle
date_created: "2025-07-12"
author: "Your Name"
derives_from:
  - mp000
influences:
  - other-principles
format:
  html:
    toc: true
    code-fold: show
---

# Principle Title {#sec-title}

::: {.callout-important}
## Core Principle
Statement of the core principle
:::

## Content sections...
```

### 3. Update Navigation

Add to `_quarto.yml`:

```yaml
website:
  navbar:
    left:
      - text: "Meta Principles (MP)"
        menu:
          - principles_qmd/MP999_new_principle.qmd
```

### 4. Add Cross-References

Reference the new principle from related documents:

```qmd
For additional guidance, see @mp999.
```

## Current Focus: D-Series Duplication

The QMD system specifically addresses the code duplication issues identified in the D-series:

- **@d00**: Overview of duplication problems and solutions
- **@mp018**: DRY principle for eliminating duplication
- **@mp044**: Functor-Module correspondence for unified modules
- **@r067**: Functional encapsulation for extracting reusable functions

## AI Integration Benefits

### 1. Structured Understanding

AI can parse the YAML front matter to understand:
- Principle relationships (`derives_from`, `influences`)
- Applicable contexts (`applies_to`)
- Principle types and hierarchy

### 2. Semantic Navigation

Cross-references provide semantic meaning:
- `@mp018` clearly indicates a meta-principle reference
- `@sec-framework` indicates a section reference
- Links preserve context and relationships

### 3. Executable Validation

Code examples can be executed to validate:
- Principle compliance
- Implementation correctness
- Example functionality

## Building and Deployment

### Local Development

```bash
# Watch for changes and auto-rebuild
quarto preview

# Build for production
quarto render

# Check for broken links
quarto check
```

### Integration with Git Workflows

The QMD system integrates with existing Git workflows:

```bash
# Add new principle
git add principles_qmd/MP999_new_principle.qmd
git commit -m "Add MP999: New Principle"

# Build documentation
quarto render
git add _site/
git commit -m "Update generated documentation"
```

## Customization

### Styling

Modify `styles.css` to customize appearance:

```css
/* Custom principle styling */
.principle-id {
  background-color: #your-color;
}
```

### Navigation

Update `_quarto.yml` to modify navigation structure:

```yaml
website:
  sidebar:
    contents:
      - section: "Your Section"
        contents:
          - your-file.qmd
```

## Troubleshooting

### Common Issues

1. **Broken cross-references**: Ensure principle IDs match file names
2. **Missing navigation**: Update `_quarto.yml` when adding files
3. **Rendering errors**: Check YAML front matter syntax

### Validation

```bash
# Check for issues
quarto check

# Validate specific file
quarto render principles_qmd/MP018_dont_repeat_yourself.qmd
```

## Migration from Markdown

The original `.md` files in the `principles/` directory are preserved. The QMD versions provide enhanced functionality while maintaining compatibility.

## Next Steps

1. **Convert priority principles** to QMD format
2. **Add interactive examples** for key principles  
3. **Implement automated validation** of principle compliance
4. **Enhance cross-reference system** with automatic relationship detection

---

For questions or contributions to the QMD documentation system, refer to the development team or create an issue in the project repository.