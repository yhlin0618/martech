# Week 7 Implementation Plan: Migration & Cutover

**Project**: MAMBA Precision Marketing ETL+DRV Redesign
**Phase**: Week 7 - Sales Data Integration & System Cutover
**Date**: 2025-11-13
**Version**: 1.0
**Status**: PLANNING
**Coordinator**: principle-product-manager

---

## Executive Summary

Week 7 represents the critical migration phase where we transition the precision marketing system from the legacy D04 implementation (which was broken) to the new ETL+DRV pipeline. This plan details the sales data integration, UI component migration, and final cutover strategy.

### Current Status
- **Weeks 0-6 Complete**: 62% of total project
- **First Validation**: 6/6 PASS (100% success)
- **System Health**: GREEN - All critical systems operational
- **Blockers**: NONE - Sales data integration is next milestone

### Week 7 Objectives
1. Integrate sales data from CBZ and/or eBay sources
2. Activate placeholder DRV tables (time series + Poisson analysis)
3. Validate R116 range metadata population (>90% target)
4. Update UI components to consume new DRV outputs
5. Execute cutover from legacy D04 to new system
6. Archive legacy D04 scripts with complete documentation

---

## Part A: Sales Data Integration Strategy

### A.1 Sales Data Source Analysis

#### Investigation Findings

**Available Sales Data Sources**:

1. **CBZ (Cyberbiz) Sales ETL** ✅ READY
   - Location: `scripts/update_scripts/ETL/cbz/`
   - Files Found:
     - `cbz_ETL_sales_0IM.R` - Import from Cyberbiz API
     - `cbz_ETL_sales_1ST.R` - R116 currency standardization
     - `cbz_ETL_sales_2TR.R` - Cross-platform transformation
   - Schema: Conforms to `transformed_schemas.yaml#sales_transformed`
   - Features: Line-item level sales, complete audit trail
   - Currency: TWD → USD conversion (R116 compliant)
   - Pipeline Type: BASE_SALES (no JOIN needed, API provides line items)

2. **eBay Sales ETL** ✅ READY
   - Location: `scripts/update_scripts/ETL/eby/`
   - Files Found:
     - `eby_ETL_sales_0IM___MAMBA.R` - NOT NEEDED (DERIVED ETL per MP109)
     - `eby_ETL_sales_1ST___MAMBA.R` - NOT NEEDED (DERIVED ETL per MP109)
     - `eby_ETL_sales_2TR___MAMBA.R` - Transforms orders + order_details JOIN
   - Schema: Composite key design (order_id + seller_email)
   - Features: Derived from orders + order_details structural JOIN
   - Currency: GBP → USD conversion (R116 compliant)
   - Pipeline Type: DERIVED_SALES (JOINs orders + order_details in 2TR)

**Database Status**:
- `raw_data.duckdb`: 3.5 MB (product profiles only)
- `staged_data.duckdb`: 3.5 MB (6 product line tables)
- `transformed_data.duckdb`: 3.8 MB (6 product line tables)
- `processed_data.duckdb`: 1.0 MB (3 DRV tables, 2 in placeholder mode)

**Sales Data NOT Found In**:
- `mamba_eby_raw.duckdb` (780 KB) - Likely old structure
- `mamba_eby_staging.duckdb` (12 KB) - Empty or minimal
- No Amazon (AMZ) sales data detected (directory exists but no sales scripts)

#### Recommended Integration Approach

**PRIMARY RECOMMENDATION**: **Start with CBZ (Cyberbiz) sales data**

**Rationale**:
1. CBZ is BASE_SALES pipeline (simpler, no JOINs needed)
2. Likely higher data quality (direct API integration)
3. Domestic market (Taiwan) - more relevant for initial precision marketing
4. Simpler execution path reduces cutover risk

**SECONDARY**: Add eBay sales data (if needed for completeness)

**Rationale**:
1. DERIVED_SALES pipeline (requires orders + order_details JOIN)
2. Composite key complexity (order_id + seller_email)
3. International market (UK) - additional complexity
4. Can be added post-cutover if business requires

### A.2 Sales Data Integration Timeline

**Phase 1: CBZ Sales Integration** (Days 1-2)

**Day 1 Morning**: Execute CBZ ETL Pipeline
```bash
# Sequence: 0IM → 1ST → 2TR
Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_0IM.R
Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_1ST.R
Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_2TR.R
```

