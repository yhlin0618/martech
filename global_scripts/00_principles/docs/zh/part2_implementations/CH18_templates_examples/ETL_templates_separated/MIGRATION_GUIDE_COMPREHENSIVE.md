# Comprehensive ETL Migration Guide
## From Mixed-Type to Data Flow Separation Architecture

**Document Version**: 1.0  
**Date**: 2025-08-28  
**Implements**: MP104 (ETL Data Flow Separation), DM_R028 (ETL Data Type Separation Rule)  
**Migration Status**: Implementation Phase  

---

## Executive Summary

This guide provides comprehensive instructions for migrating from the current mixed-type ETL architecture (where single scripts handle multiple data types) to the new **Data Flow Separation Architecture** mandated by MP104 and DM_R028. The migration ensures proper separation of concerns, enables parallel processing, and eliminates data orphaning issues.

### Key Changes

| **Current (Non-Compliant)** | **New (Compliant)** |
|------------------------------|---------------------|
| `cbz_ETL01_0IM.R` (mixed types) | `cbz_ETL_sales_0IM.R`, `cbz_ETL_customers_0IM.R`, `cbz_ETL_orders_0IM.R`, `cbz_ETL_products_0IM.R` |
| `eby_ETL01_0IM.R` (mixed types) | `eby_ETL_sales_0IM.R`, `eby_ETL_customers_0IM.R`, `eby_ETL_orders_0IM.R`, `eby_ETL_products_0IM.R` |
| Single pipeline per platform | Separate pipelines per data type per platform |
| Inconsistent table naming | Standardized `df_{platform}_{datatype}___phase` naming |

---

## Migration Overview

### Phase 1: Assessment and Planning
- **Duration**: 1-2 days
- **Activities**: Audit existing ETL scripts, identify data types, plan separation strategy

### Phase 2: Core Infrastructure Setup
- **Duration**: 2-3 days
- **Activities**: Update principles, create templates, set up schema registry

### Phase 3: Platform Migration - Cyberbiz
- **Duration**: 3-4 days
- **Activities**: Implement separated ETL pipelines for Cyberbiz platform

### Phase 4: Platform Migration - eBay
- **Duration**: 2-3 days
- **Activities**: Implement separated ETL pipelines for eBay platform

### Phase 5: Platform Migration - Amazon
- **Duration**: 2-3 days
- **Activities**: Implement separated ETL pipelines for Amazon platform

### Phase 6: Testing and Validation
- **Duration**: 2-3 days
- **Activities**: End-to-end testing, performance validation, rollback preparation

### Phase 7: Production Deployment
- **Duration**: 1-2 days
- **Activities**: Phased rollout, monitoring, legacy cleanup

**Total Estimated Duration**: 15-21 days

---

## Pre-Migration Assessment

### Current ETL Inventory

#### Cyberbiz Platform
```yaml
current_scripts:
  - cbz_ETL01_0IM.R: "Mixed import - sales, customers, orders"
  - cbz_ETL01_1ST.R: "Sales staging only (customers/orders orphaned)"
  - cbz_ETL01_2TR.R: "Sales transform only (customers/orders orphaned)"

issues_identified:
  - data_orphaning: "Customers and orders imported but never processed"
  - mixed_concerns: "Single script handles multiple business entities"
  - maintenance_complexity: "Changes affect unrelated data types"
```

#### eBay Platform
```yaml
current_scripts:
  - eby_ETL01_0IM.R: "Mixed CSV import - sales, basic customer data"
  
issues_identified:
  - incomplete_pipeline: "No staging or transform phases"
  - manual_processing: "Heavy reliance on manual data cleanup"
  - inconsistent_schema: "Output format varies by file source"
```

#### Amazon Platform
```yaml
current_scripts:
  - amz_ETL01_0IM.R: "Sales import from CSV (archived)"
  - amz_ETL03_0IM.R: "Product profiles import"
  - amz_ETL06_0IM.R: "Reviews import"
  
issues_identified:
  - archived_scripts: "Core sales ETL is archived/inactive"
  - incomplete_separation: "Partial separation attempted but inconsistent"
  - naming_inconsistency: "Does not follow standard naming conventions"
```

### Data Type Analysis

#### Identified Data Types Per Platform

| **Platform** | **Sales** | **Customers** | **Orders** | **Products** | **Reviews** |
|--------------|-----------|---------------|------------|--------------|-------------|
| **Cyberbiz** | ✅ Active | 🟡 Imported, not processed | 🟡 Imported, not processed | 🟡 Imported, not processed | ❌ Not available |
| **eBay** | ✅ Active | 🟡 Basic data only | ❌ Not separated | ❌ Not available | ❌ Not available |
| **Amazon** | 🔴 Archived | ❌ Not available | ❌ Not available | ✅ Active | ✅ Active |

