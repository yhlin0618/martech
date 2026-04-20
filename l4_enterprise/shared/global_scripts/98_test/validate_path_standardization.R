# Path Standardization Validation Script
# Tests compliance with R114: Standard Path Constants Rule

# Initialize environment
autoinit()

#' Validate Path Standardization Compliance
#' 
#' Checks global_scripts directory for hardcoded path violations
validate_path_standardization <- function() {
  
  cat("🔍 Validating Path Standardization Compliance (R114)\n")
  cat("=" %|>% rep(60) %|>% paste(collapse = ""), "\n")
  
  violations <- list()
  
  # Get all R files in global_scripts
  r_files <- get_r_files_recursive(GLOBAL_DIR)
  
  cat("📂 Scanning", length(r_files), "R files in global_scripts...\n\n")
  
  for (file_path in r_files) {
    
    # Skip this validation script itself
    if (grepl("validate_path_standardization.R", file_path)) next
    
    # Read file content
    content <- readLines(file_path, warn = FALSE)
    file_violations <- c()
    
    # Check for common hardcoded path patterns
    
    # 1. Relative paths with ../../../..
    relative_violations <- grep("\\.\\.(\\/|\\\\)\\.\\.(\\/|\\\\)\\.\\.(\\/|\\\\)\\.\\.", content)
    if (length(relative_violations) > 0) {
      file_violations <- c(file_violations, 
                          paste("Line", relative_violations, ": Hardcoded relative paths (../../..)"))
    }
    
    # 2. Hardcoded scripts/global_scripts (but allow in fallbacks and comments)
    scripts_violations <- grep('scripts(\\/|\\\\)global_scripts', content)
    # Filter out comments and fallback patterns
    scripts_violations <- scripts_violations[!grepl("^\\s*#", content[scripts_violations])]
    scripts_violations <- scripts_violations[!grepl("fallback|legacy|deprecated", 
                                                   content[scripts_violations], ignore.case = TRUE)]
    if (length(scripts_violations) > 0) {
      file_violations <- c(file_violations,
                          paste("Line", scripts_violations, ": Hardcoded 'scripts/global_scripts' path"))
    }
    
    # 3. Hardcoded app_config.yaml (without path constants)
    config_violations <- grep('"app_config\\.yaml"', content)
    # Filter out lines that use CONFIG_PATH
    config_violations <- config_violations[!grepl("CONFIG_PATH", content[config_violations])]
    if (length(config_violations) > 0) {
      file_violations <- c(file_violations,
                          paste("Line", config_violations, ": Hardcoded 'app_config.yaml' path"))
    }
    
    # 4. Update_scripts path without constants
    update_violations <- grep('update_scripts(\\/|\\\\)global_scripts', content)
    update_violations <- update_violations[!grepl("^\\s*#", content[update_violations])]
    update_violations <- update_violations[!grepl("GLOBAL_DIR|fallback", content[update_violations])]
    if (length(update_violations) > 0) {
      file_violations <- c(file_violations,
                          paste("Line", update_violations, ": Hardcoded 'update_scripts/global_scripts' path"))
    }
    
    if (length(file_violations) > 0) {
      violations[[file_path]] <- file_violations
    }
  }
  
  # Report results
  if (length(violations) == 0) {
    cat("✅ Path Standardization Validation PASSED\n")
    cat("No hardcoded path violations found!\n\n")
    return(TRUE)
  } else {
    cat("❌ Path Standardization Validation FAILED\n")
    cat("Found violations in", length(violations), "files:\n\n")
    
    for (file_path in names(violations)) {
      rel_path <- sub(paste0("^", GLOBAL_DIR, "/"), "", file_path)
      cat("📄", rel_path, "\n")
      for (violation in violations[[file_path]]) {
        cat("   ⚠️ ", violation, "\n")
      }
      cat("\n")
    }
    
    cat("💡 Recommended fixes:\n")
    cat("   • Replace ../../.. with appropriate path constants\n")
    cat("   • Use GLOBAL_DIR instead of 'scripts/global_scripts'\n")
    cat("   • Use CONFIG_PATH instead of 'app_config.yaml'\n")
    cat("   • Ensure autoinit() is called before using path constants\n\n")
    
    return(FALSE)
  }
}

#' Test Path Constants Availability
#' 
#' Verifies that all required path constants are available
test_path_constants <- function() {
  
  cat("🧪 Testing Path Constants Availability\n")
  cat("=" %|>% rep(40) %|>% paste(collapse = ""), "\n")
  
  required_constants <- c(
    "APP_DIR", "COMPANY_DIR", "GLOBAL_DIR", 
    "GLOBAL_DATA_DIR", "GLOBAL_PARAMETER_DIR",
    "APP_DATA_DIR", "APP_PARAMETER_DIR", "LOCAL_DATA_DIR",
    "CONFIG_PATH"
  )
  
  missing_constants <- c()
  
  for (const in required_constants) {
    if (!exists(const)) {
      missing_constants <- c(missing_constants, const)
      cat("❌", const, "- NOT AVAILABLE\n")
    } else {
      value <- get(const)
      cat("✅", const, "=", value, "\n")
    }
  }
  
  if (length(missing_constants) == 0) {
    cat("\n✅ All path constants are available!\n\n")
    return(TRUE)
  } else {
    cat("\n❌ Missing constants:", paste(missing_constants, collapse = ", "), "\n")
    cat("💡 Ensure autoinit() has been called before using this script.\n\n")
    return(FALSE)
  }
}

#' Main validation function
main_validation <- function() {
  
  cat("🚀 R114 Path Standardization Validation\n")
  cat("=" %|>% rep(60) %|>% paste(collapse = ""), "\n\n")
  
  # Test 1: Path constants availability
  constants_ok <- test_path_constants()
  
  # Test 2: Path standardization compliance
  if (constants_ok) {
    compliance_ok <- validate_path_standardization()
    
    # Overall result
    if (compliance_ok) {
      cat("🎉 OVERALL RESULT: PASSED\n")
      cat("Path standardization is compliant with R114!\n")
    } else {
      cat("⚠️  OVERALL RESULT: FAILED\n") 
      cat("Path standardization needs attention.\n")
    }
  } else {
    cat("⚠️  OVERALL RESULT: INCOMPLETE\n")
    cat("Cannot validate compliance without path constants.\n")
  }
}

# Execute validation if script is run directly
if (!interactive()) {
  main_validation()
}