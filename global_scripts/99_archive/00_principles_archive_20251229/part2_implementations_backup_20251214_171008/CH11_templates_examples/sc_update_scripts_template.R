# =============================================================================
# Update Script Template
# Purpose: Standard template for creating platform-specific update scripts
# Usage: Copy to /update_scripts/ and rename following conventions:
#        - Old convention: {platform}_D{derivation}_{step}.R (e.g., eby_D03_01.R)
#        - New convention: D{derivation}_{step}_P{platform}.R (e.g., D03_01_P06.R)
# =============================================================================

# --- Script Metadata ---
# Derivation: D0X - [Derivation Name]
# Platform: [Platform Name] ([platform_code])
# Step: D0X_YY - [Step Description]
# Purpose: [Brief description following SNSQL pattern]
# Author: [Your Name]
# Date Created: [YYYY-MM-DD]
# Related Principles: [List relevant principles]

# =============================================================================
# D0X_YY: [Step Title]
# Purpose: [Detailed purpose following derivation flow]
# Platform: [Platform] ([code])
# Step: D0X_YY - [SNSQL operation]
# =============================================================================

# --- Initialization ---
autoinit()

# --- Database Connections ---
# Connect to required databases based on derivation needs
dbConnect_from_list("raw_data")
dbConnect_from_list("cleansed_data")  
dbConnect_from_list("processed_data")
dbConnect_from_list("app_data")

# --- Platform Configuration ---
platform_id <- "[platform_code]"  # e.g., "amz", "eby", "cbz"
platform_name <- "[Platform Name]"  # e.g., "Amazon", "eBay", "Cyberbiz"

# --- Load Required Functions ---
# Load derivation-specific functions
source_directory("update_scripts/global_scripts/04_utils")
source_directory("update_scripts/global_scripts/05_data_processing")

# --- Security Check (if needed) ---
# For API-based platforms
# api_key <- Sys.getenv("PLATFORM_API_KEY")
# if (api_key == "") {
#   cli::cli_alert_warning("API key not found in environment, using config file")
#   # Load from secure config
# }

# --- Main Execution ---
tryCatch({
  
  cli::cli_h1("D0X_YY: [Step Title]")
  cli::cli_alert_info("Platform: {platform_name} ({platform_id})")
  cli::cli_alert_info("Time: {Sys.time()}")
  
  # =========================================================================
  # Step 1: [First Operation]
  # =========================================================================
  cli::cli_h2("Step 1: [Operation Description]")
  
  # Example: Import data
  # df_input <- dbReadTable(raw_data, "source_table")
  # cli::cli_alert_success("Loaded {nrow(df_input)} records from source")
  
  # =========================================================================
  # Step 2: [Processing Operation]
  # =========================================================================
  cli::cli_h2("Step 2: [Operation Description]")
  
  # Example: Process data
  # df_processed <- fn_process_data(
  #   data = df_input,
  #   platform_id = platform_id
  # )
  # cli::cli_alert_success("Processed {nrow(df_processed)} records")
  
  # =========================================================================
  # Step 3: [Save Results]
  # =========================================================================
  cli::cli_h2("Step 3: Save to Database")
  
  # Example: Save to appropriate schema
  # dbWriteTable(
  #   conn = processed_data,
  #   name = paste0("df_", platform_id, "_result"),
  #   value = df_processed,
  #   overwrite = TRUE
  # )
  # cli::cli_alert_success("Saved to processed_data.df_{platform_id}_result")
  
  # =========================================================================
  # Summary
  # =========================================================================
  cli::cli_h2("Summary")
  # cli::cli_alert_info("Records processed: {nrow(df_processed)}")
  # cli::cli_alert_info("Time range: {min(df_processed$date)} to {max(df_processed$date)}")
  
  cli::cli_alert_success("D0X_YY completed successfully")
  
}, error = function(e) {
  cli::cli_alert_danger("Error in D0X_YY: {e$message}")
  # Additional error logging if needed
  stop("D0X_YY execution failed")
})

# --- Deinitialization ---
autodeinit()

# =============================================================================
# Update Script Guidelines
# =============================================================================

# 1. Naming Conventions:
#    Platform IDs (R038):
#    - 00/P00: All platforms
#    - 01/P01: Amazon (amz)
#    - 02/P02: Official Website (web)
#    - 03/P03: Retail Store (ret)
#    - 04/P04: Distributor (dst)
#    - 05/P05: Social Media (soc)
#    - 06/P06: eBay (eby)
#    - 07/P07: Cyberbiz (cbz)
#    - 09/P09: Multi-platform (mpt)

# 2. Derivation Categories:
#    - D00: System initialization
#    - D01: Customer DNA analysis
#    - D02: Product analysis
#    - D03: Positioning analysis
#    - D04: Poisson precision marketing
#    - D05+: Custom derivations

# 3. SNSQL Operations:
#    - IMPORT: Load external data
#    - CLEANSING: Clean and validate data
#    - PROCESS: Transform data
#    - JOIN: Combine datasets
#    - CREATE: Generate new tables
#    - UPDATE: Modify existing data
#    - QUERY: Extract specific data

# 4. Database Schema Usage:
#    - raw_data: Original imported data
#    - cleansed_data: Cleaned, validated data
#    - processed_data: Transformed, enriched data
#    - app_data: Final application-ready data

# 5. Common Patterns:
#    
#    # Import external file
#    df_raw <- readxl::read_excel(
#      file.path(external_data_folder, platform_id, "data.xlsx")
#    )
#    
#    # Import from API
#    df_raw <- fn_fetch_platform_data(
#      api_key = api_key,
#      start_date = start_date,
#      end_date = end_date
#    )
#    
#    # Cleanse data
#    df_clean <- fn_cleanse_platform_data(
#      data = df_raw,
#      platform_id = platform_id
#    )
#    
#    # Join with reference data
#    df_enriched <- df_clean |>
#      left_join(df_reference, by = "product_id")
#    
#    # Save with standard naming
#    table_name <- paste0("df_", platform_id, "_", data_type)
#    dbWriteTable(conn, table_name, df_result, overwrite = TRUE)

# 6. Error Handling:
#    - Always wrap main logic in tryCatch
#    - Provide clear error messages
#    - Clean up on failure

# 7. Progress Reporting:
#    - Use cli package consistently
#    - Report key metrics (record counts, date ranges)
#    - Show clear success/failure status

# 8. Performance Tips:
#    - Use data.table for large datasets
#    - Process in chunks if needed
#    - Consider parallel processing for independent operations

# 9. Testing:
#    - Test with small sample first
#    - Validate output schema matches expectations
#    - Check for data quality issues

# 10. Documentation:
#     - Follow SNSQL notation in comments
#     - Document any platform-specific logic
#     - Reference source derivation document (D0X.md)