**Expected Outputs**:
- `raw_data.duckdb`: Add `raw_cbz_sales` table
- `staged_data.duckdb`: Add `df_cbz_sales___staged` table (R116 currency fields)
- `transformed_data.duckdb`: Add `df_cbz_sales___transformed` table

**Day 1 Afternoon**: Validate CBZ Sales Data
```bash
# Check table existence and row counts
R -e "library(DBI); library(duckdb);
con <- dbConnect(duckdb(), 'data/transformed_data.duckdb');
sales <- dbGetQuery(con, 'SELECT COUNT(*) as n FROM df_cbz_sales___transformed');
print(paste('CBZ Sales Records:', sales\$n));
dbDisconnect(con)"
```

**Acceptance Criteria**:
- [ ] All 3 tables created (raw, staged, transformed)
- [ ] Row count > 0 in all tables
- [ ] R116 currency fields populated (price_usd, original_price, conversion_rate)
- [ ] transaction_id is unique
- [ ] order_date range reasonable (past 12-24 months)

**Day 2 Morning**: Activate DRV Time Series
```bash
# Execute time series aggregation with REAL sales data
Rscript scripts/update_scripts/ETL/precision/precision_DRV_time_series.R
```

**Expected Changes**:
- `df_precision_time_series`: Exit placeholder mode
- `data_source`: Change from "PLACEHOLDER" to "REAL"
- `filling_method`: "none" (no gaps to fill initially)
- `data_availability`: "COMPLETE" (assuming full data)
- Row count: N rows (one per time period × product line × country)

**Day 2 Afternoon**: Activate DRV Poisson Analysis
```bash
# Execute Poisson regression with REAL sales data
Rscript scripts/update_scripts/ETL/precision/precision_DRV_poisson_analysis.R
```

**Expected Changes**:
- `df_precision_poisson_analysis`: Exit placeholder mode
- Row count: M rows (one per predictor × product line)
- R116 range metadata: Populate predictor_min, predictor_max, predictor_range
- R118 significance: Populate p_value, significance_flag
- **Target**: 90%+ predictors have complete range metadata

**Phase 2: eBay Sales Integration** (Day 3 - OPTIONAL)

**Only execute if business requires eBay data for cutover**

```bash
# eBay is DERIVED_SALES - only needs 2TR phase
# Ensure orders + order_details are in staged_data first
Rscript scripts/update_scripts/ETL/eby/eby_ETL_sales_2TR___MAMBA.R
```

**Note**: eBay integration can be deferred to Week 8 if needed to expedite cutover.

### A.3 Sales Data Validation Checklist

**Pre-Integration Checks**:
- [ ] CBZ API credentials available (if needed)
- [ ] Network connectivity to data sources verified
- [ ] Database disk space available (estimate: +50-100 MB)
- [ ] Backup of current databases taken

**Post-Integration Validation**:
- [ ] **Data Quality**:
  - [ ] No NULL values in critical fields (transaction_id, order_id, product_id, quantity, unit_price)
  - [ ] line_total = quantity × unit_price (within 2 cent tolerance)
  - [ ] order_date within reasonable range (not future dates)
  - [ ] Currencies properly converted to USD (rates between 0.001-100)

- [ ] **Business Logic**:
  - [ ] Quantity > 0 for all records
  - [ ] Unit price >= 0 (free items allowed, negative not allowed)
  - [ ] Product IDs match product profile tables
  - [ ] Customer IDs valid (if available)

- [ ] **Schema Compliance**:
  - [ ] All required fields per `transformed_schemas.yaml` present
  - [ ] platform_id = "cbz" for all CBZ records
  - [ ] transformation_timestamp populated
  - [ ] etl_pipeline = "BASE_SALES" for CBZ

- [ ] **R116 Currency Standardization**:
  - [ ] price_usd populated for all records
  - [ ] original_price matches raw data
  - [ ] original_currency = "TWD" for CBZ
  - [ ] conversion_rate reasonable (TWD/USD ≈ 0.031-0.033)
  - [ ] conversion_date = staging execution date
  - [ ] conversion_source = "FIXED" (or ECB/FRED if API integrated)

**DRV Activation Validation**:
- [ ] **Time Series Activation**:
  - [ ] Row count > 0
  - [ ] data_source changed from "PLACEHOLDER" to "REAL"
  - [ ] Time periods cover reasonable range
  - [ ] No missing product lines