### Migration Complexity Assessment

#### High Priority (Critical)
- **Cyberbiz Sales**: Active production pipeline - requires careful migration
- **eBay Sales**: Primary data source for marketplace analysis

#### Medium Priority (Important)
- **Amazon Products**: Important for competitive analysis
- **Amazon Reviews**: Key for sentiment analysis
- **Cyberbiz Customers/Orders**: Currently orphaned data

#### Lower Priority (Can be staged)
- **eBay Customers/Orders/Products**: Basic functionality needed
- **Amazon Sales**: Historical data only
- **Amazon Customers/Orders**: Nice to have

---

## Migration Implementation Plan

### Phase 1: Assessment and Planning (Days 1-2)

#### Day 1: ETL Audit
```bash
# Step 1: Create assessment workspace
mkdir -p migration_workspace/assessment
cd migration_workspace/assessment

# Step 2: Audit existing ETL scripts
find scripts/update_scripts -name "*ETL*" -type f | tee etl_inventory.txt

# Step 3: Analyze current table outputs
# For each active ETL script, document:
# - Data types handled
# - Table names created
# - Dependencies
# - Business criticality

# Step 4: Create migration plan spreadsheet
# Platform | Current Script | Data Types | Target Scripts | Priority | Effort
```

#### Day 2: Architecture Planning
```bash
# Step 1: Update principles documentation (already completed in this implementation)
# - MP104: ETL Data Flow Separation Principle
# - DM_R028: ETL Data Type Separation Rule
# - MP102: ETL Output Standardization Principle

# Step 2: Create schema registry entries
# - Define core schemas for all data types
# - Document platform-specific extensions
# - Set up validation rules

# Step 3: Plan API efficiency strategy
# - Identify platforms with single API calls returning multiple data types
# - Design shared import pattern vs. independent import pattern
# - Estimate API rate limiting impact
```

### Phase 2: Core Infrastructure Setup (Days 3-5)

#### Day 3: Template Creation
```bash
# Step 1: Create separated ETL templates (completed in this implementation)
# Templates created:
# - template_ETL_sales_0IM.R (generic template)
# - cbz_ETL_sales_0IM.R (Cyberbiz sales import)
# - cbz_ETL_sales_1ST.R (Cyberbiz sales staging)
# - cbz_ETL_sales_2TR.R (Cyberbiz sales transform)

# Step 2: Create platform-specific templates for all data types
# Required templates per platform:
# - {platform}_ETL_sales_{0IM|1ST|2TR}.R
# - {platform}_ETL_customers_{0IM|1ST|2TR}.R
# - {platform}_ETL_orders_{0IM|1ST|2TR}.R
# - {platform}_ETL_products_{0IM|1ST|2TR}.R
```

#### Day 4: Utility Functions Development
```bash
# Step 1: Create data type-specific utility functions
mkdir -p scripts/global_scripts/05_etl_utils/cbz/import
mkdir -p scripts/global_scripts/05_etl_utils/cbz/staging
mkdir -p scripts/global_scripts/05_etl_utils/cbz/transform

# Key functions to implement:
# - fn_fetch_{platform}_sales_data.R
# - fn_process_sales_import.R
# - fn_stage_sales_data.R
# - fn_transform_sales_data.R
# - fn_validate_sales_import.R

# Step 2: Create common validation functions
mkdir -p scripts/global_scripts/05_etl_utils/common/validation
# - fn_validate_etl_output.R
# - fn_validate_schema_compliance.R
# - fn_validate_platform_consistency.R
```

#### Day 5: Testing Infrastructure
```bash
# Step 1: Create ETL testing framework
mkdir -p scripts/global_scripts/98_test/etl_separation
# - test_etl_naming_convention.R
# - test_pipeline_completeness.R
# - test_single_responsibility.R
# - test_schema_compliance.R

# Step 2: Create migration validation tools
# - compare_old_vs_new_outputs.R
# - validate_data_integrity.R
# - performance_comparison.R
```

### Phase 3: Cyberbiz Platform Migration (Days 6-9)

#### Day 6: Cyberbiz Sales Pipeline
```bash
# Step 1: Analyze current cbz_ETL01_0IM.R
# Extract sales-specific logic
# Identify API calls and data transformations
# Document field mappings

# Step 2: Implement separated sales pipeline
# - cbz_ETL_sales_0IM.R (completed)
# - cbz_ETL_sales_1ST.R (completed)
# - cbz_ETL_sales_2TR.R (completed)

# Step 3: Test sales pipeline end-to-end
# - Run import phase with validation
# - Verify staging transformations
# - Validate final transform output
```

