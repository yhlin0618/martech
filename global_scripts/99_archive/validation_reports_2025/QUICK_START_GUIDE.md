# Week 5-6 Parallel Running: Quick Start Guide

**Last Updated**: 2025-11-13

---

## TL;DR - What You Need to Know

Week 5-6 parallel running infrastructure is **COMPLETE and OPERATIONAL**. First validation run: **6/6 PASS**.

**Your action**: Run daily validation for 2 weeks, then proceed to Week 7 cutover.

---

## Daily Validation (Required)

### Option 1: Manual Execution (Recommended for Week 1)

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA

# Run validation
Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R

# Check results
cat validation/parallel_run_$(date +%Y-%m-%d).csv
open validation/parallel_run_report_$(date +%Y-%m-%d).md
```

**Expected output**: "✓ VALIDATION PASSED" with 6 PASS checks

### Option 2: Automated Daily Execution

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA

# Enable daily automation at 09:00
./scripts/global_scripts/98_test/monitor_parallel_runs.sh --daily

# Check automation status
./scripts/global_scripts/98_test/monitor_parallel_runs.sh --status
```

**Logs location**: `validation/monitoring.log`

---

## Monitoring and Reporting

### Check Latest Validation Status

```bash
# Quick status check
./scripts/global_scripts/98_test/monitor_parallel_runs.sh --status

# View latest report
open validation/parallel_run_report_$(ls -t validation/parallel_run_report_*.md | head -n 1 | xargs basename | sed 's/parallel_run_report_//' | sed 's/.md//').md
```

### Trend Analysis

```bash
# Generate trend report (run after 5+ validation runs)
./scripts/global_scripts/98_test/monitor_parallel_runs.sh

# View trend analysis
open validation/trend_analysis.md
```

---

## What to Watch For

### Green Light Indicators (Good)
✅ All checks show PASS status
✅ df_precision_features has 6+ product lines
✅ R117 and R118 compliance: PASS
✅ Database size < 50MB

### Yellow Light Indicators (Investigate)
⚠️ 1-2 WARNING statuses (review details)
⚠️ Database size growing unexpectedly
⚠️ Validation runtime > 60 seconds

### Red Light Indicators (Action Required)
🚨 Any FAIL status
🚨 3+ WARNING statuses
🚨 Validation script crashes
🚨 Missing DRV tables

**If red light**: Check logs, contact technical lead, consider rollback

---

## Emergency Rollback

### Check Rollback Readiness

```bash
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA

# Dry run (safe, no changes)
./scripts/global_scripts/98_test/rollback_to_legacy.sh --check
```

### Execute Rollback (Emergency Only)

```bash
# This will disable precision marketing features
./scripts/global_scripts/98_test/rollback_to_legacy.sh --execute
```

⚠️ **WARNING**: Legacy D04 was broken. Rollback = **DISABLE** precision marketing, not restore it.

---

## File Locations

```
MAMBA/
├── scripts/global_scripts/98_test/
│   ├── compare_legacy_vs_new.R         # Validation script
│   ├── monitor_parallel_runs.sh        # Monitoring automation
│   └── rollback_to_legacy.sh           # Emergency rollback
│
├── validation/
│   ├── parallel_run_YYYY-MM-DD.csv     # Daily validation data
│   ├── parallel_run_report_YYYY-MM-DD.md # Daily reports
│   ├── trend_analysis.md               # Trend analysis
│   ├── monitoring.log                  # Execution logs
│   ├── CUTOVER_READINESS_CHECKLIST.md  # Cutover checklist
│   └── WEEK_5_6_COMPLETION_SUMMARY.md  # Full summary
│
└── data/
    └── processed_data.duckdb           # DRV tables (validated)
```

---

## Success Criteria

After 2 weeks (10-14 validation runs), you should have:

- [ ] 10+ successful validation runs
- [ ] 90%+ PASS rate across all checks
- [ ] No FAIL status in last 5 runs
- [ ] Trend analysis shows stability
- [ ] All 3 DRV tables consistently present
- [ ] Database size stable (< 50MB)

**If all criteria met**: Proceed to Week 7 cutover preparation

---

## Common Issues and Solutions

### Issue: Validation script fails to run

```bash
# Check R is available
which Rscript

# Check working directory
pwd  # Should be in MAMBA root

# Check database exists
ls -lh data/processed_data.duckdb

# Check script has execute permissions
chmod +x scripts/global_scripts/98_test/*.sh
```

### Issue: Reports not generating

```bash
# Check validation directory exists
ls -la validation/

# Create if missing
mkdir -p validation

# Check write permissions
touch validation/test_write && rm validation/test_write
```

### Issue: Automation not running

```bash
# Check launchd status
launchctl list | grep com.mamba.parallel_running

# Reload automation
./scripts/global_scripts/98_test/monitor_parallel_runs.sh --daily

# Check logs
tail -f validation/launchd_stdout.log
```

---

## Week 7 Preparation Checklist

Use this checklist to prepare for cutover decision:

- [ ] **Week 5-6 Complete**: 10+ validation runs, all stable
- [ ] **Sales Data Ready**: Source identified, ETL scripts ready
- [ ] **UI Components Reviewed**: Integration points identified
- [ ] **Stakeholders Informed**: Communication plan active
- [ ] **Rollback Tested**: Dry run executed successfully
- [ ] **Documentation Current**: All guides up to date

**Full checklist**: See `validation/CUTOVER_READINESS_CHECKLIST.md`

---

## Getting Help

### Documentation
- **Full Summary**: `validation/WEEK_5_6_COMPLETION_SUMMARY.md`
- **Cutover Checklist**: `validation/CUTOVER_READINESS_CHECKLIST.md`
- **Validation Reports**: `validation/parallel_run_report_*.md`

### Logs
- **Monitoring Log**: `validation/monitoring.log`
- **Validation Output**: Console output when running scripts
- **Launchd Logs**: `validation/launchd_stdout.log` (if automation enabled)

### Scripts Help
```bash
# Comparison script
Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R --help

# Monitoring script
./scripts/global_scripts/98_test/monitor_parallel_runs.sh --help

# Rollback script
./scripts/global_scripts/98_test/rollback_to_legacy.sh --help
```

---

## Quick Commands Cheat Sheet

```bash
# Navigate to project
cd /Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA

# Run validation manually
Rscript scripts/global_scripts/98_test/compare_legacy_vs_new.R

# Enable daily automation
./scripts/global_scripts/98_test/monitor_parallel_runs.sh --daily

# Check status
./scripts/global_scripts/98_test/monitor_parallel_runs.sh --status

# View latest report
open validation/$(ls -t validation/parallel_run_report_*.md | head -n 1)

# Check rollback readiness
./scripts/global_scripts/98_test/rollback_to_legacy.sh --check

# View trend analysis
open validation/trend_analysis.md

# Check logs
tail -f validation/monitoring.log
```

---

**Version**: 1.0
**Created**: 2025-11-13
**Status**: Current

---

*For detailed information, see WEEK_5_6_COMPLETION_SUMMARY.md*
