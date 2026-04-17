# Cutover Readiness Checklist

**Project**: MAMBA ETL+DRV Pipeline Migration
**Cutover Date**: TBD (Week 7 - after 2 weeks parallel running)
**Version**: 1.0
**Last Updated**: 2025-11-13

---

## Overview

This checklist validates readiness to cutover from legacy D04 system to new MAMBA ETL+DRV pipeline. The cutover will transition precision marketing analytics from broken D04 implementation to the new R116/R117/R118 compliant system.

**Critical Note**: Legacy D04 precision marketing was **broken**, so validation focuses on new system compliance rather than legacy comparison.

---

## Phase 1: Technical Validation

### 1.1 Database Infrastructure

- [ ] **Raw Data Layer** (raw_data.duckdb)
  - [ ] Database file created and accessible
  - [ ] All source tables present (products, reviews, qa, etc.)
  - [ ] Row counts validated against source
  - [ ] No data corruption detected

- [ ] **Staging Layer** (staged_data.duckdb)
  - [ ] Database file created and accessible
  - [ ] All staged tables present
  - [ ] SCD Type 2 logic verified
  - [ ] Data quality checks passed

- [ ] **Transformed Layer** (transformed_data.duckdb)
  - [ ] Database file created and accessible
  - [ ] All transformed tables present
  - [ ] Business logic transformations verified
  - [ ] Schema registry compliance validated

- [ ] **Processed Layer** (processed_data.duckdb)
  - [ ] Database file created and accessible
  - [ ] All 3 DRV tables present:
    - [ ] df_precision_features
    - [ ] df_precision_time_series
    - [ ] df_precision_poisson_analysis
  - [ ] Total database size < 50MB (currently ~1MB)

### 1.2 ETL Pipeline Execution

- [ ] **Week 1 Scripts** (1ST Layer)
  - [ ] customers_1ST.R: Executes without errors
  - [ ] orders_1ST.R: Executes without errors
  - [ ] products_1ST.R: Executes without errors
  - [ ] sales_1ST.R: Executes without errors (when sales data available)

- [ ] **Week 2 Scripts** (2TR Layer)
  - [ ] customers_2TR.R: Executes without errors
  - [ ] orders_2TR.R: Executes without errors
  - [ ] products_2TR.R: Executes without errors
  - [ ] sales_2TR.R: Executes without errors (when sales data available)

- [ ] **Week 3 Scripts** (3RD Layer)
  - [ ] All transformation scripts execute successfully
  - [ ] Output tables match schema registry

- [ ] **Week 4 Scripts** (4TH Layer - DRV)
  - [ ] D_precision_features.R: Executes successfully
  - [ ] D_precision_time_series.R: Executes successfully (placeholder mode OK)
  - [ ] D_precision_poisson_analysis.R: Executes successfully (placeholder mode OK)

### 1.3 Data Quality

- [ ] **df_precision_features**
  - [ ] Row count > 0 (currently: 3 product lines)
  - [ ] All expected columns present (28 columns)
  - [ ] Prevalence calculations validated
  - [ ] Aggregation metadata populated
  - [ ] Source tracking present

- [ ] **df_precision_time_series**
  - [ ] Schema matches specification (12 columns)
  - [ ] R117 transparency markers present:
    - [ ] data_source column
    - [ ] filling_method column
    - [ ] data_availability column
  - [ ] Placeholder mode documented (awaiting sales data)

- [ ] **df_precision_poisson_analysis**
  - [ ] Schema matches specification (19 columns)
  - [ ] R118 compliance fields present:
    - [ ] p_value column
    - [ ] significance_flag column
  - [ ] R116 range metadata fields present:
    - [ ] predictor_min column
    - [ ] predictor_max column
    - [ ] predictor_range column
    - [ ] predictor_is_binary column
    - [ ] predictor_is_categorical column
  - [ ] Placeholder mode documented (awaiting sales data)

---

## Phase 2: Principle Compliance

### 2.1 R116: Variable Range Metadata (CRITICAL INNOVATION)

- [ ] **Schema Validation**
  - [ ] All range metadata columns present in df_precision_poisson_analysis
  - [ ] Column types correct (numeric for ranges, logical for flags)
  - [ ] track_multiplier field present

- [ ] **Implementation Readiness**
  - [ ] D_precision_poisson_analysis.R includes range calculation logic
  - [ ] Binary variable detection logic verified
  - [ ] Categorical variable detection logic verified
  - [ ] Coefficient tracking multiplier calculation verified

