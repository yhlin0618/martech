# WEEK 7 KICKOFF BRIEF
## MAMBA ETL+DRV Precision Marketing Redesign

**Date**: 2025-11-13
**Duration**: 7 days (Nov 13-19, 2025)
**Status**: ✅ READY TO BEGIN (Day 0 Complete)
**Team Lead**: principle-product-manager

---

## WHAT WE'RE DOING

### The Mission

Integrate CBZ (ChaBangZhuo) sales data into the MAMBA precision marketing system, completing the 4-layer ETL+DRV architecture redesign.

### Why Now

Week 7 is the final phase of a 7-week project (62% complete). We're adding the last major data source to unlock complete cross-channel customer analytics.

### What Success Looks Like

By end of Week 7:
- CBZ sales data flowing through all 4 ETL layers (RAW → STAGED → TRANSFORMED → PROCESSED)
- Precision UI updated to display CBZ customer insights
- Zero data integrity issues
- Production cutover complete
- All features working seamlessly

---

## WHY WE'RE READY

### Day 0 Pre-Flight ✅ COMPLETE

| Safety Check | Status | Details |
|--------------|--------|---------|
| **Database Backups** | ✅ DONE | 4/4 databases backed up (11.79 MB) |
| **CBZ Data Pipeline** | ✅ READY | 8/8 ETL scripts validated |
| **Rollback Procedure** | ✅ TESTED | Dry-run successful |
| **System Resources** | ✅ HEALTHY | CPU: 66% idle, Memory: 20GB free |

**Confidence Level**: 95% (HIGH)
**Critical Blockers**: ZERO

### What's Already Built

From Weeks 0-6 (62% complete):
- 4-layer database architecture (RAW/STAGED/TRANSFORMED/PROCESSED)
- EBY sales data fully integrated and validated
- Core precision analytics working (RFM, CLV, segmentation)
- Comprehensive testing and validation frameworks
- 171 principles and rules documented

---

## DAILY SCHEDULE

### Day 1-2: Sales Data Integration
**Focus**: Load CBZ sales into RAW → STAGED → TRANSFORMED

**Tasks**:
- Execute `cbz_ETL_sales_1ST.R` (RAW → STAGED)
- Execute `cbz_ETL_sales_2TR.R` (STAGED → TRANSFORMED)
- Run data validation tests
- Verify no EBY data disruption

**Success Criteria**:
- ✅ CBZ sales data in all 3 layers
- ✅ Row counts match expectations
- ✅ No NULL values in critical columns
- ✅ Validation tests PASS

### Day 3-4: Customer/Product/Order Integration
**Focus**: Complete entity integration

**Tasks**:
- Execute customers ETL (1ST + 2TR)
- Execute products ETL (1ST + 2TR)
- Execute orders ETL (1ST + 2TR)
- Update precision ETL to use CBZ data
- Cross-entity validation

**Success Criteria**:
- ✅ All CBZ entities integrated
- ✅ Foreign key relationships valid
- ✅ Precision metrics updated

### Day 5: Data Validation Day
**Focus**: Comprehensive validation

**Tasks**:
- Run `validate_precision_etl_drv.R`
- Execute legacy vs. new comparison
- Check for data quality issues
- Performance benchmarking

**Success Criteria**:
- ✅ Zero critical violations
- ✅ Performance meets SLA
- ✅ Audit report generated

### Day 6: UI Update and Testing
**Focus**: User-facing components

**Tasks**:
- Update precision UI components for CBZ
- Add CBZ filters and visualizations
- User acceptance testing
- Bug fixing

**Success Criteria**:
- ✅ CBZ data visible in UI
- ✅ No UI crashes
- ✅ User workflows functional

### Day 7: Cutover and Monitoring
**Focus**: Production deployment

**Tasks**:
- Final cutover decision (GO/NO-GO)
- Deactivate legacy D04 processes
- Activate MAMBA ETL+DRV full system
- 24-hour monitoring period
- Week 7 completion report

**Success Criteria**:
- ✅ Cutover successful
- ✅ Zero critical incidents
- ✅ All features working
- ✅ Project 100% complete

---

## EMERGENCY PROCEDURES

### If Things Go Wrong

**Step 1: STOP**
```bash
# Immediately halt ETL processes
pkill -f "cbz_ETL"
```

**Step 2: ASSESS**
- Check error logs: `/scripts/global_scripts/98_test/logs/`
- Review validation results
- Determine severity (critical vs. minor)

**Step 3: DECIDE**
- **Minor issues**: Fix forward, continue Week 7
- **Major issues**: Execute rollback procedure

**Step 4: ROLLBACK (if needed)**
```bash
cd /Users/che/.../MAMBA
./scripts/global_scripts/98_test/rollback_to_legacy.sh --execute
```

