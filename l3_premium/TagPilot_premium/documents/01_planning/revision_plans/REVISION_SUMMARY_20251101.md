# TagPilot Premium - Revision Summary & Quick Reference

**Date**: 2025-11-01
**Purpose**: Executive summary of proposed changes
**For**: Product Owner, Stakeholders, Development Team

---

## 🎯 What's Changing?

We're upgrading TagPilot Premium's **customer lifecycle analysis** from **fixed thresholds** to a **data-driven, industry-adaptive statistical model**.

### Current System (Old)
```
固定閾值方法 (Fixed Thresholds):
- 新客: ni == 1
- 主力客: R ≤ 7天
- 瞌睡客: 7 < R ≤ 14天
- 半睡客: 14 < R ≤ 21天
- 沉睡客: R > 21天

問題:
❌ 咖啡店 vs 家具店用同樣標準不合理
❌ 無法適應不同產業特性
```

### New System (Z-Score Based)
```
統計分數方法 (Statistical Z-Score):
- 新客: ni == 1 AND customer_age ≤ μ_ind (產業中位購買週期)
- 主力客: z-score ≥ +0.5
- 瞌睡客: -1.0 ≤ z-score < +0.5
- 半睡客: -1.5 ≤ z-score < -1.0
- 沉睡客: z-score < -1.5

優勢:
✅ 自動適應產業特性
✅ 統計嚴謹性
✅ 可配置參數
```

---

## 📊 Key Metrics Comparison

| Aspect | Old Method | New Method |
|--------|-----------|------------|
| **Active threshold** | 7 days (fixed) | Dynamic based on z-score |
| **Industry adaptation** | ❌ None | ✅ Automatic |
| **Statistical rigor** | ❌ Arbitrary | ✅ Z-score based |
| **Data requirement** | Any | Minimum 365 days |
| **Newbie definition** | ni == 1 (simple) | ni == 1 AND age ≤ μ_ind |
| **Activity for ni < 4** | Recency-based | ❌ NA (removed) |
| **RFM threshold** | ni ≥ 4 only | ✅ All customers |

---

## 🔄 5 Major Changes

### Change 1: Customer Dynamics (顧客動態) - Z-Score Based ⭐
**Impact**: HIGH | **Effort**: 5 days

**Before**:
```r
lifecycle_stage = case_when(
  ni == 1 ~ "newbie",
  r_value <= 7 ~ "active",    // Fixed!
  r_value <= 14 ~ "sleepy",   // Fixed!
  TRUE ~ "dormant"
)
```

**After**:
```r
# Calculate industry median (μ_ind)
μ_ind = median(all_purchase_intervals)

# Calculate z-score
z_i = (F_i_w - λ_w) / σ_w

lifecycle_stage = case_when(
  ni == 1 & customer_age <= μ_ind ~ "newbie",
  z_i >= 0.5 ~ "active",      // Dynamic!
  z_i >= -1.0 ~ "sleepy",     // Dynamic!
  TRUE ~ "dormant"
)
```

**Why**: Different industries have different purchase cycles. Coffee (7 days) vs Furniture (180 days) need different standards.

---

### Change 2: Activity Level - Strict ni ≥ 4 Only
**Impact**: MEDIUM | **Effort**: 1 day

**Before**: Two-tier strategy
- ni ≥ 4: Use CAI ✅
- ni = 2-3: Use Recency degradation ⚠️
- ni = 1: NA

**After**: Simplified
- ni ≥ 4: Use CAI ✅
- ni < 4: NA ❌

**Impact**: ~40% of customers will have `activity_level = NA`

**Mitigation**: Special UI handling for ni < 4 customers

---

### Change 3: RFM Scores - Now for All Customers
**Impact**: LOW | **Effort**: 1 day

**Before**: RFM only for ni ≥ 4
**After**: RFM for ALL customers

**Why**: RFM is independent of CAI. No statistical reason to exclude ni < 4.

**Benefit**: More complete customer profiles

---

### Change 4: Next Purchase Prediction - "Remaining Time" Logic
**Impact**: MEDIUM | **Effort**: 2 days

**Before**:
```r
next_date = today + avg_ipt
```

**After**:
```r
elapsed = days_since_last_purchase
remaining = max(0, avg_ipt - elapsed)

if (remaining > 0) {
  next_date = today + remaining
} else {
  next_date = today + avg_ipt  // Overdue, predict full cycle
}
```

**Example**:
```
Scenario: Customer buys coffee every 7 days
Last purchase: 3 days ago

Old: next_date = today + 7 = 7 days from now ❌
New: next_date = today + (7-3) = 4 days from now ✅
```

---

### Change 5: Terminology Updates
**Impact**: LOW | **Effort**: 1 day

| Old | New |
|-----|-----|
| 生命週期階段 | 顧客動態 |
| DNA分析 | SDNA分析 |
| 逐漸活躍 | 漸趨活躍 |
| 逐漸不活躍 | 漸趨靜止 |

---

## 📈 Business Benefits

### For Coffee Shop (Fast-Moving)
```
μ_ind = 7 days (weekly buyers)
W = 90 days observation window

Customer A: 12 purchases in 90 days
z-score = +1.33 → Active ✅

Customer B: 2 purchases in 90 days
z-score = -2.00 → Dormant ✅

Same classification system, different thresholds!
```

### For Furniture Store (Slow-Moving)
```
μ_ind = 180 days (bi-annual buyers)
W = 315 days observation window

Customer C: 3 purchases in 315 days
z-score = +1.00 → Active ✅

Customer D: 1 purchase in 315 days
z-score = -1.00 → Half-Sleep ✅

Automatically adapts to industry rhythm!
```

