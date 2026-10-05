test_that("legacy and missing reticulate are distinguished", {
  with_clean_hints(with_project(function(project) {
    report <- audit_python(project)
    env <- Sys.getenv(retiaudit:::.audit_keys, unset = "")
    classify <- function(version) retiaudit:::.audit_classify(env, report$markers, version, "managed", NULL)
    expect_true("LEGACY_RETICULATE" %in% classify("1.40.0")$code)
    expect_false("LEGACY_RETICULATE" %in% classify("1.41.0")$code)
    expect_true("RETICULATE_NOT_INSTALLED" %in% classify(NA_character_)$code)
  }))
})

test_that("disabled managed policy is not silently assumed enabled", {
  with_clean_hints(with_project(function(project) {
    for (value in c("no", "FALSE", "0")) {
      Sys.setenv(RETICULATE_USE_MANAGED_VENV = value)
      expect_true("MANAGED_DISABLED" %in% codes(audit_python(project, "managed")))
    }
    Sys.setenv(RETICULATE_USE_MANAGED_VENV = "maybe")
    expect_identical(audit_python(project)$hints$mode[3], "unrecognized")
  }))
})
