# =============================================================================
# Test Template Integration
# Purpose: Test that LaTeX content is properly integrated with template.tex
# =============================================================================

# Load required packages
library(dotenv)
library(dplyr)

# Load environment variables
dotenv::load_dot_env(file = ".env")

# Source utility functions
source("scripts/global_scripts/04_utils/fn_latex_report_utils.R")

# Create test data
test_sales_data <- data.frame(
  customer_id = paste0("customer_", 1:5),
  lineitem_price = c(100, 200, 300, 400, 500),
  payment_time = Sys.time() - runif(5, 0, 30) * 24 * 3600,
  product_name = sample(c("產品A", "產品B", "產品C"), 5, replace = TRUE)
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

# Test API key and generate LaTeX
api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
if (api_key != "" && grepl("^sk-", api_key)) {
  cat("\nTesting GPT API call...\n")
  
  result <- fn_generate_latex_via_gpt(
    report_data = report_data,
    api_key = api_key,
    model = "gpt-3.5-turbo",
    temperature = 0.7,
    max_tokens = 1000,
    verbose = TRUE
  )
  
  if (!is.null(result$error)) {
    cat("Error:", result$error, "\n")
  } else {
    cat("Success! Generated LaTeX content:\n")
    cat("Length:", nchar(result$latex), "characters\n")
    
    # Test template integration
    cat("\nTesting template integration...\n")
    
    # Read template
    template_path <- "template.tex"
    if (file.exists(template_path)) {
      template_content <- readLines(template_path, warn = FALSE)
      cat("Template loaded successfully\n")
      
      # Find maketitle position
      maketitle_pos <- which(grepl("\\\\maketitle", template_content))
      if (length(maketitle_pos) > 0) {
        cat("Found \\maketitle at line:", maketitle_pos, "\n")
        
        # Update template metadata
        updated_template <- template_content
        
        # Update title
        title_pos <- which(grepl("\\\\title\\{", updated_template))
        if (length(title_pos) > 0) {
          updated_template[title_pos] <- paste0("\\title{", report_data$metadata$title, "}")
        }
        
        # Update author
        author_pos <- which(grepl("\\\\author\\{", updated_template))
        if (length(author_pos) > 0) {
          updated_template[author_pos] <- paste0("\\author{", report_data$metadata$author, "}")
        }
        
        # Update date
        date_pos <- which(grepl("\\\\date\\{", updated_template))
        if (length(date_pos) > 0) {
          updated_template[date_pos] <- paste0("\\date{", report_data$metadata$date, "}")
        }
        
        # Create complete document
        complete_document <- c(
          updated_template[1:maketitle_pos],
          "",  # Add empty line
          result$latex,  # Insert generated content
          "",  # Add empty line
          updated_template[(maketitle_pos + 1):length(updated_template)]
        )
        
        # Write complete document to file
        output_file <- "test_complete_document.tex"
        writeLines(complete_document, output_file, useBytes = TRUE)
        
        cat("Complete LaTeX document written to:", output_file, "\n")
        cat("Document length:", length(complete_document), "lines\n")
        
        # Show first few lines
        cat("\nFirst 10 lines of complete document:\n")
        cat(paste(complete_document[1:10], collapse = "\n"), "\n")
        
        # Show content insertion point
        cat("\nContent insertion point (around line", maketitle_pos, "):\n")
        start_show <- max(1, maketitle_pos - 2)
        end_show <- min(length(complete_document), maketitle_pos + 5)
        cat(paste(complete_document[start_show:end_show], collapse = "\n"), "\n")
        
      } else {
        cat("Error: Could not find \\maketitle in template\n")
      }
    } else {
      cat("Error: template.tex not found\n")
    }
  }
} else {
  cat("Skipping API test - invalid API key\n")
} 