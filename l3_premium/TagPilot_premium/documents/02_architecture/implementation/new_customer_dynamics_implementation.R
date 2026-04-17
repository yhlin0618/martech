# ============================================================================
# New Customer Dynamics Calculation - Z-Score Based Methodology
# ============================================================================
# Version: 1.0
# Date: 2025-11-01
# Based on: 顧客動態計算方式調整_20251025.md
# Purpose: Replace fixed R-value thresholds with statistical z-score approach
# ============================================================================

library(dplyr)
library(lubridate)

# ============================================================================
# STEP 1: Calculate Industry Median Purchase Interval (μ_ind)
# ============================================================================

#' Calculate median purchase interval across all customers
#'
#' @param transaction_data Data frame with customer_id, transaction_date, transaction_amount
#' @return List containing μ_ind and other metadata
calculate_median_purchase_interval <- function(transaction_data) {

  # Validate input
  required_cols <- c("customer_id", "transaction_date", "transaction_amount")
  if (!all(required_cols %in% names(transaction_data))) {
    stop("Missing required columns: ",
         paste(setdiff(required_cols, names(transaction_data)), collapse = ", "))
  }

  # Calculate purchase intervals for each customer (ni >= 2)
  customer_intervals <- transaction_data %>%
    arrange(customer_id, transaction_date) %>%
    group_by(customer_id) %>%
    summarise(
      ni = n(),
      transaction_dates = list(transaction_date),
      .groups = "drop"
    ) %>%
    filter(ni >= 2) %>%
    rowwise() %>%
    mutate(
      # Calculate intervals between consecutive purchases
      intervals = list({
        dates <- sort(transaction_dates[[1]])
        if (length(dates) >= 2) {
          as.numeric(diff(dates), units = "days")
        } else {
          numeric(0)
        }
      })
    ) %>%
    ungroup()

  # Check if we have enough data
  if (nrow(customer_intervals) < 10) {
    warning(paste0(
      "Only ", nrow(customer_intervals),
      " customers with ni >= 2. Recommend at least 30 for reliable μ_ind calculation."
    ))
  }

  # Combine all intervals
  all_intervals <- unlist(customer_intervals$intervals)

  if (length(all_intervals) == 0) {
    stop("No purchase intervals found. Cannot calculate μ_ind.")
  }

  # Calculate median (μ_ind)
  mu_ind <- median(all_intervals, na.rm = TRUE)

  # Return metadata
  list(
    mu_ind = mu_ind,
    n_customers_with_intervals = nrow(customer_intervals),
    n_total_intervals = length(all_intervals),
    interval_summary = summary(all_intervals),
    interval_sd = sd(all_intervals, na.rm = TRUE)
  )
}

# ============================================================================
# STEP 2: Calculate Active Observation Window (W)
# ============================================================================

#' Calculate active observation window based on data span and μ_ind
#'
#' @param transaction_data Data frame with transaction_date
#' @param mu_ind Median purchase interval
#' @param k Tolerance multiplier (default: 2.5)
#' @param min_window Minimum window in days (default: 90)
#' @return Active observation window in days
calculate_active_window <- function(transaction_data, mu_ind, k = 2.5, min_window = 90) {

  # Calculate cap_days (observation period)
  cap_days <- as.numeric(
    max(transaction_data$transaction_date, na.rm = TRUE) -
    min(transaction_data$transaction_date, na.rm = TRUE),
    units = "days"
  ) + 1

  # Calculate theoretical window
  theoretical_window <- k * mu_ind

  # Round to nearest multiple of 7 (weekly basis)
  round_to_7 <- function(x) {
    round(x / 7) * 7
  }

  rounded_window <- round_to_7(theoretical_window)

  # Apply min and cap constraints
  W <- min(cap_days, max(min_window, rounded_window))

  # Return details
  list(
    W = W,
    cap_days = cap_days,
    theoretical_window = theoretical_window,
    rounded_window = rounded_window,
    formula = paste0("min(", cap_days, ", max(", min_window, ", ", rounded_window, "))")
  )
}

# ============================================================================
# STEP 3: Calculate Purchase Frequency in Window W
# ============================================================================

