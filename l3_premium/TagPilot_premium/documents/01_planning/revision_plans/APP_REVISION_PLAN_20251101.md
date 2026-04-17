# TagPilot Premium - Comprehensive App Revision Plan

**Document Version**: 1.0
**Created**: 2025-11-01
**Purpose**: Implementation roadmap for z-score based customer dynamics methodology
**Based on**:
- `logic_revised.md` (5 modification requests)
- `顧客動態計算方式調整_20251025.md` (new z-score methodology)
- Current implementation analysis

---

## 📋 Executive Summary

This plan outlines the migration from **fixed R-value thresholds** to **statistical z-score based customer dynamics classification**, addressing all 5 modifications flagged in `logic_revised.md`.

### Key Changes
1. ✅ **Replace fixed thresholds (7/14/21 days)** → Z-score based classification
2. ✅ **Remove activity degradation strategy** → Strict ni ≥ 4 requirement
3. ✅ **Enable RFM for all customers** → Remove ni ≥ 4 restriction
4. ✅ **Update newbie definition** → ni == 1 AND customer_age ≤ μ_ind
5. ✅ **Implement "remaining time" prediction** → New next purchase date logic

---

## 🎯 Modification Mapping

| Modification | Description | Status | Priority | Estimated Effort |
|--------------|-------------|--------|----------|------------------|
| **修改1** | 顧客動態公式調整 (Z-score) | ⚠️ Major | P0 | 5 days |
| **修改2** | RFM分數計算 (remove ni<4 restriction) | ✅ Simple | P1 | 1 day |
| **修改3** | 下次購買日期預測 (remaining time) | ⚠️ Medium | P2 | 2 days |
| **修改4** | 顧客動態公式配置化 | ✅ Enhancement | P2 | 1 day |
| **修改5** | 硬編碼閾值改為參數 | ✅ Enhancement | P3 | 1 day |

**Total Estimated Effort**: 10 working days

---

## 📐 Architecture Changes

### Change 1: Customer Dynamics Calculation (修改1 & 修改4 & 修改5)

#### Current Implementation
```r
# File: modules/module_dna_multi_premium.R
# Lines: 383-415

lifecycle_stage = case_when(
  is.na(r_value) ~ "unknown",
  ni == 1 ~ "newbie",                    # ❌ Too simple
  r_value <= 7 ~ "active",                # ❌ Fixed threshold
  r_value <= 14 ~ "sleepy",               # ❌ Fixed threshold
  r_value <= 21 ~ "half_sleepy",          # ❌ Fixed threshold
  TRUE ~ "dormant"
)
```

#### New Implementation (Z-Score Based)
```r
# File: modules/module_dna_multi_premium.R
# New function to be created

calculate_customer_dynamics <- function(customer_data, transaction_data) {

  # Step 1: Calculate μ_ind (median purchase interval)
  mu_ind <- calculate_median_purchase_interval(transaction_data)

  # Step 2: Calculate W (active observation window)
  W <- calculate_active_window(transaction_data, mu_ind, k = 2.5, min_window = 90)

  # Step 3: Count purchases in window W
  customer_data <- customer_data %>%
    mutate(F_i_w = count_purchases_in_window(transaction_date, W))

  # Step 4: Calculate z-scores (exclude newbies)
  non_newbies <- customer_data %>%
    filter(!(ni == 1 & customer_age_days <= mu_ind))

  lambda_w <- mean(non_newbies$F_i_w)
  sigma_w <- sd(non_newbies$F_i_w)

  customer_data <- customer_data %>%
    mutate(
      z_i = (F_i_w - lambda_w) / sigma_w,

      # Step 5: Classify lifecycle stage
      lifecycle_stage = case_when(
        is.na(recency) ~ "unknown",

        # New: ni == 1 AND customer_age_days <= μ_ind
        ni == 1 & customer_age_days <= mu_ind ~ "newbie",

        # Z-score based classification (with optional recency guardrail)
        z_i >= 0.5 & recency <= mu_ind ~ "active",
        z_i >= -1.0 ~ "sleepy",
        z_i >= -1.5 ~ "half_sleepy",
        TRUE ~ "dormant"
      )
    )

  return(list(
    customer_data = customer_data,
    mu_ind = mu_ind,
    W = W,
    lambda_w = lambda_w,
    sigma_w = sigma_w
  ))
}
```

