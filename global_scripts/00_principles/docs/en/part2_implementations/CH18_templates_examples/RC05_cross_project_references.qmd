# RC05: Cross-Project Package Function References

## Purpose

This reference code provides the required structure and content for the cross-project package function reference repository at `/precision_marketing/R_package_references/`. As per R104 Package Function Reference Rule, these files should only be created or modified through the proper git workflow.

## Repository Structure

The cross-project reference repository should have the following structure:

```
/precision_marketing/R_package_references/
├── README.md                  # Main repository documentation
├── DOCUMENTATION_GUIDE.md     # Guide for contributing documentation
├── FUNCTION_TEMPLATE.md       # Template for function documentation
├── INDEX_TEMPLATE.md          # Template for package index files
├── dplyr/                     # Package-specific directory
│   ├── index.md               # Package index
│   ├── filter.md              # Function reference
│   ├── select.md              # Function reference
│   └── ...                    # Additional function references
├── bs4Dash/                   # Package-specific directory
│   ├── index.md               # Package index
│   ├── dashboardPage.md       # Function reference
│   ├── valueBox.md            # Function reference
│   └── ...                    # Additional function references
└── ...                        # Additional package directories
```

## Required Files

### 1. dplyr Function References

#### dplyr/index.md

```markdown
# dplyr Function Reference Index

## Overview
dplyr is a grammar of data manipulation in R, providing a consistent set of verbs that help solve the most common data manipulation challenges.

## Core Data Manipulation Functions

- [`filter()`](filter.md): Subset rows using logical conditions
- [`select()`](select.md): Subset columns by name
- [`mutate()`](mutate.md): Create or transform variables
- [`summarize()`](summarize.md): Reduce multiple values to a single value
- [`arrange()`](arrange.md): Reorder rows
- [`group_by()`](group_by.md): Group data by variables
- [`ungroup()`](ungroup.md): Remove grouping

## Join Functions

- [`inner_join()`](inner_join.md): Keep matching rows in both tables
- [`left_join()`](left_join.md): Keep all rows in left table
- [`right_join()`](right_join.md): Keep all rows in right table
- [`full_join()`](full_join.md): Keep all rows in both tables
- [`anti_join()`](anti_join.md): Keep rows in left table with no matches in right
- [`semi_join()`](semi_join.md): Keep rows in left table with matches in right

## Row Functions

- [`slice()`](slice.md): Select rows by position
- [`slice_head()`](slice_head.md): Select first rows
- [`slice_tail()`](slice_tail.md): Select last rows
- [`slice_min()`](slice_min.md): Select rows with minimum values
- [`slice_max()`](slice_max.md): Select rows with maximum values
- [`slice_sample()`](slice_sample.md): Randomly select rows

## Using This Reference

Each function reference includes:
- Function description and purpose
- Parameter documentation
- Return value information
- Working examples specific to our precision marketing applications
- Common usage patterns in our codebase

## Related Documentation

- [Project-level dplyr documentation](../../precision_marketing_MAMBA/precision_marketing_app/update_scripts/global_scripts/20_R_packages/dplyr.md)
- [Official dplyr documentation](https://dplyr.tidyverse.org/)
```

#### dplyr/filter.md

```markdown
# filter

## Description
Subset rows in a data frame using logical conditions. This is one of the core dplyr functions for data manipulation.

## Usage
```r
filter(.data, ...)
```

## Arguments
| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| .data | data.frame/tibble | Input data frame | Required |
| ... | expressions | Logical conditions to filter by | Required |

## Return Value
A data frame with rows matching the conditions, with the same type as `.data`.

## Minimal Example
```r
library(dplyr)

# Basic filtering with a single condition
mtcars %>% filter(cyl == 6)

# Multiple conditions (combined with AND)
mtcars %>% filter(cyl == 6, mpg > 20)
```

## Common Usage Pattern
```r
# Standard usage in our codebase
customer_data %>%
  filter(
    segment == "high_value",
    transaction_date >= start_date,
    transaction_date <= end_date
  )

# Using OR conditions
product_data %>%
  filter(
    category == "electronics" | 
    category == "computers"
  )

# Using NOT conditions
transaction_data %>%
  filter(
    !is.na(customer_id),
    amount > 0
  )