#' Count purchases for each customer in the most recent W days
#'
#' @param transaction_data Data frame with customer_id, transaction_date
#' @param W Active observation window in days
#' @param analysis_date Reference date (default: max transaction date)
#' @return Data frame with customer_id, F_i_w (purchase count in window)
calculate_purchase_frequency_in_window <- function(transaction_data, W,
                                                    analysis_date = NULL) {

  if (is.null(analysis_date)) {
    analysis_date <- max(transaction_data$transaction_date, na.rm = TRUE)
  }

  # Define window cutoff date
  window_start <- analysis_date - W

  # Count purchases in window for each customer
  customer_data <- transaction_data %>%
    group_by(customer_id) %>%
    summarise(
      # Total purchases ever
      ni = n(),

      # First and last purchase dates
      time_first = min(transaction_date, na.rm = TRUE),
      time_last = max(transaction_date, na.rm = TRUE),

      # Purchases in recent W days
      F_i_w = sum(transaction_date >= window_start & transaction_date <= analysis_date),

      # Customer age (days since first purchase)
      customer_age_days = as.numeric(analysis_date - time_first, units = "days"),

      # Recency (days since last purchase)
      recency = as.numeric(analysis_date - time_last, units = "days"),

      # Total monetary value
      m_value = sum(transaction_amount, na.rm = TRUE),

      .groups = "drop"
    )

  return(customer_data)
}

# ============================================================================
# STEP 4: Calculate Z-Scores
# ============================================================================

#' Calculate z-scores for purchase frequency (excluding newbies)
#'
#' @param customer_data Data frame with F_i_w, ni, customer_age_days
#' @param mu_ind Median purchase interval (for newbie definition)
#' @return Data frame with z_i and industry benchmarks
calculate_z_scores <- function(customer_data, mu_ind) {

  # Identify newbies: ni == 1 AND customer_age_days <= μ_ind
  customer_data <- customer_data %>%
    mutate(
      is_newbie = (ni == 1) & (customer_age_days <= mu_ind)
    )

  # Calculate industry benchmarks (EXCLUDE NEWBIES)
  non_newbies <- customer_data %>% filter(!is_newbie)

  if (nrow(non_newbies) < 10) {
    warning(paste0(
      "Only ", nrow(non_newbies),
      " non-newbie customers. Z-scores may be unreliable."
    ))
  }

  lambda_w <- mean(non_newbies$F_i_w, na.rm = TRUE)
  sigma_w <- sd(non_newbies$F_i_w, na.rm = TRUE)

  # Handle edge case: zero variance
  if (is.na(sigma_w) || sigma_w == 0) {
    warning("Standard deviation is zero or NA. All customers have same frequency. Using fallback logic.")
    sigma_w <- 1  # Avoid division by zero
  }

  # Calculate z-scores for ALL customers (including newbies)
  customer_data <- customer_data %>%
    mutate(
      z_i = (F_i_w - lambda_w) / sigma_w,

      # Store benchmarks for reference
      lambda_w = lambda_w,
      sigma_w = sigma_w
    )

  return(customer_data)
}

# ============================================================================
# STEP 5: Classify Customer Lifecycle Stage (New Method)
# ============================================================================

#' Classify customer lifecycle stage using z-score methodology
#'
#' @param customer_data Data frame with z_i, is_newbie, recency
#' @param mu_ind Median purchase interval (for recency guardrail)
#' @param use_recency_guardrail Whether to apply recency check for active customers
#' @return Data frame with lifecycle_stage
classify_lifecycle_stage_new <- function(customer_data, mu_ind,
                                         use_recency_guardrail = TRUE) {

  customer_data <- customer_data %>%
    mutate(
      lifecycle_stage = case_when(
        # 新客：ni == 1 AND customer_age_days <= μ_ind
        is_newbie ~ "newbie",

        # 主力客：z_i >= +0.5 (with optional recency guardrail)
        use_recency_guardrail & z_i >= 0.5 & recency <= mu_ind ~ "active",
        !use_recency_guardrail & z_i >= 0.5 ~ "active",

        # 瞌睡客：-1.0 <= z_i < +0.5
        z_i >= -1.0 ~ "sleepy",

        # 半睡客：-1.5 <= z_i < -1.0
        z_i >= -1.5 ~ "half_sleepy",

        # 沉睡客：z_i < -1.5
        TRUE ~ "dormant"
      ),

      # Add lifecycle stage explanation
      lifecycle_explanation = case_when(
        lifecycle_stage == "newbie" ~ paste0("新客 (首購 ≤ ", round(mu_ind), " 天)"),
        lifecycle_stage == "active" ~ paste0("主力客 (z-score = ", round(z_i, 2), " ≥ +0.5)"),
        lifecycle_stage == "sleepy" ~ paste0("瞌睡客 (z-score = ", round(z_i, 2), " 在 [-1.0, +0.5))"),
        lifecycle_stage == "half_sleepy" ~ paste0("半睡客 (z-score = ", round(z_i, 2), " 在 [-1.5, -1.0))"),
        lifecycle_stage == "dormant" ~ paste0("沉睡客 (z-score = ", round(z_i, 2), " < -1.5)"),
        TRUE ~ "未知"
      )
    )

  return(customer_data)
}

