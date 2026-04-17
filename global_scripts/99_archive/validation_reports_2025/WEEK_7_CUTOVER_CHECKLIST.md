# Week 7 Cutover Checklist

**Project**: MAMBA Precision Marketing ETL+DRV Migration
**Cutover Week**: Week 7 (Following 2-week parallel running)
**Version**: 1.0
**Date Created**: 2025-11-13

---

## Overview

This checklist provides step-by-step execution guidance for Week 7 cutover. All checkboxes must be completed before declaring cutover success. Critical items marked with ⭐ are go/no-go criteria.

**Cutover Approach**: Phased rollout (5 days)
**Rollback Time**: < 5 minutes
**Success Criteria**: 90%+ items complete, zero critical failures

---

## Pre-Cutover Validation (Day 0 - Day Before Week 7)

### Environment Preparation

- [ ] **Database Backups** ⭐
  - [ ] Backup `raw_data.duckdb` (current size: 3.5 MB)
  - [ ] Backup `staged_data.duckdb` (current size: 3.5 MB)
  - [ ] Backup `transformed_data.duckdb` (current size: 3.8 MB)
  - [ ] Backup `processed_data.duckdb` (current size: 1.0 MB)
  - [ ] Verify backup integrity (test restore on sample)
  - [ ] Document backup locations and timestamps

- [ ] **Disk Space Verification** ⭐
  - [ ] Check available space: Need 200 MB minimum (100 MB sales data + 100 MB buffer)
  - [ ] Current usage documented
  - [ ] Cleanup plan ready if space insufficient

- [ ] **Access Verification**
  - [ ] CBZ sales data source accessible
  - [ ] eBay data source accessible (if using)
  - [ ] Database connections tested
  - [ ] API credentials valid (if needed)

### Validation Baseline

- [ ] **Parallel Running Complete** ⭐
  - [ ] Minimum 10 validation runs completed (Target: 14)
  - [ ] PASS rate ≥ 90% (Target: 100%)
  - [ ] Trend analysis shows stability (no degradation pattern)
  - [ ] Last 3 runs all PASS status

- [ ] **Current System State**
  - [ ] All 3 DRV tables exist: features, time_series, poisson_analysis
  - [ ] df_precision_features: 6 product lines, 613 products
  - [ ] df_precision_time_series: Placeholder mode (1 row)
  - [ ] df_precision_poisson_analysis: Placeholder mode (0 rows)
  - [ ] No database corruption detected

- [ ] **Principle Compliance Baseline** ⭐
  - [ ] R116 schema validated (range metadata columns present)
  - [ ] R117 transparency markers present
  - [ ] R118 significance fields present

### Team Readiness

- [ ] **Personnel Availability Confirmed**
  - [ ] Data Engineer available (Days 1-3)
  - [ ] Backend Developer available (Days 2-4)
  - [ ] UI Developer available (Days 3-5)
  - [ ] QA Analyst available (Days 3-5)
  - [ ] Product Manager available (all days)

- [ ] **Communication Plan Ready**
  - [ ] Pre-cutover announcement drafted
  - [ ] Beta release notification ready
  - [ ] Full release announcement ready
  - [ ] Stakeholder distribution list confirmed

- [ ] **Rollback Plan Reviewed**
  - [ ] rollback_to_legacy.sh tested in dry-run mode
  - [ ] Rollback decision criteria agreed
  - [ ] Rollback authorization process clear

---

## Day 1: CBZ Sales Data Integration

### Morning: ETL Execution

- [ ] **Pre-Execution Checks**
  - [ ] CBZ data source connectivity verified
  - [ ] Autoinit system ready (`autoinit()` function available)
  - [ ] Database connections tested

- [ ] **Execute 0IM Phase** ⭐
  ```bash
  Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_0IM.R
  ```
  - [ ] Script completes without errors (exit code 0)
  - [ ] `raw_data.duckdb` size increases
  - [ ] `raw_cbz_sales` table created
  - [ ] Row count > 0
  - [ ] Execution time < 5 minutes

