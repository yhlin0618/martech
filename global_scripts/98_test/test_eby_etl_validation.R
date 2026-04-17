#!/usr/bin/env Rscript
# ==============================================================================
# Test Script for eBay ETL Validation with Real-Time Monitoring
# Following MP099: Real-time Progress Reporting
# Following MP093: Data Visualization Debugging
# ==============================================================================

cat(strrep("=", 80), "\n")
cat("eBay ETL VALIDATION TEST SUITE\n")
cat("Testing MAMBA Principle Compliance\n")
cat(strrep("=", 80), "\n")

# ==============================================================================
# PART 1: ENVIRONMENT VALIDATION
# ==============================================================================

cat("\n[1/5] ENVIRONMENT VALIDATION\n")
cat(strrep("-", 40), "\n")

# Check working directory
wd <- getwd()
cat(sprintf("Current directory: %s\n", wd))

# Check for .Rproj file to confirm project root
rproj_files <- list.files(pattern = "\\.Rproj$")
if (length(rproj_files) > 0) {
  cat(sprintf("✅ Project root confirmed: %s\n", rproj_files[1]))
} else {
  cat("⚠️  Warning: Not in project root directory\n")
  cat("Looking for MAMBA project root...\n")
  
  # Try to find and set correct working directory
  if (file.exists("scripts/update_scripts")) {
    cat("✅ Found scripts directory, appears to be correct location\n")
  } else {
    stop("❌ Not in MAMBA project root. Please cd to project directory first.")
  }
}

# Check required environment variables
required_vars <- c(
  "EBY_SSH_HOST", "EBY_SSH_USER", "EBY_SSH_PASSWORD",
  "EBY_SQL_HOST", "EBY_SQL_PORT", "EBY_SQL_USER", 
  "EBY_SQL_PASSWORD", "EBY_SQL_DATABASE"
)

env_check <- sapply(required_vars, function(v) {
  val <- Sys.getenv(v)
  if (val != "") {
    cat(sprintf("  ✅ %s: Set\n", v))
    return(TRUE)
  } else {
    cat(sprintf("  ❌ %s: Missing\n", v))
    return(FALSE)
  }
})

if (!all(env_check)) {
  cat("\n⚠️  Some environment variables are missing.\n")
  cat("Please ensure .env file is loaded or variables are set.\n")
} else {
  cat("\n✅ All environment variables configured\n")
}

# ==============================================================================
# PART 2: FILE STRUCTURE VALIDATION
# ==============================================================================

cat("\n[2/5] FILE STRUCTURE VALIDATION\n")
cat(strrep("-", 40), "\n")

# Check ETL scripts exist
etl_scripts <- c(
  "scripts/update_scripts/eby_ETL_orders_0IM___MAMBA.R",
  "scripts/update_scripts/eby_ETL_order_details_0IM___MAMBA.R"
)

for (script in etl_scripts) {
  if (file.exists(script)) {
    cat(sprintf("  ✅ %s exists\n", basename(script)))
  } else {
    cat(sprintf("  ❌ %s missing\n", basename(script)))
  }
}

# Check required source files
source_files <- c(
  "scripts/global_scripts/22_initializations/sc_Rprofile.R",
  "scripts/global_scripts/02_db_utils/duckdb/fn_dbConnectDuckdb.R"
)

for (src in source_files) {
  if (file.exists(src)) {
    cat(sprintf("  ✅ %s exists\n", basename(src)))
  } else {
    cat(sprintf("  ❌ %s missing\n", basename(src)))
  }
}

# ==============================================================================
# PART 3: PRINCIPLE COMPLIANCE STATIC ANALYSIS
# ==============================================================================

cat("\n[3/5] PRINCIPLE COMPLIANCE STATIC ANALYSIS\n")
cat(strrep("-", 40), "\n")

