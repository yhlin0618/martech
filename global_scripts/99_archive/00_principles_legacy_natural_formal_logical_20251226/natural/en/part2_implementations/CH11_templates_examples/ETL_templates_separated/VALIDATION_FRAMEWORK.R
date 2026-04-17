# VALIDATION_FRAMEWORK.R - Comprehensive ETL Data Flow Separation Validation
# ==============================================================================
# Following MP104: ETL Data Flow Separation Principle
# Following DM_R028: ETL Data Type Separation Rule
# Following MP102: ETL Output Standardization Principle
# Following R113: Four-part Update Script Structure
#
# Comprehensive validation framework for the new separated ETL architecture
# Validates compliance, performance, and data integrity across all platforms
# ==============================================================================

# ==============================================================================
# 1. INITIALIZE
# ==============================================================================

# Initialize script execution tracking
script_success <- FALSE
test_passed <- FALSE
main_error <- NULL
script_start_time <- Sys.time()

message("INITIALIZE: ⚡ Starting ETL Data Flow Separation Validation Framework")
message(sprintf("INITIALIZE: 🕐 Start time: %s", format(script_start_time, "%Y-%m-%d %H:%M:%S")))

# Initialize using unified autoinit system
autoinit()

# Load required libraries
message("INITIALIZE: 📦 Loading validation libraries...")
lib_start <- Sys.time()

library(dplyr)     # Data manipulation
library(purrr)     # Functional programming
library(stringr)   # String processing
library(yaml)      # YAML handling
library(DBI)       # Database interface