- [ ] **Poisson Analysis Activation**:
  - [ ] Row count > 0 (expect 20-50 predictors × 6 product lines = 120-300 rows)
  - [ ] All product lines represented
  - [ ] R116 metadata: 90%+ predictors have non-NULL range values
  - [ ] R118 significance: All rows have p_value and significance_flag
  - [ ] Coefficients reasonable (-10 to +10 typical range)

---

## Part B: UI Component Migration Plan

### B.1 UI Component Dependency Analysis

**Investigation Findings**:

**UI Components Examined**:
1. Poisson-related components: `scripts/global_scripts/10_rshinyapp_components/poisson/`
   - `poissonFeatureAnalysis/` - Attribute importance analysis
   - `poissonCommentAnalysis/` - Review text analysis
   - `poissonTimeAnalysis/` - Time series trends

2. Position-related components: `scripts/global_scripts/10_rshinyapp_components/position/`
   - `positionMSPlotly/` - Market share visualizations
   - `positionStrategy/` - Strategic positioning
   - `positionTable/` - Position data tables
   - `positionDNAPlotly/` - Customer DNA plots
   - `positionKFE/` - Key factor evaluation
   - `positionIdealRate/` - Ideal point analysis

**Key Finding**: NO DIRECT REFERENCES TO D04 OR LEGACY PRECISION MARKETING FOUND

**Implication**: UI components likely:
1. Are database-agnostic (use generic data access patterns like `tbl2()`)
2. Were never properly integrated with D04 (since D04 was broken)
3. Will require NEW integration with DRV outputs (not migration)

**Current Data Access Pattern**:
- Components use `tbl2()` function (following R116 universal data access)
- Data likely passed from parent app, not directly queried
- Components are reactive to input data, not hard-coded to specific tables

### B.2 UI Component Integration Strategy

**Approach**: **Soft Integration** (Phased, Low-Risk)

**Phase 1**: Data Plumbing (Week 7, Days 3-4)
- Create adapter functions that transform DRV outputs to UI component expected formats
- Test adapters with placeholder data first
- Document expected data contracts

**Phase 2**: Component Updates (Week 7, Days 4-5)
- Update Poisson components to consume `df_precision_poisson_analysis`
- Update Time components to consume `df_precision_time_series`
- Add R117 transparency indicators to UI (show data_source status)
- Add R118 significance markers (display significance_flag)

**Phase 3**: End-to-End Testing (Week 7, Day 5)
- Test each component with real DRV data
- Verify visualizations render correctly
- Validate user interactions work as expected

### B.3 Component Integration Details

#### Priority 1: Poisson Components (CRITICAL)

**poissonFeatureAnalysis**:
- **Current State**: Reads Poisson regression results from some source
- **Required Change**: Connect to `df_precision_poisson_analysis`
- **Data Mapping**:
  ```R
  # Adapter function
  get_poisson_features <- function(con, product_line) {
    tbl2(con, "df_precision_poisson_analysis") %>%
      filter(product_line == !!product_line,
             is_significant == TRUE) %>%  # Filter to significant only
      select(predictor, coefficient, p_value,
             significance_flag, track_multiplier) %>%  # R116 innovation!
      arrange(desc(abs(coefficient))) %>%
      collect()
  }
  ```
- **New Features to Enable**:
  - Display `track_multiplier` to show "real-world impact"
  - Show `significance_flag` visually (***/**/*/)
  - Filter by significance threshold
- **Testing**: Verify calculations match statistical expectations

**poissonTimeAnalysis**:
- **Current State**: Likely shows time series trends
- **Required Change**: Connect to `df_precision_time_series`
- **Data Mapping**:
  ```R
  get_time_series <- function(con, product_line, start_date, end_date) {
    tbl2(con, "df_precision_time_series") %>%
      filter(product_line == !!product_line,
             date >= !!start_date,
             date <= !!end_date) %>%
      select(date, total_sales, total_orders, avg_order_value,
             data_source, filling_method, data_availability) %>%  # R117
      arrange(date) %>%
      collect()
  }
  ```
- **New Features to Enable**:
  - Display R117 transparency markers (color code by data_source)
  - Show filling_method tooltips when data is imputed
  - Warn if data_availability != "COMPLETE"
