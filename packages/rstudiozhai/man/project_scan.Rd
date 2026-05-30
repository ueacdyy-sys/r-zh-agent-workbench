\name{collect_project_scan}
\alias{collect_project_scan}
\alias{format_project_scan}
\title{Scan a local RStudio project}
\usage{
collect_project_scan(
  path = getwd(),
  max_files = 200L,
  max_bytes = 4096L,
  include_patterns = character(),
  exclude_dirs = default_project_scan_exclude_dirs(),
  include_text = FALSE
)

format_project_scan(scan, max_files = 20L)
}
\arguments{
\item{path}{Project directory to scan.}
\item{max_files}{Maximum number of files to return.}
\item{max_bytes}{Maximum bytes per file to read when \code{include_text} is \code{TRUE}.}
\item{include_patterns}{Optional regular expressions matched against project-relative paths.}
\item{exclude_dirs}{Directory names or project-relative prefixes to skip.}
\item{include_text}{Whether to include small text previews. Defaults to \code{FALSE}.}
\item{scan}{A project scan object returned by \code{collect_project_scan()}.}
}
\description{
Collects a bounded, read-only summary of a local R/RStudio project. The scanner
skips heavy directories such as \code{.git}, \code{.Rproj.user},
\code{renv/library}, and \code{node_modules} by default. File contents are not
included unless \code{include_text = TRUE}, and then only for small text files
under \code{max_bytes}.
}
\value{
\code{collect_project_scan()} returns a list containing \code{root},
\code{limits}, \code{summary}, \code{markers}, \code{files}, \code{warnings},
and a Markdown summary. \code{format_project_scan()} returns a Markdown string.
}
\seealso{
\code{\link{run_workbench_command}}
}