#### Day 7: Cyberbiz Customers Pipeline
```bash
# Step 1: Extract customer logic from cbz_ETL01_0IM.R
# Customer-specific API endpoints or data extraction
# Customer field mappings and transformations

# Step 2: Implement customer pipeline
# - cbz_ETL_customers_0IM.R
# - cbz_ETL_customers_1ST.R
# - cbz_ETL_customers_2TR.R

# Step 3: Test and validate customer pipeline
```

#### Day 8: Cyberbiz Orders and Products Pipelines
```bash
# Step 1: Implement orders pipeline
# - cbz_ETL_orders_0IM.R
# - cbz_ETL_orders_1ST.R
# - cbz_ETL_orders_2TR.R

# Step 2: Implement products pipeline
# - cbz_ETL_products_0IM.R
# - cbz_ETL_products_1ST.R
# - cbz_ETL_products_2TR.R

# Step 3: Test individual pipelines
```

#### Day 9: Cyberbiz Integration and Optimization
```bash
# Step 1: Implement shared API import pattern
# Create cbz_ETL_shared_0IM.R for efficient API usage
# Modify individual 0IM scripts to read from shared import

# Step 2: Create orchestration script
# cbz_ETL_execute_all.R for coordinated pipeline execution

# Step 3: Performance testing and optimization
# Compare execution times
# Monitor API rate limiting
# Optimize database write operations
```

### Phase 4: eBay Platform Migration (Days 10-12)

#### Day 10: eBay Assessment and Planning
```bash
# Step 1: Analyze current eby_ETL01_0IM.R
# File-based import patterns
# Data quality issues
# Manual processing requirements

# Step 2: Design eBay-specific architecture
# CSV/Excel file handling
# Data validation and cleanup requirements
# Error handling for inconsistent file formats
```

#### Day 11: eBay Pipeline Implementation
```bash
# Step 1: Implement core eBay pipelines
# - eby_ETL_sales_{0IM|1ST|2TR}.R
# - eby_ETL_customers_{0IM|1ST|2TR}.R

# Step 2: Handle file-based import challenges
# Multiple file format support
# Data validation and error reporting
# Manual intervention workflows
```

#### Day 12: eBay Testing and Validation
```bash
# Step 1: Test with historical eBay files
# Various file formats and structures
# Error conditions and recovery
# Data quality validation

# Step 2: Document eBay-specific procedures
# File preparation requirements
# Common issues and solutions
# Manual quality control checkpoints
```

### Phase 5: Amazon Platform Migration (Days 13-15)

#### Day 13: Amazon Architecture Assessment
```bash
# Step 1: Review archived Amazon ETL scripts
# Extract reusable logic from archived scripts
# Assess current amz_ETL03 and amz_ETL06 scripts
# Plan integration strategy

# Step 2: Design Amazon-specific patterns
# API integration for product data
# Review data processing requirements
# Historical sales data handling
```

#### Day 14: Amazon Pipeline Implementation
```bash
# Step 1: Implement Amazon sales pipeline
# - amz_ETL_sales_{0IM|1ST|2TR}.R
# Revive and modernize archived sales import

# Step 2: Migrate existing Amazon scripts
# - Convert amz_ETL03_0IM.R to amz_ETL_products_0IM.R
# - Convert amz_ETL06_0IM.R to amz_ETL_reviews_0IM.R
# - Add missing 1ST and 2TR phases
```

#### Day 15: Amazon Integration and Testing
```bash
# Step 1: Complete Amazon pipeline suite
# - amz_ETL_customers_{0IM|1ST|2TR}.R
# - amz_ETL_orders_{0IM|1ST|2TR}.R

# Step 2: End-to-end Amazon testing
# Test all data types
# Validate schema compliance
# Performance testing
```

### Phase 6: Testing and Validation (Days 16-18)

#### Day 16: Integration Testing
```bash
# Step 1: Cross-platform consistency testing
# Verify all platforms produce compatible schemas
# Test derivation functions with new ETL outputs
# Validate MP102 compliance across all platforms

# Step 2: Performance benchmarking
# Compare old vs new execution times
# Monitor resource usage
# Test parallel execution capabilities
```

#### Day 17: Data Quality Validation
```bash
# Step 1: Data integrity checks
# Compare record counts before/after migration
# Validate business metrics consistency
# Check for data loss or corruption

# Step 2: Schema validation
# Verify all required fields present
# Check data type consistency
# Validate platform-specific extensions
```

