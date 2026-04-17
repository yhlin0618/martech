#!/bin/bash
# ============================================================================
# 重置所有 NSQL Subrepo 腳本
# ============================================================================
# 功能：清除所有 NSQL subrepo 並重新 clone
# ============================================================================

# 定義所有需要重置的 NSQL 路徑
NSQL_PATHS=(
    "global_scripts/16_NSQL_Language"
    "l1_basic/InsightForge/scripts/global_scripts/16_NSQL_Language"
    "l1_basic/positioning_app/scripts/global_scripts/16_NSQL_Language"
    "l1_basic/TagPilot/scripts/global_scripts/16_NSQL_Language"
    "l1_basic/VitalSigns/scripts/global_scripts/16_NSQL_Language"
    "l1_basic/latex_test/scripts/global_scripts/16_NSQL_Language"
    "l2_pro/TagPilot/scripts/global_scripts/16_NSQL_Language"
    "l3_enterprise/WISER/scripts/global_scripts/16_NSQL_Language"
)

# NSQL Language Repository URL
NSQL_REPO_URL="https://github.com/kiki830621/NSQL.git"

echo "🔄 開始重置 ${#NSQL_PATHS[@]} 個 NSQL subrepo..."
echo "Repository URL: $NSQL_REPO_URL"
echo ""

# 統計變數
SUCCESS_COUNT=0
FAILED_PATHS=()

# 第一階段：清除所有現有的 subrepo
echo "🗑️  第一階段：清除現有 subrepo..."
for path in "${NSQL_PATHS[@]}"; do
    echo "---------------------------------------"
    echo "清除: $path"
    echo "---------------------------------------"
    
    if [ -d "$path" ]; then
        # 檢查是否為 subrepo
        if [ -f "$path/.gitrepo" ]; then
            echo "正在執行: git subrepo clean $path"
            if git subrepo clean "$path"; then
                echo "✅ 成功清除 subrepo: $path"
            else
                echo "⚠️  git subrepo clean 失敗，嘗試手動刪除: $path"
                rm -rf "$path"
                echo "✅ 手動刪除完成: $path"
            fi
        else
            echo "⚠️  不是 subrepo，直接刪除: $path"
            rm -rf "$path"
            echo "✅ 刪除完成: $path"
        fi
    else
        echo "ℹ️  路徑不存在，跳過: $path"
    fi
    echo ""
done

echo ""
echo "🔄 第二階段：重新 clone subrepo..."

# 第二階段：重新 clone 所有 subrepo
for path in "${NSQL_PATHS[@]}"; do
    echo "---------------------------------------"
    echo "Clone: $path"
    echo "---------------------------------------"
    
    echo "正在執行: git subrepo clone $NSQL_REPO_URL $path"
    
    if git subrepo clone "$NSQL_REPO_URL" "$path"; then
        echo "✅ 成功 clone: $path"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "❌ 失敗 clone: $path"
        FAILED_PATHS+=("$path")
    fi
    echo ""
done

echo "🎉 重置完成！"
echo "成功: $SUCCESS_COUNT 個路徑"
echo "失敗: ${#FAILED_PATHS[@]} 個路徑"

if [ ${#FAILED_PATHS[@]} -gt 0 ]; then
    echo ""
    echo "❌ 失敗的路徑："
    for failed_path in "${FAILED_PATHS[@]}"; do
        echo "  - $failed_path"
    done
    echo ""
    echo "💡 建議手動檢查這些路徑"
fi

echo ""
echo "✅ 所有 NSQL subrepo 重置完成！"