- [ ] **Documentation**
  - [ ] R116 principle documented
  - [ ] Usage examples available
  - [ ] Benefits clearly articulated

**Target**: 90%+ of predictors have populated range metadata when sales data integrated

### 2.2 R117: Time Series Transparency

- [ ] **Mandatory Fields Present**
  - [ ] data_source: Documents real vs synthetic vs imputed
  - [ ] filling_method: Documents interpolation/extrapolation method
  - [ ] data_availability: Flags data quality issues

- [ ] **Implementation Verification**
  - [ ] D_precision_time_series.R sets appropriate values
  - [ ] Placeholder mode clearly marked
  - [ ] Real data mode logic prepared

- [ ] **Documentation**
  - [ ] R117 principle documented
  - [ ] Filling methods cataloged
  - [ ] UI integration planned

**Current Status**: PASS (placeholder mode)
**Ready for**: Sales data integration

### 2.3 R118: Statistical Significance Documentation

- [ ] **Mandatory Fields Present**
  - [ ] p_value: Raw p-value from model
  - [ ] significance_flag: Human-readable interpretation

- [ ] **Implementation Verification**
  - [ ] D_precision_poisson_analysis.R calculates p-values
  - [ ] Significance thresholds defined (0.05, 0.01, 0.001)
  - [ ] Flag generation logic verified

- [ ] **Documentation**
  - [ ] R118 principle documented
  - [ ] Significance levels defined
  - [ ] UI display standards set

**Current Status**: PASS (schema ready)
**Ready for**: Sales data integration

---

## Phase 3: Parallel Running Validation

### 3.1 Monitoring Infrastructure

- [ ] **Comparison Script**
  - [ ] compare_legacy_vs_new.R executes successfully
  - [ ] Generates CSV output
  - [ ] Generates markdown report
  - [ ] Validates all 3 DRV tables

- [ ] **Automation**
  - [ ] monitor_parallel_runs.sh executes successfully
  - [ ] Daily automation configured (if desired)
  - [ ] Trend analysis generates correctly

- [ ] **Validation Runs**
  - [ ] Minimum 10 successful validation runs completed
  - [ ] 90%+ PASS rate across all checks
  - [ ] No FAIL status in last 5 runs
  - [ ] Trend analysis shows stability

### 3.2 Legacy Comparison

- [ ] **Legacy System Assessment**
  - [ ] Legacy D04 status documented (BROKEN)
  - [ ] No functional precision marketing tables in legacy
  - [ ] Comparison strategy: Principle-based validation

- [ ] **Validation Strategy**
  - [ ] Focus on R116/R117/R118 compliance (not legacy comparison)
  - [ ] Schema validation prioritized
  - [ ] Data quality metrics established

### 3.3 Performance Metrics

- [ ] **Execution Time**
  - [ ] Full ETL pipeline (Week 1-4): < 5 minutes
  - [ ] Individual DRV scripts: < 30 seconds each
  - [ ] Validation script: < 30 seconds

- [ ] **Resource Usage**
  - [ ] Memory usage acceptable (< 2GB)
  - [ ] Database file sizes reasonable (< 50MB total)
  - [ ] No memory leaks detected

- [ ] **Reliability**
  - [ ] 10 consecutive successful runs
  - [ ] No unexpected failures
  - [ ] Error handling verified

---

## Phase 4: Integration Readiness

### 4.1 Sales Data Integration

- [ ] **Data Availability**
  - [ ] Sales data source identified
  - [ ] ETL scripts ready (sales_1ST.R, sales_2TR.R)
  - [ ] Schema validated

- [ ] **Integration Testing**
  - [ ] Time series activation tested
  - [ ] Poisson analysis activation tested
  - [ ] Range metadata population verified

- [ ] **Activation Plan**
  - [ ] Documented procedure for sales data integration
  - [ ] Rollback plan if integration fails
  - [ ] Validation criteria defined

### 4.2 UI Component Integration

- [ ] **Component Identification**
  - [ ] UI components requiring DRV data identified
  - [ ] Dependencies mapped
  - [ ] Migration plan created

- [ ] **Testing**
  - [ ] Components tested with placeholder data
  - [ ] Components ready for real data
  - [ ] Error handling verified

- [ ] **Documentation**
  - [ ] API endpoints documented
  - [ ] Data formats specified
  - [ ] Integration examples provided

### 4.3 Application Deployment

- [ ] **Configuration**
  - [ ] Database connections configured
  - [ ] Environment variables set
  - [ ] Deployment scripts updated

