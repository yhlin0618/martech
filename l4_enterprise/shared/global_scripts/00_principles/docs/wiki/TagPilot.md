# TagPilot

TagPilot 是客戶分析與名單經營模組。它把同一批客戶的價值、活躍度、流失風險、生命週期與行銷策略整合在一起，方便你從「看懂客戶」一路走到「匯出名單」。

## Tab 一覽

| Tab | 主要用途 | 你會看到什麼 |
|-----|----------|--------------|
| customerValue | 看客戶價值分布 | R/F/M 分布、價值分層、明細表 |
| customerActivity | 看購買節奏變化 | [CAI](Term-CAI) 分布、CAI vs 消費散點圖 |
| customerStatus | 看沉睡與流失風險 | [NES](Term-NES)、P(alive)、高風險名單 |
| customerStructure | 看消費結構與交易穩定度 | [IPT](Term-IPT)、[PCV](Term-PCV)、[CRI](Term-CRI) |
| customerLifecycle | 看未來價值與搶救名單 | [CLV](Term-CLV)、P(alive)、搶救優先名單 |
| rsvMatrix | 看 27 種客戶類型 | [RSV](Term-RSV) 三軸分布、R×S 熱圖 |
| marketingDecision | 看系統推薦的策略 | [行銷策略](Term-Marketing-Strategies) 分布與客戶明細 |
| customerExport | 匯出可執行名單 | 依策略、NES、風險過濾後的匯出表 |
| comprehensiveDiagnosis | AI 客戶綜合診斷 | 一鍵整合 11 項指標的 AI 診斷報告 |

## customerValue

### 顯示內容
- 客戶總數、平均消費、平均購買次數、平均最近購買天數
- High / Medium / Low Value 客戶數與占比
- R、F、M 分布圖與分段圓餅圖
- 依 R、F、M 給出的建議與客戶明細表

### 操作方式
1. 先選平台與產品線。
2. 先看 High / Medium / Low Value 占比，再看 R/F/M 分布。
3. 若想落地執行，可從明細表下載客戶資料。

### 看懂重點
這個 tab 回答的是：**客戶價值分布長什麼樣，價值差異來自最近購買、頻率，還是消費金額？**

## customerActivity

### 顯示內容
- 平均 [CAI](Term-CAI)
- 越來越活躍、穩定、逐漸不活躍三類客戶的數量
- CAI 分布、CAI 指數直方圖、CAI vs 消費散點圖
- CAI 對應的建議與客戶明細表

### 操作方式
1. 先看三類 CAI 客戶占比。
2. 再用散點圖找出「高消費但活躍下降」或「低消費但活躍上升」的客群。
3. 需要行動時，下載明細表做後續追蹤。

### 看懂重點
這個 tab 回答的是：**客戶最近的購買節奏是在升溫、持平，還是在降溫？**

## customerStatus

### 顯示內容
- N、E0、S1、S2、S3 五類 [NES](Term-NES) 客戶 KPI
- NES 分布、流失風險分布、Estimated Days to Churn、P(alive) 分布
- 指標說明卡與高風險客戶名單

### 操作方式
1. 先看 NES 結構，確認主力客與沉睡客的比例。
2. 再看 P(alive) 與 churn 視角，判斷哪些客戶需要優先喚回。
3. 高風險名單可直接下載給 CRM 或再行銷團隊。

### 看懂重點
這個 tab 回答的是：**哪些客戶已經開始沉睡，哪些客戶最有可能流失？**

## customerStructure

### 顯示內容
- 客戶總數、平均 [IPT](Term-IPT)、平均客單、總消費
- 購買週期分布與消費分布
- [PCV](Term-PCV) 與 [CRI](Term-CRI) 的分段圓餅圖
- PCV / CRI 對應的建議與明細表

### 操作方式
1. 先看 IPT 與 Monetary 分布，理解客群的基本購買節奏。
2. 再看 PCV 與 CRI，找出高歷史價值但穩定度不足，或穩定但價值偏低的客群。
3. 將這頁與 customerLifecycle 一起看，能分辨「過去高價值」與「未來高價值」。

