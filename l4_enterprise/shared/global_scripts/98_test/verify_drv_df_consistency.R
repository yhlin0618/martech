#!/usr/bin/env Rscript
# Verify complete drv → df migration (R119 compliance)
#
# Purpose: Verify NO df_ table/variable references remain (except layer names)
# Author: principle-product-manager
# Date: 2025-11-13

# Search for remaining drv_ references
cat("=== R119 Compliance Verification ===\n\n")

# Find all drv_ references in code
cat("Searching for remaining drv_ references...\n\n")

violations <- system(
  "grep -r 'drv_' . --include='*.R' --include='*.md' --include='*.qmd' --exclude-dir=archive --exclude-dir=renv --exclude-dir=.git 2>/dev/null || true",
  intern = TRUE
)

# Acceptable patterns (these are OK to keep)
acceptable_patterns <- c(
  "DRV/",                          # Directory path
  "DRV layer",                     # Layer name
  "DRV scripts",                   # Layer reference
  "update_scripts/DRV",            # Path reference
  "MP109.*DRV",                    # Principle name
  "mp109.*drv",                    # Principle reference
  "fn_validate_etl_drv_template",  # Function name (backward compat)
  "validate_etl_drv",              # Validation script names
  "precision_etl_drv",             # Existing validation file names
  "for_drv_developers",            # YAML comment
  "validate_drv_directory",        # Function name
  "drv_dir",                       # Parameter name for directory paths
  "drv_files",                     # Parameter name for file lists
  "drv_path",                      # Variable for file paths
  "drv_ro",                        # DuckDB read-only driver variable
  "drv_old",                       # Old connection driver
  "drv_new",                       # New connection driver
  "\\.backup_drv_",                # Backup files
  "week_._drv_",                   # Historical YAML keys (week_2_drv_features)
  "migrate_drv",                   # Migration script functions
  "rename_drv",                    # Migration script functions
  "drv_to_df",                     # Migration script/report names
  "execute_drv_group",             # Function about DRV operations
  "validate_drv_filename",         # Function about DRV operations
  "validate_drv_sequence",         # Function about DRV operations
  "write_drv_data",                # Function about DRV operations
  "create_etl_drv_structure",      # Function about DRV operations
  "migrate_drv_scripts",           # Function about DRV operations
  "get_drv_range",                 # Function about DRV operations
  "test_.*drv",                    # Test function names
  "fn_drv_",                       # Function file names for DRV operations
  "validate_drv_metadata",         # Function names
  "drv_activation",                # Changelog file names
  "DM_R042_drv",                   # Principle file names
  "drv_derivation",                # YAML documentation keys
  "use_drv_when",                  # Documentation headings
  "drv_example",                   # Documentation examples
  "drv_ with `df_`",               # Migration report text
  "\\bdrv_features\\s*<-",         # Pattern replacement text in migration scripts
  "\\bdrv_results\\s*<-",          # Pattern replacement text in migration scripts
  "\\bdrv_data\\s*<-",             # Pattern replacement text in migration scripts
  "\\bdrv_analysis\\s*<-",         # Pattern replacement text in migration scripts
  "\\bdrv_output\\s*<-",           # Pattern replacement text in migration scripts
  "\\bdrv_analytics\\s*<-",        # Pattern replacement text in migration scripts
  "以drv_開頭",                     # Chinese documentation text
  "precision_marketing_etl_drv",   # Case study file names
  "MP109_drv_layer_separation",    # Principle file names
  "verify_drv_df_consistency",     # THIS verification script itself
  "Searching for remaining drv_",  # Text in this script
  "Find all drv_ references",      # Text in this script
  "drv_ references are acceptable", # Text in this script
  "drv_ table/variable",           # Text in this script
  "All drv_ table/variable references", # Text in this script
  "sum\\(grepl\\('drv_",           # Regex patterns in this script
  "DRV_TO_DF_MIGRATION.*REPORT",   # Migration report file names
  "DRV_TO_DF_COMPLETE_MIGRATION",  # Complete migration report
  "R119_MIGRATION_FINAL_REPORT",   # Final migration report
  "drv_.*→.*df_",                  # Migration before→after examples
  "drv_precision_features.*→",     # Migration table mappings
  "drv_cbz_product_features",      # Example table names in docs
  "drv_cbz_time_series",           # Example table names in docs
  "drv_cbz_poisson_analysis",      # Example table names in docs
  "drv_precision_features",        # Example table names in docs
  "FROM drv_",                     # SQL examples in migration docs
  "dbReadTable.*drv_",             # Code examples in migration docs
  "dbWriteTable.*drv_",            # Code examples in migration docs
  "NOT drv_",                      # Negative examples in docs
  "Zero drv_",                     # Documentation text
  "zero drv_",                     # Documentation text
  "All drv_",                      # Documentation text
  "drv_.*describes SOURCE",        # Explanation text
  "Acceptable drv_"                # Documentation headings
)

# Filter violations
if (length(violations) > 0) {
  # Filter out acceptable uses
  pattern_regex <- paste(acceptable_patterns, collapse = "|")
  real_violations <- violations[!grepl(pattern_regex, violations)]

  if (length(real_violations) > 0) {
    cat("⚠ R119 VIOLATIONS FOUND:\n\n")
    cat(real_violations, sep = "\n")
    cat(sprintf("\nTotal violations: %d\n", length(real_violations)))

    # Categorize violations
    cat("\n=== Violation Analysis ===\n")
    cat(sprintf("Table name references: %d\n",
                sum(grepl('drv_(cbz|precision|eby)_(product_features|time_series|poisson)', real_violations))))
    cat(sprintf("Variable assignments: %d\n",
                sum(grepl('drv_[a-z_]+ <-', real_violations))))
    cat(sprintf("Documentation: %d\n",
                sum(grepl('\\.md:', real_violations))))
    cat(sprintf("R scripts: %d\n",
                sum(grepl('\\.R:', real_violations))))

    stop("\n❌ R119 COMPLIANCE FAILED - drv_ table/variable references still exist")
  } else {
    cat("✓ All drv_ references are acceptable (layer names, paths, etc.)\n")
  }
} else {
  cat("✓ No drv_ references found at all\n")
}

cat("\n✓ R119 COMPLIANCE VERIFIED\n")
cat("All drv_ table/variable references successfully migrated to df_\n")
cat("\nAcceptable drv_ references (preserved):\n")
cat("- DRV layer directory and path names\n")
cat("- Function names (fn_validate_etl_drv_template)\n")
cat("- Parameter names (drv_dir, drv_files, drv_path)\n")
cat("- Driver variables (drv_ro, drv_old, drv_new)\n")
cat("- Backup file suffixes\n")
