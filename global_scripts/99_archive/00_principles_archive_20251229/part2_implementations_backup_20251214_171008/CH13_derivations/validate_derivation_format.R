#!/usr/bin/env Rscript

#' @title Derivation Format Validator
#' @description Validates that derivation files comply with DM_R044 standard
#' @author Claude
#' @date 2025-09-29
#' @principle DM_R044 Derivation Implementation Standard
#' @principle DM_R042 DRV Sequential Numbering Rule

# ==============================================================================
# Configuration
# ==============================================================================

# Define validation rules based on DM_R044
REQUIRED_HEADER_FIELDS <- c(
  "DERIVATION:",
  "VERSION:",
  "PLATFORM:",
  "GROUP:",
  "SEQUENCE:",
  "PURPOSE:",
  "CONSUMES:",
  "PRODUCES:",
  "PRINCIPLE:"
)

REQUIRED_PARTS <- c(
  "PART 1: INITIALIZE",
  "PART 2: MAIN",
  "PART 3: TEST",
  "PART 4: SUMMARIZE",
  "PART 5: DEINITIALIZE"
)

REQUIRED_DOC_FIELDS <- c(
  "@title",
  "@description",
  "@requires",
  "@input_tables",
  "@output_tables",
  "@platform"
)

VALID_PLATFORMS <- c("cbz", "amz", "eby", "all")

# ==============================================================================
# Validation Functions
# ==============================================================================

#' Validate derivation filename format
#' @param filename The filename to validate
#' @return List with validation result and details
validate_filename <- function(filename) {
  result <- list(
    valid = FALSE,
    filename = filename,
    errors = character(),
    warnings = character()
  )

  # Check pattern: {platform}_D{group}_{seq}.R
  pattern <- "^([a-z]{3}|all)_D([0-9]{2})_([0-9]{2})\\.R$"

  if (!grepl(pattern, basename(filename))) {
    result$errors <- c(result$errors,
                       sprintf("Invalid filename format. Expected: {platform}_D{group}_{seq}.R, Got: %s",
                              basename(filename)))
    return(result)
  }

  # Extract components
  matches <- regmatches(basename(filename), regexec(pattern, basename(filename)))[[1]]
  result$platform <- matches[2]
  result$group <- matches[3]
  result$sequence <- matches[4]

  # Validate platform
  if (!result$platform %in% VALID_PLATFORMS) {
    result$errors <- c(result$errors,
                       sprintf("Invalid platform_id: %s. Must be one of: %s",
                              result$platform, paste(VALID_PLATFORMS, collapse = ", ")))
  }

  result$valid <- length(result$errors) == 0
  return(result)
}

#' Validate P-number on line 2
#' @param lines File content lines
#' @param filename_result Result from filename validation
#' @return List with validation result
validate_p_number <- function(lines, filename_result) {
  result <- list(
    valid = FALSE,
    errors = character(),
    warnings = character()
  )

  if (length(lines) < 2) {
    result$errors <- c(result$errors, "File too short to contain P-number")
    return(result)
  }

  # P-number should be on line 2 (after the header block comment)
  # Find the line after ##### that contains #P
  header_end <- which(grepl("^#####$", lines))[1]
  if (!is.na(header_end) && length(lines) > header_end) {
    p_line <- lines[header_end + 1]
  } else {
    p_line <- lines[2]
  }

  if (!grepl("^#P[0-9]+_D[0-9]+_[0-9]+", p_line)) {
    result$errors <- c(result$errors,
                       sprintf("P-number not found or invalid format on line after header. Expected: #P{n}_D{group}_{seq}"))
    return(result)
  }

  # Extract P-number components
  p_number <- sub("^#", "", p_line)
  p_parts <- strsplit(p_number, "_")[[1]]

  if (length(p_parts) == 3) {
    p_group <- sub("D", "", p_parts[2])
    p_seq <- p_parts[3]

    # Check if P-number matches filename
    if (!is.null(filename_result$group) && p_group != filename_result$group) {
      result$errors <- c(result$errors,
                        sprintf("P-number group (%s) doesn't match filename group (%s)",
                               p_group, filename_result$group))
    }

    if (!is.null(filename_result$sequence) && p_seq != filename_result$sequence) {
      result$errors <- c(result$errors,
                        sprintf("P-number sequence (%s) doesn't match filename sequence (%s)",
                               p_seq, filename_result$sequence))
    }
  } else {
    result$errors <- c(result$errors, "Invalid P-number format")
  }

  result$valid <- length(result$errors) == 0
  result$p_number <- p_number
  return(result)
}

