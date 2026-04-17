library(stringi)

convert_all_columns_to_utf8 <- function(df, from_encoding = NULL) {
  df[] <- lapply(df, function(x) {
    # 處理字串欄位
    if (is.character(x)) {
      enc <- from_encoding
      if (is.null(enc)) {
        # 取得第一個非 NA 值
        first_val <- x[which(!is.na(x))[1]]
        if (length(first_val) == 0 || is.na(first_val)) {
          enc <- "UTF-8"  # 若欄位內皆為 NA，就直接當作 UTF-8
        } else {
          detected <- stri_enc_detect(first_val)
          if (length(detected) > 0 && !is.null(detected[[1]]$Encoding)) {
            enc <- detected[[1]]$Encoding[1]
          } else {
            enc <- "UTF-8"
          }
        }
      }
      # 轉換為 UTF-8
      iconv(x, from = enc, to = "UTF-8", sub = "")
    } else if (is.factor(x)) {
      # 先轉成字串處理
      x_char <- as.character(x)
      enc <- from_encoding
      if (is.null(enc)) {
        first_val <- x_char[which(!is.na(x_char))[1]]
        if (length(first_val) == 0 || is.na(first_val)) {
          enc <- "UTF-8"
        } else {
          detected <- stri_enc_detect(first_val)
          if (length(detected) > 0 && !is.null(detected[[1]]$Encoding)) {
            enc <- detected[[1]]$Encoding[1]
          } else {
            enc <- "UTF-8"
          }
        }
      }
      x_utf8 <- iconv(x_char, from = enc, to = "UTF-8", sub = "")
      factor(x_utf8)
    } else {
      x
    }
  })
  return(df)
}