# ============================================================================
# STEP 6: Main Wrapper Function - Complete New Pipeline
# ============================================================================

#' Execute complete customer dynamics analysis using z-score methodology
#'
#' @param transaction_data Data frame with customer_id, transaction_date, transaction_amount
#' @param k Tolerance multiplier for window calculation (default: 2.5)
#' @param min_window Minimum observation window (default: 90 days)
#' @param use_recency_guardrail Apply recency check for active classification
#' @param analysis_date Reference date (default: max transaction date)
#' @return List containing customer_data and metadata
analyze_customer_dynamics_new <- function(transaction_data,
                                          k = 2.5,
                                          min_window = 90,
                                          use_recency_guardrail = TRUE,
                                          analysis_date = NULL) {

  # Validation
  if (nrow(transaction_data) < 100) {
    warning("Dataset has < 100 transactions. Results may be unreliable.")
  }

  # Step 1: Calculate μ_ind
  message("Step 1/5: Calculating median purchase interval (μ_ind)...")
  mu_result <- calculate_median_purchase_interval(transaction_data)
  mu_ind <- mu_result$mu_ind
  message(paste0("  ✓ μ_ind = ", round(mu_ind, 1), " days (based on ",
                mu_result$n_total_intervals, " intervals)"))

  # Step 2: Calculate W
  message("Step 2/5: Calculating active observation window (W)...")
  w_result <- calculate_active_window(transaction_data, mu_ind, k, min_window)
  W <- w_result$W
  message(paste0("  ✓ W = ", W, " days (", round(W/7), " weeks)"))
  message(paste0("  Formula: ", w_result$formula))

  # Step 3: Calculate F_i_w
  message("Step 3/5: Counting purchases in window W for each customer...")
  customer_data <- calculate_purchase_frequency_in_window(
    transaction_data, W, analysis_date
  )
  message(paste0("  ✓ Analyzed ", nrow(customer_data), " unique customers"))

  # Step 4: Calculate z-scores
  message("Step 4/5: Computing z-scores...")
  customer_data <- calculate_z_scores(customer_data, mu_ind)
  message(paste0("  ✓ λ_w (avg purchases in window) = ", round(customer_data$lambda_w[1], 2)))
  message(paste0("  ✓ σ_w (std dev) = ", round(customer_data$sigma_w[1], 2)))

  # Step 5: Classify lifecycle stages
  message("Step 5/5: Classifying customer lifecycle stages...")
  customer_data <- classify_lifecycle_stage_new(
    customer_data, mu_ind, use_recency_guardrail
  )

  # Summary statistics
  stage_summary <- customer_data %>%
    group_by(lifecycle_stage) %>%
    summarise(
      count = n(),
      percentage = round(n() / nrow(customer_data) * 100, 1),
      avg_z_score = round(mean(z_i, na.rm = TRUE), 2),
      .groups = "drop"
    ) %>%
    arrange(desc(count))

  message("\n=== Classification Summary ===")
  print(stage_summary)

  # Return results
  list(
    customer_data = customer_data,
    metadata = list(
      mu_ind = mu_ind,
      W = W,
      lambda_w = customer_data$lambda_w[1],
      sigma_w = customer_data$sigma_w[1],
      analysis_date = analysis_date %||% max(transaction_data$transaction_date),
      n_customers = nrow(customer_data),
      n_newbies = sum(customer_data$is_newbie),
      stage_summary = stage_summary,
      mu_result = mu_result,
      w_result = w_result
    )
  )
}

# ============================================================================
# LEGACY METHOD: Old Fixed R-Value Thresholds (for comparison)
# ============================================================================

#' Classify customer lifecycle stage using OLD fixed threshold method
#'
#' @param customer_data Data frame with recency, ni
#' @return Data frame with lifecycle_stage_old
classify_lifecycle_stage_old <- function(customer_data) {

  customer_data %>%
    mutate(
      lifecycle_stage_old = case_when(
        is.na(recency) ~ "unknown",
        ni == 1 ~ "newbie",
        recency <= 7 ~ "active",
        recency <= 14 ~ "sleepy",
        recency <= 21 ~ "half_sleepy",
        TRUE ~ "dormant"
      )
    )
}

