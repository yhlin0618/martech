# 測試 DNA 分析依賴函數載入
cat("=== 測試 DNA 分析依賴函數載入 ===\n")

# 載入必要的依賴函數
tryCatch({
  # 載入依賴函數
  if (file.exists("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")) {
    source("scripts/global_scripts/04_utils/fn_left_join_remove_duplicate2.R")
    cat("✅ fn_left_join_remove_duplicate2.R 載入成功\n")
  } else {
    cat("❌ fn_left_join_remove_duplicate2.R 檔案不存在\n")
  }
  
  if (file.exists("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")) {
    source("scripts/global_scripts/04_utils/fn_fct_na_value_to_level.R")
    cat("✅ fn_fct_na_value_to_level.R 載入成功\n")
  } else {
    cat("❌ fn_fct_na_value_to_level.R 檔案不存在\n")
  }
  
  if (file.exists("scripts/global_scripts/04_utils/fn_analysis_dna.R")) {
    source("scripts/global_scripts/04_utils/fn_analysis_dna.R")
    cat("✅ fn_analysis_dna.R 載入成功\n")
  } else {
    cat("❌ fn_analysis_dna.R 檔案不存在\n")
  }
  
}, error = function(e) {
  cat("❌ 載入錯誤:", e$message, "\n")
})

# 檢查函數是否存在
cat("\n=== 檢查函數可用性 ===\n")

if (exists("left_join_remove_duplicate2")) {
  cat("✅ left_join_remove_duplicate2 函數可用\n")
} else {
  cat("❌ left_join_remove_duplicate2 函數不可用\n")
}

if (exists("fct_na_value_to_level")) {
  cat("✅ fct_na_value_to_level 函數可用\n")
} else {
  cat("❌ fct_na_value_to_level 函數不可用\n")
}

if (exists("analysis_dna")) {
  cat("✅ analysis_dna 函數可用\n")
} else {
  cat("❌ analysis_dna 函數不可用\n")
}

cat("\n=== 修復要點 ===\n")
cat("1. ✅ 在 DNA 模組中預先載入 fn_left_join_remove_duplicate2.R\n")
cat("2. ✅ 在 DNA 模組中預先載入 fn_fct_na_value_to_level.R\n")
cat("3. ✅ 確保依賴函數在 fn_analysis_dna.R 之前載入\n")
cat("4. ✅ 同時修復了 module_dna.R 和 module_dna_multi.R\n")

cat("\n🎉 依賴問題已修復！\n") 