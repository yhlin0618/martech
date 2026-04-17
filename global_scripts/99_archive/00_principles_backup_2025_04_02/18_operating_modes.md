# Operating Modes Principle

This document defines the three distinct operating modes for the precision marketing system. Each mode serves a specific purpose and has different access levels, functionality, and security considerations.

## Core Operating Modes

The system is designed to function in three primary modes, each tailored for specific use cases and environments:

### 1. App Mode

**Purpose**: Production environment where the final application runs.

**Key Characteristics**:
- Only includes thoroughly reviewed and tested components
- Contains exclusively stable global_scripts and 30_global_data
- Includes local_scripts for initialization
- Does NOT include project_update_logic (update scripts are not deployed)

**Access and Security**:
- Exposes only necessary, abstracted functionality to end users
- Higher security through limited access patterns
- Stable public interfaces only
- Data access restricted to production-approved datasets

**Typical Usage**:
- End-user interaction with the system
- Production dashboards and analytics
- Client-facing applications
- Regular business operations

### 2. Update Mode

**Purpose**: Development and testing environment.

**Key Characteristics**:
- Full access to all update_scripts (both global_scripts and project_update_logic)
- Complete access to app_data and test data
- Used for debugging and updating processes
- Allows modifications to the codebase

**Access and Security**:
- Available only to developers and testers
- Less restrictive than App Mode for development purposes
- May include test data not suitable for production
- Supports experimental features

**Typical Usage**:
- Feature development and testing
- Debugging and error correction
- Integration testing between components
- Performance optimization
- Pre-deployment validation

### 3. Global Mode

**Purpose**: Specifically for maintaining shared resources across projects.

**Key Characteristics**:
- Focused on centralized management of global_scripts and 30_global_data
- Emphasizes unit testing and interface stability
- Uses version control and documentation signatures
- Ensures cross-project compatibility

**Access and Security**:
- Limited to system architects and core developers
- Strict version control and change documentation
- Changes require thorough review process
- Modifications impact all projects that use the resources

**Typical Usage**:
- Updates to shared utilities and functions
- Maintenance of common datasets
- API and interface evolution
- Cross-project standardization
- Performance improvements to core systems

## Implementation Details

### Mode Detection and Switching

The system should detect or set its operating mode using:

```r
# Setting the mode explicitly
OPERATION_MODE <- "APP_MODE"  # or "UPDATE_MODE" or "GLOBAL_MODE"

# Alternative environment-based detection
if (file.exists("/.app_mode")) {
  OPERATION_MODE <- "APP_MODE"
} else if (file.exists("/.global_mode")) {
  OPERATION_MODE <- "GLOBAL_MODE"
} else {
  OPERATION_MODE <- "UPDATE_MODE"  # Default for development
}
```

### Mode-Specific Behavior

Scripts should adjust their behavior based on the active mode:

```r
if (OPERATION_MODE == "APP_MODE") {
  # Production-safe operations only
  message("Running in App Mode - production environment")
  source("local_scripts/production_init.R")
} else if (OPERATION_MODE == "UPDATE_MODE") {
  # Development operations
  message("Running in Update Mode - development environment")
  source("update_scripts/dev_init.R")
} else if (OPERATION_MODE == "GLOBAL_MODE") {
  # Global resource maintenance
  message("Running in Global Mode - maintaining shared resources")
  source("update_scripts/global_scripts/maintenance_init.R")
}
```

### Directory Access Restrictions

Certain directories should only be accessible in specific modes:

| Directory | App Mode | Update Mode | Global Mode |
|-----------|----------|-------------|-------------|
| global_scripts | ✓ | ✓ | ✓ |
| 30_global_data | ✓ | ✓ | ✓ |
| project_update_logic | ✗ | ✓ | ✗ |
| app_data | ✓ | ✓ | ✓ |
| local_scripts | ✓ | ✓ | ✓ |
| test_data | ✗ | ✓ | ✓ |

## Best Practices

### 1. Clear Mode Indicators

- Always display the current operating mode in logs and user interfaces
- Use visual indicators (colors, badges) to clearly distinguish between modes
- Include mode information in error reports and log files

### 2. Mode-Specific Initialization

- Create mode-specific initialization scripts
- Load only necessary resources for each mode
- Configure logging verbosity appropriate to the mode

### 3. Security Considerations

- Implement stricter validation in App Mode
- Never expose sensitive data in Update Mode logs
- Use separate credentials for different modes
- Consider mode-specific encryption levels

### 4. Testing Across Modes

- Test functionality in all applicable modes before deployment
- Create automated tests that run in the appropriate mode
- Verify that mode restrictions prevent unauthorized access

### 5. Documentation

- Clearly document which functions and features are available in each mode
- Note any behavioral differences between modes
- Document the process for switching between modes

## Implementation Example

Here's an example of how to structure code to respect operating modes:

```r
# In initialization script
detect_operating_mode <- function() {
  if (file.exists("/.app_mode")) {
    return("APP_MODE")
  } else if (file.exists("/.global_mode")) {
    return("GLOBAL_MODE")
  } else {
    return("UPDATE_MODE")
  }
}

OPERATION_MODE <- detect_operating_mode()
message("Running in ", OPERATION_MODE)

# Function with mode-specific behavior
process_data <- function(data, options = list()) {
  # Base functionality available in all modes
  result <- perform_basic_processing(data)
  
  if (OPERATION_MODE %in% c("UPDATE_MODE", "GLOBAL_MODE")) {
    # Additional development/testing functionality
    result <- perform_advanced_processing(result, options)
    
    if (OPERATION_MODE == "GLOBAL_MODE") {
      # Global-mode specific actions
      log_processing_metrics(result)
      verify_cross_project_compatibility(result)
    }
  }
  
  # Final validation happens regardless of mode
  validate_results(result)
  
  return(result)
}
```

## Conclusion

The operating modes principle provides a structured approach to managing different environments and access levels in the precision marketing system. By clearly defining App Mode, Update Mode, and Global Mode, we establish boundaries that enhance security, maintainability, and appropriate access control throughout the development lifecycle.

This principle should be consistently applied across all aspects of the system to ensure reliable operation in all environments.