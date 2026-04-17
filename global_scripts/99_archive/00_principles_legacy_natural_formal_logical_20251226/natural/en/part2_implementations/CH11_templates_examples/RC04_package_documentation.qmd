# RC04: Package Documentation Reference Code

## Purpose

This reference code provides standardized templates and examples for package documentation according to the two-tier documentation system established by MP57, R103, and R104.

## Documentation Structure

### New Folder Structure

1. **Project-Specific Documentation** (`/20_R_packages/`)
   ```
   /20_R_packages/
   ├── package_name/
   │   ├── index.md           # Package overview
   │   ├── usage_pattern1.md  # Common usage pattern
   │   ├── usage_pattern2.md  # Another usage pattern
   │   └── integration.md     # Project integration examples
   ```

2. **Cross-Project Reference** (`/precision_marketing/R_package_references/`)
   ```
   /precision_marketing/R_package_references/
   ├── package_name/
   │   ├── index.md           # Package index
   │   ├── function1.md       # Function documentation
   │   └── function2.md       # Function documentation
   ```

### Documentation Workflow

#### For Project-Specific Documentation:
1. Create package folder in `/update_scripts/global_scripts/20_R_packages/` if it doesn't exist
2. Add individual markdown files for each usage pattern
3. Create an index.md file that links to all usage patterns
4. Reference from code with `@uses_package`

#### For Cross-Project Documentation:
1. Clone the repository
2. Create a branch
3. Add documentation following RC05 templates
4. Submit a PR
5. Reference from code with `@uses_function`

### Standard File Header Reference

```r
#' @file example.R
#' @principle R103 Package Documentation Reference Rule
#' @principle R104 Package Function Reference Rule
#' @uses_package dplyr See 20_R_packages/dplyr/index.md
#' @uses_function dplyr::filter See /precision_marketing/R_package_references/dplyr/filter.md
```

## Documentation Templates

### 1. Project-Specific Package Index (`/20_R_packages/package_name/index.md`)

```markdown
# package_name Usage Guide

## Package Overview

Brief description of the package and its purpose in the project.

## Core Components

| Component | Description | Documentation Link |
|-----------|-------------|-------------------|
| Usage Pattern 1 | Description | [usage_pattern1.md](./usage_pattern1.md) |
| Usage Pattern 2 | Description | [usage_pattern2.md](./usage_pattern2.md) |
| Integration Examples | Description | [integration.md](./integration.md) |

## Version Information

- **Required Version**: package_name >= x.y.z
- **Current Project Version**: x.y.z
- **Key Dependencies**: dep1, dep2

## Related Principles

- **Principle1**: Description
- **Principle2**: Description
```

### 2. Project-Specific Usage Pattern (`/20_R_packages/package_name/usage_pattern1.md`)

```markdown
# package_name: Usage Pattern 1

## Description

Describe what this usage pattern accomplishes.

## Code Example

```r
# Standard usage pattern example
library(package_name)
result <- function_name(params)
```

## Parameters

| Parameter | Description | Example Value |
|-----------|-------------|---------------|
| param1 | Description | Example |
| param2 | Description | Example |

## Notes

Additional information about this usage pattern.

## Related Usage Patterns

- [Usage Pattern 2](./usage_pattern2.md): Brief description
```

### 3. Project-Specific Integration Example (`/20_R_packages/package_name/integration.md`)

```markdown
# package_name: Integration Examples

## Integration with Project Components

Describe how this package integrates with specific project components.

## Example 1: Component Name

```r
# Example showing integration with project components
```

## Example 2: Another Component

```r
# Another integration example
```

## Troubleshooting

Common issues and their solutions.

## Best Practices

1. Best practice 1
2. Best practice 2
```

### 4. Cross-Project Function Reference (`/precision_marketing/R_package_references/package_name/function_name.md`)

```markdown
# function_name

## Description
Brief description of the function's purpose.

## Usage
```r
function_name(param1, param2, ...)
```

## Arguments
| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| param1 | Type | Description of param1 | Default value |
| param2 | Type | Description of param2 | Default value |
| ... | ... | ... | ... |

## Return Value
Description of what the function returns.

## Minimal Example
```r
# Simplest possible working example
library(package_name)
result <- function_name(minimal_params)
print(result)
```

## Notes
Additional information about edge cases, performance considerations, etc.

## Related Functions
- [related_function1](./related_function1.md): Brief description of relationship
- [related_function2](./related_function2.md): Brief description of relationship
```

### 5. Cross-Project Package Index (`/precision_marketing/R_package_references/package_name/index.md`)

```markdown
# package_name Function Reference Index

## Overview
Brief description of the package and its purpose in our projects.

## Core Functions

- [`function_name1()`](./function_name1.md): Brief description
- [`function_name2()`](./function_name2.md): Brief description

## Helper Functions

- [`helper_function1()`](./helper_function1.md): Brief description

## Using This Reference

Instructions specific to this package.

## Related Documentation

- [Project-level documentation](../../../precision_marketing_MAMBA/precision_marketing_app/update_scripts/global_scripts/20_R_packages/package_name/index.md)
- [Official documentation](https://package-url.org)
```

## Code Header References

### Standard Package Documentation Reference

```r
#' @file example_analysis.R
#' @principle R103 Package Documentation Reference Rule
#' @uses_package dplyr See 20_R_packages/dplyr/index.md
```

### Detailed Function Reference

```r
#' @file example_analysis.R
#' @principle R104 Package Function Reference Rule
#' @uses_function dplyr::filter See /precision_marketing/R_package_references/dplyr/filter.md
#' @uses_function dplyr::select See /precision_marketing/R_package_references/dplyr/select.md
```

## Example: dplyr Package Structure

### Project-Specific Documentation:

```
/20_R_packages/
├── dplyr/
│   ├── index.md                 # Package overview
│   ├── data_pipeline.md         # Common data pipeline pattern
│   ├── filtering.md             # Filtering usage patterns
│   ├── grouping_summarizing.md  # Group by and summarize patterns
│   └── integration.md           # Integration with project components
```

### Cross-Project Documentation:

```
/precision_marketing/R_package_references/
├── dplyr/
│   ├── index.md      # Package index
│   ├── filter.md     # filter() function documentation
│   ├── select.md     # select() function documentation 
│   ├── mutate.md     # mutate() function documentation
│   └── ...           # Additional function documentation
```

## Related Documents and Rules

- **MP57**: Package Documentation Meta-Principle
- **R103**: Package Documentation Reference Rule (Project documentation references)
- **R104**: Package Function Reference Rule (Function documentation with examples)
- **RC05**: Cross-Project References (Templates for cross-project docs)
- **MP19**: Package Consistency Principle
- **P72**: UI Package Consistency
- **R95**: Import Requirements Rule