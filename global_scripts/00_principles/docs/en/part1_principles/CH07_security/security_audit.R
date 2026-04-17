#!/usr/bin/env Rscript

# ============================================================================
# Security Audit Script - MP110 Compliance Check
# ============================================================================
# Purpose: Scan codebase for security violations per MP110 requirements
# Author: Security Team
# Date: 2025-08-30
# ============================================================================

library(tidyverse)

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Patterns that indicate potential credentials
CREDENTIAL_PATTERNS <- list(
  api_keys = c(
    "sk-[a-zA-Z0-9]{48}",                    # OpenAI style
    "api[_-]?key\\s*=\\s*[\"'][^\"']+[\"']", # Generic API key
    "AKIA[0-9A-Z]{16}",                       # AWS access key
    "AIza[0-9A-Za-z\\-_]{35}"                 # Google API key
  ),
  passwords = c(
    "password\\s*=\\s*[\"'][^\"']+[\"']",
    "pwd\\s*=\\s*[\"'][^\"']+[\"']",
    "pass\\s*=\\s*[\"'][^\"']+[\"']",
    "passwd\\s*=\\s*[\"'][^\"']+[\"']"
  ),
  tokens = c(
    "token\\s*=\\s*[\"'][^\"']+[\"']",
    "bearer\\s+[a-zA-Z0-9\\-._~+/]+=*",
    "auth\\s*=\\s*[\"'][^\"']+[\"']"
  ),
  database = c(
    "postgres://[^\\s]+",
    "mysql://[^\\s]+",
    "mongodb\\+srv://[^\\s]+"
  )
)

# File extensions to scan
SCAN_EXTENSIONS <- c(
  "\\.R$", "\\.r$", "\\.Rmd$", "\\.qmd$",
  "\\.py$", "\\.js$", "\\.jsx$", "\\.ts$", "\\.tsx$",
  "\\.yml$", "\\.yaml$", "\\.json$", "\\.env$",
  "\\.sh$", "\\.bash$", "\\.config$"
)

# Paths to exclude from scanning
EXCLUDE_PATHS <- c(
  "/\\.git/",
  "/node_modules/",
  "/venv/",
  "/\\.Rproj\\.user/",
  "/archive/",
  "/00_principles/"  # Don't scan principle documentation itself
)

# -----------------------------------------------------------------------------
# Core Functions
# -----------------------------------------------------------------------------

#' Scan file for credential patterns
#' @param file_path Path to file to scan
#' @return Data frame of violations found
scan_file <- function(file_path) {
  violations <- tibble()
  
  tryCatch({
    content <- readLines(file_path, warn = FALSE)
    
    for (category in names(CREDENTIAL_PATTERNS)) {
      patterns <- CREDENTIAL_PATTERNS[[category]]
      
      for (pattern in patterns) {
        for (line_num in seq_along(content)) {
          line <- content[line_num]
          
          if (grepl(pattern, line, perl = TRUE)) {
            # Skip if it's a comment about not using credentials
            if (grepl("NEVER|DO NOT|VIOLATION|never|don't", line, ignore.case = TRUE)) {
              next
            }
            
            violations <- bind_rows(
              violations,
              tibble(
                file = file_path,
                line = line_num,
                category = category,
                pattern = pattern,
                content = substr(line, 1, 100),  # Truncate for safety
                severity = "CRITICAL"
              )
            )
          }
        }
      }
    }
    
  }, error = function(e) {
    message(sprintf("Error scanning %s: %s", file_path, e$message))
  })
  
  return(violations)
}

