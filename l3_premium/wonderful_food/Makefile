# Wonderful Food Monorepo Deployment Makefile
# 用於從 wonderful_food_dev 同步檔案到各個 deployment repo
# 架構：開發集中（hierarchical paths）→ 部署分散（flat paths）
#
# 目錄結構：
#   wonderful_food/
#   ├── wonderful_food_dev/     # 開發環境（所有開發在這裡）
#   ├── deployment/             # 部署環境
#   │   ├── brandedge/          # 獨立 git repo
#   │   ├── insightforge/       # 獨立 git repo
#   │   └── tagpilot/           # 獨立 git repo
#   └── archive/                # 歸檔

SOURCE_DIR := wonderful_food_dev
DEPLOY_DIR := deployment

.PHONY: all brandedge insightforge tagpilot sync-all clean help status init-all init-brandedge init-insightforge init-tagpilot

help:
	@echo "Wonderful Food Monorepo Deployment Commands:"
	@echo ""
	@echo "同步命令（日常更新用）:"
	@echo "  make sync-all      - 同步所有 app"
	@echo "  make brandedge     - 同步 BrandEdge"
	@echo "  make insightforge  - 同步 InsightForge"
	@echo "  make tagpilot      - 同步 TagPilot"
	@echo ""
	@echo "初始化命令（首次建立用）:"
	@echo "  make init-all           - 初始化所有 deployment app"
	@echo "  make init-brandedge     - 初始化 BrandEdge"
	@echo "  make init-insightforge  - 初始化 InsightForge"
	@echo "  make init-tagpilot      - 初始化 TagPilot"
	@echo ""
	@echo "  make status        - 檢查所有 repo 狀態"
	@echo "  make clean         - 清理暫存檔"
	@echo ""
	@echo "Note: 同步後需要到各 deployment repo 手動 git commit 和 push"

# ========== 同步命令（日常更新用）==========

sync-all: brandedge insightforge tagpilot
	@echo ""
	@echo "✅ 所有 app 同步完成"
	@echo "📝 請到各 deployment repo 執行 git add/commit/push"

brandedge:
	@echo "🔄 同步 BrandEdge..."
	@echo "   📁 複製 app_brandedge.R → app.R (含路徑轉換)"
	@sed -e 's|config/brandedge/|config/|g' \
	     -e 's|utils/shared/|utils/|g' \
	     -e 's|utils/brandedge/|utils/|g' \
	     -e 's|modules/shared/|modules/|g' \
	     -e 's|modules/brandedge/|modules/|g' \
	     $(SOURCE_DIR)/app_brandedge.R > $(DEPLOY_DIR)/brandedge/app.R
	@echo "   📁 同步 modules (扁平化)"
	@rsync -av --delete $(SOURCE_DIR)/modules/shared/ $(DEPLOY_DIR)/brandedge/modules/
	@if [ -d "$(SOURCE_DIR)/modules/brandedge" ]; then rsync -av $(SOURCE_DIR)/modules/brandedge/ $(DEPLOY_DIR)/brandedge/modules/; fi
	@echo "   📁 同步 utils (扁平化)"
	@rsync -av --delete $(SOURCE_DIR)/utils/shared/ $(DEPLOY_DIR)/brandedge/utils/
	@if [ -d "$(SOURCE_DIR)/utils/brandedge" ]; then rsync -av $(SOURCE_DIR)/utils/brandedge/ $(DEPLOY_DIR)/brandedge/utils/; fi
	@echo "   📁 同步 config"
	@if [ -d "$(SOURCE_DIR)/config/brandedge" ]; then rsync -av --delete $(SOURCE_DIR)/config/brandedge/ $(DEPLOY_DIR)/brandedge/config/; fi
	@echo "   📁 同步 database"
	@rsync -av --delete $(SOURCE_DIR)/database/ $(DEPLOY_DIR)/brandedge/database/
	@echo "   📁 同步 www"
	@rsync -av --delete $(SOURCE_DIR)/www/ $(DEPLOY_DIR)/brandedge/www/
	@echo "   📁 同步 md"
	@rsync -av --delete $(SOURCE_DIR)/md/ $(DEPLOY_DIR)/brandedge/md/
	@echo "   📁 同步 scripts"
	@rsync -av --delete $(SOURCE_DIR)/scripts/ $(DEPLOY_DIR)/brandedge/scripts/
	@echo "✅ BrandEdge 同步完成"

