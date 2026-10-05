# retiaudit

**Why is reticulate ignoring my managed Python requirements?**

Inspect the selection hints that can get in the way, before starting Python.
`retiaudit` is a small, dependency-free R companion to reticulate. It reports
visible overrides and project markers, with local paths and values omitted.

If `py_require()` is followed by `ModuleNotFoundError`, start with the
[reproduced failure, diagnosis and remedy](inst/examples/managed-selection.md).
It shows when an explicit interpreter override prevents managed selection and
how to choose a managed or existing-environment approach deliberately.

```r
install.packages("remotes") # only needed for installation from GitHub
remotes::install_github("DaikiKumakura/retiaudit")
library(retiaudit)

audit_python(intent = "managed")
```

Alternatively, build the source archive with `R CMD build .` and install it with
`install.packages("retiaudit_0.1.0.tar.gz", repos = NULL, type = "source")`.
Not on CRAN. Initial version; feedback on real projects is welcome.

## A reproducible example

Suppose an old setting points at a Python file while you intend to use
`py_require()` with a managed environment. This synthetic example does not
run that file or start Python:

```r
local({
  previous <- Sys.getenv("RETICULATE_PYTHON", unset = NA_character_)
  placeholder <- tempfile()
  file.create(placeholder)
  on.exit({
    unlink(placeholder)
    if (is.na(previous)) Sys.unsetenv("RETICULATE_PYTHON")
    else Sys.setenv(RETICULATE_PYTHON = previous)
  })
  Sys.setenv(RETICULATE_PYTHON = placeholder)
  report <- audit_python(intent = "managed")
  report$findings[, c("code", "severity")]
})
# Includes EXPLICIT_OVERRIDE_BLOCKS_MANAGED / warning
```

For an existing interpreter, you can also check an explicit override against
the path you expect:

```r
report <- audit_python(intent = "existing", expected = "/path/to/python")
```

The audit checks file existence, not whether that file is a working Python
interpreter. It never recommends deleting an environment or changes settings.
Review findings and choose a policy deliberately in a fresh R session.

## What it checks

- Explicit interpreter and named-environment overrides.
- Managed-environment enable/disable flags, with precedence considered.
- Activated environments and project-local virtualenv markers.
- Poetry/Pipenv markers, an interpreter fallback, and a default `r-reticulate` environment marker.
- Missing interpreter files and disagreement with an optional expected path.
- Presence of startup files and a renv lockfile, without reading their contents.

## How it differs from reticulate's diagnostics

| Tool | Purpose |
| --- | --- |
| `reticulate::py_config()` | Inspect the Python configuration; can initialize Python. |
| `reticulate::py_discover_config()` | Discover a Python configuration without loading Python; discovery is still performed. |
| `retiaudit::audit_python()` | Check visible selection hints against your intent, without loading reticulate or running discovery. |

This complements the official diagnostics. It does not replace them or
reimplement reticulate's full discovery algorithm.

## Share a report

```r
report <- audit_python(intent = "managed")
cat(paste(audit_markdown(report), collapse = "\n"))
# If you choose to save it:
# writeLines(audit_markdown(report), "python-preflight.md")
```

The returned object and Markdown omit environment values, local paths,
startup-file contents, requirements and error traces. Fixed variable names,
marker names, presence flags, and the installed reticulate version remain.
Review any report before sharing. Do not append raw session dumps or secrets.

## Limits

No network calls, subprocesses, environment changes, installation, file writes,
startup-file execution, or reticulate namespace loading are performed by the
audit. It reads only selected environment variables, package metadata and file
existence. It does not observe `use_python()` requests, loaded Python state,
delayed imports, global startup code, dependency availability or ABI compatibility.
Auditing another project directory does not simulate starting R in that project.
No findings means no **visible** conflict, not a working Python setup.
Guidance targets reticulate 1.41+; older versions receive a warning.

## Background

The underlying problem is documented in
[reticulate's selection guidance](https://rstudio.github.io/reticulate/articles/versions.html)
and [managed requirements documentation](https://rstudio.github.io/reticulate/reference/py_require.html).
Examples of related reports include
[#1809](https://github.com/rstudio/reticulate/issues/1809) and
[#1832](https://github.com/rstudio/reticulate/issues/1832).
The latter discusses Python reproducibility across renv and managed environments;
retiaudit flags lockfile presence but does not solve that integration problem.

MIT license. No affiliation with the reticulate project.