- **Testing**: Verify time series continuity and trend calculations

#### Priority 2: Position Components (MODERATE)

**Position components likely need feature aggregation data**:
- Connect to `df_precision_features` for attribute prevalence
- Use aggregated metrics for market positioning visualizations

**Example Integration**:
```R
get_feature_prevalence <- function(con, product_lines) {
  tbl2(con, "df_precision_features") %>%
    filter(product_line %in% !!product_lines) %>%
    collect()
}
```

#### Priority 3: Visualization Enhancements (NICE-TO-HAVE)

**Add principle compliance indicators**:
- R116 badge: Show when track_multiplier is available
- R117 indicator: Traffic light for data quality (green=REAL, yellow=FILLED, red=SYNTHETIC)
- R118 stars: Visual significance markers (***/**/*/)

### B.4 UI Component Testing Plan

**Unit Testing** (Per Component):
```R
# Test script template: test_component_drv_integration.R
library(testthat)

test_that("Component renders with DRV data", {
  # Setup: Create test database with sample DRV data
  con_test <- create_test_drv_database()

  # Execute: Render component
  result <- render_component(con_test, product_line = "test_line")

  # Verify: Output matches expectations
  expect_true(nrow(result) > 0)
  expect_true(all(c("predictor", "coefficient") %in% names(result)))

  # Cleanup
  dbDisconnect(con_test)
})
```

**Integration Testing** (Across Components):
```R
# Test data flow from DRV → Adapter → Component → UI
test_that("End-to-end DRV to UI flow works", {
  # Use real processed_data.duckdb
  con_real <- dbConnect(duckdb(), "data/processed_data.duckdb")

  # Test each component with real data
  poisson_data <- get_poisson_features(con_real, "milk_frother")
  expect_true(nrow(poisson_data) > 0)

  time_data <- get_time_series(con_real, "milk_frother",
                                as.Date("2024-01-01"), as.Date("2024-12-31"))
  expect_true(nrow(time_data) > 0)

  dbDisconnect(con_real)
})
```

**User Acceptance Testing** (Manual):
- Load dashboard with real DRV data
- Navigate to each precision marketing section
- Verify data displays correctly
- Test filtering, sorting, visualization interactions
- Confirm R117 transparency indicators visible
- Validate R118 significance markers display

---

## Part C: Dashboard Cutover Strategy

### C.1 Cutover Approach: PHASED ROLLOUT

**Rationale**:
- Minimizes risk compared to "big bang" approach
- Allows rollback at component level if issues detected
- Enables user feedback before full cutover
- Aligns with MP029 (no fake data) and production safety principles

**NOT Recommended**: Feature flags (too complex for this scenario)

### C.2 Phased Rollout Plan

**Phase 0: Pre-Cutover Validation** (Day 1-2, parallel with sales integration)
```bash
# Continue daily validation runs
./scripts/global_scripts/98_test/monitor_parallel_runs.sh

# Expected: 12-14 successful runs by cutover day
# Target: 90%+ PASS rate maintained
```

**Phase 1: Backend Data Cutover** (Day 3 Morning)
- Sales data integration complete
- DRV tables activated (time series + Poisson)
- Validation passes with real data
- **Rollback Trigger**: Any validation FAIL status
- **Rollback Action**: Revert to placeholder mode, investigate

**Phase 2: Internal Testing** (Day 3 Afternoon)
- Deploy updated UI components to test environment
- Internal team validates functionality
- Document any issues found
- **Rollback Trigger**: Critical functionality broken
- **Rollback Action**: Revert UI components, keep backend active

**Phase 3: Limited Production Release** (Day 4)
- Deploy to production with "beta" label
- Monitor for errors and performance issues
- Collect user feedback
- **Rollback Trigger**: User-facing errors or performance degradation
- **Rollback Action**: Feature flag OFF (if implemented) or full rollback

**Phase 4: Full Production Release** (Day 5)
- Remove "beta" label
- Announce to all users
- Monitor for 48 hours
- **Rollback Trigger**: Widespread issues or data quality concerns
- **Rollback Action**: Execute full rollback script

### C.3 Rollback Procedures

**Quick Rollback** (Component Level):
```bash
# Revert specific UI component to previous version
git checkout <commit-before-drv-integration> -- \
  scripts/global_scripts/10_rshinyapp_components/poisson/poissonFeatureAnalysis/

# Redeploy application
```

