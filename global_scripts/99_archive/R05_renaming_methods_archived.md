---
id: "R05"
title: "Renaming Methods [ARCHIVED]"
type: "archived_rule"
date_created: "2025-04-02"
date_archived: "2025-04-04"
author: "Claude"
archived_reason: "Converted to M05 module for better implementation and separation of concerns"
implements:
  - "P05": "Naming Principles"
related_to:
  - "R01": "File Naming Convention"
  - "R02": "Principle Documentation"
  - "MP07": "Documentation Organization"
  - "M05": "Renumbering Principles Module"
---

# Renaming Methods Rule

This rule establishes specific methods and procedures for renaming files, principles, and other resources in the precision marketing system, ensuring consistency and preventing conflicts during renaming operations.

## Core Concept

Renaming operations must follow consistent, methodical procedures that maintain system integrity, prevent duplicate identifiers, and properly update all references to renamed resources throughout the system.

## Renaming Principles

### 1. Verification Before Renaming

Before renaming any resource:

- **Uniqueness Check**: Verify the new name does not conflict with any existing resource
- **Reference Scan**: Identify all references to the resource being renamed
- **Dependency Analysis**: Understand the impact of the rename on dependent components
- **Backup Creation**: Create a backup of affected files before proceeding

### 2. Atomic Renaming

Renaming operations should be atomic and complete:

- **All or Nothing**: Complete all aspects of a rename or none at all
- **Transactional Approach**: Treat renaming as a transaction that can be rolled back
- **Complete Implementation**: Rename the resource and all references in one operation
- **No Partial States**: Avoid leaving the system in a state with some references updated and others not

### 3. Reference Consistency

Ensure all references are updated consistently:

- **Explicit References**: Update all explicit references to the renamed resource
- **Implicit References**: Identify and update implicit references and dependencies
- **Documentation Updates**: Update all documentation that mentions the renamed resource
- **Configuration Updates**: Update all configuration files that reference the renamed resource

## Renaming Methods

### 1. Direct Renaming

For simple files with minimal external references:

```bash
# Step 1: Verify the new name is not in use
if [ -e "new_name.ext" ]; then
  echo "Error: Target name already exists"
  exit 1
fi

# Step 2: Create a backup
cp original_name.ext original_name.ext.bak

# Step 3: Perform the rename
mv original_name.ext new_name.ext

# Step 4: Update direct references in other files
grep -rl "original_name.ext" . | xargs sed -i 's/original_name.ext/new_name.ext/g'
```

### 2. Two-Phase Renaming

For complex resources with many dependencies:

**Phase 1: Preparation**
1. Identify all references to the resource
2. Create a backup of all affected files
3. Document the renaming plan, including affected files and references

**Phase 2: Execution**
1. Rename the primary resource
2. Update all references in affected files
3. Verify all references have been updated
4. Test the system to ensure functionality is preserved

### 3. Renumbering Method

For resources in a numbered sequence (like principles):

**Step 1: Duplicate Detection**
```bash
# Check for existing files with the target number
find . -name "P05_*.md" | grep -v "P05_to_rename.md"
```

**Step 2: Gap Analysis**
```bash
# List all files with the prefix to identify gaps
ls P*.md | sort -n
```

**Step 3: Principle Renumbering**
1. Create new file with correct number
2. Update YAML front matter with new id
3. Update all internal references to own id
4. Update all relationship references in YAML front matter

**Step 4: References Update**
1. Update references in related principles
2. Update references in README.md
3. Update any code that explicitly references the principle

**Step 5: Verification**
1. Check that no duplicate numbers exist
2. Verify all references are consistent
3. Ensure README.md lists all principles in correct order

## Conflict Resolution

When conflicts are detected during renaming:

### 1. Duplicate Identifier Resolution

If a duplicate identifier is found:

1. **Prioritize Based on Usage**: Determine which instance is more widely referenced
2. **Consider Recency**: More recent/updated files may take precedence
3. **Evaluate Completeness**: More complete/detailed implementations may take precedence
4. **Choose a New Identifier**: If neither has clear precedence, choose a new identifier for both

### 2. Handling Merged Content

When consolidating duplicates:

1. **Content Preservation**: Ensure valuable content from both sources is preserved
2. **Conflict Markers**: Use clear markers for conflicting sections during merging
3. **Documentation**: Document which parts came from which source
4. **Functionality Testing**: Test thoroughly after consolidation

