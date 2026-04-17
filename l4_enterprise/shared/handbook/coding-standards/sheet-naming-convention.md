# Google Sheet Tab 命名標準

> **適用範圍**: 所有公司專案的 Google Sheet ETL source(comment_properties、product_profiles 等）

## 格式

```
{product_line_id}_{english-name-kebab}
```

- `product_line_id`: 3 字元代碼,與 `df_product_line.csv` 的 `product_line_id` 欄位一致
- `english-name-kebab`: 英文名全小寫,空格改連字號 `-`
- 兩者用半形底線 `_` 連接

## 範例

| product_line_id | Tab 名稱 |
|-----------------|----------|
| hsg | `hsg_hunting-safety-glasses` |
| sfg | `sfg_safety-glasses` |
| sfo | `sfo_safety-glasses-fit-over` |
| blb | `blb_blue-light-blocking-glasses` |
| its | `its_infant-toddler-sunglasses` |
| rpl | `rpl_replacement-lens` |
| tur | `tur_turbo`（MAMBA 範例） |

## 規則

1. **不加用途前綴** — 不要寫 `comment_property_blb_...`。Google Sheet 文件名已經包含用途（例如 `comment_property_QEF_DESIGN`），tab 只需要區分 product line
2. **不加中文** — 避免全形/半形符號混用（例如 `＿` vs `_`）造成 ETL 匹配失敗
3. **不加後綴** — 不要寫 `...水準表`。這是歷史遺留,沒有資訊量
4. **用半形符號** — 底線 `_`、連字號 `-`,不要用全形 `＿`
5. **product_line_id 在最前面** — ETL 用 prefix 或精確匹配,ID 在前保證唯一性

## 為什麼

以前的 tab 命名沒有標準,混用全形底線、半形底線、括號、大寫駝峰、中文 + 英文等:

```
安全眼鏡＿hunting-safety-glasses水準表     ← 全形底線
太陽眼鏡_BaseballYouth_水準表              ← 半形底線 + CamelCase
安全眼鏡＿safety-glasses(fit over)水準表   ← 括號 + 空格
```

這導致 ETL 腳本必須用 fuzzy matching（中文 anchor + 英文關鍵字評分）來猜測哪個 tab 對應哪個 product line,經常猜錯或漏掉。

統一命名後,ETL 改用精確匹配:csv 裡寫什麼 tab 名,就讀什麼 tab,找不到就直接停住報錯,不再靜默跳過。

## 怎麼改

1. 打開 Google Sheet
2. 右鍵 tab → 重新命名 → 照上面的格式改
3. 改完後確認 `df_product_line.csv` 的 `comment_property_sheet_tab` 欄位一致
4. 跑一次 ETL 驗證:`make run TARGET=amz_ETL_comment_properties_0IM`

## 新增 product line 時

1. 在 Google Sheet 新增 tab,命名格式:`{新id}_{english-name-kebab}`
2. 在 `df_product_line.csv` 新增一行,`comment_property_sheet_tab` 填入 tab 名稱
3. 跑 ETL 驗證
