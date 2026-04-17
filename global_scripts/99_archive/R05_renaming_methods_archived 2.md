---
id: "R05_archived"
title: "Renaming Methods"
type: "archived_rule"
date_created: "2025-01-15"
date_archived: "2025-04-04"
author: "Claude"
replaced_by:
  - "M00": "Renumbering Principles Module"
reason_for_archiving: "Converted to a full module to provide better implementation and separation of concerns"
archiving_record: "2025_04_04_r05_module_conversion.md"
---

# Renaming Methods (Archived)

> **IMPORTANT: This rule has been archived.** The functionality has been converted into a full module: M00_renumbering_principles. Please refer to that module for current implementation.

## Original Content (For Historical Reference)

This rule establishes standardized methods for renaming resources within the precision marketing system, ensuring that renaming operations maintain system consistency and update all references properly.

## Core Requirement

When renaming any resource (file, function, principle, etc.), the process must:
1. Verify the new name is appropriate and not already in use
2. Create a backup of the original
3. Update all references to the resource
4. Verify system consistency after the change

## Renaming Verification

Before renaming any resource, verify that:

1. **Uniqueness**: The new name is not already in use
2. **Conventions**: The new name follows naming conventions
3. **References**: All references can be identified and updated
4. **Backup**: A backup strategy is in place

```r
# Function to verify a proposed new name
verify_unique <- function(new_name, type = "file") {
  # For files
  if (type == "file" && file.exists(new_name)) {
    return(FALSE)
  }
  
  # For principles/rules
  if (type == "principle") {
    # Extract the ID part (e.g., "R07" from "R07_module_naming_convention.md")
    id_pattern <- "^(MP|P|R)[0-9]{2}"
    id_match <- regexpr(id_pattern, new_name)
    if (id_match > 0) {
      id <- substr(new_name, id_match, id_match + attr(id_match, "match.length") - 1)
      
      # Check if this ID is already in use
      files <- list.files(pattern = paste0("^", id, "_"))
      if (length(files) > 0) {
        return(FALSE)
      }
    }
  }
  
  return(TRUE)
}
```

## Renaming Procedure

### 1. For Files

```r
# Function to rename a file and update references
rename_file <- function(old_name, new_name, update_refs = TRUE) {
  # Verify the new name
  if (!verify_unique(new_name, "file")) {
    stop("New name already exists:", new_name)
  }
  
  # Create a backup
  backup_name <- paste0(old_name, ".bak")
  file.copy(old_name, backup_name, overwrite = TRUE)
  
  # Rename the file
  file.rename(old_name, new_name)
  
  # Update references if requested
  if (update_refs) {
    # Find all files with references to the old name
    pattern <- gsub("([.\\\\+*?\\[^\\]$(){}=!<>|:\\-])", "\\\\\\1", old_name)
    files_with_refs <- system(paste0('grep -l "', pattern, '" *'), intern = TRUE)
    
    for (file in files_with_refs) {
      # Skip the backup and the new file itself
      if (file != backup_name && file != new_name) {
        # Read the file
        content <- readLines(file)
        
        # Replace references
        content <- gsub(old_name, new_name, content, fixed = TRUE)
        
        # Write the updated content
        writeLines(content, file)
      }
    }
  }
  
  # Return success
  return(TRUE)
}
```

### 2. For Principles and Rules