#### Day 18: Rollback Preparation
```bash
# Step 1: Create rollback procedures
# Document steps to revert to old system
# Create data backup and recovery procedures
# Test rollback scenarios

# Step 2: Create monitoring and alerting
# ETL pipeline health checks
# Data quality monitoring
# Performance degradation alerts
```

### Phase 7: Production Deployment (Days 19-21)

#### Day 19: Staging Deployment
```bash
# Step 1: Deploy to staging environment
# Deploy all new ETL scripts
# Update orchestration and scheduling
# Run full end-to-end tests

# Step 2: Stakeholder validation
# Business user acceptance testing
# Data analyst validation
# Dashboard and reporting verification
```

#### Day 20: Production Rollout
```bash
# Step 1: Phased production deployment
# Start with lowest-risk platform (Amazon)
# Monitor for issues before proceeding
# Deploy remaining platforms gradually

# Step 2: Monitoring and support
# Monitor ETL execution
# Respond to any issues immediately
# Document lessons learned
```

#### Day 21: Cleanup and Documentation
```bash
# Step 1: Legacy cleanup
# Archive old ETL scripts
# Update documentation and runbooks
# Clean up obsolete database tables

# Step 2: Post-migration optimization
# Fine-tune performance
# Optimize resource usage
# Plan future enhancements
```

---

## Technical Implementation Details

### API Efficiency Patterns

#### Pattern 1: Shared Import Distribution (Recommended for Cyberbiz)

```r
# cbz_ETL_shared_0IM.R - Single API call, distribute to data types
cbz_shared_api_import <- function() {
  # Single API call to minimize rate limiting
  complete_data <- fetch_cyberbiz_complete_api()
  
  # Distribute data to type-specific raw tables
  sales_data <- extract_sales_from_complete(complete_data)
  customers_data <- extract_customers_from_complete(complete_data)
  orders_data <- extract_orders_from_complete(complete_data)
  products_data <- extract_products_from_complete(complete_data)
  
  # Write to separate raw tables
  write_raw_data("df_cbz_sales___raw", sales_data)
  write_raw_data("df_cbz_customers___raw", customers_data)
  write_raw_data("df_cbz_orders___raw", orders_data)
  write_raw_data("df_cbz_products___raw", products_data)
}

# Individual ETL pipelines read from shared import
# cbz_ETL_sales_0IM.R
cbz_sales_import <- function() {
  # Read from shared import output
  sales_raw <- read_raw_data("df_cbz_sales___raw")
  
  # Apply sales-specific processing
  sales_processed <- process_sales_specific_logic(sales_raw)
  
  # Update raw table with processed data
  write_raw_data("df_cbz_sales___raw", sales_processed, overwrite = TRUE)
}
```

#### Pattern 2: Independent API Calls (Recommended for Amazon)

```r
# amz_ETL_sales_0IM.R - Independent sales import
amz_sales_import <- function() {
  # API call optimized for sales data only
  sales_data <- fetch_amazon_sales_api()
  
  # Process and store
  processed_sales <- process_sales_import(sales_data)
  write_raw_data("df_amz_sales___raw", processed_sales)
}

# amz_ETL_products_0IM.R - Independent product import  
amz_products_import <- function() {
  # API call optimized for product data only
  products_data <- fetch_amazon_products_api()
  
  # Process and store
  processed_products <- process_products_import(products_data)
  write_raw_data("df_amz_products___raw", processed_products)
}
```

### Database Schema Migration

#### Table Renaming Strategy

```sql
-- Phase 1: Create new tables with correct naming
CREATE TABLE df_cbz_sales___raw AS SELECT * FROM current_cbz_sales_raw;
CREATE TABLE df_cbz_customers___raw AS SELECT * FROM current_cbz_customers_raw;

-- Phase 2: Validate data integrity
SELECT COUNT(*) FROM df_cbz_sales___raw;
SELECT COUNT(*) FROM current_cbz_sales_raw;
-- Counts should match

-- Phase 3: Update dependent derivations to use new table names
-- Update D01, D02, D03, etc. to reference new tables

-- Phase 4: Drop old tables after validation
-- DROP TABLE current_cbz_sales_raw; (after full validation)
```

### Orchestration and Scheduling

#### New Execution Pattern