```

## Notes
- Multiple conditions are combined with AND logic by default
- Use filter(condition1 | condition2) for OR logic
- Use filter() only to subset rows, not to compute new columns (use mutate() for that)
- NAs are treated as FALSE in logical expressions
- Results have the original row order unless reordered
- For better performance with very large datasets, consider using data.table

## Related Functions
- `slice()`: Filter rows by position rather than condition
- `slice_max()`, `slice_min()`: Select rows with highest/lowest values
- `distinct()`: Filter for unique/distinct rows
- `arrange()`: Sort rows but don't filter
- `select()`: Subset columns rather than rows
```

#### dplyr/select.md

```markdown
# select

## Description
Subset columns in a data frame by name, position, or other criteria using helper functions. This is one of the core dplyr functions for data manipulation.

## Usage
```r
select(.data, ...)
```

## Arguments
| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| .data | data.frame/tibble | Input data frame | Required |
| ... | expressions | Column selection expressions | Required |

## Return Value
A data frame with only the selected columns, with the same type as `.data`.

## Minimal Example
```r
library(dplyr)

# Select columns by name
mtcars %>% select(mpg, cyl, disp)

# Select all columns except specific ones
mtcars %>% select(-hp, -wt)
```

## Common Usage Pattern
```r
# Use helper functions to select columns
customer_data %>%
  select(
    # Keep ID columns
    customer_id, 
    # Select columns containing "date"
    contains("date"),
    # Select columns starting with "transaction"
    starts_with("transaction_"),
    # Select columns matching a pattern
    matches("^amount_"),
    # Everything else
    everything()
  )

# Reorder columns for display
transaction_data %>%
  select(
    transaction_id, customer_id, 
    transaction_date, transaction_amount,
    everything()
  )
```

## Notes
- Column order in the result matches the order of selection
- Use select_if() to select columns based on predicates
- Use across() with select() to transform multiple columns
- Supports positive and negative selection (using - prefix)
- Use everything() to include all remaining columns
- Helper functions include: contains(), starts_with(), ends_with(), matches(), num_range()

## Related Functions
- `rename()`: Rename columns without dropping any
- `relocate()`: Change column positions without dropping any
- `pull()`: Extract a single column as a vector
- `filter()`: Subset rows rather than columns
```

### 2. bs4Dash Function References

#### bs4Dash/index.md

```markdown
# bs4Dash Function Reference Index

## Overview
bs4Dash is a Bootstrap 4 implementation of the AdminLTE theme for Shiny dashboards. It provides a modern, responsive dashboard framework with rich UI components.

## Layout Components

- [`dashboardPage()`](dashboardPage.md): Main container for the dashboard
- [`dashboardHeader()`](dashboardHeader.md): Top navigation bar
- [`dashboardSidebar()`](dashboardSidebar.md): Left navigation panel
- [`dashboardBody()`](dashboardBody.md): Main content area
- [`dashboardControlbar()`](dashboardControlbar.md): Right sidebar control panel
- [`dashboardFooter()`](dashboardFooter.md): Bottom footer area

## Navigation Components

- [`sidebarMenu()`](sidebarMenu.md): Creates a sidebar menu
- [`menuproduct()`](menuproduct.md): Creates a menu product in the sidebar
- [`tabproducts()`](tabproducts.md): Container for tab content
- [`tabproduct()`](tabproduct.md): Individual tab content

## Content Components

- [`box()`](box.md): Collapsible content container
- [`tabBox()`](tabBox.md): Tabbed content container
- [`valueBox()`](valueBox.md): Metric display box
- [`infoBox()`](infoBox.md): Information display box
- [`card()`](card.md): Card component
- [`cardDeck()`](cardDeck.md): Group of cards with equal height

## Form Components

- [`actionButton()`](actionButton.md): BS4 styled action button
- [`switchInput()`](switchInput.md): Toggle switch input
- [`pickerInput()`](pickerInput.md): Select picker input

## Using This Reference

Each function reference includes:
- Function description and purpose
- Parameter documentation
- Return value information
- Working examples specific to our precision marketing applications
- Common usage patterns in our codebase

## Related Documentation

- [Project-level documentation](../../precision_marketing_MAMBA/precision_marketing_app/update_scripts/global_scripts/20_R_packages/bs4Dash.md)
- [Official documentation](https://rinterface.github.io/bs4Dash/)
```

#### bs4Dash/valueBox.md