### 3. Reference Repair

After resolving duplicates:

1. **Redirect References**: Update all references to point to the correct resource
2. **Deprecation Notices**: Add deprecation notices where appropriate
3. **Documentation Updates**: Update documentation to reflect the changes
4. **Transitional Support**: Consider temporary forwarding/aliasing during transition

## Renaming Implementation Example

### Example: Renumbering a Principle

Suppose we need to renumber P16 to P07:

```bash
# Step 1: Check for conflicts
ls -l P07_*.md
# If P07 already exists, resolve the conflict

# Step 2: Create the new file with updated content
cp P16_app_bottom_up_construction.md P07_app_bottom_up_construction.md

# Step 3: Update the id field in the new file
sed -i 's/id: "P16"/id: "P07"/' P07_app_bottom_up_construction.md

# Step 4: Update internal references
sed -i 's/P16 (App Bottom-Up Construction)/P07 (App Bottom-Up Construction)/' P07_app_bottom_up_construction.md

# Step 5: Update references in other files
grep -rl '"P16"' --include="*.md" . | xargs sed -i 's/"P16": "App Bottom-Up Construction"/"P07": "App Bottom-Up Construction"/g'

# Step 6: Update README.md
sed -i 's|P16_app_bottom_up_construction.md|P07_app_bottom_up_construction.md|' README.md
sed -i 's|- P16_app_bottom_up_construction.md|- P07_app_bottom_up_construction.md|' README.md

# Step 7: Verify no duplicates exist
find . -name "P07_*.md" | wc -l
# Should output 1

# Step 8: Remove the old file (only after verification)
rm P16_app_bottom_up_construction.md
```

## Recursive Verification

After completing renaming operations, perform recursive verification:

1. **Duplicate Check**: Search for any duplicate identifiers
   ```bash
   # Find duplicate P numbers (extract the Pxx part)
   ls P*.md | sed 's/\(P[0-9]*\).*/\1/' | sort | uniq -d
   ```

2. **Reference Consistency**: Verify all references match existing files
   ```bash
   # Extract all Pxx references from files
   grep -oh '"P[0-9]*"' --include="*.md" . | sort | uniq > all_references.txt
   # Extract all actual Pxx files
   ls P*.md | sed 's/\(P[0-9]*\).*/\1"/' | sort | uniq > all_files.txt
   # Compare to find references to non-existent files
   comm -23 all_references.txt all_files.txt
   ```

3. **README Verification**: Ensure README.md includes all principles
   ```bash
   # Get files in directory
   ls P*.md | sort > dir_files.txt
   # Get files mentioned in README
   grep -o 'P[0-9]*_[a-z_]*.md' README.md | sort > readme_files.txt
   # Compare to find files not in README
   comm -23 dir_files.txt readme_files.txt
   ```

4. **Cleanup Temporary Files**: Remove all temporary files created during verification
   ```bash
   # Remove all temporary files
   rm -f all_references.txt all_files.txt dir_files.txt readme_files.txt
   rm -f all_mp_references.txt all_mp_files.txt all_r_references.txt all_r_files.txt
   ```

## Best Practices

1. **Automated Tools**: Use automated tools to assist with renaming operations
2. **Transaction Logs**: Keep detailed logs of all renaming operations
3. **Versioned Changes**: Perform renaming in a version-controlled environment
4. **Incremental Verification**: Verify each step before proceeding to the next
5. **Documentation First**: Update documentation to match planned changes before executing them
6. **Test-Driven Renaming**: Create tests to verify system function before and after renaming
7. **Systematic Approach**: Follow a systematic, methodical approach rather than ad-hoc renaming

## Relationship to Other Rules and Principles

This rule implements P05 (Naming Principles) and is related to:
- R01 (File Naming Convention): Specifies conventions that renamed files must follow
- R02 (Principle Documentation): Defines how renaming should be reflected in documentation
- MP07 (Documentation Organization): Guides how renamed resources should be organized

## Conclusion

Following these renaming methods ensures that resources can be renamed safely and consistently throughout the system. By treating renaming as a methodical, verifiable process rather than a simple file operation, we maintain system integrity and prevent reference inconsistencies and duplicate identifiers.