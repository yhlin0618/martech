# =============================================================================
# Simple Module Test
# Purpose: Test the LaTeX report module functions directly
# =============================================================================

# Load required packages
library(dotenv)
library(dplyr)
library(jsonlite)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# Source the utility functions
source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")

# Create test data
test_sales_data <- data.frame(
  customer_id = paste0("customer_", 1:10),
  lineitem_price = round(runif(10, 50, 500), 2),
  payment_time = Sys.time() - runif(10, 0, 30) * 24 * 3600,
  product_name = sample(c("產品A", "產品B", "產品C"), 10, replace = TRUE)
)

# Test data collection
cat("Testing data collection...\n")
report_data <- fn_collect_report_data(
  sales_data = test_sales_data,
  metadata = list(
    title = "測試報告",
    author = "測試用戶",
    date = "2025年1月27日"
  ),
  include_options = list(
    sales_summary = TRUE,
    dna_analysis = FALSE,
    customer_segments = FALSE
  ),
  verbose = TRUE
)

cat("Data collection result:\n")
print(str(report_data))

# Test API key
api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
if (api_key != "" && grepl("^sk-", api_key)) {
  cat("\nTesting GPT API call...\n")
  
  result <- fn_generate_latex_via_gpt(
    report_data = report_data,
    api_key = api_key,
    model = "gpt-3.5-turbo",  # Use cheaper model for testing
    temperature = 0.7,
    max_tokens = 1000,  # Smaller for testing
    verbose = TRUE
  )
  
  if (!is.null(result$error)) {
    cat("Error:", result$error, "\n")
  } else {
    cat("Success! Generated LaTeX content:\n")
    cat("Length:", nchar(result$latex), "characters\n")
    cat("First 200 characters:\n")
    cat(substr(result$latex, 1, 200), "\n")
  }
} else {
  cat("Skipping API test - invalid API key\n")
} 