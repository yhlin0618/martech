# =============================================================================
# ISSUE-119 Fix Verification Test
# =============================================================================
#
# Purpose: 驗證動態配置載入修復是否正常運作
#
# Test Scenario:
# 1. 清除環境變數（模擬 Posit Connect 尚未注入的情況）
# 2. 載入 config.R
# 3. 設定環境變數（模擬 Posit Connect 稍後注入）
# 4. 驗證 get_config() 能否取得正確的值
#
# Expected Result: get_config() 應該取得最新設定的環境變數值

cat("\n")
cat("=================================================================\n")
cat("  ISSUE-119 Fix Verification Test\n")
cat("  Testing Dynamic Config Loading\n")
cat("=================================================================\n\n")

# Step 1: 清除所有資料庫相關環境變數
cat("Step 1: Clearing database environment variables...\n")
Sys.unsetenv(c("PGHOST", "PGPORT", "PGUSER", "PGPASSWORD", "PGDATABASE", "PGSSLMODE", "OPENAI_API_KEY"))
cat("✓ Environment variables cleared\n\n")

# Step 2: 載入 config.R（此時環境變數應該是空的）
cat("Step 2: Sourcing config.R (env vars are empty at this point)...\n")
source("config/config.R")
cat("✓ config.R loaded\n\n")

# Step 3: 取得初始配置（應該是空的或預設值）
cat("Step 3: Getting initial config (should have empty/default values)...\n")
initial_db_config <- get_config("db")
cat("Initial DB Config:\n")
cat("  PGHOST:", initial_db_config$host, "\n")
cat("  PGPORT:", initial_db_config$port, "\n")
cat("  PGUSER:", initial_db_config$user, "\n")
cat("  Note: Empty values are expected at this point\n\n")

# Step 4: 現在設定環境變數（模擬 Posit Connect 稍後注入）
cat("Step 4: Setting environment variables (simulating Posit Connect injection)...\n")
Sys.setenv(
  PGHOST = "test-host.example.com",
  PGPORT = "5432",
  PGUSER = "test_user",
  PGPASSWORD = "test_password",
  PGDATABASE = "test_database",
  PGSSLMODE = "require",
  OPENAI_API_KEY = "sk-test-key"
)
cat("✓ Environment variables set\n\n")

# Step 5: 再次取得配置（應該要有新的值！）
cat("Step 5: Getting config again (should have NEW values from environment)...\n")
updated_db_config <- get_config("db")
cat("Updated DB Config:\n")
cat("  PGHOST:", updated_db_config$host, "\n")
cat("  PGPORT:", updated_db_config$port, "\n")
cat("  PGUSER:", updated_db_config$user, "\n")
cat("  PGPASSWORD:", updated_db_config$password, "\n")
cat("  PGDATABASE:", updated_db_config$dbname, "\n")
cat("  PGSSLMODE:", updated_db_config$sslmode, "\n\n")

# Step 6: 驗證結果
cat("Step 6: Verification\n")
cat("===================\n")

test_passed <- TRUE

if (updated_db_config$host == "test-host.example.com") {
  cat("✅ PASS: PGHOST correctly updated to test-host.example.com\n")
} else {
  cat("❌ FAIL: PGHOST is '", updated_db_config$host, "' (expected 'test-host.example.com')\n", sep="")
  test_passed <- FALSE
}

if (updated_db_config$port == 5432) {
  cat("✅ PASS: PGPORT correctly updated to 5432\n")
} else {
  cat("❌ FAIL: PGPORT is ", updated_db_config$port, " (expected 5432)\n", sep="")
  test_passed <- FALSE
}

if (updated_db_config$user == "test_user") {
  cat("✅ PASS: PGUSER correctly updated to test_user\n")
} else {
  cat("❌ FAIL: PGUSER is '", updated_db_config$user, "' (expected 'test_user')\n", sep="")
  test_passed <- FALSE
}

if (updated_db_config$password == "test_password") {
  cat("✅ PASS: PGPASSWORD correctly updated to test_password\n")
} else {
  cat("❌ FAIL: PGPASSWORD is '", updated_db_config$password, "' (expected 'test_password')\n", sep="")
  test_passed <- FALSE
}

cat("\n")
if (test_passed) {
  cat("🎉 SUCCESS! Dynamic config loading is working correctly.\n")
  cat("   get_config() now reads fresh environment variable values each time.\n")
  cat("   This fixes the Posit Connect variable timing issue.\n")
} else {
  cat("❌ FAILURE! Some tests failed. The fix may not be working correctly.\n")
}

cat("\n")
cat("=================================================================\n")
cat("  Test Complete\n")
cat("=================================================================\n\n")

# Cleanup
Sys.unsetenv(c("PGHOST", "PGPORT", "PGUSER", "PGPASSWORD", "PGDATABASE", "PGSSLMODE", "OPENAI_API_KEY"))
