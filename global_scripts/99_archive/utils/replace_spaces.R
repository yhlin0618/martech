#' Replace Spaces Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' replace_spaces()
replace_spaces <- function(vectors) {
gsub(" ", "_", vectors)
}