```r
# Function to renumber a principle/rule
renumber_resource <- function(old_id, new_id, name) {
  # Construct the filenames
  old_filename <- paste0(old_id, "_", name, ".md")
  new_filename <- paste0(new_id, "_", name, ".md")
  
  # Check if the old file exists
  if (!file.exists(old_filename)) {
    stop("Source file not found:", old_filename)
  }
  
  # Check if the new name is unique
  if (!verify_unique(new_filename, "principle")) {
    stop("Target file already exists:", new_filename)
  }
  
  # Create a backup of the original file
  backup_filename <- paste0(old_filename, ".bak")
  file.copy(old_filename, backup_filename, overwrite = TRUE)
  
  # Read the file content
  content <- readLines(old_filename)
  
  # Replace the id in the YAML frontmatter
  content <- gsub(paste0('id: "', old_id, '"'), paste0('id: "', new_id, '"'), content)
  
  # Replace any self-references in the content
  content <- gsub(paste0(old_id, " \\("), paste0(new_id, " ("), content)
  
  # Write the updated content to the new file
  writeLines(content, new_filename)
  
  # Find all references to the old ID in other files
  references <- system(paste0('grep -l "', old_id, '"', ' --include="*.md" .'), intern = TRUE)
  
  # Update references in other files
  for (file in references) {
    if (file != old_filename && file != new_filename && file != backup_filename) {
      # Read the file
      file_content <- readLines(file)
      
      # Replace references in YAML front matter
      file_content <- gsub(paste0('"', old_id, '":'), paste0('"', new_id, '":'), file_content)
      
      # Replace references in markdown links
      file_content <- gsub(paste0("\\[", old_id, "_"), paste0("[", new_id, "_"), file_content)
      file_content <- gsub(paste0("\\(", old_id, "_"), paste0("(", new_id, "_"), file_content)
      
      # Write the updated content
      writeLines(file_content, file)
    }
  }
  
  # Update README.md if it exists
  if (file.exists("README.md")) {
    readme_content <- readLines("README.md")
    readme_content <- gsub(old_filename, new_filename, readme_content)
    writeLines(readme_content, "README.md")
  }
  
  # Remove the old file only after all references are updated
  file.remove(old_filename)
  
  # Return success
  return(TRUE)
}
```

### 3. For Functions and Variables

```r
# Example function to rename functions in R code
rename_function <- function(old_name, new_name, directory = ".") {
  # Find all R files
  r_files <- list.files(directory, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)
  
  # Process each file
  for (file in r_files) {
    # Read the file
    content <- readLines(file)
    
    # Look for function definition
    definition_pattern <- paste0(old_name, "\\s*<-\\s*function\\s*\\(")
    definition_lines <- grep(definition_pattern, content)
    
    # Look for function calls
    call_pattern <- paste0("\\b", old_name, "\\s*\\(")
    call_lines <- grep(call_pattern, content)
    
    # If found, replace and save
    if (length(definition_lines) > 0 || length(call_lines) > 0) {
      # Make backups
      backup_file <- paste0(file, ".bak")
      file.copy(file, backup_file, overwrite = TRUE)
      
      # Replace function definition
      content <- gsub(paste0("\\b", old_name, "\\s*<-\\s*function"), 
                       paste0(new_name, " <- function"), 
                       content)
      
      # Replace function calls
      content <- gsub(paste0("\\b", old_name, "\\s*\\("), 
                       paste0(new_name, "("), 
                       content)
      
      # Write updated content
      writeLines(content, file)
    }
  }
  
  # Return success
  return(TRUE)
}
```

## Verification After Renaming

After renaming operations, verify system consistency:

```r
# Function to verify system consistency after renaming
verify_consistency <- function() {
  # List of issues found
  issues <- list()
  
  # Check for dangling references to old names
  # This example focuses on principles/rules
  
  # Get all principle/rule files
  files <- list.files(pattern = "^(MP|P|R)[0-9]{2}_.+\\.md$")
  
  # Extract IDs from filenames
  ids <- gsub("_.*$", "", files)
  
  # Check each file for references to non-existent IDs
  for (file in files) {
    content <- readLines(file)
    
    # Extract all references (simple pattern for example)
    ref_pattern <- "'(MP|P|R)[0-9]{2}'"
    refs <- gregexpr(ref_pattern, paste(content, collapse = " "))
    
    if (refs[[1]][1] > 0) {
      match_length <- attr(refs[[1]], "match.length")
      start_pos <- refs[[1]]
      
      for (i in 1:length(start_pos)) {
        ref <- substr(paste(content, collapse = " "), 
                       start_pos[i], 
                       start_pos[i] + match_length[i] - 1)
        
        # Clean up the reference
        ref <- gsub("['\":]", "", ref)
        
        # Check if the referenced ID exists
        if (!(ref %in% ids)) {
          issues[[length(issues) + 1]] <- list(
            file = file,
            issue = paste("Reference to non-existent ID:", ref)
          )
        }
      }
    }
  }
  
  # Return issues or NULL if none
  if (length(issues) > 0) {
    return(issues)
  } else {
    return(NULL)
  }
}
```