**Files to Modify**:
- `modules/module_dna_multi_premium.R` (Lines 383-488)
- `scripts/global_scripts/functions/fn_analysis_dna.R` (if DNA calculation is there)

**Impact**:
- ✅ Industry-adaptive thresholds
- ✅ Configurable parameters (k, min_window)
- ✅ Statistical rigor
- ⚠️ Requires sufficient data (recommend 365+ days, 50+ customers with ni≥2)

---

### Change 2: Activity Level Calculation (修改1 - Part 2)

#### Current Implementation
```r
# Lines 438-488: Two-tier strategy

# Tier 1: ni >= 4, use CAI
activity_level = case_when(
  cai_ecdf >= 0.8 ~ "高",
  cai_ecdf >= 0.2 ~ "中",
  TRUE ~ "低"
)

# Tier 2: ni < 4 (non-newbie), use r_value degradation
activity_level = case_when(
  r_value <= quantile(r_value, 0.2) ~ "高",
  r_value <= quantile(r_value, 0.8) ~ "中",
  TRUE ~ "低"
)
```

#### New Implementation (Strict ni ≥ 4)
```r
# Simplified: Only ni >= 4 customers get activity_level

activity_level = case_when(
  ni < 4 ~ NA_character_,  # All ni < 4 → NA

  # Only for ni >= 4
  cai_ecdf >= 0.8 ~ "高",
  cai_ecdf >= 0.2 ~ "中",
  TRUE ~ "低"
)
```

**Files to Modify**:
- `modules/module_dna_multi_premium.R` (Lines 438-488)
- Remove entire degradation logic section (50+ lines)

**Impact**:
- ❌ **40% of customers** will have `activity_level = NA`
- ❌ Cannot be placed in 9-grid framework
- ✅ Simpler logic, no degradation strategy
- ⚠️ **Breaking change** - need fallback UI for ni < 4 customers

**UI Changes Required**:
```r
# Update warning message
output$activity_warning <- renderUI({
  div(
    class = "alert alert-info",
    icon("info-circle"),
    " CAI（客戶活躍度指數）只針對交易次數 ≥ 4 的客戶計算。",
    "交易次數不足的客戶用NA表示"  # Updated message
  )
})
```

---

### Change 3: RFM Score Calculation (修改2)

#### Current Implementation
```r
# Lines 608-752: RFM only for ni >= 4

calculate_rfm_scores <- function(customer_data) {
  customer_data_filtered <- customer_data %>% filter(ni >= 4)

  # Calculate R/F/M scores
  # ...
}
```

#### New Implementation (All Customers)
```r
# Remove ni >= 4 filter

calculate_rfm_scores <- function(customer_data) {
  # Calculate for ALL customers (no filtering)

  customer_data %>%
    mutate(
      # Quintile-based scoring (all customers included)
      r_score = ntile(desc(recency), 5),
      f_score = ntile(ni, 5),
      m_score = ntile(m_value, 5),

      rfm_total_score = r_score + f_score + m_score
    )
}
```

**Files to Modify**:
- `modules/module_rfm_analysis.R` (Lines 608-752)
- Update tag documentation (tag_012 now applies to all customers)

**Impact**:
- ✅ All customers get RFM scores
- ✅ More complete analysis
- ⚠️ Newbies will have low F scores (expected)

**Rationale**:
- RFM is independent of CAI
- No statistical reliability issue with R/F/M values
- Newbies naturally score low on F (frequency), which is correct

