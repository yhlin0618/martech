#!/bin/bash
# 推送 positioning_app 到它自己的 GitHub repository

echo "🚀 推送 positioning_app 到獨立 repository..."

# 檢查是否在正確的目錄
if [ ! -f ".gitrepo" ]; then
    echo "❌ 錯誤：請在 positioning_app 目錄中執行此腳本"
    exit 1
fi

# 移到主倉庫根目錄
cd ../..

# 確認在主倉庫根目錄
if [ ! -d "l1_basic/positioning_app" ]; then
    echo "❌ 錯誤：無法找到主倉庫根目錄"
    exit 1
fi

echo "📍 當前目錄：$(pwd)"

# 檢查是否有未提交的變更
if ! git diff-index --quiet HEAD --; then
    echo "⚠️  發現未提交的變更，先提交到主倉庫..."
    git add l1_basic/positioning_app/
    read -p "請輸入提交訊息: " commit_msg
    git commit -m "$commit_msg"
    git push origin main
fi

# 推送 subrepo
echo "📤 推送 positioning_app subrepo..."
git subrepo push l1_basic/positioning_app

echo "✅ 完成！positioning_app 已推送到 git@github.com:kiki830621/positioning_app.git"
echo ""
echo "📋 下一步："
echo "1. 前往 Posit Connect Cloud"
echo "2. 選擇 repository: kiki830621/positioning_app"
echo "3. 選擇 branch: main"
echo "4. 選擇 app path: . (根目錄)"
echo "5. 選擇 main file: app.R"
