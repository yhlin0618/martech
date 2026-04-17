# analyze_rating_results.R
#
# Analyze eWOM model comparison results against two baselines:
#   - o3-mini (original research baseline)
#   - Claude Opus 4.6 (alternative baseline)
#
# Reads all result CSVs from the test_model_comparison directory.
# Usage: Rscript analyze_rating_results.R
# ---------------------------------------------------------------------

# ==== BASELINES ====

# o3-mini baseline (original research scores)
baseline_o3mini <- data.frame(
  statement_id = 1:4,
  o3_mini = c("3", "4", "3", "NaN"),
  stringsAsFactors = FALSE
)

# Claude Opus 4.6 baseline (independent assessment)
baseline_claude <- data.frame(
  statement_id = 1:4,
  claude_opus = c("2", "4", "3", "NaN"),
  stringsAsFactors = FALSE
)

# Merge baselines
baselines <- merge(baseline_o3mini, baseline_claude, by = "statement_id")

# ==== LOAD RESULTS ====

result_dir <- "scripts/global_scripts/98_test/test_model_comparison"

# Valid result files (manually specified to avoid broken parse runs)
result_files <- c(
  file.path(result_dir, "results_20260221_090856.csv"),   # gpt-5-nano + gpt-5-mini
  file.path(result_dir, "results_gpt4omini_20260221_091441.csv")  # gpt-4o-mini
)

all_results <- do.call(rbind, lapply(result_files, function(f) {
  df <- read.csv(f, stringsAsFactors = FALSE)
  # Normalize columns - some files have extra columns
  keep_cols <- c("statement_id", "model", "effort", "actual_score", "elapsed_sec")
  df[, intersect(keep_cols, names(df))]
}))

# ==== SCORING FUNCTIONS ====

match_score <- function(actual, expected) {
  if (expected == "NaN" && actual == "NaN") return("OK")
  if (expected == "NaN" || actual == "NaN") return("DIFF")
  a <- as.numeric(actual)
  e <- as.numeric(expected)
  if (is.na(a) || is.na(e)) return("DIFF")
  if (a == e) return("OK")
  if (abs(a - e) <= 1) return("~1")
  "DIFF"
}

calc_stats <- function(matches) {
  n <- length(matches)
  n_ok <- sum(matches == "OK")
  n_close <- sum(matches == "~1")
  n_diff <- sum(matches == "DIFF")
  list(
    total = n,
    exact = n_ok,
    within1 = n_close,
    diff = n_diff,
    pct_exact = round(100 * n_ok / n),
    pct_within1 = round(100 * (n_ok + n_close) / n)
  )
}

# ==== COMPARE AGAINST BOTH BASELINES ====

all_results <- merge(all_results, baselines, by = "statement_id")

all_results$match_o3 <- mapply(match_score,
  all_results$actual_score, all_results$o3_mini
)
all_results$match_claude <- mapply(match_score,
  all_results$actual_score, all_results$claude_opus
)

# ==== PRINT RESULTS ====

cat("\n")
cat("=====================================================\n")
cat("  eWOM Model Comparison Analysis\n")
cat("  Baselines: o3-mini & Claude Opus 4.6\n")
cat("=====================================================\n\n")

# --- Baselines ---
cat("--- Baselines ---\n")
cat(sprintf("  %-5s  %-10s  %-10s\n", "Stmt", "o3-mini", "Claude"))
for (i in 1:4) {
  cat(sprintf("  S%-4d  %-10s  %-10s\n",
    baselines$statement_id[i],
    baselines$o3_mini[i],
    baselines$claude_opus[i]
  ))
}
cat("\n")

# --- Per-Model Detail ---
models <- unique(all_results$model)
for (m in models) {
  sub <- all_results[all_results$model == m, ]
  cat(sprintf("--- %s ---\n", m))
  cat(sprintf("  %-5s  %-7s  %-6s  %-8s  %-8s  %s\n",
    "Stmt", "Effort", "Score", "vs_o3", "vs_claude", "Time(s)"
  ))
  for (i in seq_len(nrow(sub))) {
    r <- sub[i, ]
    cat(sprintf("  S%-4d  %-7s  %-6s  %-8s  %-8s  %.1f\n",
      r$statement_id, r$effort, r$actual_score,
      r$match_o3, r$match_claude, r$elapsed_sec
    ))
  }

  stats_o3 <- calc_stats(sub$match_o3)
  stats_cl <- calc_stats(sub$match_claude)
  cat(sprintf(
    "  Summary vs o3-mini:  Exact=%d/%d (%d%%), Within-1=%d%% \n",
    stats_o3$exact, stats_o3$total, stats_o3$pct_exact, stats_o3$pct_within1
  ))
  cat(sprintf(
    "  Summary vs Claude:   Exact=%d/%d (%d%%), Within-1=%d%% \n",
    stats_cl$exact, stats_cl$total, stats_cl$pct_exact, stats_cl$pct_within1
  ))
  cat("\n")
}

# --- Cross-Model Summary ---
cat("=====================================================\n")
cat("  CROSS-MODEL SUMMARY\n")
cat("=====================================================\n\n")

cat(sprintf("  %-15s  %-20s  %-20s  %-10s\n",
  "Model", "vs o3-mini", "vs Claude Opus", "Avg Time"
))
cat(sprintf("  %-15s  %-20s  %-20s  %-10s\n",
  "-----", "----------", "--------------", "--------"
))
for (m in models) {
  sub <- all_results[all_results$model == m, ]
  s_o3 <- calc_stats(sub$match_o3)
  s_cl <- calc_stats(sub$match_claude)
  avg_t <- round(mean(sub$elapsed_sec), 1)
  cat(sprintf("  %-15s  Exact %d%%, ~1 %d%%     Exact %d%%, ~1 %d%%     %.1fs\n",
    m, s_o3$pct_exact, s_o3$pct_within1,
    s_cl$pct_exact, s_cl$pct_within1, avg_t
  ))
}

# --- Per-Statement Consensus ---
cat("\n--- Per-Statement Consensus ---\n")
for (sid in 1:4) {
  sub <- all_results[all_results$statement_id == sid, ]
  scores <- sub$actual_score
  unique_scores <- unique(scores)
  consensus <- if (length(unique_scores) == 1) {
    paste0("unanimous: ", unique_scores)
  } else {
    tbl <- table(scores)
    paste(names(tbl), "(", tbl, ")", collapse = ", ", sep = "")
  }
  cat(sprintf("  S%d: o3=%s, Claude=%s | Models: %s\n",
    sid,
    baselines$o3_mini[sid],
    baselines$claude_opus[sid],
    consensus
  ))
}

cat("\n========== ANALYSIS COMPLETE ==========\n")
