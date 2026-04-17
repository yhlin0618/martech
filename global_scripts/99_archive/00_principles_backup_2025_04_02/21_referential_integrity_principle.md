# Referential Integrity Principle

This document establishes the "Referential Integrity Principle" as a meta-principle that ensures all references in code (to functions, variables, files, etc.) actually exist and are valid.

## Core Concept

All names referenced in code must resolve to actual entities in the codebase or standard libraries. This principle ensures that code is robust against errors that would only be detected at runtime, particularly in a dynamic language like R where references aren't checked at compile time.

## Types of References to Check

### 1. Function References

All function calls must reference functions that:
- Are defined in the current file
- Are defined in another file that is loaded
- Are part of a package that is properly imported
- Are part of base R

```r
# GOOD: Function is defined and referenced with the same name
get_r_files_recursive <- function(dir_path, pattern = "\\.R$") {
  # ...
  subdir_files <- get_r_files_recursive(subdir, pattern)  # Correct self-reference
  # ...
}

# BAD: Function is referenced with a name that doesn't exist
get_r_files_recursive <- function(dir_path, pattern = "\\.R$") {
  # ...
  subdir_files <- getRFilesRecursive(subdir, pattern)  # WRONG! This function doesn't exist
  # ...
}
```

### 2. Variable References

All variable references must be to variables that:
- Are defined in the current scope
- Are passed as parameters
- Are defined in an accessible parent scope

```r
# GOOD: Variable is defined before use
data_path <- "path/to/data"
process_data(data_path)  # Correct variable reference

# BAD: Variable is used before definition
process_data(data_path)  # WRONG! data_path isn't defined yet
data_path <- "path/to/data"
```

### 3. File References

All file paths referenced must:
- Exist in the file system
- Be accessible with current permissions
- Be referenced with correct path syntax

```r
# GOOD: File path is verified before use
file_path <- file.path("update_scripts", "global_scripts", "data.csv")
if (file.exists(file_path)) {
  data <- read.csv(file_path)
}

# BAD: File path used without verification
data <- read.csv(file.path("update_scripts", "global_scrpts", "data.csv"))  # Typo in path!
```

## Implementation Guide

### 1. Manual Verification Process

Before committing code, verify that:

1. All function calls reference existing functions
2. All variables are defined before use
3. All file paths point to existing files
4. Recursive functions call themselves with the correct name
5. Recently renamed entities are referenced by their new names everywhere

### 2. Automated Checks

Implement automated checks in the CI/CD pipeline:

1. Static analysis tools to detect undefined references
2. Test suites that exercise all code paths
3. Linting rules that enforce referential integrity
4. Custom scripts to detect common reference errors

### 3. Documentation and Logging

1. Document all defined functions, variables, and constants
2. Log when files cannot be found or functions don't exist
3. Include helpful error messages that suggest possible fixes

## Special Cases

### 1. Dynamic Reference Resolution

When using dynamic references (e.g., `get(function_name)` or `eval(parse(text = "function_call()"))`:

1. Document why dynamic resolution is necessary
2. Validate that the referenced entity exists before attempting to use it
3. Include error handling for cases where the entity doesn't exist

### 2. Lazy Evaluation

Be aware that R uses lazy evaluation, which can mask referential issues:

```r
function_that_might_error <- function(a, b) {
  if (a > 0) {
    return(a)
  } else {
    return(b)  # b is only evaluated if a <= 0
  }
}

# This works even though undefined_variable doesn't exist
result <- function_that_might_error(1, undefined_variable)  

# This fails because undefined_variable is evaluated
result <- function_that_might_error(-1, undefined_variable)  
```

### 3. NSE (Non-Standard Evaluation)

When using packages like dplyr that employ non-standard evaluation:

1. Be aware that variable references inside NSE contexts follow different rules
2. Document clearly when a function uses NSE
3. Use appropriate NSE-safe techniques like `!!` and `.data` pronoun when needed

## Best Practices

### 1. Code Review Checklist

Include these items in code reviews:

- [  ] All function references point to existing functions
- [  ] All variables are defined before use
- [  ] File paths have been verified to exist
- [  ] Recursive function calls use the correct function name
- [  ] Recently renamed entities use the new name consistently

### 2. Renaming Protocol

When renaming an entity:

1. Use search tools to find all references to the old name
2. Update all references to use the new name
3. Run tests to ensure nothing was missed
4. Consider adding a deprecated version that warns users about the new name

Example:

```r
# When renaming getRFilesRecursive to get_r_files_recursive

# Step 1: Add deprecated version
getRFilesRecursive <- function(dir_path, pattern = "\\.R$") {
  warning("'getRFilesRecursive' is deprecated. Use 'get_r_files_recursive' instead.")
  get_r_files_recursive(dir_path, pattern)
}

# Step 2: Update all references to the new name

# Step 3: Eventually remove the deprecated version
```

### 3. Regular Integrity Checks

Periodically run integrity checks on the codebase:

1. Search for function calls that don't match any function definition
2. Verify all imported packages are actually used
3. Check for file paths that no longer exist

## Conclusion

The Referential Integrity Principle is fundamental to creating robust, maintainable code. By ensuring that all references are valid, we prevent a class of errors that can be difficult to detect and debug, especially in dynamic languages like R. This principle works hand-in-hand with other meta-principles like Package Consistency and Mode Hierarchy to create a resilient codebase.