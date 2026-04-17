#\!/bin/bash
# 全面設定 Dropbox 忽略清單

echo "全面設定 Dropbox 忽略..."

# Git 相關
dirs_to_ignore=(
    ".git/tmp"
    ".git/worktrees"
    ".git/logs"
    ".git/hooks"
    ".git/index.lock"
)

# 檢查並設定每個目錄
for dir in "${dirs_to_ignore[@]}"; do
    if [ -e "$dir" ]; then
        xattr -w com.dropbox.ignored 1 "$dir" 2>/dev/null
        echo "✓ 已忽略: $dir"
    fi
done

# 找出所有 subrepo 的 tmp 目錄並忽略
find . -path "*/.git/tmp" -type d 2>/dev/null | while read dir; do
    xattr -w com.dropbox.ignored 1 "$dir"
    echo "✓ 已忽略 subrepo tmp: $dir"
done

# 大型二進位檔案
find . -name "*.duckdb" -o -name "*.sqlite" -o -name "*.db" | while read file; do
    size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null)
    if [ "$size" -gt 10485760 ]; then  # 大於 10MB
        echo "  考慮忽略大型檔案: $file ($(( size / 1024 / 1024 ))MB)"
    fi
done

echo -e "\n提示："
echo "1. 已設定的忽略屬性會保持到檔案被刪除為止"
echo "2. 如要移除忽略: xattr -d com.dropbox.ignored <path>"
echo "3. 檢視屬性: xattr -l <path>"
