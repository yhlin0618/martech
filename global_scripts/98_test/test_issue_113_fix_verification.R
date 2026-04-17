#!/usr/bin/env Rscript
# test_issue_113_fix_verification.R
#
# Verification test for ISSUE_113 fix - empty brand field handling
# This test verifies that the fix works correctly in the actual functions
# Following principles:
# - MP114: Input validation and sanitization
# - MP106: Console output transparency
# - MP051: Test Data Design

# Load required packages
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# String concatenation operator
`%+%` <- function(x, y) paste0(x, y)

message("\n" %+% paste0(rep("=", 70), collapse = ""))
message("🔍 VERIFYING FIX FOR ISSUE_113: Empty Brand Field Issue")
message(paste0(rep("=", 70), collapse = ""))

# Source the fixed function
source_file <- "scripts/global_scripts/10_rshinyapp_components/position/positionTable/positionTable.R"
if (file.exists(source_file)) {
  source(source_file)
  message("✓ Sourced positionTable.R with updated simple_filter_position_table function")
} else {
  stop("Cannot find positionTable.R file!")
}

# Create test data
create_test_data <- function() {
  data.frame(
    product_id = c(
      "185889598631",  # Empty brand, all NA attributes
      "185889598632",  # MAMBA brand, complete data
      "185889598633",  # NA brand, complete data
      "185889598634",  # Empty brand, all NA attributes
      "185889598635",  # MAMBA brand, complete data
      "185889598636",  # Empty brand but has data
      "Ideal"          # Special row
    ),
    brand = c(
      "",              # Empty string
      "MAMBA",         # Normal brand
      NA_character_,   # NA brand
      "",              # Empty string
      "MAMBA",         # Normal brand
      "",              # Empty string but has data
      "Ideal"          # Special brand
    ),
    product_line_id = rep("tur", 7),
    attribute1 = c(NA, 75, 80, NA, 85, 70, 90),
    attribute2 = c(NA, 60, 65, NA, 70, 55, 75),
    attribute3 = c(NA, 85, 88, NA, 90, 82, 92),
    rating = c(NA, 4.2, 4.5, NA, 4.3, 4.0, 5.0),
    sales = c(NA, 1200, 1500, NA, 1100, 800, 2000),
    stringsAsFactors = FALSE
  )
}

# Run verification tests
message("\n📊 TEST 1: Testing simple_filter_position_table with fixed code")
message("----------------------------------------")

test_data <- create_test_data()

message("\nOriginal data:")
print(test_data)
message("\nBrand values in original data:")
for (i in 1:nrow(test_data)) {
  brand_val <- test_data$brand[i]
  message(sprintf("  Row %d: '%s' (length=%d, is.na=%s)",
                  i,
                  ifelse(is.na(brand_val), "NA", brand_val),
                  nchar(as.character(brand_val)),
                  is.na(brand_val)))
}

# Apply the fixed filtering function
message("\n🔧 Applying simple_filter_position_table...")
filtered_data <- simple_filter_position_table(test_data, threshold = 0.3)

message("\n📋 Filtered data:")
print(filtered_data)

# Verify results
message("\n✅ VERIFICATION RESULTS:")
message("----------------------------------------")

# Check 1: No empty brand strings
empty_brands <- sum(filtered_data$brand == "", na.rm = TRUE)
message(sprintf("Empty brand strings: %d %s",
                empty_brands,
                ifelse(empty_brands == 0, "✓", "✗ FAILED")))

# Check 2: No NA brands
na_brands <- sum(is.na(filtered_data$brand))
message(sprintf("NA brands: %d %s",
                na_brands,
                ifelse(na_brands == 0, "✓", "✗ FAILED")))

# Check 3: Empty attribute rows removed
expected_removed <- c("185889598631", "185889598634")  # These have all NA attributes
actually_removed <- setdiff(expected_removed, filtered_data$product_id)
message(sprintf("Rows with all NA attributes removed: %s %s",
                paste(actually_removed, collapse=", "),
                ifelse(length(actually_removed) == length(expected_removed), "✓", "✗ FAILED")))

# Check 4: Row with empty brand but valid data is kept with brand="UNKNOWN"
item_636 <- filtered_data[filtered_data$product_id == "185889598636", ]
if (nrow(item_636) > 0) {
  message(sprintf("Item 185889598636 (empty brand, has data): brand='%s' %s",
                  item_636$brand,
                  ifelse(item_636$brand == "UNKNOWN", "✓", "✗ FAILED")))
} else {
  message("Item 185889598636: Not found ✗ FAILED")
}

# Summary
message("\n📊 SUMMARY:")
message("----------------------------------------")
message("Total rows before filtering: ", nrow(test_data))
message("Total rows after filtering: ", nrow(filtered_data))
message("Rows removed: ", nrow(test_data) - nrow(filtered_data))

# Brand distribution
brand_counts <- table(filtered_data$brand)
message("\nBrand distribution after filtering:")
for (brand in names(brand_counts)) {
  message(sprintf("  %s: %d rows", brand, brand_counts[brand]))
}

# Test with actual filtering scenario
message("\n📊 TEST 2: Simulating actual usage scenario")
message("----------------------------------------")

# Simulate selecting brand="MAMBA"
mamba_filtered <- filtered_data %>%
  filter(brand == "MAMBA")

message("Filtering for brand='MAMBA':")
message("  Rows returned: ", nrow(mamba_filtered))
print(mamba_filtered)

# Verify no confusion with empty brand items
if (nrow(mamba_filtered) > 0 && all(mamba_filtered$brand == "MAMBA")) {
  message("✓ All returned rows have brand='MAMBA' - no empty brand confusion!")
} else {
  message("✗ FAILED - unexpected brand values in MAMBA filter")
}

# Final status
message("\n" %+% paste0(rep("=", 70), collapse = ""))
message("🎯 FIX VERIFICATION COMPLETE")
message(paste0(rep("=", 70), collapse = ""))

all_checks_passed <- (empty_brands == 0 &&
                     na_brands == 0 &&
                     length(actually_removed) == length(expected_removed) &&
                     nrow(item_636) > 0 && item_636$brand == "UNKNOWN")

if (all_checks_passed) {
  message("
✅ ALL CHECKS PASSED!

The fix successfully:
1. Converts empty string brands to 'UNKNOWN'
2. Removes rows with all NA attributes
3. Preserves rows with data even if brand was empty
4. Prevents confusion in brand filtering

ISSUE_113 is RESOLVED!
")
} else {
  message("
⚠️ SOME CHECKS FAILED

Please review the test output above to identify remaining issues.
")
}

message("\nPrinciples followed:")
message("  - MP114: Input validation and sanitization")
message("  - MP106: Console output transparency")
message("  - MP051: Test Data Design")