# ============================================================================
# COMPARISON FUNCTION: Old vs New Classification
# ============================================================================

#' Compare old and new lifecycle classification methods
#'
#' @param transaction_data Transaction data
#' @param use_recency_guardrail Apply guardrail in new method
#' @return Comparison results
compare_lifecycle_methods <- function(transaction_data,
                                      use_recency_guardrail = TRUE) {

  message("\n========================================")
  message("COMPARING OLD vs NEW METHODOLOGY")
  message("========================================\n")

  # Run new method
  new_results <- analyze_customer_dynamics_new(
    transaction_data,
    use_recency_guardrail = use_recency_guardrail
  )

  customer_data <- new_results$customer_data

  # Run old method
  customer_data <- classify_lifecycle_stage_old(customer_data)

  # Create comparison table
  comparison <- customer_data %>%
    group_by(lifecycle_stage, lifecycle_stage_old) %>%
    summarise(count = n(), .groups = "drop") %>%
    tidyr::pivot_wider(
      names_from = lifecycle_stage_old,
      values_from = count,
      values_fill = 0
    )

  message("\n=== Cross-Classification Matrix ===")
  message("Rows: NEW method | Columns: OLD method\n")
  print(comparison)

  # Calculate agreement rate
  agreement <- customer_data %>%
    summarise(
      total = n(),
      matched = sum(lifecycle_stage == lifecycle_stage_old),
      agreement_rate = round(matched / total * 100, 1)
    )

  message(paste0("\nAgreement Rate: ", agreement$agreement_rate, "% (",
                agreement$matched, "/", agreement$total, " customers)"))

  # Find customers with different classifications
  differences <- customer_data %>%
    filter(lifecycle_stage != lifecycle_stage_old) %>%
    select(customer_id, ni, recency, F_i_w, z_i,
           lifecycle_stage_old, lifecycle_stage, lifecycle_explanation) %>%
    arrange(desc(abs(z_i)))

  if (nrow(differences) > 0) {
    message(paste0("\n", nrow(differences), " customers have different classifications."))
    message("Top 10 largest differences:\n")
    print(head(differences, 10))
  }

  list(
    customer_data = customer_data,
    comparison_matrix = comparison,
    agreement = agreement,
    differences = differences,
    metadata = new_results$metadata
  )
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

#' Null coalescing operator
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Generate diagnostic plots
plot_lifecycle_distribution <- function(results) {
  library(ggplot2)

  # Plot 1: Lifecycle stage distribution
  p1 <- results$metadata$stage_summary %>%
    ggplot(aes(x = reorder(lifecycle_stage, -count), y = count, fill = lifecycle_stage)) +
    geom_col() +
    geom_text(aes(label = paste0(count, "\n(", percentage, "%)")),
              vjust = -0.5, size = 3) +
    labs(title = "Customer Lifecycle Distribution (New Method)",
         x = "Lifecycle Stage", y = "Number of Customers") +
    theme_minimal() +
    theme(legend.position = "none")

  # Plot 2: Z-score distribution
  p2 <- results$customer_data %>%
    filter(!is_newbie) %>%
    ggplot(aes(x = z_i, fill = lifecycle_stage)) +
    geom_histogram(bins = 30, alpha = 0.7) +
    geom_vline(xintercept = c(-1.5, -1.0, 0.5), linetype = "dashed", color = "red") +
    labs(title = "Z-Score Distribution by Lifecycle Stage",
         x = "Z-Score", y = "Count",
         caption = "Red lines: classification thresholds") +
    theme_minimal()

  list(p1 = p1, p2 = p2)
}

# ============================================================================
# EXAMPLE USAGE
# ============================================================================

if (FALSE) {
  # Example: Load your transaction data
  transaction_data <- read.csv("customer_transactions.csv") %>%
    mutate(transaction_date = as.Date(transaction_date))

  # Run new analysis
  results <- analyze_customer_dynamics_new(transaction_data)

  # Access results
  customer_classifications <- results$customer_data
  metadata <- results$metadata

  # Compare with old method
  comparison <- compare_lifecycle_methods(transaction_data)

  # Generate plots
  plots <- plot_lifecycle_distribution(results)
  plots$p1
  plots$p2
}
