# 應用程式名稱配置指南

## 🎯 名稱設定位置

應用程式名稱可以在多個地方設定，取決於您要改變的是什麼：

### 1. 應用程式內部顯示名稱
**檔案**: `app_config.yaml`
```yaml
app_info:
  name: "Positioning App"  # 改這裡來變更應用程式標題
```

### 2. Posit Connect Cloud 名稱
在 Posit Connect Cloud 中，應用程式名稱是在：
- **首次部署時設定**：在 Connect 介面中輸入
- **部署後變更**：在 Posit Connect Cloud 的應用程式設定中修改

### 3. ShinyApps.io 名稱
**檔案**: `app_config.yaml`
```yaml
deployment:
  shinyapps:
    app_name: "positioning_app"  # 改這裡來變更 URL
```
這會影響應用程式的 URL：`https://your-account.shinyapps.io/positioning_app/`

## 📝 變更步驟

### 方法 A：修改內部顯示名稱
1. 編輯 `app_config.yaml`
```yaml
app_info:
  name: "產品定位分析系統"  # 新名稱
```

2. 重新部署應用程式

### 方法 B：修改 Posit Connect Cloud 名稱
1. 登入 [Posit Connect Cloud](https://connect.posit.cloud)
2. 找到您的應用程式
3. 點擊「Settings」
4. 修改「Application Name」
5. 儲存變更

### 方法 C：修改 ShinyApps.io URL
1. 編輯 `app_config.yaml`
```yaml
deployment:
  shinyapps:
    app_name: "product-positioning"  # 新的 URL 名稱
```

2. 重新部署（會創建新的應用程式）

## 🔧 實際範例

### 將三個應用程式改為中文名稱

**positioning_app/app_config.yaml**:
```yaml
app_info:
  name: "產品定位分析"
```

**VitalSigns/app_config.yaml**:
```yaml
app_info:
  name: "客戶生命徵象"
```

**InsightForge/app_config.yaml**:
```yaml
app_info:
  name: "洞察鍛造廠"
```

## ⚠️ 注意事項

1. **URL 限制**：
   - ShinyApps.io 的 app_name 只能使用英文、數字和連字號
   - 不能使用中文或特殊字元

2. **部署影響**：
   - 改變 ShinyApps.io 的 app_name 會創建新的應用程式
   - 舊的 URL 會失效

3. **顯示名稱 vs URL**：
   - `app_info.name` 可以是任何語言（顯示用）
   - `deployment.shinyapps.app_name` 必須符合 URL 規範

## 💡 建議

- **顯示名稱**：使用友善的中文名稱
- **URL 名稱**：使用簡短的英文名稱
- **保持一致**：在文檔中記錄名稱對應關係 