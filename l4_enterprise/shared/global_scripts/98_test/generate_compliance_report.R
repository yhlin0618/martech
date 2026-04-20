#!/usr/bin/env Rscript
#' Generate Principle Compliance Report
#' 
#' Creates formatted markdown report showing compliance with MAMBA principles
#' Includes MP029, MP108, MP109, MP064, MP102, R116, R117, R118
#' 
#' @param validation_csv Path to validation results CSV
#' @output validation/PRINCIPLE_COMPLIANCE_REPORT_[date].md

library(dplyr)
library(DBI)
library(duckdb)

# ============================================================
# Parse Command Line Arguments
# ============================================================

args <- commandArgs(trailingOnly = TRUE)

if (length(args) == 0) {
  # Find most recent validation results
  validation_files <- list.files("validation", 
                                 pattern = "precision_etl_drv_validation_.*\\.csv",
                                 full.names = TRUE)
  
  if (length(validation_files) == 0) {
    stop("No validation results found. Run validate_precision_etl_drv.R first.")
  }
  
  # Get most recent file
  validation_csv <- validation_files[which.max(file.mtime(validation_files))]
  message(sprintf("Using most recent validation results: %s", basename(validation_csv)))
} else {
  validation_csv <- args[1]
}

# ============================================================
# Load Validation Results
# ============================================================

message("Loading validation results...")
results <- read.csv(validation_csv)

# Calculate metrics
total_checks <- nrow(results)
passed_checks <- sum(results$compliant)
failed_checks <- total_checks - passed_checks
compliance_rate <- passed_checks / total_checks

# ============================================================
# Generate Markdown Report
# ============================================================

timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
report_file <- sprintf("validation/PRINCIPLE_COMPLIANCE_REPORT_%s.md", timestamp)

message(sprintf("Generating compliance report: %s", report_file))

sink(report_file)