---

### Change 4: Next Purchase Date Prediction (修改3)

#### Current Implementation
```r
# Simple: today + avg_ipt

tag_031_next_purchase_date = as.Date(Sys.time()) + avg_ipt
```

#### New Implementation ("Remaining Time" Approach)
```r
# Based on remaining cycle time

calculate_next_purchase_date <- function(customer_data) {
  customer_data %>%
    mutate(
      # Calculate how much time has elapsed since last purchase
      time_elapsed = recency,  # days since last purchase

      # Calculate expected cycle (use μ_ind or customer's own avg_ipt)
      expected_cycle = ifelse(ni >= 2, avg_ipt, mu_ind),

      # Remaining time in current cycle
      remaining_time = pmax(0, expected_cycle - time_elapsed),

      # Predicted next purchase date
      # If already overdue (remaining_time = 0), predict one full cycle ahead
      next_purchase_date = case_when(
        remaining_time > 0 ~ as.Date(Sys.time()) + remaining_time,
        TRUE ~ as.Date(Sys.time()) + expected_cycle
      ),

      # Tag with explanation
      tag_031_next_purchase_date = next_purchase_date,
      tag_031_explanation = case_when(
        remaining_time > 0 ~ paste0("預計 ", round(remaining_time), " 天後 (週期剩餘時間)"),
        TRUE ~ paste0("已逾期，預計 ", round(expected_cycle), " 天後 (下個週期)")
      )
    )
}
```

**Formula Breakdown**:
```
Scenario 1: Customer on schedule
- Last purchase: 10 days ago
- Avg cycle: 30 days
- Remaining time: 30 - 10 = 20 days
- Next purchase: Today + 20 days

Scenario 2: Customer overdue
- Last purchase: 50 days ago
- Avg cycle: 30 days
- Remaining time: 30 - 50 = -20 → 0 (overdue)
- Next purchase: Today + 30 days (full cycle ahead)
```

**Files to Modify**:
- `modules/module_lifecycle_prediction.R` (Lines 1274-1400)

**Impact**:
- ✅ More realistic predictions
- ✅ Accounts for customers who are overdue
- ✅ Better aligns with actual behavior

---

### Change 5: Terminology Updates

| Old Term | New Term |
|----------|----------|
| 生命週期階段 | 顧客動態 |
| DNA分析 | SDNA分析 |
| 逐漸活躍/逐漸不活躍 | 漸趨活躍/穩定消費/漸趨靜止 |

**Files to Modify**:
- All module files
- UI text strings
- Tag labels
- Documentation

**Search & Replace**:
```bash
# In all R files
sed -i 's/生命週期階段/顧客動態/g' modules/*.R
sed -i 's/lifecycle_stage/customer_dynamics/g' modules/*.R  # Optional: variable rename
```

---

## 📊 Data Validation Requirements

### Minimum Data Requirements

| Requirement | Threshold | Validation |
|-------------|-----------|------------|
| **Observation Period** | ≥ 365 days | `cap_days >= 365` |
| **Total Customers** | ≥ 100 | `n_distinct(customer_id) >= 100` |
| **Customers with ni ≥ 2** | ≥ 30 | `sum(ni >= 2) >= 30` |
| **Total Transactions** | ≥ 500 | `nrow(transaction_data) >= 500` |

