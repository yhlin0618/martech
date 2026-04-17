# Initialization script for MAMBA Precision Marketing App
# This script runs at startup and sets up any local configurations

# Set default options
options(shiny.maxRequestSize = 30*1024^2)  # Allow larger file uploads (30MB)
options(scipen = 999)                      # Avoid scientific notation
options(dplyr.summarise.inform = FALSE)    # Suppress dplyr grouping message

# Load environment variables if .env file exists
if (file.exists(".env")) {
  readRenviron(".env")
}

# Print startup message
message("MAMBA Precision Marketing Platform initializing...")
message("Working directory: ", getwd())

# Custom function to format currency values
format_currency <- function(x) {
  paste0("$", format(round(as.numeric(x), 2), nsmall = 2, big.mark = ","))
}

# Custom function to format percentages
format_percent <- function(x) {
  paste0(format(round(as.numeric(x) * 100, 1), nsmall = 1), "%")
}

# Set locale for date formatting
Sys.setlocale("LC_TIME", "en_US.UTF-8")