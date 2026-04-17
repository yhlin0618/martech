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
