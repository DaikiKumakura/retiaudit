\name{audit_python}
\alias{audit_python}
\title{Audit Visible Python Selection Hints}
\usage{audit_python(project = getwd(), intent = c("inspect", "managed", "existing"), expected = NULL)}
\arguments{
\item{project}{An existing project directory.}
\item{intent}{Selection intention: inspect, managed, or existing.}
\item{expected}{Optional expected interpreter file path.}
}
\description{Read-only preflight for reticulate selection hints. Does not load reticulate, start Python, run discovery, install software, or modify configuration.}
\value{A \code{retiaudit_report} containing hints, markers, findings and scope. Environment values and paths are omitted.}
\details{This is not an interpreter-selection prediction or dependency validation. Runtime use_python requests and delayed imports are not observed. Project startup files are not evaluated. A local virtualenv marker does not prove a valid interpreter. Guidance targets reticulate 1.41 and later.}
\examples{
report <- audit_python(tempdir(), intent = "managed")
report
}
