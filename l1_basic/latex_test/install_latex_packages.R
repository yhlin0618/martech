# =============================================================================
# LaTeX Package Installation Helper
# Purpose: Install missing LaTeX packages and diagnose installation issues
# =============================================================================

cat("=== LaTeX Package Installation Helper ===\n\n")

# Check if MiKTeX is available
cat("1. Checking MiKTeX installation...\n")
miktex_available <- FALSE

# Try to find MiKTeX
miktex_paths <- c(
  "C:/Program Files/MiKTeX/miktex/bin/x64/miktex.exe",
  "C:/Program Files/MiKTeX/miktex/bin/miktex.exe",
  "C:/Program Files (x86)/MiKTeX/miktex/bin/miktex.exe"
)

for (path in miktex_paths) {
  if (file.exists(path)) {
    cat("   Found MiKTeX at:", path, "\n")
    miktex_available <- TRUE
    miktex_exe <- path
    break
  }
}

if (!miktex_available) {
  cat("   MiKTeX not found in standard locations\n")
  cat("   Please install MiKTeX from: https://miktex.org/download\n")
} else {
  cat("   MiKTeX is available\n")
}

# Check if pdflatex is available
cat("\n2. Checking pdflatex availability...\n")
pdflatex_result <- tryCatch({
  system2("pdflatex", "--version", stdout = TRUE, stderr = TRUE)
}, error = function(e) {
  NULL
})

if (!is.null(pdflatex_result)) {
  cat("   pdflatex is available\n")
  cat("   Version info:", pdflatex_result[1], "\n")
} else {
  cat("   pdflatex not found in PATH\n")
}

# Try to install missing packages
if (miktex_available) {
  cat("\n3. Attempting to install missing packages...\n")
  
  # List of commonly missing packages
  missing_packages <- c(
    "bookmark",
    "hyperref", 
    "geometry",
    "fancyhdr",
    "titlesec",
    "enumitem",
    "graphicx",
    "color",
    "xcolor"
  )
  
  for (pkg in missing_packages) {
    cat("   Installing package:", pkg, "...\n")
    tryCatch({
      # Use MiKTeX package manager to install
      install_cmd <- paste0('"', miktex_exe, '" --install-package=', pkg)
      result <- system(install_cmd, intern = TRUE, ignore.stderr = TRUE)
      cat("     Result:", ifelse(length(result) > 0, "Success", "Unknown"), "\n")
    }, error = function(e) {
      cat("     Error:", e$message, "\n")
    })
  }
}

# Alternative: Use tlmgr if available (TeX Live)
cat("\n4. Checking for TeX Live...\n")
tlmgr_result <- tryCatch({
  system2("tlmgr", "--version", stdout = TRUE, stderr = TRUE)
}, error = function(e) {
  NULL
})

if (!is.null(tlmgr_result)) {
  cat("   TeX Live is available\n")
  cat("   Installing packages via tlmgr...\n")
  
  packages_to_install <- c("bookmark", "hyperref", "geometry")
  for (pkg in packages_to_install) {
    cat("   Installing:", pkg, "...\n")
    tryCatch({
      system2("tlmgr", c("install", pkg), stdout = TRUE, stderr = TRUE)
      cat("     Success\n")
    }, error = function(e) {
      cat("     Error:", e$message, "\n")
    })
  }
} else {
  cat("   TeX Live not found\n")
}

# Test compilation with minimal document
cat("\n5. Testing minimal LaTeX compilation...\n")
test_tex <- "\\documentclass{article}
\\usepackage{bookmark}
\\begin{document}
Test document
\\end{document}"

test_file <- "test_minimal.tex"
writeLines(test_tex, test_file)

tryCatch({
  result <- system2("pdflatex", c("-interaction=nonstopmode", test_file), 
                   stdout = TRUE, stderr = TRUE)
  if (file.exists("test_minimal.pdf")) {
    cat("   Minimal compilation successful!\n")
    file.remove("test_minimal.pdf")
  } else {
    cat("   Minimal compilation failed\n")
  }
}, error = function(e) {
  cat("   Compilation error:", e$message, "\n")
})

# Clean up
if (file.exists(test_file)) file.remove(test_file)
if (file.exists("test_minimal.aux")) file.remove("test_minimal.aux")
if (file.exists("test_minimal.log")) file.remove("test_minimal.log")

cat("\n=== Installation Helper Complete ===\n")
cat("\nIf packages are still missing, try:\n")
cat("1. Run MiKTeX Console as Administrator\n")
cat("2. Go to Packages tab\n")
cat("3. Search for 'bookmark' and install it\n")
cat("4. Or use: miktex --install-package=bookmark\n")
cat("\nAlternative: Use HTML output instead of PDF\n") 