---

## ⚠️ Key Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| **Insufficient data** (< 365 days) | Fallback to old method with warning |
| **40% lose activity level** | Special UI for ni < 4 customers |
| **Z-scores confusing** | Add tooltips, documentation, examples |
| **Breaking changes** | Feature flag, gradual rollout |
| **Performance issues** | Caching, optimization |

---

## 📋 Data Requirements

### Minimum Requirements
- ✅ **365+ days** of transaction data
- ✅ **100+ customers** total
- ✅ **30+ customers** with ni ≥ 2
- ✅ **500+ transactions** total

### What Happens If Requirements Not Met?

```r
if (data insufficient) {
  OPTION 1: Show error, block analysis
  OPTION 2: Show warning, use old fixed method
  OPTION 3: Show warning, continue with reduced confidence
}
```

**Recommended**: Option 2 (graceful degradation)

---

## 🚀 Implementation Timeline

| Week | Milestone | Deliverable |
|------|-----------|-------------|
| **1** | Preparation | Test data, validation framework |
| **2** | Core Dev | New calculation engine, RFM fix |
| **3** | UI Updates | New displays, warnings, diagnostics |
| **4** | Testing | Full test suite, validation report |
| **5** | Beta | Selected user testing |
| **6** | Rollout | Gradual 25% → 50% → 100% |
| **7** | Full Launch | All users, announcements |
| **8** | Cleanup | Remove old code, documentation |

**Total**: 8 weeks
**Team**: 1 dev + 1 QA + 0.5 PM

---

## 📊 Success Criteria

### Technical
- [ ] All unit tests pass (80+ coverage)
- [ ] Performance < 5 seconds for 10K customers
- [ ] Error rate < 1%
- [ ] 60-80% agreement with old method (expected difference)

### Business
- [ ] User comprehension > 80% (survey)
- [ ] Classification accuracy > 90% (manual review)
- [ ] No false active dormant customers
- [ ] Positive user feedback

---

## 🎓 User Education Plan

### Documentation
1. **What's New Guide**: Explain changes in plain language
2. **Z-Score Explained**: Infographic + examples
3. **FAQ**: Address common questions
4. **Video Tutorial**: 5-minute walkthrough

### Training
1. **Webinar**: Live demo + Q&A
2. **Email Series**: 4 emails explaining features
3. **In-App Tooltips**: Context-sensitive help

---

## 📞 Decision Required

### Option A: Full Implementation (Recommended)
- Implement all 5 changes
- Timeline: 8 weeks
- Benefit: Complete upgrade, future-proof
- Risk: Medium (mitigated with feature flag)

### Option B: Phased Approach
- Phase 1: Change 1 only (z-score dynamics)
- Phase 2: Changes 2-4 later
- Timeline: 10 weeks total
- Benefit: Lower risk
- Risk: Longer timeline, more testing overhead

### Option C: Minimal Changes
- Only implement Change 2 (RFM) and Change 5 (terminology)
- Timeline: 2 weeks
- Benefit: Quick win
- Risk: Doesn't solve core fixed-threshold problem

---

## 🎯 Recommendation

**Proceed with Option A (Full Implementation)**

**Rationale**:
1. ✅ Addresses root cause (fixed thresholds)
2. ✅ Future-proof solution
3. ✅ Risks mitigated with feature flag + gradual rollout
4. ✅ All changes interconnected (makes sense to do together)
5. ✅ Clean cut-over, less technical debt

**Next Steps**:
1. ✅ Review this plan with product team
2. Get stakeholder sign-off
3. Create development branch
4. Begin Week 1 tasks

---

## 📚 Document Index

| Document | Purpose | Audience |
|----------|---------|----------|
| **This Document** | Executive summary | All stakeholders |
| **APP_REVISION_PLAN_20251101.md** | Detailed implementation plan | Development team |
| **new_customer_dynamics_implementation.R** | R code implementation | Developers |
| **logic_revised.md** | Updated logic documentation | All |
| **顧客動態計算方式調整_20251025.md** | Original methodology spec | Product team |

---

## ✅ Approval Checklist

- [ ] Product Owner reviewed and approved
- [ ] Development team capacity confirmed
- [ ] QA resources allocated
- [ ] Timeline acceptable to business
- [ ] Risk mitigation plan approved
- [ ] Budget approved (if applicable)
- [ ] Stakeholders notified

---

## 🤔 Frequently Asked Questions

### Q: Why change the current system?
**A**: Fixed 7/14/21 day thresholds don't work for all industries. A coffee shop and furniture store have completely different purchase cycles.

### Q: Will this break existing dashboards?
**A**: No. We'll use feature flags and gradual rollout. Old method remains available as fallback.

### Q: What if I don't have 365 days of data?
**A**: System will automatically fall back to old fixed threshold method with a warning.

### Q: Will classifications change drastically?
**A**: For most customers (60-80%), classifications will be similar. Main changes will be in edge cases and industry-specific adjustments.

### Q: What happens to customers with ni < 4?
**A**: They'll have `activity_level = NA` but still get:
- ✅ Lifecycle stage (newbie/active/dormant)
- ✅ RFM scores (NEW!)
- ✅ Value level
- ❌ Activity level (requires ni ≥ 4)

### Q: Can I still use the old method?
**A**: Yes, via configuration flag during transition period. After full rollout, old method will be deprecated.

---

**Document Status**: ✅ Ready for Review
**Version**: 1.0
**Last Updated**: 2025-11-01
**Next Review Date**: 2025-11-08
