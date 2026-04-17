# 函數檢查和安裝所需的套件
library2 <- function(...) {
  # 使用 substitute 取得未評估的參數，再用 deparse 轉換為字串
  pkgs <- sapply(substitute(list(...))[-1], deparse)
  for (pkg in pkgs) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message(paste("Installing missing package:", pkg))
      install.packages(pkg, dependencies = TRUE)
    }
    library(pkg, character.only = TRUE, quietly = TRUE)
  }
}

# 自動安裝和加載所需的套件