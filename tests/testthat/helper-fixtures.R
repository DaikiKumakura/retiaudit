with_clean_hints <- function(code) {
  keys <- c("RETICULATE_PYTHON", "RETICULATE_PYTHON_ENV", "RETICULATE_USE_MANAGED_VENV",
            "VIRTUAL_ENV", "RETICULATE_PYTHON_FALLBACK", "WORKON_HOME")
  old <- Sys.getenv(keys, unset = NA_character_)
  on.exit({
    Sys.unsetenv(keys)
    present <- !is.na(old)
    if (any(present)) do.call(Sys.setenv, as.list(old[present]))
  })
  Sys.unsetenv(keys)
  # Isolate the default virtualenv root from the machine's configuration.
  root <- tempfile()
  dir.create(root)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)
  Sys.setenv(WORKON_HOME = root)
  force(code)
}

with_project <- function(code) {
  project <- tempfile()
  dir.create(project)
  on.exit(unlink(project, recursive = TRUE))
  code(project)
}

codes <- function(report) report$findings$code

