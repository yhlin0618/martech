# Deployment Patterns Principle

This principle establishes guidelines for deploying the precision marketing application to production environments, ensuring consistency, reliability, and security across deployments.

## Core Concept

Application deployment should follow consistent patterns that preserve the integrity of the codebase, maintain security boundaries, and ensure that all required dependencies are included.

## Deployment Scope

### APP_MODE Complete Inclusion

The most important rule for deployment is that **ALL files sourced in APP_MODE must be included in the deployment package**. This ensures that the application has all necessary dependencies to function properly in production.

```r
# Rule: When deploying to rsconnect (Shiny Server, Posit Connect, etc.),
# include all files that would be sourced in APP_MODE initialization.
```

This includes:
- All files in directories loaded by sc_initialization_app_mode.R
- All utility functions used by the application
- All global data files needed for app functionality
- Configuration files with the appropriate environment settings

### Directories to Include

Based on the APP_MODE initialization script, these directories must be included:
1. `update_scripts/global_scripts/02_db_utils`
2. `update_scripts/global_scripts/04_utils`
3. `update_scripts/global_scripts/03_config`
4. `update_scripts/global_scripts/10_rshinyapp_components`
5. `update_scripts/global_scripts/11_rshinyapp_utils`
6. `local_scripts` (renamed to `app_configs` in newer versions)

### Dependencies Between Utilities

When deploying, be mindful of dependencies between utility files:
- Database utilities in `02_db_utils` may depend on functions from `11_rshinyapp_utils`
- UI components may depend on utility functions
- All dependencies must be properly resolved in the deployment package

## Deployment Process

### 1. Pre-Deployment Verification

Before deploying, verify that the application can run successfully in APP_MODE with only the files that will be included in the deployment:

```r
# Test APP_MODE initialization with only deployment files
OPERATION_MODE <- "APP_MODE"
source("update_scripts/global_scripts/00_principles/sc_initialization_app_mode.R")
# Verify no errors occur during initialization
```

### 2. Deployment Manifest

Create a deployment manifest that explicitly lists all files to be included:

```r
# Example rsconnect deployment with explicit file list
rsconnect::deployApp(
  appDir = ".",
  appFiles = c(
    # Core app files
    "app.R", "global.R", "ui.R", "server.R",
    
    # Directories from APP_MODE initialization
    list.files("update_scripts/global_scripts/02_db_utils", full.names = TRUE, recursive = TRUE),
    list.files("update_scripts/global_scripts/04_utils", full.names = TRUE, recursive = TRUE),
    list.files("update_scripts/global_scripts/03_config", full.names = TRUE, recursive = TRUE),
    list.files("update_scripts/global_scripts/10_rshinyapp_components", full.names = TRUE, recursive = TRUE),
    list.files("update_scripts/global_scripts/11_rshinyapp_utils", full.names = TRUE, recursive = TRUE),
    list.files("app_configs", full.names = TRUE, recursive = TRUE)
  )
)
```

### 3. Environment-Specific Configuration

Deployment should include mechanisms for environment-specific configuration:

```r
# In app initialization
if (file.exists(".env")) {
  dotenv::load_dot_env()
} else if (file.exists("app_configs/production.env")) {
  dotenv::load_dot_env("app_configs/production.env")
}
```

## Security Considerations

### 1. Secrets Management

Never include plain-text secrets in deployment files:
- Use environment variables for sensitive information
- Configure secrets in the deployment platform (rsconnect, server environment)
- For local development, use `.env` files (excluded from version control)

### 2. Limited Scope

The deployment should only include what's needed for APP_MODE:
- Exclude update scripts that are not needed in production
- Exclude development and testing utilities
- Exclude documentation that isn't relevant to production

### 3. Read-Only Enforcement

Enforce read-only access to data in production:
- Ensure database connections use read-only mode
- Prevent file system writes where possible
- Log access attempts for security auditing

## Version Control and Deployment

### 1. Deployment from Tagged Releases

Deploy from tagged releases rather than development branches:

```bash
# Tag a release before deployment
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Deploy the tagged version
git checkout v1.0.0
# Deploy to rsconnect
```

### 2. Deployment Documentation

Document each deployment with:
- Version deployed
- Date and time of deployment
- Configuration changes
- Environment settings

## Best Practices

### 1. Deployment Testing

Before deploying to production:
- Test in a staging environment
- Verify all dependencies are included
- Check for proper initialization in APP_MODE
- Test with production-like data volumes

### 2. Rollback Plan

Always have a rollback plan:
- Keep previous version available
- Document rollback procedures
- Test rollback process periodically

### 3. Deployment Automation

Use automation to ensure consistent deployments:
- Script the deployment process
- Use continuous deployment where appropriate
- Automate verification steps

## Conclusion

By following these deployment patterns, we ensure that the precision marketing application is consistently and reliably deployed to production environments with all necessary dependencies and proper security controls.

This principle works in conjunction with the Operating Modes Principle and the Data Source Hierarchy Principle to maintain the integrity and security of the application across different environments.