# OpenAI 整合相關工作時

**使用時機**: 修改 OpenAI API 設定、更新模型版本、調整 prompt 配置、新增 AI 功能時

---

## 必須查閱 `/openai-docs-guide`

**在進行任何 OpenAI 相關設定或開發之前**，必須先執行 `/openai-docs-guide` 查詢最新狀況。

### 何時觸發

| 情境 | 必須查閱 |
|------|----------|
| 更新 `ai_prompts.yaml` 中的 `model` 欄位 | 確認模型名稱和可用性 |
| 新增 prompt template | 確認 API 參數最佳實踐 |
| 修改 `fn_chat_api.R` 或 `fn_response_api.R` | 確認 API endpoint 和參數規格 |
| 切換 API 模式（Chat → Response API） | 確認最新 API 推薦用法 |
| 遇到 API 錯誤（401/429/500） | 確認錯誤處理最佳實踐 |
| 評估新模型（如 GPT-5.2 → 更新版本） | 確認模型能力和定價 |

### 查詢方式

```
/openai-docs-guide <你的問題>
```

範例：
- `/openai-docs-guide` 查詢目前最新可用模型列表
- `/openai-docs-guide` Chat Completions API 最新參數
- `/openai-docs-guide` Response API vs Chat API 差異

### 為什麼

- OpenAI API 更新頻繁，模型名稱和參數會變
- 避免使用已棄用的模型或 API 端點
- 確保 prompt 配置符合最新最佳實踐

---

## ai_prompts.yaml 為 AI 模型的唯一真實來源

**`30_global_data/parameters/scd_type1/ai_prompts.yaml`** 是所有 AI 模型選擇與 prompt 配置的 **single source of truth**。

### 規則

1. **禁止 hardcode 模型名稱** — R 程式碼中不可寫死 `"gpt-5.2"` 或任何模型名稱，必須從 `ai_prompts.yaml` 的 `model` 欄位讀取
2. **新增 AI 功能必須註冊** — 任何新的 AI insight 元件都必須在 `ai_prompts.yaml` 中新增對應的 prompt 區塊（含 `model`、`system_prompt`、`user_prompt_template`）
3. **統一換模型只改一處** — 要切換模型版本時，只需修改 `ai_prompts.yaml` 中的 `model` 欄位，所有引用該 prompt 的元件自動連動
4. **model_selection_guide 同步更新** — 修改 `model` 欄位後，必須同步更新檔案底部的 `model_selection_guide` 區塊，保持文件與實際一致

### 連動架構

```
ai_prompts.yaml (唯一真實來源)
  │
  ├─ model: "gpt-5.2"           ← 改這裡，全部連動
  ├─ system_prompt: "..."
  └─ user_prompt_template: "..."
        │
        ▼
fn_load_openai_prompt.R (dot-path 讀取)
  │     prompt <- load_openai_prompt("vitalsigns_analysis.revenue_pulse_insights")
  │     model  <- prompt$model    ← 自動取得模型名稱
  │
  ▼
fn_chat_api.R / fn_response_api.R (API 呼叫)
  │     model = prompt$model      ← 不寫死
  │
  ▼
fn_ai_insight_async.R (非同步 UI 整合)
        setup_ai_insight_server(..., prompt_key = "vitalsigns_analysis.revenue_pulse_insights")
```

### 錯誤做法

```r
# 不好：模型名稱寫死在 R 程式碼中
response <- call_openai(model = "gpt-5.2", messages = msgs)

# 不好：prompt 寫死在 R 函數中
system_msg <- "你是專業的電商行銷顧問..."
```

### 正確做法

```r
# 好：從 ai_prompts.yaml 讀取
prompt <- load_openai_prompt("customer_analysis.activity_insights")
response <- call_openai(model = prompt$model, messages = msgs)
```

---

## AI Prompt 多語系支援 (DEV_R053)

AI prompt 需要 **localization**（在地化），不是 **translation**（翻譯）。

### 兩種機制，不可混用

| 內容類型 | 機制 | 儲存位置 | 範例 |
|---------|------|---------|------|
| UI 標籤（短語） | `translate()` | `ui_terminology.csv` | "Customer Count" → "顧客數" |
| AI Prompt（段落） | `load_openai_prompt(locale=)` | `ai_prompts.yaml` | 完整 system_prompt |

### ai_prompts.yaml locale 格式

```yaml
report_generation:
  integrated_report:
    model: "gpt-5.2"
    system_prompt:
      en: |
        You are a professional e-commerce marketing analyst.
        Generate data-driven insights in English.
      zh_tw: |
        你是專業的電商行銷分析師。
        請用繁體中文生成以資料為基礎的分析報告。
    user_prompt_template:
      en: "Based on the following data: {data_summary}"
      zh_tw: "根據以下資料：{data_summary}"
```

若 `system_prompt` 是純字串（非 locale map），視為預設語言，**向後相容**。

### R 程式碼呼叫

```r
# 好：帶 locale 載入
locale <- if (is_zh_ui) "zh_tw" else "en"
prompt <- load_openai_prompt("report_generation.integrated_report",
                             locale = locale)
# prompt$system_prompt → 已是正確語言的字串

# 壞：在 R 裡寫雙語 wrapper
report_text <- function(en, zh) if (is_zh_ui) zh else en  # 禁止
```

### 為什麼不用 translate() 管 AI prompts？

1. Prompt 是**語意完整的段落**，不是可逐詞翻譯的標籤
2. 中英版 prompt 的**結構可能完全不同**（指令順序、語氣、額外約束）
3. Prompt 含 `{template_vars}`，需要跟 model 選擇綁在一起
4. zh_tw prompt 需要額外約束（如「避免使用簡體詞彙」），這不是翻譯問題

### zh_tw prompt 必須遵守 UI_R025

所有中文 prompt 適用臺灣正體中文用語規範：
- 泛指 data 時用「資料」，不用「數據」（臺灣「數據」偏指統計數字）
- 泛指 user 時用「使用者」，不用「用戶」（臺灣「用戶」偏指帳戶持有人）
- 完整詞彙對照表見 `02-coding.md` UI_R025 區塊

---

## 相關檔案

| 檔案 | 用途 |
|------|------|
| `08_ai/fn_chat_api.R` | Chat Completions API wrapper |
| `08_ai/fn_response_api.R` | Response API wrapper |
| `08_ai/fn_load_openai_prompt.R` | Prompt 載入（dot-path 導航） |
| `08_ai/fn_ai_insight_async.R` | 非阻塞 AI insight 工具 |
| `30_global_data/parameters/scd_type1/ai_prompts.yaml` | **唯一真實來源** — 所有 prompt 模板與模型選擇 |
