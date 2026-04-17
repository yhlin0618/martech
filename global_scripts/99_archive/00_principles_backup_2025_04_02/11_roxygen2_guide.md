# Working with Roxygen2 Documentation

This guide explains how to read, write, and generate documentation using roxygen2 in R.

## 1. Reading Roxygen2 Documentation

### In R Source Files

Roxygen2 comments are lines that start with `#'` and appear directly before function definitions. They contain:

- General description (first paragraph)
- Detailed information (subsequent paragraphs)
- Tags like `@param`, `@return`, `@examples` that document specific aspects

Example:
```r
#' Add two numbers together
#'
#' This function adds two numbers and returns the result.
#'
#' @param x Numeric. First number to add
#' @param y Numeric. Second number to add
#'
#' @return Numeric. The sum of x and y
#'
#' @examples
#' add(2, 3)  # Returns 5
add <- function(x, y) {
  return(x + y)
}
```

### In R Help System

Once documentation is generated, you can read it using:

```r
?function_name   # Example: ?dbConnect_from_list
help(function_name)
```

## 2. Writing Roxygen2 Documentation

### Basic Structure

1. Start each line with `#'`
2. Begin with a title (first line)
3. Leave a blank line, then add a description
4. Add tags for specific documentation elements

### Common Tags

- `@param [name] [description]` - Document function parameters
- `@return` - Describe what the function returns
- `@examples` - Provide usage examples
- `@details` - Add detailed information
- `@note` - Add notes or warnings
- `@author` - Specify function author
- `@seealso` - Reference related functions
- `@export` - Mark function to be exported in package
- `@importFrom [package] [function]` - Document dependencies

### Special Formatting

- Use backticks for inline code: \`variable\`
- Use indentation for code blocks after @examples
- Use markdown for formatting:
  - *italics* or _italics_
  - **bold** or __bold__
  - Lists with - or * characters

## 3. Generating Documentation

### Using devtools (in a package)

```r
# Install required packages if needed
install.packages("devtools")
install.packages("roxygen2")

# Generate documentation
library(devtools)
document()  # Process roxygen comments and update man/ directory
```

### Without devtools (for standalone scripts)

For standalone scripts like ours, roxygen2 comments serve as in-file documentation. While you can't directly generate help files outside a package structure, you can:

1. Create a lightweight package structure to generate documentation
2. Use custom tools to extract roxygen comments
3. Use RStudio's code folding and navigation features (which recognize roxygen blocks)

## 4. Best Practices

1. **Be consistent** - Maintain the same documentation style across all functions
2. **Document parameters thoroughly** - Include type information and constraints
3. **Provide examples** - Show how the function is meant to be used
4. **Clarify return values** - What does the function return in different scenarios?
5. **Document side effects** - If the function modifies global state, note this clearly
6. **Keep updated** - Update documentation when you change function behavior

## 5. Using in Our Project

Since we're not building a formal R package, roxygen2-style comments primarily serve as:

1. **In-file documentation** - Makes code more understandable
2. **Standardized format** - Provides consistent documentation structure
3. **Future-proofing** - Makes it easier to convert to a package later if needed
4. **IDE integration** - Works well with RStudio features for code navigation

View the documentation directly in the source files or display function help using the standard R help commands if you set up a package structure.