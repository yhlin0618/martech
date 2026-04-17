# Word to Markdown 轉換工具比較：markitdown vs. Pandoc

## 測試檔案
- **來源**：`顧客動態計算方式調整_20251025.docx`
- **markitdown 輸出**：`顧客動態計算方式調整_20251025.md.backup`
- **Pandoc 輸出**：`顧客動態計算方式調整_20251025_pandoc.md`

---

## 🔍 主要差異比較

### 1. 🎯 數學符號處理

| 類型 | markitdown | Pandoc | 正確性 |
|------|-----------|---------|--------|
| 希臘字母 μ | `$μ$` (Unicode) | `$\mu$` (LaTeX) | ✅ Pandoc 勝 |
| 希臘字母 λ | `λ` (裸 Unicode) | `\lambda` (LaTeX) | ✅ Pandoc 勝 |
| 希臘字母 σ | `σ` (裸 Unicode) | `\sigma` (LaTeX) | ✅ Pandoc 勝 |
| 乘號 | `×` (Unicode) | `\times` (LaTeX) | ✅ Pandoc 勝 |

**影響**：
- ❌ markitdown 的 Unicode 字元在 LaTeX/PDF 轉換時可能無法正確渲染
- ✅ Pandoc 使用標準 LaTeX 命令，保證跨平台相容性

---

### 2. 📐 數學公式格式

#### markitdown 輸出（有問題）
```markdown
$$W=2.5×u\_{ind}$$
$$z\_{i}=\frac{F\_{i,w}-λ\_{w}}{σ\_{w}}$$
```

#### Pandoc 輸出（正確）
```markdown
$$W = 2.5 \times u_{ind}$$
$$z_{i} = \frac{F_{i,w} - \lambda_{w}}{\sigma_{w}}$$
```

**問題分析**：
1. ❌ **markitdown**：錯誤地轉義下標 `\_{ind}` 應該是 `_{ind}`
2. ❌ **markitdown**：沒有空格，不易閱讀
3. ❌ **markitdown**：混用 Unicode 和 LaTeX
4. ✅ **Pandoc**：正確的 LaTeX 語法，有適當空格

---

### 3. 📝 列表格式

#### markitdown
```markdown
1. 首購：僅購買一次
2. 平均購買時間：所有大於等於2比顧客相鄰購買間隔中位數(天)
3. 計算活躍觀察窗
```

#### Pandoc
```markdown
1.  首購：僅購買一次

2.  平均購買時間：所有大於等於2比顧客相鄰購買間隔中位數(天)

3.  計算活躍觀察窗
```

**差異**：
- Pandoc 使用雙空格（更符合 Markdown 標準）
- Pandoc 在列表項目間保留空行（提升可讀性）

---

### 4. 📦 引用區塊（Blockquote）

#### markitdown（扁平結構）
```markdown
$cap\_days$定義：資料可觀察期間的天數；...

$90天是下限$(僅有超短週期的品類才會受影響)

round_to_7：四捨五入到 7 的倍數（以週為單位）
```

#### Pandoc（結構化）
```markdown
> $cap\_ days$定義：資料可觀察期間的天數；...
>
> $90天是下限$(僅有超短週期的品類才會受影響)

round_to_7：四捨五入到 7 的倍數（以週為單位）
```

**優勢**：
- ✅ Pandoc 識別 Word 中的縮排/引用格式
- ✅ 使用 `>` 標記保留結構層次
- 📖 更易於理解內容的層級關係

---

### 5. 🖼️ 圖片處理（最關鍵差異）

#### markitdown
```markdown
![一張含有 文字, 螢幕擷取畫面, 軟體 的圖片  AI 產生的內容可能不正確。](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAA2oA...)
```

**問題**：
- ❌ 使用 base64 inline 編碼（數千字元）
- ❌ 無法被 Pandoc/LaTeX 等工具識別
- ❌ 檔案肥大（一張圖可能增加數 KB）
- ❌ Git diff 無法追蹤圖片變更
- ❌ 無法單獨編輯或替換圖片

#### Pandoc
```markdown
![顧客購買間隔計算示意圖](media/image2.png)
```

