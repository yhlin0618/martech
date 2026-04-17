# Shiny Test Applications

This directory contains Shiny applications specifically designed for testing components of the precision marketing system. These interactive applications provide visual interfaces for validating functionality and observing behavior.

## Available Test Apps

### Database Permission Testing

**File**: `test_db_permission_app.R`

This application tests the database connection permission system that enforces the Data Source Hierarchy Principle across different operation modes.

#### Purpose

- Verify that database connections respect the permission rules defined in the Data Source Hierarchy Principle
- Test behavior across different operation modes (APP_MODE, UPDATE_MODE, GLOBAL_MODE)
- Validate read/write permissions for different data layers (App, Processing, Global)

#### How to Use

1. **Launch the application**:
   ```r
   # IMPORTANT: Run from project root directory (following Authentic Context Testing Principle)
   # Navigate to project root first if necessary
   setwd("/path/to/precision_marketing_app")  # Adjust path as needed
   
   # Then launch the app using platform-neutral path handling (Platform-Neutral Code Principle)
   app_path <- file.path("update_scripts", "global_scripts", "98_test", 
                        "rshinyapp", "test_db_permission_app.R")
   shiny::runApp(app_path)
   ```

2. **Test different operation modes**:
   - Select an operation mode from the dropdown menu
   - The application will reinitialize with the selected mode
   - View the initialization messages in the results panel

3. **Test database connections**:
   - Click the "Test App Data Connection" button to test connections to app_data
   - Click the "Test Processing Data Connection" button to test connections to processed_data
   - Click the "Test Global Data Connection" button to test connections to global_scd_type1

4. **Interpret results**:
   - The results panel shows connection status, database tables, and read/write mode
   - It also indicates if write operations succeed or fail
   - The expected behavior panel shows the permission rules for each mode

#### Expected Results

- **APP_MODE**:
  - App Data: Connection succeeds, forced to read-only mode, write operations fail
  - Processing Data: Connection might be blocked entirely
  - Global Data: Connection succeeds, forced to read-only mode, write operations fail

- **UPDATE_MODE**:
  - App Data: Connection succeeds with write access, write operations succeed
  - Processing Data: Connection succeeds with write access, write operations succeed
  - Global Data: Connection succeeds, forced to read-only mode, write operations fail

- **GLOBAL_MODE**:
  - App Data: Connection succeeds with write access, write operations succeed
  - Processing Data: Connection succeeds with write access, write operations succeed
  - Global Data: Connection succeeds with write access, write operations succeed

#### Debugging Assistance

The app provides detailed output to help diagnose issues:
- Shows the current operation mode
- Indicates if permission checking functions are available
- Displays database connection status and permissions
- Reports success or failure of write operations

#### Implementation Notes

- The app automatically creates test databases if they don't exist
- It handles mode switching by resetting initialization flags
- It properly cleans up connections between tests
- It works even when permission checking utilities aren't fully loaded

## Usage Guidelines

1. **Development Only**: These apps are for testing during development, not for production
2. **Clean Up**: After running tests, ensure all connections are properly closed
3. **Documentation**: If you discover issues, document them in the appropriate records
4. **Enhancement**: If you enhance a test app, update its documentation