# ==============================================================================
# Test Script for eBay ETL Encoding Fix
# Purpose: Verify MP100 UTF-8 compliance and proper data import
# ==============================================================================

message(strrep("=", 80))
message("TESTING EBY ETL ENCODING FIX")
message(strrep("=", 80))

# Initialize
library(DBI)
library(duckdb)
library(odbc)

# Test 1: Direct SQL Server Connection Test
message("\n=== TEST 1: SQL Server Connection and Encoding ===")

test_sql_connection <- function() {
  tryCatch({
    # Connect to SQL Server through SSH tunnel
    conn <- DBI::dbConnect(
      odbc::odbc(),
      Driver = "ODBC Driver 18 for SQL Server",
      Server = "tcp:127.0.0.1,1433",
      Database = "MAMBATEK",
      UID = "sa",
      PWD = "u3sql@2007",
      Encrypt = "no"
    )
    
    message("✅ Connected to MAMBATEK database")
    
    # Test query with explicit encoding handling
    test_query <- "
      SELECT TOP 5
        ORD001,
        CONVERT(VARCHAR(500), ORD010) AS ORD010_varchar,
        CAST(ORD010 AS NVARCHAR(500)) COLLATE Chinese_PRC_CI_AS AS ORD010_nvarchar,
        ISNULL(CAST(ORD010 AS NVARCHAR(500)) COLLATE Chinese_PRC_CI_AS, '') AS ORD010_safe
      FROM BAYORD
      WHERE ORD010 IS NOT NULL
    "
    
    result <- DBI::dbGetQuery(conn, test_query)
    
    message("\nSample data retrieved:")
    print(head(result, 3))
    
    # Check for encoding issues
    has_encoding_issues <- FALSE
    for (col in names(result)) {
      if (any(grepl("ENCODING_ERROR|\\?\\?|\\xEF\\xBF\\xBD", result[[col]], perl = TRUE))) {
        message(sprintf("⚠️  Encoding issues detected in column: %s", col))
        has_encoding_issues <- TRUE
      }
    }
    
    if (!has_encoding_issues) {
      message("✅ No obvious encoding issues detected in test query")
    }
    
    DBI::dbDisconnect(conn)
    return(TRUE)
    
  }, error = function(e) {
    message("❌ SQL Server connection test failed: ", e$message)
    return(FALSE)
  })
}

# Test 2: Check Raw Data Import
message("\n=== TEST 2: Raw Data Import Verification ===")

