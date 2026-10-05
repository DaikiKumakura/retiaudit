# `py_require()` followed by `ModuleNotFoundError`: check environment selection first

Declaring Python requirements and selecting an existing interpreter are different
operations. When reticulate uses a self-managed environment, `py_require()` does
not install its declarations into that environment.

## Check before importing

```r
retiaudit::audit_python(intent = "managed")
```

For an explicit interpreter override, a relevant finding is:

```text
EXPLICIT_OVERRIDE_BLOCKS_MANAGED [warning]
An explicit interpreter override takes precedence over managed selection.
```

No Python installation is inspected or modified by this check.

## Choose the intended approach

**Managed requirements:** in a fresh R session, before any Python interaction,
deliberately choose managed selection:

```r
Sys.setenv(RETICULATE_PYTHON = "managed")
library(reticulate)
py_require("colorama==0.4.6")
colorama <- import("colorama")
```

This can download Python, uv and packages. It changes which environment will be
used, so it is not an automatic remedy for projects that intentionally pin an
existing interpreter or use renv to manage Python. The above managed recipe
comes from official guidance; this example's local verification instead used
the existing-environment approach below.

**Existing environment:** keep that interpreter selected and install the missing
package into that specific environment using its package-management workflow.
For a dedicated disposable virtualenv, a concrete command is:

```text
python -m pip --python path/to/venv/python install colorama==0.4.6
```

Here the first `python` must have a pip version that supports `--python`. On
Windows the virtualenv interpreter is normally `venv/Scripts/python.exe`; on
Unix-like systems it is `venv/bin/python`. This explicitly installs a package;
the audit does not run it for you. Respect your project's dependency policy.

## Reproduce the failure and existing-environment remedy

1. Create a dedicated virtualenv with `python -m venv --without-pip demo-venv`.
2. Run `explicit-environment.R` with its interpreter path and `before`.
3. Install colorama into that environment using the command above.
4. Run the script in another fresh R process, with the same path and `after`.

Verified on Windows with R 4.5.1 and reticulate 1.46.0: the preflight found the
override before reticulate was loaded; the first import failed; the import
succeeded after installation into the explicitly selected environment.
This demonstrates one failure mode, not every cause of ModuleNotFoundError.

## What this cannot diagnose

retiaudit 0.1.0 does not observe runtime `use_python()` requests. The report in
[reticulate #1809](https://github.com/rstudio/reticulate/issues/1809) includes
such a request, and that report already has a maintainer response and a
confirmed workaround. This example illustrates a related environment-variable
override; it is not a verified reproduction or complete fix for that issue.

For actual interpreter discovery, see
[`py_discover_config()`](https://rstudio.github.io/reticulate/reference/py_discover_config.html).
For the selection policy and managed requirements, see
[order of discovery](https://rstudio.github.io/reticulate/articles/versions.html#order-of-discovery)
and [`py_require()`](https://rstudio.github.io/reticulate/reference/py_require.html).