## Batch Renaming

For larger renaming operations, use batch processing:

```r
# Function for batch renumbering
batch_renumber <- function(mapping) {
  # mapping should be a data frame with columns:
  # - old_id: The current ID
  # - new_id: The new ID
  # - name: The name part of the file
  
  # Verify all operations before executing
  for (i in 1:nrow(mapping)) {
    old_id <- mapping$old_id[i]
    new_id <- mapping$new_id[i]
    name <- mapping$name[i]
    
    old_filename <- paste0(old_id, "_", name, ".md")
    new_filename <- paste0(new_id, "_", name, ".md")
    
    if (!file.exists(old_filename)) {
      stop("Source file not found:", old_filename)
    }
    
    if (file.exists(new_filename)) {
      stop("Target file already exists:", new_filename)
    }
  }
  
  # Execute all operations
  results <- list()
  for (i in 1:nrow(mapping)) {
    old_id <- mapping$old_id[i]
    new_id <- mapping$new_id[i]
    name <- mapping$name[i]
    
    result <- tryCatch({
      renumber_resource(old_id, new_id, name)
      TRUE
    }, error = function(e) {
      return(e$message)
    })
    
    results[[i]] <- result
  }
  
  # Verify consistency after all operations
  consistency <- verify_consistency()
  
  # Return results
  return(list(
    operations = results,
    consistency = consistency
  ))
}
```

## Real-World Scenarios

### Example 1: Renumbering a Principle

When a principle needs to be renumbered (e.g., moving from P16 to P07):

```r
# Step 1: Verify the operation
old_id <- "P16"
new_id <- "P07"
name <- "app_bottom_up_construction"

# Step 2: Execute the renumbering
renumber_resource(old_id, new_id, name)

# Step 3: Verify consistency
verify_consistency()
```

### Example 2: Batch Renumbering

When renumbering multiple principles as part of a reorganization:

```r
# Create a mapping table
mapping <- data.frame(
  old_id = c("R16", "R17", "R18", "R19"),
  new_id = c("R07", "R08", "R09", "R10"),
  name = c("module_hierarchy", "ui_integration", "defaults_implementation", "yaml_config")
)

# Execute batch renumbering
batch_renumber(mapping)
```

## Best Practices

1. **Always Create Backups**: Always make backups before any renaming operation
2. **Verify Before and After**: Verify system consistency before and after renaming
3. **Update Documentation**: Update any documentation that references the renamed resources
4. **Small Batches**: Prefer smaller batches of renaming operations for easier verification
5. **Use Version Control**: Commit before and after renaming operations for additional safety
6. **Record Changes**: Document renaming operations in change logs or records

## Relationship to Other Principles

This rule implements:
- Naming Principles (P05)
- Modularity (MP16)
- Separation of Concerns (MP17)

It is related to:
- File Naming Convention (R01)
- Module Naming Convention (R07)

## Conclusion

Proper renaming methods ensure that the system remains coherent and well-organized when resources need to be renamed or renumbered. By following these standardized procedures, we maintain system integrity and avoid broken references or inconsistent naming.

When multiple renaming operations are needed, the batch processing approach enables systematic changes while maintaining system-wide consistency. The verification steps ensure that any issues are identified and addressed promptly.