This will:
- Create rollback backup of current state
- Restore pre-Week-7 databases
- Deactivate MAMBA processes
- Return to Day 0 state (< 15 minutes)

### Rollback Decision Tree

Execute rollback if ANY of these occur:
- ❌ Database corruption detected
- ❌ Data loss > 1% of records
- ❌ System-wide ETL failures
- ❌ Precision features completely broken

Do NOT rollback for:
- ✅ UI cosmetic bugs (fix forward)
- ✅ Minor data warnings (document and fix)
- ✅ Performance optimization opportunities
- ✅ Non-critical validation failures

---

## TEAM ROLES AND RESPONSIBILITIES

### principle-product-manager (AI Agent)
- Overall coordination and decision-making
- Daily progress monitoring
- Risk management
- Documentation

### principle-coder (AI Agent)
- ETL script execution
- Code modifications as needed
- Bug fixing

### principle-debugger (AI Agent)
- Data validation
- Quality assurance
- Performance testing

### User (Project Owner)
- Final approvals
- Go/No-Go decisions
- Issue escalation
- Post-deployment validation

---

## SUCCESS METRICS

### Technical Metrics

| Metric | Target | How We Measure |
|--------|--------|----------------|
| **Data Completeness** | 100% | Row counts match source |
| **Data Quality** | > 99% | Validation test pass rate |
| **ETL Success Rate** | 100% | All scripts execute without errors |
| **Performance** | < 2 min | Full precision ETL execution time |
| **Uptime** | > 99.5% | System availability during cutover |

### Business Metrics

| Metric | Target | Impact |
|--------|--------|--------|
| **Customer Coverage** | + CBZ customers | Expanded analytics scope |
| **Sales Visibility** | + CBZ channel | Complete multi-channel view |
| **Precision Accuracy** | Maintained | No regression in analytics quality |

---

## COMMUNICATION PLAN

### Daily Stand-Up (10 minutes)

**Time**: Start of each day
**Format**: Status update in this document

**Questions**:
1. What was completed yesterday?
2. What's planned for today?
3. Any blockers or risks?

### Progress Tracking

Update `IMPLEMENTATION_PROGRESS_SUMMARY.md` daily with:
- Completed tasks (✅)
- In-progress tasks (🔄)
- Blocked tasks (❌)
- Overall percentage complete

### Escalation Path

1. **Minor issues**: Document in daily notes, fix forward
2. **Medium issues**: Alert user, provide options
3. **Critical issues**: STOP work, trigger emergency procedure

---

## KEY RESOURCES

### Documentation

- **Day 0 Report**: `/validation/DAY_0_COMPLETION_REPORT.md`
- **Week 7 Plans**: `/validation/WEEK_7_DAY_*.md` (5 files)
- **Progress Tracker**: `/IMPLEMENTATION_PROGRESS_SUMMARY.md`
- **Principles**: `/scripts/global_scripts/00_principles/`

### Backups

- **Pre-Week 7**: `/data/backups/pre_week7_20251113_055815/`
- **Checksums**: See Day 0 report Appendix A

### Scripts

- **ETL Scripts**: `/scripts/update_scripts/ETL/cbz/`
- **Validation**: `/scripts/global_scripts/98_test/validate_precision_etl_drv.R`
- **Rollback**: `/scripts/global_scripts/98_test/rollback_to_legacy.sh`

### Databases

- **Production**: `/data/{raw,staged,transformed,processed}_data.duckdb`
- **Legacy**: `/data/data.duckdb` (12 KB, preserved for rollback)

---

## CONFIDENCE BOOSTERS

### What Makes This Safe

1. **Complete Backups**: Every database backed up with MD5 verification
2. **Tested Rollback**: Dry-run successful, < 15 min execution
3. **Incremental Approach**: 7 days with daily validation
4. **No Data Loss Risk**: Backups + rollback = zero permanent damage
5. **Proven Foundation**: Weeks 0-6 complete (62% project done)

### Why This Will Succeed

1. **Clear Plan**: 5 detailed daily plans created
2. **Ready Infrastructure**: All scripts validated, databases ready
3. **Safety Nets**: Backups, rollback, validation at every step
4. **Experienced Team**: AI agents with proven Week 0-6 track record
5. **No Critical Blockers**: Day 0 checks 100% passed

---

## LET'S GO! 🚀

**Week 7 starts NOW.**

Next action: Execute Day 1 plan - CBZ Sales Integration

Questions? Check the Day 0 Completion Report or ask principle-product-manager.

**Remember**: We have backups, we have rollback, we have a plan. Let's ship this! 💪

---

**Prepared By**: principle-product-manager
**Date**: 2025-11-13
**Status**: ✅ READY FOR WEEK 7 EXECUTION

*End of Kickoff Brief*
