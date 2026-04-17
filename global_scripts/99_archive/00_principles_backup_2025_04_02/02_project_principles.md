# Project Principles

> **Important Note**: These principles are the authoritative versions and should never be duplicated in other locations. Always reference these files directly.

This document outlines the core principles and best practices for the Precision Marketing project. These principles should guide all development and decision-making within the project.

## Code Organization

1. **Directory Structure**
   - Use numbered directories (01_db, 02_db_utils, etc.) to establish clear loading order
   - Place related functionality in the same directory
   - Use snake_case for all file and directory names
   - **Minimize nesting** - Keep directory structure flat with clear, purpose-named top-level directories rather than excessive subdirectories
   - Each directory should clearly indicate its purpose without requiring further subdivision
   - Specialized utility functions should be organized in dedicated directories (e.g., 14_sql_utils)

2. **File Naming**
   - Use numeric prefixes to indicate execution order (e.g., 101g_create_table.R)
   - Use 'g' suffix for global scripts
   - Use descriptive names that clearly indicate functionality
   - **ONE function per file** - Each R file should define only one function, with the file name matching the function name

3. **Code Style**
   - Follow consistent indentation (2 spaces)
   - Use descriptive variable names
   - Include comments for complex logic
   - Keep functions focused on a single responsibility

## Data Handling

1. **Raw Data Integrity**
   - **NEVER modify raw data files** - see [Data Integrity Principles](data_integrity_principles.md)
   - Process data through scripts that can be audited and reproduced
   - Document data processing steps clearly

2. **Data Processing**
   - Implement proper error handling
   - Validate inputs and outputs
   - Log processing steps and any issues encountered

3. **Data Storage**
   - Use appropriate data types for storage efficiency
   - Create proper database schemas before importing data
   - Document table relationships

## Cross-Computer Compatibility

1. **Path Management**
   - Use the root path configuration system for cross-machine compatibility
   - Avoid hardcoded absolute paths
   - Use file.path() for OS-independent path construction

2. **Environment Setup**
   - Document dependencies in a central location
   - Use initialization scripts to set up the environment consistently
   - Handle different operating systems gracefully

## Documentation

1. **Code Documentation**
   - Document functions with purpose and parameters
   - Explain complex algorithms
   - Keep documentation up to date with code changes

2. **Project Documentation**
   - Maintain README files in each directory
   - Document overall architecture in the root README
   - Include examples for complex functionality
   - Follow DRY principles - Never duplicate documentation across directories
   - Always reference the authoritative principles in 00_principles rather than copying them

## Version Control

1. **Git Workflow**
   - Use clear, descriptive commit messages
   - Prefix commit messages with the module name in brackets
   - Create focused branches for specific features or fixes
   - Review code before merging
   - Only revise code when there are sufficient reasons for the change
   - When uncertain about code changes, ask for guidance rather than immediately implementing

2. **Git-Dropbox Integration**
   - Use exclude_git_from_dropbox.sh to set up proper integration
   - Follow the guidelines in GIT_QUICKSTART.md
   - Be aware of Dropbox sync issues

## Testing

1. **Code Testing**
   - Test scripts with sample data before running on production data
   - Create automated tests where possible
   - Document test procedures and expected outcomes

## Security

1. **Data Security**
   - Never commit sensitive data to the repository
   - Use environment variables for credentials
   - Follow secure coding practices