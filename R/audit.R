# This intentionally does not load reticulate or call Python discovery.
.audit_keys <- c("RETICULATE_PYTHON", "RETICULATE_PYTHON_ENV",
                 "RETICULATE_USE_MANAGED_VENV", "VIRTUAL_ENV",
                 "RETICULATE_PYTHON_FALLBACK", "WORKON_HOME")

.audit_path <- function(x) normalizePath(path.expand(x), winslash = "/", mustWork = FALSE)
.audit_file <- function(x) nzchar(x) && file.exists(path.expand(x)) && !dir.exists(path.expand(x))
.audit_same <- function(x, y) {
  x <- .audit_path(x)
  y <- .audit_path(y)
  if (.Platform$OS.type == "windows") { x <- tolower(x); y <- tolower(y) }
  identical(x, y)
}

# Pure classifier separated from observation for reproducible tests.
.audit_classify <- function(env, markers, version, intent, expected) {
  findings <- data.frame(code = character(), severity = character(),
                         message = character(), action = character())
  add <- function(code, severity, message, action) {
    findings[nrow(findings) + 1L, ] <<- list(code, severity, message, action)
  }
  explicit <- nzchar(env[["RETICULATE_PYTHON"]])
  managed <- identical(env[["RETICULATE_PYTHON"]], "managed")
  named <- nzchar(env[["RETICULATE_PYTHON_ENV"]])
  toggle <- tolower(env[["RETICULATE_USE_MANAGED_VENV"]])
  force <- toggle %in% c("yes", "true", "1")
  disabled <- toggle %in% c("no", "false", "0")
  active <- nzchar(env[["VIRTUAL_ENV"]])
  local <- any(markers$present[markers$kind == "virtualenv"])
  tooling <- any(markers$present[markers$kind == "tooling"])
  configured <- attr(env, "configured")
  if (!is.null(configured) && any(configured & !nzchar(env))) {
    add("EMPTY_ENVIRONMENT_HINT", "warning", "One or more selection variables are set to an empty string.",
        "Unset unused selection variables explicitly; an empty value can differ from an absent variable.")
  }
  if (is.na(version)) {
    add("RETICULATE_NOT_INSTALLED", "info", "reticulate is not installed in the active R libraries.",
        "Install reticulate when you are ready to use Python; this audit itself needs only R.")
  } else if (utils::compareVersion(version, "1.41.0") < 0) {
    add("LEGACY_RETICULATE", "warning", "Installed reticulate predates the managed-environment guidance used by this audit.",
        "Check the documentation for your installed version before changing selection settings.")
  }
  if (explicit && !managed && !.audit_file(env[["RETICULATE_PYTHON"]])) {
    add("INVALID_PYTHON_OVERRIDE", "error", "RETICULATE_PYTHON does not point to an existing file.",
        "Check the interpreter path. A directory or command name is not an interpreter path.")
  }
  if (explicit && named) {
    add("PYTHON_OVERRIDES_ENV", "info", "RETICULATE_PYTHON takes precedence over RETICULATE_PYTHON_ENV.",
        "Check whether the lower-priority setting is still intentional.")
  }
  if (intent == "managed") {
    if (explicit && !managed) {
      add("EXPLICIT_OVERRIDE_BLOCKS_MANAGED", "warning", "An explicit interpreter override takes precedence over managed selection.",
          "In a fresh R session, remove the override or deliberately set RETICULATE_PYTHON='managed'.")
    } else if (!managed && named) {
      add("NAMED_ENV_BLOCKS_MANAGED", "warning", "RETICULATE_PYTHON_ENV takes precedence over managed selection.",
          "In a fresh R session, reconsider that setting or deliberately set RETICULATE_PYTHON='managed'.")
    }
    if (!managed && disabled) {
      add("MANAGED_DISABLED", "warning", "Managed fallback is disabled by RETICULATE_USE_MANAGED_VENV.",
          "Review the setting in a fresh R session; do not change it blindly in an initialized session.")
    }
    if (!managed && !explicit && !named && !force && active) {
      add("ACTIVATED_ENV_BEFORE_MANAGED", "warning", "An activated virtual environment is a higher-priority selection hint than managed fallback.",
          "Check terminal or IDE activation; use a fresh session with an intentional selection policy.")
    }
    if (!managed && !explicit && !named && !force && local) {
      add("LOCAL_ENV_BEFORE_MANAGED", "warning", "A project-local virtual environment can precede managed fallback.",
          "Decide whether the local environment or managed requirements should be used. No directory needs to be deleted by this audit.")
    }
    if (!managed && !explicit && !named && !force && tooling) {
      add("PROJECT_TOOLING_HINT", "info", "A Poetry or Pipenv marker is present; a corresponding environment can precede managed fallback.",
          "Verify the environment using the relevant project tool; marker presence alone does not prove an environment exists.")
    }
    if (!managed && !explicit && !named && !force && nzchar(env[["RETICULATE_PYTHON_FALLBACK"]])) {
      add("FALLBACK_BEFORE_MANAGED", "info", "An interpreter fallback hint can precede managed fallback.",
          "Review the fallback setting if managed requirements are intended.")
    }
    if (!managed && !explicit && !named && !force && markers$present[markers$name == "r-reticulate (virtualenv root)"]) {
      add("DEFAULT_ENV_BEFORE_MANAGED", "warning", "A virtual environment named r-reticulate is present in the configured virtualenv root.",
          "Decide which environment policy to use; this audit does not remove environments.")
    }
  }
  if (markers$present[markers$name == "renv.lock"] && intent == "managed") {
    add("RENV_LOCK_NOT_PROOF", "info", "A renv lockfile is present. Its presence does not prove that managed Python dependencies are recorded.",
        "Check the Python reproducibility strategy separately; this audit does not inspect or validate lockfile contents.")
  }
  if (!is.null(expected)) {
    if (!.audit_file(expected)) {
      add("EXPECTED_INTERPRETER_MISSING", "error", "The expected interpreter is not an existing file.",
          "Check the expected interpreter path before using Python.")
    } else if (explicit && !managed && !.audit_same(env[["RETICULATE_PYTHON"]], expected)) {
      add("EXPECTED_OVERRIDE_MISMATCH", "warning", "The explicit interpreter override differs from the expected interpreter.",
          "Review the intended interpreter in a fresh R session.")
    } else if (managed) {
      add("EXPECTED_WITH_MANAGED", "info", "Managed selection does not pin the expected interpreter path.",
          "Use either a managed requirements policy or a deliberately selected existing interpreter.")
    }
  }
  if (any(markers$present[markers$kind == "startup"])) {
    add("STARTUP_FILES_NOT_EVALUATED", "info", "Project startup files are present; they were not read or executed.",
        "This audit sees current environment variables, not unevaluated startup code.")
  }
  findings
}

