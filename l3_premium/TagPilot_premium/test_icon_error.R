################################################################################
# Test Icon Error - Find Exact Location
################################################################################

library(shiny)
library(bs4Dash)

cat("🔍 Testing app.R icon initialization...\n\n")

# Test by sourcing app.R in a controlled environment
test_env <- new.env()

tryCatch({
  cat("Loading app.R...\n")
  source("app.R", local = test_env, verbose = FALSE)
  cat("✅ app.R loaded successfully!\n")
}, error = function(e) {
  cat("❌ Error in app.R:\n")
  cat("  Message:", conditionMessage(e), "\n")
  cat("  Call:", deparse(conditionCall(e)), "\n\n")

  # Try to get more details
  cat("Traceback:\n")
  traceback_list <- sys.calls()
  for (i in seq_along(traceback_list)) {
    cat(sprintf("  %d: %s\n", i, deparse(traceback_list[[i]])[1]))
  }
})

cat("\n✅ Test complete!\n")
