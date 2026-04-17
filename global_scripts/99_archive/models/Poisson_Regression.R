poisson_regression <- function(var_name, Dta) {
  # 檢查變數是否全為 NA
  if (all(is.na(Dta[[var_name]]))) {
    return(c(NA,NA,NA))  # 直接跳過
  }
  
  # 進行 Poisson 回歸
  formula <- as.formula(paste("sales ~", var_name))
  poisson_model <- glm(formula, data = Dta, family = poisson())
  
  
  # 獲取指定變數的係數
  coef_var <- poisson_model$coefficients[var_name]
  
  # 檢查係數是否存在
  if (is.na(coef_var)) {
    return(c(NA_real_,NA_real_,NA_real_))  # 直接跳過
  }
  
  # 計算當前變量的範圍
  var_range <- range(Dta[[var_name]], na.rm = TRUE)
  
  # 計算範圍乘以係數再取 exp 的結果
  exp_result <- exp(var_range * coef_var)
  
  # 返回排序的結果和範圍差異的指數值
  return(c(sort(exp_result), exp(abs(diff(var_range * coef_var)))))
}
