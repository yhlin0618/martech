# Test script to verify app runs without errors

cat("Testing BrandEdge Premium Application...\n")
cat("=====================================\n\n")

# Check if required packages are installed
required_packages <- c("shiny", "bs4Dash", "DT", "readxl", "dplyr", "plotly")
missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]

if(length(missing_packages) > 0) {
  cat("Missing packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("Installing missing packages...\n")
  install.packages(missing_packages)
}

# Try to run the app in test mode
cat("\nAttempting to start the application...\n")
cat("Press Ctrl+C to stop the application\n\n")

# Run app with error handling
tryCatch({
  shiny::runApp("app.R", launch.browser = FALSE, port = 8888)
}, error = function(e) {
  cat("\n❌ Error occurred:\n")
  cat(as.character(e), "\n")
  cat("\nPlease check the error message above and fix any issues.\n")
})