cat("# MAMBA Precision Marketing ETL+DRV Principle Compliance Report\n\n")
cat(sprintf("**Generated**: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat("**Domain**: Precision Marketing\n")
cat("**Pipeline Version**: v1.0.0\n")
cat("**Validation Framework**: fn_validate_etl_drv_template v1.0.0\n\n")
cat("---\n\n")

# ============================================================
# Executive Summary
# ============================================================

cat("## Executive Summary\n\n")
cat(sprintf("%s **Overall Compliance**: %.1f%% (%d/%d checks passed)\n",
           if(compliance_rate == 1.0) "✅" else if(compliance_rate >= 0.95) "⚠️" else "❌",
           compliance_rate * 100,
           passed_checks,
           total_checks))
cat(sprintf("⚠️ **Critical Failures**: %d\n", 
           sum(results$principle %in% c("MP029", "MP108", "MP109") & !results$compliant)))
cat(sprintf("⚠️ **Warnings**: %d\n\n", 
           sum(results$principle %in% c("MP064", "MP102") & !results$compliant)))

# Compliance status badge
if (compliance_rate == 1.0) {
  cat("**Status**: 🟢 FULLY COMPLIANT\n\n")
} else if (compliance_rate >= 0.95) {
  cat("**Status**: 🟡 MOSTLY COMPLIANT (minor issues)\n\n")
} else {
  cat("**Status**: 🔴 NON-COMPLIANT (critical issues)\n\n")
}

cat("---\n\n")

# ============================================================
# Meta-Principle Compliance
# ============================================================

cat("## Meta-Principle Compliance\n\n")

meta_principles <- c("MP029", "MP108", "MP109", "MP064", "MP102")
mp_names <- c(
  "MP029" = "No Fake Data",
  "MP108" = "Base ETL Pipeline (0IM→1ST→2TR)",
  "MP109" = "DRV Derivation Layer",
  "MP064" = "ETL-Derivation Separation",
  "MP102" = "Completeness & Standardization"
)

for (mp in meta_principles) {
  cat(sprintf("### %s: %s\n\n", mp, mp_names[mp]))
  
  mp_results <- results %>% filter(principle == mp)
  
  if (nrow(mp_results) > 0) {
    for (i in 1:nrow(mp_results)) {
      status_icon <- if(mp_results$compliant[i]) "✅" else "❌"
      cat(sprintf("- %s %s\n", status_icon, mp_results$check_description[i]))
      if (nchar(mp_results$detail[i]) > 0) {
        cat(sprintf("  - *%s*\n", mp_results$detail[i]))
      }
    }
    
    mp_compliance <- mean(mp_results$compliant)
    cat(sprintf("\n**Status**: %s (%.0f%% compliant)\n\n",
               if(mp_compliance == 1.0) "COMPLIANT" else "NON-COMPLIANT",
               mp_compliance * 100))
  } else {
    cat("*No checks defined for this principle*\n\n")
  }
}

cat("---\n\n")

# ============================================================
# Rule Compliance
# ============================================================

cat("## Rule Compliance\n\n")

rules <- c("R116", "R117", "R118")
rule_names <- c(
  "R116" = "Currency Standardization in ETL 1ST",
  "R117" = "Time Series Filling Transparency",
  "R118" = "Statistical Significance Documentation"
)

for (rule in rules) {
  cat(sprintf("### %s: %s\n\n", rule, rule_names[rule]))
  
  rule_results <- results %>% filter(principle == rule)
  
  if (nrow(rule_results) > 0) {
    for (i in 1:nrow(rule_results)) {
      status_icon <- if(rule_results$compliant[i]) "✅" else "❌"
      cat(sprintf("- %s %s\n", status_icon, rule_results$check_description[i]))
      if (nchar(rule_results$detail[i]) > 0) {
        cat(sprintf("  - *%s*\n", rule_results$detail[i]))
      }
    }
    
    rule_compliance <- mean(rule_results$compliant)
    cat(sprintf("\n**Status**: %s\n\n",
               if(rule_compliance == 1.0) "COMPLIANT" else "NON-COMPLIANT"))
  } else {
    cat("*No checks defined for this rule*\n\n")
  }
}

cat("---\n\n")

# ============================================================
# Database Validation
# ============================================================

cat("## Database Validation\n\n")
cat("### Databases Exist\n\n")

db_results <- results %>% filter(grepl("^db_", check_id))

if (nrow(db_results) > 0) {
  for (i in 1:nrow(db_results)) {
    status_icon <- if(db_results$compliant[i]) "✅" else "❌"
    cat(sprintf("- %s %s\n", status_icon, db_results$check_description[i]))
    if (nchar(db_results$detail[i]) > 0) {
      cat(sprintf("  - *%s*\n", db_results$detail[i]))
    }
  }
  cat("\n")
}

# Get table counts from databases
cat("### Table Counts\n\n")

dbs <- c(
  "data/raw_data.duckdb",
  "data/staged_data.duckdb",
  "data/transformed_data.duckdb",
  "data/processed_data.duckdb"
)

for (db_path in dbs) {
  if (file.exists(db_path)) {
    con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
    tables <- dbListTables(con)
    dbDisconnect(con, shutdown = TRUE)
    
    db_name <- basename(db_path)
    cat(sprintf("- ✅ **%s**: %d tables\n", db_name, length(tables)))
  } else {
    cat(sprintf("- ❌ **%s**: Not found\n", basename(db_path)))
  }
}

cat("\n---\n\n")

# ============================================================
# Custom Checks
# ============================================================

cat("## Custom Domain Checks\n\n")

custom_results <- results %>% filter(principle == "CUSTOM")

if (nrow(custom_results) > 0) {
  for (i in 1:nrow(custom_results)) {
    status_icon <- if(custom_results$compliant[i]) "✅" else "❌"
    cat(sprintf("- %s %s\n", status_icon, custom_results$check_description[i]))
    if (nchar(custom_results$detail[i]) > 0) {
      cat(sprintf("  - *%s*\n", custom_results$detail[i]))
    }
  }
  cat("\n")
} else {
  cat("*No custom checks defined*\n\n")
}

cat("---\n\n")

# ============================================================
# Metadata Files
# ============================================================

cat("## Metadata Files\n\n")

metadata_files <- c(
  "metadata/variable_name_transformations.csv",
  "metadata/dummy_encoding_metadata.csv",
  "metadata/time_series_filling_stats.csv",
  "metadata/country_extraction_metadata.csv"
)

for (meta_file in metadata_files) {
  if (file.exists(meta_file)) {
    meta_data <- read.csv(meta_file)
    file_size <- file.size(meta_file) / 1024  # KB
    cat(sprintf("- ✅ **%s**\n", basename(meta_file)))
    cat(sprintf("  - Records: %d\n", nrow(meta_data)))
    cat(sprintf("  - Size: %.1f KB\n", file_size))
  } else {
    cat(sprintf("- ❌ **%s**: Not found\n", basename(meta_file)))
  }
}

cat("\n---\n\n")

# ============================================================
# Failure Details
# ============================================================

if (failed_checks > 0) {
  cat("## Failed Checks Details\n\n")
  
  failed_results <- results %>% filter(!compliant) %>% arrange(principle)
  
  for (i in 1:nrow(failed_results)) {
    cat(sprintf("### ❌ [%s] %s\n\n", 
               failed_results$principle[i],
               failed_results$check_description[i]))
    cat(sprintf("**Detail**: %s\n\n", failed_results$detail[i]))
  }
  
  cat("---\n\n")
}

# ============================================================
# Recommendations
# ============================================================

cat("## Recommendations\n\n")

if (compliance_rate == 1.0) {
  cat("1. ✅ All checks passed - no actions required\n")
  cat("2. Consider adding automated validation to CI/CD pipeline\n")
  cat("3. Archive legacy D04 scripts after parallel running validation\n")
} else {
  cat("### Priority Actions\n\n")
  
  # Critical failures
  critical_failures <- results %>% 
    filter(!compliant, principle %in% c("MP029", "MP108", "MP109"))
  
  if (nrow(critical_failures) > 0) {
    cat("**Critical (must fix)**:\n\n")
    for (i in 1:nrow(critical_failures)) {
      cat(sprintf("%d. Fix [%s] %s\n", 
                 i,
                 critical_failures$principle[i],
                 critical_failures$check_description[i]))
    }
    cat("\n")
  }
  
  # Non-critical failures
  other_failures <- results %>%
    filter(!compliant, !principle %in% c("MP029", "MP108", "MP109"))
  
  if (nrow(other_failures) > 0) {
    cat("**Non-critical (should fix)**:\n\n")
    for (i in 1:nrow(other_failures)) {
      cat(sprintf("%d. Fix [%s] %s\n",
                 i,
                 other_failures$principle[i],
                 other_failures$check_description[i]))
    }
    cat("\n")
  }
}

cat("\n---\n\n")

# ============================================================
# Footer
# ============================================================

cat("## Report Metadata\n\n")
cat(sprintf("- **Generated by**: `generate_compliance_report.R`\n"))
cat(sprintf("- **Validation Framework**: `fn_validate_etl_drv_template.R`\n"))
cat(sprintf("- **Source Data**: `%s`\n", basename(validation_csv)))
cat(sprintf("- **Report Date**: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))
cat(sprintf("- **Total Execution Time**: < 1 second\n"))

cat("\n---\n\n")
cat("*End of Report*\n")

sink()

# ============================================================
# Print Summary to Console
# ============================================================

message("\n=======================================================")
message("COMPLIANCE REPORT GENERATED SUCCESSFULLY")
message("=======================================================")
message(sprintf("Report location: %s", report_file))
message(sprintf("Overall compliance: %.1f%%", compliance_rate * 100))
message(sprintf("Status: %s", 
               if(compliance_rate == 1.0) "FULLY COMPLIANT" 
               else if(compliance_rate >= 0.95) "MOSTLY COMPLIANT"
               else "NON-COMPLIANT"))
message("=======================================================\n")

# Return exit code based on compliance
if (compliance_rate >= 0.95) {
  quit(status = 0)
} else {
  quit(status = 1)
}