#' Check if .gitignore has required entries
#' @param gitignore_path Path to .gitignore file
#' @return Logical indicating if properly configured
check_gitignore <- function(gitignore_path = ".gitignore") {
  required_entries <- c(
    ".env",
    "*.key",
    "*.pem",
    "*secret*",
    "*password*",
    ".Renviron",
    ".Rprofile"
  )
  
  if (!file.exists(gitignore_path)) {
    message("⚠️  WARNING: No .gitignore file found!")
    return(FALSE)
  }
  
  content <- readLines(gitignore_path, warn = FALSE)
  missing <- character()
  
  for (entry in required_entries) {
    if (!any(grepl(entry, content, fixed = TRUE))) {
      missing <- c(missing, entry)
    }
  }
  
  if (length(missing) > 0) {
    message("⚠️  Missing .gitignore entries:")
    for (m in missing) {
      message(sprintf("   - %s", m))
    }
    return(FALSE)
  }
  
  message("✅ .gitignore properly configured")
  return(TRUE)
}

#' Check environment variable usage
#' @param file_path Path to R file
#' @return Data frame of environment variable usage
check_env_usage <- function(file_path) {
  env_usage <- tibble()
  
  tryCatch({
    content <- readLines(file_path, warn = FALSE)
    
    for (line_num in seq_along(content)) {
      line <- content[line_num]
      
      # Check for Sys.getenv usage
      if (grepl("Sys\\.getenv\\(", line)) {
        env_usage <- bind_rows(
          env_usage,
          tibble(
            file = file_path,
            line = line_num,
            type = "good_practice",
            content = substr(line, 1, 100)
          )
        )
      }
      
      # Check for direct credential assignment (bad)
      if (grepl("(api_key|password|token|secret)\\s*<-\\s*[\"']", line, ignore.case = TRUE)) {
        if (!grepl("Sys\\.getenv", line)) {
          env_usage <- bind_rows(
            env_usage,
            tibble(
              file = file_path,
              line = line_num,
              type = "violation",
              content = substr(line, 1, 100)
            )
          )
        }
      }
    }
  }, error = function(e) {
    message(sprintf("Error checking %s: %s", file_path, e$message))
  })
  
  return(env_usage)
}

#' Get all files to scan
#' @param root_dir Root directory to scan
#' @return Vector of file paths
get_scan_files <- function(root_dir = ".") {
  all_files <- list.files(
    root_dir,
    recursive = TRUE,
    full.names = TRUE,
    all.files = TRUE
  )
  
  # Filter by extension
  pattern <- paste(SCAN_EXTENSIONS, collapse = "|")
  files <- all_files[grepl(pattern, all_files)]
  
  # Exclude paths
  for (exclude in EXCLUDE_PATHS) {
    files <- files[!grepl(exclude, files)]
  }
  
  return(files)
}

# -----------------------------------------------------------------------------
# Main Audit Function
# -----------------------------------------------------------------------------

