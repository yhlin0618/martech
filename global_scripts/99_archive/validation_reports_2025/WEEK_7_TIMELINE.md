# Week 7 Timeline: Detailed Execution Schedule

**Project**: MAMBA Precision Marketing ETL+DRV Migration
**Phase**: Week 7 - Sales Data Integration & System Cutover
**Duration**: 7 working days + 1 buffer day
**Coordinator**: principle-product-manager

---

## Timeline Overview

```
Day 0 (Pre-Week 7)  Day 1          Day 2          Day 3          Day 4          Day 5          Day 6          Day 7
[PREPARATION]      [SALES ETL]    [DRV ACTIVE]   [UI INTEGRATE] [BETA RELEASE] [FULL RELEASE] [ARCHIVE]      [WRAP-UP]
     |                 |              |              |              |              |              |              |
   Backup          0IM→1ST→2TR    Time Series   Adapters      Deploy Beta    Remove Beta   D04 Archive   Final Valid
   Verify          Validate       Poisson       Components    Monitor        Announce      Document      Retrospect
   Prep Team       Quality        R116/R117     UAT           Collect FB     Monitor       Update        Report
                   Check          R118          Go/No-Go      Triage         Success       CHANGELOG     Complete
```

**Critical Path**: Day 1 → Day 2 → Day 3 → Day 4 → Day 5
**Buffer**: Day 7 can extend to Day 8 if needed
**Rollback Points**: End of Day 1, 2, 3, 4

---

## Day 0: Pre-Week 7 Preparation (Day Before Execution)

**Date**: TBD (Day before Week 7 starts)
**Duration**: 4-6 hours
**Lead**: Product Manager + Data Engineer
**Critical**: YES ⭐ (Failure to prepare = high Week 7 risk)

### Morning (08:00 - 12:00)

#### 08:00 - 09:00: Environment Verification
- [ ] **Database Backups** (1 hour):
  ```bash
  # Create timestamped backups
  timestamp=$(date +%Y%m%d_%H%M%S)
  cp data/raw_data.duckdb data/backups/raw_data_pre_week7_${timestamp}.duckdb
  cp data/staged_data.duckdb data/backups/staged_data_pre_week7_${timestamp}.duckdb
  cp data/transformed_data.duckdb data/backups/transformed_data_pre_week7_${timestamp}.duckdb
  cp data/processed_data.duckdb data/backups/processed_data_pre_week7_${timestamp}.duckdb
  ```
- [ ] Verify backup integrity (test read from each)
- [ ] Document backup timestamps and sizes

#### 09:00 - 10:00: Data Source Validation
- [ ] **CBZ Sales Data Access**:
  ```bash
  # Test connection
  Rscript scripts/update_scripts/ETL/cbz/test_cbz_connection.R
  ```
  - [ ] Connection successful
  - [ ] Sample data retrievable (>100 rows)
  - [ ] Data fields match expected schema
  - [ ] Date range covers past 12-24 months

- [ ] **Disk Space Check**:
  ```bash
  df -h data/
  # Require: ≥200 MB free
  ```

- [ ] **Network Connectivity**: Verify stable connection to data sources

#### 10:00 - 11:00: Team Alignment Meeting
**Attendees**: All Week 7 team members

**Agenda**:
1. Review Week 7 timeline (15 min)
2. Review risk assessment and mitigation strategies (15 min)
3. Clarify roles and responsibilities (10 min)
4. Q&A and concerns (10 min)
5. Confirm go/no-go decision process (10 min)

**Outputs**:
- [ ] Team aligned on timeline
- [ ] Risks understood
- [ ] Communication plan confirmed
- [ ] Daily standup time scheduled (suggest 09:00 daily)

#### 11:00 - 12:00: Documentation Review
- [ ] Review Implementation Plan
- [ ] Review Cutover Checklist
- [ ] Review Rollback Procedures
- [ ] Ensure all team members have access

### Afternoon (13:00 - 17:00)

#### 13:00 - 14:00: Rollback Testing
- [ ] **Dry Run Rollback Script**:
  ```bash
  ./scripts/global_scripts/98_test/rollback_to_legacy.sh --check
  ```
- [ ] Review output, ensure no errors
- [ ] Confirm rollback time estimate (<5 minutes)
- [ ] Document manual rollback steps (if script fails)

