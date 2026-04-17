#!/bin/bash
# ============================================================================
# 極簡 Git Subrepo Pull 腳本
# ============================================================================
# 功能：輪流對每個路徑執行 git subrepo pull
# 失敗會無限重試，直到成功或手動中斷
# 用戶可以隨時 Ctrl+C 結束
# 支援傳遞任意 git subrepo pull 選項
# ============================================================================

git subrepo clean --ALL

# 定義所有需要更新的 global_scripts 路徑
GLOBAL_SCRIPTS_PATHS=(
    "global_scripts"
    "l1_basic/InsightForge/scripts/global_scripts"
    "l1_basic/positioning_app/scripts/global_scripts"
    "l1_basic/TagPilot/scripts/global_scripts"
    "l1_basic/VitalSigns/scripts/global_scripts"
    "l1_basic/latex_test/scripts/global_scripts"
    "l2_pro/TagPilot_pro/scripts/global_scripts"
    "l2_pro/TagPilot_pro___v2/scripts/global_scripts"
    "l3_enterprise/WISER/scripts/global_scripts"
)

# 獲取傳入的選項，如果沒有提供則為空
SUBREPO_OPTIONS=("$@")

echo "開始更新 ${#GLOBAL_SCRIPTS_PATHS[@]} 個 global_scripts 路徑..."
if [ ${#SUBREPO_OPTIONS[@]} -gt 0 ]; then
    echo "使用選項: ${SUBREPO_OPTIONS[@]}"
fi
echo "用戶可以隨時按 Ctrl+C 結束"
echo "失敗時會不斷重試，直到成功或手動中斷"
echo ""

# 統計變數
SUCCESS_COUNT=0

# 迴圈處理每個路徑
for path in "${GLOBAL_SCRIPTS_PATHS[@]}"; do
    echo "======================================="
    echo "正在處理: $path"
    echo "======================================="
    
    # 無限循環直到成功
    while true; do
        echo "正在執行: git subrepo pull ${SUBREPO_OPTIONS[@]} $path"
        
        if git subrepo pull "${SUBREPO_OPTIONS[@]}" "$path"; then
            echo "✅ $path 成功"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            break
        else
            echo "❌ $path 失敗，2秒後重試..."
            sleep 2
        fi
    done
    
    echo ""
done

echo "🎉 所有路徑都成功更新完成！"
echo "成功更新: $SUCCESS_COUNT 個路徑"