### Validation Function
```r
validate_data_requirements <- function(transaction_data) {

  # Calculate metrics
  cap_days <- as.numeric(max(transaction_data$transaction_date) -
                         min(transaction_data$transaction_date)) + 1
  n_customers <- n_distinct(transaction_data$customer_id)
  n_transactions <- nrow(transaction_data)

  customer_counts <- transaction_data %>%
    group_by(customer_id) %>%
    summarise(ni = n())

  n_with_repeat <- sum(customer_counts$ni >= 2)

  # Check requirements
  checks <- list(
    observation_period = list(
      value = cap_days,
      threshold = 365,
      passed = cap_days >= 365,
      message = paste0("觀察期: ", cap_days, " 天 (需要 ≥ 365 天)")
    ),
    total_customers = list(
      value = n_customers,
      threshold = 100,
      passed = n_customers >= 100,
      message = paste0("總客戶數: ", n_customers, " (建議 ≥ 100)")
    ),
    repeat_customers = list(
      value = n_with_repeat,
      threshold = 30,
      passed = n_with_repeat >= 30,
      message = paste0("回購客戶: ", n_with_repeat, " (需要 ≥ 30 才能計算可靠的 μ_ind)")
    ),
    total_transactions = list(
      value = n_transactions,
      threshold = 500,
      passed = n_transactions >= 500,
      message = paste0("總交易數: ", n_transactions, " (建議 ≥ 500)")
    )
  )

  # Overall pass/fail
  all_passed <- all(sapply(checks, function(x) x$passed))

  # Print results
  cat("\n=== 資料驗證結果 ===\n\n")
  for (check_name in names(checks)) {
    check <- checks[[check_name]]
    status <- if (check$passed) "✅" else "❌"
    cat(status, check$message, "\n")
  }

  if (!all_passed) {
    cat("\n⚠️ 警告: 部分資料要求未達標，分析結果可能不可靠。\n")
  } else {
    cat("\n✅ 所有資料要求均已滿足，可進行分析。\n")
  }

  invisible(list(
    checks = checks,
    all_passed = all_passed
  ))
}
```

---

## 🔄 Migration Strategy

### Phase 1: Preparation (Week 1)

**Tasks**:
1. ✅ Create new implementation file (`new_customer_dynamics_implementation.R`)
2. Create test dataset with known characteristics
3. Run validation checks on test data
4. Establish baseline metrics with old method

**Deliverables**:
- Working implementation code
- Test data validation report
- Baseline comparison metrics

---

### Phase 2: Core Implementation (Week 2)

**Tasks**:
1. **Modify `module_dna_multi_premium.R`**:
   - Integrate z-score calculation functions
   - Replace lifecycle_stage logic (Lines 383-415)
   - Update activity_level logic (Lines 438-488)
   - Add data validation checks

2. **Modify `module_rfm_analysis.R`**:
   - Remove ni >= 4 filter (Lines 608-620)
   - Update documentation (Lines 760-780)

3. **Modify `module_lifecycle_prediction.R`**:
   - Implement remaining time algorithm (Lines 1274-1320)
   - Update tag_031 calculation

4. **Create configuration file** (`config/customer_dynamics_config.yaml`):
```yaml
customer_dynamics:
  method: "z_score"  # Options: "z_score", "fixed_threshold", "auto"

  z_score_params:
    k: 2.5                    # Tolerance multiplier for W calculation
    min_window: 90            # Minimum observation window (days)
    use_recency_guardrail: true

  fixed_threshold_params:   # Legacy fallback
    active_threshold: 7
    sleepy_threshold: 14
    half_sleepy_threshold: 21

  validation:
    min_observation_days: 365
    min_customers: 100
    min_repeat_customers: 30
    min_transactions: 500

  fallback_behavior: "warn_and_continue"  # Options: "warn_and_continue", "error", "use_fixed"
```

**Deliverables**:
- Updated module files
- Configuration system
- Unit tests for each function

---

### Phase 3: UI Updates (Week 3)

**Tasks**:
1. **Update warning messages**:
   - Change activity warning text
   - Add data validation warnings

2. **Add metadata displays**:
   - Show μ_ind in UI
   - Show W (observation window)
   - Show λ_w and σ_w benchmarks

3. **Update tag labels**:
   - Rename "生命週期" → "顧客動態"
   - Update tag explanations

4. **Add diagnostic tab** (optional):
   - Show z-score distribution
   - Show lifecycle stage transitions
   - Compare old vs new classifications

