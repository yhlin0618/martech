# Generating Documentation from Roxygen2 Comments

This guide provides a practical walkthrough of how to generate formatted documentation from roxygen2 comments in your R code.

## Option 1: Setting Up a Minimal Package Structure

The most straightforward way to generate documentation from roxygen2 comments is to create a minimal package structure. This doesn't require distributing your code as a package - it's just for documentation purposes.

### Step 1: Create a Package Structure

```r
# Install required packages if you don't have them
install.packages(c("devtools", "roxygen2", "usethis"))

# Create a temporary directory for the package
temp_dir <- tempdir()
setwd(temp_dir)

# Initialize a package structure
usethis::create_package("precisionMarketingDocs")
```

### Step 2: Copy Functions with Roxygen Comments

Copy your functions with roxygen comments into R files in the `R/` directory of the package structure.

For example, create a file `R/db_utils.R` containing:

```r
#' DuckDB Database Connection Manager
#' 
#' This file provides a centralized way to manage DuckDB database connections
#' across the project.
#'
#' @param dataset Character. The name of the database to connect to
#' @param path_list List. The list of database paths
#' @param read_only Logical. Whether to open the database in read-only mode
#'
#' @return Connection object. The established database connection
#'
#' @examples
#' conn <- dbConnect_from_list("raw_data", read_only = TRUE)
dbConnect_from_list <- function(dataset, path_list = db_path_list, read_only = FALSE) {
  # Function code here
}
```

### Step 3: Generate Documentation

```r
# Set working directory to the package directory
setwd("precisionMarketingDocs")

# Generate documentation
devtools::document()
```

This will create documentation in the `man/` directory and a `NAMESPACE` file.

### Step 4: View the Documentation

```r
# Install the package temporarily
devtools::install()

# Load the package
library(precisionMarketingDocs)

# View the documentation
?dbConnect_from_list
```

Or open the generated `.Rd` files in the `man/` directory directly to view the raw documentation files.

## Option 2: Using Documentation Generators Without a Package

If you prefer not to create a package structure, you can use standalone tools to extract and format roxygen comments.

### Using roxygen2md

The `roxygen2md` package can convert roxygen2 comments to markdown:

```r
# Install the package
install.packages("roxygen2md")

# Create a function to extract documentation from a file
extract_documentation <- function(file_path, output_dir = ".") {
  # Read the file
  lines <- readLines(file_path)
  
  # Extract roxygen blocks and function names
  in_roxygen <- FALSE
  current_doc <- character()
  function_name <- ""
  docs <- list()
  
  for (i in seq_along(lines)) {
    line <- lines[i]
    
    # Start of roxygen block
    if (grepl("^#'", line) && !in_roxygen) {
      in_roxygen <- TRUE
      current_doc <- line
    }
    # Inside roxygen block
    else if (grepl("^#'", line) && in_roxygen) {
      current_doc <- c(current_doc, line)
    }
    # End of roxygen block, get function name
    else if (!grepl("^#'", line) && in_roxygen) {
      in_roxygen <- FALSE
      # Extract function name
      if (grepl("^[a-zA-Z0-9_]+ <- function", line)) {
        function_name <- gsub(" .*", "", line)
        docs[[function_name]] <- current_doc
      }
    }
  }
  
  # Convert roxygen to markdown and write to files
  for (name in names(docs)) {
    md_file <- file.path(output_dir, paste0(name, ".md"))
    
    # Remove roxygen markers and convert to markdown
    md_content <- gsub("^#' ?", "", docs[[name]])
    
    # Write to file
    writeLines(md_content, md_file)
    message("Documentation generated: ", md_file)
  }
}

# Use the function
extract_documentation("path/to/your/script.R", "docs")
```

## Option 3: Create an Automated Documentation Script

Here's a script you can use to automatically generate documentation for all your functions:

