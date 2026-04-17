# ============================================================================
# Customer Dynamics Configuration
# ============================================================================
#
# Purpose: Centralized configuration for z-score based customer dynamics
#          classification in TagPilot Premium
#
# Usage:
#   source("config/customer_dynamics_config.R")
#   config <- get_customer_dynamics_config()
#
# Date Created: 2025-11-01
# Last Updated: 2025-11-01
#
# ============================================================================

# ----------------------------------------------------------------------------
# Main Configuration Object
# ----------------------------------------------------------------------------

CUSTOMER_DYNAMICS_CONFIG <- list(

  # ==========================================================================
  # Method Selection
  # ==========================================================================
  # Options:
  #   "z_score"         - Use statistical z-score method (recommended)
  #   "fixed_threshold" - Use fixed R-value thresholds (7/14/21 days)
  #   "auto"            - Automatically select based on data validation
  # ==========================================================================
  method = "auto",

  # ==========================================================================
  # Z-Score Parameters
  # ==========================================================================
  # Controls the statistical calculation of customer dynamics based on
  # purchase frequency patterns
  # ==========================================================================
  zscore = list(

    # ------------------------------------------------------------------------
    # Window Calculation Parameters
    # ------------------------------------------------------------------------
    k = 2.5,                       # Tolerance multiplier for W calculation
                                   # W = min(cap_days, max(min_window, round_to_7(k × μ_ind)))
                                   # Higher k = wider observation window

    min_window = 90,               # Minimum observation window (days)
                                   # Ensures statistical validity

    cap_days = 365,                # Maximum observation window (days)
                                   # Prevents excessive lookback

    round_to_multiple = 7,         # Round W to nearest multiple of 7 (weeks)
                                   # Set to 1 for no rounding

    # ------------------------------------------------------------------------
    # Classification Thresholds
    # ------------------------------------------------------------------------
    # Based on standardized z-scores of purchase frequency

    active_threshold = 0.5,        # z >= 0.5 → Active customers
                                   # Above average purchase frequency

    sleepy_threshold = -1.0,       # z >= -1.0 → Sleepy customers
                                   # Slightly below average frequency

    half_sleepy_threshold = -1.5,  # z >= -1.5 → Half-sleepy customers
                                   # Moderately below average frequency

                                   # z < -1.5 → Dormant customers
                                   # Significantly below average frequency

    # ------------------------------------------------------------------------
    # Guardrails
    # ------------------------------------------------------------------------
    use_recency_guardrail = TRUE,  # Apply r_value <= μ_ind check for active
                                   # Prevents classifying old customers as active
                                   # based solely on z-score

    newbie_age_threshold = NULL,   # Days to classify as newbie
                                   # NULL = use μ_ind (industry-adaptive)
                                   # Can override with fixed value (e.g., 30)

    # ------------------------------------------------------------------------
    # Minimum Data Requirements for Z-Score
    # ------------------------------------------------------------------------
    min_ni_for_zscore = 2,         # Minimum transactions for z-score calculation
                                   # ni == 1 automatically classified as newbie

    min_customers_for_mu = 10      # Minimum customers with ni >= 2 to calculate μ_ind
                                   # Falls back to fixed thresholds if insufficient
  ),

  # ==========================================================================
  # Fixed Threshold Parameters (Fallback/Legacy)
  # ==========================================================================
  # Used when z-score method is unavailable or disabled
  # ==========================================================================
  fixed = list(
    active_threshold = 7,          # r_value <= 7 days → Active
    sleepy_threshold = 14,         # r_value <= 14 days → Sleepy
    half_sleepy_threshold = 21,    # r_value <= 21 days → Half-sleepy
    newbie_threshold = 30          # customer_age_days <= 30 → Newbie
  ),

  # ==========================================================================
  # Activity Level Classification (CAI-based)
  # ==========================================================================
  # Requires ni >= 4 for valid CAI calculation
  # ==========================================================================
  activity_levels = list(
    min_ni = 4,                    # Minimum transactions for activity classification

    high_threshold = 0.8,          # cai_ecdf >= 0.8 → 高 (High)
    medium_threshold = 0.2,        # cai_ecdf >= 0.2 → 中 (Medium)
                                   # cai_ecdf < 0.2 → 低 (Low)

    labels = list(
      high = "高",
      medium = "中",
      low = "低",
      insufficient = NA_character_
    )
  ),

  # ==========================================================================
  # Value Level Classification (M-value based)
  # ==========================================================================
  # Based on RFM monetary quintiles
  # ==========================================================================
  value_levels = list(
    high_threshold = 0.6,          # m_value >= 60th percentile → 高 (High)
    medium_threshold = 0.4,        # m_value >= 40th percentile → 中 (Medium)
                                   # m_value < 40th percentile → 低 (Low)

    labels = list(
      high = "高",
      medium = "中",
      low = "低"
    )
  ),

  # ==========================================================================
  # Grid Position Mapping
  # ==========================================================================
  # Defines 3×3 grid mapping for visualization
  # ==========================================================================
  grid_mapping = list(
    value = list(
      high = "A",    # A = High value
      medium = "B",  # B = Medium value
      low = "C"      # C = Low value
    ),
    activity = list(
      high = "1",    # 1 = High activity
      medium = "2",  # 2 = Medium activity
      low = "3"      # 3 = Low activity
    )
  ),

  # ==========================================================================
  # Data Validation Requirements
  # ==========================================================================
  # Checks data quality before applying z-score method
  # ==========================================================================
  validation = list(

    # Minimum data requirements
    min_observation_days = 365,    # At least 1 year of data
    min_customers = 100,           # At least 100 customers
    min_repeat_customers = 30,     # At least 30 customers with ni >= 2
    min_transactions = 500,        # At least 500 total transactions

    # Data quality thresholds
    min_repeat_rate = 0.20,        # At least 20% customers have ni >= 2
    max_missing_rate = 0.10,       # Less than 10% missing critical fields

    # Behavior on validation failure
    warn_only = TRUE               # TRUE: warn and use fixed thresholds
                                   # FALSE: error and halt execution
  ),

  # ==========================================================================
  # Fallback Behavior
  # ==========================================================================
  # Controls what happens when z-score method cannot be applied
  # ==========================================================================
  fallback_behavior = "warn_and_continue",  # Options:
                                             # "warn_and_continue" - use fixed thresholds with warning
                                             # "error" - halt execution
                                             # "silent" - use fixed thresholds silently

  # ==========================================================================
  # Prediction Algorithm Parameters
  # ==========================================================================
  # Controls next purchase date prediction (remaining time algorithm)
  # ==========================================================================
  prediction = list(
    use_remaining_time = TRUE,     # Use remaining time algorithm
                                   # FALSE: simple today + avg_ipt

    prefer_individual_pattern = TRUE, # Prefer customer's own avg_ipt over μ_ind

    min_ni_for_individual = 2,     # Minimum transactions to use individual avg_ipt

    overdue_handling = "next_cycle" # Options:
                                    # "next_cycle" - predict today + expected_cycle
                                    # "immediate" - predict today + remaining_time (can be 0)
  ),

  # ==========================================================================
  # Display and UI Settings
  # ==========================================================================
  display = list(

    # Terminology
    customer_dynamics_label = "客戶動態",
    activity_level_label = "活動力",
    value_level_label = "價值力",

    # Color schemes for grid cells
    colors = list(
      active = list(
        high = "#28a745",    # Green
        medium = "#17a2b8",  # Cyan
        low = "#6c757d"      # Gray
      ),
      sleepy = list(
        high = "#ffc107",    # Amber
        medium = "#fd7e14",  # Orange
        low = "#dc3545"      # Red
      ),
      half_sleepy = list(
        high = "#e83e8c",    # Pink
        medium = "#6f42c1",  # Purple
        low = "#343a40"      # Dark
      ),
      dormant = list(
        high = "#495057",    # Dark gray
        medium = "#6c757d",  # Gray
        low = "#adb5bd"      # Light gray
      ),
      newbie = list(
        high = "#007bff",    # Blue
        medium = "#0056b3",  # Dark blue
        low = "#004085"      # Darker blue
      )
    ),

    # Border colors by customer dynamics
    border_colors = list(
      active = "#28a745",
      sleepy = "#ffc107",
      half_sleepy = "#e83e8c",
      dormant = "#6c757d",
      newbie = "#007bff"
    )
  )
)

