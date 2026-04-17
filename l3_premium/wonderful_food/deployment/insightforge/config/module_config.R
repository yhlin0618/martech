################################################################################
# module_config.R - 模組配置設定
################################################################################

# 設定是否使用已評分資料上傳模組
# TRUE: 使用新的 module_upload_complete_score.R（直接上傳已評分資料）
# FALSE: 使用原始的 module_upload.R + module_score_v2.R（上傳評論後進行評分）

options(use_complete_score_upload = TRUE)

# 您可以根據需要切換模組：
# - 若要使用原始流程（上傳評論 -> AI評分 -> 分析），請設定為 FALSE
# - 若要使用新流程（直接上傳已評分資料 -> 分析），請設定為 TRUE

cat("📋 模組配置已載入\n")
cat("   使用已評分資料上傳:", getOption("use_complete_score_upload", FALSE), "\n")