#' Validate header block
#' @param lines File content lines
#' @return List with validation result
validate_header <- function(lines) {
  result <- list(
    valid = FALSE,
    errors = character(),
    warnings = character(),
    header_fields = list()
  )

  # Find header block (between ##### markers)
  header_start <- which(grepl("^#####$", lines))[1]
  if (is.na(header_start)) {
    result$errors <- c(result$errors, "Header block not found (missing ##### delimiter)")
    return(result)
  }

  # Find header content
  header_lines <- character()
  for (i in (header_start + 1):length(lines)) {
    if (grepl("^#####$", lines[i]) || !grepl("^#", lines[i])) {
      break
    }
    header_lines <- c(header_lines, lines[i])
  }

  # Check for required fields
  for (field in REQUIRED_HEADER_FIELDS) {
    if (!any(grepl(paste0("^# ", field), header_lines))) {
      result$errors <- c(result$errors,
                        sprintf("Missing required header field: %s", field))
    } else {
      # Extract field value
      field_line <- header_lines[grepl(paste0("^# ", field), header_lines)][1]
      field_value <- sub(paste0("^# ", field, "\\s*"), "", field_line)
      result$header_fields[[gsub(":", "", field)]] <- field_value
    }
  }

  # Validate platform field if present
  if ("PLATFORM" %in% names(result$header_fields)) {
    platform <- tolower(trimws(result$header_fields$PLATFORM))
    if (!platform %in% VALID_PLATFORMS) {
      result$warnings <- c(result$warnings,
                          sprintf("Invalid platform in header: %s", platform))
    }
  }

  result$valid <- length(result$errors) == 0
  return(result)
}

#' Validate documentation block
#' @param lines File content lines
#' @return List with validation result
validate_documentation <- function(lines) {
  result <- list(
    valid = FALSE,
    errors = character(),
    warnings = character(),
    doc_fields = list()
  )

  # Find roxygen2-style documentation lines
  doc_lines <- grep("^#'", lines, value = TRUE)

  if (length(doc_lines) == 0) {
    result$errors <- c(result$errors, "No documentation block found (missing #' lines)")
    return(result)
  }

  # Check for required documentation fields
  for (field in REQUIRED_DOC_FIELDS) {
    if (!any(grepl(paste0("^#'\\s*", field), doc_lines))) {
      result$errors <- c(result$errors,
                        sprintf("Missing required documentation field: %s", field))
    }
  }

  # Check for optional but recommended fields
  recommended_fields <- c("@author", "@date", "@business_rules")
  for (field in recommended_fields) {
    if (!any(grepl(paste0("^#'\\s*", field), doc_lines))) {
      result$warnings <- c(result$warnings,
                          sprintf("Missing recommended documentation field: %s", field))
    }
  }

  result$valid <- length(result$errors) == 0
  return(result)
}

