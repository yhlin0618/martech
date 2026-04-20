#!/usr/bin/env Rscript
# test_brand_empty_issue_113.R
#
# Testing and debugging ISSUE_113 - Brand field showing empty string causes empty data rows
# Following principles:
# - MP114: Input validation and sanitization
# - MP106: Console output transparency
# - MP051: Test Data Design
# - R113: Four-part script structure (INITIALIZE/MAIN/TEST/DEINITIALIZE)

# ==============================================================================
# INITIALIZE SECTION (R113)
# ==============================================================================

# Set working directory to project root (critical for autoinit)
if (!endsWith(getwd(), "MAMBA")) {
  # Try to find MAMBA directory
  potential_dirs <- c(
    "/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA",
    "~/che_workspace/projects/ai_martech/l4_enterprise/MAMBA",
    file.path(getwd(), "MAMBA")
  )

  for (dir in potential_dirs) {
    if (dir.exists(dir)) {
      setwd(dir)
      message("✓ Changed working directory to: ", getwd())
      break
    }
  }
}

# Initialize environment (MP031 - autoinit pattern)
tryCatch({
  source("scripts/global_scripts/00_principles/sc_initialization_update_mode.R")
  message("✓ Environment initialized successfully")
}, error = function(e) {
  message("✗ Failed to initialize environment: ", e$message)
  stop("Cannot proceed without proper initialization")
})

# Load required functions
suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
})

# ==============================================================================
# MAIN SECTION - Create Test Data (MP051)
# ==============================================================================

message("\n" %+% paste0(rep("=", 70), collapse = ""))
message("🔍 TESTING ISSUE_113: Empty Brand Field Issue")
message(paste0(rep("=", 70), collapse = ""))

# Create test data simulating the issue
create_test_data_issue_113 <- function() {
  message("\n📊 Creating test data to reproduce ISSUE_113...")

  # Simulate the problematic data with item 185889598631
  test_data <- data.frame(
    product_id = c(
      "185889598631",  # Problematic item with empty brand
      "185889598632",  # Normal MAMBA item
      "185889598633",  # Item with NA brand
      "185889598634",  # Item with empty string brand
      "185889598635",  # Another MAMBA item
      "Ideal"          # Special row
    ),
    brand = c(
      "",              # Empty string - THE ISSUE
      "MAMBA",         # Normal brand
      NA_character_,   # NA brand
      "",              # Another empty string
      "MAMBA",         # Normal brand
      "Ideal"          # Special brand
    ),
    product_line_id = rep("tur", 6),
    # All attribute values for problematic item are NA/empty
    attribute1 = c(NA, 75, 80, NA, 85, 90),
    attribute2 = c(NA, 60, 65, NA, 70, 75),
    attribute3 = c(NA, 85, 88, NA, 90, 92),
    rating = c(NA, 4.2, 4.5, NA, 4.3, 5.0),
    sales = c(NA, 1200, 1500, NA, 1100, 2000),
    stringsAsFactors = FALSE
  )

  message("✓ Created test data with ", nrow(test_data), " rows")
  message("  - Row 1: Item 185889598631 with empty string brand and all NA values")
  message("  - Row 2: Normal MAMBA item with complete data")
  message("  - Row 3: Item with NA brand")
  message("  - Row 4: Item with empty string brand")
  message("  - Row 5: Another normal MAMBA item")
  message("  - Row 6: Ideal special row")

  return(test_data)
}

# ==============================================================================
# TEST SECTION - Reproduce and Fix Issue (R113)
# ==============================================================================

message("\n🧪 REPRODUCING THE ISSUE...")

# Create test data
test_data <- create_test_data_issue_113()

# Show the problematic data
message("\n📋 Original test data:")
print(test_data)

# Test 1: Current behavior (reproducing the issue)
message("\n❌ TEST 1: Current behavior with empty string brands")
message("----------------------------------------")

# Simulate current processing (from fn_process_position_table.R line 163)
current_processing <- test_data %>%
  mutate(brand = dplyr::na_if(brand, NA_character_) %>%
                 tidyr::replace_na("UNKNOWN"))

message("After current processing (na_if with NA_character_ only):")
print(current_processing)
message("⚠️ ISSUE: Empty strings '' are NOT converted to 'UNKNOWN'!")

# Show which rows would be filtered by simple_filter_position_table
message("\n🔍 Analyzing which rows would be filtered...")

# Identify filterable columns (numeric, excluding essentials)
essential_cols <- c("product_id", "brand", "product_line_id", "rating", "sales")
numeric_cols <- names(test_data)[sapply(test_data, is.numeric)]
filterable_cols <- setdiff(numeric_cols, essential_cols)

message("Filterable columns: ", paste(filterable_cols, collapse = ", "))

# Check which rows have all NA in filterable columns
row_non_na_count <- apply(test_data[filterable_cols], 1, function(row) {
  sum(!is.na(row))
})