**Full Rollback** (System Level):
```bash
# Execute comprehensive rollback
./scripts/global_scripts/98_test/rollback_to_legacy.sh --check  # Dry run
./scripts/global_scripts/98_test/rollback_to_legacy.sh --execute  # Actual rollback
```

**Important Rollback Notes**:
- Legacy D04 was BROKEN - rollback will DISABLE precision marketing features
- Rollback should only be used if new system has critical issues
- Preferred approach: Fix forward rather than rollback

### C.4 User Acceptance Testing Plan

**Pre-Cutover UAT** (Internal, Day 3):
- Test users: 2-3 internal analysts
- Duration: 4 hours
- Focus: Core workflows, data accuracy, UI usability
- Acceptance criteria: No critical issues, <3 minor issues

**Scenarios to Test**:
1. **Poisson Feature Analysis**:
   - Select product line
   - View attribute importance rankings
   - Verify track_multiplier values make sense
   - Check significance flags display correctly

2. **Time Series Analysis**:
   - Select date range
   - View sales trends
   - Verify R117 transparency indicators
   - Test data export functionality

3. **Market Positioning**:
   - View feature prevalence heatmap
   - Compare across product lines
   - Verify aggregation calculations

**Post-Cutover Monitoring** (Days 4-7):
- Monitor error logs for exceptions
- Track user engagement metrics
- Collect feedback via in-app survey
- Review performance metrics (page load times)

### C.5 Communication Plan

**Pre-Cutover** (Day 2):
- **Audience**: All dashboard users
- **Message**: "Precision marketing upgrade scheduled for [Day 3]"
- **Channel**: Email + in-app notification
- **Content**: Brief description of enhancements (R116/R117/R118 benefits)

**During Cutover** (Day 3-4):
- **Audience**: Active users
- **Message**: "New precision marketing features now available (beta)"
- **Channel**: In-app banner
- **Content**: Link to quick start guide, feedback form

**Post-Cutover** (Day 5):
- **Audience**: All stakeholders
- **Message**: "Precision marketing system upgrade complete"
- **Channel**: Email summary report
- **Content**: Success metrics, new capabilities, support contacts

---

## Part D: Legacy D04 Archive Plan

### D.1 Legacy D04 Status Assessment

**Current State**:
- **Functional Status**: BROKEN (non-operational)
- **Last Modified**: Archive dated 2025-09-29
- **Location**: `scripts/update_scripts/archive/historical_versions/update_scripts_20250929/archive/MAMBA/`
- **Files Count**: 12 D04 scripts found

**Found D04 Files**:
1. `cbz_D04_01.R` through `cbz_D04_09.R` (9 files)
2. `eby_D04_09_quick.R` (1 file)
3. `all_D04_00.R`, `all_D04_04.R`, `all_D04_05.R` (3 files)

**Documentation**:
- Principle definition: `scripts/global_scripts/00_principles/docs/en/part2_implementations/CH13_derivations/D04_poisson_marketing.qmd`
- Changelog: `scripts/global_scripts/00_principles/CHANGELOG/archive/principles_processed/20250823_193744_derivations/D04_poisson_precision_marketing/D04.md`

### D.2 Archive Structure

**Recommended Archive Location**:
```
scripts/update_scripts/archive/
└── legacy_D04_precision_marketing/
    ├── README_D04_LEGACY.md                   # This document
    ├── scripts/
    │   ├── cbz_D04_01.R                       # Original scripts (copy)
    │   ├── cbz_D04_02.R
    │   ├── ...
    │   └── eby_D04_09_quick.R
    ├── documentation/
    │   ├── D04_poisson_marketing.qmd           # Principle doc (copy)
    │   └── D04.md                               # Changelog (copy)
    └── analysis/
        └── why_D04_was_broken.md               # Root cause analysis
```

### D.3 Archive Documentation Template

