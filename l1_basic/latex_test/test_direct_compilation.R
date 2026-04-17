# =============================================================================
# Test Direct Compilation
# Purpose: Test direct LaTeX compilation without the module
# =============================================================================

# Test direct compilation
cat("Testing direct pdflatex compilation...\n")

# Create a simple test file
test_content <- c(
  "\\documentclass{article}",
  "\\usepackage[utf8]{inputenc}",
  "\\title{Test Report}",
  "\\author{Test User}",
  "\\begin{document}",
  "\\maketitle",
  "\\section{Test}",
  "This is a test.",
  "\\end{document}"
)

writeLines(test_content, "test_direct.tex")

# Try direct compilation
result <- system2(
  "C:/Program Files/MiKTeX/miktex/bin/x64/pdflatex.exe",
  args = c("-interaction=nonstopmode", "test_direct.tex"),
  stdout = TRUE,
  stderr = TRUE
)

cat("Compilation result:\n")
cat(paste(result, collapse = "\n"), "\n")

# Check if PDF was created
if (file.exists("test_direct.pdf")) {
  cat("✓ PDF created successfully!\n")
  cat("File size:", file.size("test_direct.pdf"), "bytes\n")
} else {
  cat("✗ PDF not created\n")
}

# Clean up
file.remove("test_direct.tex", "test_direct.pdf", "test_direct.log", "test_direct.aux") 