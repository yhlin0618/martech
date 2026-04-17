#' Read YAML Configuration [DEPRECATED]
#'
#' DEPRECATED: This function has been archived and replaced by load_app_config in 04_utils.
#' Please use load_app_config instead as it provides more comprehensive functionality.
#' 
#' This utility function reads a YAML configuration file and returns its contents 
#' as an R list. It checks if the yaml package is available and falls back to a 
#' simulated configuration if needed.
#'
#' @param yaml_file Either the full path to the YAML file or just the filename
#' @param base_path Base path to prepend to yaml_file (default: NULL, meaning yaml_file is the full path)
#'
#' @return The configuration as an R list
#' @export
#'
#' @examples
#' # Read configuration from a file in the app_configs directory
#' config <- readYamlConfig("customer_dna_app.yaml", "app_configs")
#' 
#' # Read configuration using full path
#' config <- readYamlConfig("app_config.yaml")
readYamlConfig <- function(yaml_file, base_path = NULL) {
  # Determine the yaml path
  if (is.null(base_path)) {
    # If base_path is NULL, assume yaml_file is the full path
    yaml_path <- yaml_file
  } else {
    # Construct the full path to the YAML file
    yaml_path <- file.path(base_path, yaml_file)
  }
  
  # Validate that the file exists
  if (!file.exists(yaml_path)) {
    warning("Configuration file not found: ", yaml_path)
    return(list())
  }
  
  message("Loading configuration from: ", yaml_path)
  
  # Check if yaml package is available
  if (requireNamespace("yaml", quietly = TRUE)) {
    tryCatch({
      # Use yaml package to read the file
      config <- yaml::read_yaml(yaml_path)
      return(config)
    }, error = function(e) {
      warning("Error reading YAML file: ", e$message, 
              ". Falling back to default configuration.")
    })
  } else {
    message("yaml package not available; using hardcoded configuration.")
  }
  
  # If yaml package is not available or there was an error, 
  # provide a simulated configuration matching the file format
  list(
    title = "AI行銷科技平台",
    theme = list(
      version = 5,
      bootswatch = "cosmo"
    ),
    layout = "navbar",
    
    components = list(
      macro = list(
        overview = "sales_summary_view",
        trends = list(
          data_source = "sales_trends",
          parameters = list(
            show_kpi = TRUE,
            refresh_interval = 300
          )
        )
      ),
      
      micro = list(
        customer_profile = list(
          primary = "customer_details",
          preferences = "customer_preferences",
          history = "customer_history"
        ),
        transactions = "transaction_history"
      ),
      
      target = list(
        segmentation = c("customer_segments", "segment_definitions", "segment_metrics"),
        advanced_segmentation = list(
          primary = "customer_segments",
          reference = "segment_definitions",
          parameters = list(
            visualization_type = "tree",
            max_depth = 3
          )
        )
      )
    ),
    
    environments = list(
      development = list(
        data_source = "development_data/",
        parameters = list(
          debug = TRUE
        )
      ),
      production = list(
        data_source = "app_data/",
        parameters = list(
          debug = FALSE
        )
      )
    )
  )
}