#!/bin/bash

# ================================================================
# Git 推送前安全檢查腳本
# 
# 用途：確保在推送到 GitHub 前，所有安全和同步檢查都已完成
# ================================================================

echo "🔍 開始 Git 推送前檢查..."
echo "================================"

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 檢查結果
CHECKS_PASSED=true

# 1. 檢查 Dropbox 同步狀態
echo -n "1. 檢查 Dropbox 同步狀態... "
if command -v dropbox &> /dev/null; then
    DROPBOX_STATUS=$(dropbox status 2>/dev/null | head -1)
    if [[ $DROPBOX_STATUS == *"Up to date"* ]] || [[ $DROPBOX_STATUS == *"最新狀態"* ]]; then
        echo -e "${GREEN}✓ 已同步${NC}"
    else
        echo -e "${RED}✗ 未完全同步${NC}"
        echo "   Dropbox 狀態: $DROPBOX_STATUS"
        CHECKS_PASSED=false
    fi
else
    echo -e "${YELLOW}⚠ 無法檢查（Dropbox CLI 未安裝）${NC}"
fi

# 2. 檢查 Dropbox 衝突檔案
echo -n "2. 檢查 Dropbox 衝突檔案... "
CONFLICT_FILES=$(find . -name "*衝突的複本*" -o -name "*conflicted copy*" 2>/dev/null | grep -v .git)
if [ -z "$CONFLICT_FILES" ]; then
    echo -e "${GREEN}✓ 無衝突檔案${NC}"
else
    echo -e "${RED}✗ 發現衝突檔案${NC}"
    echo "$CONFLICT_FILES" | head -5
    CHECKS_PASSED=false
fi

# 3. 檢查 git 狀態
echo -n "3. 檢查 Git 工作目錄狀態... "
if [ -z "$(git status --porcelain)" ]; then
    echo -e "${GREEN}✓ 工作目錄乾淨${NC}"
else
    echo -e "${YELLOW}⚠ 有未提交的變更${NC}"
    git status --short | head -5
fi

# 4. 檢查敏感資料檔案
echo -n "4. 檢查敏感資料檔案... "
SENSITIVE_STAGED=$(git diff --cached --name-only | grep -E '\.(csv|xlsx|xls|sqlite|db)$' | grep -v "app_data")
if [ -z "$SENSITIVE_STAGED" ]; then
    echo -e "${GREEN}✓ 無敏感資料檔案${NC}"
else
    echo -e "${RED}✗ 發現可能的敏感資料檔案${NC}"
    echo "$SENSITIVE_STAGED"
    CHECKS_PASSED=false
fi

# 5. 檢查大型檔案
echo -n "5. 檢查大型檔案（>10MB）... "
LARGE_FILES=$(git ls-files -z | xargs -0 du -h 2>/dev/null | grep -E "^[0-9]+M|^[0-9]+G" | cut -f2)
if [ -z "$LARGE_FILES" ]; then
    echo -e "${GREEN}✓ 無大型檔案${NC}"
else
    echo -e "${YELLOW}⚠ 發現大型檔案${NC}"
    echo "$LARGE_FILES" | head -5
fi

# 6. 檢查壓縮檔
echo -n "6. 檢查壓縮檔案... "
ZIP_FILES=$(git diff --cached --name-only | grep -E '\.(zip|rar|7z|tar|gz)$')
if [ -z "$ZIP_FILES" ]; then
    echo -e "${GREEN}✓ 無壓縮檔案${NC}"
else
    echo -e "${YELLOW}⚠ 發現壓縮檔案${NC}"
    echo "$ZIP_FILES"
fi

# 7. 檢查 app_data 外的資料
echo -n "7. 檢查 app_data 外的資料檔案... "
DATA_OUTSIDE=$(find . -path "*/app_data" -prune -o -name "*.xlsx" -o -name "*.csv" -o -name "*.sqlite" | grep -v "app_data" | grep -v ".git")
if [ -z "$DATA_OUTSIDE" ]; then
    echo -e "${GREEN}✓ 資料檔案都在正確位置${NC}"
else
    echo -e "${YELLOW}⚠ 發現 app_data 外的資料檔案（請確認已在 .gitignore）${NC}"
    echo "$DATA_OUTSIDE" | head -5
fi

echo "================================"

# 總結
if [ "$CHECKS_PASSED" = true ]; then
    echo -e "${GREEN}✅ 所有檢查通過！可以安全地推送。${NC}"
    echo ""
    echo "建議的推送命令："
    echo "  git push origin main"
else
    echo -e "${RED}❌ 有檢查未通過，請先解決問題再推送。${NC}"
    exit 1
fi

# 詢問是否要查看完整的 git diff
echo ""
read -p "是否要查看詳細的變更內容？(y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git diff --cached --stat
    echo ""
    read -p "按 Enter 繼續查看詳細 diff，或 Ctrl+C 結束..."
    git diff --cached
fi 