- [ ] **Execute 1ST Phase (R116 Standardization)** ⭐
  ```bash
  Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_1ST.R
  ```
  - [ ] Script completes without errors
  - [ ] `df_cbz_sales___staged` table created in `staged_data.duckdb`
  - [ ] R116 currency fields populated:
    - [ ] price_usd (not NULL)
    - [ ] original_price (matches raw)
    - [ ] original_currency = "TWD"
    - [ ] conversion_rate reasonable (0.031-0.033 range)
    - [ ] conversion_date = today
    - [ ] conversion_source documented
  - [ ] Execution time < 5 minutes

- [ ] **Execute 2TR Phase (Transformation)** ⭐
  ```bash
  Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_2TR.R
  ```
  - [ ] Script completes without errors
  - [ ] `df_cbz_sales___transformed` table created in `transformed_data.duckdb`
  - [ ] transaction_id is unique (no duplicates)
  - [ ] platform_id = "cbz" for all rows
  - [ ] etl_pipeline = "BASE_SALES"
  - [ ] Time dimensions populated (year, month, quarter, weekday)
  - [ ] Execution time < 5 minutes

### Afternoon: Sales Data Validation

- [ ] **Data Quality Checks** ⭐
  - [ ] No NULL values in critical fields:
    - [ ] transaction_id
    - [ ] order_id
    - [ ] product_id
    - [ ] quantity
    - [ ] unit_price
  - [ ] Business logic validation:
    - [ ] line_total = quantity × unit_price (±$0.02 tolerance)
    - [ ] quantity > 0
    - [ ] unit_price ≥ 0
  - [ ] Date range reasonable:
    - [ ] No future dates
    - [ ] order_date within past 12-24 months

- [ ] **Schema Compliance**
  - [ ] All required fields per `transformed_schemas.yaml#sales_transformed` present
  - [ ] Column types correct
  - [ ] Metadata fields populated (transformation_timestamp, transformation_version)

- [ ] **Integration Verification**
  - [ ] Product IDs in sales data match product profile tables
  - [ ] Customer IDs valid (if available)
  - [ ] No orphan records (sales without matching products)

- [ ] **Performance Check**
  - [ ] Query response time acceptable (< 2 seconds for simple queries)
  - [ ] Database file size reasonable (<50 MB total for transformed_data)

### End of Day 1

- [ ] **Status Report**
  - [ ] All 3 ETL scripts executed successfully
  - [ ] Sales data quality validated
  - [ ] No critical issues found
  - [ ] Database backups refreshed (post-sales integration)

- [ ] **Go/No-Go for Day 2** ⭐
  - [ ] All Day 1 critical items (⭐) complete
  - [ ] Zero critical failures
  - [ ] Data quality acceptable
  - [ ] **Decision**: PROCEED / ROLLBACK / INVESTIGATE

---

## Day 2: DRV Table Activation

### Morning: Time Series Activation

- [ ] **Pre-Execution**
  - [ ] Verify sales data available in transformed_data.duckdb
  - [ ] Current df_precision_time_series in placeholder mode confirmed

- [ ] **Execute Time Series DRV** ⭐
  ```bash
  Rscript scripts/update_scripts/ETL/precision/precision_DRV_time_series.R
  ```
  - [ ] Script completes without errors
  - [ ] df_precision_time_series updated (not in placeholder mode)
  - [ ] Row count > 1 (was 1 in placeholder)
  - [ ] data_source changed from "PLACEHOLDER" to "REAL"
  - [ ] filling_method = "none" (assuming complete data)
  - [ ] data_availability = "COMPLETE"

- [ ] **Time Series Validation**
  - [ ] All product lines represented
  - [ ] Time periods cover reasonable range
  - [ ] Metrics calculated correctly (total_sales, total_orders, avg_order_value)
  - [ ] No missing periods (or properly marked if gaps exist)

### Afternoon: Poisson Analysis Activation