### 看懂重點
這個 tab 回答的是：**我的客群交易週期穩不穩、過去價值集中在哪些人身上？**

## customerLifecycle

### 顯示內容
- 平均 [CLV](Term-CLV)、高 CLV 客戶數、平均 P(alive)、平均預期交易次數
- CLV 分布、P(alive) 分布、CLV vs P(alive) 矩陣
- 高價值但低存活機率的 Rescue Priority List
- 完整生命週期預測明細表

### 操作方式
1. 先看 CLV 與 P(alive) 的整體分布。
2. 再看矩陣中「高價值低存活」象限。
3. 最後用 Rescue Priority List 排定搶救順序。

### 看懂重點
這個 tab 回答的是：**哪些客戶未來值錢，哪些高價值客戶正在流失邊緣？**

## rsvMatrix

### 顯示內容
- High Risk、High Stability、High Value 三個 KPI
- Risk / Stability / Value 三個分布圖
- R×S 熱圖，以平均 CLV 呈現 Value 強弱
- 每位客戶的 RSV、策略與 RFM 明細

### 操作方式
1. 先看三個分布圖，掌握整體客群落點。
2. 再看 R×S 熱圖找出「高風險但高價值」或「低風險但低價值」區塊。
3. 需要逐一執行時，再切到 marketingDecision 或 customerExport。

### 看懂重點
這個 tab 回答的是：**如果同時看風險、穩定與價值，客戶最值得先處理的區塊在哪裡？**

## marketingDecision

### 顯示內容
- 四個策略總覽 KPI：喚回、新客培育、養成型策略、VIP / Premium
- 策略分布長條圖
- 每位客戶對應的策略、目的與建議明細

### 操作方式
1. 若只想看某一種策略，可先用上方 Filter Strategy 篩選。
2. 先看各策略的客戶數，再進入明細表。
3. 明細表可匯出，直接交給行銷或 CRM 團隊執行。

### 看懂重點
這個 tab 回答的是：**不同客戶現在最適合哪一種經營策略？**

## customerExport

### 顯示內容
- 客戶總數、可用標籤數、平均 CLV、平均 RFM
- 前 1000 筆匯出預覽
- 欄位說明卡

### 操作方式
1. 先用 Marketing Strategy、Customer Status、Dormancy Risk 三個條件縮小名單。
2. 確認預覽結果後，下載完整 CSV。
3. 匯出表已包含 RFM、NES、RSV、CLV 與策略欄位，適合拿去做再行銷、會員經營或分眾投放。

### 看懂重點
這個 tab 回答的是：**我現在要執行哪一批客戶，名單要怎麼匯出？**

## comprehensiveDiagnosis

### 顯示內容
- 一個提示區塊，說明此頁功能
- 按下左側 AI 分析按鈕後，系統會把 [[RFM|Term-RFM]]、[[CAI|Term-CAI]]、[[NES|Term-NES]]、[[IPT|Term-IPT]]、[[PCV|Term-PCV]]、[[CLV|Term-CLV]]、[[P(alive)|Term-P-alive]]、[[CRI|Term-CRI]]、[[RSV|Term-RSV]] 等 11 項指標的統計摘要送給 AI，生成一份綜合客戶診斷報告

### 操作方式
1. 切換到 comprehensiveDiagnosis tab。
2. 按下左側「AI 分析」按鈕。
3. 等待幾秒後，主面板會出現一份涵蓋所有 DNA 指標的診斷報告。
4. 報告可當作客戶體質檢查的快速總結，也可用來決定下一步該進哪個 tab 深入分析。

### 看懂重點
這個 tab 回答的是：**如果只看一份報告，這群客戶最大的優勢和隱憂是什麼？**

> 此頁不顯示圖表或明細表。它的價值在於把分散在其他 tab 的 11 項指標**整合成一段可閱讀的文字摘要**，適合在會議中快速回顧客戶整體狀態。
