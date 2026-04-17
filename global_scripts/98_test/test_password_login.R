# Test script for password-only login
# Run this to test the updated union_production_test.R

# Set up test environment
Sys.setenv(APP_PASSWORD = "test123")

# Run the app
setwd("/Users/che/Library/CloudStorage/Dropbox/che_workspace/projects/ai_martech/l4_enterprise/MAMBA")

# Instructions:
# 1. When the app opens, you should see the password login page
# 2. Enter password: test123
# 3. Click "進入系統"
# 4. You should be logged in and see the main application interface
# 5. The right panel should display content properly when clicking menu items
# 6. Try clicking different menu items to ensure content loads correctly

# Run the app
source("scripts/global_scripts/10_rshinyapp_components/unions/union_production_test.R")