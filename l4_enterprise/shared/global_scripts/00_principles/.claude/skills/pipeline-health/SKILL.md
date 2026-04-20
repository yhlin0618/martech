---
name: pipeline-health
description: |
  檢查 ETL/DRV pipeline 的全管線健康狀態。
  列出所有 targets 的成功/失敗/未跑狀態、每個 DuckDB layer 的 table 和 row count、
  每個 product line 的資料覆蓋率。一張表告訴你「哪裡斷了」。
  Use when: 問「ETL 有通嗎」「pipeline 狀態」「哪些 product line 缺資料」「資料庫有什麼表」
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

# Pipeline Health Check

## Overview

快速診斷一個公司專案的 ETL/DRV pipeline 健康狀態。輸出一份完整報告，讓你一眼看到「哪裡斷了、哪裡缺資料」。

## Execution Flow

### Step 0: 確定公司目錄

如果使用者沒指定，從 cwd 推斷。確認目錄有 `app_config.yaml`。

```bash
# 確認是公司目錄
ls app_config.yaml
```

如果不在公司目錄，問使用者要檢查哪個公司（QEF_DESIGN / MAMBA / D_RACING / ...）。

### Step 1: Pipeline Targets 狀態

用 `{targets}` 的 metadata 查每個 target 的狀態：

```r
QEF_ROOT <- "{company_root}"
store <- file.path(QEF_ROOT, "_targets")

if (!dir.exists(store)) {
  cat("No _targets store. Pipeline has never been run.\n")
} else {
  meta <- targets::tar_meta(store = store, fields = c("name", "time", "error", "seconds"))

  # 分類
  etl <- meta[grepl("^(amz|cbz|eby|all)_ETL_", meta$name), ]
  drv <- meta[grepl("^(amz|cbz|eby|all)_D\\d", meta$name), ]

  # 顯示
  for (df_name in c("ETL", "DRV")) {
    df <- if (df_name == "ETL") etl else drv
    cat(sprintf("\n=== %s Targets ===\n", df_name))
    for (i in seq_len(nrow(df))) {
      status <- if (!is.na(df$error[i]) && nchar(df$error[i]) > 0) "ERROR" else "OK"
      cat(sprintf("%-50s %s\n", df$name[i], status))
    }
  }
}
```

輸出格式：
```
=== ETL Targets ===
amz_ETL_sales_0IM                                  OK
amz_ETL_sales_1ST                                  OK
amz_ETL_sales_2TR                                  OK
amz_ETL_comment_properties_0IM                     OK
amz_ETL_comment_properties_1ST                     ERROR
...

=== DRV Targets ===
amz_D01_00                                         OK
amz_D01_01                                         OK
...
```

### Step 2: 找出缺失的 Targets

**重要：只檢查 app_config.yaml 裡的 active platforms，不檢查 shared scripts 裡所有可用的平台。**

```bash
# 1. 讀 app_config.yaml 的 active platforms
#    用 R 或 grep 從 platforms: section 取出 status: "active" 的 platform codes
#    例：QEF_DESIGN 只有 amz

# 2. 只列出 active platform 的 scripts
for platform in $ACTIVE_PLATFORMS; do
  ls scripts/update_scripts/ETL/$platform/*.R 2>/dev/null | sed 's|.*/||;s|\.R||'
  ls scripts/update_scripts/DRV/$platform/*.R 2>/dev/null | sed 's|.*/||;s|\.R||'
done
# 加上 all/ (跨平台共用)
ls scripts/update_scripts/ETL/all/*.R 2>/dev/null | sed 's|.*/||;s|\.R||'
ls scripts/update_scripts/DRV/all/*.R 2>/dev/null | sed 's|.*/||;s|\.R||'

# 3. 已跑過的（從 _targets metadata）
# 4. 取差集 = 從未跑過的
```

> **為什麼只看 active platforms?** `shared/update_scripts/` 是跨公司共用的,包含所有平台(amz, cbz, eby 等)的腳本。但每家公司只啟用部分平台 — QEF_DESIGN 只用 amz,MAMBA 只用 cbz + eby。列出非 active platform 的「未跑」是假警報。

輸出：
```
Active platforms: amz
=== Never Executed (amz + all only) ===
amz_ETL_sales_time_series_2TR
amz_D04_01
amz_D04_02
...
```

### Step 3: DuckDB Layer 健康

檢查每個 DuckDB 的 table 和 row count：

