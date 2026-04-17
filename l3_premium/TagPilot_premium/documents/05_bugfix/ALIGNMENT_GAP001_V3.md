# Alignment with GAP-001 v3: Simplified Newbie Definition

**Date**: 2025-11-01
**Type**: Architecture Alignment
**Status**: ✅ Implemented

---

## Overview

This document records the alignment of TagPilot Premium V2's newbie definition with GAP-001 v3 specification from `logic_revised.md`.

---

## Background

### Document Conflict Identified

During verification, we found a conflict between two specification documents:

1. **logic_revised.md (GAP-001 v3)** - Line 190:
   ```
   新客 (Newbie) | ni == 1 | ✅ GAP-001 v3 simplified (2025-10-26)
   ```
   - **Definition**: Single purchase only (`ni == 1`)
   - **Rationale**: 業務清晰度、100% 覆蓋率、符合實務需求
   - **Previous versions**:
     - v2: `ni == 1 & customer_age_days <= 60`
     - v1: `ni == 1 & customer_age_days <= avg_ipt`

2. **顧客動態計算方式調整_20251025.md** - Lines 65-69:
   ```
   新客的定義是首購＆在平均購買時間內
   1. 首購：僅購買一次 (ni == 1)
   2. 平均購買時間：所有大於等於2比顧客相鄰購買間隔中位數(天)
   ```
   - **Definition**: `ni == 1 & customer_age_days <= μ_ind`
   - **More restrictive**: Adds time constraint

---

## Decision: Follow GAP-001 v3

**Selected**: Option B - GAP-001 v3 (`ni == 1` only)

### Rationale

1. **Business Clarity**: Simpler definition is easier to explain and understand
2. **100% Coverage**: All single-purchase customers are classified (no edge cases)
3. **Practical Need**: Aligns with business requirements
4. **Recent Specification**: GAP-001 v3 is dated 2025-10-26 (more recent)
5. **Documented Evolution**: Explicitly marked as "simplified" improvement

### Benefits

- ✅ **Simpler Logic**: One condition instead of two
- ✅ **No Edge Cases**: All ni==1 customers clearly classified
- ✅ **Consistent**: Same definition for both z-score and fixed threshold methods
- ✅ **Maintainable**: Less complexity in classification logic

---

## Implementation

### File: `utils/analyze_customer_dynamics_new.R`

**Lines 259-263** (Z-Score Method):

```r
# ✅ GAP-001 v3: 新客定義簡化為 ni == 1 (2025-10-26)
# 簡化理由：業務清晰度、100% 覆蓋率、符合實務需求
# 歷史版本：v2 使用 ni == 1 & customer_age_days <= 60
#          v1 使用 ni == 1 & customer_age_days <= avg_ipt
ni == 1 ~ "newbie",
```

**Lines 233-238** (Fixed Threshold Method):

```r
customer_dynamics = case_when(
  is.na(r_value) ~ "unknown",

  # 新客：ni == 1 (首購)
  ni == 1 ~ "newbie",
```

### Key Changes

1. **Removed time constraint**: No longer check `customer_age_days <= μ_ind`
2. **Primary condition**: Moved `ni == 1` to first position (after unknown check)
3. **Added documentation**: Inline comments explain GAP-001 v3 and history
4. **Consistent across methods**: Both z-score and fixed threshold use same logic

---

## Verification

### Integration Test Results

```
🏷️ Testing Customer Tags Calculation...
  ✅ Tags calculated for 38,350 customers
  ✅ Total tags created: 14
  ✅ tag_017_customer_dynamics exists
     Distribution:
       - 主力客 (active): 398
       - 半睡客 (half_sleepy): 329
       - 沉睡客 (dormant): 259
       - 新客 (newbie): 37,016  ← 96.5% of customers
       - 睡眠客 (sleepy): 348

✅ ALL TESTS PASSED
```

### Customer Distribution Analysis

**Total Customers**: 38,350

| Category | English | Count | Percentage | Notes |
|----------|---------|-------|------------|-------|
| 新客 | newbie | 37,016 | 96.5% | Single purchase customers |
| 主力客 | active | 398 | 1.0% | High frequency (z_i ≥ +0.5) |
| 睡眠客 | sleepy | 348 | 0.9% | Medium frequency |
| 半睡客 | half_sleepy | 329 | 0.9% | Low frequency |
| 沉睡客 | dormant | 259 | 0.7% | Very low frequency |

