\name{collect_rstudio_extension_status}
\alias{collect_rstudio_extension_status}
\alias{format_rstudio_extension_status}
\title{Validate installed RStudio extension resources}
\usage{
collect_rstudio_extension_status(rstudio = detect_rstudio_info())

format_rstudio_extension_status(status)
}
\arguments{
\item{rstudio}{Optional RStudio detection result. Defaults to
\code{detect_rstudio_info()}; tests can pass a stub to validate package resources
on machines without RStudio Desktop.}

\item{status}{Result from \code{collect_rstudio_extension_status()}.}
}
\value{
A structured status list or a Chinese Markdown-style report.
}
\description{
Read-only validation for the installed RStudio Addin, Project Template,
Connections metadata, connection snippets, and bundled R snippets.
}
\details{
This check does not launch RStudio and does not write user configuration. It parses
package DCF files and verifies that RStudio Binding fields point to exported
package functions.
}