**UI Code Example**:
```r
# Add to sidebar or info panel
output$dynamics_metadata <- renderUI({
  req(customer_dynamics_results())

  metadata <- customer_dynamics_results()$metadata

  tagList(
    h4("分析參數"),
    tags$ul(
      tags$li(paste0("中位購買間隔 (μ_ind): ", round(metadata$mu_ind, 1), " 天")),
      tags$li(paste0("活躍觀察窗 (W): ", metadata$W, " 天 (", round(metadata$W/7), " 週)")),
      tags$li(paste0("平均窗口購買次數 (λ_w): ", round(metadata$lambda_w, 2))),
      tags$li(paste0("標準差 (σ_w): ", round(metadata$sigma_w, 2)))
    )
  )
})
```

**Deliverables**:
- Updated UI components
- New diagnostic visualizations
- User documentation updates

---

### Phase 4: Testing & Validation (Week 4)

**Test Cases**:

1. **Unit Tests**:
   - μ_ind calculation correctness
   - W calculation edge cases (cap_days < 90, etc.)
   - Z-score calculation accuracy
   - Classification logic

2. **Integration Tests**:
   - Full pipeline with real data
   - Old vs new method comparison
   - Performance benchmarks

3. **Edge Case Tests**:
   - Small datasets (< 100 customers)
   - Short observation periods (< 365 days)
   - All customers have same frequency (σ_w = 0)
   - No repeat customers (all ni = 1)

4. **User Acceptance Tests**:
   - Classification makes business sense
   - UI displays correctly
   - Error messages are helpful

**Test Data Scenarios**:
```r
# Test Scenario 1: Ideal dataset
test_data_ideal <- generate_test_data(
  n_customers = 1000,
  observation_days = 730,
  avg_purchase_interval = 30,
  repeat_rate = 0.7
)

# Test Scenario 2: Minimal dataset
test_data_minimal <- generate_test_data(
  n_customers = 50,
  observation_days = 365,
  avg_purchase_interval = 60,
  repeat_rate = 0.4
)

# Test Scenario 3: Edge case (all newbies)
test_data_newbies <- generate_test_data(
  n_customers = 200,
  observation_days = 90,
  avg_purchase_interval = 30,
  repeat_rate = 0.0  # No one has purchased twice
)
```

**Deliverables**:
- Test suite with 50+ test cases
- Validation report
- Performance benchmarks
- Edge case handling documentation

---

## 📈 Success Metrics

### Technical Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Agreement with old method** | 60-80% | Cross-classification matrix |
| **μ_ind calculation time** | < 1 second | Benchmark |
| **Full analysis time** | < 5 seconds | End-to-end pipeline |
| **Memory usage** | < 500 MB | For 10,000 customers |
| **Test coverage** | > 80% | Unit + integration tests |

### Business Metrics

| Metric | Target | Validation |
|--------|--------|------------|
| **Newbie identification accuracy** | > 90% | Manual review of 100 samples |
| **Active customer precision** | > 85% | Compare with recent purchasers |
| **Dormant customer recall** | > 90% | No false actives |
| **User comprehension** | > 80% | User survey on z-score explanation |

### Data Quality Gates

| Gate | Requirement | Action if Failed |
|------|-------------|------------------|
| **Gate 1: Data Volume** | cap_days ≥ 365, n_customers ≥ 100 | Show error, prevent analysis |
| **Gate 2: Repeat Customers** | ni ≥ 2 count ≥ 30 | Show warning, offer fixed method |
| **Gate 3: Z-Score Validity** | σ_w > 0 | Fallback to fixed thresholds |
| **Gate 4: Classification Coverage** | > 95% customers classified | Investigate unknowns |

---

## ⚠️ Risk Assessment

