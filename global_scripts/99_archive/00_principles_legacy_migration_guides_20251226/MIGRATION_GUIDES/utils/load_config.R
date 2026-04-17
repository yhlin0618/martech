# load_config.R - Load project configuration in R
#
# This module provides functions to automatically detect and load
# project configuration from project_config.yaml files.
#
# Usage:
#   source("path/to/load_config.R")
#   config <- load_project_config()
#   print(config$project$name)
#
# Functions:
#   detect_project()           - Find project root by looking for config
#   load_project_config()      - Load and parse configuration
#   get_project_name()         - Get current project name
#   get_project_type()         - Get current project type
#   get_project_entities()     - Get project entities (companies/labs/tools)
#   get_principle_path()       - Get path to principles (core or local)
#
# Global Options Set:
#   project_config             - Full config object
#   project_root               - Project root path
#   project_name               - Project name
#   project_type               - Project type

# Required packages
if (!require("yaml", quietly = TRUE)) {
  stop("Package 'yaml' is required. Install with: install.packages('yaml')")
}

# Detect project root by walking up directory tree
detect_project <- function(start_dir = getwd(), max_depth = 10) {
  current_dir <- normalizePath(start_dir, mustWork = FALSE)
  depth <- 0

  while (current_dir != dirname(current_dir) && depth < max_depth) {
    config_path <- file.path(current_dir, "project_config.yaml")

    if (file.exists(config_path)) {
      return(list(
        root = current_dir,
        config_path = config_path
      ))
    }

    current_dir <- dirname(current_dir)
    depth <- depth + 1
  }

  stop(
    "No project_config.yaml found in parent directories\n",
    "  Started from: ", start_dir, "\n",
    "  Searched ", depth, " levels up\n",
    "  Make sure you are within a project directory"
  )
}

# Resolve environment variables in paths
resolve_env_vars <- function(path) {
  if (is.null(path) || !is.character(path)) {
    return(path)
  }

  # Replace ${VAR} with Sys.getenv("VAR")
  pattern <- "\\$\\{([^}]+)\\}"

  while (grepl(pattern, path)) {
    matches <- regmatches(path, regexpr(pattern, path))

    if (length(matches) > 0) {
      var_name <- sub("^\\$\\{(.+)\\}$", "\\1", matches[1])
      var_value <- Sys.getenv(var_name, unset = "")

      if (var_value == "") {
        warning(
          "Environment variable ${", var_name, "} not set, using empty string",
          call. = FALSE
        )
      }

      path <- sub(
        paste0("\\$\\{", var_name, "\\}"),
        var_value,
        path,
        fixed = FALSE
      )
    } else {
      break
    }
  }

  return(path)
}

# Recursively resolve environment variables in nested lists
resolve_env_vars_recursive <- function(obj) {
  if (is.list(obj)) {
    lapply(obj, resolve_env_vars_recursive)
  } else if (is.character(obj)) {
    resolve_env_vars(obj)
  } else {
    obj
  }
}

# Load project configuration
load_project_config <- function(config_path = NULL, verbose = TRUE) {
  # Auto-detect if not provided
  if (is.null(config_path)) {
    project_info <- detect_project()
    config_path <- project_info$config_path

    if (verbose) {
      message("Detected project at: ", dirname(config_path))
    }
  }

  # Validate config file exists
  if (!file.exists(config_path)) {
    stop("Configuration file not found: ", config_path)
  }

  if (verbose) {
    message("Loading configuration from: ", config_path)
  }

  # Read YAML configuration
  config <- tryCatch(
    {
      yaml::read_yaml(config_path)
    },
    error = function(e) {
      stop(
        "Failed to parse configuration file: ", config_path, "\n",
        "  Error: ", conditionMessage(e)
      )
    }
  )

  # Validate required fields
  if (is.null(config$project$name)) {
    stop("Invalid configuration: project.name is not set")
  }

  # Resolve environment variables in all paths
  config <- resolve_env_vars_recursive(config)

  # Add computed paths
  config$project$root <- dirname(config_path)
  config$project$config_path <- config_path

  # Compute absolute paths for principles
  if (!is.null(config$project$principles$core_path)) {
    config$project$principles_core_full <- normalizePath(
      file.path(config$project$root, config$project$principles$core_path),
      mustWork = FALSE
    )
  }

  if (!is.null(config$project$principles$local_path)) {
    config$project$principles_local_full <- normalizePath(
      file.path(config$project$root, config$project$principles$local_path),
      mustWork = FALSE
    )
  }

  # Verify principles directories
  if (!is.null(config$project$principles_core_full)) {
    if (!dir.exists(config$project$principles_core_full)) {
      warning(
        "Core principles directory not found: ",
        config$project$principles_core_full, "\n",
        "  You may need to run: git subrepo pull ",
        config$project$principles$core_path,
        call. = FALSE
      )
    }
  }

  if (!is.null(config$project$principles_local_full)) {
    if (!dir.exists(config$project$principles_local_full)) {
      warning(
        "Local principles directory not found: ",
        config$project$principles_local_full, "\n",
        "  Creating directory...",
        call. = FALSE
      )
      dir.create(
        config$project$principles_local_full,
        recursive = TRUE,
        showWarnings = FALSE
      )
    }
  }

  # Set global options for easy access
  options(
    project_config = config,
    project_root = config$project$root,
    project_name = config$project$name,
    project_type = config$project$type %||% "unknown"
  )

  if (verbose) {
    message("Configuration loaded successfully!")
    message("  Project: ", config$project$name, " (", config$project$type, ")")
  }

  return(invisible(config))
}

