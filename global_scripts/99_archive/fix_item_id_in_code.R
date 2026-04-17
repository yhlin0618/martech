#!/usr/bin/env Rscript
# =============================================================
# Fix item_id references in R code files
# This script replaces item_id with product_id in all R files
# Date: 2025-08-03
# =============================================================

library(stringr)

# Function to fix item_id references in a file
fix_item_id_in_file <- function(file_path) {
  tryCatch({
    # Read file content
    content <- readLines(file_path, warn = FALSE)
    original_content <- content
    
    # Define replacement patterns
    replacements <- list(
      # Column references in data operations
      c('item_id %in%', 'product_id %in%'),
      c('filter\\(item_id', 'filter(product_id'),
      c('filter\\(!item_id', 'filter(!product_id'),
      c('pull\\(item_id', 'pull(product_id'),
      c('select\\(item_id', 'select(product_id'),
      c('mutate\\(item_id', 'mutate(product_id'),
      c('rename\\(item_id', 'rename(product_id'),
      c('arrange\\(item_id', 'arrange(product_id'),
      c('"item_id"', '"product_id"'),
      c("'item_id'", "'product_id'"),
      
      # pivot_longer specific patterns
      c('-c\\("item_id"', '-c("product_id"'),
      c("-c\\('item_id'", "-c('product_id'"),
      c('cols = -item_id', 'cols = -product_id'),
      
      # Column existence checks
      c('"item_id" %in% names', '"product_id" %in% names'),
      c("'item_id' %in% names", "'product_id' %in% names"),
      c('!"item_id" %in%', '!"product_id" %in%'),
      c("!'item_id' %in%", "!'product_id' %in%"),
      
      # dplyr operations
      c('dplyr::filter\\(item_id', 'dplyr::filter(product_id'),
      c('dplyr::filter\\(!item_id', 'dplyr::filter(!product_id'),
      c('dplyr::select\\(item_id', 'dplyr::select(product_id'),
      c('dplyr::mutate\\(item_id', 'dplyr::mutate(product_id'),
      c('dplyr::arrange\\(item_id', 'dplyr::arrange(product_id'),
      
      # Variable assignments
      c('item_id <-', 'product_id <-'),
      c('item_id =', 'product_id ='),
      
      # Variable references in loops and data frames
      c('item_id_groups', 'product_id_groups'),
      c('item_id_data', 'product_id_data'),
      c('~item_id', '~product_id'),
      
      # Function parameters
      c('\\$item_id', '$product_id'),
      c('\\[\\["item_id"\\]\\]', '[["product_id"]]'),
      c("\\[\\['item_id'\\]\\]", "[['product_id']]"),
      
      # Comments and documentation (preserve context)
      c('item_id column', 'product_id column'),
      c('item_id field', 'product_id field'),
      c('item identifier', 'product identifier')
    )
    
    # Apply replacements
    changes_made <- FALSE
    for (pattern in replacements) {
      new_content <- gsub(pattern[1], pattern[2], content, perl = TRUE)
      if (!identical(content, new_content)) {
        content <- new_content
        changes_made <- TRUE
      }
    }
    
    # Write back only if changes were made
    if (changes_made) {
      writeLines(content, file_path)
      return(TRUE)
    }
    
    return(FALSE)
    
  }, error = function(e) {
    message("❌ Error processing file '", file_path, "': ", e$message)
    return(FALSE)
  })
}

# Main function
main <- function() {
  message("\n🔧 FIXING ITEM_ID REFERENCES IN R CODE")
  message(strrep("=", 60))
  
  # Find all R files in the components directory
  r_files <- list.files(
    path = "scripts/global_scripts/10_rshinyapp_components",
    pattern = "\\.R$",
    recursive = TRUE,
    full.names = TRUE
  )
  
  # Add other directories with R files
  additional_dirs <- c(
    "scripts/global_scripts/11_rshinyapp_utils",
    "scripts/global_scripts/04_utils"
  )
  
  for (dir in additional_dirs) {
    if (dir.exists(dir)) {
      more_files <- list.files(
        path = dir,
        pattern = "\\.R$",
        recursive = TRUE,
        full.names = TRUE
      )
      r_files <- c(r_files, more_files)
    }
  }
  
  message("📋 Found ", length(r_files), " R files to check")
  
  # Process each file
  fixed_files <- 0
  for (file in r_files) {
    if (fix_item_id_in_file(file)) {
      message("✅ Fixed: ", basename(file))
      fixed_files <- fixed_files + 1
    }
  }
  
  message("\n📊 SUMMARY:")
  message("  Total files checked: ", length(r_files))
  message("  Files modified: ", fixed_files)
  message("  Files unchanged: ", length(r_files) - fixed_files)
  
  return(list(
    total = length(r_files),
    fixed = fixed_files
  ))
}

# Run if executed directly
if (!interactive()) {
  main()
} else {
  message("ℹ️  To run this script, use: source('scripts/fix_item_id_in_code.R') and then call main()")
  
  # Ask for confirmation
  cat("\n⚠️  This will modify R code files. Continue? (yes/no): ")
  response <- tolower(trimws(readline()))
  
  if (response == "yes" || response == "y") {
    main()
  } else {
    message("❌ Operation cancelled by user.")
  }
}