```markdown
# valueBox

## Description
Creates a value box to display important metrics or KPIs with an icon. Value boxes are designed to highlight key statistics in a dashboard interface.

## Usage
```r
valueBox(
  value,
  subtitle,
  icon = NULL,
  color = "primary",
  width = 4,
  href = NULL,
  footer = NULL,
  elevation = NULL
)
```

## Arguments
| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| value | character/numeric | The main value to display | Required |
| subtitle | character | Description of the value | Required |
| icon | shiny.tag | Icon to display (created with icon()) | NULL |
| color | character | Color theme: primary, info, success, warning, danger | "primary" |
| width | numeric | Width of the box (1-12) | 4 |
| href | character | Optional URL to link to | NULL |
| footer | character/shiny.tag | Optional footer content | NULL |
| elevation | numeric | Shadow depth (0-5) | NULL |

## Return Value
A bs4Dash value box that can be included in a Shiny UI or rendered with renderValueBox().

## Minimal Example
```r
library(bs4Dash)
library(shiny)

# Basic value box
valueBox(
  value = "1,234",
  subtitle = "Total Customers",
  icon = icon("users"),
  color = "primary"
)
```

## Common Usage Pattern
```r
# Server-side dynamic value box
output$total_customers <- renderValueBox({
  valueBox(
    value = format(customer_count(), big.mark = ","),
    subtitle = "Total Customers",
    icon = icon("users"),
    color = "primary"
  )
})

# Different colors for different metric types
valueBox(
  value = format(revenue(), big.mark = ",", prefix = "$"),
  subtitle = "Total Revenue",
  icon = icon("dollar-sign"),
  color = "success"  # Green for financial metrics
)

valueBox(
  value = paste0(format(conversion_rate(), digits = 1), "%"),
  subtitle = "Conversion Rate",
  icon = icon("percentage"),
  color = "info"  # Blue for percentage metrics
)

# Value box with footer
valueBox(
  value = "85%",
  subtitle = "Customer Satisfaction",
  icon = icon("smile"),
  color = "warning",
  footer = "Based on 120 responses"
)
```

## Notes
- For dynamic value boxes, use valueBoxOutput() and renderValueBox()
- Follow consistent color usage: primary (blue) for counts, success (green) for positive metrics, warning (yellow) for metrics needing attention, danger (red) for negative metrics
- Format numbers appropriately (e.g., use commas as thousand separators, limit decimal places)
- Keep value text short enough to display properly
- Consider using reactive expressions to calculate values efficiently

## Related Functions
- `infoBox()`: Similar to valueBox but with more detailed subtitle area
- `renderValueBox()`: Server-side rendering function for valueBoxOutput()
- `valueBoxOutput()`: UI placeholder for a renderValueBox() output
```

#### bs4Dash/dashboardPage.md

```markdown
# dashboardPage

## Description
Creates the main container for a bs4Dash dashboard application. This is the top-level function that contains all dashboard components.

## Usage
```r
dashboardPage(
  header,
  sidebar,
  body,
  controlbar = NULL,
  footer = NULL,
  title = NULL,
  freshTheme = NULL,
  options = NULL,
  fullscreen = FALSE,
  preloader = NULL,
  dark = FALSE,
  scrollToTop = FALSE,
  help = NULL,
  skin = "blue"
)
```

## Arguments
| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| header | shiny.tag | Header created with dashboardHeader() | Required |
| sidebar | shiny.tag | Sidebar created with dashboardSidebar() | Required |
| body | shiny.tag | Body created with dashboardBody() | Required |
| controlbar | shiny.tag | Optional controlbar created with dashboardControlbar() | NULL |
| footer | shiny.tag | Optional footer created with dashboardFooter() | NULL |
| title | character | Dashboard title shown in browser tab | NULL |
| freshTheme | list | Optional theme created with create_theme() | NULL |
| options | list | Additional options for AdminLTE | NULL |
| fullscreen | logical | Whether the app starts in fullscreen mode | FALSE |
| preloader | list | Loading screen settings (see details) | NULL |
| dark | logical | Whether to use dark mode | FALSE |
| scrollToTop | logical | Whether to show a scroll to top button | FALSE |
| help | list | Help settings (see details) | NULL |
| skin | character | Dashboard color theme | "blue" |

## Return Value
A complete bs4Dash dashboard layout that forms the UI of a Shiny application.

## Minimal Example
```r
library(bs4Dash)
library(shiny)

