#
# Complete Shiny App Template following Bottom-Up Construction Principle
#

# Load required packages
library(shiny)
library(bslib)
library(dplyr)
library(plotly)
library(DBI)
library(duckdb)

# Source components incrementally added during development
# 1. Core data components
source("update_scripts/global_scripts/10_rshinyapp_components/data/ui_data_source.R")
source("update_scripts/global_scripts/10_rshinyapp_components/data/server_data_source.R")

# 2. Common UI components
source("update_scripts/global_scripts/10_rshinyapp_components/common/ui_common_sidebar.R")
source("update_scripts/global_scripts/10_rshinyapp_components/common/server_common_sidebar.R")

# 3. Section components 
# These would be added one by one as they're developed
source("update_scripts/global_scripts/10_rshinyapp_components/macro/ui_macro_overview.R")
source("update_scripts/global_scripts/10_rshinyapp_components/macro/server_macro_overview.R")
source("update_scripts/global_scripts/10_rshinyapp_components/macro/fn_create_kpi_box.R")

source("update_scripts/global_scripts/10_rshinyapp_components/micro/ui_micro_customer_profile.R")
source("update_scripts/global_scripts/10_rshinyapp_components/micro/server_micro_customer_profile.R")

source("update_scripts/global_scripts/10_rshinyapp_components/target/ui_target_segmentation.R")
source("update_scripts/global_scripts/10_rshinyapp_components/target/server_target_segmentation.R")

# Define UI with full navigation structure
ui <- page_navbar(
  title = "AI行銷科技平台",
  theme = bs_theme(version = 5, 
                  bootswatch = "default"),
  
  # Common sidebar for filters
  sidebar = commonSidebarUI("sidebar"),
  
  # Main nav panels - each corresponding to a major section
  # These would be uncommented as they become available
  macroOverviewUI("macro"),
  microCustomerProfileUI("micro"),
  targetSegmentationUI("target")
)

# Define server logic
server <- function(input, output, session) {
  # 1. Initialize data source first - foundation of the app
  data_source <- dataSourceServer("data")
  
  # 2. Initialize sidebar filters
  commonSidebarServer("sidebar", data_source)
  
  # 3. Initialize section components
  # These would be uncommented as they become available
  macroOverviewServer("macro", data_source)
  microCustomerProfileServer("micro", data_source)
  targetSegmentationServer("target", data_source)
  
  # Optional: Add any global reactive elements or observers
  # that coordinate between components
}

# Run the app
shinyApp(ui = ui, server = server)