# 處理資料查詢時

**使用時機**: 用戶詢問資料問題時

---

## NSQL Confirmation Protocol v3.0

當用戶請求涉及資料查詢或操作時，使用此確認協議。

### 核心原則

1. **AI 寫，人讀**: 用戶只需閱讀和確認，不需學習任何語法
2. **操作順序明確**: 每個操作及其順序必須可見，防止隱含假設
3. **動態確認迴圈**: 透過對話達成共識，而非完美的一次性解析

---

## 確認格式

### Pipeline 格式（預設）

最精確、操作順序明確、最少歧義：

```
我理解您要的是：

Orders
  -> filter(status = 'completed' AND date in [2024-11-01, 2024-11-30])
  -> group(customer_id)
  -> aggregate(total_spent = sum(amount))
  -> sort(total_spent desc)
  -> limit(10)

這樣對嗎？
```

### SQL-like 格式（備用）

適合偏好 SQL 風格的用戶：

```
我理解您要的是：

transform Orders to CustomerRanking
as sum(amount) as total_spent
grouped by customer_id
where status = 'completed' AND date >= '2024-11-01'
ordered by total_spent desc
limit 10

這樣對嗎？
```

### Operation 格式（寫入操作）

用於 CREATE, UPDATE, DELETE 等修改操作：

```
我將執行以下操作：

UPDATE on Customers
with status = 'inactive'
affecting customers where last_purchase < '2024-06-24'

⚠️ 此操作將影響約 1,247 筆資料
⚠️ 此操作無法復原

確認執行嗎？
```

---

## 格式選擇指南

| 場景 | 推薦格式 | 理由 |
|------|----------|------|
| 一般資料查詢 | **Pipeline** | 操作順序明確 |
| 多步驟轉換 | **Pipeline** | 鏈式操作清晰 |
| 用戶偏好 SQL | SQL-like | 更熟悉的格式 |
| 寫入/刪除操作 | **Operation** | 強調影響範圍和警告 |

---

## 歧義消解觸發點

遇到以下情況時，必須先釐清再確認：

1. **模糊時間**: "上個月"、"最近"、"去年" → 詢問具體範圍
2. **未定義業務術語**: "高價值客戶"、"活躍用戶" → 提供定義選項
3. **多義詞**: "銷售"（金額/數量）、"訂單"（筆數/金額）→ 確認語意
4. **隱含聚合**: "各區的銷售" → 確認是總和/平均/計數
5. **操作順序**: "篩選後加總" vs "加總後篩選" → 確認順序

---

## 回應處理

| 用戶回應 | AI 行動 |
|---------|---------|
| "對/是/確認" | 執行操作 |
| "不對，應該是..." | 更新確認並重新呈現 |
| "不是/錯了" | 請求釐清並重新開始 |
| "還要加上..." | 整合新資訊並更新 |

---

## Schema 意識確認

本專案的 schema 定義位於：
- **摘要版**: `00_principles/nsql_schema_summary.yaml`（供 NSQL 確認協議使用）
- **完整版**: `00_principles/docs/en/part2_implementations/CH10_database_specifications/etl_schemas/core_schemas.yaml`

**Schema-Aware 確認流程**：

1. **讀取 schema**：確認前先讀取 `nsql_schema_summary.yaml`
2. **對應表格**：將用戶的自然語言對應到實際表格名稱
3. **驗證欄位**：確保確認中的欄位存在於 schema
4. **顯示可用欄位**：在確認中列出相關表格的可用欄位

**Schema-Aware 確認範例**：

```
用戶：找評分最高的產品

AI 回應：根據 reviews 表，我理解您要的是：

reviews
  -> group(product_id)
  -> aggregate(avg_rating = mean(rating))
  -> sort(avg_rating desc)
  -> limit({N})

可用欄位：review_id, product_id, rating, review_date, review_text
（product_id 對應您說的「產品」）

N = ?（請指定數量）
```

---

## 參考資源

- **協議規範**: `scripts/nsql/protocol.yaml`
- **術語定義**: `scripts/nsql/dictionary.yaml`
- **Schema 摘要**: `00_principles/nsql_schema_summary.yaml`
- **詳細指南**: `scripts/nsql/docs/guide.md`