- [ ] **Testing**
  - [ ] End-to-end testing completed
  - [ ] UI displays data correctly
  - [ ] Performance acceptable

---

## Phase 5: Operational Readiness

### 5.1 Documentation

- [ ] **Technical Documentation**
  - [ ] Architecture diagrams updated
  - [ ] ETL workflow documented
  - [ ] Schema registry current
  - [ ] Principle documents (R116/R117/R118) complete

- [ ] **Operational Guides**
  - [ ] Execution procedures documented
  - [ ] Monitoring procedures defined
  - [ ] Troubleshooting guide created

- [ ] **User Documentation**
  - [ ] Feature changes documented
  - [ ] New capabilities explained
  - [ ] Migration impact assessed

### 5.2 Rollback Plan

- [ ] **Rollback Script**
  - [ ] rollback_to_legacy.sh created
  - [ ] Tested in non-production environment
  - [ ] Execution time < 5 minutes

- [ ] **Rollback Triggers**
  - [ ] Criteria defined (data corruption, performance degradation)
  - [ ] Decision makers identified
  - [ ] Communication plan established

- [ ] **Rollback Testing**
  - [ ] Dry run completed successfully
  - [ ] Data restoration verified
  - [ ] Application functionality confirmed

### 5.3 Monitoring and Alerting

- [ ] **Monitoring**
  - [ ] Daily validation automated
  - [ ] Trend analysis generated
  - [ ] Alerts configured for failures

- [ ] **Support**
  - [ ] Issue escalation path defined
  - [ ] On-call rotation established (if applicable)
  - [ ] Support documentation available

---

## Phase 6: Stakeholder Approval

### 6.1 Technical Sign-off

- [ ] **Data Engineering**
  - [ ] ETL pipeline approved
  - [ ] Data quality validated
  - [ ] Performance acceptable

- [ ] **Analytics**
  - [ ] DRV outputs validated
  - [ ] Statistical methods approved
  - [ ] Compliance verified (R116/R117/R118)

### 6.2 Business Sign-off

- [ ] **Product Owner**
  - [ ] Feature completeness validated
  - [ ] Migration risk accepted
  - [ ] Cutover date approved

- [ ] **Operations**
  - [ ] Monitoring adequate
  - [ ] Support plan acceptable
  - [ ] Rollback plan approved

---

## Pre-Cutover Final Checks

**To be completed 24 hours before cutover:**

- [ ] Run full validation suite
- [ ] Verify all checks above are complete
- [ ] Confirm rollback plan is ready
- [ ] Notify stakeholders
- [ ] Schedule cutover window
- [ ] Prepare communication

---

## Cutover Execution

**During cutover window:**

1. [ ] Stop legacy D04 jobs (if any)
2. [ ] Run final validation
3. [ ] Execute full ETL+DRV pipeline
4. [ ] Validate all outputs
5. [ ] Deploy updated UI components
6. [ ] Verify end-to-end functionality
7. [ ] Monitor for 2 hours post-cutover
8. [ ] Declare success OR execute rollback

---

## Post-Cutover

**Within 24 hours:**

- [ ] Post-cutover validation completed
- [ ] Performance metrics reviewed
- [ ] Issues logged and triaged
- [ ] Stakeholders notified of status
- [ ] Documentation updated

**Within 1 week:**

- [ ] Retrospective completed
- [ ] Lessons learned documented
- [ ] Process improvements identified
- [ ] Legacy system decommissioned (if applicable)

---

## Current Status Summary

**Last Updated**: 2025-11-13

### Completed
✅ ETL+DRV pipeline (Week 1-4) fully operational
✅ All 3 DRV tables created with correct schemas
✅ R116/R117/R118 principle compliance validated
✅ Parallel running monitoring infrastructure ready
✅ Comparison and monitoring scripts operational

### In Progress
🔄 Sales data integration preparation
🔄 UI component integration planning
🔄 Parallel running validation (2-week period)

### Pending
⏳ Sales data source integration
⏳ End-to-end testing with real sales data
⏳ UI component updates
⏳ Stakeholder sign-offs

### Blockers
🚫 **None currently** - All critical path items unblocked
ℹ️ Sales data integration is next major milestone

---

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Technical Lead | | | |
| Data Engineering | | | |
| Analytics | | | |
| Product Owner | | | |
| Operations | | | |

---

**Notes**:
- This checklist will be updated as parallel running progresses
- Additional items may be added based on findings
- Weekly review recommended during parallel running phase

*Checklist created: 2025-11-13*
*Location: validation/CUTOVER_READINESS_CHECKLIST.md*