# Null-coalescing operator
`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}

# Get current project name
get_project_name <- function() {
  config <- getOption("project_config")

  if (is.null(config)) {
    config <- load_project_config(verbose = FALSE)
  }

  return(config$project$name)
}

# Get current project type
get_project_type <- function() {
  config <- getOption("project_config")

  if (is.null(config)) {
    config <- load_project_config(verbose = FALSE)
  }

  return(config$project$type %||% "unknown")
}

# Get project root directory
get_project_root <- function() {
  config <- getOption("project_config")

  if (is.null(config)) {
    config <- load_project_config(verbose = FALSE)
  }

  return(config$project$root)
}

# Get project entities (companies/labs/tools)
get_project_entities <- function(active_only = TRUE) {
  config <- getOption("project_config")

  if (is.null(config)) {
    config <- load_project_config(verbose = FALSE)
  }

  entities <- config$project$entities$list

  if (active_only && !is.null(entities)) {
    entities <- Filter(function(e) isTRUE(e$active), entities)
  }

  return(entities)
}

# Get entity names as character vector
get_entity_names <- function(active_only = TRUE) {
  entities <- get_project_entities(active_only = active_only)

  if (is.null(entities) || length(entities) == 0) {
    return(character(0))
  }

  vapply(entities, function(e) e$name, character(1))
}

# Get entity codes as character vector
get_entity_codes <- function(active_only = TRUE) {
  entities <- get_project_entities(active_only = active_only)

  if (is.null(entities) || length(entities) == 0) {
    return(character(0))
  }

  vapply(entities, function(e) e$code, character(1))
}

# Get path to principles directory
get_principle_path <- function(type = c("core", "local")) {
  type <- match.arg(type)

  config <- getOption("project_config")

  if (is.null(config)) {
    config <- load_project_config(verbose = FALSE)
  }

  path <- if (type == "core") {
    config$project$principles_core_full
  } else {
    config$project$principles_local_full
  }

  if (is.null(path)) {
    stop("Principle path not configured for type: ", type)
  }

  return(path)
}

# Get project parameter by name
get_parameter <- function(param_name, default = NULL) {
  config <- getOption("project_config")

  if (is.null(config)) {
    config <- load_project_config(verbose = FALSE)
  }

  # Split parameter name by dots for nested access
  parts <- strsplit(param_name, ".", fixed = TRUE)[[1]]

  value <- config$parameters
  for (part in parts) {
    if (is.null(value) || !is.list(value)) {
      return(default)
    }
    value <- value[[part]]
  }

  return(value %||% default)
}

# Check if environment variable is set
check_env_var <- function(var_name, required = TRUE) {
  value <- Sys.getenv(var_name, unset = "")

  if (value == "" && required) {
    stop("Required environment variable not set: ", var_name)
  }

  return(value)
}

# Validate all required environment variables
validate_environment <- function() {
  config <- getOption("project_config")

  if (is.null(config)) {
    config <- load_project_config(verbose = FALSE)
  }

  required_vars <- config$environment$required_vars

  if (!is.null(required_vars) && length(required_vars) > 0) {
    missing_vars <- character(0)

    for (var_name in required_vars) {
      if (Sys.getenv(var_name, unset = "") == "") {
        missing_vars <- c(missing_vars, var_name)
      }
    }

    if (length(missing_vars) > 0) {
      stop(
        "Missing required environment variables:\n  ",
        paste(missing_vars, collapse = "\n  ")
      )
    }
  }

  return(invisible(TRUE))
}

# Print project configuration summary
print_project_info <- function() {
  config <- getOption("project_config")

  if (is.null(config)) {
    config <- load_project_config(verbose = FALSE)
  }

  cat("\nProject Configuration\n")
  cat("=====================\n\n")

  cat("Name:         ", config$project$name, "\n")
  cat("Type:         ", config$project$type %||% "unknown", "\n")
  cat("Owner:        ", config$project$owner %||% "unknown", "\n")
  cat("Root:         ", config$project$root, "\n")

  cat("\nPrinciples:\n")
  cat("  Core:       ", config$project$principles_core_full, "\n")
  cat("  Local:      ", config$project$principles_local_full, "\n")

  entities <- get_project_entities()
  if (!is.null(entities) && length(entities) > 0) {
    cat("\nEntities (", config$project$entities$type, "):\n", sep = "")
    for (entity in entities) {
      status <- if (isTRUE(entity$active)) "active" else "inactive"
      cat("  - ", entity$name, " (", entity$code, ") [", status, "]\n", sep = "")
    }
  }

  cat("\n")
  invisible(config)
}

# Example usage (commented out)
# config <- load_project_config()
# print_project_info()
# entities <- get_project_entities()
# project_name <- get_project_name()