# ----------------------------------------------------------------------------
# Helper Functions
# ----------------------------------------------------------------------------

#' Get Customer Dynamics Configuration
#'
#' @return List containing all configuration parameters
#' @export
get_customer_dynamics_config <- function() {
  CUSTOMER_DYNAMICS_CONFIG
}

#' Get Z-Score Thresholds
#'
#' @return Named vector of z-score thresholds
#' @export
get_zscore_thresholds <- function() {
  config <- CUSTOMER_DYNAMICS_CONFIG$zscore
  c(
    active = config$active_threshold,
    sleepy = config$sleepy_threshold,
    half_sleepy = config$half_sleepy_threshold
  )
}

#' Get Activity Level Thresholds
#'
#' @return Named vector of CAI percentile thresholds
#' @export
get_activity_thresholds <- function() {
  config <- CUSTOMER_DYNAMICS_CONFIG$activity_levels
  c(
    high = config$high_threshold,
    medium = config$medium_threshold
  )
}

#' Get Value Level Thresholds
#'
#' @return Named vector of M-value percentile thresholds
#' @export
get_value_thresholds <- function() {
  config <- CUSTOMER_DYNAMICS_CONFIG$value_levels
  c(
    high = config$high_threshold,
    medium = config$medium_threshold
  )
}