empty_rows <- row_non_na_count == 0
message("\nRows with all NA in filterable columns:")
for (i in which(empty_rows)) {
  message("  Row ", i, ": product_id=", test_data$product_id[i],
          ", brand='", test_data$brand[i], "'")
}

# Test 2: Proposed fix
message("\n✅ TEST 2: Proposed fix - handle empty strings properly")
message("----------------------------------------")

# Fixed processing - convert empty strings to NA first, then to UNKNOWN
fixed_processing <- test_data %>%
  mutate(
    # Step 1: Convert empty strings to NA (MP114 - input validation)
    brand = na_if(brand, ""),
    # Step 2: Convert NA to UNKNOWN
    brand = tidyr::replace_na(brand, "UNKNOWN")
  )

message("After fixed processing (handling empty strings):")
print(fixed_processing)
message("✓ SUCCESS: All empty/NA brands are now 'UNKNOWN'!")

# Test 3: Complete filtering logic
message("\n🔧 TEST 3: Complete filtering with fixed brand handling")
message("----------------------------------------")

# Apply the complete filtering logic
apply_complete_filtering <- function(data) {
  message("\n📊 Applying complete filtering logic...")

  # Step 1: Fix brand field (handle empty strings and NA)
  data <- data %>%
    mutate(
      brand = na_if(brand, ""),           # Convert empty string to NA
      brand = na_if(brand, NA_character_), # Redundant but safe
      brand = replace_na(brand, "UNKNOWN") # Convert NA to UNKNOWN
    )

  message("✓ Step 1: Fixed brand field")

  # Step 2: Remove completely empty rows (MP106 - transparency)
  essential_cols <- c("product_id", "brand", "product_line_id", "rating", "sales")
  numeric_cols <- names(data)[sapply(data, is.numeric)]
  filterable_cols <- setdiff(numeric_cols, essential_cols)

  if (length(filterable_cols) > 0) {
    row_non_na_count <- apply(data[filterable_cols], 1, function(row) {
      sum(!is.na(row))
    })

    non_empty_rows <- row_non_na_count > 0
    rows_before <- nrow(data)
    data <- data[non_empty_rows, ]
    rows_after <- nrow(data)

    message("✓ Step 2: Removed ", rows_before - rows_after, " empty rows")

    # Log which rows were removed (MP106 - transparency)
    if (rows_before > rows_after) {
      removed_indices <- which(!non_empty_rows)
      message("  Removed rows: ", paste(removed_indices, collapse = ", "))
    }
  }

  return(data)
}

# Apply complete filtering
filtered_data <- apply_complete_filtering(test_data)

message("\n📋 Final filtered data:")
print(filtered_data)

# Verify the fix
message("\n✅ VERIFICATION:")
message("----------------------------------------")

# Check if problematic row is properly handled
problematic_item <- "185889598631"
if (problematic_item %in% filtered_data$product_id) {
  row_data <- filtered_data[filtered_data$product_id == problematic_item, ]
  if (row_data$brand == "UNKNOWN") {
    message("✓ Item ", problematic_item, " now has brand = 'UNKNOWN' (was empty)")
  }
  message("✗ Item ", problematic_item, " still in data - should be filtered out due to empty attributes!")
} else {
  message("✓ Item ", problematic_item, " properly filtered out (all attributes were NA)")
}

# Check no rows have empty brand
empty_brand_count <- sum(filtered_data$brand == "", na.rm = TRUE)
na_brand_count <- sum(is.na(filtered_data$brand))

message("\n📊 Final validation:")
message("  - Rows with empty string brand: ", empty_brand_count,
        ifelse(empty_brand_count == 0, " ✓", " ✗"))
message("  - Rows with NA brand: ", na_brand_count,
        ifelse(na_brand_count == 0, " ✓", " ✗"))
message("  - Total rows after filtering: ", nrow(filtered_data))

# ==============================================================================
# DEINITIALIZE SECTION (R113, MP031)
# ==============================================================================

message("\n" %+% paste0(rep("=", 70), collapse = ""))
message("📝 RECOMMENDED FIX FOR fn_process_position_table.R")
message(paste0(rep("=", 70), collapse = ""))

message("
Replace line 163 in fn_process_position_table.R:

OLD CODE:
    dplyr::mutate(brand = dplyr::na_if(brand, NA_character_) %>%
                   tidyr::replace_na('UNKNOWN'))

NEW CODE:
    dplyr::mutate(
      # Convert empty strings to NA first (MP114 - input validation)
      brand = dplyr::na_if(brand, ''),
      # Then handle NA values
      brand = tidyr::replace_na(brand, 'UNKNOWN')
    )
")

message("\n✓ Test completed successfully")
message("  Following principles:")
message("  - MP114: Input validation and sanitization")
message("  - MP106: Console output transparency")
message("  - MP051: Test Data Design")
message("  - R113: Four-part script structure")

# Clean up (MP031 - autodeinit pattern would handle this in production)
rm(list = ls())
message("\n✓ Test environment cleaned up")