```r
# execute_complete_etl.R - Master orchestration
execute_complete_etl <- function(platforms = c("cbz", "eby", "amz")) {
  
  for (platform in platforms) {
    message(sprintf("Starting %s ETL pipeline...", toupper(platform)))
    
    # Phase 1: Import (can be parallel)
    execute_parallel(
      sprintf("%s_ETL_sales_0IM", platform),
      sprintf("%s_ETL_customers_0IM", platform),
      sprintf("%s_ETL_orders_0IM", platform),
      sprintf("%s_ETL_products_0IM", platform)
    )
    
    # Phase 2: Staging (can be parallel)
    execute_parallel(
      sprintf("%s_ETL_sales_1ST", platform),
      sprintf("%s_ETL_customers_1ST", platform),
      sprintf("%s_ETL_orders_1ST", platform),
      sprintf("%s_ETL_products_1ST", platform)
    )
    
    # Phase 3: Transform (can be parallel)
    execute_parallel(
      sprintf("%s_ETL_sales_2TR", platform),
      sprintf("%s_ETL_customers_2TR", platform),
      sprintf("%s_ETL_orders_2TR", platform),
      sprintf("%s_ETL_products_2TR", platform)
    )
    
    message(sprintf("✅ %s ETL pipeline completed", toupper(platform)))
  }
}
```

---

## Risk Management

### High-Risk Items

1. **Cyberbiz Sales Pipeline** - Critical production system
   - **Mitigation**: Extensive testing, gradual rollout, immediate rollback capability
   
2. **Data Loss During Migration** - Business critical data
   - **Mitigation**: Complete backups, validation scripts, parallel run period

3. **API Rate Limiting Issues** - Service availability
   - **Mitigation**: Implement proper rate limiting, retry logic, monitoring

4. **Performance Degradation** - User experience impact  
   - **Mitigation**: Performance testing, resource monitoring, optimization

### Medium-Risk Items

1. **Derivation Function Updates** - Analytical processes
   - **Mitigation**: Comprehensive testing, business user validation

2. **Scheduling and Orchestration** - Operational reliability
   - **Mitigation**: Phased deployment, monitoring, fallback procedures

### Low-Risk Items

1. **eBay File Processing** - Manual processes
   - **Mitigation**: User training, documentation

2. **Amazon Historical Data** - Non-critical systems
   - **Mitigation**: Standard testing procedures

---

## Success Criteria

### Technical Success Criteria

- [ ] All platforms have complete separated ETL pipelines (0IM, 1ST, 2TR)
- [ ] All scripts follow DM_R028 naming conventions
- [ ] All outputs comply with MP102 schema standards
- [ ] Zero data loss during migration
- [ ] Performance meets or exceeds current system
- [ ] All derivation functions work with new ETL outputs

### Business Success Criteria

- [ ] All critical business reports continue to function
- [ ] Data quality meets or exceeds current standards
- [ ] ETL processing time is reduced or maintained
- [ ] System reliability is improved
- [ ] Maintenance complexity is reduced

### Operational Success Criteria

- [ ] ETL pipelines can be executed independently
- [ ] Error isolation prevents cascade failures
- [ ] Monitoring and alerting systems are operational
- [ ] Documentation is complete and accurate
- [ ] Team is trained on new architecture

---

## Post-Migration Optimization

### Short-term (1-2 weeks)
- Performance tuning based on production usage
- Fine-tuning of error handling and retry logic
- User feedback incorporation
- Documentation updates based on operational experience

### Medium-term (1-2 months)
- Parallel processing optimization
- Advanced monitoring and alerting setup
- Additional data type pipelines (inventory, promotions, etc.)
- Cross-platform analytics improvements

### Long-term (3-6 months)
- Machine learning integration for data quality
- Real-time streaming ETL capabilities
- Advanced data lineage tracking
- Automated data quality remediation

---

## Conclusion

The migration to the Data Flow Separation Architecture represents a significant improvement in the ETL system's maintainability, reliability, and scalability. By following this comprehensive guide and adhering to the established principles, the migration will result in a more robust and efficient data processing system that can scale with business growth and evolving requirements.

The separated architecture enables:
- **Independent Development**: Teams can work on different data types without conflicts
- **Parallel Processing**: Improved performance through concurrent pipeline execution
- **Error Isolation**: Failures in one data type don't affect others
- **Easier Maintenance**: Clear boundaries and responsibilities for each pipeline
- **Better Testing**: Focused testing for each component
- **Scalable Growth**: Easy addition of new data types and platforms

**Migration Timeline**: 15-21 days  
**Expected Benefits**: 40% reduction in maintenance complexity, 25% improvement in processing speed, 60% reduction in cross-component failures  
**Risk Level**: Medium (with proper mitigation strategies in place)