---
id: "P07"
title: "App Construction Principles"
type: "principle"
date_created: "2025-03-10"
author: "Claude"
derives_from:
  - "P02": "Structural Blueprint"
  - "MP01": "Primitive Terms and Definitions"
influences:
  - "P17": "App Construction Function"
  - "P27": "YAML Configuration"
  - "R16": "Bottom-Up Construction Guide"
---

# Customer DNA App Construction Principles

## Core Implementation Principles

**IMPORTANT:** The app follows these critical construction principles:

1. **Content Treatment Rule:** 
   - If content is treated as a constant (not a variable), preserve it exactly as in the reference KitchenMAMA app
   - If content is treated as a variable, it may be modified to match specific requirements

2. **Scroll-Free UI Rule:**
   - Avoid unnecessary scrolling in the app interface
   - Use navigation panels (nav_panel) instead of long scrollable pages
   - Keep all critical information visible without requiring scrolling

3. **Brand Protection Rule:**
   - Never display company names in user-facing elements
   - Use generic application names (e.g., "AI行銷科技平台") instead of client-specific names
   - Maintain confidentiality of client identity in all UI components
   - Apply this rule even in development and internal testing environments

4. **Component Reuse Rule:**
   - Base all app functionality on existing components from 10_rshinyapp_components and 11_rshinyapp_utils directories
   - Do not create new UI or server functions outside of these established components
   - Only utilize and arrange the existing components within the app structure
   - Adapt the layout but not the core functionality of these components

5. **Bottom-Up Construction Rule:**
   - Start with data acquisition and processing components
   - Build small, focused components that perform specific functions
   - Test components individually before integration
   - Assemble the app incrementally, adding only necessary components
   - Avoid adding functionality until it's actually needed

6. **UI-Server-Defaults Triple Rule:**
   - Every UI component must have a corresponding server component and defaults file
   - Server components should handle NULL data_source gracefully by using defaults
   - All outputs defined in a UI module must be fulfilled by the matching server module
   - Provide default values for all outputs to handle cases where data is unavailable
   - Validate data before rendering to prevent errors and broken displays
   - Make server components usable with minimal or no configuration

7. **Initialization-Based Loading Rule:**
   - Use the appropriate mode-specific initialization script to load components
   - Do not manually source individual component files in app scripts
   - Rely on the initialization system to ensure all dependencies are properly loaded
   - Components should be automatically loaded based on their location and naming convention
   - Only use explicit source() for custom components not covered by initialization scripts

8. **Standardized Data Source Processing Rule:**
   - Use the processDataSource utility function to handle data source specifications
   - Support multiple data source formats consistently (NULL, string, array, object)
   - Ensure server components can work with all supported formats
   - Use a clean mapping between configuration and component initialization
   - Always provide reasonable defaults when data sources are unavailable
   - Process data sources reactively to respond to changes

This principle ensures that the app's structure, layout, and behavior remain identical to the KitchenMAMA app, while only WISER-specific data elements (like product categories, distribution channels, and brand-specific terminology) are adapted.

## Component Naming Convention

Shiny components should follow the naming convention defined in the script separation principles:

```
ui_[section]_[component].R
server_[section]_[component].R
defaults_[section]_[component].R
```

Where:
- **section**: Identifies the main app section (macro, micro, target)
- **component**: Describes specific functionality

Components are stored in the `10_rshinyapp_components` directory, organized by section:

Examples:
- `10_rshinyapp_components/macro/ui_macro_overview.R` and `server_macro_overview.R` for the Macro Overview panel
- `10_rshinyapp_components/micro/ui_micro_customer.R`, `server_micro_customer.R`, and `defaults_micro_customer.R` for the Micro Customer panel
- `10_rshinyapp_components/target/ui_target_segmentation.R` and `server_target_segmentation.R` for the Target Profiling panel

This naming convention provides clarity about each component's purpose and location in the app.

## Implementation Details

### Constant Elements (Preserved Exactly)

These elements must not be changed as they are part of the core app structure:

1. **Panel Organization**
   - Three main panels: Macro Overview (總覽), Micro Customer (微觀), Target Profiling (目標群組)
   - Layout of elements within each panel
   - Panel ordering and hierarchy

2. **UI Components**
   - Value box structure and arrangement
   - Chart types and visualization approaches
   - Filter mechanisms and layout
   - Grid and card layout patterns

3. **Interaction Patterns**
   - How filtering affects data display
   - Interactive chart behaviors
   - Navigation between views
   - Selection mechanisms

4. **Code Architecture**
   - Module structure and organization
   - Reactive data flow patterns
   - Server-side data processing approach
   - Error handling methodologies

