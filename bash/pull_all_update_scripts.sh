#!/bin/bash
# ============================================================================
# 更新所有 update_scripts subrepos
# ============================================================================
# 使用方式：./bash/pull_all_update_scripts.sh
#
# 功能：
# 1. 強制 pull 所有 update_scripts subrepos 到最新版本
# 2. 這會覆蓋本地的 update_scripts 變更，請先確認已經 push 重要變更
# ============================================================================

# update_scripts remote URLs
# l3_enterprise/WISER: git@github.com:kiki830621/ai_martech_l3_enterprise_update_scripts.git

# 定義所有需要更新的 update_scripts 路徑
# 新增路徑時只需要在這個陣列中加入即可
UPDATE_SCRIPTS_PATHS=(
    "l3_enterprise/WISER/scripts/update_scripts"
    # 未來可以在這裡加入其他應用的 update_scripts 路徑
    # 例如：
    # "l1_basic/AppName/scripts/update_scripts"
    # "l2_pro/AppName/scripts/update_scripts"
)

# 智能等待函數：偵測 worktree 清理需要多久
smart_wait_for_worktree_cleanup() {
    local start_time=$(date +%s)
    local retry=0
    local MAX_WAIT=120  # 最多等 2 分鐘
    local last_file_count=0
    local stable_count=0  # 連續穩定次數
    
    echo "  🔍 智能偵測 worktree 清理狀態..."
    
    while [ $retry -lt $MAX_WAIT ]; do
        if [ ! -d ".git/tmp/subrepo" ]; then
            echo "  ✅ worktree 目錄已清理完成"
            break
        fi
        
        current_file_count=$(ls -A .git/tmp/subrepo 2>/dev/null | wc -l)
        
        if [ "$current_file_count" -eq 0 ]; then
            echo "  ✅ worktree 目錄已清空，等待系統完全釋放..."
            rmdir .git/tmp/subrepo 2>/dev/null || true
            sleep 1
            if [ ! -d ".git/tmp/subrepo" ]; then
                break
            fi
        fi
        
        # 偵測檔案數量變化
        if [ "$current_file_count" -ne "$last_file_count" ]; then
            echo "  📊 檔案數量變化: $last_file_count → $current_file_count"
            last_file_count=$current_file_count
            stable_count=0
        else
            ((stable_count++))
            # 如果連續 5 秒檔案數量沒變化，嘗試主動清理
            if [ $stable_count -eq 5 ]; then
                echo "  🧹 檔案數量穩定 5 秒，嘗試主動清理..."
                git worktree prune 2>/dev/null || true
                rm -rf .git/tmp/subrepo/* 2>/dev/null || true
                stable_count=0
            fi
        fi
        
        echo "  ⏳ 等待中... (第 $((retry+1)) 秒，檔案數: $current_file_count)"
        sleep 1
        ((retry++))
    done
    
    local end_time=$(date +%s)
    local elapsed=$((end_time - start_time))
    
    if [ -d ".git/tmp/subrepo" ] && [ "$(ls -A .git/tmp/subrepo 2>/dev/null | wc -l)" -gt 0 ]; then
        echo "  ⚠️  等待 $elapsed 秒後仍有殘留，但繼續執行（通常不影響操作）"
        return 1
    else
        echo "  ✅ worktree 完全清理完成，耗時 $elapsed 秒"
        return 0
    fi
}

echo "開始更新所有 update_scripts subrepos..."
echo "共有 ${#UPDATE_SCRIPTS_PATHS[@]} 個路徑需要更新"
echo ""

# 記錄開始時間
SCRIPT_START_TIME=$(date +%s)

# 執行初始清理，並偵測清理時間
echo "執行初始 worktree 清理..."
rm -rf .git/tmp/subrepo/* 2>/dev/null || true
git worktree prune 2>/dev/null || true

# 如果還有殘留，使用智能等待
if [ -d ".git/tmp/subrepo" ] && [ "$(ls -A .git/tmp/subrepo 2>/dev/null | wc -l)" -gt 0 ]; then
    echo "發現殘留檔案，啟動智能清理..."
    smart_wait_for_worktree_cleanup
else
    echo "✅ 初始清理完成"
fi

# 計數器
success_count=0
failed_count=0

# 迴圈處理每個路徑
for path in "${UPDATE_SCRIPTS_PATHS[@]}"; do
    # 智能等待前一次 worktree 釋放
    smart_wait_for_worktree_cleanup

    echo "正在更新: $path"
    
    # 執行命令並捕獲錯誤輸出
    # 移除 -f，與手動使用的指令保持一致，避免因 "Unstaged changes" 被拒絕
    error_output=$(git subrepo pull "$path" 2>&1)
    exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo "  ✅ 成功"
        ((success_count++))
        
        # 主動清理殘留的 worktree 和臨時檔案（避免 macOS + Dropbox I/O 延遲問題）
        git subrepo clean "$path" -q 2>/dev/null || true
        rm -rf .git/tmp/subrepo/* 2>/dev/null || true
        git worktree prune 2>/dev/null || true
    
    else
        echo "  ❌ 失敗"
        echo "  錯誤信息: $error_output"
        ((failed_count++))
        
        # 失敗時也清理一下，避免影響下次執行
        git subrepo clean "$path" -q 2>/dev/null || true
        rm -rf .git/tmp/subrepo/* 2>/dev/null || true
        git worktree prune 2>/dev/null || true
    fi

    # 操作完成後的智能清理等待
    echo "  🧹 操作完成，等待系統清理..."
    smart_wait_for_worktree_cleanup

    echo ""
done

echo ""
echo "🧹 執行最終清理..."
smart_wait_for_worktree_cleanup

# 計算總耗時
SCRIPT_END_TIME=$(date +%s)
TOTAL_ELAPSED=$((SCRIPT_END_TIME - SCRIPT_START_TIME))

echo ""
echo "========================================="
echo "更新完成摘要："
echo "✅ 成功: $success_count"
echo "❌ 失敗: $failed_count"
echo "總路徑數: ${#UPDATE_SCRIPTS_PATHS[@]}"
echo "總耗時: ${TOTAL_ELAPSED} 秒"
echo "========================================="

if [ $failed_count -gt 0 ]; then
    echo "⚠️  有失敗的路徑，建議檢查上述錯誤信息"
    exit 1
else
    echo "🎉 所有路徑都成功更新完成！"
    exit 0
fi