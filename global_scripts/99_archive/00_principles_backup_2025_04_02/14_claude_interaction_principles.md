# Claude Interaction Principles

This document outlines principles for interacting with Claude AI in the context of our precision marketing projects, ensuring consistent and efficient workflows across all company repositories.

## Core Principles

### 1. Project Context Awareness

- Claude should detect and respect which project context is active in the current session
- When working with WISER files, Claude should make changes in the WISER directory structure
- When working with KitchenMAMA files, Claude should make changes in the KitchenMAMA directory structure
- Initial repository location should be determined by the files being discussed or modified

### 2. Cross-Project Synchronization

- After completing changes in one project, use the sync_global_scripts.sh tool to propagate changes
- All edits to files in global_scripts should be synchronized across projects
- Project-specific files (outside global_scripts) should remain isolated to their respective projects
- Always commit changes before synchronizing between projects

### 3. Code Modification Restraint

- Only revise code when there are sufficient reasons to make such changes
- When the need for code changes is unclear or could have multiple approaches, ASK first
- Provide explanations and alternatives rather than making immediate changes
- Respect the existing architecture and coding patterns
- Prioritize stability and maintainability over stylistic improvements

### 4. Documentation Non-Duplication

- NEVER create duplicate copies of principles, guidelines, or architectural documentation
- Always reference the authoritative versions in 00_principles rather than copying them
- When asked to explain principles, link to the relevant file in 00_principles
- When working in claude_prompts, refer to 00_principles rather than duplicating information
- If the same information needs to appear in multiple places, maintain it in 00_principles and link to it

### 5. Directory Navigation

- Avoid hardcoding default paths to KitchenMAMA or any specific project
- Derive the working path based on the current context of the conversation
- When the context is ambiguous, ask which project is currently being worked on
- Use the correct path structure based on the active project

## Implementation Guidelines

### For Project Detection

Claude should:

1. Pay attention to the directory paths mentioned in the conversation
2. Look for project identifiers in file paths (e.g., "precision_marketing_WISER" vs "precision_marketing_KitchenMAMA")
3. Maintain awareness of which project directory was last used in the session
4. Default to the most recently used project context unless specified otherwise

### For File Operations

When operating on files:

1. Use the absolute path with the correct project name in the path
2. Ensure consistency within a session by staying in the same project context unless directed otherwise
3. When switching projects, clearly indicate the context change
4. Verify paths are correct before executing file operations

### For Global Scripts Changes

When modifying global_scripts files:

1. Make changes in the context of the active project
2. Commit changes to that project's global_scripts repository
3. Run the sync script to propagate changes to other projects
4. Verify synchronization was successful

### For Documentation and Principles

When creating or updating documentation:

1. Check if the topic is already covered in 00_principles before creating new content
2. If similar content exists, update the existing principles instead of creating duplicates
3. When documenting project-specific implementations, reference the global principles with relative links
4. For company-specific guidance, explain how the global principles apply, don't restate them
5. Use the pattern "For more information on X, see [Link to Principle]" rather than duplicating content

### For Code Modification

When asked to modify or improve code:

1. Assess whether the change is necessary and has sufficient justification
2. If multiple approaches are possible or the best approach is unclear, ask for guidance
3. Present alternatives with pros and cons rather than making immediate changes
4. When improvements are minor or purely stylistic, ask before implementing
5. Explain why a change is needed before making it, especially for structural changes

## Examples

### Example 1: Context-Aware Path Handling

**Good Example**:
```
# When working with WISER files
file_path = "/Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_WISER/precision_marketing_app/update_scripts/global_scripts/00_principles/data_integrity_principles.md"

# When working with KitchenMAMA files
file_path = "/Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_KitchenMAMA/precision_marketing_app/update_scripts/global_scripts/00_principles/data_integrity_principles.md"
```

**Bad Example**:
```
# Always defaulting to one project regardless of context
file_path = "/Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_KitchenMAMA/precision_marketing_app/update_scripts/global_scripts/00_principles/data_integrity_principles.md"
```

### Example 2: Workflow For Global Scripts Changes

```
# 1. Detect we're working with WISER
cd /Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_WISER/precision_marketing_app/update_scripts/global_scripts

# 2. Make changes to files in this directory
Edit file_path="/Users/che/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_WISER/precision_marketing_app/update_scripts/global_scripts/00_principles/script_separation_principles.md"

# 3. Commit changes in this project
git add 00_principles/script_separation_principles.md
git commit -m "Update script separation principles"

# 4. Sync changes to other projects
bash 12_bash/sync_global_scripts.sh
```

### Example 3: Handling Principle References Without Duplication

**Good Example**:
```
# In a company-specific README or implementation guide
# Reference the principle without duplicating it

## Data Management
For our customer DNA processing, we follow the global data integrity principles,
particularly regarding raw data sanctity. See the [Data Integrity Principles](../00_principles/04_data_integrity_principles.md)
for detailed guidelines on data transformation workflows.
```

**Bad Example**:
```
# Copying content from data integrity principles to a local document

## Data Integrity
Raw data must never be modified. Instead, follow these steps for transformation:
1. Import raw data...
2. Transform in memory...
3. Store in cleansed database...
# ... continues to duplicate content from data_integrity_principles.md
```

### Example 4: Code Modification Restraint

**Good Example**:
```
User: The performance of the customer DNA calculation seems slow.

Claude: I've looked at the DNA calculation code and see a few potential approaches to improve performance:

1. We could vectorize the operations using data.table instead of the current dplyr implementation
2. We could add caching for intermediate results
3. We could parallelize certain operations

Which approach would you prefer I explore first, or do you have other ideas?
```

**Bad Example**:
```
User: The performance of the customer DNA calculation seems slow.

Claude: I've rewritten the DNA calculation function to use data.table instead of dplyr and made several other optimizations. Here's the new implementation:

[proceeds to make significant changes without discussing approaches first]
```

## Conclusion

By following these principles, Claude will maintain awareness of which project context is active, make changes in the appropriate directories, and ensure synchronization of global_scripts across all projects. The code modification restraint prevents unnecessary or inappropriate changes, while the strict non-duplication approach maintains a single source of truth for all principles and documentation. Together, these principles ensure that Claude's contributions align with the project's needs and user expectations.

Last Updated: April 1, 2025 (Updated to include code modification restraint and non-duplication principles)