- [ ] **Pre-Execution**
  - [ ] Sales data validated
  - [ ] Product profiles available
  - [ ] Current df_precision_poisson_analysis is empty confirmed

- [ ] **Execute Poisson Analysis DRV** ⭐
  ```bash
  Rscript scripts/update_scripts/ETL/precision/precision_DRV_poisson_analysis.R
  ```
  - [ ] Script completes without errors
  - [ ] df_precision_poisson_analysis populated (row count > 0)
  - [ ] Expected row count: 20-50 predictors × 6 product lines = 120-300 rows
  - [ ] All product lines represented

- [ ] **R116 Range Metadata Validation** ⭐ (CRITICAL INNOVATION)
  - [ ] predictor_min populated (>90% of rows)
  - [ ] predictor_max populated (>90% of rows)
  - [ ] predictor_range populated (>90% of rows)
  - [ ] predictor_is_binary correctly flagged (0/1 variables marked TRUE)
  - [ ] predictor_is_categorical correctly flagged
  - [ ] track_multiplier calculated (>90% of rows)
  - [ ] **Target**: ≥90% metadata population rate achieved

- [ ] **R118 Significance Documentation Validation** ⭐
  - [ ] p_value populated for all rows
  - [ ] significance_flag populated correctly:
    - [ ] '***' for p < 0.001
    - [ ] '**' for p < 0.01
    - [ ] '*' for p < 0.05
    - [ ] '' for p ≥ 0.05
  - [ ] Statistical validity: Coefficients reasonable (-10 to +10 typical)

- [ ] **Poisson Analysis Quality Checks**
  - [ ] Model diagnostics acceptable (AIC, deviance)
  - [ ] No singular matrix errors
  - [ ] Predictors logically sound (no nonsense variables)

### End of Day 2

- [ ] **Principle Compliance Report** ⭐
  - [ ] R116 compliance: PASS (≥90% metadata populated)
  - [ ] R117 compliance: PASS (transparency markers active)
  - [ ] R118 compliance: PASS (significance documented)

- [ ] **Validation Run**
  ```bash
  Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R
  ```
  - [ ] Validation status: PASS (all checks green)
  - [ ] No new warnings or failures
  - [ ] Report generated successfully

- [ ] **Go/No-Go for Day 3** ⭐
  - [ ] Both DRV tables activated successfully
  - [ ] R116/R117/R118 compliance validated
  - [ ] Zero critical failures
  - [ ] **Decision**: PROCEED / ROLLBACK / INVESTIGATE

---

## Day 3: UI Component Integration

### Morning: Backend Data Plumbing

- [ ] **Create Adapter Functions**
  - [ ] `get_poisson_features(con, product_line)` implemented
  - [ ] `get_time_series(con, product_line, start_date, end_date)` implemented
  - [ ] `get_feature_prevalence(con, product_lines)` implemented
  - [ ] Unit tests for adapters pass

- [ ] **Test Adapters with Real Data**
  ```R
  con <- dbConnect(duckdb(), "data/processed_data.duckdb")
  poisson_data <- get_poisson_features(con, "milk_frother")
  time_data <- get_time_series(con, "milk_frother", Sys.Date() - 90, Sys.Date())
  dbDisconnect(con)
  ```
  - [ ] Poisson data returns rows
  - [ ] Time series data returns rows
  - [ ] Column names match expectations
  - [ ] Data types correct

### Afternoon: UI Component Updates & Internal UAT

- [ ] **Update Poisson Components**
  - [ ] poissonFeatureAnalysis updated to use `get_poisson_features()`
  - [ ] Display track_multiplier values (R116 innovation)
  - [ ] Show significance_flag visually (R118)
  - [ ] Component renders without errors

- [ ] **Update Time Series Components**
  - [ ] poissonTimeAnalysis updated to use `get_time_series()`
  - [ ] Display R117 transparency indicators:
    - [ ] Color code by data_source (green=REAL, yellow=FILLED, red=SYNTHETIC)
    - [ ] Tooltip shows filling_method
    - [ ] Warning if data_availability != "COMPLETE"
  - [ ] Component renders without errors