insightforge:
	@echo "🔄 同步 InsightForge..."
	@echo "   📁 複製 app_insightforge.R → app.R (含路徑轉換)"
	@sed -e 's|config/insightforge/|config/|g' \
	     -e 's|utils/shared/|utils/|g' \
	     -e 's|utils/insightforge/|utils/|g' \
	     -e 's|modules/shared/|modules/|g' \
	     -e 's|modules/insightforge/|modules/|g' \
	     $(SOURCE_DIR)/app_insightforge.R > $(DEPLOY_DIR)/insightforge/app.R
	@echo "   📁 同步 modules (扁平化)"
	@rsync -av --delete $(SOURCE_DIR)/modules/shared/ $(DEPLOY_DIR)/insightforge/modules/
	@if [ -d "$(SOURCE_DIR)/modules/insightforge" ]; then rsync -av $(SOURCE_DIR)/modules/insightforge/ $(DEPLOY_DIR)/insightforge/modules/; fi
	@echo "   📁 同步 utils (扁平化)"
	@rsync -av --delete $(SOURCE_DIR)/utils/shared/ $(DEPLOY_DIR)/insightforge/utils/
	@if [ -d "$(SOURCE_DIR)/utils/insightforge" ]; then rsync -av $(SOURCE_DIR)/utils/insightforge/ $(DEPLOY_DIR)/insightforge/utils/; fi
	@echo "   📁 同步 config"
	@if [ -d "$(SOURCE_DIR)/config/insightforge" ]; then rsync -av --delete $(SOURCE_DIR)/config/insightforge/ $(DEPLOY_DIR)/insightforge/config/; fi
	@echo "   📁 同步 database"
	@rsync -av --delete $(SOURCE_DIR)/database/ $(DEPLOY_DIR)/insightforge/database/
	@echo "   📁 同步 www"
	@rsync -av --delete $(SOURCE_DIR)/www/ $(DEPLOY_DIR)/insightforge/www/
	@echo "   📁 同步 md"
	@rsync -av --delete $(SOURCE_DIR)/md/ $(DEPLOY_DIR)/insightforge/md/
	@echo "   📁 同步 scripts"
	@rsync -av --delete $(SOURCE_DIR)/scripts/ $(DEPLOY_DIR)/insightforge/scripts/
	@echo "✅ InsightForge 同步完成"

tagpilot:
	@echo "🔄 同步 TagPilot..."
	@echo "   📁 複製 app_tagpilot.R → app.R (含路徑轉換)"
	@sed -e 's|config/tagpilot/|config/|g' \
	     -e 's|utils/shared/|utils/|g' \
	     -e 's|utils/tagpilot/|utils/|g' \
	     -e 's|modules/shared/|modules/|g' \
	     -e 's|modules/tagpilot/|modules/|g' \
	     $(SOURCE_DIR)/app_tagpilot.R > $(DEPLOY_DIR)/tagpilot/app.R
	@echo "   📁 同步 modules (扁平化)"
	@rsync -av --delete $(SOURCE_DIR)/modules/shared/ $(DEPLOY_DIR)/tagpilot/modules/
	@if [ -d "$(SOURCE_DIR)/modules/tagpilot" ]; then rsync -av $(SOURCE_DIR)/modules/tagpilot/ $(DEPLOY_DIR)/tagpilot/modules/; fi
	@echo "   📁 同步 utils (扁平化)"
	@rsync -av --delete $(SOURCE_DIR)/utils/shared/ $(DEPLOY_DIR)/tagpilot/utils/
	@if [ -d "$(SOURCE_DIR)/utils/tagpilot" ]; then rsync -av $(SOURCE_DIR)/utils/tagpilot/ $(DEPLOY_DIR)/tagpilot/utils/; fi
	@echo "   📁 同步 config"
	@if [ -d "$(SOURCE_DIR)/config/tagpilot" ]; then rsync -av --delete $(SOURCE_DIR)/config/tagpilot/ $(DEPLOY_DIR)/tagpilot/config/; fi
	@echo "   📁 同步 database"
	@rsync -av --delete $(SOURCE_DIR)/database/ $(DEPLOY_DIR)/tagpilot/database/
	@echo "   📁 同步 www"
	@rsync -av --delete $(SOURCE_DIR)/www/ $(DEPLOY_DIR)/tagpilot/www/
	@echo "   📁 同步 md"
	@rsync -av --delete $(SOURCE_DIR)/md/ $(DEPLOY_DIR)/tagpilot/md/
	@echo "   📁 同步 scripts"
	@rsync -av --delete $(SOURCE_DIR)/scripts/ $(DEPLOY_DIR)/tagpilot/scripts/
	@echo "✅ TagPilot 同步完成"

