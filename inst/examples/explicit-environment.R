# Run in a fresh R session with a dedicated test virtualenv, not a live project.
# Rscript explicit-environment.R path/to/venv/python before
# After installing colorama into that dedicated environment, rerun with "after".
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L, args[2] %in% c("before", "after"))
Sys.setenv(RETICULATE_PYTHON = args[1])
library(retiaudit)
report <- audit_python(intent = "managed")
stopifnot("EXPLICIT_OVERRIDE_BLOCKS_MANAGED" %in% report$findings$code)
stopifnot(!"reticulate" %in% loadedNamespaces())
cat("Preflight: explicit interpreter override precedes managed selection.\n")
library(reticulate)
py_require("colorama==0.4.6")
module <- tryCatch(import("colorama", convert = TRUE), error = identity)
if (args[2] == "before") {
  stopifnot(inherits(module, "error"), grepl("ModuleNotFoundError", conditionMessage(module)))
  cat("Before: py_require declaration did not install colorama into the explicit environment.\n")
} else {
  stopifnot(!inherits(module, "error"), identical(py_to_r(py_get_attr(module, "__version__")), "0.4.6"))
  cat("After: explicitly installing into the intended environment made import succeed.\n")
}
