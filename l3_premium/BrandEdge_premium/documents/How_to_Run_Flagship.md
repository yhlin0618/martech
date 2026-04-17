# 如何運行 BrandEdge 品牌印記引擎 - 旗艦版

## 版本資訊
- **當前版本**：v3.2.1 Flagship Edition
- **更新日期**：2025-01-12
- **系統名稱**：品牌印記引擎（原：品牌定位分析平台）

## 快速開始

### 1. 環境準備
```bash
# 進入專案目錄
cd /path/to/BrandEdge_premium

# 確認環境變數設定
cat .env
```

### 2. 執行應用程式
```r
# 在 R Console 中執行
shiny::runApp("app.R")
```

應用程式將在瀏覽器中自動開啟，預設網址：`http://127.0.0.1:####`

## 主要更新（v3.2.1）

### 系統更新
1. **品牌識別更新**
   - 系統名稱更新為「品牌印記引擎」
   - 更清楚體現系統核心價值

2. **功能優化**
   - 移除PCA 3D定位地圖功能
   - 保留8個核心分析模組
   - 優化分析流程

3. **安全增強**
   - 移除登入頁面測試帳號顯示
   - 提升系統安全性

4. **聯絡資訊統一**
   - 所有聯絡方式：partners@peakedges.com

### 旗艦版核心特色

1. **擴展屬性支援**
   - 支援 10-30 個產品屬性（標準版只有 6 個）
   - 動態屬性數量選擇器
   - 智慧屬性萃取

2. **增強的資料限制**
   - 最多 1000 則評論（標準版 100 則）
   - 支援 20 個品牌同時分析
   - 批次評分優化

3. **八大分析功能**
   - 目標市場輪廓（增強版）
   - 市場賽道分析
   - 品牌DNA分析
   - 關鍵因素分析
   - 理想點分析
   - 定位策略建議
   - 品牌識別度策略
   - AI綜合洞察

4. **集中管理系統**
   - UI 提示系統（hint.csv）
   - GPT Prompt 集中管理（prompt.csv）
   - 無需修改程式碼即可更新

## 使用流程

### 步驟 1：登入系統
1. 開啟應用程式
2. 輸入帳號密碼登入
3. 新用戶請先註冊
4. 聯絡支援：partners@peakedges.com

### 步驟 2：資料準備
1. 準備 Excel 或 CSV 檔案
2. 必要欄位：
   - `Variation`：品牌/產品名稱
   - `Title`：評論標題
   - `Body`：評論內容
3. 建議每個品牌至少 50 則評論

### 步驟 3：屬性萃取
1. 選擇要萃取的屬性數量（10-30 個）
2. 系統自動從評論中萃取關鍵屬性
3. 確認屬性列表

### 步驟 4：屬性評分
1. 設定每個品牌的評分樣本數
2. 系統自動進行批次評分
3. 生成品牌屬性分數矩陣

### 步驟 5：分析報告
選擇不同的分析模組查看結果：

#### 📊 市場輪廓
市場區隔與客群分析，透過AI自動為不同客群命名

#### 🚀 市場賽道（重點功能）
**成長機會識別與策略優先級分析**

**如何解讀市場賽道圖表：**
1. **橫軸（成長潛力）**：顯示改善空間大小
   - 越往右：改善空間越大，機會越多
   - 越往左：已接近理想狀態，維持即可

2. **縱軸（市場重要性）**：顯示消費者重視程度
   - 越往上：消費者越重視，影響力越大
   - 越往下：相對次要，可選擇性投資

3. **點的大小**：綜合機會分數
   - 點越大：綜合價值越高
   - 點越小：優先級較低

4. **四個象限的策略建議**：
   - 🟢 **右上（高潛力賽道）**：立即行動，重點投資
   - 🔵 **左上（成熟賽道）**：保持優勢，防禦競爭
   - 🟡 **右下（利基賽道）**：差異化機會，選擇性開發
   - ⚪ **左下（低優先賽道）**：維持基本，資源轉移

**實務應用範例**：
如果您看到「產品品質」在右上角（成長潛力75%、重要性90%），這表示：
- 產品品質是消費者極為重視的屬性（90%重要性）
- 目前表現不佳，有很大改善空間（75%成長潛力）
- 應該立即投入資源改善品質，這將帶來最大的投資回報

#### 🧬 品牌DNA
多維度競爭力分析，雷達圖展示各項能力

#### 🎯 關鍵因素
成功要素識別，找出影響成敗的核心屬性

#### 📍 理想點
目標達成分析，衡量與理想狀態的距離

#### 📈 定位策略
四象限策略建議，明確改善優先順序

#### 🏷️ 識別度策略
差異化分析，建立獨特市場定位

#### 🤖 AI洞察
綜合策略報告，整合所有分析的智慧建議

## 環境需求

### R套件安裝
```r
# 檢查並安裝必要套件
required_packages <- c(
  "shiny", "bs4Dash", "DT", "plotly", 
  "tidyverse", "httr2", "jsonlite",
  "readxl", "markdown", "shinycssloaders",
  "stringr", "dplyr", "bcrypt",
  "DBI", "RSQLite", "RPostgres"
)

# 自動安裝缺失套件
missing_packages <- required_packages[!required_packages %in% installed.packages()[,"Package"]]
if(length(missing_packages) > 0) {
  install.packages(missing_packages)
}
```

### 環境變數配置

創建 `.env` 檔案並設定：
```bash
# OpenAI API
OPENAI_API_KEY=your_api_key_here

# PostgreSQL配置（生產環境）
PGHOST=your_host
PGPORT=5432
PGUSER=your_user
PGPASSWORD=your_password
PGDATABASE=brandedge_db
PGSSLMODE=require
```

