#' Load df_platform for Shiny runtime (DM_R054 v2.1.1)
#'
#' Prefers `meta_data.duckdb` when present (local ETL / DuckDB mode). When the
#' file is absent — typical for Posit Connect + `database.mode = supabase` —
#' reads `public.df_platform` from the app_data PostgreSQL connection via
#' [dbConnectAppData()].
#'
#' @param meta_path Path to `meta_data.duckdb`, usually `db_path_list$meta_data`.
#' @keywords internal
load_df_platform_metadata <- function(
  meta_path = if (exists("db_path_list") && !is.null(db_path_list$meta_data)) {
    db_path_list$meta_data
  } else {
    NULL
  }
) {
  .fail <- function(detail) {
    stop(
      "Shiny startup cannot load df_platform — meta_data.duckdb OR Supabase app_data required ",
      "(DM_R054 v2.1.1).\n",
      detail,
      "Local fix: run `Rscript shared/update_scripts/ETL/all/all_ETL_meta_init_0IM.R` from company root.\n",
      "Connect fix: set SUPABASE_DB_* or PGHOST/PGPASSWORD; use `database.mode: supabase` (or auto) in app_config.yaml.",
      call. = FALSE
    )
  }

  if (!is.null(meta_path) && nzchar(meta_path) && file.exists(meta_path)) {
    .meta_con <- DBI::dbConnect(duckdb::duckdb(), meta_path, read_only = TRUE)
    on.exit(try(DBI::dbDisconnect(.meta_con, shutdown = TRUE), silent = TRUE),
            add = TRUE
    )
    if (!("df_platform" %in% DBI::dbListTables(.meta_con))) {
      .fail(paste0("meta_data.duckdb at ", meta_path, " has no df_platform.\n"))
    }
    return(DBI::dbReadTable(.meta_con, "df_platform"))
  }

  supabase_ok <- exists("supabase_env_available", mode = "function", inherits = TRUE) &&
    isTRUE(supabase_env_available())
  if (!supabase_ok) {
    .env_diag <- vapply(
      c("SUPABASE_DB_HOST", "SUPABASE_DB_PASSWORD",
        "SUPABASE_DB_PORT", "SUPABASE_DB_USER", "SUPABASE_DB_NAME",
        "SUPABASE_URL",
        "PGHOST", "PGPASSWORD", "PGPORT", "PGUSER", "PGDATABASE"),
      function(v) sprintf("  %s = %s", v,
                          if (nzchar(Sys.getenv(v, ""))) "SET" else "unset"),
      character(1)
    )
    .fail(paste0(
      "  meta_data path: ",
      if (is.null(meta_path) || !nzchar(meta_path)) "(not set / missing file)" else meta_path,
      "\n  DB env: need SUPABASE_DB_HOST+SUPABASE_DB_PASSWORD or PGHOST+PGPASSWORD.\n",
      "  --- env var visibility (names only, values hidden) ---\n",
      paste(.env_diag, collapse = "\n"),
      "\n  ------------------------------------------------------\n"
    ))
  }
  if (!exists("dbConnectAppData", mode = "function", inherits = TRUE)) {
    .fail("dbConnectAppData not found (expected from 02_db_utils).\n")
  }

  message(
    "⇢ load_df_platform_metadata: no local meta_data.duckdb — reading df_platform ",
    "from app_data DB (DM_R054 v2.1.1)"
  )
  pg_con <- dbConnectAppData(
    config_path = "app_config.yaml",
    verbose = isTRUE(getOption("app.verbose", FALSE))
  )
  on.exit(try(DBI::dbDisconnect(pg_con), silent = TRUE), add = TRUE)
  DBI::dbReadTable(pg_con, "df_platform")
}
