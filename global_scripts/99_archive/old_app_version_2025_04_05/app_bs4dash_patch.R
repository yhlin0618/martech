# Script to update app_bs4dash_prototype.R to use centralized translation
# This removes the duplicate translation code and uses the centralized implementation

# Find the app file
app_file <- "app_bs4dash_prototype.R"

# Check if the file exists
if (!file.exists(app_file)) {
  stop("App file not found: ", app_file)
}

# Read the content of the app file
app_content <- readLines(app_file)

# Find the boundaries of the translation section
start_line <- grep("# Load translation dictionary", app_content)
end_line <- grep("# Create simple versions", app_content) - 1

if (length(start_line) == 0 || length(end_line) == 0 || start_line >= end_line) {
  stop("Could not find translation section in the app file")
}

# Create the replacement text
replacement_text <- c(
  "# Translation and locale handling is now done in fn_load_app_config.R",
  "# following R34_ui_text_standardization and R36_available_locales rules",
  "",
  "# Print some diagnostic information",
  "message(\"Language setting from config: \", config$brand$language)",
  "if (exists(\"available_locales\")) {",
  "  message(\"Available locales: \", paste(available_locales, collapse = \", \"))",
  "}",
  "if (exists(\"ui_dictionary\")) {",
  "  message(\"Translation dictionary loaded with \", length(ui_dictionary), \" entries\")",
  "} else {",
  "  message(\"Warning: No translation dictionary loaded\")",
  "}",
  "",
  "# Create fallback translation function if it doesn't exist (should never happen if initialization worked)",
  "if (!exists(\"translate\")) {",
  "  translate <- function(text) { text }",
  "  message(\"Warning: Translation function not available, using default text\")",
  "}"
)

# Create the updated content
updated_content <- c(
  app_content[1:(start_line-1)],
  replacement_text,
  app_content[(end_line+1):length(app_content)]
)

# Write the updated app file
writeLines(updated_content, app_file)

message("Successfully updated app_bs4dash_prototype.R to use centralized translation")