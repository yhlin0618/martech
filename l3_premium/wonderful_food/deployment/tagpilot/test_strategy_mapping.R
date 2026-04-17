# Test Strategy Mapping Functions
# This script tests the strategy mapping functionality

# Load required libraries
library(dplyr)

# Source the strategy functions from the main module
source("modules/module_dna_multi_pro2.R")

# Test the strategy loading
cat("Testing strategy data loading...\n")
strategy_data <- load_strategy_data()

if (!is.null(strategy_data$mapping)) {
  cat("✅ Mapping data loaded successfully -", nrow(strategy_data$mapping), "rows\n")
  cat("Columns:", paste(names(strategy_data$mapping), collapse = ", "), "\n")
  
  # Show first few mappings
  cat("\nFirst few mappings:\n")
  print(head(strategy_data$mapping[, 1:3], 3))
} else {
  cat("❌ Failed to load mapping data\n")
}

if (!is.null(strategy_data$strategy)) {
  cat("\n✅ Strategy data loaded successfully -", nrow(strategy_data$strategy), "rows\n")
  cat("Columns:", paste(names(strategy_data$strategy), collapse = ", "), "\n")
  
  # Show first few strategies
  cat("\nFirst few strategies:\n")
  print(head(strategy_data$strategy[, 1:3], 3))
} else {
  cat("❌ Failed to load strategy data\n")
}

# Test ROS baseline filtering
cat("\n", paste(rep("=", 50), collapse = ""), "\n")
cat("Testing ROS baseline filtering...\n")

# Create sample customer data with different ROS segments
sample_customers <- data.frame(
  customer_id = 1:10,
  ros_segment = c("R + S-Low", "rO + S-High", "O", "ro + S-Medium", "R + S-Medium", 
                  "R + S-Low", "O", "rR + S-High", "ro + S-Low", "RO + S-High"),
  m_value = runif(10, 10, 100),
  f_value = sample(1:10, 10, replace = TRUE),
  stringsAsFactors = FALSE
)

cat("Sample customers:\n")
print(sample_customers[, c("customer_id", "ros_segment")])

# Test filtering for different baselines
test_baselines <- c("R + S‑Low", "S‑High + O", "R + S‑Medium")

for (baseline in test_baselines) {
  cat("\n--- Testing baseline:", baseline, "---\n")
  
  filtered <- filter_customers_by_ros_baseline(sample_customers, baseline)
  
  cat("Filtered customers:", nrow(filtered), "/", nrow(sample_customers), "\n")
  if (nrow(filtered) > 0) {
    cat("Matching ROS segments:", paste(filtered$ros_segment, collapse = ", "), "\n")
  }
}

# Test segment strategy retrieval
cat("\n", paste(rep("=", 50), collapse = ""), "\n")
cat("Testing segment strategy retrieval...\n")

test_segments <- c("A3N", "B3N", "A1C", "C3S")

for (segment in test_segments) {
  cat("\n--- Testing segment:", segment, "---\n")
  
  result <- get_strategy_by_segment(segment, strategy_data)
  
  if (!is.null(result)) {
    cat("✅ Strategy found!\n")
    if (!is.null(result$primary) && nrow(result$primary) > 0) {
      cat("Primary Strategy:", result$primary_code, "-", result$primary$core_action[1], "\n")
    }
    if (!is.null(result$secondary) && nrow(result$secondary) > 0) {
      cat("Secondary Strategy:", result$secondary_code, "-", result$secondary$core_action[1], "\n")
    }
    if (!is.null(result$segment_info)) {
      cat("Required ROS Baseline:", result$segment_info$ros_baseline[1], "\n")
      cat("区段範例:", result$segment_info$example[1], "\n")
    }
  } else {
    cat("❌ No strategy found for this segment\n")
  }
}

# Test ROS format conversion
cat("\n", paste(rep("=", 50), collapse = ""), "\n")
cat("Testing ROS format conversion...\n")

ros_examples <- c("R + S-Low", "rO + S-High", "O", "ro + S-Medium")
for (ros in ros_examples) {
  cat("Original:", ros, "| ")
  
  # Extract components (simulating the logic in get_segment_strategy)
  has_R <- grepl("^R", ros)
  has_r <- grepl("^r", ros) && !grepl("^R", ros)
  has_O <- grepl("O", ros)
  has_o <- grepl("o", ros) && !grepl("O", ros)
  
  stability_level <- ""
  if (grepl("S-High", ros)) stability_level <- "S‑High"
  else if (grepl("S-Medium", ros)) stability_level <- "S‑Medium"
  else if (grepl("S-Low", ros)) stability_level <- "S‑Low"
  
  cat("R:", has_R, "r:", has_r, "O:", has_O, "o:", has_o, "Stability:", stability_level, "\n")
}

cat("\nStrategy mapping test completed!\n") 