### High Risk Items

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Insufficient data for μ_ind** | ❌ Analysis fails | Medium | Add fallback to fixed thresholds |
| **40% customers lose activity_level** | ⚠️ UI gaps | High | Design special UI for ni < 4 |
| **Z-scores confusing to users** | ⚠️ Low adoption | Medium | Add explanatory tooltips |
| **Breaking changes in modules** | ❌ Downstream failures | Medium | Comprehensive testing |

### Medium Risk Items

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| **Performance degradation** | ⚠️ Slow UI | Low | Optimize calculations, add caching |
| **Different results vs old method** | ⚠️ User confusion | High | Show comparison mode |
| **Configuration complexity** | ⚠️ Setup errors | Medium | Provide sensible defaults |

### Mitigation Strategies

1. **Gradual Rollout**:
   - Add feature flag: `use_new_dynamics = FALSE` (default)
   - Allow A/B testing: show both old and new side-by-side
   - Collect user feedback before full switch

2. **Fallback Mechanism**:
```r
calculate_customer_dynamics_safe <- function(customer_data, transaction_data, config) {

  # Try new method
  tryCatch({
    # Validate data
    validation <- validate_data_requirements(transaction_data)

    if (!validation$all_passed && config$fallback_behavior == "error") {
      stop("Data requirements not met. See validation report.")
    }

    if (!validation$all_passed && config$fallback_behavior == "use_fixed") {
      warning("Using fixed threshold method due to insufficient data.")
      return(calculate_lifecycle_old(customer_data))
    }

    # Proceed with new method
    result <- analyze_customer_dynamics_new(transaction_data, ...)

    # Success
    attr(result, "method") <- "z_score"
    return(result)

  }, error = function(e) {
    # Fallback to old method
    warning(paste("New method failed:", e$message, "Using fixed thresholds."))
    result <- calculate_lifecycle_old(customer_data)
    attr(result, "method") <- "fixed_threshold"
    return(result)
  })
}
```

3. **User Education**:
   - Add help documentation explaining z-scores
   - Provide example scenarios
   - Create video tutorial

---

## 📝 Documentation Updates Required

### Code Documentation
- [ ] Add roxygen2 documentation to all new functions
- [ ] Update function parameter descriptions
- [ ] Add examples to each function

### User Documentation
- [ ] Update `logic_revised.md` with implemented changes
- [ ] Create "What's New" guide for users
- [ ] Update FAQ with z-score explanation

### Technical Documentation
- [ ] Update architecture diagram
- [ ] Document new data flow
- [ ] Add troubleshooting guide

### Training Materials
- [ ] Create user training slides
- [ ] Record demo video
- [ ] Prepare migration guide for existing users

---

## 🎯 Implementation Checklist

### Week 1: Preparation
- [x] Draft R implementation code
- [ ] Create test datasets
- [ ] Run baseline metrics with old method
- [ ] Set up version control branch

### Week 2: Core Development
- [ ] Implement μ_ind calculation
- [ ] Implement W calculation
- [ ] Implement z-score calculation
- [ ] Implement new lifecycle classification
- [ ] Update RFM module (remove ni ≥ 4 filter)
- [ ] Implement remaining time prediction
- [ ] Create configuration system
- [ ] Write unit tests

### Week 3: UI & Integration
- [ ] Update UI warning messages
- [ ] Add metadata displays
- [ ] Update tag labels and terminology
- [ ] Create diagnostic visualizations
- [ ] Integrate with existing modules
- [ ] Test end-to-end flow

### Week 4: Testing & Deployment
- [ ] Run full test suite
- [ ] Perform user acceptance testing
- [ ] Generate validation reports
- [ ] Update documentation
- [ ] Deploy to staging environment
- [ ] Collect feedback
- [ ] Deploy to production (with feature flag)

---

## 🚀 Deployment Plan

### Stage 1: Internal Testing (Week 4)
- Deploy to internal staging server
- Test with real customer data (anonymized)
- Gather feedback from product team

