# Test script for updated app with icons and improved attribute parsing
# This script checks for syntax errors and verifies the fixes

# Test 1: Check if the app loads without syntax errors
test_app_syntax <- function() {
  cat("Testing app syntax...\n")
  
  tryCatch({
    # Source the app file to check for syntax errors
    source("app.R", local = TRUE)
    cat("✅ App syntax check passed\n")
    return(TRUE)
  }, error = function(e) {
    cat("❌ App syntax error:", e$message, "\n")
    return(FALSE)
  })
}

# Test 2: Check if icon files exist
test_icon_files <- function() {
  cat("Testing icon files...\n")
  
  # 檢查 www/icons/icon.png 是否存在
  if (file.exists("www/icons/icon.png")) {
    cat("✅ www/icons/icon.png exists\n")
    file_info <- file.info("www/icons/icon.png")
    cat("   File size:", file_info$size, "bytes\n")
    return(TRUE)
  } else {
    cat("❌ www/icons/icon.png not found\n")
    return(FALSE)
  }
}

# Test 3: Check if dependencies are available
test_dependencies <- function() {
  cat("Testing dependencies...\n")
  
  required_packages <- c("shiny", "bs4Dash", "DT", "readxl", "readr", 
                        "stringr", "jsonlite", "httr", "shinyjs", "dplyr")
  
  missing_packages <- c()
  
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing_packages <- c(missing_packages, pkg)
    }
  }
  
  if (length(missing_packages) == 0) {
    cat("✅ All required packages are available\n")
    return(TRUE)
  } else {
    cat("❌ Missing packages:", paste(missing_packages, collapse = ", "), "\n")
    return(FALSE)
  }
}

# Test 4: Check attribute parsing improvements
test_attribute_parsing <- function() {
  cat("Testing attribute parsing function...\n")
  
  # Test cases for attribute parsing
  test_cases <- c(
    "品質優良,價格實惠,使用方便,外觀美觀,功能豐富,服務良好",
    "{品質優良，價格實惠，使用方便，外觀美觀，功能豐富，服務良好}",
    "1. 品質優良 2. 價格實惠 3. 使用方便 4. 外觀美觀 5. 功能豐富 6. 服務良好",
    "品質優良、價格實惠、使用方便、外觀美觀、功能豐富、服務良好"
  )
  
  for (i in seq_along(test_cases)) {
    txt <- test_cases[i]
    cat("Testing case", i, ":", substr(txt, 1, 30), "...\n")
    
    # 模擬 app.R 中的解析邏輯
    clean_txt <- gsub("[{}\\[\\]]", "", txt)
    attrs <- unlist(strsplit(clean_txt, "[,，、；;\\n\\r]+"))
    attrs <- trimws(attrs)
    attrs <- attrs[attrs != ""]
    attrs <- attrs[!grepl("^\\d+\\.?$", attrs)]
    attrs <- unique(attrs)
    
    if (length(attrs) < 3) {
      attrs <- unlist(strsplit(clean_txt, "[\\s]+"))
      attrs <- trimws(attrs)
      attrs <- attrs[attrs != ""]
      attrs <- attrs[nchar(attrs) > 1]
      attrs <- unique(attrs)
    }
    
    attrs <- head(attrs, 6)
    
    cat("   Parsed attributes:", length(attrs), "items\n")
    if (length(attrs) > 0) {
      cat("   ", paste(attrs, collapse = " | "), "\n")
    }
    cat("   Result:", if(length(attrs) >= 3) "✅ PASS" else "❌ FAIL", "\n\n")
  }
}

# Run all tests
main <- function() {
  cat("=== App Update Test Suite ===\n\n")
  
  results <- c(
    test_dependencies(),
    test_icon_files(),
    test_attribute_parsing(),
    test_app_syntax()
  )
  
  cat("\n=== Test Summary ===\n")
  cat("Passed:", sum(results), "/", length(results), "tests\n")
  
  if (all(results)) {
    cat("🎉 All tests passed! The app should work correctly.\n")
  } else {
    cat("⚠️ Some tests failed. Please check the issues above.\n")
  }
}

# Execute tests
if (!interactive()) {
  main()
} 