#!/bin/bash

# ================================================================
# 切換 .git Dropbox 同步設定
# ================================================================

echo "🔧 Git Dropbox 同步設定工具"
echo "=========================="

# 檢查 .git 是否存在
if [ ! -d ".git" ]; then
    echo "❌ 錯誤：當前目錄不是 git 倉庫"
    exit 1
fi

# 檢查當前 .git 大小
GIT_SIZE=$(du -sh .git | cut -f1)
echo "📊 .git 目錄大小：$GIT_SIZE"

# 檢查 Dropbox 排除狀態
echo ""
echo "目前狀態："
if xattr -p com.dropbox.ignored .git 2>/dev/null | grep -q "1"; then
    echo "🚫 .git 目前被排除在 Dropbox 同步之外"
    CURRENT_STATE="excluded"
else
    echo "✅ .git 目前正在被 Dropbox 同步"
    CURRENT_STATE="synced"
fi

# 提供選項
echo ""
echo "請選擇："
echo "1) 同步 .git（電腦損壞時可恢復，但要注意不要多人/多電腦同時操作）"
echo "2) 排除 .git（避免衝突，但需依賴 GitHub 備份）"
echo "3) 查看建議"
echo "4) 取消"
echo ""
read -p "請輸入選項 (1-4): " choice

case $choice in
    1)
        # 移除排除標記
        xattr -d com.dropbox.ignored .git 2>/dev/null || true
        echo "✅ 已設定：.git 將被 Dropbox 同步"
        echo ""
        echo "⚠️  重要提醒："
        echo "- 不要在多台電腦同時進行 git 操作"
        echo "- 定期推送到 GitHub 作為額外備份"
        echo "- 如果看到 .git 相關的衝突檔案，立即處理"
        ;;
    2)
        # 添加排除標記
        xattr -w com.dropbox.ignored 1 .git
        echo "🚫 已設定：.git 被排除在 Dropbox 同步之外"
        echo ""
        echo "📌 請記得："
        echo "- 經常推送到 GitHub (git push)"
        echo "- 考慮設定自動備份"
        echo "- 可以使用 git bundle 創建離線備份"
        ;;
    3)
        echo ""
        echo "💡 建議："
        echo ""
        echo "如果你是："
        echo "- 唯一開發者 → 選擇同步 .git（選項 1）"
        echo "- 團隊協作 → 選擇排除 .git（選項 2）"
        echo "- 在多台電腦開發 → 謹慎選擇，避免同時操作"
        echo ""
        echo "無論選擇哪個，都應該："
        echo "✓ 定期 git push 到 GitHub"
        echo "✓ 設定備份策略"
        echo "✓ 了解恢復程序"
        ;;
    4)
        echo "已取消"
        ;;
    *)
        echo "無效的選項"
        ;;
esac

# 顯示備份建議
if [ "$choice" = "1" ] || [ "$choice" = "2" ]; then
    echo ""
    echo "💾 快速備份指令："
    echo "git bundle create backup_$(date +%Y%m%d).bundle --all"
fi 