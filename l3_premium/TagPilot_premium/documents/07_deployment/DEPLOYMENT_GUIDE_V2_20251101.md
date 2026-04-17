# Deployment Guide - TagPilot Premium V2 (Z-Score Customer Dynamics)

**Version**: 2.0
**Date**: 2025-11-01
**Status**: Ready for Deployment

---

## Overview

This guide covers deploying the updated TagPilot Premium application with z-score based customer dynamics methodology.

---

## Pre-Deployment Checklist

### Code Preparation

- [ ] All code changes committed to Git
- [ ] Configuration file in place (`config/customer_dynamics_config.R`)
- [ ] Module v2 tested locally (`module_dna_multi_premium_v2.R`)
- [ ] All utilities updated (RFM, prediction, tags)
- [ ] Terminology updated across codebase
- [ ] No syntax errors

### Testing Verification

- [ ] Integration tests passed
- [ ] UI renders correctly
- [ ] All visualizations working
- [ ] CSV exports functional
- [ ] Performance acceptable
- [ ] Edge cases handled

### Documentation

- [ ] User guide updated
- [ ] Changelog created
- [ ] API documentation (if applicable)
- [ ] Known issues documented

---

## Deployment Steps

### Step 1: Update app.R to Load V2 Module

**Current (Line 86)**:
```r
source("modules/module_dna_multi_premium.R")  # DNA 分析模組 Premium with IPT T-Series Insight
```

**Change To**:
```r
source("modules/module_dna_multi_premium_v2.R")  # DNA 分析模組 Premium V2 with Z-Score Customer Dynamics
```

**Verification**:
```r
# Check the line exists
grep -n "module_dna_multi_premium" app.R
```

---

### Step 2: Verify All Required Files Exist

Run this checklist:

```bash
# Core files
ls modules/module_dna_multi_premium_v2.R
ls config/customer_dynamics_config.R
ls utils/analyze_customer_dynamics_new.R
ls utils/calculate_customer_tags.R

# Supporting files
ls modules/module_customer_status.R
ls modules/module_customer_base_value.R
ls modules/module_lifecycle_prediction.R

# Documentation
ls documents/01_planning/revision_plans/FINAL_IMPLEMENTATION_SUMMARY_20251101.md
ls documents/04_testing/INTEGRATION_TESTING_PLAN_20251101.md
ls documents/07_deployment/DEPLOYMENT_GUIDE_V2_20251101.md
```

**Expected**: All files exist

---

### Step 3: Update Configuration (Optional)

If you need to adjust z-score parameters before deployment:

**Edit**: `config/customer_dynamics_config.R`

**Key Parameters to Review**:
```r
CUSTOMER_DYNAMICS_CONFIG <- list(
  method = "auto",  # "z_score", "fixed_threshold", or "auto"

  zscore = list(
    k = 2.5,                      # Tolerance multiplier
    active_threshold = 0.5,       # z >= 0.5 → active
    sleepy_threshold = -1.0,      # z >= -1.0 → sleepy
    half_sleepy_threshold = -1.5  # z >= -1.5 → half_sleepy
  ),

  # ...
)
```

**Default Values**: Tested and recommended, change only if needed

---

### Step 4: Backup Current Version

Before deploying, backup the current working version:

```bash
# Create backup directory
mkdir -p backups/pre_v2_deployment

# Backup key files
cp app.R backups/pre_v2_deployment/
cp modules/module_dna_multi_premium.R backups/pre_v2_deployment/
cp utils/calculate_customer_tags.R backups/pre_v2_deployment/

# Tag in git
git tag -a v1.0-pre-zscore -m "Backup before z-score deployment"
git push origin v1.0-pre-zscore
```

---

### Step 5: Deploy to Production

#### Option A: Local Deployment (Development/Testing)

```r
# Open RStudio
# Set working directory to project root
setwd("/path/to/TagPilot_premium")

# Run app
shiny::runApp()

# Or with specific host/port
shiny::runApp(host = "0.0.0.0", port = 8080)
```

---

#### Option B: Posit Connect Cloud

1. **Update rsconnect configuration** (if needed):
```r
library(rsconnect)
rsconnect::setAccountInfo(
  name = 'your-account',
  token = 'your-token',
  secret = 'your-secret'
)
```

2. **Deploy**:
```r
rsconnect::deployApp(
  appDir = ".",
  appName = "TagPilot_Premium_V2",
  forceUpdate = TRUE,
  launch.browser = FALSE
)
```

