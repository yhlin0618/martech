#!/usr/bin/env Rscript
# Test script for fn_ensure_dna_schema.R (Issue #376, fix-mamba-dashboard-empty-data)
#
# Verifies:
# 1. ensure_dna_schema() adds missing columns when target schema is stale
#    (e.g., missing p_alive after BTYD #211 was added to canonical schema)
# 2. ensure_dna_schema() is idempotent — second call is a no-op
# 3. ensure_dna_schema() handles missing target table gracefully
#
# Run from project root:
#   Rscript shared/global_scripts/98_test/data_tests/test_ensure_dna_schema.R

suppressPackageStartupMessages({
  library(DBI)
  library(duckdb)
})

# ----------------------------------------------------------------------------
# Locate global scripts
# ----------------------------------------------------------------------------
candidate_global_dirs <- c(
  "shared/global_scripts",
  file.path("scripts", "global_scripts"),
  file.path("..", "global_scripts")
)
gs_dir <- candidate_global_dirs[dir.exists(candidate_global_dirs)][1]
if (is.na(gs_dir)) {
  stop("[test] Cannot locate global_scripts directory")
}

# Source dependencies in correct order (matches 14_sql_utils/README.md ordering)
source(file.path(gs_dir, "14_sql_utils", "fn_sanitize_identifier.R"))
source(file.path(gs_dir, "14_sql_utils", "fn_quote_identifier.R"))
source(file.path(gs_dir, "14_sql_utils", "fn_process_column_def.R"))
source(file.path(gs_dir, "14_sql_utils", "fn_generate_column_definitions.R"))
source(file.path(gs_dir, "01_db", "generate_create_table_query", "fn_generate_create_table_query.R"))
source(file.path(gs_dir, "01_db", "fn_create_df_dna_by_customer_table.R"))
source(file.path(gs_dir, "28_migration_scripts", "fn_ensure_dna_schema.R"))

message("=== Test 1: Missing target table is handled gracefully ===")
con1 <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
result1 <- ensure_dna_schema(con1, verbose = TRUE)
stopifnot(length(result1) == 0)
message("PASS: No error when target table absent\n")
DBI::dbDisconnect(con1, shutdown = TRUE)

message("=== Test 2: Stale schema gets missing columns added ===")
con2 <- DBI::dbConnect(duckdb::duckdb(), ":memory:")

# Build a simulated pre-BTYD-#211 schema: a minimal df_dna_by_customer with
# the primary key columns but missing p_alive and btyd_expected_transactions.
# DuckDB rejects ALTER TABLE DROP COLUMN on indexed tables, so we create the
# stale shape directly via raw SQL. ensure_dna_schema() should then add every
# canonical column not present here.
DBI::dbExecute(con2, "
  CREATE TABLE df_dna_by_customer (
    customer_id INTEGER NOT NULL,
    platform_id VARCHAR NOT NULL,
    product_line_id_filter VARCHAR,
    nrec_prob DOUBLE,
    nrec VARCHAR,
    PRIMARY KEY (platform_id, customer_id, product_line_id_filter)
  )
")

cols_before <- DBI::dbListFields(con2, "df_dna_by_customer")
stopifnot(!("p_alive" %in% cols_before))
stopifnot(!("btyd_expected_transactions" %in% cols_before))
message(sprintf("Pre-migration columns: %d (no p_alive, no btyd_expected_transactions)",
                length(cols_before)))

added <- ensure_dna_schema(con2, verbose = TRUE)

cols_after <- DBI::dbListFields(con2, "df_dna_by_customer")
stopifnot("p_alive" %in% cols_after)
stopifnot("btyd_expected_transactions" %in% cols_after)
stopifnot(length(cols_after) > length(cols_before))
stopifnot("p_alive" %in% added)
stopifnot("btyd_expected_transactions" %in% added)
message(sprintf("PASS: Post-migration columns: %d (added %d cols including p_alive + btyd_expected_transactions)\n",
                length(cols_after), length(added)))

message("=== Test 3: Second call is no-op (idempotent) ===")
added2 <- ensure_dna_schema(con2, verbose = TRUE)
stopifnot(length(added2) == 0)
cols_after2 <- DBI::dbListFields(con2, "df_dna_by_customer")
stopifnot(length(cols_after2) == length(cols_after))
message("PASS: Idempotent — second call added 0 columns\n")
DBI::dbDisconnect(con2, shutdown = TRUE)

message("=== Test 4: Fresh canonical table reports 'up to date' on first call ===")
con4 <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
create_df_dna_by_customer_table(con4, or_replace = TRUE, verbose = FALSE)
added4 <- ensure_dna_schema(con4, verbose = TRUE)
stopifnot(length(added4) == 0)
message("PASS: Fresh canonical schema reports 0 missing columns\n")
DBI::dbDisconnect(con4, shutdown = TRUE)

message("=== Test 5: Canonical schema explicitly contains p_alive and btyd_expected_transactions as DOUBLE ===")
con5 <- DBI::dbConnect(duckdb::duckdb(), ":memory:")
create_df_dna_by_customer_table(con5, or_replace = TRUE, verbose = FALSE)
schema_info <- DBI::dbGetQuery(con5, "
  SELECT column_name, data_type
  FROM information_schema.columns
  WHERE table_name = 'df_dna_by_customer' AND table_schema = 'main'
    AND column_name IN ('p_alive', 'btyd_expected_transactions')
  ORDER BY column_name
")
stopifnot(nrow(schema_info) == 2)
stopifnot(all(schema_info$data_type == "DOUBLE"))
print(schema_info)
message("PASS: Canonical D00 schema contains both BTYD #211 columns as DOUBLE\n")
DBI::dbDisconnect(con5, shutdown = TRUE)

message("=== ALL TESTS PASSED ===")