#' Audit visible Python selection hints
#'
#' Performs read-only checks without loading reticulate or starting Python.
#' Local paths and environment variable values are never included in the report.
#' This is not a prediction of the selected interpreter: runtime use_python()
#' requests, delayed imports, interpreter validity, and dependency resolution
#' are outside its scope. No configuration is changed.
#' @param project Existing project directory. Defaults to the working directory.
#' @param intent Selection intention: inspect, managed, or existing.
#' @param expected Optional expected interpreter file path.
#' @return A retiaudit_report with hints, project markers, and findings.
#' @export
audit_python <- function(project = getwd(), intent = c("inspect", "managed", "existing"), expected = NULL) {
  intent <- match.arg(intent)
  if (!is.character(project) || length(project) != 1L || is.na(project) || !dir.exists(project))
    stop("project must be one existing directory.", call. = FALSE)
  if (!is.null(expected) && (!is.character(expected) || length(expected) != 1L || is.na(expected) || !nzchar(expected)))
    stop("expected must be NULL or one non-empty interpreter path.", call. = FALSE)
  env <- Sys.getenv(.audit_keys, unset = NA_character_)
  configured <- !is.na(env)
  env[is.na(env)] <- ""
  attr(env, "configured") <- configured
  version <- tryCatch(as.character(utils::packageVersion("reticulate")), error = function(e) NA_character_)
  markers <- data.frame(
    name = c(".venv", "venv", ".virtualenv", "virtualenv", "pyproject.toml", "Pipfile", "renv.lock", ".Rprofile", ".Renviron"),
    kind = c(rep("virtualenv", 4), rep("tooling", 2), "lockfile", rep("startup", 2)),
    present = FALSE)
  for (i in seq_len(nrow(markers))) {
    path <- file.path(project, markers$name[i])
    markers$present[i] <- if (markers$kind[i] == "virtualenv")
      dir.exists(path) && file.exists(file.path(path, "pyvenv.cfg")) else .audit_file(path)
  }
  root <- if (nzchar(env[["WORKON_HOME"]])) env[["WORKON_HOME"]] else "~/.virtualenvs"
  default_env <- file.path(path.expand(root), "r-reticulate")
  markers <- rbind(markers, data.frame(name = "r-reticulate (virtualenv root)", kind = "virtualenv-root",
    present = dir.exists(default_env) && file.exists(file.path(default_env, "pyvenv.cfg"))))
  findings <- .audit_classify(env, markers, version, intent, expected)
  structure(list(
    intent = intent,
    reticulate_version = version,
    hints = data.frame(variable = .audit_keys, set = configured,
                       mode = vapply(seq_along(env), function(i) {
                         if (!nzchar(env[i])) return("unset")
                         if (.audit_keys[i] == "RETICULATE_PYTHON" && env[i] == "managed") return("managed")
                         if (.audit_keys[i] == "RETICULATE_USE_MANAGED_VENV") {
                           if (tolower(env[i]) %in% c("yes", "true", "1")) return("enabled")
                           if (tolower(env[i]) %in% c("no", "false", "0")) return("disabled")
                           return("unrecognized")
                         }
                         "value omitted"
                       }, character(1))),
    markers = markers,
    findings = findings,
    scope = "Visible hints only. No interpreter discovery, runtime selection proof, dependency validation, or automatic fixes."
  ), class = "retiaudit_report")
}

