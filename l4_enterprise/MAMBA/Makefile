# MAMBA Enterprise Platform - Deployment Makefile
# 用於從開發環境（symlinks）同步到部署目錄（真實檔案）
#
# 日常流程：
#   make deploy-sync   → 同步開發 → 部署
#   make deploy-push   → commit + push → 自動觸發 Posit Connect 部署
#
# 首次設定：
#   make deploy-init   → 建立部署目錄 + git repo + GitHub repo

DEPLOY_DIR := deployment/mamba-enterprise
GITHUB_REPO := kiki830621/ai_martech_l4_MAMBA_deploy

.PHONY: help deploy-init deploy-sync deploy-push deploy-status deploy-diff clean

help:
	@echo "MAMBA Deployment Commands:"
	@echo ""
	@echo "  日常部署："
	@echo "  make deploy-sync     - 同步開發 → 部署（rsync -avL 解析 symlinks）"
	@echo "  make deploy-push     - commit + push 到 GitHub（觸發自動部署）"
	@echo "  make deploy-diff     - 查看部署目錄的變更"
	@echo "  make deploy-status   - 查看部署目錄 git 狀態"
	@echo ""
	@echo "  首次設定："
	@echo "  make deploy-init     - 初始化部署目錄 + GitHub repo"
	@echo ""
	@echo "  維護："
	@echo "  make deploy-manifest - 重新產生 manifest.json"
	@echo "  make clean           - 清理暫存檔"

# ========== 日常部署 ==========

deploy-sync:
	@echo "🔄 同步開發 → 部署..."
	@test -d $(DEPLOY_DIR) || (echo "❌ 部署目錄不存在，請先執行 make deploy-init" && exit 1)
	@# 核心應用檔案
	@cp app.R $(DEPLOY_DIR)/app.R
	@cp app_config.yaml $(DEPLOY_DIR)/app_config.yaml
	@cp .Rprofile $(DEPLOY_DIR)/.Rprofile
	@cp .rsconnectignore $(DEPLOY_DIR)/.rsconnectignore
	@cp .env $(DEPLOY_DIR)/.env 2>/dev/null || true
	@# manifest.json（從開發環境複製）
	@cp manifest.json $(DEPLOY_DIR)/manifest.json 2>/dev/null || true
	@# www 靜態資源（-L 解析 symlinks，如 favicon.ico）
	@mkdir -p $(DEPLOY_DIR)/www
	@rsync -avL --delete www/ $(DEPLOY_DIR)/www/ 2>/dev/null || true
	@# 核心 scripts（rsync -avL 解析 symlinks 為真實檔案）
	@rsync -avL --delete \
		--exclude='.DS_Store' \
		--exclude='*.duckdb' \
		--exclude='*.wal' \
		--exclude='.git' \
		--exclude='.gitrepo' \
		--exclude='__pycache__' \
		--exclude='.Rproj.user' \
		scripts/global_scripts/ $(DEPLOY_DIR)/scripts/global_scripts/
	@rsync -avL --delete \
		--exclude='.DS_Store' \
		--exclude='.git' \
		--exclude='.gitrepo' \
		scripts/nsql/ $(DEPLOY_DIR)/scripts/nsql/ 2>/dev/null || true
	@# Parameters metadata (df_product_line.csv, etc) — not duckdb, must ship with app
	@mkdir -p $(DEPLOY_DIR)/data/app_data/parameters
	@rsync -avL --delete \
		--exclude='.DS_Store' \
		--exclude='*.duckdb' \
		--exclude='*.wal' \
		data/app_data/parameters/ $(DEPLOY_DIR)/data/app_data/parameters/
	@echo ""
	@echo "✅ 同步完成。執行 'make deploy-push' 提交並推送。"

deploy-push:
	@echo "🚀 提交並推送部署..."
	@test -d $(DEPLOY_DIR)/.git || (echo "❌ 部署目錄無 git repo" && exit 1)
	@cd $(DEPLOY_DIR) && \
		git add -A && \
		if git diff --cached --quiet; then \
			echo "ℹ️  無變更需要推送"; \
		else \
			git commit -m "Deploy: $$(date '+%Y-%m-%d %H:%M')" && \
			git push && \
			echo "✅ 推送完成，Posit Connect 將自動部署"; \
		fi

deploy-diff:
	@cd $(DEPLOY_DIR) && git diff --stat

deploy-status:
	@cd $(DEPLOY_DIR) && git status

deploy-manifest:
	@echo "📦 重新產生 manifest.json..."
	@cd $(DEPLOY_DIR) && \
		Rscript -e "rsconnect::writeManifest(appDir = '.', appPrimaryDoc = 'app.R')"
	@echo "✅ manifest.json 產生完成"

# ========== 首次設定 ==========

deploy-init:
	@echo "🚀 初始化 MAMBA 部署目錄..."
	@test ! -d $(DEPLOY_DIR)/.git || (echo "❌ 部署目錄已存在，如需重建請先刪除 $(DEPLOY_DIR)" && exit 1)
	@# 1. 建立目錄結構
	@mkdir -p $(DEPLOY_DIR)/scripts
	@# 2. 複製部署專用 .gitignore
	@cp deployment/.gitignore.deploy $(DEPLOY_DIR)/.gitignore
	@# 3. 複製 deploy_now.R
	@cp deployment/deploy_now.R $(DEPLOY_DIR)/deploy_now.R
	@# 4. 首次完整同步
	@$(MAKE) deploy-sync
	@# 5. 初始化 git
	@cd $(DEPLOY_DIR) && \
		git init && \
		git add -A && \
		git commit -m "Initial deployment: MAMBA Enterprise Platform"
	@echo ""
	@echo "✅ 部署目錄初始化完成"
	@echo ""
	@echo "下一步："
	@echo "  1. 建立 GitHub repo："
	@echo "     cd $(DEPLOY_DIR) && gh repo create $(GITHUB_REPO) --private --source=. --push"
	@echo ""
	@echo "  2. 到 Posit Connect Cloud UI 註冊 app："
	@echo "     https://connect.posit.cloud → Publish → Shiny → 選 $(GITHUB_REPO)"

# ========== 清理 ==========

clean:
	@find . -name ".DS_Store" -delete 2>/dev/null || true
	@echo "✅ 清理完成"