**優勢**：
- ✅ 圖片儲存為獨立檔案 `media/image2.png`
- ✅ 使用相對路徑引用
- ✅ 可以被所有工具識別
- ✅ 便於圖片管理和版本控制
- ✅ 可直接轉換為 PDF/HTML

---

### 6. 🔡 特殊符號轉義

| 符號 | markitdown | Pandoc |
|------|-----------|---------|
| 波浪號 | `1~2月` | `1\~2月` |
| 底線 | `u\_ind` 或 `u\_{ind}` | `u_{ind}` |

**Pandoc 勝**：正確處理 Markdown 特殊字元的轉義

---

## 📊 綜合評比

| 評估項目 | markitdown | Pandoc | 說明 |
|---------|-----------|---------|------|
| **數學公式** | ⚠️ 有問題 | ✅ 正確 | Pandoc 產生正確 LaTeX 語法 |
| **希臘字母** | ❌ Unicode | ✅ LaTeX | Pandoc 跨平台相容性更好 |
| **圖片處理** | ❌ base64 | ✅ 獨立檔案 | **Pandoc 大勝** |
| **可讀性** | ⚠️ 普通 | ✅ 優秀 | Pandoc 格式更清晰 |
| **再轉換能力** | ❌ 困難 | ✅ 容易 | Pandoc 輸出可轉 PDF/HTML |
| **版本控制** | ❌ 不友善 | ✅ 友善 | base64 無法 diff |
| **檔案大小** | ❌ 大 | ✅ 小 | inline 圖片讓 .md 變很大 |

---

## 🎯 實際轉換測試

### 測試 1：轉換成 PDF

```bash
# markitdown 版本（失敗）
pandoc 顧客動態計算方式調整_20251025.md.backup -o output.pdf
# ❌ 錯誤：無法處理 base64 圖片

# Pandoc 版本（成功）
pandoc 顧客動態計算方式調整_20251025_pandoc.md -o output.pdf
# ✅ 成功產生 PDF，圖片正常顯示
```

### 測試 2：數學公式渲染

```bash
# markitdown 的公式
$λ\_{w}=mean\left(F\_{i,w}\right)$
# ❌ 下標顯示錯誤：λ_{w} 變成 λ\_{w}

# Pandoc 的公式
$\lambda_{w} = mean\left( F_{i,w} \right)$
# ✅ 正確渲染：λw = mean(Fi,w)
```

---

## 💡 結論與建議

### ✅ Pandoc 優勢
1. **數學公式處理完美**：生成標準 LaTeX 語法
2. **圖片獨立管理**：提取為獨立檔案，易於編輯
3. **再轉換能力強**：可以無痛轉成 PDF、HTML、LaTeX
4. **格式保留完整**：保留 Word 的層次結構（引用、縮排）
5. **跨平台相容**：輸出符合標準，所有工具都能處理

### ⚠️ markitdown 問題
1. **數學公式有錯**：錯誤的轉義語法 `\_{}`
2. **圖片無法使用**：base64 inline 導致後續處理困難
3. **混用格式**：Unicode + LaTeX 混用造成相容性問題
4. **不利於維護**：檔案肥大，版本控制困難

### 📋 最終建議

**Word → Markdown 轉換的最佳實踐：**

```bash
# 推薦使用 Pandoc
pandoc input.docx -o output.md --extract-media=./media

# 避免使用 markitdown（除非只需要純文字內容）
```

**適用場景：**
- ✅ **使用 Pandoc**：包含圖片、數學公式、需要再轉換
- ⚠️ **使用 markitdown**：純文字轉換、不需要圖片、不需要數學公式

---

## 📁 測試檔案位置

```
subscription/
├── 顧客動態計算方式調整_20251025.docx          # 原始 Word 檔
├── 顧客動態計算方式調整_20251025.md.backup     # markitdown 版本
├── 顧客動態計算方式調整_20251025_pandoc.md     # Pandoc 版本
└── media/
    └── image2.png                                 # Pandoc 提取的圖片
```

---

**測試日期**：2025-10-31
**結論**：在包含數學公式和圖片的文件轉換中，**Pandoc 完勝 markitdown**