#' Format a Python selection audit as Markdown
#' @param report A report returned by audit_python().
#' @return Character vector of Markdown lines; does not write files.
#' @export
audit_markdown <- function(report) {
  if (!inherits(report, "retiaudit_report")) stop("report must be a retiaudit_report.", call. = FALSE)
  lines <- c("# Python selection preflight", "", paste("Intent:", report$intent),
             paste("reticulate:", if (is.na(report$reticulate_version)) "not installed" else report$reticulate_version),
             "", "## Environment hints", "", "| Variable | Set | Mode |", "| --- | --- | --- |")
  for (i in seq_len(nrow(report$hints))) lines <- c(lines, sprintf("| %s | %s | %s |", report$hints$variable[i], report$hints$set[i], report$hints$mode[i]))
  lines <- c(lines, "", "## Project markers", "", "| Marker | Present |", "| --- | --- |")
  for (i in seq_len(nrow(report$markers))) lines <- c(lines, sprintf("| %s | %s |", report$markers$name[i], report$markers$present[i]))
  lines <- c(lines, "", "## Findings", "")
  if (!nrow(report$findings)) lines <- c(lines, "No visible conflict detected. This does not establish that Python will work.")
  for (i in seq_len(nrow(report$findings))) lines <- c(lines,
    sprintf("- **%s [%s]**: %s %s", report$findings$code[i], report$findings$severity[i], report$findings$message[i], report$findings$action[i]))
  c(lines, "", report$scope, "", "Local paths, environment values, startup-file contents, and package requirements are omitted. Review before sharing.")
}

#' @export
print.retiaudit_report <- function(x, ...) {
  cat(paste(audit_markdown(x), collapse = "\n"), "\n")
  invisible(x)
}
