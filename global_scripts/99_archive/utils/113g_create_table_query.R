#' @file fn_generate_create_table_query.R
#' @principle MP058 Database Table Creation Strategy
#' @principle R092 Universal DBI Approach
#' @principle R067 Functional Encapsulation
#' @author Claude
#' @date 2025-04-15
#' @modified 2025-04-15
#' @related_to fn_initialize_app_database.R

#' Generate CREATE TABLE SQL Query from Existing Table
#'
#' Creates a SQL query to replicate the schema of an existing table.
#' This implements the fixed schema strategy from MP058, ensuring
#' explicit table definitions with proper column types and formatting.
#'
#' @param con Database connection object (DBI-compatible)
#' @param source_table Name of the source table to extract schema from
#' @param target_table Name of the target table to create
#' @param add_indexes Logical, whether to add indexes on primary keys (defaults to TRUE)
#' @return Formatted SQL CREATE TABLE query string
#' @export
#'
#' @examples
#' # Generate create table query
#' con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
#' DBI::dbExecute(con, "CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT)")
#' query <- generate_create_table_query(con, "test", "test_copy")
#' cat(query)
#' DBI::dbDisconnect(con)
#'
#' VALIDATION {
#'   REQUIRE: inherits(con, "DBIConnection")
#'   REQUIRE: is.character(source_table) && length(source_table) == 1
#'   REQUIRE: is.character(target_table) && length(target_table) == 1
#'   REQUIRE: is.logical(add_indexes)
#' }
#'
generate_create_table_query <- function(con, source_table, target_table, add_indexes = TRUE) {
  # Validate inputs
  if (!inherits(con, "DBIConnection")) {
    stop("Connection must be a DBI connection object")
  }
  if (!is.character(source_table) || length(source_table) != 1) {
    stop("source_table must be a single character string")
  }
  if (!is.character(target_table) || length(target_table) != 1) {
    stop("target_table must be a single character string")
  }
  
  # Get table structure information using DBI standard approach
  table_info <- DBI::dbGetQuery(con, paste0("PRAGMA table_info('", source_table, "');"))
  
  # Check if table exists
  if (nrow(table_info) == 0) {
    stop("Source table '", source_table, "' does not exist")
  }
  
  # Extract column names, types, and constraints
  columns <- table_info$name
  types <- table_info$type
  not_null <- table_info$notnull
  primary_key <- table_info$pk
  
  # Build column definitions
  column_defs <- character(length(columns))
  primary_keys <- character()
  
  for (i in seq_along(columns)) {
    # Format column definition with constraints
    col_def <- paste0(columns[i], " ", types[i])
    
    # Add NOT NULL constraint if applicable
    if (not_null[i] == 1) {
      col_def <- paste0(col_def, " NOT NULL")
    }
    
    # Check for primary key
    if (primary_key[i] > 0) {
      col_def <- paste0(col_def, " PRIMARY KEY")
      primary_keys <- c(primary_keys, columns[i])
    }
    
    column_defs[i] <- col_def
  }
  
  # Generate CREATE TABLE statement with proper formatting
  create_table_query <- paste0(
    "CREATE TABLE ", target_table, " (\n  ",
    paste(column_defs, collapse = ",\n  "),
    "\n);"
  )
  
  # Add index creation statements if requested
  index_queries <- character()
  if (add_indexes && length(primary_keys) > 0) {
    for (key in primary_keys) {
      index_name <- paste0("idx_", target_table, "_", key)
      index_query <- paste0(
        "\n\nCREATE INDEX IF NOT EXISTS ", index_name, 
        " ON ", target_table, "(", key, ");"
      )
      index_queries <- c(index_queries, index_query)
    }
  }
  
  # Combine CREATE TABLE with any INDEX statements
  formatted_query <- paste0(create_table_query, paste(index_queries, collapse = ""))
  
  return(formatted_query)
}