# 從 deployment_config.yaml 遷移到 app_config.yaml

## 🔄 變更說明

我們已將配置檔案從 `deployment_config.yaml` 改名為 `app_config.yaml`，並擴展了其功能。

## ✨ 改名的好處

1. **更通用的名稱**
   - `app_config.yaml` 不只限於部署配置
   - 可以包含應用程式的所有設定

2. **與其他專案保持一致**
   - 您在 precision_marketing 專案中也使用 `app_config.yaml`
   - 統一的命名規範更容易管理

3. **擴展性更好**
   - 現在包含了應用程式資訊、主題設定、資料配置等
   - 部署設定只是配置的一部分

## 📁 新的配置結構

```yaml
# 應用程式基本資訊
app_info:
  name: "App Name"
  version: "1.0.0"
  
# UI/主題設定  
theme:
  bootswatch: cosmo
  
# 資料設定
data:
  cache_dir: "./cache"
  
# 部署配置（原本的內容）
deployment:
  github_repo: "..."
  app_path: "..."
  # ... 其他部署設定
  
# 可以繼續擴展其他設定
```

## 🚀 使用方式

部署腳本會自動尋找 `app_config.yaml`：

```bash
# 使用預設的 app_config.yaml
Rscript scripts/global_scripts/23_deployment/sc_deployment_config.R

# 或指定其他配置檔案
Rscript scripts/global_scripts/23_deployment/sc_deployment_config.R my_config.yaml
```

## 📝 遷移步驟

如果您有舊的 `deployment_config.yaml`：

1. 將檔案改名為 `app_config.yaml`
2. 將原本的設定移到 `deployment:` 區塊下
3. 可選：加入其他應用程式設定

## 🔗 相關文件

- [配置驅動部署系統](scripts/global_scripts/23_deployment/README_CONFIG.md)
- [配置模板](scripts/global_scripts/23_deployment/app_config_template.yaml) 