3. **Set environment variables** in Posit Connect UI:
   - `PGHOST`
   - `PGPORT`
   - `PGUSER`
   - `PGPASSWORD`
   - `PGDATABASE`
   - `OPENAI_API_KEY`

4. **Test deployed app**:
   - Navigate to app URL
   - Upload test data
   - Verify all modules work

---

#### Option C: ShinyApps.io

1. **Deploy**:
```r
library(rsconnect)
rsconnect::deployApp(
  appDir = ".",
  appName = "TagPilot-Premium-V2"
)
```

2. **Configure settings** in ShinyApps.io dashboard

---

### Step 6: Post-Deployment Verification

Run these checks after deployment:

#### 6.1: App Loads
- [ ] App URL accessible
- [ ] No startup errors in logs
- [ ] Login works (if enabled)

#### 6.2: Module 1 (DNA Multi V2)
- [ ] Upload test CSV
- [ ] Analysis completes
- [ ] Customer dynamics dropdown appears
- [ ] Grid visualization displays
- [ ] Newbie special handling works
- [ ] Strategies show correctly

#### 6.3: Module 2 (Customer Status)
- [ ] Metrics display (high risk, active, dormant)
- [ ] Pie chart shows customer dynamics
- [ ] Chinese labels correct (新客/活躍/輕度睡眠/半睡眠/沉睡)
- [ ] Heatmap renders
- [ ] Detail table shows `客戶動態` column
- [ ] CSV export contains `tag_017_customer_dynamics`

#### 6.4: Module 3 (Customer Base Value)
- [ ] AOV analysis works
- [ ] Filters by customer dynamics
- [ ] Calculations correct

#### 6.5: Performance
- [ ] Analysis completes in < 5 seconds (1K customers)
- [ ] No memory issues
- [ ] UI responsive

---

### Step 7: Monitor and Log

After deployment, monitor for:

1. **Error Logs**:
   - Check app logs for errors
   - Monitor console for warnings
   - Track user-reported issues

2. **Performance Metrics**:
   - Analysis completion time
   - Memory usage
   - Concurrent users

3. **User Feedback**:
   - Are z-scores understood?
   - Do strategies make sense?
   - Any confusion with terminology?

---

## Rollback Plan

If critical issues arise:

### Quick Rollback (app.R only)

**Step 1**: Revert app.R to load v1 module:
```r
# Change line 86 back to:
source("modules/module_dna_multi_premium.R")  # Revert to V1
```

**Step 2**: Restart app

**Time**: < 5 minutes

---

### Full Rollback (All Changes)

**Step 1**: Restore from backup:
```bash
cp backups/pre_v2_deployment/app.R app.R
cp backups/pre_v2_deployment/module_dna_multi_premium.R modules/
cp backups/pre_v2_deployment/calculate_customer_tags.R utils/
```

**Step 2**: Or use Git:
```bash
git revert HEAD~3  # Adjust number as needed
# Or
git checkout v1.0-pre-zscore
```

**Step 3**: Redeploy

**Time**: < 15 minutes

---

## Configuration Management

### Environment-Specific Configurations

For different environments (dev/staging/prod), you can use environment variables:

```r
# In customer_dynamics_config.R
method <- Sys.getenv("CUSTOMER_DYNAMICS_METHOD", default = "auto")

CUSTOMER_DYNAMICS_CONFIG <- list(
  method = method,
  # ...
)
```

**Set in environment**:
```bash
# Development
export CUSTOMER_DYNAMICS_METHOD="z_score"

# Production (if data insufficient)
export CUSTOMER_DYNAMICS_METHOD="fixed_threshold"
```

---

### A/B Testing (Optional)

To run both versions simultaneously:

1. **Deploy V1** to: `tagpilot-premium-v1`
2. **Deploy V2** to: `tagpilot-premium-v2`
3. **Compare**:
   - User adoption
   - Classification accuracy
   - Performance
4. **Choose winner** after 1-2 weeks

---

## User Training

### Key Points to Communicate

1. **New Terminology**:
   - "客戶動態" (Customer Dynamics) instead of "生命週期階段"
   - Same Chinese labels, different underlying methodology

2. **Z-Score Method**:
   - Automatically adapts to your industry
   - More accurate than fixed thresholds
   - Uses statistical patterns

3. **What Changed**:
   - Grid visualization enhanced
   - More strategies (45 total)
   - Newbies handled specially
   - RFM scores for all customers

4. **What Stayed the Same**:
   - Same user interface
   - Same export format (with updated column name)
   - Same workflow

### Training Materials

Create these materials (optional):

- [ ] Quick start guide (1-page)
- [ ] Video walkthrough (5-10 min)
- [ ] FAQ document
- [ ] Comparison chart (v1 vs v2)

