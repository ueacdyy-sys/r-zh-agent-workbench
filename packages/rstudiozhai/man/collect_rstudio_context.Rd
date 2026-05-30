\name{collect_rstudio_context}
\alias{collect_rstudio_context}
\title{Collect RStudio editor context}
\usage{
collect_rstudio_context(max_chars = 12000L)
}
\arguments{
\item{max_chars}{Maximum number of characters to keep from the active document.}
}
\value{
A named list describing RStudio availability, active project, active document, and selection.
}
\description{
Collects a bounded context snapshot through \pkg{rstudioapi}. Outside RStudio, it returns a stable unavailable shape.
}