**Insight**: 96.5% newbies is expected for this dataset (29-day observation period in February 2023) - most customers only purchased once during this short window.

---

## Comparison with Alternative

### If we had used μ_ind constraint:

**With time constraint** (`ni == 1 & customer_age_days <= μ_ind`):
- μ_ind = 0 days (median of intervals in this dataset)
- Would classify differently: Some ni==1 customers might not be "newbie"
- More complex classification logic
- Edge cases to handle

**Without time constraint** (GAP-001 v3 - **CURRENT**):
- All ni==1 are "newbie"
- Simple and clear
- No edge cases
- ✅ **Chosen approach**

---

## Impact on Other Modules

### Modules Using customer_dynamics

1. **Module 4: Customer Status** ✅
   - Uses `tag_017_customer_dynamics` (Chinese values)
   - No changes needed - receives translated values

2. **Module 6: Lifecycle Prediction** ✅
   - Uses customer lifecycle stages for predictions
   - Simplified newbie definition improves clarity

3. **Tag Calculation** ✅
   - `calculate_status_tags()` transforms to Chinese
   - Works correctly with simplified definition

### No Breaking Changes

- ✅ Data structure unchanged
- ✅ Field names unchanged
- ✅ Tag calculations unchanged
- ✅ UI displays unchanged
- ✅ Only classification logic simplified

---

## Documentation Updates

### Files Updated

1. **utils/analyze_customer_dynamics_new.R**:
   - Lines 259-263: Z-score method newbie classification
   - Lines 233-238: Fixed threshold method newbie classification
   - Added GAP-001 v3 documentation comments

2. **documents/05_bugfix/ALIGNMENT_GAP001_V3.md** (this file):
   - Documents decision and rationale
   - Explains implementation
   - Records verification results

### Files Requiring No Changes

- ✅ `modules/module_dna_multi_premium_v2.R` - Uses classification output
- ✅ `utils/calculate_customer_tags.R` - Receives customer_dynamics values
- ✅ `modules/module_customer_status.R` - Displays tag_017 values
- ✅ Test files - Continue to pass

---

## Specification Alignment Summary

| Aspect | Specification | Implementation | Status |
|--------|--------------|----------------|---------|
| **Newbie Definition** | GAP-001 v3: `ni == 1` | `ni == 1` | ✅ Aligned |
| **Active Customer** | z_i ≥ +0.5 (with optional guardrail) | Implemented | ✅ Aligned |
| **Sleepy Customer** | -1.0 ≤ z_i < +0.5 | Implemented | ✅ Aligned |
| **Half-Sleepy** | -1.5 ≤ z_i < -1.0 | Implemented | ✅ Aligned |
| **Dormant** | z_i < -1.5 | Implemented | ✅ Aligned |
| **μ_ind Calculation** | Median of intervals (ni≥2) | Using diff() | ✅ Aligned |
| **W Calculation** | min(cap_days, max(90, round_to_7(2.5×μ_ind))) | Implemented | ✅ Aligned |
| **Z-Score Formula** | (F_i,w - λ_w) / σ_w | Implemented | ✅ Aligned |

---

## Lessons Learned

1. **Specification Priority**: When conflicts exist, use the most recent dated specification
2. **Business Simplicity**: Simpler definitions are often better for business understanding
3. **Document Evolution**: Track version history (v1 → v2 → v3) for context
4. **Inline Documentation**: Add comments explaining architectural decisions
5. **Verification**: Test with real data to confirm classification distribution

---

## Future Considerations

### Monitoring Recommendations

1. **Track newbie percentage** over time
   - Current: 96.5% (29-day window)
   - Expected to decrease with longer observation periods
   - Flag if >80% in 365-day windows

2. **Validate business assumptions**
   - Confirm ni==1 definition meets business needs
   - Review after 6 months of production use
   - Collect user feedback on classification clarity

3. **Document edge cases**
   - VIP customers with single high-value purchase
   - Test purchases or returns
   - Corporate bulk orders

---

**Alignment Completed By**: Development Team
**Date**: 2025-11-01
**Status**: ✅ Aligned with GAP-001 v3
**Verification**: ✅ Integration test passing
**Ready**: For production deployment
