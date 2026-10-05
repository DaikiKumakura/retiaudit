test_that("explicit overrides are detected without exposing their values", {
  with_clean_hints(with_project(function(project) {
    fake <- file.path(project, "private-interpreter-identity")
    file.create(fake)
    Sys.setenv(RETICULATE_PYTHON = fake, RETICULATE_PYTHON_ENV = "private-env-identity")
    r <- audit_python(project, "managed")
    expect_true("EXPLICIT_OVERRIDE_BLOCKS_MANAGED" %in% codes(r))
    expect_true("PYTHON_OVERRIDES_ENV" %in% codes(r))
    expect_false(any(grepl("private-", capture.output(str(r)), fixed = TRUE)))
    expect_false(any(grepl(project, audit_markdown(r), fixed = TRUE)))
  }))
})

test_that("missing and directory overrides are rejected", {
  with_clean_hints(with_project(function(project) {
    for (path in c(file.path(project, "missing"), project)) {
      Sys.setenv(RETICULATE_PYTHON = path)
      expect_true("INVALID_PYTHON_OVERRIDE" %in% codes(audit_python(project)))
    }
  }))
})

test_that("managed sentinel wins over conflicting lower priority hints", {
  with_clean_hints(with_project(function(project) {
    Sys.setenv(RETICULATE_PYTHON = "managed", VIRTUAL_ENV = project,
               RETICULATE_USE_MANAGED_VENV = "no")
    r <- audit_python(project, "managed")
    expect_false(any(c("INVALID_PYTHON_OVERRIDE", "MANAGED_DISABLED", "ACTIVATED_ENV_BEFORE_MANAGED") %in% codes(r)))
    expect_identical(r$hints$mode[1], "managed")
  }))
})

test_that("managed toggle does not supersede explicit overrides", {
  with_clean_hints(with_project(function(project) {
    Sys.setenv(RETICULATE_USE_MANAGED_VENV = "YES", VIRTUAL_ENV = project)
    expect_false("ACTIVATED_ENV_BEFORE_MANAGED" %in% codes(audit_python(project, "managed")))
    Sys.setenv(RETICULATE_PYTHON_ENV = "named-env")
    expect_true("NAMED_ENV_BLOCKS_MANAGED" %in% codes(audit_python(project, "managed")))
  }))
})

test_that("project markers are observations and startup code is not executed", {
  with_clean_hints(with_project(function(project) {
    dir.create(file.path(project, ".venv"))
    # An ordinary directory alone is not counted as a virtual environment.
    expect_false("LOCAL_ENV_BEFORE_MANAGED" %in% codes(audit_python(project, "managed")))
    file.create(file.path(project, ".venv", "pyvenv.cfg"))
    file.create(file.path(project, "renv.lock"))
    file.create(file.path(project, "pyproject.toml"))
    writeLines("stop('must never execute')", file.path(project, ".Rprofile"))
    r <- audit_python(project, "managed")
    expect_true(all(c("LOCAL_ENV_BEFORE_MANAGED", "PROJECT_TOOLING_HINT", "RENV_LOCK_NOT_PROOF", "STARTUP_FILES_NOT_EVALUATED") %in% codes(r)))
  }))
})

test_that("expected interpreter mismatch is meaningful and paths remain private", {
  with_clean_hints(with_project(function(project) {
    p <- file.path(project, c("one", "two"))
    file.create(p)
    Sys.setenv(RETICULATE_PYTHON = p[1])
    expect_false("EXPECTED_OVERRIDE_MISMATCH" %in% codes(audit_python(project, "existing", p[1])))
    expect_true("EXPECTED_OVERRIDE_MISMATCH" %in% codes(audit_python(project, "existing", p[2])))
    expect_true("EXPECTED_INTERPRETER_MISSING" %in% codes(audit_python(project, expected = paste0(p[2], "missing"))))
    expect_error(audit_python(project, expected = NA_character_), "expected")
  }))
})

test_that("audit does not load reticulate, change environment or create files", {
  with_clean_hints(with_project(function(project) {
    before_ns <- loadedNamespaces()
    before_env <- Sys.getenv()
    before_files <- list.files(project, all.files = TRUE)
    before_wd <- getwd()
    r <- audit_python(project, "managed")
    expect_identical(Sys.getenv(), before_env)
    expect_identical(list.files(project, all.files = TRUE), before_files)
    expect_identical(getwd(), before_wd)
    expect_identical("reticulate" %in% loadedNamespaces(), "reticulate" %in% before_ns)
    expect_invisible(print(r))
  }))
})

test_that("empty selection variable is recorded rather than treated as absent", {
  with_clean_hints(with_project(function(project) {
    Sys.setenv(RETICULATE_PYTHON = "")
    r <- audit_python(project)
    # Windows can remove a variable when assigned an empty value.
    is_set <- !is.na(Sys.getenv("RETICULATE_PYTHON", unset = NA_character_))
    expect_identical(r$hints$set[1], is_set)
    expect_identical("EMPTY_ENVIRONMENT_HINT" %in% codes(r), is_set)
  }))
})

test_that("default virtualenv and fallback are visible managed-selection obstacles", {
  with_clean_hints(with_project(function(project) {
    root <- Sys.getenv("WORKON_HOME")
    dir.create(file.path(root, "r-reticulate"))
    file.create(file.path(root, "r-reticulate", "pyvenv.cfg"))
    Sys.setenv(RETICULATE_PYTHON_FALLBACK = "private-path")
    r <- audit_python(project, "managed")
    expect_true(all(c("DEFAULT_ENV_BEFORE_MANAGED", "FALLBACK_BEFORE_MANAGED") %in% codes(r)))
    expect_false(any(grepl("private-path", audit_markdown(r), fixed = TRUE)))
  }))
})

test_that("invalid arguments fail with no echo of private input", {
  expect_error(audit_python("/private-nonexistent-project"), "one existing directory")
  expect_error(audit_python(c("a", "b")), "one existing directory")
  expect_error(audit_markdown(list()), "retiaudit_report")
})
