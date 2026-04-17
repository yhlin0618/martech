#!/usr/bin/env Rscript

# Debug ETL script - minimal version
message("Starting CBZ debug test...")

# Try source the Rprofile directly
tryCatch({
  source("scripts/global_scripts/22_initializations/sc_Rprofile.R")
  message("✅ sc_Rprofile.R loaded successfully")
}, error = function(e) {
  message("❌ Error loading sc_Rprofile.R: ", e$message)
})

# Try calling autoinit
tryCatch({
  autoinit()
  message("✅ autoinit() completed successfully")
}, error = function(e) {
  message("❌ Error in autoinit(): ", e$message)
})

message("CBZ debug test completed")
