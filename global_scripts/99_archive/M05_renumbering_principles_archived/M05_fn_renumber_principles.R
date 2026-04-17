#' Renumbering Principles Module - Main Function
#'
#' @description
#' This is the main entry point for the M05_renumbering_principles module.
#' It loads all the component functions and provides a unified interface.
#'
#' @author Claude
#' @date 2025-04-04

# Create the module namespace
M05_renumbering_principles <- new.env()

# Source all function files
function_dir <- file.path(dirname(sys.frame(1)$ofile), "functions")
function_files <- list.files(function_dir, pattern = "\\.R$", full.names = TRUE)

for (file in function_files) {
  source(file, local = M05_renumbering_principles)
}

#' Rename a resource
#'
#' @param old_name The current name of the resource
#' @param new_name The new name for the resource
#' @param update_refs Whether to automatically update references (default: TRUE)
#' @return A list with success status and details
#'
M05_renumbering_principles$rename <- function(old_name, new_name, update_refs = TRUE) {
  # Call the actual implementation
  M05_renumbering_principles$rename_resource(old_name, new_name, update_refs)
}

#' Renumber a sequenced resource (MP, P, R)
#'
#' @param old_id The current id (e.g., "P16")
#' @param new_id The new id (e.g., "P07")
#' @param name The name part of the resource (e.g., "app_bottom_up_construction")
#' @return A list with success status and details
#'
M05_renumbering_principles$renumber <- function(old_id, new_id, name) {
  # Call the actual implementation
  M05_renumbering_principles$renumber_resource(old_id, new_id, name)
}

#' Batch renumber multiple resources
#'
#' @param mapping_table A data frame with old_id, new_id, and name columns
#' @return A list with success status and details for each operation
#'
M05_renumbering_principles$batch_renumber <- function(mapping_table) {
  # Call the actual implementation
  M05_renumbering_principles$batch_renumber_resources(mapping_table)
}

#' Verify system consistency
#'
#' @return NULL if consistent, or a list of issues if inconsistent
#'
M05_renumbering_principles$verify <- function() {
  # Call the actual implementation
  M05_renumbering_principles$verify_consistency()
}

# Export the module
M05_renumbering_principles