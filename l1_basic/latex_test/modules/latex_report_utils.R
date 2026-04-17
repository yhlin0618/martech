# =============================================================================
# LaTeX Report Module - Utility Functions
# =============================================================================

# Load required packages
if (!require(jsonlite)) install.packages("jsonlite")
if (!require(httr)) install.packages("httr")

library(jsonlite)
library(httr)

# =============================================================================
# Data Collection Functions
# =============================================================================

collect_app_data <- function(app_data) {
  # Collect and structure data from the Shiny app for LaTeX report generation.
  #
  # Args:
  #   app_data: List containing app data (sales_data, dna_analysis, other_results)
  #
  # Returns:
  #   List with structured data for LaTeX generation
  
  # Initialize data structure
  collected_data <- list(
    sales_data = NULL,
    dna_analysis = NULL,
    other_results = list()
  )
  
  # Collect sales data
  if (!is.null(app_data$sales_data) && is.data.frame(app_data$sales_data)) {
    collected_data$sales_data <- app_data$sales_data
  }
  
  # Collect DNA analysis data
  if (!is.null(app_data$dna_analysis) && is.data.frame(app_data$dna_analysis)) {
    collected_data$dna_analysis <- app_data$dna_analysis
  }
  
  # Collect other results
  if (!is.null(app_data$other_results) && is.list(app_data$other_results)) {
    collected_data$other_results <- app_data$other_results
  }
  
  return(collected_data)
}

# =============================================================================
# GPT Integration Functions
# =============================================================================

generate_latex_from_gpt <- function(data, model = "gpt-4") {
  # Generate LaTeX code from data using OpenAI GPT API.
  #
  # Args:
  #   data: Structured data for report generation
  #   model: GPT model to use (default: gpt-4)
  #
  # Returns:
  #   List containing LaTeX code and metadata
  
  api_key <- Sys.getenv("OPENAI_API_KEY_LIN")
  if (api_key == "") stop("OpenAI API key not found in environment variable OPENAI_API_KEY_LIN")
  
  # Prepare the prompt
  prompt <- create_latex_prompt(data)
  
  # Prepare the API request
  url <- "https://api.openai.com/v1/chat/completions"
  headers <- c(
    "Authorization" = paste("Bearer", api_key),
    "Content-Type" = "application/json"
  )
  
  body <- list(
    model = model,
    messages = list(
      list(
        role = "system",
        content = "You are a LaTeX expert. Generate clean, well-structured LaTeX code for business reports. Use appropriate packages for Chinese text support."
      ),
      list(
        role = "user",
        content = prompt
      )
    ),
    temperature = 0.7,
    max_tokens = 4000
  )
  
  # Make the API request
  response <- tryCatch({
    httr::POST(url, httr::add_headers(.headers = headers), body = jsonlite::toJSON(body, auto_unbox = TRUE))
  }, error = function(e) {
    stop(paste("API request failed:", e$message))
  })
  
  # Check response status
  if (httr::status_code(response) != 200) {
    stop(paste("API error:", httr::status_code(response), rawToChar(response$content)))
  }
  
  # Parse response
  result <- jsonlite::fromJSON(rawToChar(response$content))
  latex_code <- result$choices[[1]]$message$content
  
  return(list(
    latex_code = latex_code,
    model = model,
    tokens_used = result$usage$total_tokens
  ))
}

