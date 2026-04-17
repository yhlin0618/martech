#!/bin/bash
# 備份並合併 global_scripts 的腳本
# 這個腳本會：
# 1. 備份當前的 global_scripts
# 2. 從遠端拉取缺失的檔案
# 3. 保留本地的新開發內容

set -e

# 顏色輸出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}開始備份和合併 global_scripts...${NC}"

# 1. 建立備份
backup_dir="global_scripts_backup_$(date +%Y%m%d_%H%M%S)"
echo -e "${BLUE}建立備份: $backup_dir${NC}"
cp -r global_scripts "$backup_dir"

# 2. 克隆遠端倉庫到臨時目錄
temp_dir="temp_remote_$(date +%s)"
echo -e "${BLUE}克隆遠端倉庫...${NC}"
git clone git@github.com:kiki830621/precision_marketing_global_scripts.git "$temp_dir"

# 3. 複製遠端獨有的檔案到本地
echo -e "${BLUE}合併遠端獨有的檔案...${NC}"

# 複製 rsconnect 相關檔案
if [ -d "$temp_dir/global_scripts/20_R_packages" ]; then
    mkdir -p global_scripts/20_R_packages
    cp -r "$temp_dir/global_scripts/20_R_packages/"* global_scripts/20_R_packages/ 2>/dev/null || true
    echo -e "${GREEN}✓ 複製了 20_R_packages 目錄${NC}"
fi

if [ -d "$temp_dir/global_scripts/21_rshinyapp_templates/rsconnect" ]; then
    mkdir -p global_scripts/21_rshinyapp_templates/rsconnect
    cp -r "$temp_dir/global_scripts/21_rshinyapp_templates/rsconnect/"* global_scripts/21_rshinyapp_templates/rsconnect/ 2>/dev/null || true
    echo -e "${GREEN}✓ 複製了 21_rshinyapp_templates/rsconnect 目錄${NC}"
fi

# 複製其他 rsconnect 相關的 .dcf 檔案
find "$temp_dir" -name "*.dcf" -type f | while read -r dcf_file; do
    relative_path="${dcf_file#$temp_dir/}"
    target_dir="$(dirname "$relative_path")"
    mkdir -p "$target_dir"
    cp "$dcf_file" "$relative_path"
    echo -e "${GREEN}✓ 複製了 $relative_path${NC}"
done

# 4. 清理臨時目錄
echo -e "${BLUE}清理臨時檔案...${NC}"
rm -rf "$temp_dir"

echo -e "${GREEN}✅ 合併完成！${NC}"
echo -e "${YELLOW}備份保存在: $backup_dir${NC}"
echo -e "${YELLOW}建議檢查 git status 並提交變更${NC}"