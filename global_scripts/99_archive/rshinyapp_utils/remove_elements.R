  vector <- vector[!tolower(vector) %in% tolower(elements)]
  return(vector)
}
