#!/bin/bash
# ============================================================================
# 極簡 Git Subrepo Push 腳本
# ============================================================================
# 功能：輪流對每個應用程式執行 git subrepo push
# 失敗會無限重試，直到成功或手動中斷
# 用戶可以隨時 Ctrl+C 結束
# 支援傳遞任意 git subrepo push 選項
# ============================================================================

git subrepo clean --ALL

# 定義所有應用程式路徑
APP_PATHS=(
    "l1_basic/InsightForge"
    "l1_basic/positioning_app" 
    "l1_basic/TagPilot"
    "l1_basic/VitalSigns"
    "l2_pro/TagPilot_pro"
    "l2_pro/TagPilot_pro___v2"
    "l4_enterprise/WISER"
)

# 獲取傳入的選項，如果沒有提供則為空
SUBREPO_OPTIONS=("$@")

echo "開始推送 ${#APP_PATHS[@]} 個應用程式..."
if [ ${#SUBREPO_OPTIONS[@]} -gt 0 ]; then
    echo "使用選項: ${SUBREPO_OPTIONS[@]}"
fi
echo "用戶可以隨時按 Ctrl+C 結束"
echo "失敗時會不斷重試，直到成功或手動中斷"
echo ""

# 統計變數
SUCCESS_COUNT=0

# 清理 git-subrepo 臨時檔案
echo "清理 git-subrepo 臨時檔案..."
rm -rf .git/tmp/subrepo/ 2>/dev/null || true
git worktree prune 2>/dev/null || true

# 設定 Dropbox 忽略臨時目錄
if [ -d ".git/tmp" ]; then
    xattr -w com.dropbox.ignored 1 .git/tmp 2>/dev/null || true
fi

echo "清理完成，開始執行 subrepo push 操作..."
echo ""

# 迴圈處理每個應用程式
for app_path in "${APP_PATHS[@]}"; do
    echo "======================================="
    echo "正在處理: $app_path"
    echo "======================================="
    
    # 無限循環直到成功
    while true; do
        echo "正在執行: git subrepo push ${SUBREPO_OPTIONS[@]} $app_path"
        
        if git subrepo push "${SUBREPO_OPTIONS[@]}" "$app_path" 2>/tmp/subrepo_err; then
            echo "✅ $app_path 成功"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
            
            # 清理臨時檔案
            git subrepo clean "$app_path" -q 2>/dev/null || true
            rm -rf .git/tmp/subrepo/* 2>/dev/null || true
            
            break
        else
            error_output=$(cat /tmp/subrepo_err)
            
            # 檢查是否是 "no new commits to push" 的情況
            if echo "$error_output" | grep -q "has no new commits to push"; then
                echo "✅ $app_path 成功 (沒有新提交需要推送)"
                SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
                
                # 清理臨時檔案
                git subrepo clean "$app_path" -q 2>/dev/null || true
                rm -rf .git/tmp/subrepo/* 2>/dev/null || true
                
                break
            else
                echo "❌ $app_path 失敗，2秒後重試..."
                echo "錯誤信息: $error_output"
                
                # 清理臨時檔案
                git subrepo clean "$app_path" -q 2>/dev/null || true
                rm -rf .git/tmp/subrepo/* 2>/dev/null || true
                
                sleep 2
            fi
        fi
    done
    
    echo ""
done

echo "🎉 所有應用程式都成功推送完成！"
echo "成功推送: $SUCCESS_COUNT 個應用程式"

# 清理臨時檔案
rm -f /tmp/subrepo_err