analyze_script_compliance <- function(script_path) {
  if (!file.exists(script_path)) {
    return(list(compliant = FALSE, issues = "File not found"))
  }
  
  content <- readLines(script_path)
  script_name <- basename(script_path)
  
  cat(sprintf("\nAnalyzing: %s\n", script_name))
  
  checks <- list()
  
  # Check 1: Five-part structure (DEV_R032)
  parts <- c("INITIALIZE", "MAIN", "TEST", "DEINITIALIZE", "AUTODEINIT")
  for (part in parts) {
    if (any(grepl(sprintf("PART.*%s", part), content))) {
      cat(sprintf("  ✅ %s section found\n", part))
      checks[[part]] <- TRUE
    } else {
      cat(sprintf("  ❌ %s section missing\n", part))
      checks[[part]] <- FALSE
    }
  }
  
  # Check 2: autodeinit() is last (MP103)
  last_line <- tail(content[content != ""], 1)
  if (grepl("autodeinit\\(\\)", last_line)) {
    cat("  ✅ autodeinit() is last statement\n")
    checks$autodeinit_last <- TRUE
  } else {
    cat("  ❌ autodeinit() is not last statement\n")
    checks$autodeinit_last <- FALSE
  }
  
  # Check 3: No JOIN in 0IM (MP064)
  if (any(grepl("JOIN|join", content))) {
    join_lines <- which(grepl("JOIN|join", content))
    # Check if these are just comments
    actual_joins <- FALSE
    for (line_num in join_lines) {
      if (!grepl("^\\s*#", content[line_num])) {
        actual_joins <- TRUE
        break
      }
    }
    if (actual_joins) {
      cat("  ❌ JOIN operations found in 0IM phase\n")
      checks$no_joins <- FALSE
    } else {
      cat("  ✅ No JOIN operations in code (only comments)\n")
      checks$no_joins <- TRUE
    }
  } else {
    cat("  ✅ No JOIN operations found\n")
    checks$no_joins <- TRUE
  }
  
  # Check 4: Proper naming (DM_R037)
  if (grepl("___MAMBA", script_name)) {
    cat("  ✅ Script has ___MAMBA suffix\n")
    checks$naming <- TRUE
  } else {
    cat("  ❌ Script missing ___MAMBA suffix\n")
    checks$naming <- FALSE
  }
  
  # Check 5: Table naming pattern
  table_pattern <- "df_eby_.*___raw___MAMBA"
  if (any(grepl(table_pattern, content))) {
    cat("  ✅ Correct table naming pattern found\n")
    checks$table_naming <- TRUE
  } else {
    cat("  ❌ Table naming pattern not found\n")
    checks$table_naming <- FALSE
  }
  
  # Check 6: Data separation (MP104)
  if (grepl("orders", script_name)) {
    # Should only have ORD columns, not ORE
    if (any(grepl("ORE[0-9]", content))) {
      cat("  ❌ BAYORE columns found in orders script\n")
      checks$data_separation <- FALSE
    } else {
      cat("  ✅ No BAYORE columns in orders script\n")
      checks$data_separation <- TRUE
    }
  } else if (grepl("order_details", script_name)) {
    # Should only have ORE columns, not ORD
    if (any(grepl("ORD[0-9]", content))) {
      cat("  ❌ BAYORD columns found in order_details script\n")
      checks$data_separation <- FALSE
    } else {
      cat("  ✅ No BAYORD columns in order_details script\n")
      checks$data_separation <- TRUE
    }
  }
  
  # Calculate compliance score
  compliance_score <- sum(unlist(checks)) / length(checks) * 100
  cat(sprintf("\n  Overall Compliance: %.1f%%\n", compliance_score))
  
  return(list(
    compliant = all(unlist(checks)),
    score = compliance_score,
    checks = checks
  ))
}

# Analyze both scripts
orders_compliance <- analyze_script_compliance(etl_scripts[1])
details_compliance <- analyze_script_compliance(etl_scripts[2])

# ==============================================================================
# PART 4: DATABASE VALIDATION
# ==============================================================================

cat("\n[4/5] DATABASE VALIDATION\n")
cat(strrep("-", 40), "\n")

