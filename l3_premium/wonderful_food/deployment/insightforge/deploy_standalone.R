#!/usr/bin/env Rscript
# 獨立部署腳本 - 不依賴 global_scripts

cat("🚀 InsightForge 部署準備\n")
cat("========================\n\n")

# 檢查 app_config.yaml
if (!file.exists("app_config.yaml")) {
  cat("❌ 找不到 app_config.yaml\n")
  stop("請先創建 app_config.yaml 配置檔案")
}

# 載入配置
if (!requireNamespace("yaml", quietly = TRUE)) {
  cat("安裝 yaml 套件...\n")
  install.packages("yaml")
}
config <- yaml::read_yaml("app_config.yaml")

cat("📋 應用程式資訊\n")
cat("名稱:", config$app_info$name, "\n")
cat("描述:", config$app_info$description, "\n")
cat("版本:", config$app_info$version, "\n\n")

# 步驟 1: 檢查主檔案
cat("步驟 1: 檢查主檔案\n")
cat("------------------\n")
main_file <- ifelse(is.null(config$deployment$main_file), "app.R", config$deployment$main_file)

if (!file.exists(main_file)) {
  cat("❌", main_file, "不存在\n")
  stop("請確保主檔案存在")
} else {
  cat("✅", main_file, "存在\n")
}

# 如果主檔案不是 app.R，檢查是否需要複製
if (main_file != "app.R") {
  if (!file.exists("app.R")) {
    cat("創建 app.R (從", main_file, "複製)...\n")
    file.copy(main_file, "app.R", overwrite = TRUE)
  }
}

# 步驟 2: 更新 manifest.json
cat("\n步驟 2: 更新 manifest.json\n")
cat("-------------------------\n")
if (requireNamespace("rsconnect", quietly = TRUE)) {
  tryCatch({
    rsconnect::writeManifest()
    cat("✅ manifest.json 已更新\n")
  }, error = function(e) {
    cat("⚠️  更新失敗，請手動執行 rsconnect::writeManifest()\n")
  })
} else {
  cat("⚠️  請安裝 rsconnect 套件\n")
}

# 步驟 3: 檢查環境變數
cat("\n步驟 3: 環境變數檢查\n")
cat("-------------------\n")
if (!is.null(config$env_vars)) {
  cat("需要設定的環境變數:\n")
  for (var in config$env_vars) {
    cat("  •", var, "\n")
  }
}

# 步驟 4: 部署指示
cat("\n========================\n")
cat("📋 部署步驟\n")
cat("========================\n\n")

cat("1️⃣ 提交變更到 Git:\n")
cat("   cd ../..\n")
cat("   git add -A\n")
cat("   git commit -m 'Update InsightForge'\n")
cat("   git subrepo push l1_basic/InsightForge\n\n")

cat("2️⃣ 在 Posit Connect Cloud:\n")
cat("   https://connect.posit.cloud\n")
cat("   - Repository:", config$deployment$github_repo, "\n")
cat("   - Branch:", config$deployment$branch, "\n")
cat("   - App Path:", config$deployment$app_path, "\n\n")

cat("3️⃣ 設定環境變數（如上所列）\n\n")

cat("完成時間:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n") 