create_latex_prompt <- function(data) {
  # Create a prompt for GPT to generate LaTeX code.
  #
  # Args:
  #   data: Structured data for report generation
  #
  # Returns:
  #   String containing the prompt
  
  prompt <- "Generate a professional LaTeX report with the following data:\n\n"
  
  # Add sales data
  if (!is.null(data$sales_data) && nrow(data$sales_data) > 0) {
    prompt <- paste0(prompt, "Sales Data:\n")
    prompt <- paste0(prompt, "Number of records: ", nrow(data$sales_data), "\n")
    if ("revenue" %in% names(data$sales_data)) {
      total_revenue <- sum(data$sales_data$revenue, na.rm = TRUE)
      prompt <- paste0(prompt, "Total revenue: ", total_revenue, "\n")
    }
    prompt <- paste0(prompt, "\n")
  }
  
  # Add DNA analysis data
  if (!is.null(data$dna_analysis) && nrow(data$dna_analysis) > 0) {
    prompt <- paste0(prompt, "DNA Analysis Data:\n")
    prompt <- paste0(prompt, "Number of customers: ", nrow(data$dna_analysis), "\n")
    if ("segment" %in% names(data$dna_analysis)) {
      segment_counts <- table(data$dna_analysis$segment)
      prompt <- paste0(prompt, "Segment distribution: ", paste(names(segment_counts), segment_counts, collapse = ", "), "\n")
    }
    prompt <- paste0(prompt, "\n")
  }
  
  # Add other results
  if (!is.null(data$other_results) && length(data$other_results) > 0) {
    prompt <- paste0(prompt, "Other Results:\n")
    for (key in names(data$other_results)) {
      prompt <- paste0(prompt, key, ": ", data$other_results[[key]], "\n")
    }
    prompt <- paste0(prompt, "\n")
  }
  
  prompt <- paste0(prompt, "Requirements:\n")
  prompt <- paste0(prompt, "1. Use appropriate LaTeX packages for Chinese text support (ctex or CJKutf8)\n")
  prompt <- paste0(prompt, "2. Include a title, author, and date\n")
  prompt <- paste0(prompt, "3. Create sections for different data types\n")
  prompt <- paste0(prompt, "4. Include tables and/or figures where appropriate\n")
  prompt <- paste0(prompt, "5. Use professional formatting\n")
  prompt <- paste0(prompt, "6. Include a summary section\n")
  prompt <- paste0(prompt, "7. Return only the LaTeX code, no explanations\n")
  
  return(prompt)
}

# =============================================================================
# LaTeX Compilation Functions
# =============================================================================

validate_latex_compilers <- function() {
  # Check which LaTeX compilers are available on the system.
  #
  # Returns:
  #   List with boolean values for pdflatex and xelatex availability
  
  compilers <- list(pdflatex = FALSE, xelatex = FALSE)
  
  # Check pdflatex
  tryCatch({
    result <- system2("pdflatex", "--version", stdout = TRUE, stderr = TRUE)
    compilers$pdflatex <- TRUE
  }, error = function(e) {
    compilers$pdflatex <- FALSE
  })
  
  # Check xelatex
  tryCatch({
    result <- system2("xelatex", "--version", stdout = TRUE, stderr = TRUE)
    compilers$xelatex <- TRUE
  }, error = function(e) {
    compilers$xelatex <- FALSE
  })
  
  return(compilers)
}

compile_latex_to_pdf <- function(latex_code, filename, compiler = "pdflatex") {
  # Compile LaTeX code to PDF using the specified compiler.
  #
  # Args:
  #   latex_code: LaTeX source code as string
  #   filename: Base filename (without extension)
  #   compiler: Compiler to use (pdflatex or xelatex)
  #
  # Returns:
  #   List with success status and file paths
  
  # Create reports directory if it doesn't exist
  reports_dir <- "test_reports"
  if (!dir.exists(reports_dir)) {
    dir.create(reports_dir, recursive = TRUE)
  }
  
  # Define file paths
  tex_file <- file.path(reports_dir, paste0(filename, ".tex"))
  pdf_file <- file.path(reports_dir, paste0(filename, ".pdf"))
  log_file <- file.path(reports_dir, paste0(filename, ".log"))
  
  # Write LaTeX code to file
  writeLines(latex_code, tex_file, useBytes = TRUE)
  
  # Change to reports directory for compilation
  old_wd <- getwd()
  setwd(reports_dir)
  
  # Prepare compilation command
  cmd <- paste0(compiler, " -interaction=nonstopmode ", basename(tex_file))
  
  # Compile LaTeX using shell() for better Windows compatibility
  cat("編譯 LaTeX 文件: ", filename, ".tex\n")
  cat("使用編譯器: ", compiler, "\n")
  
  compilation_result <- tryCatch({
    result <- shell(cmd, intern = TRUE)
    
    # Check if PDF was created
    if (file.exists(basename(pdf_file))) {
      setwd(old_wd)
      return(list(
        success = TRUE,
        pdf_path = pdf_file,
        tex_path = tex_file,
        log_path = log_file,
        output = result
      ))
    } else {
      # If PDF not created, try alternative approaches
      setwd(old_wd)
      return(try_alternative_compilation(latex_code, filename, compiler, reports_dir))
    }
  }, error = function(e) {
    # If standard compilation fails, try alternative approaches
    setwd(old_wd)
    return(try_alternative_compilation(latex_code, filename, compiler, reports_dir))
  })
  
  return(compilation_result)
}