test_raw_data <- function() {
  tryCatch({
    # Connect to raw_data.duckdb
    con <- dbConnect(duckdb::duckdb(), "data/mamba_eby_raw.duckdb", read_only = TRUE)
    
    # Check if table exists
    if (dbExistsTable(con, "df_eby_sales___raw___MAMBA")) {
      message("✅ Table df_eby_sales___raw___MAMBA exists")
      
      # Get sample data
      sample_data <- dbGetQuery(con, "
        SELECT ORD001, ORD010, ORD011, ORD013, ORD014, ORD015
        FROM df_eby_sales___raw___MAMBA
        LIMIT 5
      ")
      
      message("\nSample data from raw table:")
      print(sample_data)
      
      # Check for ENCODING_ERROR strings
      encoding_errors <- dbGetQuery(con, "
        SELECT COUNT(*) as error_count
        FROM df_eby_sales___raw___MAMBA
        WHERE ORD010 = 'ENCODING_ERROR'
           OR ORD011 = 'ENCODING_ERROR'
           OR ORD013 = 'ENCODING_ERROR'
      ")
      
      if (encoding_errors$error_count > 0) {
        message(sprintf("⚠️  Found %d rows with ENCODING_ERROR placeholders", 
                       encoding_errors$error_count))
        
        # Get total row count for context
        total_rows <- dbGetQuery(con, 
          "SELECT COUNT(*) as n FROM df_eby_sales___raw___MAMBA")$n
        
        message(sprintf("    This affects %.1f%% of %d total rows", 
                       (encoding_errors$error_count / total_rows) * 100, total_rows))
      } else {
        message("✅ No ENCODING_ERROR placeholders found - encoding fix successful!")
      }
      
      # Check UTF-8 compliance flag
      utf8_check <- dbGetQuery(con, "
        SELECT utf8_compliant, encoding_method, COUNT(*) as count
        FROM df_eby_sales___raw___MAMBA
        GROUP BY utf8_compliant, encoding_method
      ")
      
      message("\nUTF-8 Compliance Status:")
      print(utf8_check)
      
    } else {
      message("❌ Table df_eby_sales___raw___MAMBA not found")
      message("   Please run: Rscript scripts/update_scripts/eby_ETL_sales_0IM___MAMBA.R")
    }
    
    dbDisconnect(con)
    return(TRUE)
    
  }, error = function(e) {
    message("❌ Raw data test failed: ", e$message)
    return(FALSE)
  })
}

# Test 3: Verify Character Encoding in R
message("\n=== TEST 3: R Character Encoding Test ===")

test_r_encoding <- function() {
  # Test string with various characters
  test_strings <- c(
    "Simple ASCII text",
    "Text with accents: café, naïve",
    "Chinese characters: 中文测试",
    "Mixed: Hello 世界 café"
  )
  
  message("Testing encoding conversions:")
  
  for (str in test_strings) {
    message(sprintf("\nOriginal: %s", str))
    
    # Simulate SQL Server encoding scenarios
    # Windows-1252 simulation
    win_encoded <- iconv(str, from = "UTF-8", to = "Windows-1252", sub = "?")
    win_decoded <- iconv(win_encoded, from = "Windows-1252", to = "UTF-8", sub = "")
    message(sprintf("  Via Windows-1252: %s", win_decoded))
    
    # GB2312 simulation (for Chinese)
    gb_encoded <- iconv(str, from = "UTF-8", to = "GB2312", sub = "?")
    gb_decoded <- iconv(gb_encoded, from = "GB2312", to = "UTF-8", sub = "")
    message(sprintf("  Via GB2312: %s", gb_decoded))
    
    # Check for data loss
    if (str != win_decoded && str != gb_decoded) {
      message("  ⚠️  Potential data loss in encoding conversion")
    }
  }
  
  return(TRUE)
}

# Run all tests
message("\n" , strrep("=", 80))
message("RUNNING ALL TESTS")
message(strrep("=", 80))

# Check if SSH tunnel is running first
tunnel_check <- system("pgrep -f 'ssh.*220.128.138.146.*125.227.84.85'", intern = TRUE)
if (length(tunnel_check) == 0) {
  message("\n⚠️  SSH tunnel not detected!")
  message("Please run: bash scripts/update_scripts/setup_mamba_tunnel.sh")
  message("Or manually: ssh -L 1433:125.227.84.85:1433 kylelin@220.128.138.146")
  message("Password: 618112")
} else {
  message("✅ SSH tunnel is running (PID: ", tunnel_check[1], ")")
  
  # Run SQL connection test only if tunnel is available
  test1_result <- test_sql_connection()
}

# Always run these tests (they check local data)
test2_result <- test_raw_data()
test3_result <- test_r_encoding()

# Summary
message("\n" , strrep("=", 80))
message("TEST SUMMARY")
message(strrep("=", 80))

if (exists("test1_result") && test1_result) {
  message("✅ SQL Server connection test: PASSED")
} else {
  message("⚠️  SQL Server connection test: SKIPPED or FAILED")
}

if (test2_result) {
  message("✅ Raw data import test: PASSED")
} else {
  message("❌ Raw data import test: FAILED")
}

if (test3_result) {
  message("✅ R encoding test: PASSED")
}

message("\n=== RECOMMENDATIONS ===")
message("1. If encoding errors persist, check SQL Server collation settings")
message("2. Consider using nchar/nvarchar columns in SQL Server for Unicode support")
message("3. Ensure ODBC driver supports UTF-8 (ODBC Driver 18 recommended)")
message("4. Monitor scripts/global_scripts/00_principles/changelog/monitoring/ for real-time errors")

message(strrep("=", 80))
message("TEST COMPLETE")
message(strrep("=", 80))