**README_D04_LEGACY.md**:
```markdown
# Legacy D04 Precision Marketing Archive

**Archive Date**: 2025-11-13
**Reason for Archive**: Replaced by ETL+DRV pipeline (Week 0-7)
**Functional Status at Archive**: BROKEN (non-operational)

## What Was D04?

D04 (Derivation 04) was the original Poisson-based precision marketing system. It attempted to:
- Calculate attribute importance using Poisson regression
- Track time series of marketing metrics
- Provide precision marketing insights

## Why Was It Archived?

1. **Non-Functional**: System was broken and not producing valid outputs
2. **Principle Violations**: Did not comply with R116/R117/R118
3. **Architecture Limitations**: Monolithic design, no separation of concerns
4. **Data Quality Issues**: No currency standardization, no metadata tracking

## Replacement System

The new ETL+DRV pipeline provides:
- **Week 1-2**: Clean ETL with R116 currency standardization
- **Week 3-4**: DRV aggregations with R117 transparency, R118 significance
- **Week 5-6**: Parallel running validation
- **Week 7**: Production cutover

See: `scripts/update_scripts/ETL/precision/README.md`

## Retention Policy

**Keep Until**: 2026-11-13 (1 year retention)
**After**: Eligible for permanent deletion if no compliance requirements
**Contact**: Data governance team for questions

## Do Not Use

**WARNING**: These scripts are archived for historical reference only.
- DO NOT attempt to execute
- DO NOT copy code without understanding replacement system
- DO NOT rely on D04 logic for new development

For precision marketing, use: `df_precision_*` tables in `processed_data.duckdb`
```

### D.4 Archive Execution Plan

**Day 6 Tasks**:

1. **Create Archive Structure**:
```bash
mkdir -p scripts/update_scripts/archive/legacy_D04_precision_marketing/{scripts,documentation,analysis}
```

2. **Copy D04 Scripts**:
```bash
# Copy from historical archive
cp scripts/update_scripts/archive/historical_versions/update_scripts_20250929/archive/MAMBA/*D04*.R \
   scripts/update_scripts/archive/legacy_D04_precision_marketing/scripts/
```

3. **Copy Documentation**:
```bash
# Copy principle docs
cp scripts/global_scripts/00_principles/docs/en/part2_implementations/CH13_derivations/D04_poisson_marketing.qmd \
   scripts/update_scripts/archive/legacy_D04_precision_marketing/documentation/

# Copy changelog
cp scripts/global_scripts/00_principles/CHANGELOG/archive/principles_processed/20250823_193744_derivations/D04_poisson_precision_marketing/D04.md \
   scripts/update_scripts/archive/legacy_D04_precision_marketing/documentation/
```

4. **Create Archive README**:
```bash
# Use template above
vim scripts/update_scripts/archive/legacy_D04_precision_marketing/README_D04_LEGACY.md
```

5. **Document Why D04 Was Broken** (Optional but recommended):
```bash
vim scripts/update_scripts/archive/legacy_D04_precision_marketing/analysis/why_D04_was_broken.md
```

6. **Update CHANGELOG**:
```bash
echo "## 2025-11-13: D04 Legacy Archive" >> scripts/global_scripts/00_principles/CHANGELOG.md
echo "- Archived legacy D04 precision marketing scripts (non-functional)" >> scripts/global_scripts/00_principles/CHANGELOG.md
echo "- Replaced by ETL+DRV pipeline with R116/R117/R118 compliance" >> scripts/global_scripts/00_principles/CHANGELOG.md
echo "- Retention: 1 year (until 2026-11-13)" >> scripts/global_scripts/00_principles/CHANGELOG.md
```

### D.5 Verification Checklist

After archive execution:
- [ ] All D04 scripts copied to archive location
- [ ] Documentation copied and accessible
- [ ] README_D04_LEGACY.md created
- [ ] CHANGELOG updated
- [ ] Archive location added to `.gitignore` (if contains sensitive data)
- [ ] Team notified of archive location
- [ ] No active references to D04 in production code

---

## Success Criteria

### Week 7 Completion Criteria

**Sales Data Integration**:
- [ ] CBZ sales ETL executed successfully (0IM → 1ST → 2TR)
- [ ] Sales data validated (row count > 0, schema correct, R116 compliant)
- [ ] DRV time series activated (exited placeholder mode)
- [ ] DRV Poisson analysis activated (exited placeholder mode)
- [ ] R116 range metadata > 90% populated

**UI Component Migration**:
- [ ] Poisson components updated to use DRV data
- [ ] Time series components updated to use DRV data
- [ ] R117 transparency indicators visible in UI
- [ ] R118 significance markers displaying correctly
- [ ] End-to-end testing passed

