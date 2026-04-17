################################################################################
# Icon Diagnostic Script
# Purpose: Identify invalid icon names in the app
################################################################################

library(shiny)
library(bs4Dash)

cat("🔍 Icon Diagnostic Tool\n")
cat("==========================================\n\n")

# List of all Font Awesome icons used in app.R
icons_in_app <- c(
  "upload", "th", "coins", "chart-pie", "heartbeat", "cube",
  "clock", "chart-line", "info-circle", "sign-out-alt",
  "bullseye", "brain", "comments", "chart-bar", "user", "database"
)

cat("Testing", length(icons_in_app), "icons from app.R:\n\n")

invalid_icons <- character()

for (icon_name in icons_in_app) {
  result <- tryCatch({
    test_icon <- icon(icon_name)
    cat("✅", icon_name, "\n")
    TRUE
  }, error = function(e) {
    cat("❌", icon_name, "- ERROR:", conditionMessage(e), "\n")
    invalid_icons <<- c(invalid_icons, icon_name)
    FALSE
  })
}

cat("\n==========================================\n")

if (length(invalid_icons) > 0) {
  cat("⚠️  Found", length(invalid_icons), "invalid icon(s):\n")
  for (icon_name in invalid_icons) {
    cat("  -", icon_name, "\n")
  }
  cat("\nRecommended replacements:\n")
  cat("  crystal-ball -> clock, hourglass, or magic\n")
  cat("  Other icons -> check Font Awesome 5 free icons\n")
} else {
  cat("✅ All icons are valid!\n")
}

cat("\n🔍 Now checking if app.R can be sourced...\n\n")

# Try to source just the UI definition
tryCatch({
  source("app.R", local = TRUE)
  cat("✅ app.R sourced successfully!\n")
}, error = function(e) {
  cat("❌ Error sourcing app.R:\n")
  cat(conditionMessage(e), "\n")
  cat("\nTraceback:\n")
  print(sys.calls())
})

cat("\n✅ Diagnostic complete!\n")