---

## Troubleshooting

### Common Issues

#### Issue 1: "customer_dynamics field not found"

**Cause**: Old module still loaded

**Fix**:
```r
# Check app.R line 86
# Should be: source("modules/module_dna_multi_premium_v2.R")
```

---

#### Issue 2: Grid doesn't display

**Cause**: JavaScript not loading

**Fix**:
1. Clear browser cache
2. Hard reload (Cmd+Shift+R)
3. Check console for errors

---

#### Issue 3: All customers classified as newbie

**Cause**: Insufficient data for z-score

**Fix**:
1. Check data validation
2. May need more customers (>100) or longer time period (>1 year)
3. Use fixed threshold method temporarily

---

#### Issue 4: Performance slow (> 30 seconds)

**Cause**: Large dataset or inefficient computation

**Fix**:
1. Check customer count
2. Review logs for bottlenecks
3. Consider batch processing for >10K customers

---

## Success Metrics

Track these metrics post-deployment:

### Technical Metrics

- [ ] Uptime: > 99%
- [ ] Analysis time: < 5s for 1K customers
- [ ] Error rate: < 1%
- [ ] Memory usage: < 500 MB

### Business Metrics

- [ ] User adoption: % using v2 module
- [ ] Data quality: % datasets passing validation
- [ ] Classification distribution: Reasonable spread across 5 dynamics
- [ ] User satisfaction: Survey results

---

## Maintenance Schedule

### Weekly

- [ ] Review error logs
- [ ] Check performance metrics
- [ ] Monitor user feedback

### Monthly

- [ ] Review configuration settings
- [ ] Analyze classification accuracy
- [ ] Update documentation as needed

### Quarterly

- [ ] Evaluate need for threshold adjustments
- [ ] Review new feature requests
- [ ] Plan enhancements

---

## Contact and Support

### Development Team

- **Primary Contact**: [Your Name]
- **Email**: [Your Email]
- **Response Time**: 24-48 hours

### Issue Reporting

**For bugs**:
1. Create GitHub issue with:
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots
   - Data sample (if possible)

**For questions**:
1. Check FAQ first
2. Email support
3. Schedule call if needed

---

## Changelog

### Version 2.0 (2025-11-01)

**Major Changes**:
- ✅ Z-score based customer dynamics classification
- ✅ 9-grid matrix with 45 strategies
- ✅ RFM scoring for all customers (no ni >= 4 filter)
- ✅ Remaining time prediction algorithm
- ✅ Centralized configuration system
- ✅ Terminology updated: lifecycle_stage → customer_dynamics

**Files Modified**:
- `modules/module_dna_multi_premium_v2.R` (new)
- `config/customer_dynamics_config.R` (new)
- `utils/calculate_customer_tags.R` (updated)
- `utils/analyze_customer_dynamics_new.R` (new)
- `modules/module_customer_status.R` (updated)
- `modules/module_customer_base_value.R` (updated)
- `modules/module_advanced_analytics.R` (updated)

**Backward Compatibility**: ✅ Yes
- Chinese labels unchanged
- V1 module still available
- Easy rollback

---

## Appendix

### A. File Structure
```
TagPilot_premium/
├── app.R                                    # Main app (update line 86)
├── config/
│   └── customer_dynamics_config.R           # New configuration
├── modules/
│   ├── module_dna_multi_premium.R           # V1 (keep for rollback)
│   ├── module_dna_multi_premium_v2.R        # V2 (new)
│   ├── module_customer_status.R             # Updated
│   ├── module_customer_base_value.R         # Updated
│   └── module_advanced_analytics.R          # Updated
├── utils/
│   ├── analyze_customer_dynamics_new.R      # New z-score function
│   └── calculate_customer_tags.R            # Updated
└── documents/
    ├── 01_planning/revision_plans/
    ├── 04_testing/
    └── 07_deployment/
        └── DEPLOYMENT_GUIDE_V2_20251101.md  # This file
```

### B. Configuration Reference

See [config/customer_dynamics_config.R](../../config/customer_dynamics_config.R) for:
- Z-score parameters
- Activity/value thresholds
- Validation requirements
- Helper functions

### C. Testing Reference

See [INTEGRATION_TESTING_PLAN_20251101.md](../04_testing/INTEGRATION_TESTING_PLAN_20251101.md) for:
- Complete test checklist
- Test execution steps
- Bug tracking template

---

**Document Status**: ✅ Ready
**Last Updated**: 2025-11-01
**Version**: 2.0
**Maintained By**: Development Team
