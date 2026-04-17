# =============================================================================
# LaTeX Module Issue Diagnosis
# Purpose: Diagnose the API timeout issue in the LaTeX report module
# =============================================================================

cat("=== LaTeX Module Issue Diagnosis ===\n\n")

# 1. Check environment variables
cat("1. Environment Variables:\n")
library(dotenv)
dotenv::load_dot_env(file = ".env")

api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
cat("   API Key loaded:", ifelse(api_key != "", "YES", "NO"), "\n")
cat("   API Key length:", nchar(api_key), "\n")
cat("   API Key format:", ifelse(grepl("^sk-", api_key), "CORRECT", "INCORRECT"), "\n\n")

# 2. Check required packages
cat("2. Required Packages:\n")
required_packages <- c("shiny", "dplyr", "jsonlite", "httr", "rmarkdown", "tools", "dotenv")
for (pkg in required_packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("   ✓", pkg, "\n")
  } else {
    cat("   ✗", pkg, "(missing)\n")
  }
}
cat("\n")

# 3. Check file existence
cat("3. File Existence:\n")
files_to_check <- c(
  "modules/module_latex_report.R",
  "scripts/global_scripts/04_utils/fn_latex_report_utils.R",
  "template.tex",
  ".env"
)

for (file in files_to_check) {
  if (file.exists(file)) {
    cat("   ✓", file, "\n")
  } else {
    cat("   ✗", file, "(missing)\n")
  }
}
cat("\n")

# 4. Test API connectivity
cat("4. API Connectivity Test:\n")
if (api_key != "" && grepl("^sk-", api_key)) {
  tryCatch({
    library(httr)
    library(jsonlite)
    
    response <- httr::GET(
      url = "https://api.openai.com/v1/models",
      httr::add_headers(
        "Authorization" = paste("Bearer", api_key)
      ),
      httr::timeout(10)  # Short timeout for quick test
    )
    
    if (response$status_code == 200) {
      cat("   ✓ API connection successful\n")
      models <- jsonlite::fromJSON(rawToChar(response$content))
      cat("   ✓ Available models:", length(models$data), "\n")
    } else {
      cat("   ✗ API connection failed (status:", response$status_code, ")\n")
    }
  }, error = function(e) {
    cat("   ✗ API connection error:", e$message, "\n")
  })
} else {
  cat("   ✗ Cannot test API - invalid key\n")
}
cat("\n")

# 5. Test utility functions
cat("5. Utility Functions Test:\n")
tryCatch({
  source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")
  cat("   ✓ Utility functions loaded successfully\n")
  
  # Test data collection
  test_data <- data.frame(
    customer_id = paste0("customer_", 1:5),
    lineitem_price = c(100, 200, 300, 400, 500),
    payment_time = Sys.time()
  )
  
  result <- fn_collect_report_data(
    sales_data = test_data,
    verbose = FALSE
  )
  
  if (!is.null(result$sales_summary)) {
    cat("   ✓ Data collection function works\n")
  } else {
    cat("   ✗ Data collection function failed\n")
  }
  
}, error = function(e) {
  cat("   ✗ Utility functions error:", e$message, "\n")
})
cat("\n")

# 6. Test LaTeX compilation
cat("6. LaTeX Compilation Test:\n")
tryCatch({
  # Test if pdflatex is available
  result <- system2("pdflatex", "--version", stdout = TRUE, stderr = TRUE)
  if (length(result) > 0) {
    cat("   ✓ pdflatex available\n")
  } else {
    cat("   ✗ pdflatex not available\n")
  }
  
  # Test if xelatex is available
  result <- system2("xelatex", "--version", stdout = TRUE, stderr = TRUE)
  if (length(result) > 0) {
    cat("   ✓ xelatex available\n")
  } else {
    cat("   ✗ xelatex not available\n")
  }
  
}, error = function(e) {
  cat("   ✗ LaTeX test error:", e$message, "\n")
})
cat("\n")

# 7. Recommendations
cat("7. Recommendations:\n")
if (api_key == "" || !grepl("^sk-", api_key)) {
  cat("   • Fix API key in .env file\n")
}
if (!file.exists("template.tex")) {
  cat("   • Create template.tex file\n")
}
if (!file.exists("modules/module_latex_report.R")) {
  cat("   • Check module file path\n")
}
if (!file.exists("scripts/global_scripts/04_utils/fn_latex_report_utils.R")) {
  cat("   • Check utility functions path\n")
}

cat("\n=== Diagnosis Complete ===\n") 