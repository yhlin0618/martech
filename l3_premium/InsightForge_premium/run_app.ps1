# InsightForge Shiny App 啟動腳本
# 適用於 Windows PowerShell

Write-Host "🚀 啟動 InsightForge 行銷分析平台..." -ForegroundColor Green

# 檢查是否在正確的目錄
if (!(Test-Path "app.R")) {
    Write-Host "❌ 找不到 app.R 文件，請確保在 InsightForge 目錄中運行此腳本" -ForegroundColor Red
    Read-Host "按任意鍵退出..."
    exit
}

# 設定參數
$port = 3838
$host = "0.0.0.0"

Write-Host "📊 配置資訊:" -ForegroundColor Yellow
Write-Host "   - 端口: $port" -ForegroundColor White
Write-Host "   - 主機: $host" -ForegroundColor White
Write-Host "   - 網址: http://localhost:$port" -ForegroundColor Cyan

Write-Host ""
Write-Host "🌐 應用程式即將啟動，請稍候..." -ForegroundColor Green
Write-Host "💡 啟動後請在瀏覽器中訪問: http://localhost:$port" -ForegroundColor Cyan
Write-Host "🛑 要停止應用程式，請按 Ctrl+C" -ForegroundColor Yellow
Write-Host ""

# 運行 Shiny 應用
try {
    Rscript -e "shiny::runApp(port = $port, host = '$host')"
}
catch {
    Write-Host "❌ 啟動失敗: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "按任意鍵退出..."
} 