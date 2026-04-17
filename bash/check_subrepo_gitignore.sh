#!/bin/bash

# 檢查所有 subrepo 的 .gitignore 設定
echo "🔍 檢查 git subrepo 的 .gitignore 設定..."
echo "============================================"

# 必須包含的規則
REQUIRED_PATTERNS=(
    ".DS_Store"
    ".env"
    "*.log"
    "*.tmp"
)

# 找出所有的 .gitrepo 檔案
SUBREPOS=$(find . -name ".gitrepo" -not -path "./.git/*" | sed 's|/.gitrepo||')

# 檢查每個 subrepo
for SUBREPO in $SUBREPOS; do
    echo ""
    echo "📁 檢查: $SUBREPO"
    
    GITIGNORE="$SUBREPO/.gitignore"
    
    if [ -f "$GITIGNORE" ]; then
        echo "  ✅ 找到 .gitignore 檔案"
        
        # 檢查必要的規則
        for PATTERN in "${REQUIRED_PATTERNS[@]}"; do
            if grep -q "^$PATTERN" "$GITIGNORE" || grep -q "^\\$PATTERN" "$GITIGNORE"; then
                echo "  ✅ 包含規則: $PATTERN"
            else
                echo "  ❌ 缺少規則: $PATTERN"
            fi
        done
    else
        echo "  ❌ 沒有 .gitignore 檔案！"
    fi
done

echo ""
echo "============================================"
echo "💡 建議："
echo "- 每個 subrepo 都應該有自己的 .gitignore"
echo "- 應包含通用規則（如 .DS_Store）和專案特定規則"
echo "- 主專案的 .gitignore 不會影響 subrepo 內部" 