### Variable Elements (May Be Adapted)

These elements can be modified to match WISER-specific requirements:

1. **Data Sources**
   - Product categories from WISER catalog
   - Distribution channels specific to WISER
   - Geographic locations relevant to WISER
   - Time scale options if needed

2. **Terminology**
   - Text labels for metrics
   - Category names
   - Status descriptions
   - Value segment and loyalty tier labels

3. **Brand Elements**
   - App title incorporating WISER brand name
   - Color schemes if specified in brand guidelines
   - Terminology specific to WISER business context

4. **Data Processing**
   - Specific calculations for WISER metrics
   - How DNA segments are derived for WISER customers
   - Default filter values appropriate for WISER

## Practical Examples

### UI-Server-Defaults Triple Examples

#### Example 1: Complete Triple Implementation
- **Good Practice**: Create all three files for each component:
```r
# ui_micro_customer.R - Defines the UI structure
microCustomerUI <- function(id) { ... }

# server_micro_customer.R - Processes data and fulfills outputs
microCustomerServer <- function(id, data_source = NULL) { ... }

# defaults_micro_customer.R - Provides fallback values
microCustomerDefaults <- function() { ... }
```
- **Bad Practice**: Missing defaults or not handling NULL data gracefully

#### Example 2: Defaults-Based Component
- **Good Practice**: Allow components to run without real data:
```r
# In app.R
ui <- fluidPage(
  microCustomerUI("customer_module")
)

server <- function(input, output, session) {
  # No data source needed - defaults will be used
  microCustomerServer("customer_module")
}
```
- **Bad Practice**: Requiring a data source even for preview or testing purposes

#### Example 3: Default Fallback Logic
- **Good Practice**: Using safe access with defaults:
```r
# Get default values
defaults <- microCustomerDefaults()

# Use defaults for missing data
output$metric_value <- renderText({ 
  if (is.null(data) || is.na(data$value)) {
    return(defaults$metric_value)
  }
  data$value 
})
```
- **Bad Practice**: Direct unsafe access that can cause errors or empty displays

### Initialization-Based Loading Examples

#### Example 1: Correct Component Loading
- **Good Practice**: Using the appropriate initialization script at the start of the app
```r
# Load all components through initialization
if (!exists("INITIALIZATION_COMPLETED") || !INITIALIZATION_COMPLETED) {
  source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_app_mode.R"))
}

# The app can now directly use any component that was loaded by the initialization
ui <- fluidPage(
  microCustomerUI("customer_module")
)
```
- **Bad Practice**: Manually sourcing each component file
```r
# Don't do this
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "micro", "ui_micro_customer.R"))
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "micro", "server_micro_customer.R"))
```

### Standardized Data Source Processing Examples

#### Example 1: Using processDataSource in a Server Component
- **Good Practice**: Processing various data source formats consistently
```r
# In server_micro_customer.R
microCustomerServer <- function(id, data_source = NULL) {
  moduleServer(id, function(input, output, session) {
    # Process data source using the utility function
    tables <- reactive({
      processDataSource(
        data_source = data_source, 
        table_names = c("primary", "sales_by_customer", "customers"),
        get_table_func = get_table
      )
    })
    
    # Now access data through the standardized tables structure
    data <- reactive({ tables()$primary })
  })
}
```
- **Bad Practice**: Using complex conditional logic for different formats

#### Example 2: Data Source Specification in YAML
- **Good Practice**: Various data source formats in configuration
```yaml
components:
  micro:
    # Simple case - single table
    customer_profile: "customer_details"
    
    # Complex case - multiple tables with roles
    sales_analysis:
      primary: "sales_summary"
      history: "sales_history"
      details: "transaction_details"
      
    # Array case - ordered tables
    product_trends:
      - "product_data"
      - "trend_data"
      - "forecast_data"
```
- **Bad Practice**: Inconsistent formats or complex nested structures

#### Example 3: Building App from Configuration
- **Good Practice**: Using standardized processing
```r
# In app_builder_example.R
buildAppFromConfig <- function(config_file) {
  # Load configuration
  config <- readYamlConfig(config_file)
  
  # Server function with standardized component initialization
  server <- function(input, output, session) {
    # Initialize each component with its configuration
    microCustomerServer(
      id = "customer_module",
      data_source = config$components$micro$customer_profile
    )
  }
  
  # Return shiny app
  shinyApp(ui, server)
}
```
- **Bad Practice**: Custom format handling for each component

