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

## Quick start

```r
library(retiaudit)
audit_python(intent = "managed")     # you use py_require()
audit_python(intent = "existing", expected = "/path/to/python")
```

## Documentation

[Package website](https://daikikumakura.github.io/retiaudit/) · [Function reference](https://daikikumakura.github.io/retiaudit/reference/) · [Changelog](https://daikikumakura.github.io/retiaudit/news/) · [Releases](https://github.com/DaikiKumakura/retiaudit/releases) · [R-universe](https://daikikumakura.r-universe.dev/retiaudit) · [Usage guide](https://github.com/DaikiKumakura/retiaudit/blob/main/README-GUIDE.md)

## Validation and limitations

- **Validation:** Checked Python-selection hints with fixtures in the R test suite.
- **Results:** Checks cover visible overrides and project settings without loading reticulate or starting Python.
- **Limitations:** The audit cannot establish which Python a later R session actually starts or whether that environment works.
- **Reproduction:** [tests/testthat](https://github.com/DaikiKumakura/retiaudit/tree/main/tests/testthat).

## Citation

Kumakura, D. (2026). *retiaudit: Inspect Python Selection Hints Without Starting Python* [Software]. [DOI: 10.5281/zenodo.24210475](https://doi.org/10.5281/zenodo.24210475).

Citation metadata: [CITATION.cff](CITATION.cff).

## License

This project is licensed under MIT. See [LICENSE.md](LICENSE.md) for the license terms.

This project is independent of the reticulate project.