#' Validate five-part structure
#' @param lines File content lines
#' @return List with validation result
validate_structure <- function(lines) {
  result <- list(
    valid = FALSE,
    errors = character(),
    warnings = character(),
    parts_found = character()
  )

  # Check for each required part
  for (part in REQUIRED_PARTS) {
    if (any(grepl(part, lines, fixed = TRUE))) {
      result$parts_found <- c(result$parts_found, part)
    } else {
      result$errors <- c(result$errors,
                        sprintf("Missing required section: %s", part))
    }
  }

  # Check order of parts
  if (length(result$parts_found) == length(REQUIRED_PARTS)) {
    part_positions <- sapply(result$parts_found, function(part) {
      which(grepl(part, lines, fixed = TRUE))[1]
    })

    if (!all(diff(part_positions) > 0)) {
      result$errors <- c(result$errors, "Parts are not in correct order")
    }
  }

  # Check for autoinit() and autodeinit()
  if (!any(grepl("autoinit\\(\\)", lines))) {
    result$warnings <- c(result$warnings, "autoinit() not found in INITIALIZE section")
  }

  if (!any(grepl("autodeinit\\(\\)", lines))) {
    result$errors <- c(result$errors, "autodeinit() not found in DEINITIALIZE section")
  } else {
    # Check if autodeinit() is the last executable statement
    autodeinit_line <- max(which(grepl("autodeinit\\(\\)", lines)))
    remaining_lines <- lines[(autodeinit_line + 1):length(lines)]
    executable_lines <- remaining_lines[!grepl("^\\s*(#|$)", remaining_lines)]

    # Allow only return statement after autodeinit
    if (length(executable_lines) > 0) {
      if (!all(grepl("^\\s*(final_status|return)", executable_lines))) {
        result$warnings <- c(result$warnings,
                           "Code found after autodeinit() (only return statement allowed)")
      }
    }
  }

  # Check for proper error handling
  if (!any(grepl("tryCatch", lines))) {
    result$warnings <- c(result$warnings, "No tryCatch blocks found for error handling")
  }

  result$valid <- length(result$errors) == 0
  return(result)
}

#' Validate a single derivation file
#' @param filepath Path to the derivation file
#' @return Comprehensive validation report
validate_derivation_file <- function(filepath) {
  cat(sprintf("\n%s\n", paste(rep("=", 70), collapse = "")))
  cat(sprintf("Validating: %s\n", basename(filepath)))
  cat(sprintf("%s\n", paste(rep("-", 70), collapse = "")))

  # Initialize report
  report <- list(
    file = filepath,
    valid = FALSE,
    errors = character(),
    warnings = character(),
    checks = list()
  )

  # Check if file exists
  if (!file.exists(filepath)) {
    report$errors <- c(report$errors, "File does not exist")
    return(report)
  }

  # Read file content
  tryCatch({
    lines <- readLines(filepath, warn = FALSE)
  }, error = function(e) {
    report$errors <- c(report$errors, sprintf("Cannot read file: %s", e$message))
    return(report)
  })

  # 1. Validate filename
  cat("  Checking filename format... ")
  filename_result <- validate_filename(filepath)
  report$checks$filename <- filename_result
  if (!filename_result$valid) {
    cat("❌\n")
    report$errors <- c(report$errors, filename_result$errors)
  } else {
    cat("✅\n")
  }

  # 2. Validate P-number
  cat("  Checking P-number... ")
  p_number_result <- validate_p_number(lines, filename_result)
  report$checks$p_number <- p_number_result
  if (!p_number_result$valid) {
    cat("❌\n")
    report$errors <- c(report$errors, p_number_result$errors)
  } else {
    cat(sprintf("✅ (%s)\n", p_number_result$p_number))
  }

  # 3. Validate header
  cat("  Checking header block... ")
  header_result <- validate_header(lines)
  report$checks$header <- header_result
  if (!header_result$valid) {
    cat("❌\n")
    report$errors <- c(report$errors, header_result$errors)
  } else {
    cat("✅\n")
  }
  report$warnings <- c(report$warnings, header_result$warnings)

  # 4. Validate documentation
  cat("  Checking documentation... ")
  doc_result <- validate_documentation(lines)
  report$checks$documentation <- doc_result
  if (!doc_result$valid) {
    cat("❌\n")
    report$errors <- c(report$errors, doc_result$errors)
  } else {
    cat("✅\n")
  }
  report$warnings <- c(report$warnings, doc_result$warnings)

  # 5. Validate structure
  cat("  Checking five-part structure... ")
  structure_result <- validate_structure(lines)
  report$checks$structure <- structure_result
  if (!structure_result$valid) {
    cat("❌\n")
    report$errors <- c(report$errors, structure_result$errors)
  } else {
    cat("✅\n")
  }
  report$warnings <- c(report$warnings, structure_result$warnings)

  # Overall validation result
  report$valid <- length(report$errors) == 0

  # Print summary
  cat(sprintf("\n  Summary: %s\n",
             ifelse(report$valid, "✅ PASSED", "❌ FAILED")))

  if (length(report$errors) > 0) {
    cat("\n  Errors:\n")
    for (error in report$errors) {
      cat(sprintf("    ❌ %s\n", error))
    }
  }

  if (length(report$warnings) > 0) {
    cat("\n  Warnings:\n")
    for (warning in report$warnings) {
      cat(sprintf("    ⚠️  %s\n", warning))
    }
  }

  return(report)
}

