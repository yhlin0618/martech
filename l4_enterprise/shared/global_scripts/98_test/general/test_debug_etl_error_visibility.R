# Test script to validate enhanced error visibility in debug ETL
# This script contains intentional errors to test the debugging system

cat("🧪 TESTING ENHANCED ERROR VISIBILITY SYSTEM\n")
cat(strrep("=", 60), "\n")

# Load the debugging system
if (!exists("autoinit", mode = "function")) {
  source(file.path("scripts", "global_scripts", "22_initializations", "sc_Rprofile.R"))
}

# Load debug enhancement functions
source(file.path("scripts", "global_scripts", "22_initializations", "sc_debug_verbose_init.R"))

# Test 1: Initialize with clean output
cat("\n1️⃣ Testing clean initialization...\n")
debug_autoinit(quiet_init = TRUE, highlight_errors = TRUE)

# Test 2: Test debug_progress function
cat("\n2️⃣ Testing debug progress reporting...\n")
debug_progress("TEST", "This is a test progress message", "start")
debug_progress("TEST", "This is a success message", "success")
debug_progress("TEST", "This is a warning message", "warning")
debug_progress("TEST", "This is an info message", "info")

# Test 3: Test enhanced error catching
cat("\n3️⃣ Testing enhanced error visibility...\n")
cat("Triggering intentional error to test visibility...\n")

# This should produce a prominently displayed error
tryCatch({
  debug_tryCatch({
    nonexistent_function_call()
  }, "Function Call Test")
}, error = function(e) {
  cat("✅ Error was properly caught and displayed prominently\n")
})

# Test 4: Test database connection error simulation
cat("\n4️⃣ Testing database connection error...\n")
tryCatch({
  debug_tryCatch({
    # Simulate a database connection failure
    stop("Failed to connect to database: Connection timeout")
  }, "Database Connection Test")
}, error = function(e) {
  cat("✅ Database error was properly caught and displayed\n")
})

# Test 5: Test warning visibility
cat("\n5️⃣ Testing warning visibility...\n")
debug_tryCatch({
  warning("This is a test warning - should be visible immediately")
  cat("Continuing after warning...\n")
}, "Warning Test")

cat("\n")
cat(strrep("✅", 60), "\n")
cat("✅ ERROR VISIBILITY TESTING COMPLETED\n")
cat("✅ All errors should have been prominently displayed above\n")
cat(strrep("✅", 60), "\n")

# Clean up
autodeinit()