#### Example 2: Mode-Specific Loading
- **Good Practice**: Using the correct mode-specific initialization
```r
# In a production app
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_app_mode.R"))

# In a development environment
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_update_mode.R"))
```
- **Bad Practice**: Manual component management or using the wrong mode

#### Example 3: Custom Component Loading
- **Good Practice**: Only sourcing components not covered by initialization
```r
# First initialize the standard components
source(file.path("update_scripts", "global_scripts", "00_principles", "sc_initialization_app_mode.R"))

# Then only source custom components if needed
if (use_custom_feature) {
  source(file.path("local_scripts", "custom_feature.R"))
}
```
- **Bad Practice**: Mixing initialization with redundant manual sourcing of already-loaded components

### Bottom-Up Construction Examples

#### Example 1: Starting with Data
- **Good Practice**: First create and test the data source component that loads customer data
- **Bad Practice**: Building the entire UI first without confirming data availability and structure

#### Example 2: Incremental Development
- **Good Practice**: Creating a working macro overview panel before starting on the micro customer panel
- **Bad Practice**: Trying to implement all panels simultaneously before any are fully functional

#### Example 3: Component Testing
- **Good Practice**: Testing each component in isolation with mock data before integration
- **Bad Practice**: Only testing the app as a whole, making it difficult to identify component-specific issues

### Content Treatment Examples

#### Example 1: Panel Structure
- **Constant**: Three main panels with the same layout and functionality
- **Variable**: Panel titles translated to match language preference

#### Example 2: Customer Segmentation
- **Constant**: The segmentation approach (NES status, value segments, loyalty tiers)
- **Variable**: The specific labels and thresholds for segmentation

#### Example 3: Filter Options
- **Constant**: Filter types and their placement in the sidebar
- **Variable**: The actual options in each filter (e.g., specific product categories)

### Brand Protection Examples

#### Example 1: App Title
- **Bad Practice**: "WISER Customer DNA Analysis Dashboard"
- **Good Practice**: "AI行銷科技平台" (Generic AI Marketing Platform)

#### Example 2: Data Labels
- **Bad Practice**: "WISER Customer Segments"
- **Good Practice**: "Customer Segments" (Remove brand name)

#### Example 3: Documentation
- **Bad Practice**: Including client names in user-visible comments or help text
- **Good Practice**: Using generic terms like "the platform" or "this application"

### Scroll-Free UI Examples

#### Example 1: Navigation Structure
- **Good Practice**: Using nav_panel for each major functional area (Macro, Micro, Target)
- **Bad Practice**: Creating a single long scrollable page that requires users to scroll up and down

#### Example 2: Data Presentation
- **Good Practice**: Using compact visualizations and value boxes that fit within the visible area
- **Bad Practice**: Creating charts that extend beyond the screen, requiring scrolling to view all data

#### Example 3: Filter Placement
- **Good Practice**: Placing filters in a fixed sidebar that's always accessible
- **Bad Practice**: Placing filters at the top of a long scrollable page, making them inaccessible when scrolled down

### Component Reuse Examples

#### Example 1: UI Components
- **Good Practice**: Using ui_common_sidebar() from common/ui_common_sidebar.R without modification
- **Bad Practice**: Creating a new sidebar function with different parameters/structure

#### Example 2: Component Arrangement
- **Good Practice**: Organizing existing components within tabsets or layouts for better UX
- **Bad Practice**: Writing new component functions that duplicate functionality in existing components

#### Example 3: Server Logic
- **Good Practice**: Using macroOverviewServer() and other existing server functions
- **Bad Practice**: Creating custom server logic that bypasses the established component pattern

## Maintenance Guidelines

When updating the app:

1. Always check against the KitchenMAMA reference app to ensure constant elements remain unchanged
2. Update variable elements only when specific requirements change
3. Document any deviations from the KitchenMAMA reference with clear rationale
4. Test thoroughly to ensure both structural integrity and specific functionality
5. Verify that no company or brand names appear in any user-facing elements
6. Apply the Brand Protection Rule consistently across all UI components and documentation
7. Use only existing components from 10_rshinyapp_components and 11_rshinyapp_utils directories
8. If new functionality is needed, add it to the appropriate component in these directories first
9. Always implement both UI and server components as pairs, never one without the other
10. Rely on the initialization scripts to load components rather than manually sourcing them
11. Design server components to handle NULL data_source by using defaults
12. Use the processDataSource utility to handle all data source formats consistently
13. Create new utilities in 11_rshinyapp_utils when implementing reusable functionality
14. Use the buildAppFromConfig function for declarative app construction via YAML
15. Maintain a clean separation between data configuration and component implementation