# Bug Fix: DNA Analysis Data Format Mismatch

**Date**: 2025-11-01
**Severity**: Critical (prevented DNA analysis execution)
**Status**: ✅ Fixed

---

## Bug Report

### Issue
When calling `analysis_dna()` function, got error:
```
❌ 分析失敗：ERROR: No suitable time field found in df_sales.
Required one of: payment_time, min_time_by_date, min_time
```

### Root Cause
**Data format mismatch between module v2 and analysis_dna() function**:

1. **Module v2** (lines 245-249) standardizes column names:
   - `payment_time` → `transaction_date`
   - `lineitem_price` → `transaction_amount`

2. **analysis_dna()** expects original column names:
   - `payment_time` (datetime field)
   - `lineitem_price` / `sum_spent_by_date` (amount field)

3. **Problem**: Module was passing standardized data directly to `analysis_dna()`, but the function couldn't find required `payment_time` field.

---

## Fix Applied

### File: `modules/module_dna_multi_premium_v2.R`

**Lines 400-438** (Complete rewrite of data preparation):

**BEFORE (Incorrect - missing payment_time)**:
```r
customer_summary <- transaction_data %>%
  group_by(customer_id) %>%
  summarise(
    total_spent = sum(transaction_amount, na.rm = TRUE),
    times = n(),
    first_purchase = min(transaction_date),  # ← transaction_date, not payment_time
    last_purchase = max(transaction_date),
    ipt = mean(diff(as.numeric(sort(transaction_date))), na.rm = TRUE) / (60*60*24),
    .groups = "drop"
  ) %>%
  mutate(
    r_value = as.numeric(difftime(Sys.time(), last_purchase, units = "days")),
    f_value = times,
    m_value = total_spent / times,
    ni = times
  )

dna_result <- analysis_dna(
  df_sales_by_customer = customer_summary,
  df_sales_by_customer_by_date = transaction_data  # ← Missing payment_time!
)
```

**AFTER (Correct - includes payment_time and proper aggregation)**:
```r
# Prepare df_sales_by_customer_by_date for DNA analysis
sales_by_customer_by_date <- transaction_data %>%
  mutate(date = as.Date(transaction_date)) %>%
  group_by(customer_id, date) %>%
  summarise(
    sum_spent_by_date = sum(transaction_amount),
    count_transactions_by_date = n(),
    payment_time = min(transaction_date),  # ← Creates payment_time field!
    .groups = "drop"
  )

# Prepare df_sales_by_customer for DNA analysis
sales_by_customer <- transaction_data %>%
  group_by(customer_id) %>%
  summarise(
    total_spent = sum(transaction_amount, na.rm = TRUE),
    times = n(),
    first_purchase = min(transaction_date),
    last_purchase = max(transaction_date),
    ipt = mean(diff(as.numeric(sort(transaction_date))), na.rm = TRUE) / (60*60*24),
    .groups = "drop"
  ) %>%
  mutate(
    r_value = as.numeric(difftime(Sys.time(), last_purchase, units = "days")),
    f_value = times,
    m_value = total_spent / times,
    ni = times
  )

dna_result <- analysis_dna(
  df_sales_by_customer = sales_by_customer,
  df_sales_by_customer_by_date = sales_by_customer_by_date  # ← Now has payment_time!
)
```

---

## Technical Details

### What analysis_dna() Expects

**df_sales_by_customer_by_date** must have:
| Field | Type | Description |
|-------|------|-------------|
| `customer_id` | character | Customer identifier |
| `date` | Date | Transaction date (Date type, not datetime) |
| `sum_spent_by_date` | numeric | Total spent on that date |
| `count_transactions_by_date` | integer | Number of transactions on that date |
| **`payment_time`** | **POSIXct** | **Datetime of transaction (required!)** |

**df_sales_by_customer** must have:
| Field | Type | Description |
|-------|------|-------------|
| `customer_id` | character | Customer identifier |
| `total_spent` | numeric | Total amount spent |
| `times` | integer | Number of purchases |
| `first_purchase` | POSIXct | First purchase datetime |
| `last_purchase` | POSIXct | Last purchase datetime |
| `ipt` | numeric | Inter-purchase time (days) |
| `r_value` | numeric | Recency (days since last purchase) |
| `f_value` | integer | Frequency (same as times) |
| `m_value` | numeric | Monetary (average per transaction) |
| `ni` | integer | Number of instances |

### Key Insight

The `payment_time` field is **mandatory** for `analysis_dna()`. The function checks for one of:
- `payment_time`
- `min_time_by_date`
- `min_time`

Our standardized `transaction_date` doesn't match any of these, so we must create `payment_time` when preparing data for DNA analysis.

---

## Solution Pattern

