#!/usr/bin/env Rscript
# ============================================================================
# 測試專案根目錄尋找
# ============================================================================
# 用來測試 rprojroot 是否能正確找到專案根目錄
# ============================================================================

cat("\n====================================\n")
cat("   專案根目錄尋找測試\n")
cat("====================================\n\n")

# 測試 rprojroot
if (!requireNamespace("rprojroot", quietly = TRUE)) {
  cat("rprojroot 套件未安裝，請執行：install.packages('rprojroot')\n")
  stop("需要 rprojroot 套件")
}

library(rprojroot)

# 顯示當前位置
cat("當前工作目錄：\n")
cat(getwd(), "\n\n")

# 測試不同的判斷條件
cat("測試各種根目錄判斷條件：\n")
cat(rep("-", 50), "\n", sep = "")

# 1. RStudio 專案
tryCatch({
  root <- find_root(is_rstudio_project)
  cat("✅ RStudio 專案根目錄：", root, "\n")
}, error = function(e) {
  cat("❌ 找不到 RStudio 專案檔案 (.Rproj)\n")
})

# 2. Git 根目錄
tryCatch({
  root <- find_root(is_git_root)
  cat("✅ Git 根目錄：", root, "\n")
}, error = function(e) {
  cat("❌ 找不到 Git 根目錄 (.git)\n")
})

# 3. 包含 l1_basic 的目錄
tryCatch({
  root <- find_root(has_dir("l1_basic"))
  cat("✅ 包含 l1_basic 的目錄：", root, "\n")
}, error = function(e) {
  cat("❌ 找不到包含 l1_basic 的目錄\n")
})

# 4. 包含 global_scripts 的目錄
tryCatch({
  root <- find_root(has_dir("global_scripts"))
  cat("✅ 包含 global_scripts 的目錄：", root, "\n")
}, error = function(e) {
  cat("❌ 找不到包含 global_scripts 的目錄\n")
})

# 5. 包含 README.md 的目錄
tryCatch({
  root <- find_root(has_file("README.md"))
  cat("✅ 包含 README.md 的目錄：", root, "\n")
}, error = function(e) {
  cat("❌ 找不到包含 README.md 的目錄\n")
})

cat(rep("-", 50), "\n\n", sep = "")

# 使用組合條件
cat("使用組合條件尋找：\n")
root_criterion <- is_rstudio_project | 
                  is_git_root | 
                  has_dir("l1_basic") | 
                  has_dir("global_scripts") |
                  has_file("README.md")

tryCatch({
  project_root <- find_root(root_criterion)
  cat("✅ 找到專案根目錄：", project_root, "\n\n")
  
  # 驗證目錄結構
  cat("驗證目錄結構：\n")
  dirs_to_check <- c("l1_basic", "l2_pro", "l3_enterprise", "global_scripts", "docs")
  
  for (dir in dirs_to_check) {
    path <- file.path(project_root, dir)
    if (dir.exists(path)) {
      cat("  ✅", dir, "\n")
    } else {
      cat("  ❌", dir, "(不存在)\n")
    }
  }
  
  # 顯示相對路徑
  cat("\n從專案根目錄到當前位置的相對路徑：\n")
  rel_path <- gsub(paste0("^", project_root, "/"), "", getwd())
  cat(rel_path, "\n")
  
}, error = function(e) {
  cat("❌ 無法找到專案根目錄\n")
  cat("錯誤訊息：", e$message, "\n")
})

cat("\n測試完成！\n") 