### Stage 2: Beta Release (Week 5)
- Enable for select beta users via feature flag
- Monitor performance and errors
- Collect user feedback via survey

### Stage 3: Gradual Rollout (Week 6)
- Enable for 25% of users
- Monitor metrics (error rates, performance)
- Address any issues

### Stage 4: Full Release (Week 7)
- Enable for all users
- Announce via email/blog post
- Monitor support tickets

### Stage 5: Cleanup (Week 8)
- Remove old method code (if stable)
- Remove feature flag
- Archive old documentation

---

## 📞 Support Plan

### User Support
- Create FAQ document
- Set up support email alias
- Train support team on new methodology

### Technical Support
- Document common error scenarios
- Create debugging guide
- Set up monitoring alerts

### Escalation Path
```
Level 1: User Documentation / FAQ
   ↓
Level 2: Support Team (email/chat)
   ↓
Level 3: Product Manager
   ↓
Level 4: Development Team
```

---

## 📊 Monitoring & Analytics

### Metrics to Track
- [ ] Daily active users using new method
- [ ] Error rate (by error type)
- [ ] Average calculation time
- [ ] Data validation failure rate
- [ ] User feedback scores
- [ ] Classification distribution changes

### Dashboards to Create
1. **Usage Dashboard**: Adoption rate, user engagement
2. **Performance Dashboard**: Response times, error rates
3. **Quality Dashboard**: Classification accuracy, data validation results

---

## 🔄 Rollback Plan

If critical issues arise:

### Triggers for Rollback
- Error rate > 5%
- Performance degradation > 50%
- Critical bug affecting > 10% of users
- Data accuracy issues confirmed

### Rollback Procedure
```r
# 1. Set feature flag to FALSE
config$use_new_dynamics <- FALSE

# 2. Restart app servers
# 3. Notify users via banner
# 4. Investigate root cause
# 5. Fix and re-deploy
```

### Communication Plan
- Send email to affected users
- Post status update on website
- Update support documentation

---

## 📅 Timeline Summary

| Week | Focus | Key Deliverables |
|------|-------|------------------|
| **1** | Preparation | Test data, baseline metrics, branch setup |
| **2** | Core Development | New functions, RFM update, configuration |
| **3** | UI & Integration | Updated UI, diagnostics, end-to-end testing |
| **4** | Testing | Test suite, validation report, staging deploy |
| **5** | Beta | Beta user feedback, monitoring |
| **6** | Rollout | Gradual release, monitoring |
| **7** | Full Release | 100% rollout, announcements |
| **8** | Cleanup | Code cleanup, documentation archive |

**Total Duration**: 8 weeks
**Resource Requirements**: 1 developer + 1 QA + 0.5 PM

---

## 🎓 Key Learnings & Best Practices

### Do's ✅
- Start with comprehensive testing
- Provide clear error messages
- Offer fallback mechanisms
- Document everything
- Gather user feedback early

### Don'ts ❌
- Don't force new method on insufficient data
- Don't remove old code until new method is stable
- Don't skip validation checks
- Don't deploy without feature flag
- Don't assume users understand z-scores

---

## 📚 References

1. **顧客動態計算方式調整_20251025.md** - New methodology specification
2. **logic_revised.md** - Modification requests
3. **Business_Logic_Implementation_Details.md** - Current implementation details
4. **new_customer_dynamics_implementation.R** - R implementation code
5. **GAP001_NEWBIE_DEFINITION_ANALYSIS.md** - Previous newbie fix documentation

---

## ✅ Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| **Product Owner** | _______________ | ___/___/___ | _________ |
| **Lead Developer** | _______________ | ___/___/___ | _________ |
| **QA Lead** | _______________ | ___/___/___ | _________ |
| **Data Scientist** | _______________ | ___/___/___ | _________ |

---

**Document Status**: ✅ Draft Complete
**Next Action**: Review with product team
**Last Updated**: 2025-11-01
**Maintained By**: Development Team