- [ ] **Update Position Components** (if applicable)
  - [ ] Integration with df_precision_features
  - [ ] Prevalence data displays correctly

- [ ] **Internal UAT Execution** ⭐
  - [ ] Test participants: 2-3 internal analysts
  - [ ] Duration: 2-4 hours
  - [ ] Test scenarios:
    - [ ] Select product line → view Poisson features
    - [ ] Check track_multiplier values make sense
    - [ ] View time series trends
    - [ ] Verify R117 indicators visible
    - [ ] Test data export functionality
  - [ ] Issues found documented
  - [ ] Critical issues: 0
  - [ ] Minor issues: ≤3

### End of Day 3

- [ ] **UAT Report**
  - [ ] All test scenarios executed
  - [ ] Pass rate: ≥95%
  - [ ] No critical bugs
  - [ ] User feedback documented

- [ ] **Deploy to Test Environment**
  - [ ] Updated components deployed
  - [ ] Smoke test passed
  - [ ] No deployment errors

- [ ] **Go/No-Go for Day 4 (Production Beta)** ⭐
  - [ ] UAT passed (≥95%)
  - [ ] Zero critical bugs
  - [ ] Components stable in test environment
  - [ ] **Decision**: PROCEED to Production / FIX ISSUES / ROLLBACK

---

## Day 4: Limited Production Release (Beta)

### Morning: Production Deployment

- [ ] **Pre-Deployment Checks**
  - [ ] Production database backup refreshed
  - [ ] Rollback script ready (`rollback_to_legacy.sh`)
  - [ ] Monitoring alerts configured
  - [ ] Communication ready

- [ ] **Deploy Updated UI Components** ⭐
  - [ ] Deploy to production with "BETA" label
  - [ ] Smoke test in production environment
  - [ ] Components load without errors
  - [ ] Data displays correctly

- [ ] **Send Beta Announcement**
  - [ ] Email to active users sent
  - [ ] In-app notification displayed
  - [ ] Link to feedback form included

### All Day: Monitoring & Support

- [ ] **Error Monitoring**
  - [ ] Check error logs every 2 hours
  - [ ] No critical exceptions detected
  - [ ] Response time acceptable (<2 seconds)

- [ ] **User Engagement**
  - [ ] Monitor user activity
  - [ ] Collect feedback from beta users
  - [ ] Document reported issues

- [ ] **Performance Metrics**
  - [ ] Page load times ≤ 3 seconds
  - [ ] Database query times ≤ 2 seconds
  - [ ] No memory leaks detected
  - [ ] System uptime: 100%

### End of Day 4

- [ ] **Beta Day Summary**
  - [ ] Active users: [N] users tested beta
  - [ ] Feedback collected: [N] responses
  - [ ] Issues found: [N] critical, [M] minor
  - [ ] Performance: ACCEPTABLE / NEEDS OPTIMIZATION

- [ ] **Issue Triage**
  - [ ] All critical issues resolved or have workarounds
  - [ ] Minor issues prioritized for post-cutover fix

- [ ] **Go/No-Go for Day 5 (Full Release)** ⭐
  - [ ] Zero critical issues unresolved
  - [ ] User feedback positive (≥80% satisfaction)
  - [ ] Performance acceptable
  - [ ] **Decision**: PROCEED to Full Release / EXTEND BETA / ROLLBACK

---

## Day 5: Full Production Release

### Morning: Full Release

- [ ] **Remove Beta Label**
  - [ ] Update UI to remove "BETA" designation
  - [ ] Deploy to all users
  - [ ] Smoke test post-deployment

- [ ] **Send Full Release Announcement** ⭐
  - [ ] Email to all stakeholders
  - [ ] Announce new features:
    - [ ] R116: Real-world impact tracking (track_multiplier)
    - [ ] R117: Data transparency indicators
    - [ ] R118: Statistical significance markers
  - [ ] Link to user guide
  - [ ] Support contact information