#' Run complete security audit
#' @param root_dir Directory to audit
#' @param report_file Optional file to save report
run_security_audit <- function(root_dir = ".", report_file = NULL) {
  
  message("=" %.% rep("", 70))
  message("SECURITY AUDIT - MP110 Compliance Check")
  message("=" %.% rep("", 70))
  message(sprintf("Scanning directory: %s", normalizePath(root_dir)))
  message("")
  
  # Step 1: Check .gitignore
  message("Step 1: Checking .gitignore configuration...")
  gitignore_ok <- check_gitignore(file.path(root_dir, ".gitignore"))
  message("")
  
  # Step 2: Get files to scan
  message("Step 2: Identifying files to scan...")
  files <- get_scan_files(root_dir)
  message(sprintf("Found %d files to scan", length(files)))
  message("")
  
  # Step 3: Scan for violations
  message("Step 3: Scanning for credential violations...")
  all_violations <- map_dfr(files, scan_file)
  
  if (nrow(all_violations) > 0) {
    message(sprintf("❌ CRITICAL: Found %d potential credential violations!", nrow(all_violations)))
    message("\nViolations by category:")
    all_violations %>%
      count(category) %>%
      arrange(desc(n)) %>%
      pwalk(~message(sprintf("  %s: %d", ..1, ..2)))
    
    message("\nViolations by file:")
    all_violations %>%
      count(file) %>%
      arrange(desc(n)) %>%
      head(10) %>%
      pwalk(~message(sprintf("  %s: %d", basename(..1), ..2)))
  } else {
    message("✅ No credential violations detected")
  }
  message("")
  
  # Step 4: Check environment variable usage
  message("Step 4: Checking environment variable usage...")
  r_files <- files[grepl("\\.R$|\\.r$", files)]
  env_checks <- map_dfr(r_files, check_env_usage)
  
  good_practices <- env_checks %>% filter(type == "good_practice")
  bad_practices <- env_checks %>% filter(type == "violation")
  
  message(sprintf("✅ Found %d proper Sys.getenv() usages", nrow(good_practices)))
  if (nrow(bad_practices) > 0) {
    message(sprintf("⚠️  Found %d suspicious credential assignments", nrow(bad_practices)))
  }
  message("")
  
  # Step 5: Generate report
  message("Step 5: Generating report...")
  
  report <- list(
    timestamp = Sys.time(),
    directory = normalizePath(root_dir),
    summary = list(
      files_scanned = length(files),
      violations = nrow(all_violations),
      gitignore_ok = gitignore_ok,
      env_usage_good = nrow(good_practices),
      env_usage_bad = nrow(bad_practices)
    ),
    violations = all_violations,
    env_issues = bad_practices
  )
  
  # Save report if requested
  if (!is.null(report_file)) {
    saveRDS(report, report_file)
    message(sprintf("Report saved to: %s", report_file))
    
    # Also save human-readable version
    txt_file <- sub("\\.rds$", ".txt", report_file)
    sink(txt_file)
    cat("SECURITY AUDIT REPORT\n")
    cat("=====================\n\n")
    cat(sprintf("Date: %s\n", report$timestamp))
    cat(sprintf("Directory: %s\n", report$directory))
    cat(sprintf("Files Scanned: %d\n", report$summary$files_scanned))
    cat(sprintf("Violations Found: %d\n", report$summary$violations))
    cat(sprintf(".gitignore OK: %s\n", report$summary$gitignore_ok))
    cat("\n")
    
    if (nrow(all_violations) > 0) {
      cat("CRITICAL VIOLATIONS:\n")
      cat("-------------------\n")
      for (i in 1:min(20, nrow(all_violations))) {
        v <- all_violations[i,]
        cat(sprintf("\nFile: %s\n", v$file))
        cat(sprintf("Line: %d\n", v$line))
        cat(sprintf("Category: %s\n", v$category))
        cat(sprintf("Content: %s\n", v$content))
      }
    }
    sink()
    message(sprintf("Text report saved to: %s", txt_file))
  }
  
  message("")
  message("=" %.% rep("", 70))
  
  # Return status
  audit_passed <- (nrow(all_violations) == 0) && 
                  gitignore_ok && 
                  (nrow(bad_practices) == 0)
  
  if (audit_passed) {
    message("✅ SECURITY AUDIT PASSED")
  } else {
    message("❌ SECURITY AUDIT FAILED - IMMEDIATE ACTION REQUIRED")
    message("\nRequired Actions:")
    if (!gitignore_ok) {
      message("1. Update .gitignore with required security entries")
    }
    if (nrow(all_violations) > 0) {
      message("2. Remove all hardcoded credentials from source files")
      message("3. Rotate any exposed credentials immediately")
    }
    if (nrow(bad_practices) > 0) {
      message("4. Convert credential assignments to use Sys.getenv()")
    }
  }
  
  message("=" %.% rep("", 70))
  
  return(invisible(report))
}

# -----------------------------------------------------------------------------
# Execute Audit (if run directly)
# -----------------------------------------------------------------------------

if (!interactive()) {
  # Parse command line arguments
  args <- commandArgs(trailingOnly = TRUE)
  
  if (length(args) == 0) {
    root_dir <- "."
  } else {
    root_dir <- args[1]
  }
  
  # Run audit
  report <- run_security_audit(
    root_dir = root_dir,
    report_file = sprintf("security_audit_%s.rds", format(Sys.Date(), "%Y%m%d"))
  )
  
  # Exit with appropriate code
  if (report$summary$violations > 0) {
    quit(status = 1)
  } else {
    quit(status = 0)
  }
}