#### 14:00 - 15:00: Stakeholder Communication
- [ ] **Send Pre-Cutover Announcement**:
  - To: All dashboard users
  - Subject: "Precision Marketing System Upgrade - Week 7"
  - Content:
    - Upgrade schedule (Day 1-5)
    - Expected improvements (R116/R117/R118 benefits)
    - Minimal expected downtime
    - Support contact information

#### 15:00 - 16:00: Final Validation Run
- [ ] **Execute Baseline Validation**:
  ```bash
  Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R
  ```
- [ ] Verify: PASS status (6/6 checks)
- [ ] Document: Final pre-Week 7 baseline
- [ ] Archive report: `validation/parallel_run_pre_week7.md`

#### 16:00 - 17:00: Pre-Flight Checklist Review
- [ ] All Day 0 tasks complete
- [ ] Zero critical blockers identified
- [ ] Team ready for Day 1 execution
- [ ] **Final Go/No-Go Decision**: _______ (PM signature)

### End of Day 0
**Output**: Pre-Week 7 Readiness Report
**Decision**: GO / NO-GO for Week 7 execution
**Status**: READY / BLOCKED

---

## Day 1: CBZ Sales Data Integration

**Date**: TBD (Week 7 Day 1)
**Duration**: 8 hours
**Lead**: Data Engineer
**Critical**: YES ⭐ (Failure blocks entire Week 7)
**Rollback Point**: End of Day 1

### Morning (08:00 - 12:00): ETL Execution

#### 08:00 - 08:15: Daily Standup
- Review Day 1 plan
- Confirm team availability
- Address any overnight concerns

#### 08:15 - 09:00: Pre-Execution Checks (45 min)
- [ ] Verify CBZ data source still accessible
- [ ] Confirm disk space available (≥200 MB)
- [ ] Check `autoinit()` system ready
- [ ] Open monitoring dashboard

#### 09:00 - 09:30: Execute 0IM Phase (30 min target)
```bash
time Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_0IM.R | tee logs/cbz_0IM_$(date +%Y%m%d).log
```
**Expected Duration**: 5-10 minutes
**Success Criteria**:
- [ ] Exit code 0
- [ ] `raw_cbz_sales` table created
- [ ] Row count > 0 (expect 1000+ rows)
- [ ] No error messages in log

**If Failure**:
- Review error log
- Fix within 30 minutes
- Retry (max 3 attempts)
- If 3 failures → Escalate to technical lead

#### 09:30 - 10:00: Execute 1ST Phase (30 min target)
```bash
time Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_1ST.R | tee logs/cbz_1ST_$(date +%Y%m%d).log
```
**Expected Duration**: 5-10 minutes
**Success Criteria**:
- [ ] Exit code 0
- [ ] `df_cbz_sales___staged` table created
- [ ] R116 currency fields populated
- [ ] conversion_rate in reasonable range (0.031-0.033 for TWD/USD)

#### 10:00 - 10:30: Execute 2TR Phase (30 min target)
```bash
time Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_2TR.R | tee logs/cbz_2TR_$(date +%Y%m%d).log
```
**Expected Duration**: 5-10 minutes
**Success Criteria**:
- [ ] Exit code 0
- [ ] `df_cbz_sales___transformed` table created
- [ ] transaction_id unique
- [ ] platform_id = "cbz"

#### 10:30 - 11:00: Coffee Break + Status Update
- Quick team sync
- Report ETL execution status
- Prepare for validation

#### 11:00 - 12:00: Sales Data Quality Validation (1 hour)
**Execute validation queries**:
```R
library(DBI); library(duckdb)
con <- dbConnect(duckdb(), "data/transformed_data.duckdb")

# Row count
dbGetQuery(con, "SELECT COUNT(*) as n FROM df_cbz_sales___transformed")

# Check for NULLs in critical fields
dbGetQuery(con, "
  SELECT
    SUM(CASE WHEN transaction_id IS NULL THEN 1 ELSE 0 END) as null_txn,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) as null_qty,
    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END) as null_price
  FROM df_cbz_sales___transformed
")

# Business logic validation
dbGetQuery(con, "
  SELECT COUNT(*) as mismatch_count
  FROM df_cbz_sales___transformed
  WHERE ABS(line_total - (quantity * unit_price)) > 0.02
")

dbDisconnect(con)
```