#' Validate Data for Z-Score Method
#'
#' @param transaction_data Data frame with transaction records
#' @param customer_data Data frame with customer summaries
#' @return List with validation results (passed, issues, recommendations)
#' @export
validate_zscore_data <- function(transaction_data, customer_data) {

  config <- CUSTOMER_DYNAMICS_CONFIG$validation
  issues <- character()

  # Check observation period
  if (!is.null(transaction_data$transaction_date)) {
    date_range <- as.numeric(difftime(
      max(transaction_data$transaction_date),
      min(transaction_data$transaction_date),
      units = "days"
    ))
    if (date_range < config$min_observation_days) {
      issues <- c(issues, sprintf(
        "觀察期僅 %d 天（需要 %d 天）",
        round(date_range),
        config$min_observation_days
      ))
    }
  }

  # Check customer count
  n_customers <- nrow(customer_data)
  if (n_customers < config$min_customers) {
    issues <- c(issues, sprintf(
      "客戶數僅 %d 位（建議 %d 位以上）",
      n_customers,
      config$min_customers
    ))
  }

  # Check repeat customers
  if ("ni" %in% names(customer_data)) {
    n_repeat <- sum(customer_data$ni >= 2, na.rm = TRUE)
    if (n_repeat < config$min_repeat_customers) {
      issues <- c(issues, sprintf(
        "回購客戶僅 %d 位（需要 %d 位）",
        n_repeat,
        config$min_repeat_customers
      ))
    }

    # Check repeat rate
    repeat_rate <- n_repeat / n_customers
    if (repeat_rate < config$min_repeat_rate) {
      issues <- c(issues, sprintf(
        "回購率僅 %.1f%%（建議 %.1f%% 以上）",
        repeat_rate * 100,
        config$min_repeat_rate * 100
      ))
    }
  }

  # Check transaction count
  n_transactions <- nrow(transaction_data)
  if (n_transactions < config$min_transactions) {
    issues <- c(issues, sprintf(
      "交易筆數僅 %d 筆（建議 %d 筆以上）",
      n_transactions,
      config$min_transactions
    ))
  }

  # Determine result
  passed <- length(issues) == 0

  # Generate recommendations
  recommendations <- if (!passed) {
    c(
      "建議使用固定門檻法（7/14/21天）",
      "或收集更多資料後再使用 z-score 法"
    )
  } else {
    c("資料品質良好，可使用 z-score 法")
  }

  list(
    passed = passed,
    issues = issues,
    recommendations = recommendations,
    method_suggestion = if (passed) "z_score" else "fixed_threshold"
  )
}

#' Print Configuration Summary
#'
#' @export
print_config_summary <- function() {
  config <- CUSTOMER_DYNAMICS_CONFIG

  cat("====================================\n")
  cat("Customer Dynamics Configuration\n")
  cat("====================================\n\n")

  cat("Method:", config$method, "\n\n")

  cat("Z-Score Thresholds:\n")
  cat("  Active:      z >=", config$zscore$active_threshold, "\n")
  cat("  Sleepy:      z >=", config$zscore$sleepy_threshold, "\n")
  cat("  Half-Sleepy: z >=", config$zscore$half_sleepy_threshold, "\n")
  cat("  Dormant:     z < ", config$zscore$half_sleepy_threshold, "\n\n")

  cat("Window Parameters:\n")
  cat("  k (multiplier):", config$zscore$k, "\n")
  cat("  Min window:   ", config$zscore$min_window, "days\n")
  cat("  Max window:   ", config$zscore$cap_days, "days\n\n")

  cat("Activity Levels (CAI):\n")
  cat("  High:   >=", config$activity_levels$high_threshold, "\n")
  cat("  Medium: >=", config$activity_levels$medium_threshold, "\n")
  cat("  Low:     <", config$activity_levels$medium_threshold, "\n\n")

  cat("Fallback Behavior:", config$fallback_behavior, "\n")
  cat("====================================\n")
}

# ============================================================================
# End of Configuration
# ============================================================================
