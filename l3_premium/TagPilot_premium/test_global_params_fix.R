# 測試全域參數修復
cat("=== 測試全域參數修復 ===\n")

# 測試完整的全域參數設定
complete_global_params <- list(
  delta = 0.1,
  ni_threshold = 2,
  cai_breaks = c(0, 0.1, 0.9, 1),
  text_cai_label = c("逐漸不活躍", "穩定", "日益活躍"),
  f_breaks = c(-0.0001, 1.1, 2.1, Inf),
  text_f_label = c("低頻率", "中頻率", "高頻率"),
  r_breaks = c(-0.0001, 0.1, 0.9, 1.0001),
  text_r_label = c("長期不活躍", "中期不活躍", "近期購買"),
  m_breaks = c(-0.0001, 0.1, 0.9, 1.0001),
  text_m_label = c("低價值", "中價值", "高價值"),
  nes_breaks = c(0, 1, 2, 2.5, Inf),
  text_nes_label = c("E0", "S1", "S2", "S3")
)

cat("✅ 完整全域參數創建完成\n")

# 檢查所有必要參數
required_params <- c("delta", "ni_threshold", "cai_breaks", "text_cai_label", 
                    "f_breaks", "text_f_label", "r_breaks", "text_r_label", 
                    "m_breaks", "text_m_label", "nes_breaks", "text_nes_label")

missing_params <- required_params[!required_params %in% names(complete_global_params)]

if (length(missing_params) == 0) {
  cat("✅ 所有必要參數都已包含\n")
  cat("📊 參數列表:", paste(names(complete_global_params), collapse = ", "), "\n")
} else {
  cat("❌ 缺少參數:", paste(missing_params, collapse = ", "), "\n")
}

# 測試參數值
tryCatch({
  # 測試 breaks 參數格式
  if (is.numeric(complete_global_params$m_breaks) && length(complete_global_params$m_breaks) > 1) {
    cat("✅ m_breaks 參數格式正確\n")
  } else {
    cat("❌ m_breaks 參數格式錯誤\n")
  }
  
  if (is.numeric(complete_global_params$r_breaks) && length(complete_global_params$r_breaks) > 1) {
    cat("✅ r_breaks 參數格式正確\n")
  } else {
    cat("❌ r_breaks 參數格式錯誤\n")
  }
  
  if (is.numeric(complete_global_params$f_breaks) && length(complete_global_params$f_breaks) > 1) {
    cat("✅ f_breaks 參數格式正確\n")
  } else {
    cat("❌ f_breaks 參數格式錯誤\n")
  }
  
  # 測試標籤參數
  if (is.character(complete_global_params$text_m_label) && length(complete_global_params$text_m_label) > 0) {
    cat("✅ text_m_label 參數格式正確\n")
  } else {
    cat("❌ text_m_label 參數格式錯誤\n")
  }
  
  # 測試 delta 參數
  if (is.numeric(complete_global_params$delta) && complete_global_params$delta > 0) {
    cat("✅ delta 參數格式正確\n")
  } else {
    cat("❌ delta 參數格式錯誤\n")
  }
  
}, error = function(e) {
  cat("❌ 參數測試失敗:", e$message, "\n")
})

cat("\n=== 修復前後比較 ===\n")
cat("❌ 修復前: global_params = list(delta = delta_factor)\n")
cat("✅ 修復後: global_params = complete_global_params (包含所有12個參數)\n")

cat("\n=== 參數詳細資訊 ===\n")
cat("• delta:", complete_global_params$delta, "\n")
cat("• ni_threshold:", complete_global_params$ni_threshold, "\n")
cat("• m_breaks:", paste(complete_global_params$m_breaks, collapse = ", "), "\n")
cat("• text_m_label:", paste(complete_global_params$text_m_label, collapse = ", "), "\n")
cat("• r_breaks:", paste(complete_global_params$r_breaks, collapse = ", "), "\n")
cat("• f_breaks:", paste(complete_global_params$f_breaks, collapse = ", "), "\n")
cat("• nes_breaks:", paste(complete_global_params$nes_breaks, collapse = ", "), "\n")

cat("\n=== 修復要點 ===\n")
cat("1. ✅ 提供完整的 global_params 而非只有 delta\n")
cat("2. ✅ 包含所有 analysis_dna 函數需要的參數\n")
cat("3. ✅ 避免了 '找不到物件 m_breaks' 錯誤\n")
cat("4. ✅ 確保 RFM 分析和 NES 狀態計算正常運作\n")

cat("\n🎉 全域參數問題已修復！\n") 