**Validation Checklist**:
- [ ] Row count > 0 (expect 1000+ transactions)
- [ ] Zero NULLs in transaction_id, quantity, unit_price
- [ ] line_total = quantity × unit_price (within $0.02 tolerance)
- [ ] All dates reasonable (not future, within past 24 months)
- [ ] Conversion rates valid (0.031-0.033 range for TWD)

### Afternoon (13:00 - 17:00): Extended Validation & Reporting

#### 13:00 - 14:00: Schema Compliance Check (1 hour)
- [ ] Verify all required fields per `transformed_schemas.yaml#sales_transformed`
- [ ] Check column types correct
- [ ] Validate metadata fields (transformation_timestamp, etc.)
- [ ] Cross-reference product IDs with product profile tables

#### 14:00 - 15:00: Integration Testing (1 hour)
- [ ] Test JOIN between sales and product profiles
- [ ] Verify no orphan sales records
- [ ] Check for customer ID validity (if applicable)
- [ ] Performance test: Basic queries <2 seconds

#### 15:00 - 16:00: Database Backup (Post-Sales) (1 hour)
```bash
# Refresh backups with sales data integrated
timestamp=$(date +%Y%m%d_%H%M%S)
cp data/raw_data.duckdb data/backups/raw_data_post_sales_${timestamp}.duckdb
cp data/staged_data.duckdb data/backups/staged_data_post_sales_${timestamp}.duckdb
cp data/transformed_data.duckdb data/backups/transformed_data_post_sales_${timestamp}.duckdb
```

#### 16:00 - 17:00: Day 1 Status Report & Go/No-Go (1 hour)
**Generate Day 1 Report**:
- ETL execution summary (success/failure, timing)
- Data quality validation results (PASS/FAIL)
- Issues encountered and resolutions
- Database sizes (before/after)

**Day 1 Go/No-Go Decision** ⭐:
- [ ] All 3 ETL scripts executed successfully
- [ ] Data quality validation PASS
- [ ] Zero critical issues
- [ ] Database backups refreshed
- **Decision**: PROCEED to Day 2 / ROLLBACK / DEFER

**If ROLLBACK needed**:
```bash
./scripts/global_scripts/98_test/rollback_to_legacy.sh --execute
```

### End of Day 1
**Output**: Day 1 Execution Report
**Status**: SALES DATA INTEGRATED / BLOCKED
**Next**: Day 2 (DRV Activation) or Investigation/Retry

---

## Day 2: DRV Table Activation

**Date**: Week 7 Day 2
**Duration**: 8 hours
**Lead**: Data Scientist + Data Engineer
**Critical**: YES ⭐ (Core analytics depend on this)
**Rollback Point**: End of Day 2

### Morning (08:00 - 12:00): Time Series Activation

#### 08:00 - 08:15: Daily Standup
- Review Day 1 results
- Confirm Day 2 readiness
- Address any concerns

#### 08:15 - 08:30: Pre-Execution Validation (15 min)
- [ ] Verify sales data available in transformed_data.duckdb
- [ ] Confirm product profiles available
- [ ] Check current time_series status (should be placeholder with 1 row)

#### 08:30 - 09:30: Execute Time Series DRV (1 hour)
```bash
time Rscript scripts/update_scripts/ETL/precision/precision_DRV_time_series.R | tee logs/df_time_series_$(date +%Y%m%d).log
```
**Expected Duration**: 10-20 minutes
**Success Criteria**:
- [ ] Script completes without errors
- [ ] Row count > 1 (was 1 in placeholder mode)
- [ ] data_source changed from "PLACEHOLDER" to "REAL"
- [ ] All 6 product lines represented

#### 09:30 - 10:30: Time Series Validation (1 hour)
```R
con <- dbConnect(duckdb(), "data/processed_data.duckdb")

# Check activation
dbGetQuery(con, "SELECT COUNT(*) as n, COUNT(DISTINCT product_line) as lines FROM df_precision_time_series")

# Verify R117 compliance
dbGetQuery(con, "SELECT DISTINCT data_source, filling_method, data_availability FROM df_precision_time_series")

# Check time periods
dbGetQuery(con, "SELECT MIN(date) as start_date, MAX(date) as end_date FROM df_precision_time_series")

dbDisconnect(con)
```

