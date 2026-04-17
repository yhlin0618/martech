#!/usr/bin/env Rscript
# ============================================================================
# 快速使用部署工具
# 所有部署工具現在位於: scripts/global_scripts/23_deployment/
# ============================================================================

# 設定部署工具路徑
DEPLOY_BASE <- "scripts/global_scripts/23_deployment"

# 顯示可用工具
show_deployment_tools <- function() {
  cat("\n📦 Positioning App 部署工具集\n")
  cat("================================\n\n")
  
  cat("🚀 一鍵部署：\n")
  cat("   - sc_deployment.R - 互動式一鍵部署\n")
  cat("   - sc_deployment_auto.R - 自動部署（無需互動）\n")
  
  cat("\n1️⃣ 檢查工具：\n")
  cat("   - check_deployment_improved.R - 改進版部署檢查\n")
  cat("   - check_app_location.R - 檢查應用程式位置\n")
  cat("   - check_deployment.R - 原始部署檢查\n")
  
  cat("\n2️⃣ 更新工具：\n")
  cat("   - update_app.sh --latest - 更新到最新版本\n")
  cat("   - update_app.R - 互動式更新\n")
  cat("   - update_to_latest.R - 快速更新到 v17\n")
  
  cat("\n3️⃣ 部署工具：\n")
  cat("   - deploy_app.R - 簡化部署腳本\n")
  cat("   - deploy.R - 完整部署腳本\n")
  
  cat("\n4️⃣ 文檔：\n")
  cat("   - COMPLETE_DEPLOYMENT_GUIDE.md - 完整指南\n")
  cat("   - POSIT_CONNECT_CLOUD_GITHUB_DEPLOYMENT.md - Posit Cloud 指南\n")
  
  cat("\n📌 快捷方式（在 positioning_app 目錄）：\n")
  cat("   - deploy_now.R - 執行互動式部署\n")
  cat("   - deploy_auto.R - 執行自動部署\n")
}

# 快捷函數
check_deployment <- function() {
  source(file.path(DEPLOY_BASE, "01_checks/check_deployment_improved.R"))
}

update_app_interactive <- function() {
  source(file.path(DEPLOY_BASE, "04_update/update_app.R"))
  update_app()
}

update_to_latest <- function() {
  source(file.path(DEPLOY_BASE, "04_update/update_to_latest.R"))
}

deploy_app <- function() {
  source(file.path(DEPLOY_BASE, "03_deploy/deploy_app.R"))
}

# 新增：一鍵部署函數
deploy_interactive <- function() {
  source(file.path(DEPLOY_BASE, "sc_deployment.R"))
}

deploy_auto <- function() {
  source(file.path(DEPLOY_BASE, "sc_deployment_auto.R"))
}

# 顯示使用方法
if (!interactive()) {
  show_deployment_tools()
  cat("\n使用方法：\n")
  cat("----------\n")
  cat("# 最簡單的方式：\n")
  cat("Rscript deploy_now.R    # 互動式部署\n")
  cat("Rscript deploy_auto.R   # 自動部署\n")
  cat("\n# 或載入工具後使用：\n")
  cat("source('use_deployment_tools.R')\n")
  cat("deploy_interactive()    # 互動式一鍵部署\n")
  cat("deploy_auto()           # 自動部署\n")
} else {
  cat("部署工具已載入！可用函數：\n")
  cat("🚀 一鍵部署：\n")
  cat("- deploy_interactive() - 互動式一鍵部署\n")
  cat("- deploy_auto() - 自動部署\n")
  cat("\n其他工具：\n")
  cat("- check_deployment() - 檢查部署狀態\n")
  cat("- update_app_interactive() - 互動式更新 app.R\n") 
  cat("- update_to_latest() - 更新到最新版本\n")
  cat("- deploy_app() - 部署應用程式\n")
  cat("- show_deployment_tools() - 顯示所有工具\n")
} 