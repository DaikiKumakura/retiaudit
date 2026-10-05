\name{audit_markdown}
\alias{audit_markdown}
\title{Format a Python Selection Audit}
\usage{audit_markdown(report)}
\arguments{\item{report}{A report from \code{audit_python()}.}}
\description{Formats the report without including local paths or environment values. Does not write files.}
\value{A character vector of Markdown lines. Review before sharing.}
\examples{
lines <- audit_markdown(audit_python(tempdir()))
cat(paste(lines, collapse = "\n"))
}