**Validation Checklist**:
- [ ] Row count ≥10 (expect N periods × 6 product lines)
- [ ] data_source = "REAL" (not PLACEHOLDER)
- [ ] filling_method = "none" (assuming complete data)
- [ ] data_availability = "COMPLETE"
- [ ] Time range covers sales data period
- [ ] Metrics calculated (total_sales, total_orders, avg_order_value)

#### 10:30 - 11:00: Coffee Break

#### 11:00 - 12:00: Time Series Quality Check (1 hour)
- [ ] Visual inspection: Plot time series trends
- [ ] Anomaly detection: Check for unreasonable spikes/drops
- [ ] Completeness: Verify no unexpected missing periods
- [ ] Cross-validation: Compare aggregated sales to raw sales totals

### Afternoon (13:00 - 17:00): Poisson Analysis Activation

#### 13:00 - 13:30: Pre-Execution Setup (30 min)
- [ ] Verify product profiles with attributes available
- [ ] Check sales data linkage
- [ ] Review model parameters

#### 13:30 - 15:00: Execute Poisson Analysis DRV (1.5 hours)
```bash
time Rscript scripts/update_scripts/ETL/precision/precision_DRV_poisson_analysis.R | tee logs/df_poisson_$(date +%Y%m%d).log
```
**Expected Duration**: 20-60 minutes (depends on model fitting)
**Success Criteria**:
- [ ] Script completes without errors
- [ ] Row count > 0 (expect 120-300 rows: 20-50 predictors × 6 product lines)
- [ ] All 6 product lines represented

#### 15:00 - 16:30: Poisson Analysis Validation (1.5 hours)
```R
con <- dbConnect(duckdb(), "data/processed_data.duckdb")

# Row count and coverage
dbGetQuery(con, "SELECT COUNT(*) as n, COUNT(DISTINCT product_line) as lines FROM df_precision_poisson_analysis")

# R116 metadata population rate
dbGetQuery(con, "
  SELECT
    COUNT(*) as total_predictors,
    SUM(CASE WHEN predictor_range IS NOT NULL THEN 1 ELSE 0 END) as range_populated,
    ROUND(100.0 * SUM(CASE WHEN predictor_range IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 1) as pct
  FROM df_precision_poisson_analysis
")

# R118 significance validation
dbGetQuery(con, "
  SELECT significance_flag, COUNT(*) as count
  FROM df_precision_poisson_analysis
  GROUP BY significance_flag
")

dbDisconnect(con)
```

**Validation Checklist (Critical)**:
- [ ] Row count 120-300 (reasonable range)
- [ ] R116 metadata population ≥90% ⭐ (Target met)
  - [ ] predictor_min populated (>90%)
  - [ ] predictor_max populated (>90%)
  - [ ] predictor_range populated (>90%)
  - [ ] track_multiplier calculated (>90%)
- [ ] R118 significance documentation complete:
  - [ ] p_value populated (100%)
  - [ ] significance_flag calculated (100%)
  - [ ] Flag distribution reasonable (expect ~5% '***', ~10% '**', ~20% '*')

**If R116 <90% populated**:
- Review failed predictors
- Identify patterns (e.g., specific Chinese variable types)
- Decision: PROCEED if ≥80% / INVESTIGATE if <80%

#### 16:30 - 17:00: Day 2 Validation Run & Reporting (30 min)
```bash
Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R
```
**Expected**: PASS status (all 6 checks)

**Day 2 Go/No-Go Decision** ⭐:
- [ ] Time series activated (exited placeholder mode)
- [ ] Poisson analysis activated (populated)
- [ ] R116 metadata ≥90% (or ≥80% with documented plan)
- [ ] R117 transparency markers active
- [ ] R118 significance documented
- [ ] Validation PASS
- **Decision**: PROCEED to Day 3 / INVESTIGATE / ROLLBACK

### End of Day 2
**Output**: Day 2 DRV Activation Report
**Status**: DRV ACTIVATED / BLOCKED
**Next**: Day 3 (UI Integration) or Investigation/Retry

---

## Day 3: UI Component Integration

**Date**: Week 7 Day 3
**Duration**: 8 hours
**Lead**: Backend Developer + UI Developer
**Critical**: YES (User-facing)
**Rollback Point**: End of Day 3