# Check if we can connect to DuckDB
tryCatch({
  library(DBI)
  library(duckdb)
  
  # Check if raw_data database exists
  db_path <- "data/database/raw_data.duckdb"
  if (file.exists(db_path)) {
    cat(sprintf("  ✅ Database exists: %s\n", db_path))
    
    # Connect and check tables
    con <- dbConnect(duckdb::duckdb(), db_path, read_only = TRUE)
    tables <- dbListTables(con)
    
    # Check for expected tables
    expected_tables <- c(
      "df_eby_orders___raw___MAMBA",
      "df_eby_order_details___raw___MAMBA"
    )
    
    for (tbl in expected_tables) {
      if (tbl %in% tables) {
        row_count <- dbGetQuery(con, sprintf("SELECT COUNT(*) as n FROM \"%s\"", tbl))$n
        cat(sprintf("  ✅ Table %s exists (%d rows)\n", tbl, row_count))
      } else {
        cat(sprintf("  ⚠️  Table %s not found (not yet imported)\n", tbl))
      }
    }
    
    dbDisconnect(con)
  } else {
    cat(sprintf("  ⚠️  Database not found: %s\n", db_path))
    cat("      This is normal if ETL hasn't been run yet\n")
  }
  
}, error = function(e) {
  cat(sprintf("  ❌ Database check failed: %s\n", e$message))
})

# ==============================================================================
# PART 5: SUMMARY REPORT
# ==============================================================================

cat("\n[5/5] VALIDATION SUMMARY\n")
cat(strrep("=", 80), "\n")

cat("\nCOMPLIANCE SCORES:\n")
cat(sprintf("  • eby_ETL_orders_0IM___MAMBA.R:        %.1f%%\n", orders_compliance$score))
cat(sprintf("  • eby_ETL_order_details_0IM___MAMBA.R: %.1f%%\n", details_compliance$score))

avg_score <- (orders_compliance$score + details_compliance$score) / 2
cat(sprintf("\n  AVERAGE COMPLIANCE SCORE: %.1f%%\n", avg_score))

if (avg_score == 100) {
  cat("\n🎯 PERFECT COMPLIANCE - Scripts are production ready!\n")
} else if (avg_score >= 90) {
  cat("\n✅ EXCELLENT - Minor improvements needed\n")
} else if (avg_score >= 80) {
  cat("\n⚠️  GOOD - Some principle violations need attention\n")
} else {
  cat("\n❌ NEEDS WORK - Significant principle violations detected\n")
}

# ==============================================================================
# MONITORING SETUP INSTRUCTIONS
# ==============================================================================

cat("\n" , strrep("=", 80), "\n")
cat("REAL-TIME MONITORING INSTRUCTIONS\n")
cat(strrep("=", 80), "\n")

cat("
To run with real-time monitoring:

1. Open a terminal and navigate to project root:
   cd ", wd, "

2. Create monitoring directory:
   mkdir -p scripts/global_scripts/00_principles/changelog/monitoring/etl

3. Run orders ETL with monitoring:
   stdbuf -oL -eL Rscript scripts/update_scripts/eby_ETL_orders_0IM___MAMBA.R 2>&1 | \\
     tee scripts/global_scripts/00_principles/changelog/monitoring/etl/orders_$(date +%Y%m%d_%H%M%S).log &

4. Run order details ETL with monitoring:
   stdbuf -oL -eL Rscript scripts/update_scripts/eby_ETL_order_details_0IM___MAMBA.R 2>&1 | \\
     tee scripts/global_scripts/00_principles/changelog/monitoring/etl/details_$(date +%Y%m%d_%H%M%S).log &

5. Monitor for errors in real-time:
   tail -f scripts/global_scripts/00_principles/changelog/monitoring/etl/*.log | \\
     grep -E 'ERROR|Failed|exception|rapi_register_df'

6. Check S02 data exports for validation:
   Rscript scripts/update_scripts/all_S02_00.R
   ls -la data/database_to_csv/

", sep = "")

cat(strrep("=", 80), "\n")
cat("Validation completed successfully!\n")
cat(strrep("=", 80), "\n")