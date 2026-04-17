# Working Directory Guide

This document explains how working directories should be handled within the Precision Marketing framework. These principles apply to all scripts, including both update scripts and Shiny applications.

## Project Directory Structure

The project uses a standardized directory structure based on Dropbox:

```
/Users/[username]/Library/CloudStorage/Dropbox/precision_marketing/
└── precision_marketing_WISER/
    └── precision_marketing_app/
        ├── data/
        ├── update_scripts/
        │   ├── global_scripts/
        │   │   ├── 00_principles/
        │   │   ├── 01_db/
        │   │   ├── 02_db_utils/
        │   │   ├── ...
        │   │   ├── 10_rshinyapp_components/
        │   │   └── ...
        │   └── ...
        └── app.R
```

## Working Directory Principle

**IMPORTANT**: All scripts in the project should use the `precision_marketing_app` directory as the working directory root. This ensures consistency and reliable file path resolution across all scripts and applications.

## Working Directory Conventions

1. **Project Root Directory**:
   - The working directory for all scripts should be the `precision_marketing_app` directory
   - The system detects this automatically for update scripts using `root_path_config.R`
   - Shiny apps must be explicitly run from this directory

2. **Absolute File Paths**:
   - Always use file paths relative to the project root directory
   - Examples:
     ```r
     # Correct - path relative to project root
     source("update_scripts/global_scripts/02_db_utils/fn_dbConnect_from_list.R")
     
     # Incorrect - relative path that depends on current location
     source("../db_utils/fn_dbConnect_from_list.R")
     ```

3. **File Path Helpers**:
   - Use `file.path()` to create paths in a platform-independent way:
     ```r
     # Good practice
     source(file.path("update_scripts", "global_scripts", "02_db_utils", "fn_dbConnect_from_list.R"))
     ```

## Initialization in Scripts

All scripts should follow this pattern:

```r
# Standard initialization pattern
if(!exists("INITIALIZATION_COMPLETED")) {
  source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))
}

# Script-specific code follows
# ...
```

## Initialization in Shiny Apps

Shiny apps should use this approach:

```r
# Standard initialization pattern for Shiny apps
library(shiny)
library(bslib)

# Initialize with absolute paths from project root
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "data", "ui_data_source.R"))
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "data", "server_data_source.R"))

# Additional components as needed...

# Define UI and server
ui <- fluidPage(...)
server <- function(input, output, session) {...}

# Run the app
shinyApp(ui, server)
```

## Common Working Directory Issues

### Problem: File Not Found Errors

If you see errors like:
```
Error in file(filename, "r", encoding = encoding) : 
  cannot open the connection
In addition: Warning message:
In file(filename, "r", encoding = encoding) :
  cannot open file '../data/ui_data_source.R': No such file or directory
```

This typically indicates that the working directory is not set correctly.

### Solution:

1. **Check Working Directory**:
   - Add `message(getwd())` at the start of your script to verify the working directory
   - Ensure you are in the `precision_marketing_app` directory
   - For update scripts, use the initialization script which handles this automatically

2. **Update File Paths**:
   - Make all paths relative to `precision_marketing_app/`
   - Use the pattern: `update_scripts/global_scripts/[directory]/[file].R`

3. **Use the Provided Templates**:
   - For Shiny apps, use the templates in the examples directory
   - For update scripts, follow the template in `update_scripts/templates/`
   
## Running Scripts and Apps

### For Update Scripts:

1. **From RStudio**:
   - The initialization script will handle working directory setup
   - Just ensure you run the initialization script first

2. **From Command Line**:
   - Navigate to the `precision_marketing_app/` directory
   - Run `Rscript update_scripts/your_script.R`

### For Shiny Apps:

1. **From RStudio**:
   - Set the working directory to `precision_marketing_app/` using `setwd()`
   - Then run `shiny::runApp("path/to/app.R")`

2. **From Command Line**:
   - Navigate to the `precision_marketing_app/` directory
   - Run `R -e "shiny::runApp('path/to/app.R')"`

3. **Using app.R in Root**:
   - For deployment, place app.R in the `precision_marketing_app/` directory
   - This ensures correct working directory by default

## Automatic Working Directory Detection

The project includes mechanisms to detect the correct working directory automatically:

1. **root_path_config.R**:
   - Detects the Dropbox location across different computers
   - Adapts to different usernames and operating systems
   - Provides the ROOT_PATH variable for absolute path construction

2. **sc_initialization_update_mode.R**:
   - Sources root_path_config.R
   - Sets up environment variables and paths
   - Loads required libraries
   - Use this for all update scripts

## Best Practices

1. **Test Path Resolution**:
   - Add debug messages to verify file paths are resolving correctly
   - Example: `message(paste("Checking path:", file.path("update_scripts", "global_scripts", "02_db_utils", "fn_dbConnect_from_list.R")))`

2. **Set Working Directory Explicitly**:
   - When running scripts manually, explicitly set working directory to precision_marketing_app
   - Example: `setwd("/Users/[username]/Library/CloudStorage/Dropbox/precision_marketing/precision_marketing_WISER/precision_marketing_app")`

3. **Use Relative Paths from Project Root**:
   - Always construct paths relative to the project root
   - Never use `setwd()` within scripts (except at the very beginning of interactive sessions)
   - Avoid `../` in paths as they depend on current location