### Morning (08:00 - 12:00): Backend Adapter Development

#### 08:00 - 08:15: Daily Standup

#### 08:15 - 10:00: Create Adapter Functions (1.75 hours)
**Implement**:
1. `get_poisson_features(con, product_line)`
2. `get_time_series(con, product_line, start_date, end_date)`
3. `get_feature_prevalence(con, product_lines)`

**Location**: `scripts/global_scripts/04_utils/fn_drv_adapters.R`

**Unit Testing**:
```R
# Test with real data
con <- dbConnect(duckdb(), "data/processed_data.duckdb")
test_poisson <- get_poisson_features(con, "milk_frother")
test_ts <- get_time_series(con, "milk_frother", Sys.Date()-90, Sys.Date())
dbDisconnect(con)

# Verify outputs
stopifnot(nrow(test_poisson) > 0)
stopifnot("track_multiplier" %in% names(test_poisson))  # R116
stopifnot("significance_flag" %in% names(test_poisson))  # R118
stopifnot("data_source" %in% names(test_ts))  # R117
```

#### 10:00 - 12:00: Update UI Components (2 hours)
**Poisson Feature Analysis**:
- Modify `poissonFeatureAnalysis.R` to use `get_poisson_features()`
- Add track_multiplier display
- Add significance_flag visual indicators (stars ***)

**Time Series Analysis**:
- Modify `poissonTimeAnalysis.R` to use `get_time_series()`
- Add R117 transparency indicators (color code by data_source)
- Add tooltips for filling_method

**Component Testing**:
- Test in dev environment
- Verify data displays correctly
- Check no JavaScript errors

### Afternoon (13:00 - 17:00): Internal UAT & Beta Prep

#### 13:00 - 15:00: Internal UAT Execution (2 hours)
**Participants**: 2-3 internal analysts

**Test Scenarios**:
1. **Poisson Features**:
   - [ ] Select product line → view attribute importance
   - [ ] Check track_multiplier values reasonable
   - [ ] Verify significance stars display correctly
   - [ ] Test filtering by significance level

2. **Time Series**:
   - [ ] Select date range → view trends
   - [ ] Verify R117 indicators visible
   - [ ] Check data_source color coding (green=REAL)
   - [ ] Test data export functionality

3. **General**:
   - [ ] Performance acceptable (<3 seconds page load)
   - [ ] No UI errors or broken layouts
   - [ ] Mobile responsive (if applicable)

**Issue Tracking**:
- Document all issues found
- Classify: CRITICAL / MAJOR / MINOR
- Triage: FIX NOW / FIX BEFORE BETA / FIX POST-CUTOVER

#### 15:00 - 16:00: Issue Resolution (1 hour)
- Fix CRITICAL issues immediately
- Plan fixes for MAJOR issues before beta
- Document MINOR issues for post-cutover

#### 16:00 - 17:00: UAT Report & Go/No-Go (1 hour)
**UAT Results Summary**:
- Test scenarios executed: [N/N]
- Pass rate: [%] (Target: ≥95%)
- Critical issues: [N] (Target: 0)
- Major issues: [N] (Target: ≤2)
- Minor issues: [N] (Accept any number)

**Day 3 Go/No-Go Decision** ⭐:
- [ ] UAT pass rate ≥95%
- [ ] Zero critical bugs
- [ ] All major issues resolved or have workarounds
- [ ] Components stable in test environment
- **Decision**: PROCEED to Beta (Day 4) / FIX ISSUES / ROLLBACK

### End of Day 3
**Output**: UAT Report + Beta Release Package
**Status**: READY FOR BETA / BLOCKED
**Next**: Day 4 (Beta Release) or Fix/Retry

---

## Day 4: Limited Production Release (Beta)

**Date**: Week 7 Day 4
**Duration**: 8 hours
**Lead**: Product Manager + QA Analyst
**Critical**: MODERATE (Can extend beta if issues)
**Rollback Point**: End of Day 4

### Morning (08:00 - 12:00): Beta Deployment

#### 08:00 - 08:15: Daily Standup + Go/No-Go Confirmation

#### 08:15 - 09:00: Pre-Deployment Final Checks (45 min)
- [ ] Production database backup refreshed
- [ ] Rollback script ready
- [ ] Monitoring alerts configured
- [ ] Beta announcement drafted