# ========== 初始化命令（首次建立用）==========

init-all: init-brandedge init-insightforge init-tagpilot
	@echo "✅ 所有 deployment app 初始化完成"

init-brandedge:
	@echo "🚀 初始化 BrandEdge..."
	@mkdir -p $(DEPLOY_DIR)/brandedge/{modules,utils,config,database,www,md,scripts}
	@$(MAKE) brandedge
	@cp .gitignore.template $(DEPLOY_DIR)/brandedge/.gitignore 2>/dev/null || echo "# .gitignore\n*.log\n.DS_Store\n*.db\n.env" > $(DEPLOY_DIR)/brandedge/.gitignore
	@cd $(DEPLOY_DIR)/brandedge && \
		git init && \
		git add -A && \
		git commit -m "Initial commit: BrandEdge Premium with Supabase auth" && \
		git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts && \
		gh repo create wonderful_food_brandedge --private --source=. --remote=origin --push
	@echo "✅ BrandEdge 初始化完成"

init-insightforge:
	@echo "🚀 初始化 InsightForge..."
	@mkdir -p $(DEPLOY_DIR)/insightforge/{modules,utils,config,database,www,md,scripts}
	@$(MAKE) insightforge
	@cp .gitignore.template $(DEPLOY_DIR)/insightforge/.gitignore 2>/dev/null || echo "# .gitignore\n*.log\n.DS_Store\n*.db\n.env" > $(DEPLOY_DIR)/insightforge/.gitignore
	@cd $(DEPLOY_DIR)/insightforge && \
		git init && \
		git add -A && \
		git commit -m "Initial commit: InsightForge Premium with Supabase auth" && \
		git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts && \
		gh repo create wonderful_food_insightforge --private --source=. --remote=origin --push
	@echo "✅ InsightForge 初始化完成"

init-tagpilot:
	@echo "🚀 初始化 TagPilot..."
	@mkdir -p $(DEPLOY_DIR)/tagpilot/{modules,utils,config,database,www,md,scripts}
	@$(MAKE) tagpilot
	@cp .gitignore.template $(DEPLOY_DIR)/tagpilot/.gitignore 2>/dev/null || echo "# .gitignore\n*.log\n.DS_Store\n*.db\n.env" > $(DEPLOY_DIR)/tagpilot/.gitignore
	@cd $(DEPLOY_DIR)/tagpilot && \
		git init && \
		git add -A && \
		git commit -m "Initial commit: TagPilot Premium with Supabase auth" && \
		git subrepo clone https://github.com/kiki830621/ai_martech_global_scripts.git scripts/global_scripts && \
		gh repo create wonderful_food_tagpilot --private --source=. --remote=origin --push
	@echo "✅ TagPilot 初始化完成"

# ========== 狀態檢查 ==========

status:
	@echo "📊 Wonderful Food Repo 狀態"
	@echo ""
	@echo "=== wonderful_food_dev ==="
	@cd $(SOURCE_DIR) && git status -s
	@echo ""
	@echo "=== deployment/brandedge ==="
	@if [ -d "$(DEPLOY_DIR)/brandedge/.git" ]; then cd $(DEPLOY_DIR)/brandedge && git status -s; else echo "(未初始化)"; fi
	@echo ""
	@echo "=== deployment/insightforge ==="
	@if [ -d "$(DEPLOY_DIR)/insightforge/.git" ]; then cd $(DEPLOY_DIR)/insightforge && git status -s; else echo "(未初始化)"; fi
	@echo ""
	@echo "=== deployment/tagpilot ==="
	@if [ -d "$(DEPLOY_DIR)/tagpilot/.git" ]; then cd $(DEPLOY_DIR)/tagpilot && git status -s; else echo "(未初始化)"; fi

# ========== 清理 ==========

clean:
	@find . -name ".DS_Store" -delete
	@find . -name "*.log" -delete
	@find . -name "*~" -delete
	@echo "✅ 清理完成"
