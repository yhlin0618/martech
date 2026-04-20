#' Load Product Line Data into Database and Memory
#'
#' Reads `df_product_line` from the canonical source (`meta_data.duckdb`) and
#' caches it in the provided SQLite connection as `df_product_line_profile`.
#' Follows R119 Memory-Resident Parameters Rule.
#'
#' As of DM_R054 v2.1 (2026-04-19), `meta_data.duckdb` is the primary runtime
#' source. DM_R054 v2.1.1 adds: when that file is absent (e.g. Posit Connect +
#' Supabase), rows are read from PostgreSQL table `df_product_line_profile` via
#' [dbConnectAppData()]. There is NO CSV runtime fallback: the CSV at
#' `data/app_data/parameters/scd_type1/df_product_line.csv` is a bootstrap seed
#' consumed ONLY by the producer ETL (`all_ETL_meta_init_0IM.R`).
#'
#' @param conn A DBI connection object (typically SQLite) to store the
#'   `df_product_line_profile` table for the app's in-memory lookup.
#' @param meta_data_path Absolute path to `meta_data.duckdb`. Defaults to
#'   `db_path_list$meta_data` if available; otherwise `NULL`, which will
#'   trigger `stop()` — APP_MODE autoinit() is required to populate this path
#'   (DM_R054 v2.1 Section 8).
#' @param csv_path Deprecated / reserved. Accepted for signature compatibility
#'   but NOT consulted for fallback; any non-NULL value is logged for audit and
#'   the function still routes through `meta_data.duckdb`.
#'
#' @return Invisibly returns the product_lines data frame.
#'
#' @examples
#' \dontrun{
#' conn <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
#' product_lines <- load_product_lines(
#'   conn,
#'   meta_data_path = db_path_list$meta_data
#' )
#' }
#'
#' @export
load_product_lines <- function(
  conn,
  meta_data_path = if (exists("db_path_list") && !is.null(db_path_list$meta_data))
                   db_path_list$meta_data else NULL,
  csv_path = NULL
) {
  # DM_R054 v2.1 / v2.1.1 — DuckDB primary; Supabase profile table when absent.
  actionable <- paste0(
    "Cannot load product lines — need meta_data.duckdb OR Supabase df_product_line_profile (DM_R054 v2.1.1).\n",
    "  path checked: ",
    if (is.null(meta_data_path)) "(db_path_list$meta_data not set — file absent)"
    else meta_data_path, "\n",
    "Local fix: run `Rscript shared/update_scripts/ETL/all/all_ETL_meta_init_0IM.R` ",
    "to bootstrap meta_data.duckdb from the CSV seed.",
    "\nConnect fix: set SUPABASE_DB_* or PGHOST/PGPASSWORD; ensure `df_product_line_profile` exists in app_data DB."
  )

  required_fields <- c(
    "product_line_name_english",
    "product_line_name_chinese",
    "product_line_id"
  )

  meta_ok <- !is.null(meta_data_path) && nzchar(meta_data_path) &&
    file.exists(meta_data_path)

  if (!meta_ok) {
    supabase_ok <- exists("supabase_env_available", mode = "function", inherits = TRUE) &&
      isTRUE(supabase_env_available())
    if (!supabase_ok || !exists("dbConnectAppData", mode = "function", inherits = TRUE)) {
      stop(actionable, call. = FALSE)
    }
    message(
      "⇢ load_product_lines: no meta_data.duckdb — reading df_product_line_profile ",
      "from app_data DB (DM_R054 v2.1.1)"
    )
    pg_con <- dbConnectAppData(
      config_path = "app_config.yaml",
      verbose = isTRUE(getOption("app.verbose", FALSE))
    )
    on.exit(try(DBI::dbDisconnect(pg_con), silent = TRUE), add = TRUE)
    product_lines <- DBI::dbReadTable(pg_con, "df_product_line_profile")
    product_lines <- as.data.frame(product_lines)[, required_fields, drop = FALSE]
  } else {
    if (!is.null(csv_path)) {
      message("⇢ load_product_lines: ignoring csv_path argument (DM_R054 v2.1: ",
              "runtime MUST NOT read CSV seeds). Source = meta_data.duckdb at ",
              meta_data_path)
    }

    message("⇢ Loading product lines from canonical meta_data.duckdb: ",
            meta_data_path)
    meta_con <- DBI::dbConnect(duckdb::duckdb(), meta_data_path, read_only = TRUE)
    on.exit(try(DBI::dbDisconnect(meta_con, shutdown = TRUE), silent = TRUE),
            add = TRUE)
    if (!("df_product_line" %in% DBI::dbListTables(meta_con))) {
      stop(
        "meta_data.duckdb exists but contains no df_product_line table.\n",
        "  path: ", meta_data_path, "\n",
        "Fix: run `Rscript shared/update_scripts/ETL/all/all_ETL_meta_init_0IM.R` ",
        "to (re)bootstrap metadata tables from the CSV seed.",
        call. = FALSE
      )
    }
    product_lines <- DBI::dbReadTable(meta_con, "df_product_line")
  }

  # --- Validate schema ---------------------------------------------------
  missing_fields <- setdiff(required_fields, names(product_lines))
  if (length(missing_fields) > 0) {
    stop("product_lines source missing required fields: ",
         paste(missing_fields, collapse = ", "),
         call. = FALSE)
  }

  # R118: Normalize product_line_id to lowercase
  uppercase_ids <- product_lines$product_line_id[
    grepl("[A-Z]", product_lines$product_line_id)
  ]
  if (length(uppercase_ids) > 0) {
    warning("Converting uppercase product_line_ids to lowercase: ",
            paste(uppercase_ids, collapse = ", "))
    product_lines$product_line_id <- tolower(product_lines$product_line_id)
  }

  # --- Store in SQLite conn (in-memory app cache) -----------------------
  message("⇢ Storing product line data in SQLite: df_product_line_profile")
  DBI::dbExecute(conn, "
    CREATE TABLE IF NOT EXISTS df_product_line_profile (
      product_line_id CHAR(3) PRIMARY KEY,
      product_line_name_english TEXT NOT NULL,
      product_line_name_chinese TEXT
    )
  ")
  DBI::dbWriteTable(conn, "df_product_line_profile", product_lines,
                    overwrite = TRUE)

  return(product_lines)
}
