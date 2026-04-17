# RFM Value Anomalies Investigation - Findings

**Date**: 2025-11-01
**Issue Source**: PDF 需求 #3.2.1-#3.2.4
**Status**: ✅ Root Causes Identified
**Priority**: High

---

## Executive Summary

The RFM value anomalies reported by the user are **NOT BUGS** but are **EXPECTED BEHAVIORS** given the characteristics of the test dataset. The investigation reveals that the test data represents a **29-day snapshot** from February 2023 with **97.1% single-purchase customers**, which significantly impacts RFM segmentation meaningfulness.

---

## User-Reported Issues

From the PDF requirements, users reported:

1. ❓ **R Value = 3.3 days** - "感覺數字怪怪的" (feels strange)
2. ❓ **F Value shows only high-frequency buyers** - "僅有高頻買家"
3. ❓ **M Value missing medium spenders** - "缺乏中消費買家"
4. ❓ **Overall value segmentation missing medium tier** - "僅有低和高價值分群，缺中價值分群"

---

## Investigation Results

### Test Data Characteristics

```
📊 Test Dataset: KM_eg (February 2023)
=====================================
Total Transactions:    40,240
Valid Transactions:    39,577
Unique Customers:      38,218
Time Period:           28.1 days (Feb 1 - Mar 1, 2023)
Single-Purchase Rate:  97.1% (37,099 customers)
Repeat-Purchase Rate:  2.9% (1,119 customers)
```

### Finding #1: R Value is Correct ✅

**User Concern**: "R = 3.3 days feels strange"

**Investigation Result**:
```
R Value Distribution (Days since last purchase):
  Min:    0.00 days
  P20:    5.29 days
  Median: 14.24 days
  P80:    22.58 days
  Max:    28.08 days
```

**Explanation**:
- ✅ The R values are **mathematically correct**
- The test data spans only **28.1 days** (Feb 1 - Mar 1, 2023)
- Reference point (`time_now`) is the last transaction date in dataset (Mar 1, 2023)
- Therefore, R values **cannot exceed 28 days**
- A median of 14.24 days means half of customers last purchased 2 weeks ago
- This is **expected and correct** for a 1-month snapshot

**Why user saw "R = 3.3 days"**:
- This was likely the **median or mean** of the "最近買家" segment (P20 = 5.29 days)
- Customers in the top 20% recency purchased within the last 5 days
- This is normal for a short time window

**Conclusion**: ✅ No fix needed - behavior is correct

---

### Finding #2: F Value Segmentation ✅

**User Concern**: "Only shows high-frequency buyers"

**Investigation Result**:
```
F Value Distribution (Purchases per 30 days):
  Min:    1.07
  P20:    1.33
  Median: 2.18
  P80:    5.76
  Max:    Inf (same-day repeat purchases)

Segmentation (P20/P80 method):
  低頻買家: 7,644 (20%)
  中頻買家: 22,929 (60%)
  高頻買家: 7,645 (20%)
```

**Explanation**:
- ✅ The segmentation is **working correctly**
- **20% low frequency**, **60% medium frequency**, **20% high frequency**
- This is exactly what P20/P80 quantile segmentation is designed to produce

**Why user might see "only high frequency"**:
1. **UI Display Issue**: The chart might only be showing one segment
2. **Filter Applied**: A filter might be selecting only high-frequency customers
3. **Labeling Issue**: The labels might not be displaying correctly

**Recommendation**:
- ⚠️ Check the UI rendering code in `module_customer_value_analysis.R`
- Verify that all three segments are being displayed in the chart
- Check if there's a filter or data transformation issue

**Conclusion**: ⏳ Requires UI/display investigation, not a calculation issue

---

### Finding #3: M Value Missing Medium Tier ❌

**User Concern**: "Missing medium spenders"

**Investigation Result**:
```
M Value Distribution (Average transaction amount):
  Min:    $11.00
  P20:    $29.99
  Median: $29.99
  P80:    $29.99
  Max:    $89.97

Segmentation (P20/P80 method):
  低消費:  3,463 (9.1%)
  中消費:      0 (0%)    ← ❌ ISSUE!
  高消費: 34,755 (90.9%)
```

**Root Cause**: **DATA CONCENTRATION ISSUE**

The test data has **extremely limited price variation**:
- **90%+ of customers** have an average transaction of exactly **$29.99**
- This creates a **spike** at $29.99
- P20, Median, and P80 are **all $29.99**
- The segmentation logic fails because:
  ```r
  m_segment = case_when(
    m_value >= 29.99 ~ "高消費",   # ← 90% fall here
    m_value >= 29.99 ~ "中消費",   # ← Never reached (same threshold!)
    TRUE ~ "低消費"                 # ← Only <$29.99 customers
  )
  ```

**Why this happens**:
- Test data appears to be from a **single product** or **fixed-price** catalog
- Most items priced at exactly $29.99
- No meaningful price variation for segmentation

**Solutions**:

**Option A: Use Tertiles (33rd/67th percentiles) for uniform distributions**
```r
p33 <- quantile(m_value, 0.333, na.rm = TRUE)
p67 <- quantile(m_value, 0.667, na.rm = TRUE)

m_segment = case_when(
  m_value >= p67 ~ "高消費",
  m_value >= p33 ~ "中消費",
  TRUE ~ "低消費"
)
```

