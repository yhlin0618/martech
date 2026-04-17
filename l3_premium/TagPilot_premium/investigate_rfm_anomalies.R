################################################################################
# RFM Value Anomalies Investigation
# Purpose: Analyze why RFM segmentation shows unusual patterns
################################################################################

library(tidyverse)
library(lubridate)

cat("📊 RFM Value Anomalies Investigation\n")
cat("==========================================\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 1: Load Test Data
# ══════════════════════════════════════════════════════════════════════════

files <- list.files('test_data/KM_eg', pattern = '.csv$', full.names = TRUE)
all_data <- map_dfr(files, function(file) {
  read_csv(file, show_col_types = FALSE, col_types = cols(.default = "c"))
})

cat("✅ Loaded", nrow(all_data), "transactions from", length(files), "files\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 2: Transform Data
# ══════════════════════════════════════════════════════════════════════════

upload_data <- all_data %>%
  transmute(
    customer_id = `Buyer Email`,
    payment_time = ymd_hms(`Payments Date`),
    lineitem_price = as.numeric(`Item Price`)
  ) %>%
  filter(!is.na(customer_id), !is.na(payment_time), !is.na(lineitem_price), lineitem_price > 0)

cat("✅ Valid transactions:", nrow(upload_data), "\n")
cat("✅ Unique customers:", length(unique(upload_data$customer_id)), "\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 3: Date Range Analysis
# ══════════════════════════════════════════════════════════════════════════

cat("📅 Date Range Analysis:\n")
cat("  Min date:", as.character(min(upload_data$payment_time)), "\n")
cat("  Max date:", as.character(max(upload_data$payment_time)), "\n")
date_span <- as.numeric(difftime(max(upload_data$payment_time), min(upload_data$payment_time), units = "days"))
cat("  Span:", round(date_span, 1), "days (", round(date_span/30, 1), "months)\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 4: Calculate RFM Values (Simple Method)
# ══════════════════════════════════════════════════════════════════════════

time_now <- max(upload_data$payment_time)

customer_summary <- upload_data %>%
  group_by(customer_id) %>%
  summarise(
    ni = n(),
    first_purchase = min(payment_time),
    last_purchase = max(payment_time),
    r_value = as.numeric(difftime(time_now, last_purchase, units = "days")),
    f_value = ni / as.numeric(difftime(time_now, first_purchase, units = "days")) * 30,
    m_value = mean(lineitem_price),
    total_spent = sum(lineitem_price),
    .groups = "drop"
  )

cat("📈 R Value (Recency - Days since last purchase):\n")
cat("  Min:", round(min(customer_summary$r_value, na.rm = TRUE), 2), "\n")
cat("  P20:", round(quantile(customer_summary$r_value, 0.2, na.rm = TRUE), 2), "\n")
cat("  Median:", round(median(customer_summary$r_value, na.rm = TRUE), 2), "\n")
cat("  P80:", round(quantile(customer_summary$r_value, 0.8, na.rm = TRUE), 2), "\n")
cat("  Max:", round(max(customer_summary$r_value, na.rm = TRUE), 2), "\n\n")

cat("📈 F Value (Frequency - Purchases per 30 days):\n")
cat("  Min:", round(min(customer_summary$f_value, na.rm = TRUE), 2), "\n")
cat("  P20:", round(quantile(customer_summary$f_value, 0.2, na.rm = TRUE), 2), "\n")
cat("  Median:", round(median(customer_summary$f_value, na.rm = TRUE), 2), "\n")
cat("  P80:", round(quantile(customer_summary$f_value, 0.8, na.rm = TRUE), 2), "\n")
cat("  Max:", round(max(customer_summary$f_value, na.rm = TRUE), 2), "\n\n")

cat("📈 M Value (Monetary - Average transaction amount):\n")
cat("  Min:", round(min(customer_summary$m_value, na.rm = TRUE), 2), "\n")
cat("  P20:", round(quantile(customer_summary$m_value, 0.2, na.rm = TRUE), 2), "\n")
cat("  Median:", round(median(customer_summary$m_value, na.rm = TRUE), 2), "\n")
cat("  P80:", round(quantile(customer_summary$m_value, 0.8, na.rm = TRUE), 2), "\n")
cat("  Max:", round(max(customer_summary$m_value, na.rm = TRUE), 2), "\n\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 5: Segmentation Analysis
# ══════════════════════════════════════════════════════════════════════════

# R Segmentation
p80_r <- quantile(customer_summary$r_value, 0.8, na.rm = TRUE)
p20_r <- quantile(customer_summary$r_value, 0.2, na.rm = TRUE)

customer_summary <- customer_summary %>%
  mutate(
    r_segment = case_when(
      r_value <= p20_r ~ "最近買家",
      r_value <= p80_r ~ "一般買家",
      TRUE ~ "久未購買"
    )
  )

cat("🔍 R Value Segmentation (P20/P80 method):\n")
print(table(customer_summary$r_segment))
cat("\n")

# F Segmentation
p80_f <- quantile(customer_summary$f_value, 0.8, na.rm = TRUE)
p20_f <- quantile(customer_summary$f_value, 0.2, na.rm = TRUE)

customer_summary <- customer_summary %>%
  mutate(
    f_segment = case_when(
      f_value >= p80_f ~ "高頻買家",
      f_value >= p20_f ~ "中頻買家",
      TRUE ~ "低頻買家"
    )
  )

cat("🔍 F Value Segmentation (P20/P80 method):\n")
print(table(customer_summary$f_segment))
cat("\n")

# M Segmentation
p80_m <- quantile(customer_summary$m_value, 0.8, na.rm = TRUE)
p20_m <- quantile(customer_summary$m_value, 0.2, na.rm = TRUE)

customer_summary <- customer_summary %>%
  mutate(
    m_segment = case_when(
      m_value >= p80_m ~ "高消費",
      m_value >= p20_m ~ "中消費",
      TRUE ~ "低消費"
    )
  )

cat("🔍 M Value Segmentation (P20/P80 method):\n")
print(table(customer_summary$m_segment))
cat("\n")

# ══════════════════════════════════════════════════════════════════════════
# STEP 6: Identify Issues
# ══════════════════════════════════════════════════════════════════════════

cat("⚠️  IDENTIFIED ISSUES:\n")
cat("==========================================\n\n")

# Issue 1: R Value
if (median(customer_summary$r_value) < 10) {
  cat("❌ Issue #1: R Value is very small (median:", round(median(customer_summary$r_value), 1), "days)\n")
  cat("   Reason: Test data is from Feb 2023, but 'time_now' is max date in dataset\n")
  cat("   Impact: All customers appear very recent\n")
  cat("   Solution: Use current date (Sys.Date()) as reference point\n\n")
}

# Issue 2: F Value - Check if most are high frequency
high_freq_pct <- mean(customer_summary$f_segment == "高頻買家") * 100
if (high_freq_pct > 60) {
  cat("❌ Issue #2: F Value shows", round(high_freq_pct, 1), "% as high frequency\n")
  cat("   P80 threshold:", round(p80_f, 2), "\n")
  cat("   Reason: Many single-purchase customers in short timespan\n")
  cat("   Impact: Segmentation not meaningful\n\n")
}

# Issue 3: M Value - Check distribution
cat("📊 M Value Distribution Check:\n")
cat("   Count by segment:\n")
print(table(customer_summary$m_segment))
cat("\n")

# Issue 4: Single purchase customers
single_purchase_pct <- mean(customer_summary$ni == 1) * 100
cat("📊 Single Purchase Customers:", round(single_purchase_pct, 1), "%\n")
if (single_purchase_pct > 90) {
  cat("   ⚠️  Most customers only purchased once in test period\n")
  cat("   Impact: F and R values less meaningful for segmentation\n\n")
}

cat("\n✅ Investigation complete!\n")
