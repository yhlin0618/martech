#### 上傳資料說明

以下為上傳評論資料時所需遵循的格式與欄位說明，請依照範例檔案準備您的資料。

------------------------------------------------------------------------

##### 一、檔案格式

-   **檔案類型**：Excel 檔（.xlsx）或 CSV 檔（.csv）
-   **工作表**：若為 Excel，請將資料放在第一個工作表（Sheet1）\
-   **編碼**：UTF-8\
-   **標題列**：請確保第一列為欄位名稱，不要有空白列

------------------------------------------------------------------------

##### 二、欄位說明

| 欄位名稱 | 資料型態 | 必填 | 說明 |
|----|----|----|----|
| `Variation` | 字串 | 是 | 商品唯一識別碼（如 Amazon ASIN），不可重複或留空 |
| `Title` | 字串 | 是 | 評論標題，簡短扼要；長度建議 10～100 字元 |
| `Body` | 字串 | 是 | 評論內容，完整陳述使用心得；長度建議 50～1000 字元 |
| ... |  |  |  |

------------------------------------------------------------------------

##### 三、範例資料

| Variation | Title | Body | ... |
|----|----|----|----|
| B000CRV48I | It’s a good product. Thanks. | I like the way that cuts the cans. |  |
| B0000CGQD4 | Cheap | Save your money and spend a little extra for a better machine—you’ll thank yourself. |  |
| B000CRV48I | Well known Brand name product | I have been using this electric can opener for years and it never fails to impress me. |  |
| B0000CGQD4 | Works great | I hate can openers—most are a pain in the butt—this one is surprisingly smooth. |  |
| B0000CGQD4 | never worked | Another lemon from Amazon! Arrived today and it doesn’t turn on at all. |  |

------------------------------------------------------------------------

##### 四、注意事項

1.  **必要欄位確認**：請務必確認資料包含必要欄位，不要刪除必要欄位。\
2.  **空值檢查**：所有必填欄位均不可為空；如有缺少請先補齊再上傳。\
3.  **重複檢查**：同一筆 `Variation` + `Title` + `Body` 不可重複。\
4.  **字元編碼**：CSV 檔請以 UTF-8 編碼儲存，避免中文亂碼。\
5.  **檔名命名**：建議命名為 `reviews_上傳日期.xlsx` 或 `reviews_YYYYMMDD.csv`。

------------------------------------------------------------------------
