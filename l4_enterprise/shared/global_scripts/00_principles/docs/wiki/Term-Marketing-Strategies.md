# Marketing Strategies — 系統的 13 種行銷策略

## 定義

Marketing Strategies 是 TagPilot 依據客戶狀態自動分派的策略名稱。
它不是單看一個指標，而是綜合 [[NES|Term-NES]]、[[CAI|Term-CAI]]、[[RSV|Term-RSV]]、RFM Score 與 CLV 層級後，用優先順序決定客戶最適合被放進哪一種策略池。

## 數學公式

系統依照下列優先順序分派策略：

1. `NES` 屬於 `S1`、`S2`、`S3` → `Awakening / Return`
2. `CAI < -0.2` 且 `Risk` 為 `Mid` 或 `High` → `Relationship Repair`
3. `Risk = High` → `Cost Control`
4. `NES = N` → `New Customer Nurturing`
5. `RFM Score <= 5` 且 `CLV Level = Low` → `Low-Cost Nurturing`
6. `5 < RFM Score <= 10` 且 `Stability = Low / Mid / High` → `Standard Nurturing (Conservative / Core / Advanced)`
7. `RFM Score > 10` 且 `Stability = Low / Mid / High` → `VIP Maintenance (Low / Mid / High Stability)`
8. `NES = E0` 且 `CLV Level = High` → `Premium Retention`
9. 其餘全部 → `Basic Maintenance`

以上規則一旦前面命中，後面就不再往下判斷。

## 變數說明

| 變數 | 意義 |
|------|------|
| `NES` | 客戶目前的狀態代碼，見 [NES](Term-NES) |
| `CAI` | 活躍度變化，見 [CAI](Term-CAI) |
| `Risk` | 流失風險層級，見 [RSV](Term-RSV) |
| `Stability` | 規律性層級，見 [RSV](Term-RSV) |
| `RFM Score` | 3 到 15 的客戶綜合分數，見 [RFM](Term-RFM) |
| `CLV Level` | 由 CLV 第 20、80 百分位切出的高中低價值層級 |

## 範例

假設某位客戶同時符合下列條件：

- `NES = S1`
- `CAI = -0.35`
- `Risk = High`

雖然他也符合 `Relationship Repair` 和 `Cost Control` 的條件，但系統會先命中第一條：

$$
\text{Strategy} = \text{Awakening / Return}
$$

原因是策略採「優先順序制」，沉睡客會先被放入喚醒池，而不會再被後面的規則覆蓋。

## 儀表板中的位置

- `TagPilot > marketingDecision`：主要策略分布、用途與建議
- `TagPilot > customerExport`：可依策略直接篩選並匯出名單

## R 程式碼實作

### 程式碼摘錄

```r
# 優先順序分派（前面命中就不再往下）
# Priority 1: 沉睡客
df <- assign_strat(df, df$nes_norm %in% c("S1", "S2", "S3"), "Awakening / Return")
# Priority 2: 低活躍 + 中高風險
df <- assign_strat(df, df$cai_low & df$r_level %in% c("Mid", "High"), "Relationship Repair")
# Priority 3: 高風險
df <- assign_strat(df, df$r_level == "High", "Cost Control")
# Priority 4: 新客
df <- assign_strat(df, df$nes_norm == "N", "New Customer Nurturing")
# Priority 5: 低 RFM + 低 CLV
df <- assign_strat(df, df$rfm_score <= 5 & df$clv_level == "Low", "Low-Cost Nurturing")
# Priority 6-7: 中/高 RFM 依穩定性分流
# Priority 8: 主力客 + 高 CLV
df <- assign_strat(df, df$nes_norm == "E0" & df$clv_level == "High", "Premium Retention")
# Priority 9: 其餘
df$strategy[is.na(df$strategy)] <- "Basic Maintenance"

# 策略的顯示內容從 YAML 載入，不寫死在程式碼中
strategies <- yaml::read_yaml("30_global_data/parameters/marketing_strategies.yaml")
```

### 白話解讀

1. **先到先得**：`assign_strat()` 只對尚未被分派策略的客戶生效，所以優先順序很重要——沉睡客一定先被抓走
2. **沉睡客最優先**：不管其他指標多好，只要 NES 是 S1/S2/S3，就直接歸入「喚醒/回流」池
3. **新客有專屬策略**：NES = N 的客戶不會被其他規則搶走，確保新客導入流程完整
4. **RFM 越高的客戶分得越細**：高分客戶會依穩定性再分成保守/核心/進階維護，低分客戶則統一低成本培養
5. **策略名稱和建議內容從 YAML 讀取**：程式碼只管分派邏輯，實際要顯示的中文建議都存在外部檔案，方便非工程人員修改

> **程式碼來源**：`10_rshinyapp_components/tagpilot/fn_rsv_classification.R`（`assign_strategy()` 區段，約第 203–262 行）
