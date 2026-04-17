remove_illegal_utf8 <- function(df) {
  df[] <- lapply(df, function(x) {
    if (is.character(x)) {
      # 嘗試將字串從 UTF-8 轉回 UTF-8，不合法的部分以空字串替換
      iconv(x, "UTF-8", "UTF-8", sub = "")
    } else if (is.factor(x)) {
      # 因子先轉為字串，處理後再轉回因子
      x_clean <- iconv(as.character(x), "UTF-8", "UTF-8", sub = "")
      factor(x_clean)
    } else {
      x
    }
  })
  return(df)
}