或在 R 中設定：
```r
Sys.setenv(OPENAI_API_KEY = "your_api_key_here")
```

## 管理功能

### 管理 UI 提示

1. **查看現有提示**
   ```r
   hints_df <- read.csv("database/hint.csv")
   print(hints_df)
   ```

2. **新增提示**
   編輯 `database/hint.csv`：
   ```csv
   "功能名稱","元素ID","提示說明"
   ```

3. **測試提示系統**
   ```r
   source("test_hint_system.R")
   ```

### 管理 GPT Prompts

1. **查看可用 Prompts**
   ```r
   source("utils/prompt_manager.R")
   prompts_df <- load_prompts()
   list_available_prompts()
   ```

2. **修改 Prompt**
   編輯 `database/prompt.csv`：
   - 使用 `{variable_name}` 定義變數
   - 保持 system/user 結構

3. **測試 Prompt 系統**
   ```r
   source("test_prompt_manager.R")
   ```

## 常見問題

### Q: 為什麼移除了PCA功能？
A: PCA 3D定位圖缺少原點參考，難以提供有效的策略指引，故決定移除此功能，專注於其他更實用的分析模組。

### Q: 市場賽道分析的「成長潛力」是如何計算的？
A: 成長潛力 = (理想值 - 當前表現) / 理想值 × 100%。理想值設定為滿分5分，當前表現來自消費者評論的平均評分。例如某屬性平均分2分，成長潛力就是 (5-2)/5 = 60%。

### Q: 為什麼有些屬性明明表現不錯，但還是被列為優先改善？
A: 這是因為該屬性的「市場重要性」很高。即使目前表現尚可（如3.5分），但如果消費者極度重視（重要性90%以上），仍需要優先提升到更高水準來建立競爭優勢。

### Q: 四象限中哪個最重要？
A: 優先順序如下：
1. **右上（高潛力賽道）**：最優先，投資回報最高
2. **左上（成熟賽道）**：次優先，維持競爭力
3. **右下（利基賽道）**：第三，創造差異化
4. **左下（低優先賽道）**：最後，維持基本即可

### Q: 如何決定要投資多少資源在每個賽道？
A: 建議資源配置比例：
- 高潛力賽道：40-50%資源
- 成熟賽道：20-30%資源（維護性投資）
- 利基賽道：15-20%資源（實驗性投資）
- 低優先賽道：5-10%資源（基本維持）

### Q: 評分需要多久？
A: 取決於樣本數量。50 則評論 × 15 個屬性約需 5-10 分鐘。建議使用批次處理優化。

### Q: 沒有 API 金鑰怎麼辦？
A: 系統會使用模擬模式進行示範，但建議申請 OpenAI API 金鑰以獲得準確結果。

### Q: 如何自訂提示內容？
A: 編輯 `database/hint.csv` 檔案，重新啟動應用程式即可生效。

### Q: 如何修改 GPT 行為？
A: 編輯 `database/prompt.csv` 中對應的 prompt 內容，無需修改程式碼。

### Q: 資料安全如何保障？
A: 
- 所有資料僅在本地處理
- API 調用使用加密傳輸
- 不儲存敏感資訊
- 支援私有部署

## 技術支援

### 錯誤排查步驟

1. **檢查環境變數**
   ```r
   Sys.getenv("OPENAI_API_KEY")
   ```

2. **驗證套件安裝**
   ```r
   sapply(required_packages, require, character.only = TRUE)
   ```

3. **檢查資料格式**
   - 確認必要欄位存在
   - 檢查編碼（建議 UTF-8）
   - 驗證資料完整性

4. **查看錯誤日誌**
   ```r
   options(shiny.trace = TRUE)
   ```

### 效能優化建議

1. **資料量控制**
   - 每次分析不超過 500 則評論
   - 屬性數量控制在 15-20 個

2. **API 調用優化**
   - 使用批次處理
   - 實施請求間隔
   - 監控配額使用

3. **記憶體管理**
   - 定期重啟應用
   - 清理暫存資料
   - 使用適當的資料結構

## 部署指南

### 本地部署
```r
# 開發環境
shiny::runApp("app.R", port = 3838)
```

### 伺服器部署
```r
# Shiny Server
sudo cp -R /path/to/BrandEdge_premium /srv/shiny-server/

# Posit Connect
rsconnect::deployApp(
  appDir = ".",
  appName = "BrandEdge-Flagship"
)
```

### Docker 部署
```dockerfile
FROM rocker/shiny:latest
COPY . /srv/shiny-server/
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
```

## 更新日誌

### v3.2.1 (2025-01-12)
- 移除 PCA 3D定位地圖功能
- 更新系統名稱為「品牌印記引擎」
- 統一聯絡資訊
- 移除測試帳號顯示

### v3.1 (2025-01-11)
- 新增 UI 提示系統
- GPT Prompt 集中管理
- 優化批次處理

### v3.0 (2025-01-07)
- 旗艦版正式發布
- 支援 10-30 個屬性
- 八大分析模組

## 詳細文檔

如需更詳細的系統說明，請參考：
- `BrandEdge_Premium_Documentation.md` - 完整技術文檔
- `System_Enhancement_Guide.md` - 系統增強功能指南
- `Missing_Features_List.md` - 待開發功能清單

## 聯絡資訊

技術支援與商務合作：
- **Email**: partners@peakedges.com
- **系統版本**: v3.2.1 Flagship Edition
- **更新日期**: 2025-01-12

---

*BrandEdge 品牌印記引擎 - 為您的品牌建立獨特市場印記*