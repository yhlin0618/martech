#!/bin/bash
# Dropbox Ignore 管理工具

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_menu() {
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}Dropbox Ignore 管理工具${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""
    echo "請選擇操作："
    echo "1) 套用 .dropboxignore 規則"
    echo "2) 更新忽略設定"
    echo "3) 檢查忽略狀態"
    echo "4) 還原忽略設定"
    echo "5) 顯示被忽略的檔案統計"
    echo "6) 退出"
    echo ""
}

check_installation() {
    if ! command -v dropboxignore &> /dev/null; then
        echo -e "${RED}❌ dropboxignore 未安裝${NC}"
        echo ""
        echo "安裝方式："
        echo "git clone https://codeberg.org/sp1thas/dropboxignore.git"
        echo "cd dropboxignore && sudo make install"
        exit 1
    fi
    echo -e "${GREEN}✓ dropboxignore 已安裝${NC}"
}

apply_rules() {
    echo -e "${YELLOW}正在套用 .dropboxignore 規則...${NC}"
    if dropboxignore; then
        echo -e "${GREEN}✅ 成功套用規則！${NC}"
    else
        echo -e "${RED}❌ 套用失敗${NC}"
    fi
}

update_rules() {
    echo -e "${YELLOW}正在更新忽略設定...${NC}"
    if dropboxignore update; then
        echo -e "${GREEN}✅ 更新成功！${NC}"
    else
        echo -e "${RED}❌ 更新失敗${NC}"
    fi
}

check_status() {
    echo -e "${YELLOW}檢查忽略狀態...${NC}"
    dropboxignore status || echo -e "${YELLOW}無狀態資訊${NC}"
}

revert_settings() {
    echo -e "${YELLOW}正在還原忽略設定...${NC}"
    read -p "確定要還原所有忽略設定嗎？(y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        if dropboxignore revert; then
            echo -e "${GREEN}✅ 還原成功！${NC}"
        else
            echo -e "${RED}❌ 還原失敗${NC}"
        fi
    else
        echo "取消還原"
    fi
}

show_statistics() {
    echo -e "${BLUE}被忽略檔案統計：${NC}"
    echo "----------------------------------------"
    
    # 統計 .git 目錄
    git_count=$(find . -name ".git" -type d 2>/dev/null | wc -l)
    echo "• .git 目錄: $git_count 個"
    
    # 統計其他檔案類型
    ds_store_count=$(find . -name ".DS_Store" 2>/dev/null | wc -l)
    echo "• .DS_Store 檔案: $ds_store_count 個"
    
    rproj_count=$(find . -name ".Rproj.user" -type d 2>/dev/null | wc -l)
    echo "• .Rproj.user 目錄: $rproj_count 個"
    
    log_count=$(find . -name "*.log" 2>/dev/null | wc -l)
    echo "• 日誌檔案 (*.log): $log_count 個"
    
    echo "----------------------------------------"
}

# 主程式
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$PROJECT_ROOT" || exit 1

check_installation

while true; do
    show_menu
    read -p "請選擇 (1-6): " choice
    echo ""
    
    case $choice in
        1)
            apply_rules
            ;;
        2)
            update_rules
            ;;
        3)
            check_status
            ;;
        4)
            revert_settings
            ;;
        5)
            show_statistics
            ;;
        6)
            echo -e "${GREEN}再見！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}無效選項，請重新選擇${NC}"
            ;;
    esac
    
    echo ""
    read -p "按 Enter 繼續..."
    echo ""
done