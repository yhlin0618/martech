# ISSUE_117: AI Strategy Naming Consistency Issue

## Issue Description
AI策略：訴求、改善、改變要有四個策略訴求，名稱要一致

The AI strategy analysis should use four consistent dimensions:
- 訴求 (Appeal)
- 改善 (Improvement)
- 改變 (Change)
- 劣勢 (Weakness)

## Current State Analysis

### File Location
`scripts/global_scripts/10_rshinyapp_components/position/positionStrategy/positionStrategy.R`

### Current Implementation

The system currently uses **inconsistent naming** for the four strategy dimensions:

#### Internal Variable Names (Lines 269-278)
```r
argument_factors    # 訴求 - Strengths to emphasize
improvement_factors # 改善 - Areas needing improvement
weakness_factors    # 劣勢 - Weaknesses to address
changing_factors    # 改變 - Strategic changes needed
```

#### Quadrant Data Structure (Lines 770-773)
```r
argument_factors    # 訴求 - 可以強調的優勢
improvement_factors # 改善 - 可以改善的地方
weakness_factors    # 劣勢 - 需要解決的弱點
changing_factors    # 改變 - 需要調整的關鍵因素
```

#### AI Prompt Structure (Lines 790-801)
```markdown
### 訴求策略      # Maps to argument_factors
### 改善策略      # Maps to improvement_factors
### 劣勢應對      # Maps to weakness_factors
### 關鍵調整      # Maps to changing_factors
```

#### Visualization Labels (Lines 883-885)
Chinese: `"訴求", "改善", "劣勢", "改變"`
English: `"Argument", "Improvement", "Weakness", "Change"`

## Issues Found

### 1. Naming Inconsistency
The English terms don't match between internal variables and display:
- "Argument" vs "訴求" (Appeal would be more accurate)
- "Changing" vs "改變" (Change is correct)

### 2. Strategy Prompt Inconsistency
The AI prompt uses different terms than the quadrant labels:
- 訴求策略 vs 訴求
- 改善策略 vs 改善
- 劣勢應對 vs 劣勢
- 關鍵調整 vs 改變

### 3. English Translation Issues
- "Argument" is not the best translation for "訴求" (should be "Appeal")
- The variable name `argument_factors` doesn't align well with the Chinese concept

## Current AI Prompt (Lines 786-807)

```r
content = paste0(
  "根據四象限策略分析結果，為該產品提供具體的行銷策略建議。請使用以下 markdown 架構，但**只顯示該產品實際有因素的部分**：",
  "\n\n## 產品策略分析",
  "\n\n### 訴求策略",
  "\n（僅當 argument_factors 有內容時顯示此部分）",
  "\n基於該產品的優勢因素，建議如何在行銷中突出這些優勢。",
  "\n\n### 改善策略",
  "\n（僅當 improvement_factors 有內容時顯示此部分）",
  "\n基於可改善因素，提出產品優化方向。",
  "\n\n### 劣勢應對",
  "\n（僅當 weakness_factors 有內容時顯示此部分）",
  "\n基於弱勢因素，建議如何在行銷中減少負面影響。",
  "\n\n### 關鍵調整",
  "\n（僅當 changing_factors 有內容時顯示此部分）",
  "\n基於需要改變的因素，提出重點改進建議。",
  "\n\n**重要規則**：",
  "\n- 如果某個象限沒有因素（空白或無內容），請完全跳過該部分的標題和內容",
  "\n- 針對具體的因素變數提供實用的策略建議和廣告文案方向",
  "\n- 保持 markdown 格式，不要用程式碼區塊包起來",
  "\n- 字數限制300字內",
  "\n\n四象限分析資料：", strategy_txt
)
```

## Recommendations

### 1. Standardize Naming Convention

For consistency, recommend using these four dimensions:

**Chinese (Primary)**:
1. 訴求 (Appeal) - Strengths to emphasize
2. 改善 (Improvement) - Areas to improve
3. 劣勢 (Weakness) - Weaknesses to address
4. 改變 (Change) - Changes needed

**English (Aligned)**:
1. Appeal (not Argument)
2. Improvement
3. Weakness
4. Change (not Changing)

### 2. Update Variable Names
```r
# From:
argument_factors -> appeal_factors
changing_factors -> change_factors

# Keep:
improvement_factors
weakness_factors
```

### 3. Align AI Prompt Headers
Keep the prompt headers consistent with quadrant labels:
```markdown
### 訴求
### 改善
### 劣勢
### 改變
```

Or if more descriptive headers are needed:
```markdown
### 訴求策略
### 改善方向
### 劣勢應對
### 改變重點
```

### 4. Update English Labels in Plot
Change line 885:
```r
# From:
c("Argument", "Improvement", "Weakness", "Change")
# To:
c("Appeal", "Improvement", "Weakness", "Change")
```

## Principle Compliance

This issue relates to:
- **MP056**: Connected Component Principle - Components should maintain consistent interfaces
- **R072**: Component ID Consistency - Maintain consistency across component elements
- **MP064**: ETL-Derivation Separation - Clear separation of data transformation and display logic

## Resolution Status

**Status**: DOCUMENTED - Awaiting implementation
**Date Found**: 2025-01-22
**Found By**: Principle-Debugger Agent
**Priority**: Medium - Affects user experience and AI output consistency