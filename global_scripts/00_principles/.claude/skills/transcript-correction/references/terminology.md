# MarTech 會議術語對照表

> AI 模型名稱更新快速，若遇到不確定的模型名，請使用
> `/openai-docs-guide` 或 `/claude-docs-guide` 查詢最新模型清單。

## 語音辨識常見錯誤

### 公司名

| 正確 | 常見錯誤 | 英文代碼 | 備註 |
|------|---------|---------|------|
| 曼巴 | 漫八、慢八、蠻八 | MAMBA | L4 企業版客戶 |
| 向創 | 像創、相創、想創 | QEF | L4 企業版客戶，專案代碼 QEF_DESIGN |
| 好農 | 好濃、豪農 | - | |
| 秩宇 | 智宇、知宇 | - | |
| 技詮科技 | 技全、技銓、技荃 | D-Racing | L4 企業版客戶，品牌 D-Racing |
| kitchenMAMA | kitchen mama | kitchenMAMA | L4 企業版客戶 |
| WISER | wiser、外射 | WISER | L4 企業版客戶 |

### 產品名（保留英文原名）

| 產品 | 可能的錯誤辨識 | 用途 |
|------|---------------|------|
| BrandEdge | Brand Edge、品牌Edge | 品牌定位分析 |
| InsightForge | Insight Forge、因賽Forge | 市場洞察 |
| VitalSigns | Vital Signs、外頭Signs | 營運監控 |
| TagPilot | Tag Pilot、太Pilot | 標籤管理 |
| TagPilot Premium | 同上 | 進階標籤管理 |

### 技術術語

| 正確 | 常見錯誤 | 說明 |
|------|---------|------|
| DuckDB | 大可DB、達可DB | 分析資料庫 |
| DigitalOcean | de-show、地球ocean | 雲端主機平台（已停用，改用 Supabase） |
| Posit Connect | positive connect、波斯Connect | 部署平台 |
| ETL | ETL | Extract-Transform-Load |
| pipeline | 派不來、派破來 | 資料管線 |
| API | API | 應用程式介面 |
| deploy | 低派 | 部署 |
| token | 偷肯、投肯 | API 計費單位 |
| prompt | 破安、普朗 | AI 提示詞 |
| common property | common property | AI 評分屬性 |
| Derivation | derivation | DRV 階段（商業邏輯處理） |

### AI 模型名

> 模型名稱變動頻繁。以下是本專案程式碼中實際使用的模型。
> 不確定時請用 `/openai-docs-guide` 或 `/claude-docs-guide` 查詢。

#### OpenAI 模型（本專案使用中）

| API model ID | 口語念法 | 用途 |
|-------------|---------|------|
| `o4-mini` | o4 mini | AI 評分（fn_process_property_ratings） |
| `gpt-5-mini` | GPT-5 mini | 串流 API（fn_chat_api_stream） |
| `gpt-5-nano` | GPT-5 nano | 聊天 API（chat_api 預設） |
| `gpt-4o-mini` | GPT-4o mini | L1/L2 apps（module_wo_b，較舊） |

#### OpenAI 模型（目前可用，截至 2026-02）

| 系列 | 模型 |
|------|------|
| GPT-5 | GPT-5.2, GPT-5.1, GPT-5 mini, GPT-5 nano |
| GPT-4.1 | GPT-4.1, GPT-4.1 mini, GPT-4.1 nano |
| o 系列 | o4-mini, o3-deep-research, o4-mini-deep-research |
| 舊版 | GPT-4o, GPT-4o-mini, GPT-4, o1, o3-mini |

#### Claude 模型（目前可用，截至 2026-02）

| API model ID | 口語念法 |
|-------------|---------|
| `claude-opus-4-6` | Claude Opus 4.6 |
| `claude-sonnet-4-6` | Claude Sonnet 4.6 |
| `claude-haiku-4-5-20251001` | Claude Haiku 4.5 |
| 舊版：`claude-sonnet-4-5`, `claude-opus-4-5`, `claude-opus-4-1` | |

#### AI 模型名常見辨識錯誤

| 正確 | 常見錯誤 | 備註 |
|------|---------|------|
| Claude | Cloud、克勞德 | |
| Opus | 歐普斯 | |
| Sonnet | 桑奈、桑拿 | |
| GPT | GPT | 通常能正確辨識 |
| o4-mini | o4 mini | 注意不要與 GPT-4o-mini 混淆 |

### 行銷分析術語

| 正確 | 常見錯誤 | 說明 |
|------|---------|------|
| RFM | RFM | Recency, Frequency, Monetary |
| NES | NES | 新客/既有/沈睡分群 |
| DNA 分數 | DNA 分數 | 客戶 DNA 分析 |
| Poisson 分析 | 不松分析、泊松 | 購買頻率模型 |
| 定位矩陣 | 定位距陣 | 品牌定位分析 |
| 精準行銷 | 精準行銷 | Precision Marketing |
| 儀表板 | 儀表板、儀錶板 | Dashboard |
| 評分模型 | 評分模型 | Scoring Model |

### 電商平台名

| 正確 | 常見錯誤 | 程式碼代碼 |
|------|---------|-----------|
| Amazon | 亞馬遜 | amz |
| Cyberbiz | 賽伯比斯 | cbz |
| eBay | eBay | eby |
| Shopee | 蝦皮 | spe |

---

## 團隊成員

已知的團隊成員名字（用於 Speaker 辨識參考）：

| 名字 | 角色 | 備註 |
|------|------|------|
| che (鄭澈) | 開發者 | Plaud 通常能辨識 |
| 林郁翔 | 團隊成員 | Plaud 通常能辨識 |
| hardy (昊紘) | 團隊成員 | 常被辨識為「浩宏」，正確為「昊紘」 |

> 其他成員請根據會議上下文推斷，無法確定時保留 `Speaker N`。

---

## 口語贅詞清單

### 應移除的贅詞

```
嗯、啊、呃、欸
那個、這個、那種
就是說、也就是說（過度重複時）
然後呢、然後、接著（過度重複時）
對不對、對吧、是不是
好、好的（非確認用途時）
這樣子、就這樣
所以說、基本上、其實
你知道、你看
反正就是（過度使用時）
```

### 應保留的語氣詞

```
對（確認回應）
好（轉折用，如「好，那接下來...」）
那（引導用，如「那我們來看...」）
等一下（會議互動）
```
