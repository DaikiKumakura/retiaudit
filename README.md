# retiaudit

<!-- badges: start -->
[![R-universe](https://daikikumakura.r-universe.dev/badges/retiaudit)](https://daikikumakura.r-universe.dev/retiaudit)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24210475.svg)](https://doi.org/10.5281/zenodo.24210475)
<!-- badges: end -->

**Why is reticulate ignoring my managed Python requirements? A preflight
check of the settings that steer Python selection, run before Python starts.**

## Installation

```r
install.packages("retiaudit", repos = c(
  "https://daikikumakura.r-universe.dev",
  "https://cloud.r-project.org"
))
```

Or from GitHub: `remotes::install_github("DaikiKumakura/retiaudit")`. Not on
CRAN.

## Quick start

```r
library(retiaudit)
audit_python(intent = "managed")     # you use py_require()
audit_python(intent = "existing", expected = "/path/to/python")
```

| Function | What it does |
|---|---|
| `audit_python(intent)` | Collects the hints and returns a report with findings (code and severity) |
| `audit_markdown(report)` | Turns the report into Markdown to paste into an issue or a note |

The printed report has three parts: the environment hints (set or not), the
project markers (present or not), and the findings.

## Documentation

[Package website](https://daikikumakura.github.io/retiaudit/) · [Function reference](https://daikikumakura.github.io/retiaudit/reference/) · [Changelog](https://daikikumakura.github.io/retiaudit/news/) · [Releases](https://github.com/DaikiKumakura/retiaudit/releases) · [R-universe](https://daikikumakura.r-universe.dev/retiaudit)

## Overview

<details>
<summary>Show details</summary>

You call `py_require()`, and then `import` fails with `ModuleNotFoundError`.
Often an old setting, such as `RETICULATE_PYTHON` or an activated virtualenv,
makes reticulate use a different Python. retiaudit lists the visible
selection hints and checks them against what you intend:

- **Before Python starts.** It does not load reticulate, run its discovery,
  start Python or run any file.
- **Against your intent.** Say whether you want a managed environment
  (`py_require()`) or an existing one, and it reports what conflicts.
- **Safe to share.** Reports leave out environment values, local paths and
  file contents.
- **Small.** No dependencies; it reads only selected environment variables,
  package metadata and whether files exist.

**Documentation:** <https://daikikumakura.github.io/retiaudit/>

</details>

## Example: an old override blocks the managed environment

<details>
<summary>Show details</summary>

This synthetic example sets `RETICULATE_PYTHON` to a placeholder file; it
does not run that file or start Python:

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
#>                               code severity
#> 1 EXPLICIT_OVERRIDE_BLOCKS_MANAGED  warning
```

The [reproduced failure, diagnosis and remedy](https://github.com/DaikiKumakura/retiaudit/blob/main/inst/examples/managed-selection.md)
shows the whole case: the error, what retiaudit reports, and how to choose a
managed or an existing environment deliberately.

</details>

## What it checks

<details>
<summary>Show details</summary>

| Hint | Examples |
|---|---|
| Explicit overrides | interpreter path, named environment |
| Managed environments | enable and disable flags, with their precedence |
| Active environments | activated virtualenv, project-local virtualenv folders |
| Other markers | Poetry and Pipenv files, interpreter fallback, default `r-reticulate` environment |
| Consistency | missing interpreter files, disagreement with an expected path |
| Startup | presence of `.Rprofile`, `.Renviron` and `renv.lock` (contents are not read) |

The audit checks that a file exists, not that it is a working Python. It
never changes settings or recommends deleting an environment: review the
findings and decide in a fresh R session.

</details>

## How it differs from reticulate's diagnostics

<details>
<summary>Show details</summary>

| Tool | Purpose |
| --- | --- |
| `reticulate::py_config()` | Inspect the Python configuration; can initialize Python |
| `reticulate::py_discover_config()` | Discover a configuration without loading Python; discovery still runs |
| `retiaudit::audit_python()` | Check visible hints against your intent, without loading reticulate or running discovery |

retiaudit complements the official diagnostics; it does not reimplement
reticulate's discovery.

</details>

## Share a report

<details>
<summary>Show details</summary>

```r
report <- audit_python(intent = "managed")
cat(paste(audit_markdown(report), collapse = "\n"))
# writeLines(audit_markdown(report), "python-preflight.md")
```

The report keeps fixed variable names, marker names, presence flags and the
reticulate version, and leaves out environment values, local paths,
startup-file contents, requirements and error traces. Review it before
sharing.

</details>

## Background

<details>
<summary>Show details</summary>

The problem is described in reticulate's
[selection guidance](https://rstudio.github.io/reticulate/articles/versions.html)
and [managed requirements documentation](https://rstudio.github.io/reticulate/reference/py_require.html);
related reports include [rstudio/reticulate#1809](https://github.com/rstudio/reticulate/issues/1809)
and [rstudio/reticulate#1832](https://github.com/rstudio/reticulate/issues/1832).
retiaudit flags an renv lockfile but does not solve the integration of renv
and managed environments.

</details>

<a id="limits"></a>

## Validation and limitations

- No network calls, subprocesses, environment changes, installation, file
  writes, startup-file execution or reticulate loading.
- It does not see `use_python()` calls, a Python that is already loaded,
  delayed imports, global startup code, package availability or ABI
  compatibility.
- Auditing another project folder does not simulate starting R there.
- No findings means no **visible** conflict, not a working Python setup.
- Written for reticulate 1.41 or later; older versions get a warning.

## Citation

Kumakura, D. (2026). *retiaudit: Inspect Python Selection Hints Without Starting Python* [Software]. [DOI: 10.5281/zenodo.24210475](https://doi.org/10.5281/zenodo.24210475).

Citation metadata: [CITATION.cff](CITATION.cff).

## License

This project is licensed under MIT. See [LICENSE.md](LICENSE.md) for the license terms.

This project is independent of the reticulate project.
