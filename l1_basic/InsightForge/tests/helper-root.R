# helper-root.R ─ 專案根目錄偵測
# 此檔案會被 testthat 自動於測試前載入，用來將工作目錄設為專案根，
# 以確保所有相對路徑（scripts/…, config/…）能正確解析。

if (!requireNamespace("rprojroot", quietly = TRUE)) {
  stop("❌ 需要先安裝 rprojroot 套件，請執行 install.packages('rprojroot')")
}

root <- rprojroot::find_root(
  rprojroot::is_rstudio_project | rprojroot::is_git_root | rprojroot::has_file(".here")
)

if (!requireNamespace("withr", quietly = TRUE)) {
  stop("❌ 需要先安裝 withr 套件，請執行 install.packages('withr')")
}

# 將工作目錄在整個測試期間鎖定於專案根
withr::local_dir(root, .local_envir = parent.frame())
message("ℹ️  測試期間工作目錄固定於：", root)

# 統一從專案根組路徑
proj_path <- function(...) testthat::test_path("..", ...) 