**Cutover Execution**:
- [ ] Phased rollout completed without major issues
- [ ] User acceptance testing passed
- [ ] Performance metrics acceptable
- [ ] No critical bugs in production
- [ ] Rollback procedures tested (dry run minimum)

**Legacy Archive**:
- [ ] D04 scripts archived with documentation
- [ ] Archive README created
- [ ] CHANGELOG updated
- [ ] Team notified

**Validation Metrics**:
- [ ] 14+ successful validation runs completed (2 weeks)
- [ ] 90%+ PASS rate maintained
- [ ] Trend analysis shows stability
- [ ] No regression detected

### Key Performance Indicators (Week 7)

| Metric | Target | Measurement Method |
|--------|--------|--------------------|
| Sales Data Integration Time | < 4 hours | Execution timestamps |
| DRV Activation Success Rate | 100% (2/2 tables) | Table row count > 0 |
| R116 Metadata Population | > 90% | Non-NULL count in predictor_range |
| UI Component Migration | 100% (all critical components) | Manual verification |
| User Acceptance Test Pass Rate | > 95% | UAT checklist completion |
| Production Uptime During Cutover | > 99% | Monitoring logs |
| Rollback Execution Time (if needed) | < 5 minutes | Dry run timing |

---

## Risks and Dependencies

### Critical Dependencies

1. **Sales Data Availability**: CBZ sales data must be accessible
   - **Mitigation**: Verify data source connectivity before starting
   - **Contingency**: Use sample data to test pipeline, defer cutover if needed

2. **Database Resources**: Sufficient disk space for sales data integration
   - **Mitigation**: Check available space (need ~100 MB buffer)
   - **Contingency**: Archive old data if space limited

3. **UI Development Resources**: Developer availability for component updates
   - **Mitigation**: Schedule developers in advance
   - **Contingency**: Prioritize critical components, defer nice-to-haves

### Risk Assessment

**High Risk**:
- Sales data integration fails → MITIGATION: Pre-validate data source, test scripts
- DRV tables don't populate → MITIGATION: Comprehensive validation script
- UI components break → MITIGATION: Phased rollout, component-level rollback

**Medium Risk**:
- R116 metadata population < 90% → MITIGATION: Review predictor detection logic
- User confusion with new features → MITIGATION: Clear communication, documentation
- Performance degradation → MITIGATION: Monitor metrics, optimize queries

**Low Risk**:
- Archive documentation incomplete → MITIGATION: Use template, peer review
- Validation monitoring gaps → MITIGATION: Daily automation already in place

---

## Resource Requirements

### Personnel

- **Data Engineer** (2-3 days): Sales data integration, DRV activation
- **Backend Developer** (1-2 days): Adapter functions, data plumbing
- **UI Developer** (2-3 days): Component updates, testing
- **QA Analyst** (2 days): UAT execution, validation testing
- **Product Manager** (1 day): Stakeholder coordination, communication

### Infrastructure

- **Database Storage**: +100 MB for sales data
- **Test Environment**: Dedicated environment for UAT
- **Backup Storage**: Full database backup before cutover
- **Monitoring Tools**: Error tracking, performance monitoring

### Timeline

- **Total Duration**: 7 days (Week 7)
- **Critical Path**: Sales integration → DRV activation → UI updates → Cutover
- **Buffer**: Built-in 1 day for unexpected issues

---

## Next Steps

### Immediate Actions (Before Week 7 Starts)

1. **Pre-Flight Checklist**:
   - [ ] Verify CBZ sales data source accessibility
   - [ ] Confirm developer availability
   - [ ] Schedule UAT participants
   - [ ] Prepare communication templates
   - [ ] Review rollback procedures

2. **Environment Preparation**:
   - [ ] Backup all databases
   - [ ] Allocate disk space
   - [ ] Set up test environment
   - [ ] Configure monitoring alerts

3. **Stakeholder Alignment**:
   - [ ] Review implementation plan with team
   - [ ] Confirm cutover timeline acceptable
   - [ ] Identify decision makers for go/no-go
   - [ ] Set up daily standup for Week 7

### Daily Execution Checklist

**Day 1**: Sales Data Integration (CBZ)
- [ ] Morning: Execute 0IM, 1ST, 2TR scripts
- [ ] Afternoon: Validate sales data quality
- [ ] End of day: Report status, prepare for DRV activation

**Day 2**: DRV Activation
- [ ] Morning: Activate time series
- [ ] Afternoon: Activate Poisson analysis
- [ ] End of day: Validate R116/R117/R118 compliance

