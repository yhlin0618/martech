# Cleanup script to remove unused code sections

# Read the app.R file
lines <- readLines("app.R")

# Find line numbers to remove
preview_btn_start <- grep("# ──── 步驟 1：上傳資料", lines)
attributes_start <- grep("# ──── 步驟 2：屬性萃取", lines)
scoring_start <- grep("observeEvent\\(input\\$start_scoring", lines)

cat("Found sections at lines:\n")
cat("Preview button section:", preview_btn_start, "\n")
cat("Attributes section:", attributes_start, "\n")
cat("Scoring section:", scoring_start, "\n")

# Mark sections for removal
# We'll comment them out instead of deleting to be safe

# Comment out upload review data handlers (lines 669-733)
if (length(preview_btn_start) > 0 && preview_btn_start == 669) {
  for (i in 669:733) {
    if (i <= length(lines)) {
      lines[i] <- paste0("# REMOVED: ", lines[i])
    }
  }
}

# Comment out attributes extraction handlers (lines 735-835)
if (length(attributes_start) > 0 && attributes_start == 735) {
  for (i in 735:835) {
    if (i <= length(lines)) {
      lines[i] <- paste0("# REMOVED: ", lines[i])
    }
  }
}

# Comment out scoring handlers (lines 837-950)
if (length(scoring_start) > 0 && scoring_start == 837) {
  for (i in 837:950) {
    if (i <= length(lines)) {
      lines[i] <- paste0("# REMOVED: ", lines[i])
    }
  }
}

# Write back
writeLines(lines, "app_cleaned.R")
cat("\nCleaned file saved as app_cleaned.R\n")
cat("Review the changes and rename to app.R when satisfied.\n")