### All Day: Monitoring & Validation

- [ ] **Continuous Monitoring**
  - [ ] Error logs checked hourly
  - [ ] Performance metrics tracked
  - [ ] User engagement monitored

- [ ] **Validation Run** (Mid-Day)
  ```bash
  Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R
  ```
  - [ ] Validation status: PASS
  - [ ] No regressions detected
  - [ ] Report archived

### End of Day 5

- [ ] **Success Metrics Report**
  - [ ] Total users reached: [N]
  - [ ] Active engagement: [%]
  - [ ] Error rate: <1%
  - [ ] Performance: Acceptable
  - [ ] User satisfaction: ≥80%

- [ ] **Cutover Declared SUCCESSFUL** ⭐ (or ROLLBACK if issues)
  - [ ] All critical criteria met
  - [ ] System stable for 8+ hours
  - [ ] No major issues detected
  - [ ] **Status**: SUCCESS / ROLLBACK EXECUTED

---

## Day 6: Legacy Archive & Stabilization

### Morning: D04 Legacy Archive

- [ ] **Create Archive Structure**
  ```bash
  mkdir -p scripts/update_scripts/archive/legacy_D04_precision_marketing/{scripts,documentation,analysis}
  ```

- [ ] **Copy D04 Scripts**
  - [ ] All 12 D04 script files copied to archive
  - [ ] Verification: File count and sizes match

- [ ] **Copy Documentation**
  - [ ] D04_poisson_marketing.qmd copied
  - [ ] D04.md changelog copied
  - [ ] Principle references archived

- [ ] **Create Archive README**
  - [ ] README_D04_LEGACY.md created
  - [ ] Contains: archive date, reason, replacement system info
  - [ ] Retention policy documented (1 year until 2026-11-13)

- [ ] **Update CHANGELOG**
  - [ ] D04 archive entry added
  - [ ] Replacement system referenced
  - [ ] Retention date noted

### Afternoon: Documentation Updates

- [ ] **Update System Documentation**
  - [ ] Architecture diagrams reflect new DRV system
  - [ ] ETL workflow documentation current
  - [ ] UI integration guide updated

- [ ] **Update Operational Guides**
  - [ ] Execution procedures documented
  - [ ] Monitoring procedures updated
  - [ ] Troubleshooting guide enhanced

- [ ] **User Documentation**
  - [ ] Feature guide created (R116/R117/R118 benefits)
  - [ ] FAQ updated
  - [ ] Training materials prepared (if needed)

### End of Day 6

- [ ] **Archive Verification**
  - [ ] All D04 files archived
  - [ ] Documentation complete
  - [ ] Team notified of archive location
  - [ ] No active references to D04 in production code

---

## Day 7: Week 7 Wrap-Up

### Morning: Final Validation

- [ ] **Execute Final Validation Run** ⭐
  ```bash
  Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R
  ```
  - [ ] Status: PASS
  - [ ] All 6 checks passing
  - [ ] Report generated and archived

- [ ] **Trend Analysis Review**
  - [ ] 14 validation runs completed (full 2 weeks)
  - [ ] PASS rate: ≥90% (Target: 100%)
  - [ ] Trend stable or improving
  - [ ] No degradation detected

### Afternoon: Retrospective & Reporting

- [ ] **Week 7 Retrospective Meeting**
  - [ ] What went well documented
  - [ ] What could be improved identified
  - [ ] Action items for future migrations created

- [ ] **Week 7 Completion Report**
  - [ ] Executive summary
  - [ ] Success metrics
  - [ ] Lessons learned
  - [ ] Next steps (ongoing monitoring)

- [ ] **Stakeholder Notification**
  - [ ] Success report sent to all stakeholders
  - [ ] Thank you to team members
  - [ ] Ongoing support plan communicated

### End of Day 7

- [ ] **Week 7 COMPLETE** ⭐
  - [ ] All deliverables completed
  - [ ] System operational and stable
  - [ ] Team aligned on next steps
  - [ ] **Status**: MIGRATION COMPLETE

