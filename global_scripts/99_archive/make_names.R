#' Make Names Function
#'
#' Cleans column names to ensure they're valid R variable names
#'
#' @param x A character vector of column names
#'
#' @return A cleaned character vector
#'
make_names <- function(x) {
  x <- tolower(x)
  x <- gsub("[^a-z0-9_]", "_", x)
  x <- gsub("(^_+|_+$)", "", x)
  x <- gsub("_+", "_", x)
  
  # Ensure names are unique
  if (any(duplicated(x))) {
    x <- make.names(x, unique = TRUE)
  }
  
  return(x)
}