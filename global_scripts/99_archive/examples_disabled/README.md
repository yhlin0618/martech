# Shiny Component Examples

**IMPORTANT NOTE: Some example apps in this directory have been temporarily moved to `examples_disabled/` to prevent them from automatically launching during initialization.**

This directory contains example Shiny components that follow the established naming conventions and best practices. Use these examples as templates when creating new components.

## Naming Convention

All Shiny components should follow the hierarchical naming convention:

```
ui_[section]_[component].R
server_[section]_[component].R
fn_[helper_function].R  (for helper functions)
```

Where:
- **section**: Identifies the main app section (macro, micro, target)
- **component**: Describes specific functionality 

## Examples

This directory includes the following example components and templates:

- `ui_micro_customer_profile.R` and `server_micro_customer_profile.R`: Example of a customer profile component for the micro section
- `app_minimal_template.R`: Minimal Shiny app demonstrating the Bottom-Up Construction principle
- `app_complete_template.R`: Complete Shiny app template with all sections

### App Construction Function Examples

- `fn_app_constructor.R`: Function for creating apps from declarative configurations
- `app_constructor_example.R`: Example of using the constructor with an R list configuration
- `app_config_from_file_example.R`: Example of using the constructor with a JSON configuration file
- `app_configs/`: Directory containing example configuration files:
  - `customer_dna_app.json`: JSON configuration example
  - `customer_dna_app.yaml`: YAML configuration example (preferred format)

**Disabled Examples** (in examples_disabled/ directory):
- `app_builder_example.R`: Shows how to use the app builder to construct an app declaratively
- `app_config_from_yaml_example.R`: Example of using the constructor with a YAML configuration file

## Related Principles

All principle documents have been centralized in the `00_principles` directory following the Documentation Centralization meta-principle:

- See `/update_scripts/global_scripts/00_principles/16_bottom_up_construction_guide.md` for the Bottom-Up Construction principle
- See `/update_scripts/global_scripts/00_principles/15_working_directory_guide.md` for the Working Directory guide

## Usage in App

Components should be imported and used in the main app.R file like this:

```r
# Source the UI and server components
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "macro", "ui_macro_overview.R"))
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "macro", "server_macro_overview.R"))
source(file.path("update_scripts", "global_scripts", "10_rshinyapp_components", "macro", "fn_create_kpi_box.R"))

# In the UI
ui <- fluidPage(
  macroOverviewUI("macro1")
)

# In the server
server <- function(input, output, session) {
  macroOverviewServer("macro1", data_source)
}
```

## Template for New Components

When creating a new component, follow this structure for the UI file:

```r
#' Section Component UI Component
#'
#' This component provides the UI elements for...
#'
#' @param id The component ID
#'
#' @return A UI component for...
#' 
#' @examples
#' # In the main UI
#' fluidPage(
#'   sectionComponentUI("example")
#' )
#'
#' @export
sectionComponentUI <- function(id) {
  ns <- NS(id)
  
  # UI code here
}
```

And for the server file:

```r
#' Section Component Server Component
#'
#' This component provides the server-side logic for...
#'
#' @param id The component ID
#' @param data_source The data source
#'
#' @return A server function for...
#' 
#' @examples
#' # In the server function
#' sectionComponentServer("example", data_source)
#'
#' @export
sectionComponentServer <- function(id, data_source) {
  moduleServer(id, function(input, output, session) {
    # Server code here
  })
}
```

For helper functions, use:

```r
#' Helper Function Description
#'
#' This function provides...
#' 
#' @param param1 Description of parameter
#'
#' @return Description of return value
#'
#' @examples
#' helperFunction("example")
#' 
#' @export
helperFunction <- function(param1) {
  # Function code here
}
```