#' Validate all derivation files in a directory
#' @param drv_dir Path to DRV directory
#' @param pattern File pattern to match (default: all .R files)
#' @return Summary report of all validations
validate_drv_directory <- function(drv_dir, pattern = ".*_D[0-9]{2}_[0-9]{2}\\.R$") {
  cat(sprintf("\n%s\n", paste(rep("=", 70), collapse = "")))
  cat(sprintf("DM_R044 DERIVATION FORMAT VALIDATOR\n"))
  cat(sprintf("%s\n", paste(rep("=", 70), collapse = "")))
  cat(sprintf("Directory: %s\n", drv_dir))
  cat(sprintf("Pattern: %s\n", pattern))

  # Find all derivation files
  drv_files <- list.files(drv_dir, pattern = pattern,
                         recursive = TRUE, full.names = TRUE)

  if (length(drv_files) == 0) {
    cat("\n⚠️  No derivation files found matching pattern\n")
    return(NULL)
  }

  cat(sprintf("\nFound %d derivation files to validate\n", length(drv_files)))

  # Validate each file
  results <- lapply(drv_files, validate_derivation_file)

  # Generate summary
  summary <- data.frame(
    file = sapply(results, function(r) basename(r$file)),
    valid = sapply(results, function(r) r$valid),
    errors = sapply(results, function(r) length(r$errors)),
    warnings = sapply(results, function(r) length(r$warnings)),
    stringsAsFactors = FALSE
  )

  # Print summary table
  cat(sprintf("\n%s\n", paste(rep("=", 70), collapse = "")))
  cat("VALIDATION SUMMARY\n")
  cat(sprintf("%s\n", paste(rep("-", 70), collapse = "")))

  # Sort by validity and filename
  summary <- summary[order(!summary$valid, summary$file), ]

  # Print results
  for (i in 1:nrow(summary)) {
    status_icon <- ifelse(summary$valid[i], "✅", "❌")
    cat(sprintf("%s %-30s | Errors: %2d | Warnings: %2d\n",
               status_icon,
               summary$file[i],
               summary$errors[i],
               summary$warnings[i]))
  }

  # Print totals
  cat(sprintf("%s\n", paste(rep("-", 70), collapse = "")))
  cat(sprintf("Total: %d files | Passed: %d | Failed: %d\n",
             nrow(summary),
             sum(summary$valid),
             sum(!summary$valid)))

  # Calculate compliance percentage
  compliance <- round(100 * sum(summary$valid) / nrow(summary), 1)
  cat(sprintf("Compliance Rate: %.1f%%\n", compliance))

  cat(sprintf("%s\n", paste(rep("=", 70), collapse = "")))

  # Return detailed results
  return(list(
    summary = summary,
    details = results,
    compliance_rate = compliance
  ))
}

