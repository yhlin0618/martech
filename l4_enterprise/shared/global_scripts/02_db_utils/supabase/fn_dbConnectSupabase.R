#' Connect to Supabase PostgreSQL Database
#'
#' @description
#' Establishes a connection to Supabase PostgreSQL database for deployment.
#' Uses environment variables for secure credential management.
#'
#' @param host Character. Supabase database host. Default: from SUPABASE_DB_HOST env var
#' @param port Character. Database port. Default: "5432"
#' @param dbname Character. Database name. Default: "postgres"
#' @param user Character. Database user. Default: "postgres"
#' @param password Character. Database password. Default: from SUPABASE_DB_PASSWORD env var
#' @param verbose Logical. Print connection status messages. Default: TRUE
#'
#' @return DBI connection object to Supabase PostgreSQL
#'
#' @details
#' Required environment variables:
#'   - SUPABASE_DB_HOST: Database host (e.g., db.xxxxx.supabase.co)
#'   - SUPABASE_DB_PASSWORD: Database password
#'
#' Optional environment variables:
#'   - SUPABASE_DB_PORT: Default "5432"
#'   - SUPABASE_DB_NAME: Default "postgres"
#'   - SUPABASE_DB_USER: Default "postgres"
#'
#' If `SUPABASE_DB_HOST` / `SUPABASE_DB_PASSWORD` are unset, falls back to
#' `PGHOST` / `PGPASSWORD` (and `PGPORT`, `PGDATABASE`, `PGUSER`) for Posit
#' Connect and standard libpq tooling.
#'
#' Following Principles:
#'   - SEC_R001: Credential Management (no hardcoded credentials)
#'   - DM_R023: Universal DBI Approach
#'   - SO_R007: One Function One File
#'
#' @export
#' @importFrom DBI dbConnect
#' @use_package DBI
#' @use_package RPostgres

dbConnectSupabase <- function(
    host = NULL,
    port = NULL,
    dbname = NULL,
    user = NULL,
    password = NULL,
    verbose = TRUE
) {
  # Ensure RPostgres is available (must be pre-installed via manifest.json)
  if (!requireNamespace("RPostgres", quietly = TRUE)) {
    stop(
      "RPostgres package is not available!\n",
      "This package must be pre-installed in the deployment environment.\n",
      "Add library(RPostgres) to app.R to include it in manifest.json."
    )
  }

  # Get connection parameters from environment variables if not provided
  host <- trimws(host %||% "")
  if (!nzchar(host)) host <- trimws(Sys.getenv("SUPABASE_DB_HOST", ""))
  if (!nzchar(host)) host <- trimws(Sys.getenv("PGHOST", ""))

  port <- port %||% ""
  if (!nzchar(port)) port <- Sys.getenv("SUPABASE_DB_PORT", "")
  if (!nzchar(port)) port <- Sys.getenv("PGPORT", "5432")
  if (!nzchar(port)) port <- "5432"

  dbname <- dbname %||% ""
  if (!nzchar(dbname)) dbname <- Sys.getenv("SUPABASE_DB_NAME", "")
  if (!nzchar(dbname)) dbname <- Sys.getenv("PGDATABASE", "postgres")
  dbname <- trimws(dbname)
  if (!nzchar(dbname)) {
    dbname <- "postgres"
  }
  # Supabase 託管：有效 database 名稱為 postgres（Posit Variables 常誤填專案 ref）
  supabase_url <- trimws(Sys.getenv("SUPABASE_URL", ""))
  if (grepl("supabase", host, ignore.case = TRUE) ||
      (nzchar(supabase_url) && grepl("supabase", supabase_url, ignore.case = TRUE))) {
    dbname <- "postgres"
  }
  user <- user %||% ""
  if (!nzchar(user)) user <- Sys.getenv("SUPABASE_DB_USER", "")
  if (!nzchar(user)) user <- Sys.getenv("PGUSER", "postgres")
  if (!nzchar(user)) user <- "postgres"

  password <- password %||% ""
  if (!nzchar(password)) password <- Sys.getenv("SUPABASE_DB_PASSWORD", "")
  if (!nzchar(password)) password <- Sys.getenv("PGPASSWORD", "")

  # Validate required parameters
  if (host == "") {
    stop(
      "Database host not configured!\n",
      "Set SUPABASE_DB_HOST or PGHOST (or pass 'host').\n",
      "Example: aws-0-....pooler.supabase.com or db.xxxxx.supabase.co"
    )
  }

  if (password == "") {
    stop(
      "Database password not configured!\n",
      "Set SUPABASE_DB_PASSWORD or PGPASSWORD (or pass 'password')."
    )
  }

  if (verbose) {
    message("Connecting to Supabase PostgreSQL...")
    message("  Host: ", host)
    message("  Port: ", port)
    message("  Database: ", dbname)
    message("  User: ", user)
  }

  # Establish connection with SSL
  tryCatch({
    con <- DBI::dbConnect(
      RPostgres::Postgres(),
      host = host,
      port = as.integer(port),
      dbname = dbname,
      user = user,
      password = password,
      sslmode = "require"
    )

    # Add connection metadata
    attr(con, "connection_type") <- "supabase_postgres"
    attr(con, "connection_time") <- Sys.time()
    attr(con, "supabase_host") <- host

    if (verbose) {
      message("Successfully connected to Supabase PostgreSQL")
    }

    return(con)

  }, error = function(e) {
    stop(
      "Failed to connect to Supabase:\n",
      "  Error: ", e$message, "\n\n",
      "Troubleshooting:\n",
      "  1. Verify SUPABASE_DB_HOST is correct\n",
      "  2. Check SUPABASE_DB_PASSWORD is valid\n",
      "  3. Ensure your IP is allowed in Supabase Dashboard\n",
      "  4. Verify the database is not paused"
    )
  })
}

# Null coalescing operator (if not already defined)
`%||%` <- function(x, y) if (is.null(x) || x == "") y else x