lib_elapsed <- as.numeric(Sys.time() - lib_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Libraries loaded successfully (%.2fs)", lib_elapsed))

# Source validation utilities
message("INITIALIZE: 📋 Loading validation functions...")
source_start <- Sys.time()

if (!exists("dbConnectDuckdb", mode = "function")) {
  source(here::here("scripts", "global_scripts", "02_db_utils", "duckdb", "fn_dbConnectDuckdb.R"))
}

source_elapsed <- as.numeric(Sys.time() - source_start, units = "secs")
message(sprintf("INITIALIZE: ✅ Functions loaded successfully (%.2fs)", source_elapsed))

# Define validation configuration
validation_config <- list(
  platforms = c("cbz", "eby", "amz"),
  data_types = c("sales", "customers", "orders", "products", "reviews"),
  phases = c("0IM", "1ST", "2TR"),
  schema_registry_path = here::here("scripts", "global_scripts", "00_principles", 
                                   "natural", "en", "part2_implementations", 
                                   "CH17_database_specifications", "etl_schemas"),
  templates_path = here::here("scripts", "global_scripts", "00_principles",
                             "natural", "en", "part2_implementations",
                             "CH11_templates_examples", "ETL_templates_separated")
)

# ==============================================================================
# 2. MAIN
# ==============================================================================

message("MAIN: 🚀 Starting comprehensive ETL architecture validation...")
main_start_time <- Sys.time()

# Validation results storage
validation_results <- list()

# ==============================================================================
# VALIDATION 1: NAMING CONVENTION COMPLIANCE
# ==============================================================================

validate_naming_conventions <- function() {
  message("VALIDATION 1: 🏷️  Checking ETL naming convention compliance...")
  
  results <- list()
  
  # Expected naming pattern: {platform}_ETL_{datatype}_{phase}.R
  expected_pattern <- "^([a-z]{3})_ETL_([a-z_]+)_(0IM|1ST|2TR)\\.R$"
  
  # Check templates directory
  template_files <- list.files(validation_config$templates_path, pattern = ".*ETL.*\\.R$", full.names = FALSE)
  
  for (file in template_files) {
    if (grepl(expected_pattern, file)) {
      matches <- regmatches(file, regexec(expected_pattern, file))[[1]]
      platform <- matches[2]
      datatype <- matches[3]
      phase <- matches[4]
      
      results[[file]] <- list(
        compliant = TRUE,
        platform = platform,
        datatype = datatype, 
        phase = phase,
        issues = c()
      )
    } else {
      results[[file]] <- list(
        compliant = FALSE,
        platform = NA,
        datatype = NA,
        phase = NA,
        issues = c("Does not follow naming convention")
      )
    }
  }
  
  compliant_count <- sum(sapply(results, function(x) x$compliant))
  total_count <- length(results)
  
  message(sprintf("VALIDATION 1: ✅ Naming convention compliance: %d/%d files (%.1f%%)",
                  compliant_count, total_count, (compliant_count/total_count)*100))
  
  return(list(
    validation = "naming_conventions",
    passed = compliant_count == total_count,
    compliant_files = compliant_count,
    total_files = total_count,
    details = results
  ))
}

validation_results$naming <- validate_naming_conventions()

# ==============================================================================
# VALIDATION 2: PIPELINE COMPLETENESS
# ==============================================================================

validate_pipeline_completeness <- function() {
  message("VALIDATION 2: 🔗 Checking pipeline completeness...")
  
  results <- list()
  
  # Group files by platform and datatype
  compliant_files <- validation_results$naming$details
  compliant_files <- compliant_files[sapply(compliant_files, function(x) x$compliant)]
  
  # Create pipeline matrix
  pipeline_matrix <- data.frame(
    platform = sapply(compliant_files, function(x) x$platform),
    datatype = sapply(compliant_files, function(x) x$datatype),
    phase = sapply(compliant_files, function(x) x$phase),
    stringsAsFactors = FALSE
  )
  
  # Check completeness for each platform-datatype combination
  platform_datatype_combos <- pipeline_matrix %>%
    select(platform, datatype) %>%
    distinct()
  
  incomplete_pipelines <- c()
  
  for (i in seq_len(nrow(platform_datatype_combos))) {
    platform <- platform_datatype_combos$platform[i]
    datatype <- platform_datatype_combos$datatype[i]
    
    phases_present <- pipeline_matrix %>%
      filter(platform == !!platform, datatype == !!datatype) %>%
      pull(phase) %>%
      sort()
    
    required_phases <- c("0IM", "1ST", "2TR")
    missing_phases <- setdiff(required_phases, phases_present)
    
    pipeline_key <- sprintf("%s_%s", platform, datatype)
    
    if (length(missing_phases) == 0) {
      results[[pipeline_key]] <- list(
        complete = TRUE,
        platform = platform,
        datatype = datatype,
        phases_present = phases_present,
        missing_phases = c()
      )
    } else {
      results[[pipeline_key]] <- list(
        complete = FALSE,
        platform = platform,
        datatype = datatype,
        phases_present = phases_present,
        missing_phases = missing_phases
      )
      incomplete_pipelines <- c(incomplete_pipelines, pipeline_key)
    }
  }
  
  complete_count <- sum(sapply(results, function(x) x$complete))
  total_count <- length(results)
  
  message(sprintf("VALIDATION 2: ✅ Pipeline completeness: %d/%d pipelines complete (%.1f%%)",
                  complete_count, total_count, (complete_count/total_count)*100))
  
  if (length(incomplete_pipelines) > 0) {
    message(sprintf("VALIDATION 2: ⚠️  Incomplete pipelines: %s", paste(incomplete_pipelines, collapse = ", ")))
  }
  
  return(list(
    validation = "pipeline_completeness",
    passed = complete_count == total_count,
    complete_pipelines = complete_count,
    total_pipelines = total_count,
    incomplete_pipelines = incomplete_pipelines,
    details = results
  ))
}

validation_results$completeness <- validate_pipeline_completeness()

# ==============================================================================
# VALIDATION 3: SCHEMA REGISTRY CONSISTENCY
# ==============================================================================

validate_schema_registry <- function() {
  message("VALIDATION 3: 📋 Checking schema registry consistency...")
  
  results <- list()
  issues <- c()
  
  # Load schema registry
  registry_file <- file.path(validation_config$schema_registry_path, "schema_registry.yaml")
  
  if (!file.exists(registry_file)) {
    return(list(
      validation = "schema_registry",
      passed = FALSE,
      error = "Schema registry file not found",
      details = list()
    ))
  }
  
  registry <- yaml::read_yaml(registry_file)
  
  # Check core schemas file
  core_schemas_file <- file.path(validation_config$schema_registry_path, "core_schemas.yaml")
  
  if (!file.exists(core_schemas_file)) {
    issues <- c(issues, "Core schemas file not found")
  } else {
    core_schemas <- yaml::read_yaml(core_schemas_file)
    
    # Verify schema consistency
    expected_schemas <- c("sales", "customers", "orders", "products", "reviews")
    actual_schemas <- names(core_schemas)
    missing_schemas <- setdiff(expected_schemas, actual_schemas)
    
    if (length(missing_schemas) > 0) {
      issues <- c(issues, sprintf("Missing core schemas: %s", paste(missing_schemas, collapse = ", ")))
    }
    
    # Check each schema has required fields
    for (schema_name in intersect(expected_schemas, actual_schemas)) {
      schema_def <- core_schemas[[schema_name]]
      
      if (is.null(schema_def$required_fields)) {
        issues <- c(issues, sprintf("Schema %s missing required_fields definition", schema_name))
      }
      
      if (is.null(schema_def$table_pattern)) {
        issues <- c(issues, sprintf("Schema %s missing table_pattern", schema_name))
      } else {
        # Check table pattern uses triple underscores
        if (!grepl("___", schema_def$table_pattern)) {
          issues <- c(issues, sprintf("Schema %s table_pattern does not use triple underscores", schema_name))
        }
      }
    }
  }
  
  # Check platform extensions
  for (platform in validation_config$platforms) {
    extension_file <- file.path(validation_config$schema_registry_path, 
                               "platform_extensions", 
                               sprintf("%s_extensions.yaml", platform))
    
    if (!file.exists(extension_file)) {
      issues <- c(issues, sprintf("Missing platform extensions for %s", platform))
    }
  }
  
  # Check registry platform entries
  if (!is.null(registry$platforms)) {
    for (platform in names(registry$platforms)) {
      platform_def <- registry$platforms[[platform]]
      
      if (is.null(platform_def$etl_scripts)) {
        issues <- c(issues, sprintf("Platform %s missing etl_scripts definition", platform))
      }
      
      if (is.null(platform_def$outputs)) {
        issues <- c(issues, sprintf("Platform %s missing outputs definition", platform))
      }
    }
  }
  
  message(sprintf("VALIDATION 3: %s Schema registry validation: %d issues found",
                  if (length(issues) == 0) "✅" else "⚠️", length(issues)))
  
  if (length(issues) > 0) {
    for (issue in issues) {
      message(sprintf("VALIDATION 3: 📋 Issue: %s", issue))
    }
  }
  
  return(list(
    validation = "schema_registry",
    passed = length(issues) == 0,
    issues_found = length(issues),
    issues = issues,
    details = list(registry_exists = file.exists(registry_file))
  ))
}

validation_results$schema <- validate_schema_registry()

# ==============================================================================
# VALIDATION 4: TEMPLATE QUALITY ASSESSMENT
# ==============================================================================

validate_template_quality <- function() {
  message("VALIDATION 4: 📄 Assessing template code quality...")
  
  results <- list()
  
  # Check for key patterns in templates
  template_files <- list.files(validation_config$templates_path, pattern = ".*ETL.*\\.R$", full.names = TRUE)
  
  quality_checks <- list(
    has_four_part_structure = c("# 1. INITIALIZE", "# 2. MAIN", "# 3. TEST", "# 4. RESULT"),
    has_autoinit = c("autoinit()", "autodeinit()"),
    has_error_handling = c("tryCatch", "stop(", "warning("),
    has_logging = c("message(", "sprintf("),
    has_validation = c("validate_", "validation_"),
    has_mp102_compliance = c("MP102", "platform_code", "import_timestamp"),
    has_triple_underscore = c("___raw", "___staged", "___transformed")
  )
  
  for (template_file in template_files) {
    file_name <- basename(template_file)
    
    if (file.exists(template_file)) {
      content <- readLines(template_file, warn = FALSE)
      content_text <- paste(content, collapse = " ")
      
      file_results <- list()
      
      for (check_name in names(quality_checks)) {
        patterns <- quality_checks[[check_name]]
        pattern_found <- any(sapply(patterns, function(p) grepl(p, content_text, fixed = TRUE)))
        file_results[[check_name]] <- pattern_found
      }
      
      # Calculate quality score
      quality_score <- mean(unlist(file_results))
      
      results[[file_name]] <- list(
        quality_score = quality_score,
        checks = file_results,
        file_exists = TRUE,
        line_count = length(content)
      )
    } else {
      results[[file_name]] <- list(
        quality_score = 0,
        checks = list(),
        file_exists = FALSE,
        line_count = 0
      )
    }
  }
  
  # Calculate overall quality metrics
  quality_scores <- sapply(results, function(x) x$quality_score)
  avg_quality <- mean(quality_scores)
  high_quality_count <- sum(quality_scores >= 0.8)
  
  message(sprintf("VALIDATION 4: ✅ Template quality assessment: %.1f%% average score",
                  avg_quality * 100))
  message(sprintf("VALIDATION 4: 📊 High quality templates (≥80%%): %d/%d",
                  high_quality_count, length(quality_scores)))
  
  return(list(
    validation = "template_quality",
    passed = avg_quality >= 0.7,  # 70% threshold
    average_quality_score = avg_quality,
    high_quality_count = high_quality_count,
    total_templates = length(quality_scores),
    details = results
  ))
}

validation_results$quality <- validate_template_quality()

# ==============================================================================
# VALIDATION 5: PRINCIPLE CONSISTENCY CHECK
# ==============================================================================

validate_principle_consistency <- function() {
  message("VALIDATION 5: 📖 Checking principle documentation consistency...")
  
  results <- list()
  issues <- c()
  
  # Key principle files to check
  principle_files <- c(
    "natural/en/part1_principles/CH00_fundamental_principles/04_data_management/MP064_etl_derivation_separation.qmd",
    "natural/en/part1_principles/CH00_fundamental_principles/04_data_management/MP102_etl_output_standardization.qmd", 
    "natural/en/part1_principles/CH00_fundamental_principles/04_data_management/MP104_etl_data_flow_separation.qmd",
    "natural/en/part1_principles/CH02_data_management/rules/DM_R028_etl_data_type_separation.qmd",
    "natural/en/part1_principles/CH02_data_management/rules/DM_R027_etl_schema_validation.qmd"
  )
  
  principles_base_path <- here::here("scripts", "global_scripts", "00_principles")
  
  for (principle_file in principle_files) {
    full_path <- file.path(principles_base_path, principle_file)
    file_key <- basename(principle_file)
    
    if (!file.exists(full_path)) {
      issues <- c(issues, sprintf("Missing principle file: %s", file_key))
      results[[file_key]] <- list(exists = FALSE, consistent = FALSE)
    } else {
      content <- readLines(full_path, warn = FALSE)
      content_text <- paste(content, collapse = " ")
      
      # Check for key consistency markers
      consistency_checks <- list(
        has_triple_underscore = grepl("___", content_text),
        mentions_mp104 = grepl("MP104", content_text),
        mentions_dm_r028 = grepl("DM_R028", content_text),
        has_platform_codes = grepl("cbz|eby|amz", content_text),
        has_data_types = grepl("sales|customers|orders|products", content_text)
      )
      
      consistency_score <- mean(unlist(consistency_checks))
      
      results[[file_key]] <- list(
        exists = TRUE,
        consistent = consistency_score >= 0.6,
        consistency_score = consistency_score,
        checks = consistency_checks
      )
      
      if (consistency_score < 0.6) {
        issues <- c(issues, sprintf("Low consistency score for %s: %.1f%%", file_key, consistency_score * 100))
      }
    }
  }
  
  consistent_count <- sum(sapply(results, function(x) x$consistent))
  total_count <- length(results)
  
  message(sprintf("VALIDATION 5: %s Principle consistency: %d/%d files consistent (%.1f%%)",
                  if (consistent_count == total_count) "✅" else "⚠️",
                  consistent_count, total_count, (consistent_count/total_count)*100))
  
  return(list(
    validation = "principle_consistency",
    passed = length(issues) == 0,
    consistent_files = consistent_count,
    total_files = total_count,
    issues = issues,
    details = results
  ))
}

validation_results$principles <- validate_principle_consistency()

# ==============================================================================
# VALIDATION SUMMARY AND RECOMMENDATIONS
# ==============================================================================

generate_validation_summary <- function() {
  message("SUMMARY: 📊 Generating comprehensive validation summary...")
  
  # Calculate overall scores
  validations <- names(validation_results)
  passed_count <- sum(sapply(validation_results, function(x) x$passed))
  total_count <- length(validation_results)
  overall_score <- (passed_count / total_count) * 100
  
  # Generate summary
  summary <- list(
    overall_score = overall_score,
    validations_passed = passed_count,
    total_validations = total_count,
    timestamp = Sys.time(),
    details = validation_results
  )
  
  # Print summary
  message("SUMMARY: " %+% rep("=", 60))
  message(sprintf("SUMMARY: 🎯 ETL Data Flow Separation Architecture Validation Results"))
  message("SUMMARY: " %+% rep("=", 60))
  message(sprintf("SUMMARY: 📈 Overall Score: %.1f%% (%d/%d validations passed)", 
                  overall_score, passed_count, total_count))
  message("")
  
  # Individual validation results
  for (validation_name in names(validation_results)) {
    result <- validation_results[[validation_name]]
    status_icon <- if (result$passed) "✅" else "❌"
    message(sprintf("SUMMARY: %s %s: %s", status_icon, toupper(validation_name), 
                    if (result$passed) "PASSED" else "FAILED"))
  }
  
  message("")
  
  # Recommendations based on results
  recommendations <- c()
  
  if (!validation_results$naming$passed) {
    recommendations <- c(recommendations, "Update non-compliant file names to follow {platform}_ETL_{datatype}_{phase}.R pattern")
  }
  
  if (!validation_results$completeness$passed) {
    recommendations <- c(recommendations, "Create missing pipeline phases to complete all platform-datatype combinations")
  }
  
  if (!validation_results$schema$passed) {
    recommendations <- c(recommendations, "Fix schema registry issues and ensure all platform extensions are documented")
  }
  
  if (!validation_results$quality$passed) {
    recommendations <- c(recommendations, "Improve template code quality by adding missing patterns (error handling, validation, logging)")
  }
  
  if (!validation_results$principles$passed) {
    recommendations <- c(recommendations, "Update principle documentation to ensure consistency with new architecture")
  }
  
  if (length(recommendations) > 0) {
    message("SUMMARY: 🔧 RECOMMENDATIONS:")
    for (i in seq_along(recommendations)) {
      message(sprintf("SUMMARY: %d. %s", i, recommendations[i]))
    }
  } else {
    message("SUMMARY: 🎉 All validations passed! Architecture is fully compliant.")
  }
  
  message("SUMMARY: " %+% rep("=", 60))
  
  return(summary)
}

validation_summary <- generate_validation_summary()

# Store results for later analysis
validation_output_file <- file.path(validation_config$templates_path, "VALIDATION_RESULTS.yaml")
yaml::write_yaml(validation_summary, validation_output_file)
message(sprintf("SUMMARY: 💾 Validation results saved to: %s", validation_output_file))

# ==============================================================================
# 3. TEST
# ==============================================================================

message("TEST: 🧪 Running validation framework self-tests...")
test_start_time <- Sys.time()

test_execution <- function() {
  tryCatch({
    
    # Test 1: Verify all validation functions executed
    message("TEST: 🔍 Checking validation function execution...")
    
    expected_validations <- c("naming", "completeness", "schema", "quality", "principles")
    actual_validations <- names(validation_results)
    missing_validations <- setdiff(expected_validations, actual_validations)
    
    if (length(missing_validations) > 0) {
      stop(sprintf("Missing validation results: %s", paste(missing_validations, collapse = ", ")))
    }
    
    message("TEST: ✅ All validation functions executed successfully")
    
    # Test 2: Verify validation result structure
    message("TEST: 📋 Checking validation result structure...")
    
    for (validation_name in names(validation_results)) {
      result <- validation_results[[validation_name]]
      
      if (is.null(result$validation) || is.null(result$passed)) {
        stop(sprintf("Invalid result structure for %s validation", validation_name))
      }
    }
    
    message("TEST: ✅ All validation results have correct structure")
    
    # Test 3: Verify output file was created
    message("TEST: 💾 Checking output file creation...")
    
    if (!file.exists(validation_output_file)) {
      stop("Validation results file was not created")
    }
    
    # Try to read the output file
    saved_results <- yaml::read_yaml(validation_output_file)
    if (is.null(saved_results$overall_score)) {
      stop("Invalid validation results file format")
    }
    
    message("TEST: ✅ Validation results file created and readable")
    
    test_elapsed <- as.numeric(Sys.time() - test_start_time, units = "secs")
    message(sprintf("TEST: 🎉 All validation framework tests passed (%.2fs)", test_elapsed))
    
    test_passed <<- TRUE
    return(TRUE)
    
  }, error = function(e) {
    message(sprintf("TEST: ❌ Validation framework test failed: %s", e$message))
    return(FALSE)
  })
}

# Execute test function
test_result <- test_execution()

# ==============================================================================
# 4. RESULT
# ==============================================================================

script_end_time <- Sys.time()
total_elapsed <- as.numeric(script_end_time - script_start_time, units = "secs")

message("RESULT: 📊 ETL Validation Framework Summary:")
message(sprintf("RESULT: ⏱️  Total execution time: %.2f seconds", total_elapsed))
message(sprintf("RESULT: 🎯 Overall validation score: %.1f%%", validation_summary$overall_score))
message(sprintf("RESULT: ✅ Validations passed: %d/%d", validation_summary$validations_passed, validation_summary$total_validations))

if (test_passed && validation_summary$overall_score >= 80) {
  message("RESULT: ✅ ETL Data Flow Separation Architecture validation completed successfully")
  message("RESULT: 🎉 Architecture meets quality standards for production deployment")
  script_success <- TRUE
} else {
  error_msg <- sprintf("ETL Architecture validation failed. Overall score: %.1f%%, Framework tests: %s", 
                      validation_summary$overall_score, test_passed)
  message(sprintf("RESULT: ❌ %s", error_msg))
  message("RESULT: 🔧 Review recommendations above before proceeding with deployment")
  script_success <- (validation_summary$overall_score >= 60)  # Allow with warnings if score >= 60%
}

message(sprintf("RESULT: 🕐 End time: %s", format(script_end_time, "%Y-%m-%d %H:%M:%S")))

# Clean up and deinitialize
autodeinit()

# Return final result
if (script_success) {
  message("🎉 ETL Data Flow Separation Architecture validation completed successfully!")
} else {
  stop("❌ ETL Architecture validation failed - see recommendations above")
}