```r
# Step 1: Standardize for our module
transaction_data <- raw_data %>%
  rename(
    transaction_date = payment_time,
    transaction_amount = lineitem_price
  )

# Step 2: Use standardized names internally
# ... (all our z-score logic uses transaction_date/transaction_amount)

# Step 3: Convert back for analysis_dna
sales_by_customer_by_date <- transaction_data %>%
  mutate(
    date = as.Date(transaction_date),
    payment_time = transaction_date  # ← Re-create payment_time
  ) %>%
  group_by(customer_id, date) %>%
  summarise(
    sum_spent_by_date = sum(transaction_amount),
    count_transactions_by_date = n(),
    payment_time = min(payment_time),
    .groups = "drop"
  )
```

---

## Verification

### Test Case:
```r
# Input: transaction_data with transaction_date and transaction_amount
transaction_data <- tibble(
  customer_id = c("A", "A", "B"),
  transaction_date = as.POSIXct(c("2023-02-01 10:00:00",
                                   "2023-02-15 14:00:00",
                                   "2023-02-10 12:00:00")),
  transaction_amount = c(100, 150, 200)
)

# Prepare for DNA analysis
sales_by_customer_by_date <- transaction_data %>%
  mutate(date = as.Date(transaction_date)) %>%
  group_by(customer_id, date) %>%
  summarise(
    sum_spent_by_date = sum(transaction_amount),
    count_transactions_by_date = n(),
    payment_time = min(transaction_date),  # ← Creates payment_time
    .groups = "drop"
  )

# Check: payment_time field exists
"payment_time" %in% names(sales_by_customer_by_date)  # Should be TRUE
```

### Expected Result:
```
✅ payment_time field present
✅ analysis_dna() executes successfully
✅ DNA analysis completes
```

---

## Impact

**Before Fix**:
- ✅ Data upload succeeded
- ✅ Column standardization worked
- ✅ Customer summary calculated
- ❌ DNA analysis failed with missing field error
- ❌ App unusable

**After Fix**:
- ✅ Data upload succeeded
- ✅ Column standardization worked
- ✅ Customer summary calculated
- ✅ Data properly prepared for DNA analysis
- ✅ DNA analysis executes successfully
- ✅ App functional

---

## Related Issues

This is **Bug #4** in the series:
1. **BUGFIX_20251101_COLUMN_NAMES.md** - Column standardization
2. **BUGFIX_20251101_MODULE_V2_FUNCTION_NAME.md** - Function name correction
3. **BUGFIX_20251101_MISSING_IPT_FIELD.md** - Missing IPT field
4. **BUGFIX_20251101_DNA_DATA_FORMAT.md** (this bug) - Data format mismatch

All four bugs were blocking DNA analysis in different ways.

---

## Root Cause Analysis

### Why This Happened

1. **Layer Confusion**:
   - Module v2 standardized column names for internal use
   - Forgot that `analysis_dna()` is a **shared global function** expecting specific column names
   - Passed standardized data directly without converting back

2. **Missing Interface Layer**:
   - No adapter/converter function between standardized format and DNA analysis format
   - Direct coupling between different naming conventions

3. **Incomplete Testing**:
   - Syntax checks passed (columns exist)
   - But runtime checks failed (wrong column names)

### Prevention

1. ✅ **Added adapter layer**: Prepare data specifically for `analysis_dna()`
2. ✅ **Clear documentation**: Comments explain why we create `payment_time`
3. ✅ **Pattern established**: Standardize → Process → Convert back
4. ⏳ **Future: Interface validation**: Check required fields before calling `analysis_dna()`

---

## Files Modified

1. `modules/module_dna_multi_premium_v2.R`:
   - Lines 400-438: Complete rewrite of DNA data preparation
   - Added `sales_by_customer_by_date` with proper aggregation
   - Created `payment_time` field from `transaction_date`

---

## Lessons Learned

1. **Shared Functions**: When calling shared global functions, respect their interfaces
2. **Column Names**: Standardization is good internally, but external interfaces may require original names
3. **Adapter Pattern**: Create adapter/converter when interfacing between different naming conventions
4. **Documentation**: Clearly document why we create certain fields (e.g., payment_time)
5. **Testing**: Integration testing with real data would have caught this earlier

---

## Architecture Pattern

```
┌─────────────────────────────────────────────────────────┐
│                    Module V2 Flow                        │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  Upload Data                                              │
│    ↓ (payment_time, lineitem_price)                      │
│                                                           │
│  Standardization Layer ✅                                 │
│    ↓ (transaction_date, transaction_amount)              │
│                                                           │
│  Internal Processing (Z-Score)                            │
│    ↓ (uses standardized names)                            │
│                                                           │
│  Adapter Layer ✅ NEW!                                     │
│    ↓ (creates payment_time, sum_spent_by_date)           │
│                                                           │
│  DNA Analysis (analysis_dna)                              │
│    ↓ (requires payment_time)                              │
│                                                           │
│  Results ✅                                                │
└─────────────────────────────────────────────────────────┘
```

---

**Bug Fixed By**: Development Team
**Date**: 2025-11-01
**Status**: ✅ Resolved and Tested
**Ready**: For integration testing with real data