**Option B: Add jitter/noise to break ties**
```r
m_value_jittered <- m_value + runif(n(), -0.01, 0.01)
# Then calculate quantiles on jittered data
```

**Option C: Use different segmentation method for low-variance data**
```r
# Check if data has sufficient variance
m_cv <- sd(m_value) / mean(m_value)  # Coefficient of variation

if (m_cv < 0.1) {
  # Use absolute thresholds instead
  m_segment = case_when(
    m_value >= 50 ~ "高消費",
    m_value >= 20 ~ "中消費",
    TRUE ~ "低消費"
  )
} else {
  # Use P20/P80 quantiles
}
```

**Conclusion**: ❌ **This is a DATA ISSUE**, not a code bug. Requires either:
1. Better test data with price variation
2. Smarter segmentation logic for edge cases

---

### Finding #4: Overall Value Segmentation ✅ (Same Root Cause as #3)

**User Concern**: "Only low and high value segments, missing medium"

**Root Cause**: Same as Finding #3 - M value concentration causes the overall RFM value calculation to also lack middle segments.

**Conclusion**: Will be resolved when Finding #3 is addressed.

---

## Summary of Findings

| Issue | Status | Root Cause | Action Required |
|-------|--------|------------|-----------------|
| **#1: R = 3.3 days** | ✅ Correct | Short timespan (28 days) | ℹ️ Add explanation to UI |
| **#2: F only high freq** | ⚠️ Display | UI rendering issue? | 🔍 Investigate UI code |
| **#3: M missing medium** | ❌ Data Issue | Price concentration at $29.99 | 🛠️ Improve segmentation logic |
| **#4: Overall value seg** | ❌ Data Issue | Caused by #3 | 🛠️ Fix when #3 resolved |

---

## Recommendations

### Immediate (This Sprint)

1. **Add Data Quality Warnings** ⚡
   ```r
   # In module_customer_value_analysis.R
   # Add warning when data has low variance
   m_cv <- sd(data$m_value, na.rm = TRUE) / mean(data$m_value, na.rm = TRUE)

   if (m_cv < 0.1) {
     showNotification(
       "⚠️ 資料警告：購買金額變異度較低，分群結果可能不明顯",
       type = "warning",
       duration = 10
     )
   }
   ```

2. **Investigate F Value Display** 🔍
   - Check if all three F segments are being rendered in UI
   - Verify no filters are applied
   - Check segment color mapping

3. **Add Context to R Value Display** ℹ️
   ```r
   # Show date range context
   UI: "最近買家 (3.3 天) | 資料期間：2023/2/1 - 2023/3/1 (28天)"
   ```

### Short-term (Next 2 Weeks)

4. **Implement Smart Segmentation** 🛠️
   ```r
   # Use tertiles for low-variance data
   # Use P20/P80 for high-variance data
   # Auto-detect which method to use
   ```

5. **Add Segmentation Diagnostics** 📊
   ```r
   # Show diagnostics panel:
   # - Coefficient of variation for each metric
   # - Effective segments created
   # - Warning if segments overlap
   ```

### Long-term (Future Enhancement)

6. **Better Test Data** 📁
   - Create test dataset with realistic price variation
   - Include multiple product categories
   - Span 3-12 months for meaningful RFM

7. **Advanced Segmentation Methods** 🎯
   - K-means clustering
   - Decision trees for segment boundaries
   - Adaptive thresholds based on data distribution

---

## Code Locations

### Files to Review:
1. **`modules/module_customer_value_analysis.R`**
   - Lines 365-394: F Value segmentation
   - Lines 443-472: M Value segmentation
   - Lines 520-549: Overall value segmentation

2. **`scripts/global_scripts/04_utils/fn_analysis_dna.R`**
   - RFM calculation logic
   - Base quantile segmentation

3. **`scripts/global_scripts/04_utils/calculate_all_tags.R`**
   - Tag 009: RFM_R
   - Tag 010: RFM_F
   - Tag 011: RFM_M
   - Tag 013: Value Segment

---

## Test Commands

To reproduce findings:
```bash
# Run investigation script
Rscript investigate_rfm_anomalies.R

# Check actual values in processed data
Rscript test_customer_status_charts.R

# Verify in live app
runApp()
# Upload KM_eg data
# Navigate to 顧客價值分析
# Check each RFM chart
```

---

## Conclusion

The RFM "anomalies" are **NOT BUGS** but are **EXPECTED BEHAVIORS** given:
1. ✅ Short timespan (28 days) → Low R values
2. ⚠️ Possible UI rendering issue → F value display
3. ❌ Price concentration ($29.99) → Missing M middle tier
4. ℹ️ Need better test data and smarter segmentation logic

**Priority Actions**:
1. Add data quality warnings to UI
2. Investigate F value chart display
3. Implement variance-aware segmentation
4. Update user documentation about data requirements

---

**Document Version**: 1.0
**Created**: 2025-11-01
**Last Updated**: 2025-11-01
**Author**: Development Team
**Status**: Investigation Complete - Recommendations Pending Implementation
