#!/bin/bash
# ============================================================================
# 設定全域 Git 忽略規則
# ============================================================================
# 此腳本會設定全域的 gitignore，自動忽略敏感檔案
# ============================================================================

echo "======================================"
echo "   設定全域 Git 忽略規則"
echo "======================================"
echo ""

# 定義全域 gitignore 檔案路徑
GLOBAL_GITIGNORE="$HOME/.gitignore_global"

echo "🔧 設定全域 gitignore 檔案路徑..."
git config --global core.excludesfile "$GLOBAL_GITIGNORE"

echo "📝 創建/更新全域 gitignore 檔案..."

# 創建或追加到全域 gitignore
cat >> "$GLOBAL_GITIGNORE" << 'EOF'

# ============================================
# 環境變數檔案（絕對不要提交）
# ============================================
.env
.env.*
.env.local
.env.development
.env.production
.env.test
.Renviron
.Renviron.*

# ============================================
# 敏感配置檔案
# ============================================
*_secret*
*_private*
*.pem
*.key
credentials*
secrets*
config/secrets*

# ============================================
# API Keys 和 Token
# ============================================
*api_key*
*apikey*
*token*
.httr-oauth*

# ============================================
# 資料庫配置
# ============================================
database.yml
database.json
db_config*
*connection_string*

# ============================================
# R 相關敏感檔案
# ============================================
.Rprofile
rsconnect/
shinyapps/

# ============================================
# Python 相關敏感檔案
# ============================================
venv/
env/
.python-version
pip.conf

# ============================================
# IDE 和編輯器
# ============================================
.vscode/settings.json
.idea/
*.sublime-workspace

# ============================================
# 系統檔案
# ============================================
.DS_Store
Thumbs.db
desktop.ini

# ============================================
# 暫存和快取
# ============================================
*.log
*.tmp
*.temp
*.cache
.cache/
tmp/
temp/

EOF

echo ""
echo "✅ 全域 gitignore 已設定完成！"
echo ""
echo "📍 檔案位置：$GLOBAL_GITIGNORE"
echo ""
echo "🔍 查看目前的全域 Git 設定："
git config --global core.excludesfile
echo ""
echo "📋 已加入的忽略規則："
echo "   • .env 和 .env.* （環境變數檔案）"
echo "   • .Renviron 和 .Renviron.* （R 環境變數）"
echo "   • 各種敏感配置檔案"
echo "   • API keys 和 tokens"
echo "   • 資料庫配置"
echo "   • IDE 設定檔案"
echo ""
echo "⚠️  注意事項："
echo "   1. 這些規則會套用到您所有的 Git 專案"
echo "   2. 個別專案的 .gitignore 仍然有效"
echo "   3. 如需修改，編輯 $GLOBAL_GITIGNORE"
echo ""
echo "🔐 安全提醒："
echo "   永遠不要將包含密碼、API Key 或其他敏感資訊的檔案提交到 Git！" 