```r
# script_name: generate_function_docs.R

library(roxygen2)
library(knitr)

# Directory containing R scripts with roxygen comments
scripts_dir <- "update_scripts/global_scripts"

# Output directory for documentation
docs_dir <- "docs/functions"
dir.create(docs_dir, recursive = TRUE, showWarnings = FALSE)

# Find all R files
r_files <- list.files(scripts_dir, pattern = "\\.R$", recursive = TRUE, full.names = TRUE)

# Process each file
for (file_path in r_files) {
  # Get file contents
  lines <- readLines(file_path, warn = FALSE)
  
  # Extract roxygen blocks and corresponding function names
  roxygen_blocks <- list()
  current_block <- character()
  in_roxygen <- FALSE
  
  for (i in seq_along(lines)) {
    line <- lines[i]
    
    # Start of roxygen block
    if (grepl("^#'", line) && !in_roxygen) {
      in_roxygen <- TRUE
      current_block <- line
    }
    # Continue roxygen block
    else if (grepl("^#'", line) && in_roxygen) {
      current_block <- c(current_block, line)
    }
    # End of roxygen block
    else if (!grepl("^#'", line) && in_roxygen) {
      in_roxygen <- FALSE
      
      # Find function name (look for next line with function definition)
      for (j in i:min(i+5, length(lines))) {
        if (grepl("<- function", lines[j]) || grepl("= function", lines[j])) {
          func_line <- lines[j]
          # Extract function name
          if (grepl("<- function", func_line)) {
            func_name <- trimws(gsub("<- function.*", "", func_line))
          } else {
            func_name <- trimws(gsub("= function.*", "", func_line))
          }
          
          # Store the roxygen block with the function name
          roxygen_blocks[[func_name]] <- current_block
          break
        }
      }
    }
  }
  
  # If blocks were found, generate documentation
  if (length(roxygen_blocks) > 0) {
    # Get relative file path for naming
    rel_path <- gsub(scripts_dir, "", file_path)
    rel_path <- gsub("^/", "", rel_path)
    
    # Create markdown file for the R file
    md_filename <- gsub("\\.R$", ".md", basename(file_path))
    md_path <- file.path(docs_dir, md_filename)
    
    # Start with a header
    md_content <- c(
      paste("# Documentation for", basename(file_path)),
      paste("Source file:", rel_path),
      "",
      "## Functions"
    )
    
    # Process each roxygen block
    for (func_name in names(roxygen_blocks)) {
      block <- roxygen_blocks[[func_name]]
      
      # Transform roxygen to markdown
      md_block <- gsub("^#' ?", "", block)
      
      # Add function heading
      md_content <- c(md_content, "", paste("### `", func_name, "`", sep = ""), "")
      
      # Add documentation content
      md_content <- c(md_content, md_block, "")
    }
    
    # Write the markdown file
    writeLines(md_content, md_path)
    message("Documentation generated for ", basename(file_path), " at ", md_path)
  }
}

# Generate an index file
index_content <- c(
  "# Function Documentation Index",
  "",
  "This document provides links to all function documentation files.",
  "",
  "## Files"
)

md_files <- list.files(docs_dir, pattern = "\\.md$", full.names = FALSE)
for (file in sort(md_files)) {
  index_content <- c(index_content, paste0("- [", gsub("\\.md$", "", file), "](", file, ")"))
}

writeLines(index_content, file.path(docs_dir, "index.md"))
message("Documentation index generated at ", file.path(docs_dir, "index.md"))
```

### How to Use the Script

1. Save the script above as `generate_function_docs.R`
2. Adjust the `scripts_dir` and `docs_dir` paths as needed
3. Run the script:

```r
source("generate_function_docs.R")
```

4. Browse the generated markdown documentation in the `docs/functions` directory

## Integrating with Your Workflow

For ongoing documentation:

1. **Add to your initialization scripts**: Add an option to generate documentation when needed:

```r
# Add to a development initialization script
if (exists("GENERATE_DOCS") && GENERATE_DOCS) {
  source("path/to/generate_function_docs.R")
}
```

2. **Use with git hooks**: Automatically generate documentation before commits

3. **Generate as part of your build process**: If you have a build system, include documentation generation

## Summary

- **Option 1**: Create a minimal package structure (most standard approach)
- **Option 2**: Use custom tools to extract documentation without a package
- **Option 3**: Use the provided script for automatic documentation generation

Each approach has its advantages depending on your workflow. Option 1 integrates with R's built-in help system, while Options 2 and 3 provide more flexibility for custom documentation formats.