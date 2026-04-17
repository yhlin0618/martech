#!/bin/bash
# 套用 macOS Dropbox ignore (xattr) 規則的腳本

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ATTR="com.apple.fileprovider.ignore#P"  # 官方屬性名稱

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Dropbox Ignore (xattr) 套用工具${NC}"
echo -e "${BLUE}=========================================${NC}"

# 取得專案根目錄
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
echo -e "${YELLOW}專案目錄: $PROJECT_ROOT${NC}"

cd "$PROJECT_ROOT" || exit 1

# 檢查 .dropboxignore
if [ ! -f ".dropboxignore" ]; then
    echo -e "${RED}❌ 找不到 .dropboxignore 檔案${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 找到 .dropboxignore 檔案${NC}"

# 參數解析
FORCE_REAPPLY=0
for arg in "$@"; do
  case $arg in
    -f|--force)
      FORCE_REAPPLY=1
      shift ;;
  esac
done

# 函數：設定 / 移除 xattr
ignore_path() { xattr -w "$ATTR" 1 "$1" 2>/dev/null; }
revert_path() { xattr -d "$ATTR" "$1" 2>/dev/null; }

# 強制模式：先清除全部 xattr
if [[ $FORCE_REAPPLY -eq 1 ]]; then
  echo -e "${YELLOW}⚙️  強制模式：移除既有 ignore 屬性${NC}"
  find . -exec sh -c 'xattr -d "$0" "$1" 2>/dev/null' "$ATTR" {} \;
  echo -e "${GREEN}✓ 清除完成${NC}\n"
fi

# 逐條讀取 .dropboxignore 套用
no_match=()
IGNORED_PATHS=()
while IFS= read -r pattern || [[ -n "$pattern" ]]; do
    # 跳過空行或註解
    [[ -z "$pattern" || "$pattern" =~ ^[[:space:]]*# ]] && continue
    pattern=$(echo "$pattern" | sed 's/^ *//;s/ *$//')

    match_cnt=0
    if [[ "$pattern" == */ ]]; then
        clean="${pattern%/}"
        while IFS= read -r dir; do
          if ignore_path "$dir"; then
            ((match_cnt++))
            IGNORED_PATHS+=("$dir")
          fi
        done < <(find . -type d -name "${clean##*/}" 2>/dev/null)
    else
        while IFS= read -r file; do
          if ignore_path "$file"; then
            ((match_cnt++))
            IGNORED_PATHS+=("$file")
          fi
        done < <(find . -name "$pattern" 2>/dev/null)
    fi
    [[ $match_cnt -eq 0 ]] && no_match+=("$pattern")
    echo -e "${GREEN}✓ $pattern → 忽略 $match_cnt 個項目${NC}"
done < .dropboxignore

# 特別處理 .git 目錄
echo -e "\n${BLUE}額外忽略 .git 目錄...${NC}"
find . -name ".git" -type d 2>/dev/null | while read -r g; do ignore_path "$g"; done

echo -e "\n${BLUE}統計結果：${NC}"
IGNORED_TOTAL=${#IGNORED_PATHS[@]}
echo "總共有 $IGNORED_TOTAL 個項目被設定為忽略（本次執行）"

echo -e "\n${BLUE}已忽略項目預覽（前20）：${NC}"
printf '%s\n' "${IGNORED_PATHS[@]}" | head -20

if [[ ${#no_match[@]} -gt 0 ]]; then
  echo -e "\n${YELLOW}⚠️ 以下規則未匹配任何檔案：${NC}"
  printf '  • %s\n' "${no_match[@]}"
fi

echo -e "\n${GREEN}✨ 完成！${NC}"