#' Replace Non Numeric Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' replace_non_numeric()
replace_non_numeric <- function(x) {
  suppressWarnings(as.numeric(as.character(x)))
}
