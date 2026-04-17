#' EmailtoID Function
#'
#' Brief description of what this function does
#'
#' @param params Description of parameters
#' @return Description of return value
#'
#' @examples
#' EmailtoID()
EmailtoID<- function(Email){
  tolower(substr(Email, 1, regexpr("@", Email) - 1))
}