#### 09:00 - 10:00: Deploy to Production with BETA Label (1 hour)
**Deployment Steps**:
1. Update UI components (include "BETA" designation)
2. Deploy to production server
3. Smoke test in production
4. Verify components load without errors

**Deployment Verification**:
- [ ] Components deployed successfully
- [ ] Database connections work
- [ ] Sample data displays correctly
- [ ] No 500 errors in logs

#### 10:00 - 10:30: Send Beta Announcement (30 min)
**Email to Active Users**:
```
Subject: Try Our New Precision Marketing Features (BETA)

We're excited to announce new precision marketing enhancements:

• Real-world impact tracking (R116 innovation)
• Data transparency indicators (R117)
• Statistical significance markers (R118)

This is a BETA release. Please try the new features and share feedback:
[Feedback Form Link]

Thank you for helping us improve!
```

**In-App Notification**: Display banner with "BETA - New Features Available"

#### 10:30 - 12:00: Monitoring Setup (1.5 hours)
- Configure error monitoring (check every 2 hours)
- Set up performance tracking
- Prepare feedback collection spreadsheet

### Afternoon (13:00 - 17:00): Beta Monitoring & Support

#### 13:00 - 17:00: Continuous Monitoring (4 hours)
**Every 2 Hours** (13:00, 15:00, 17:00):
1. Check error logs
2. Review performance metrics
3. Collect user feedback
4. Triage any issues

**Metrics to Track**:
- Active users testing beta: [N]
- Error rate: [%] (Target: <1%)
- Average page load time: [seconds] (Target: <3s)
- User feedback count: [N]

**Issue Response**:
- **Critical Bug**: Fix immediately, hotfix deploy within 2 hours
- **Major Bug**: Document, fix before Day 5 full release
- **Minor Bug**: Document, fix post-cutover

### End of Day 4
**Output**: Beta Day 1 Summary Report
**Metrics**:
- Users engaged: [N]
- Feedback collected: [N] responses
- Issues found: [N critical], [N major], [N minor]
- Performance: ACCEPTABLE / NEEDS OPTIMIZATION

**Day 4 Go/No-Go for Full Release (Day 5)** ⭐:
- [ ] Zero unresolved critical issues
- [ ] User feedback positive (≥80% satisfaction)
- [ ] Performance acceptable
- [ ] Error rate <1%
- **Decision**: PROCEED to Full Release / EXTEND BETA / ROLLBACK

**Status**: BETA STABLE / ISSUES DETECTED / ROLLBACK NEEDED

---

## Day 5: Full Production Release

**Date**: Week 7 Day 5
**Duration**: 8 hours
**Lead**: Product Manager
**Critical**: MODERATE
**Final Rollback Point**: End of Day 5

### Morning (08:00 - 12:00): Full Release

#### 08:00 - 08:15: Daily Standup + Final Go/No-Go

#### 08:15 - 09:00: Remove Beta Label & Deploy (45 min)
- Update UI to remove "BETA" designation
- Deploy to all users
- Smoke test post-deployment

#### 09:00 - 10:00: Send Full Release Announcement (1 hour)
**Email to All Stakeholders**:
```
Subject: Precision Marketing System Upgrade Complete

We're pleased to announce the completion of our precision marketing system upgrade.

New Features:
• R116: Real-world impact tracking via track_multiplier
• R117: Data transparency indicators (REAL/FILLED/SYNTHETIC)
• R118: Statistical significance markers (***/**/*)

All features are now available to all users.

User Guide: [Link]
Support: [Contact]

Thank you for your patience during this upgrade.
```

#### 10:00 - 12:00: Initial Monitoring (2 hours)
- Monitor error logs
- Track user engagement
- Respond to user questions

### Afternoon (13:00 - 17:00): Validation & Success Metrics

#### 13:00 - 14:00: Mid-Day Validation Run (1 hour)
```bash
Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R
```
- Expected: PASS (all 6 checks)
- Document: No regressions detected

#### 14:00 - 15:00: Performance Review (1 hour)
- Check query response times
- Review database sizes
- Verify no memory leaks
- Assess system stability

#### 15:00 - 16:00: User Engagement Analysis (1 hour)
- Active users count
- Feature adoption rate
- Feedback sentiment analysis
- Issue summary

