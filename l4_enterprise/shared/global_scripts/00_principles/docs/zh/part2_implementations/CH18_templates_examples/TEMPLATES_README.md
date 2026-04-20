# 實作範本庫 (Implementation Templates)

此目錄包含實作原則和規則的代碼範本。這些範本提供標準化的起點，幫助開發者正確實施文檔化的原則。

⭐ **IMPORTANT UPDATE (2025-08-28)**: The five-part script structure is now the PRIMARY STANDARD. All new scripts MUST use the five-part template. Four-part templates are maintained for legacy compatibility only.

## 📁 目錄結構

### development/ - 開發範本
- **template_update_script_five_part.R** - ⭐ **五部分更新腳本結構範本（PRIMARY STANDARD - 實作 DEV_R033, MP104）**
  - INITIALIZE、MAIN、TEST、**SUMMARIZE**、DEINITIALIZE 結構
  - 完全解決 autodeinit() 變數存取問題
  - 清晰的關注點分離
- **template_update_script_four_part_LEGACY.R** - ⚠️ 四部分更新腳本結構範本（LEGACY - 僅供向後相容）
  - INITIALIZE、MAIN、TEST、DEINITIALIZE 結構（已知有 autodeinit 問題）
  - 保留用於現有腳本維護
- **fn_function_template.R** - 函數檔案範本（實作 R021, R069）
- **sc_global_scripts_template.R** - 全域腳本範本
- **sc_update_scripts_template.R** - 更新腳本範本

> **Note**: RC01-RC05 Rule Composite 文檔已移至 `principles_qmd/docs/en/part2_implementations/CH18_templates_examples/`

### testing/ - 測試範本
（待添加測試相關範本）

### deployment/ - 部署範本
（待添加部署相關範本）

### shiny/ - Shiny 應用範本
（待添加 Shiny 模組和應用範本）

## 🔗 使用方式

1. **選擇適當的範本**：根據您的需求從相應目錄選擇範本
2. **複製範本**：將範本複製到您的工作目錄
3. **自訂內容**：根據範本中的 TODO 和註釋進行修改
4. **遵循原則**：確保修改後的代碼仍然符合相關原則

## 📋 範本與原則對應

| 範本檔案 | 實作原則 | 狀態 | 位置 |
|---------|---------|------|------|
| template_update_script_five_part.R | DEV_R033, MP104 | ⭐ PRIMARY | development/ |
| template_update_script_four_part_LEGACY.R | DEV_R032 | ⚠️ LEGACY | development/ |
| fn_function_template.R | R021, R069 | CURRENT | development/ |
| sc_global_scripts_template.R | - | CURRENT | development/ |
| sc_update_scripts_template.R | - | CURRENT | development/ |

### Rule Composites (已移至文檔系統)
| 文檔 | 描述 | 新位置 |
|------|------|--------|
| RC01 | Function File Template | principles_qmd/.../CH18_templates_examples/ |
| RC02 | App Test File Template | principles_qmd/.../CH18_templates_examples/ |
| RC03 | App Component Template | principles_qmd/.../CH18_templates_examples/ |
| RC04 | Package Documentation | principles_qmd/.../CH18_templates_examples/ |
| RC05 | Cross Project References | principles_qmd/.../CH18_templates_examples/ |

## ⚠️ 重要提醒

- **新腳本必須使用五部分結構範本** (template_update_script_five_part.R)
- 四部分範本僅用於維護現有腳本
- 範本是起點，不是最終解決方案
- 始終根據具體需求調整範本
- 保持與最新原則文檔同步
- 範本中的 TODO 項目必須完成

## 🔄 從四部分遷移到五部分

1. 保持 INITIALIZE、MAIN、TEST 不變
2. 將 DEINITIALIZE 分為兩部分：
   - 所有報告和返回值準備移至新的 SUMMARIZE（第4部分）
   - 只保留清理和 autodeinit() 在 DEINITIALIZE（第5部分）
3. 更新部分編號和註釋
4. 測試 autodeinit() 現在確實是最後操作

## 🔄 貢獻新範本

新增範本時：
1. 放置在適當的子目錄中
2. 在範本頂部註明實作的原則
3. 更新此 README 的對應表
4. 包含清晰的使用說明和 TODO 標記

---

最後更新：2025-08-28

## 📚 參考資料

- [MP104: Script Organization Evolution](../../part1_principles/CH00_fundamental_principles/02_structure_organization/MP104_script_organization_evolution.qmd)
- [DEV_R033: Five-Part Script Structure](../../part1_principles/CH03_development_methodology/rules/DEV_R033_five_part_script_structure.qmd)
- [MP103: autodeinit Behavior](../../part1_principles/CH00_fundamental_principles/02_structure_organization/MP103_autodeinit_behavior.qmd)