# Basic dashboard structure
ui <- dashboardPage(
  dashboardHeader(title = "My Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuproduct("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuproduct("Data", tabName = "data", icon = icon("database"))
    )
  ),
  dashboardBody(
    tabproducts(
      tabproduct(tabName = "dashboard", "Dashboard content"),
      tabproduct(tabName = "data", "Data content")
    )
  )
)

# In a Shiny app
server <- function(input, output) {}
shinyApp(ui, server)
```

## Common Usage Pattern
```r
# Dashboard with theme, controlbar, and footer
dashboardPage(
  dashboardHeader(
    title = "Precision Marketing"
  ),
  dashboardSidebar(
    sidebarMenu(
      menuproduct("Overview", tabName = "overview", icon = icon("dashboard")),
      menuproduct("Customers", tabName = "customers", icon = icon("users")),
      menuproduct("Campaigns", tabName = "campaigns", icon = icon("bullhorn"))
    )
  ),
  dashboardBody(
    tabproducts(
      # Tab content goes here
      tabproduct(tabName = "overview", h2("Overview")),
      tabproduct(tabName = "customers", h2("Customers")),
      tabproduct(tabName = "campaigns", h2("Campaigns"))
    )
  ),
  controlbar = dashboardControlbar(
    title = "Filters",
    skin = "light",
    pinned = TRUE,
    collapsed = TRUE,
    div(
      selectInput("filter_date", "Date Range", choices = c("Today", "This Week", "This Month")),
      selectInput("filter_segment", "Segment", choices = c("All", "High Value", "Medium Value"))
    )
  ),
  footer = dashboardFooter(
    left = "Precision Marketing Analytics",
    right = "© 2025"
  ),
  title = "Precision Marketing Dashboard",
  freshTheme = create_theme(
    primary = "#0066CC",
    secondary = "#6C757D",
    success = "#28A745", 
    info = "#17A2B8",
    warning = "#FFC107",
    danger = "#DC3545"
  ),
  dark = FALSE
)
```

## Notes
- Always include header, sidebar, and body components
- Control bar and footer are optional but recommended for professional dashboards
- Use freshTheme for consistent branding across the application
- Set preloader for better user experience during loading
- Ensure all tabName values in menuproduct match corresponding tabproduct components
- Set dark=TRUE carefully as it affects all dashboard components

## Related Functions
- `dashboardHeader()`: Creates the dashboard header
- `dashboardSidebar()`: Creates the dashboard sidebar
- `dashboardBody()`: Creates the dashboard body
- `dashboardControlbar()`: Creates the right sidebar controlbar
- `dashboardFooter()`: Creates the dashboard footer
- `create_theme()`: Creates a custom theme for the dashboard
```

## Required Documentation Structure

For each package that needs documentation in the cross-project reference repository, the following structure should be created through proper git workflow:

1. **Package Directory**: Create a directory with the package name
2. **Index File**: Create an index.md file listing all documented functions
3. **Function Files**: Create individual markdown files for each function

Each function file should follow the template structure:
- Function name as title
- Description section
- Usage section with function signature
- Arguments table
- Return value description
- Minimal example
- Common usage patterns
- Notes section
- Related functions

## Documentation Process

When adding new package documentation to the cross-project repository:

1. Clone the repository
2. Create a new branch
3. Add the package directory and files
4. Commit and push
5. Create a pull request
6. After approval, merge to main

## Function Documentation Priority

When documenting packages, prioritize functions in this order:

1. Most commonly used functions
2. Functions with complex parameters or usage patterns
3. Functions specific to precision marketing workflows
4. Helper or utility functions

## Example File References in Code

When referencing function documentation in code files:

```r
#' @file customer_analysis.R
#' @principle R104 Package Function Reference Rule
#' @uses_function dplyr::filter See /precision_marketing/R_package_references/dplyr/filter.md
#' @uses_function dplyr::select See /precision_marketing/R_package_references/dplyr/select.md
#' @uses_function bs4Dash::valueBox See /precision_marketing/R_package_references/bs4Dash/valueBox.md
```

## Related Documents and Rules

- **MP57**: Package Documentation Meta-Principle (Overall documentation approach)
- **R103**: Package Documentation Reference Rule (Project documentation references)
- **R104**: Package Function Reference Rule (Function documentation with examples)
- **RC04**: Package Documentation Reference Code (Templates for project-specific docs)