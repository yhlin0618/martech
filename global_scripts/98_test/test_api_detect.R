api_token <- Sys.getenv("CBZ_API_TOKEN", "")
cat("Token value: '", api_token, "'\n", sep="")
cat("Token length:", nchar(api_token), "\n")
api_available <- nchar(api_token) > 0
cat("API available:", api_available, "\n")

if (api_available) {
  cat("Would use API path\n")
} else {
  cat("Would use FILE path\n")
}
