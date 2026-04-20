# VitalSigns

VitalSigns 是營運健康儀表板。它把營收、成長、留存、互動與地區市場放在同一套視角下，適合用來快速掌握「現在有沒有變好」以及「問題出在哪裡」。

## Tab 一覽

| Tab | 主要用途 | 你會看到什麼 |
|-----|----------|--------------|
| revenuePulse | 看營收健康與集中度 | 營收 KPI、Pareto 80/20、Top 客戶表 |
| macroTrends | 看月度趨勢與成長動能 | 月營收/訂單/客戶趨勢線、MoM/YoY 成長率 |
| customerAcquisition | 看成長與轉換 | 客戶結構圓餅圖、Acquisition Funnel |
| customerRetention | 看留存與沉睡結構 | NES 結構、回購率、風險分析、分狀態策略建議 |
| customerEngagement | 看互動深度與忠誠度 | CAI / IPT / 頻率指標、漏斗、Loyalty Ladder |
| worldMap（全球戰情室） | 看市場分布 | 世界地圖、美國州地圖、國家明細 |
| comprehensiveDiagnosis | AI 營運綜合診斷 | 一鍵整合營收、結構、留存、互動的 AI 報告 |

## revenuePulse

### 顯示內容
- 總營收、ARPU、平均 [CLV](Term-CLV)、交易一致性
- 新客 vs 主力客的 AOV 比較
- CLV 散點圖、Pareto 80/20 曲線、Revenue Segment Distribution
- Top Revenue Customers 明細表

### 操作方式
1. 先看四個 KPI 掌握總體狀態。
2. 再看 Pareto 曲線，確認營收是否過度集中在少數客戶。
3. 需要找關鍵客戶時，查看 Top Revenue Customers。

### 看懂重點
這個 tab 回答的是：**營收健康嗎？收入來自哪些客戶？營收是否過度集中？**

## macroTrends

### 顯示內容
- 最新月份營收、訂單數、月增率 (MoM)、年增率 (YoY)
- 月營收趨勢線圖、月訂單趨勢線圖
- 活躍客戶數趨勢（含新客獨立線）、平均客單價趨勢
- 月度彙總明細表（可下載 CSV）

### 操作方式
1. 先看四個 KPI，掌握最新月份的營收和成長方向。
2. 用趨勢圖看是持續成長、季節波動，還是在走下坡。
3. 活躍客戶圖中的新客線如果與總活躍客戶線同步下降，代表整體成長在衰退。
4. 需要逐月分析時，打開明細表。

### KPI 計算方式

| KPI | 計算公式 | 說明 |
|-----|----------|------|
| MoM Revenue Growth（月增率） | (本月營收 − 上月營收) ÷ 上月營收 × 100% | 正值代表環比成長，負值代表衰退 |
| YoY Revenue Growth（年增率） | (本月營收 − 去年同月營收) ÷ 去年同月營收 × 100% | 排除季節因素後的同期對比 |

> **MoM** 看的是短期動能；**YoY** 看的是長期趨勢。如果 MoM 正成長但 YoY 負成長，通常代表「比上月好但還沒回到去年同期水準」。

### 看懂重點
這個 tab 回答的是：**生意是在成長還是衰退？成長動能是加速還是減速？**

## customerAcquisition

### 顯示內容
- 活躍客戶數、累積客戶數、新客成長率
- Customer Structure 圓餅圖
- Acquisition Funnel：首購、回購、多次購買、核心客
- 客戶明細表

### 操作方式
1. 先看新客比例與重複購買比例。
2. 再用漏斗看首購轉回購、回購轉核心客的落差。
3. 若有地區篩選，可比較不同國家的成長品質。

### KPI 計算方式

| KPI | 計算公式 | 說明 |
|-----|----------|------|
| Customer Growth Rate（新客成長率） | N 人數 ÷ 全體客戶數 × 100% | N 是 [NES](Term-NES) 中的新客，代表新進客戶佔全體的比例 |

> **Customer Growth Rate** 看的是「新血注入的速度」。成長率高代表持續有新客進來；若成長率高但漏斗中回購比例低，代表客人來了卻留不住，需要搭配 Acquisition Funnel 判斷成長品質。

#### R 程式碼實作

以下是儀表板實際計算 Customer Growth Rate 的邏輯（摘自 `customerAcquisition.R`）：

```r
# 從 DNA 資料中計算新客成長率
n_new <- sum(df$nes_status == "N", na.rm = TRUE)
pct <- round(n_new / nrow(df) * 100, 1)
# 結果顯示為 KPI 卡片，例如 "12.3%"
```

**白話解讀**：
- `nes_status == "N"` = [[NES|Term-NES]] 分類中的新客（只有首購、尚無購買節奏）
- 分母是**全體客戶數**（不是某段時間內的客戶，而是資料庫中的所有客戶）
- 所以這個比例代表的是「目前客戶池中，新客佔多少」，不是「本月新增率」

> 對應程式碼位置：`10_rshinyapp_components/vitalsigns/customerAcquisition/customerAcquisition.R`

### Acquisition Funnel 各層