#' Generate migration script for non-compliant files
#' @param validation_results Results from validate_drv_directory
#' @param output_file Path to save migration script
generate_migration_script <- function(validation_results, output_file = "migrate_derivations.R") {
  if (is.null(validation_results)) {
    cat("No validation results to process\n")
    return()
  }

  # Filter for non-compliant files
  failed_files <- validation_results$summary[!validation_results$summary$valid, "file"]

  if (length(failed_files) == 0) {
    cat("\n✅ All files are compliant! No migration needed.\n")
    return()
  }

  cat(sprintf("\nGenerating migration script for %d non-compliant files...\n",
             length(failed_files)))

  # Create migration script content
  script_lines <- c(
    "#!/usr/bin/env Rscript",
    "#",
    "# Migration script for DM_R044 compliance",
    sprintf("# Generated: %s", Sys.Date()),
    "#",
    "",
    "# Files to migrate:",
    paste0("# - ", failed_files),
    "",
    "migrate_to_dm_r044 <- function(filepath) {",
    "  # Read existing file",
    "  lines <- readLines(filepath)",
    "  ",
    "  # TODO: Add migration logic based on specific issues",
    "  # - Add missing header fields",
    "  # - Restructure to five-part format",
    "  # - Add documentation blocks",
    "  ",
    "  # Backup original",
    "  backup_file <- paste0(filepath, '.backup_', format(Sys.Date(), '%Y%m%d'))",
    "  file.copy(filepath, backup_file)",
    "  ",
    "  # Write updated file",
    "  # writeLines(updated_lines, filepath)",
    "  ",
    "  message(sprintf('Migrated: %s', basename(filepath)))",
    "}",
    "",
    "# Process each file",
    "files_to_migrate <- c(",
    paste0("  '", failed_files, "'", ifelse(seq_along(failed_files) < length(failed_files), ",", "")),
    ")",
    "",
    "for (file in files_to_migrate) {",
    "  tryCatch({",
    "    migrate_to_dm_r044(file)",
    "  }, error = function(e) {",
    "    message(sprintf('Failed to migrate %s: %s', file, e$message))",
    "  })",
    "}"
  )

  # Write migration script
  writeLines(script_lines, output_file)
  cat(sprintf("Migration script saved to: %s\n", output_file))
}

# ==============================================================================
# Main Execution (if run as script)
# ==============================================================================

if (!interactive()) {
  # Parse command line arguments
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    cat("Usage: Rscript validate_derivation_format.R <df_directory> [pattern]\n")
    cat("Example: Rscript validate_derivation_format.R ./DRV\n")
    cat("Example: Rscript validate_derivation_format.R ./DRV 'cbz.*\\.R$'\n")
    quit(status = 1)
  }

  drv_dir <- args[1]
  pattern <- ifelse(length(args) > 1, args[2], ".*_D[0-9]{2}_[0-9]{2}\\.R$")

  # Validate directory exists
  if (!dir.exists(drv_dir)) {
    cat(sprintf("Error: Directory does not exist: %s\n", drv_dir))
    quit(status = 1)
  }

  # Run validation
  results <- validate_drv_directory(drv_dir, pattern)

  # Generate migration script for failed files
  if (!is.null(results) && results$compliance_rate < 100) {
    generate_migration_script(results)
  }

  # Exit with appropriate status
  if (!is.null(results) && results$compliance_rate == 100) {
    quit(status = 0)
  } else {
    quit(status = 1)
  }
}

# If sourced, provide functions for interactive use
cat("DM_R044 Derivation Format Validator loaded.\n")
cat("Functions available:\n")
cat("  - validate_derivation_file(filepath)\n")
cat("  - validate_drv_directory(drv_dir, pattern)\n")
cat("  - generate_migration_script(validation_results)\n")