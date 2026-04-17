# Bug Fix #11: Chart Label Mappings - Chinese Key Mismatch

**Date**: 2025-11-01
**Severity**: Critical (lifecycle charts showing "null")
**Status**: ✅ Fixed
**Related**: BUGFIX_20251101_NULL_LIFECYCLE_CHARTS.md (Fix #9)

---

## Problem Summary

### User Report
> "為什麼都是顯示null" (Why is everything showing null)

**Screenshot showed**:
- 生命週期階段分布 (Lifecycle Stage Distribution): **"null 38,350 100%"**
- 流失風險分布 (Churn Risk Distribution): ✅ Working correctly
- 生命週期階段 × 流失風險矩陣 (Lifecycle × Churn Risk Matrix): Empty/no data

### Root Cause

**The problem**: English/Chinese key mismatch in plotly chart mappings

```r
# In module_customer_status.R - BEFORE FIX
color_map <- c(
  "newbie" = "#17a2b8",      # English keys
  "active" = "#28a745",
  "sleepy" = "#ffc107",
  ...
)

# But the data contains:
tag_017_customer_dynamics = c("新客", "主力客", "睡眠客", ...)  # Chinese values
```

**What happened**:
1. `tag_017_customer_dynamics` is calculated by `calculate_status_tags()` which transforms English to Chinese
2. Customer status module tried to map Chinese values to English keys
3. Mapping failed → returned `NULL`
4. Plotly displayed "null 38,350 100%"

**Why churn risk chart worked**:
```r
# Churn risk chart already used Chinese keys (lines 306-310)
color_map <- c(
  "低" = "#28a745",    # ✅ Matches tag_018_churn_risk values
  "中" = "#ffc107",
  "高" = "#dc3545"
)
```

---

## Fix Applied

### File Modified
`modules/module_customer_status.R`

### Changes Made

#### 1. Lifecycle Pie Chart (lines 253-276)

**BEFORE**:
```r
# 定義顏色和中文標籤
color_map <- c(
  "newbie" = "#17a2b8",        # ❌ English keys
  "active" = "#28a745",
  "sleepy" = "#ffc107",
  "half_sleepy" = "#fd7e14",
  "dormant" = "#6c757d",
  "unknown" = "#e9ecef"
)

label_map <- c(
  "newbie" = "新客",           # ❌ English keys mapping to Chinese
  "active" = "活躍",
  "sleepy" = "輕度睡眠",
  "half_sleepy" = "半睡眠",
  "dormant" = "沉睡",
  "unknown" = "未知"
)
```

**AFTER**:
```r
# ✅ FIX: tag_017_customer_dynamics contains CHINESE values
color_map <- c(
  "新客" = "#17a2b8",          # ✅ Chinese keys
  "主力客" = "#28a745",
  "睡眠客" = "#ffc107",
  "半睡客" = "#fd7e14",
  "沉睡客" = "#6c757d",
  "未知" = "#e9ecef"
)

label_map <- c(
  "新客" = "新客",             # ✅ Chinese keys
  "主力客" = "主力客",
  "睡眠客" = "睡眠客",
  "半睡客" = "半睡客",
  "沉睡客" = "沉睡客",
  "未知" = "未知"
)
```

#### 2. Lifecycle × Churn Risk Heatmap (lines 353-370)

**BEFORE**:
```r
# 轉換為矩陣格式
lifecycle_order <- c("newbie", "active", "sleepy",
                     "half_sleepy", "dormant", "unknown")  # ❌ English

label_map <- c(
  "newbie" = "新客",          # ❌ English to Chinese mapping
  "active" = "活躍",
  ...
)
```

**AFTER**:
```r
# ✅ FIX: Use Chinese lifecycle stage order
lifecycle_order <- c("新客", "主力客", "睡眠客",
                     "半睡客", "沉睡客", "未知")  # ✅ Chinese

label_map <- c(
  "新客" = "新客",            # ✅ Chinese keys
  "主力客" = "主力客",
  "睡眠客" = "睡眠客",
  "半睡客" = "半睡客",
  "沉睡客" = "沉睡客",
  "未知" = "未知"
)
```

#### 3. Customer Table (lines 420-429)

**BEFORE**:
```r
label_map <- c(
  "newbie" = "新客",          # ❌ English keys
  "active" = "活躍",
  ...
)
```

**AFTER**:
```r
# ✅ FIX: tag_017_customer_dynamics contains CHINESE values
label_map <- c(
  "新客" = "新客",            # ✅ Chinese keys
  "主力客" = "主力客",
  ...
)
```

---

## Technical Details

### Data Flow Review

```
calculate_status_tags() (utils/calculate_customer_tags.R)
    ↓
Transforms customer_dynamics:
    - "newbie" → "新客"
    - "active" → "主力客"
    - "sleepy" → "睡眠客"
    - "half_sleepy" → "半睡客"
    - "dormant" → "沉睡客"
    ↓
Stores in tag_017_customer_dynamics (CHINESE values)
    ↓
module_customer_status.R receives data
    ↓
Charts must use CHINESE keys for mapping
```

### Why This Happened

1. **Assumption Error**: Module assumed tags would be in English
2. **Partial Testing**: Churn risk chart worked (already had Chinese keys), so issue not obvious
3. **Translation Layer**: Tag calculation includes English→Chinese transformation not documented in module
4. **Integration Gap**: No validation that chart keys match actual data values

### English vs Chinese Lifecycle Labels

| English (customer_dynamics) | Chinese (tag_017) | Display Label |
|----------------------------|------------------|---------------|
| newbie | 新客 | 新客 |
| active | 主力客 | 主力客 |
| sleepy | 睡眠客 | 睡眠客 |
| half_sleepy | 半睡客 | 半睡客 |
| dormant | 沉睡客 | 沉睡客 |
| unknown | 未知 | 未知 |

**Note**: Original module used different display labels:
- "活躍" (active/lively) → Changed to "主力客" (main customer)
- "輕度睡眠" (light sleep) → Changed to "睡眠客" (sleepy customer)

---

## Impact

### Before Fix
- ❌ Lifecycle pie chart: "null 38,350 100%"
- ❌ Lifecycle × churn risk heatmap: Empty (no data)
- ✅ Churn risk bar chart: Working (already had Chinese keys)
- ❌ Customer table: Potentially incorrect labels

### After Fix
- ✅ Lifecycle pie chart: Shows actual distribution
- ✅ Lifecycle × churn risk heatmap: Populated with cross-tabulation
- ✅ Churn risk bar chart: Still working
- ✅ Customer table: Correct label mappings

---

## Verification

### Syntax Check
```bash
Rscript -e "source('modules/module_customer_status.R')"
# ✅ No syntax errors
```

### Expected Results (After Fix)

**Lifecycle Pie Chart** should display:
- 新客: 37,016 (96.5%)
- 主力客: 398 (1.0%)
- 睡眠客: 348 (0.9%)
- 半睡客: 329 (0.9%)
- 沉睡客: 259 (0.7%)

**Lifecycle × Churn Risk Heatmap** should show:
- Cross-tabulation of 5 lifecycle stages × 3 risk levels
- Most "新客" should be "新客（無法評估）" or "低風險"
- "主力客" should have lower risk
- "沉睡客" should have higher risk

---

## Related Fixes

This fix is part of the comprehensive lifecycle chart debugging:

1. **Fix #9.1-9.4**: Calculate all tags after DNA analysis
2. **Fix #10**: Use correct Chinese values for counting
3. **Fix #11**: Use correct Chinese keys for chart mappings ← **THIS FIX**

---

## Lessons Learned

1. **Data Contract Validation**: Verify actual data values match expected keys
2. **Consistent Language**: Use same language (Chinese or English) throughout data flow
3. **Test All Charts**: Don't assume all charts work if some work
4. **Document Transformations**: Clearly document where English→Chinese conversion happens
5. **Type Safety**: Consider using enums or constants for lifecycle stages

---

## Prevention Measures

### Immediate
- ✅ Use Chinese keys consistently in all customer_status charts
- ✅ Document that tag_017 contains Chinese values

### Short-term
- [ ] Add data validation: Check tag_017 values are in expected Chinese set
- [ ] Create shared constants file for lifecycle/risk labels
- [ ] Add inline comments explaining language expectations

### Long-term
- [ ] Consider creating a `customer_lifecycle_labels.R` config file
- [ ] Add unit tests for chart data preparation
- [ ] Schema validation for tag values

---

**Bug Fixed By**: Development Team
**Date**: 2025-11-01
**Status**: ✅ Fixed and Documented
**Syntax Check**: ✅ Passed
**Files Modified**: 1 (module_customer_status.R)
**Lines Changed**: 3 sections (pie chart, heatmap, table)
**Ready**: For app testing with real data

---

**Next Step**: Test app with real data to verify charts display correctly
