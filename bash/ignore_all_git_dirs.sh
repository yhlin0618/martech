#\!/bin/bash
# 設定所有 .git 目錄不參與 Dropbox 同步

echo "========================================="
echo "設定所有 .git 目錄不參與 Dropbox 同步"
echo "========================================="

# 計數器
count=0
failed=0

# 找出所有 .git 目錄
echo -e "\n搜尋所有 .git 目錄..."
git_dirs=$(find . -name ".git" -type d 2>/dev/null)

if [ -z "$git_dirs" ]; then
    echo "未找到任何 .git 目錄"
    exit 0
fi

echo -e "\n找到的 .git 目錄："
echo "$git_dirs" | while read dir; do
    echo "  • $dir"
done

echo -e "\n開始設定 Dropbox 忽略屬性..."
echo "$git_dirs" | while read dir; do
    if [ -d "$dir" ]; then
        # 設定忽略屬性
        if xattr -w com.dropbox.ignored 1 "$dir" 2>/dev/null; then
            echo "✓ 已忽略: $dir"
            ((count++))
        else
            echo "✗ 設定失敗: $dir"
            ((failed++))
        fi
    fi
done

# 驗證設定
echo -e "\n========================================="
echo "驗證已設定的忽略屬性："
echo "========================================="

echo "$git_dirs" | while read dir; do
    if [ -d "$dir" ]; then
        # 檢查是否有 dropbox.ignored 屬性
        if xattr -l "$dir" 2>/dev/null | grep -q "com.dropbox.ignored"; then
            echo "✓ $dir - 已設定忽略"
        else
            echo "✗ $dir - 未設定忽略"
        fi
    fi
done

echo -e "\n========================================="
echo "總結："
echo "成功設定: $count 個目錄"
echo "失敗: $failed 個目錄"
echo "========================================="

echo -e "\n提示："
echo "1. 已設定的 .git 目錄將不會被 Dropbox 同步"
echo "2. 如要移除忽略: xattr -d com.dropbox.ignored <path>"
echo "3. 查看所有被忽略的目錄: find . -type d -exec xattr -l {} \; 2>/dev/null | grep -B1 'com.dropbox.ignored'"
echo "4. 這個設定是永久的，直到手動移除"