---

## Post-Cutover (Ongoing)

### Monitoring (Days 8-14)

- [ ] **Continue Daily Validation**
  - [ ] Daily runs via `monitor_parallel_runs.sh`
  - [ ] Maintain PASS status
  - [ ] Document any anomalies

- [ ] **Performance Tracking**
  - [ ] Monitor query times
  - [ ] Track database growth
  - [ ] Optimize if needed

### Support (Week 8+)

- [ ] **User Support**
  - [ ] Respond to user questions
  - [ ] Document common issues
  - [ ] Enhance documentation as needed

- [ ] **System Optimization**
  - [ ] Review performance metrics
  - [ ] Optimize slow queries
  - [ ] Refine UI based on feedback

### Future Enhancements

- [ ] **eBay Sales Integration** (if needed)
  - [ ] Evaluate business need
  - [ ] Execute eBay ETL if approved
  - [ ] Validate multi-platform aggregation

- [ ] **Advanced R116 Features**
  - [ ] Data-driven range detection (replace heuristics)
  - [ ] Dynamic track_multiplier calculation
  - [ ] Automated coefficient interpretation

- [ ] **R117 Enhancements**
  - [ ] Advanced gap-filling algorithms
  - [ ] Predictive imputation methods
  - [ ] Enhanced transparency visualizations

---

## Rollback Procedures

### When to Rollback

**Critical Triggers** (Immediate Rollback):
- Database corruption detected
- Data quality failures (>10% NULL in critical fields)
- System unavailable for >15 minutes
- Critical security vulnerability discovered

**Major Triggers** (Rollback within 4 hours):
- User-facing errors affecting >20% of users
- Performance degradation >50% (e.g., 2sec → 3sec+ query times)
- R116/R117/R118 compliance violations

**Minor Issues** (Fix Forward, No Rollback):
- UI cosmetic issues
- Minor performance variations (<20%)
- Non-critical bugs with workarounds

### Rollback Execution

1. **Announce Rollback**:
   ```
   "We're experiencing technical issues and are reverting to the previous system.
   Precision marketing features will be temporarily unavailable during the transition."
   ```

2. **Execute Rollback Script**:
   ```bash
   ./scripts/global_scripts/98_test/rollback_to_legacy.sh --execute
   ```
   - Expected time: <5 minutes
   - Will disable precision marketing features (legacy D04 was broken)

3. **Verify Rollback**:
   - [ ] System returns to pre-cutover state
   - [ ] Databases restored from backups
   - [ ] UI reverted to previous version
   - [ ] System stable

4. **Post-Rollback**:
   - [ ] Incident report created
   - [ ] Root cause analysis initiated
   - [ ] Fix plan developed
   - [ ] Retry cutover scheduled (if appropriate)

---

## Sign-Off

**Cutover Authorization**:

| Role | Name | Date | Signature | Go/No-Go |
|------|------|------|-----------|----------|
| **Technical Lead** | | | | [ ] GO [ ] NO-GO |
| **Data Engineering** | | | | [ ] GO [ ] NO-GO |
| **UI/UX Lead** | | | | [ ] GO [ ] NO-GO |
| **Product Manager** | | | | [ ] GO [ ] NO-GO |
| **QA Lead** | | | | [ ] GO [ ] NO-GO |

**Unanimous GO Required**: All roles must approve before cutover execution.

**Final Authorization**:
- [ ] All Pre-Cutover Validation items complete
- [ ] All sign-offs obtained
- [ ] Rollback plan confirmed ready
- [ ] Team briefed on Day 1 execution plan

**Week 7 Cutover AUTHORIZED**: _____________________ (Product Manager Signature & Date)

---

**Checklist Version**: 1.0
**Created**: 2025-11-13
**Author**: principle-product-manager
**Next Review**: Day 0 (day before cutover execution)

---

*This checklist must be reviewed daily during Week 7. All items must be checked before declaring cutover success. Any critical (⭐) item failure triggers go/no-go decision review.*
