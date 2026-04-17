# VitalSigns 啟動腳本
Write-Host "🚀 啟動 VitalSigns 精準行銷平台..." -ForegroundColor Green

if (!(Test-Path "app.R")) {
    Write-Host "❌ 找不到 app.R 文件" -ForegroundColor Red
    exit
}

$port = 3839
Write-Host "📊 端口: $port" -ForegroundColor Yellow
Write-Host "🌐 網址: http://localhost:$port" -ForegroundColor Cyan

Write-Host ""
Write-Host "🔧 數據庫修復 & 功能更新:" -ForegroundColor Magenta
Write-Host "   ✅ 修復數據庫連接問題 (<<- 運算符)" -ForegroundColor Green
Write-Host "   ✅ 修復PostgreSQL參數轉換邏輯" -ForegroundColor Green
Write-Host "   ✅ 修復表格生成錯誤 (二維數據檢查)" -ForegroundColor Green
Write-Host "   ✅ PostgreSQL/SQLite 跨數據庫兼容" -ForegroundColor Green
Write-Host "   ✅ 移除時間折扣因子UI" -ForegroundColor Green
Write-Host "   ✅ 表格欄位中文化" -ForegroundColor Green
Write-Host "   ✅ 顧客活躍度增強顯示" -ForegroundColor Green
Write-Host "   ✅ 高中低文字轉換選項" -ForegroundColor Green

Write-Host ""
Write-Host "🔄 啟動中..." -ForegroundColor Blue

try {
    R -e "shiny::runApp(port = $port, host = '0.0.0.0')"
} catch {
    Write-Host "❌ 啟動失敗，請檢查R環境" -ForegroundColor Red
} 