# RC03: App Component Template

## Type
Rule

## Summary
All application components must follow a standardized structure that enables modular composition and interchangeability.

## Motivation
Consistent component structure ensures:
1. Components can be developed independently
2. Components can be combined using the Union pattern
3. UIs remain maintainable and extensible
4. Components can be easily substituted or upgraded

## Rule Details

### Component Structure Requirements

All application components MUST return a list with the following structure:

```r
list(
  ui = list(
    filter = function(id) { ... },  # UI for filters in sidebar
    display = function(id) { ... }  # UI for main display area
  ),
  server = function(input, output, session) {
    # Server-side logic
    
    # Use defaults() function to get default values when needed
    default_values <- defaults()
    
    # Apply defaults to outputs when data is missing
    # ...
    
    # Returns reactive data or values for external use
    return(reactive_data)
  },
  defaults = function() {
    # Returns a list of default values for the component
    list(
      field1 = "default1",
      field2 = 0
    )
  }
)
```

IMPORTANT: The `defaults` function should be defined at the same level as `ui` and `server`, NOT within the server function. This ensures:
1. The Union pattern can properly combine defaults from multiple components (MP56)
2. Defaults are accessible both within and outside the server function
3. Component structure maintains clear separation of concerns (P62)

### Component Creator Function

Every component MUST have a creator function with a consistent signature:

```r
myComponentName <- function(
  id,                    # Required: component ID
  app_data_connection,   # Required: data connection
  config = NULL,         # Optional: component configuration
  translate = function(x) x  # Optional: translation function
) {
  # Component implementation
  list(
    ui = list(...),
    server = function(...) { ... },
    defaults = function() { ... }  # Default values for the component
  )
}
```

### UI Functions

Both filter and display UI functions:

1. MUST take an `id` parameter
2. MUST use proper namespacing via `NS(id)`
3. MUST return valid Shiny UI elements
4. SHOULD use reactive input elements consistently
5. SHOULD handle empty or missing data gracefully

### Server Function

The server function:

1. MUST take standard `input`, `output`, and `session` parameters
2. MUST initialize all outputs declared in UI functions
3. MUST use the Universal Data Access Pattern (R91)
4. MUST return any data intended for external use
5. SHOULD handle errors gracefully
6. SHOULD provide meaningful debug output

### Nesting and Composition

Components MUST support compositional patterns:

1. Multiple instances can exist simultaneously
2. Components can be combined via the Union pattern
3. Component state should not leak to global scope

## Examples

### Basic Component Implementation

```r
myComponent <- function(id, app_data_connection, config = NULL, translate = function(x) x) {
  # Create namespaced ID for demonstrating scope (actual namespacing happens in UI functions)
  ns <- NS(id)
  
  # Return a properly structured component
  list(
    ui = list(
      filter = function(id) {
        ns <- NS(id)
        div(
          class = "component-filter",
          selectInput(ns("option"), translate("Select Option:"), choices = c("A", "B", "C"))
        )
      },
      display = function(id) {
        ns <- NS(id)
        div(
          class = "component-display",
          h3(translate("My Component")),
          plotOutput(ns("plot"))
        )
      }
    ),
    server = function(input, output, session) {
      # Get default values from defaults() function
      default_values <- defaults()
      
      # Implementation of server logic
      output$plot <- renderPlot({
        # Get the option or use default if NULL
        option_value <- if (is.null(input$option)) default_values$option else input$option
        
        # Generate plot based on input$option
        plot(1:default_values$data_points, main = option_value)
      })
      
      # Return reactive data for external use
      return(reactive({ input$option }))
    },
    defaults = function() {
      # Return default values for the component
      list(
        option = "A",
        plot_title = "Default Chart",
        data_points = 10
      )
    }
  )
}
```

### Using a Component

```r
ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      # Render the filter UI
      uiOutput("component_filter")
    ),
    mainPanel(
      # Render the display UI
      uiOutput("component_display")
    )
  )
)

server <- function(input, output, session) {
  # Create the component
  my_component <- myComponent("comp1", app_data)
  
  # Render the filter UI
  output$component_filter <- renderUI({
    my_component$ui$filter("comp1")
  })
  
  # Render the display UI
  output$component_display <- renderUI({
    my_component$ui$display("comp1")
  })
  
  # Initialize the server
  component_result <- my_component$server(input, output, session)
}
```

## Related Rules and Principles

- **MP56 Connected Component Principle**: Components return parts that can be connected separately
- **MP52 Unidirectional Data Flow**: Data flows in one direction from selection to display
- **MP54 UI-Server Correspondence**: UI elements have corresponding server-side functionality
- **R88 Shiny Module ID Handling**: Proper namespace management across components
- **R91 Universal Data Access Pattern**: Components access data consistently

## Implementation Notes

1. Component creators should not initialize data connections directly; these should always be passed in
2. Avoid global variables and side effects in components
3. Components should use consistent styling and UI patterns
4. Filter UI should be kept minimal and focused on data filtering
5. Display UI should handle different screen sizes gracefully

## Anti-patterns

DO NOT:
- Create components that modify global state
- Create components that directly embed other components (use Union instead)
- Have component UI generate complete page layouts
- Create components with hardcoded data sources
- Return server functions that don't correctly handle inputs and outputs

## See Also

- [Union Component Pattern](/update_scripts/global_scripts/10_rshinyapp_components/unions/Union.md)
- [MP56: Connected Component Principle](/update_scripts/global_scripts/00_principles/MP56_connected_component.md)
- [R91: Universal Data Access Pattern](/update_scripts/global_scripts/00_principles/R91_universal_data_access_pattern.md)