**Day 3**: UI Component Integration
- [ ] Morning: Update Poisson components
- [ ] Afternoon: Update time series components, internal UAT
- [ ] End of day: UAT report, go/no-go decision for Day 4

**Day 4**: Limited Production Release
- [ ] Morning: Deploy to production (beta)
- [ ] All day: Monitor for issues
- [ ] End of day: Collect feedback, prepare for full release

**Day 5**: Full Production Release
- [ ] Morning: Remove beta label, announce
- [ ] All day: Monitor performance
- [ ] End of day: Success metrics report

**Day 6**: Legacy Archive & Documentation
- [ ] Morning: Execute archive plan
- [ ] Afternoon: Update documentation
- [ ] End of day: Archive verification

**Day 7**: Week 7 Wrap-Up
- [ ] Morning: Final validation run
- [ ] Afternoon: Retrospective meeting
- [ ] End of day: Week 7 completion report

---

## Appendices

### Appendix A: Command Reference

**Sales Data Integration**:
```bash
# CBZ Sales ETL (recommended primary path)
Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_0IM.R
Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_1ST.R
Rscript scripts/update_scripts/ETL/cbz/cbz_ETL_sales_2TR.R

# eBay Sales ETL (optional, DERIVED pipeline)
Rscript scripts/update_scripts/ETL/eby/eby_ETL_sales_2TR___MAMBA.R
```

**DRV Activation**:
```bash
# Time Series Aggregation
Rscript scripts/update_scripts/ETL/precision/precision_DRV_time_series.R

# Poisson Analysis
Rscript scripts/update_scripts/ETL/precision/precision_DRV_poisson_analysis.R
```

**Validation**:
```bash
# Daily validation
Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R

# Monitoring automation
./scripts/global_scripts/98_test/monitor_parallel_runs.sh
```

**Rollback** (if needed):
```bash
# Dry run
./scripts/global_scripts/98_test/rollback_to_legacy.sh --check

# Execute (with confirmation)
./scripts/global_scripts/98_test/rollback_to_legacy.sh --execute
```

### Appendix B: File Locations

**ETL Scripts**:
- CBZ Sales: `scripts/update_scripts/ETL/cbz/cbz_ETL_sales_*.R`
- eBay Sales: `scripts/update_scripts/ETL/eby/eby_ETL_sales_2TR___MAMBA.R`
- DRV Scripts: `scripts/update_scripts/ETL/precision/precision_DRV_*.R`

**UI Components**:
- Poisson: `scripts/global_scripts/10_rshinyapp_components/poisson/`
- Position: `scripts/global_scripts/10_rshinyapp_components/position/`

**Databases**:
- Raw: `data/raw_data.duckdb`
- Staged: `data/staged_data.duckdb`
- Transformed: `data/transformed_data.duckdb`
- Processed: `data/processed_data.duckdb`

**Validation**:
- Scripts: `scripts/global_scripts/98_test/`
- Reports: `validation/parallel_run_*.{csv,md}`
- Monitoring: `validation/monitoring.log`

**Documentation**:
- Principles: `scripts/global_scripts/00_principles/R116.md`, `R117.md`, `R118.md`
- Schemas: `scripts/global_scripts/00_principles/docs/en/part2_implementations/CH17_database_specifications/etl_schemas/`
- Archive: `scripts/update_scripts/archive/legacy_D04_precision_marketing/`

### Appendix C: Contact Information

**Escalation Path**:
- **Technical Issues**: Data Engineering Team
- **UI Issues**: Frontend Development Team
- **Data Quality**: Analytics Team
- **Go/No-Go Decisions**: Product Manager
- **Rollback Authorization**: Technical Lead + Product Manager

**Support Channels**:
- **Slack**: #precision-marketing-migration
- **Email**: precision-marketing-team@company.com
- **Documentation**: Confluence/Wiki link
- **Issue Tracking**: Jira project MAMBA

---

**Document Version**: 1.0
**Created**: 2025-11-13
**Author**: principle-product-manager
**Status**: READY FOR REVIEW
**Next Review**: Before Week 7 Day 1 execution

---

*This implementation plan provides comprehensive guidance for Week 7 migration and cutover. Review with technical team before execution. Update as needed based on pre-flight checks and environment specifics.*
