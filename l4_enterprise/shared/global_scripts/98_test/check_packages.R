required <- c("duckdb", "DBI", "dplyr", "tidyr", "googlesheets4", "broom", "zoo", "knitr")
installed <- installed.packages()[,"Package"]
missing <- required[!required %in% installed]
if(length(missing) > 0) {
  cat("Missing packages:", paste(missing, collapse=", "), "\n")
  cat("Please run: install.packages(c('", paste(missing, collapse="', '"), "'))\n", sep="")
} else {
  cat("All required packages installed\n")
}