| 漏斗層 | 條件 | 意義 |
|--------|------|------|
| First Purchase | 所有客戶 | 至少買過一次 |
| Repeat Purchase | 購買次數 ≥ 2 | 願意回來再買 |
| Multi-Purchase | 購買次數 ≥ 4 | 成為穩定消費者 |
| Core Customer | [NES](Term-NES) = E0 | 仍在正常購買節奏內的忠實客 |

### 看懂重點
這個 tab 回答的是：**成長有沒有進來？新客會不會變成回購客？**

## customerRetention

### 顯示內容
- 流失率、回購率、核心客占比、預測沉睡客
- N / E0 / S1 / S2 / S3 / 預測沉睡客 KPI
- Customer Structure (NES) 與 Churn Risk Analysis
- 依狀態切分的策略建議頁籤

### 操作方式
1. 先看流失率與回購率。
2. 再看 NES 結構，確認問題集中在新客、主力客，還是沉睡客。
3. 最後切換各狀態頁籤，看每一類客戶的維繫或喚回建議。

### KPI 計算方式

| KPI | 計算公式 | 說明 |
|-----|----------|------|
| Churn Rate（流失率） | (S1 + S2 + S3) ÷ 既有客戶數 × 100% | 既有客戶 = E0 + S1 + S2 + S3（不含新客 N）；各級沉睡客佔既有客戶的比例 |
| Repurchase Rate（回購率） | 時間窗口法：W = 1.5 × 各品類中位 [IPT](Term-IPT)；回購客 = 購買 ≥ 2 次且 IPT ≤ W | 在合理時間窗口內回購的客戶比例，比單純計次更準確 |
| Predicted Dormant（預測沉睡客） | R 值 > 2.5 × [IPT](Term-IPT) 的客戶人數 | 距上次購買時間超過其正常間隔 2.5 倍，高風險即將流失 |

> **流失率**的分母是「既有客戶」（E0 + S1 + S2 + S3），不含新客 N，因為新客還沒有足夠購買歷史來判斷是否流失。流失率持續上升代表客戶基礎正在弱化。
>
> **回購率**使用時間窗口法：先算出每個品類的中位購買間隔（[[IPT|Term-IPT]]），設定合理的回購時間窗口 W = 1.5 × 中位 IPT，然後計算在此窗口內有回購的客戶比例。比起單純計算「買過兩次以上」，這個方法更能反映客戶是否在正常節奏內持續購買。回購率低代表首購客留不住，要配合 customerAcquisition 的轉換漏斗一起看。
>
> **預測沉睡客**（取代舊版的「風險客戶數」）以 [[IPT|Term-IPT]] 為基準：如果客戶距上次購買已超過其正常購買間隔的 2.5 倍，就判定為高風險即將沉睡。

### 看懂重點
這個 tab 回答的是：**客戶留得住嗎？最需要優先保住的是哪一群？**

## customerEngagement

### 顯示內容
- 平均 [CAI](Term-CAI)、平均頻率、平均 [IPT](Term-IPT)
- Activity Scatter、Conversion Funnel、Purchase Pattern
- Loyalty Ladder

### 操作方式
1. 先看 KPI，確認互動整體在升還是降。
2. 用 Activity Scatter 找出高消費但活躍下降的客戶。
3. 用 Loyalty Ladder 規劃下一波互動方案。

### KPI 計算方式

| KPI | 計算公式 | 說明 |
|-----|----------|------|
| Avg [CAI](Term-CAI) | 所有客戶的 CAI 平均值 | 整體購買活躍度變化趨勢（正值代表越來越活躍） |
| Avg Frequency | 平均購買次數 | 客群整體回購次數 |
| Avg [IPT](Term-IPT) | 回購客（F≥2）的平均購買間隔天數 | 客戶多久會再買一次 |

### 看懂重點
這個 tab 回答的是：**客戶互動有多深？哪些人最值得先做活化？**

## worldMap（全球戰情室）

### 顯示內容
- 可切換 Revenue、Order Count、Customer Count、Avg Order Value
- 可切換 World Map / US States
- 總國家數、最大市場、前 3 大市場占比、總營收
- 國家明細表

### 操作方式
1. 先選你要看的 KPI。
2. 若以美國為主，可切到 US States 看州別分布。
3. 再配合國家明細表找出高成長市場與低效率市場。

### 看懂重點
這個 tab 回答的是：**營收與訂單集中在哪些市場？市場擴張機會在哪裡？**

## comprehensiveDiagnosis

### 顯示內容
- 一個提示區塊，說明此頁功能
- 按下左側 AI 分析按鈕後，系統會把營收、客戶結構、留存、互動四大面向的統計摘要送給 AI，生成一份綜合營運診斷報告

### 操作方式
1. 切換到 comprehensiveDiagnosis tab。
2. 按下左側「AI 分析」按鈕。
3. 等待幾秒後，主面板會出現一份涵蓋所有面向的診斷報告。
4. 報告可用來當作管理會議的快速簡報素材，或作為進一步分析的方向指引。

### 看懂重點
這個 tab 回答的是：**如果只看一份報告，整體營運的強項和弱項分別在哪裡？**

> 此頁不顯示圖表或明細表。它的價值在於把分散在其他 tab 的指標**整合成一段可閱讀的文字摘要**，節省逐頁查看的時間。
