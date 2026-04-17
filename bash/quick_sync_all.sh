#!/bin/bash
# ============================================================================
# 快速同步所有 Git Repositories
# ============================================================================
# 自動 commit、pull、push 所有倉庫
# ============================================================================

set -e

# 顏色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 預設 commit 訊息
DEFAULT_MSG="chore: sync updates $(date '+%Y-%m-%d %H:%M')"

echo -e "${BLUE}快速同步所有 Git Repositories${NC}\n"

# 取得專案根目錄
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT"

# 1. 處理 global_scripts submodule
echo -e "${YELLOW}[1/3] 同步 global_scripts (submodule)...${NC}"
if [ -d "global_scripts/.git" ]; then
    cd global_scripts
    if [[ -n $(git status --porcelain) ]]; then
        git add -A
        git commit -m "$DEFAULT_MSG" || true
    fi
    git pull --rebase origin main || git pull --rebase origin master || true
    git push origin main || git push origin master || true
    cd "$PROJECT_ROOT"
    echo -e "${GREEN}✓ global_scripts 已同步${NC}"
fi

# 2. 同步 subrepo
echo -e "\n${YELLOW}[2/3] 同步 subrepo 應用程式...${NC}"
SUBREPOS=("l1_basic/positioning_app" "l1_basic/VitalSigns" "l1_basic/InsightForge" "l1_basic/TagPilot" "l3_enterprise/WISER")

# 先檢查並提交所有 subrepo 的修改
for subrepo in "${SUBREPOS[@]}"; do
    if [ -f "$subrepo/.gitrepo" ] && [ -d "$subrepo" ]; then
        # 檢查 subrepo 內是否有修改
        if [[ -n $(git status --porcelain "$subrepo") ]]; then
            echo -e "  發現 $subrepo 有修改，正在提交..."
            git add "$subrepo"
            git commit -m "chore: update $subrepo" || true
        fi
    fi
done

# 然後同步 subrepo
for subrepo in "${SUBREPOS[@]}"; do
    if [ -f "$subrepo/.gitrepo" ]; then
        echo -e "  同步 $subrepo..."
        git subrepo pull "$subrepo" --force 2>/dev/null || true
        git subrepo push "$subrepo" 2>/dev/null || true
    fi
done
echo -e "${GREEN}✓ Subrepo 已同步${NC}"

# 3. 同步主倉庫
echo -e "\n${YELLOW}[3/3] 同步主倉庫...${NC}"
if [[ -n $(git status --porcelain) ]]; then
    git add -A
    git commit -m "$DEFAULT_MSG" || true
fi
git pull --rebase origin main || git pull --rebase origin master || true
git push origin main || git push origin master || true
echo -e "${GREEN}✓ 主倉庫已同步${NC}"

echo -e "\n${GREEN}所有倉庫同步完成！${NC}" 