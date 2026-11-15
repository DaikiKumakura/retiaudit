#' retiaudit: inspect Python selection hints without starting Python
#'
#' When `py_require()` is followed by `ModuleNotFoundError`, an old setting
#' often makes reticulate use a different Python. retiaudit lists the visible
#' selection hints (explicit overrides, managed-environment flags, active
#' environments, project markers) and checks them against what you intend,
#' without loading reticulate or starting Python.
#'
#' @section Workflow:
#' 1. [audit_python()] with `intent = "managed"` (you use `py_require()`) or
#'    `intent = "existing"` (optionally with the `expected` interpreter path)
#'    returns a report of hints and findings.
#' 2. [audit_markdown()] turns the report into Markdown to share. Reports
#'    leave out environment values, local paths and file contents.
#'
#' No findings means no visible conflict, not a working Python setup.
#'
#' @keywords internal
"_PACKAGE"