#### 16:00 - 17:00: Success Metrics Report (1 hour)
**Generate Day 5 Report**:
- Total users reached: [N]
- Active engagement: [%]
- Error rate: [%] (Target: <1%)
- Performance metrics: ACCEPTABLE / NEEDS OPTIMIZATION
- User satisfaction: [%] (Target: ≥80%)

**Cutover Status Decision** ⭐:
- [ ] All critical criteria met
- [ ] System stable for 8+ hours
- [ ] No major issues detected
- [ ] User feedback positive
- **Status**: CUTOVER SUCCESSFUL ✅ / ROLLBACK NEEDED ❌

### End of Day 5
**Output**: Week 7 Success Metrics Report
**Status**: MIGRATION COMPLETE / ROLLBACK EXECUTED
**Next**: Day 6 (Archive & Documentation) or Investigation

---

## Day 6: Legacy Archive & Documentation

**Date**: Week 7 Day 6
**Duration**: 6 hours (lighter day post-cutover)
**Lead**: Product Manager + Technical Writer
**Critical**: NO (Can extend to Week 8 if needed)

### Morning (08:00 - 12:00): D04 Legacy Archive

#### 08:00 - 08:15: Daily Standup

#### 08:15 - 10:00: Execute Archive Plan (1.75 hours)
```bash
# Create archive structure
mkdir -p scripts/update_scripts/archive/legacy_D04_precision_marketing/{scripts,documentation,analysis}

# Copy D04 scripts
cp scripts/update_scripts/archive/historical_versions/update_scripts_20250929/archive/MAMBA/*D04*.R \
   scripts/update_scripts/archive/legacy_D04_precision_marketing/scripts/

# Copy documentation
cp scripts/global_scripts/00_principles/docs/en/part2_implementations/CH13_derivations/D04_poisson_marketing.qmd \
   scripts/update_scripts/archive/legacy_D04_precision_marketing/documentation/

cp scripts/global_scripts/00_principles/CHANGELOG/archive/principles_processed/20250823_193744_derivations/D04_poisson_precision_marketing/D04.md \
   scripts/update_scripts/archive/legacy_D04_precision_marketing/documentation/
```

#### 10:00 - 11:00: Create Archive Documentation (1 hour)
- Create `README_D04_LEGACY.md`
- Document: archive date, reason, retention policy
- Reference replacement system

#### 11:00 - 12:00: Update CHANGELOG (1 hour)
```bash
# Add entry to main changelog
cat >> scripts/global_scripts/00_principles/CHANGELOG.md <<EOF

## 2025-11-13: D04 Legacy Archive (Week 7 Day 6)

### Archived
- Legacy D04 precision marketing scripts (12 files)
- Status at archive: Non-functional (broken)
- Retention: 1 year (until 2026-11-13)

### Replacement
- New ETL+DRV pipeline (Week 0-7)
- Location: scripts/update_scripts/ETL/precision/
- Features: R116/R117/R118 compliance
EOF
```

### Afternoon (13:00 - 16:00): Documentation Updates

#### 13:00 - 14:30: System Documentation (1.5 hours)
- Update architecture diagrams
- Update ETL workflow documentation
- Update UI integration guide

#### 14:30 - 16:00: Operational Guides (1.5 hours)
- Document new execution procedures
- Update monitoring procedures
- Enhance troubleshooting guide

### End of Day 6
**Output**: Complete Archive Package + Updated Documentation
**Status**: ARCHIVE COMPLETE

---

## Day 7: Week 7 Wrap-Up

**Date**: Week 7 Day 7
**Duration**: 4 hours (half day)
**Lead**: Product Manager
**Critical**: NO

### Morning (08:00 - 12:00): Final Validation & Retrospective

#### 08:00 - 08:15: Daily Standup

#### 08:15 - 09:00: Final Validation Run (45 min)
```bash
Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R
```
- Status: PASS (expected)
- Report: Archive as final Week 7 validation

#### 09:00 - 10:00: Trend Analysis Review (1 hour)
- Review full 2-week parallel running (14 validation runs)
- Calculate PASS rate (Target: ≥90%, Ideal: 100%)
- Identify any trends or patterns
- Document stability confirmation

#### 10:00 - 11:30: Retrospective Meeting (1.5 hours)
**Attendees**: All Week 7 team members