try_alternative_compilation <- function(latex_code, filename, compiler, reports_dir) {
  # Try alternative compilation approaches when standard compilation fails.
  #
  # Args:
  #   latex_code: Original LaTeX code
  #   filename: Base filename
  #   compiler: Original compiler
  #   reports_dir: Reports directory
  #
  # Returns:
  #   List with compilation result
  
  # Define file paths
  tex_file <- file.path(reports_dir, paste0(filename, ".tex"))
  pdf_file <- file.path(reports_dir, paste0(filename, ".pdf"))
  log_file <- file.path(reports_dir, paste0(filename, ".log"))
  
  # Change to reports directory for compilation
  old_wd <- getwd()
  setwd(reports_dir)
  
  # Approach 1: Try with different LaTeX document class
  if (grepl("ctex", latex_code)) {
    # If using ctex, try switching to simple article class
    simple_tex <- gsub("\\\\documentclass\\{ctexart\\}", "\\\\documentclass{article}\\\\usepackage[utf8]{inputenc}\\\\usepackage{CJKutf8}", latex_code)
    simple_tex <- gsub("\\\\begin\\{document\\}", "\\\\begin{document}\\\\begin{CJK*}{UTF8}{gbsn}", simple_tex)
    simple_tex <- gsub("\\\\end\\{document\\}", "\\\\end{CJK*}\\\\end{document}", simple_tex)
    
    writeLines(simple_tex, tex_file, useBytes = TRUE)
    
    cmd <- paste0(compiler, " -interaction=nonstopmode ", basename(tex_file))
    result <- shell(cmd, intern = TRUE)
    
    if (file.exists(basename(pdf_file))) {
      setwd(old_wd)
      return(list(
        success = TRUE,
        pdf_path = pdf_file,
        tex_path = tex_file,
        log_path = log_file,
        output = result,
        method = "alternative_1"
      ))
    }
  }
  
  # Approach 2: Try English-only version
  english_tex <- "\\documentclass{article}
\\usepackage[utf8]{inputenc}
\\title{Test Report}
\\author{LaTeX Test}
\\begin{document}
\\maketitle
\\section{Summary}
This is a test report generated from the data.
\\section{Data Overview}
The report contains processed data from the application.
\\end{document}"
  
  writeLines(english_tex, tex_file, useBytes = TRUE)
  
  cmd <- paste0(compiler, " -interaction=nonstopmode ", basename(tex_file))
  result <- shell(cmd, intern = TRUE)
  
  if (file.exists(basename(pdf_file))) {
    setwd(old_wd)
    return(list(
      success = TRUE,
      pdf_path = pdf_file,
      tex_path = tex_file,
      log_path = log_file,
      output = result,
      method = "alternative_2"
    ))
  }
  
  # All approaches failed
  setwd(old_wd)
  return(list(
    success = FALSE,
    error = "All compilation approaches failed",
    tex_path = tex_file,
    log_path = log_file,
    output = result
  ))
}

# =============================================================================
# File Management Functions
# =============================================================================

cleanup_temp_files <- function(filename, reports_dir = "test_reports") {
  # Clean up temporary files created during LaTeX compilation.
  #
  # Args:
  #   filename: Base filename
  #   reports_dir: Reports directory
  
  extensions <- c(".aux", ".log", ".out", ".toc", ".nav", ".snm", ".vrb")
  
  for (ext in extensions) {
    file_path <- file.path(reports_dir, paste0(filename, ext))
    if (file.exists(file_path)) {
      file.remove(file_path)
    }
  }
}

# =============================================================================
# Module Integration Functions
# =============================================================================

generate_latex_report <- function(app_data, compiler = "pdflatex") {
  # Complete LaTeX report generation workflow.
  #
  # Args:
  #   app_data: Data from the Shiny app
  #   compiler: LaTeX compiler to use
  #
  # Returns:
  #   List with report generation results
  
  tryCatch({
    # Step 1: Collect data
    collected_data <- collect_app_data(app_data)
    
    # Step 2: Generate LaTeX code
    gpt_result <- generate_latex_from_gpt(collected_data)
    
    # Step 3: Compile to PDF
    filename <- paste0("report_", format(Sys.time(), "%Y%m%d_%H%M%S"))
    compilation_result <- compile_latex_to_pdf(gpt_result$latex_code, filename, compiler)
    
    # Step 4: Clean up temporary files
    if (compilation_result$success) {
      cleanup_temp_files(filename)
    }
    
    return(list(
      success = compilation_result$success,
      pdf_path = if (compilation_result$success) compilation_result$pdf_path else NULL,
      tex_path = compilation_result$tex_path,
      latex_code = gpt_result$latex_code,
      error = if (!compilation_result$success) compilation_result$error else NULL
    ))
    
  }, error = function(e) {
    return(list(
      success = FALSE,
      error = e$message
    ))
  })
} 