```r
library(DBI)
library(duckdb)

layers <- list(
  raw_data      = "data/database/raw_data.duckdb",
  staged_data   = "data/database/staged_data.duckdb",
  transformed_data = "data/database/transformed_data.duckdb",
  processed_data = "data/database/processed_data.duckdb",
  cleansed_data = "data/database/cleansed_data.duckdb",
  app_data      = "data/app_data/app_data.duckdb"
)

for (layer_name in names(layers)) {
  path <- file.path("{company_root}", layers[[layer_name]])
  if (!file.exists(path)) {
    cat(sprintf("\n=== %s === (NOT FOUND)\n", layer_name))
    next
  }
  con <- dbConnect(duckdb(), path, read_only = TRUE)
  tables <- dbListTables(con)
  cat(sprintf("\n=== %s === (%d tables)\n", layer_name, length(tables)))
  for (tbl in tables) {
    n <- dbGetQuery(con, sprintf("SELECT COUNT(*) as n FROM \"%s\"", tbl))$n
    cat(sprintf("  %-50s %s rows\n", tbl, format(n, big.mark = ",")))
  }
  dbDisconnect(con)
}
```

### Step 4: Product Line 覆蓋率

對有 `product_line_id` 欄位的 key tables 做覆蓋率分析：

```r
key_tables <- list(
  raw_data = c("df_all_comment_property"),
  app_data = c("df_dna_by_customer", "df_position")
)

active_pl <- get_active_product_lines()$product_line_id

for (layer in names(key_tables)) {
  path <- file.path("{company_root}", layers[[layer]])
  con <- dbConnect(duckdb(), path, read_only = TRUE)
  for (tbl in key_tables[[layer]]) {
    if (!dbExistsTable(con, tbl)) next
    cols <- dbListFields(con, tbl)
    if (!"product_line_id" %in% cols) next

    coverage <- dbGetQuery(con, sprintf("
      SELECT product_line_id, COUNT(*) as rows
      FROM \"%s\"
      GROUP BY product_line_id
      ORDER BY product_line_id
    ", tbl))

    cat(sprintf("\n=== %s.%s Product Line Coverage ===\n", layer, tbl))
    for (pl in active_pl) {
      rows <- coverage$rows[coverage$product_line_id == pl]
      if (length(rows) == 0) rows <- 0
      status <- if (rows > 0) "OK" else "MISSING"
      cat(sprintf("  %-10s %6s rows  %s\n", pl, format(rows, big.mark = ","), status))
    }

    missing <- setdiff(active_pl, coverage$product_line_id)
    if (length(missing) > 0) {
      cat(sprintf("  MISSING product lines: %s\n", paste(missing, collapse = ", ")))
    }
  }
  dbDisconnect(con)
}
```

### Step 5: Error Details

如果有 ERROR targets，顯示完整錯誤訊息：

```r
errors <- meta[!is.na(meta$error) & nchar(meta$error) > 0, ]
if (nrow(errors) > 0) {
  cat("\n=== Error Details ===\n")
  for (i in seq_len(nrow(errors))) {
    cat(sprintf("\nTARGET: %s\nERROR: %s\n", errors$name[i], errors$error[i]))
  }
}
```

### Step 6: Summary Report

整合 Step 1-5 的結果，輸出一份簡潔的健康報告：

```
## Pipeline Health Report: {COMPANY}

### Targets
- ETL: {n_ok}/{n_total} OK, {n_err} ERROR, {n_never} never executed
- DRV: {n_ok}/{n_total} OK, {n_err} ERROR, {n_never} never executed

### DuckDB Layers
| Layer | Tables | Total Rows | Exists |
|-------|--------|------------|--------|
| raw_data | 12 | 45,230 | YES |
| staged_data | 10 | 42,100 | YES |
| ... | ... | ... | ... |
| app_data | 8 | 38,500 | YES |

### Product Line Coverage
| Product Line | comment_property | dna | position | Overall |
|-------------|-----------------|-----|----------|---------|
| hsg | 136 | 500 | 10 | OK |
| sfg | 99 | 300 | 8 | OK |
| ... | ... | ... | ... | ... |

### Issues Found
1. ERROR: all_D01_07 — object 'amz_D01_06' not found
2. NEVER RUN: amz_D04_01 ~ D04_06 (Poisson analysis)
3. MISSING: sales_time_series_2TR (needed for D04)

### Recommended Actions
- [ ] Fix all_D01_07 dependency issue
- [ ] Run sales_time_series pipeline: `make run TARGET=amz_ETL_sales_time_series_2TR`
- [ ] Run D04 Poisson analysis: `make run TARGET=amz_D04_01`
```

## Notes

- 此 skill 只讀不寫（read-only DuckDB connections）
- 不會執行任何 ETL 腳本，只檢查狀態
- 若 `_targets` store 不存在，報告「pipeline 從未執行」
- 若某個 DuckDB 不存在（例如 `processed_data.duckdb`），報告 NOT FOUND 並繼續
- key_tables 列表可能需要根據公司調整（不同公司可能有不同的核心 tables）