**Agenda**:
1. **What Went Well** (30 min):
   - Celebrate successes
   - Identify effective strategies

2. **What Could Be Improved** (30 min):
   - Document challenges
   - Identify areas for improvement

3. **Action Items** (30 min):
   - Create improvement backlog
   - Assign owners and timelines

**Output**: Retrospective Notes Document

#### 11:30 - 12:00: Week 7 Completion Report (30 min)
**Generate Report**:
- Executive summary
- Success metrics
- Lessons learned
- Recommendations for ongoing monitoring

**Send to Stakeholders**:
- All team members
- Management
- Key stakeholders

### End of Day 7
**Output**: Week 7 Completion Report
**Status**: WEEK 7 COMPLETE ✅
**Next**: Ongoing monitoring (Week 8+)

---

## Post-Week 7: Ongoing Operations

### Week 8-10: Stabilization Period

**Daily** (First 2 weeks):
- [ ] Continue daily validation runs
- [ ] Monitor error logs
- [ ] Track performance metrics
- [ ] Respond to user questions

**Weekly** (Weeks 8-10):
- [ ] Review trend analysis
- [ ] Optimize slow queries if needed
- [ ] Enhance documentation based on user feedback
- [ ] Address minor issues from backlog

### Week 11+: Business as Usual

**Weekly Validation** (Instead of daily):
- [ ] Run validation script weekly
- [ ] Review for any regressions
- [ ] Document anomalies

**Monthly Review**:
- [ ] Performance metrics review
- [ ] User satisfaction survey
- [ ] Optimization opportunities
- [ ] Feature enhancement planning

---

## Contingency Timeline (If Rollback Needed)

### If Rollback on Day 1-2
- **Rollback Time**: <5 minutes
- **Investigation**: 1-2 days
- **Fix**: 1-3 days
- **Retry**: Restart Week 7 timeline
- **Impact**: +3-7 day delay

### If Rollback on Day 3-4
- **Rollback Time**: <5 minutes
- **Investigation**: 1 day
- **Fix**: 1-2 days
- **Retry**: Day 3-5 only (reuse Day 1-2 results)
- **Impact**: +2-4 day delay

### If Rollback on Day 5
- **Rollback Time**: <5 minutes
- **Investigation**: Immediate (same day)
- **Fix**: 1 day
- **Retry**: Day 5 only
- **Impact**: +1-2 day delay

---

## Critical Milestone Timeline

```
Week 5-6 (Complete):  Parallel running validation (14 runs, 6/6 PASS)
├─ Baseline: 2025-11-13 (First validation)
├─ Monitoring: Daily validation runs
└─ Status: GREEN ✅ (Ready for Week 7)

Week 7 (Cutover):  Sales integration → DRV activation → UI update → Cutover
├─ Day 0: Preparation (backups, team alignment, final checks)
├─ Day 1: CBZ sales ETL (0IM→1ST→2TR) [CRITICAL PATH]
├─ Day 2: DRV activation (time_series + poisson_analysis) [CRITICAL PATH]
├─ Day 3: UI integration (adapters + components + UAT) [CRITICAL PATH]
├─ Day 4: Beta release (limited production) [CRITICAL PATH]
├─ Day 5: Full release (remove beta, announce) [CRITICAL PATH]
├─ Day 6: D04 archive (legacy cleanup, documentation)
└─ Day 7: Wrap-up (final validation, retrospective, report)

Week 8+:  Stabilization and continuous improvement
├─ Week 8-10: Daily validation, issue resolution, optimization
└─ Week 11+: Weekly validation, monthly reviews, enhancements
```

**Total Project Duration**: 7 weeks (Week 0-6) + 1 week (Week 7) = **8 weeks from start to cutover**

**Project Completion**: **End of Week 7** ✅

---

**Timeline Version**: 1.0
**Created**: 2025-11-13
**Author**: principle-product-manager
**Next Review**: Day 0 (before Week 7 execution)
**Post-Week 7 Update**: Required within 3 days of completion

---

*This timeline provides hour-by-hour execution guidance for Week 7 cutover. Actual timing may vary based on data volumes and issue complexity. Built-in buffer time allows for unexpected challenges. Daily standup meetings ensure team alignment and rapid issue resolution.*
