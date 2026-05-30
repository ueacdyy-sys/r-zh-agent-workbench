\name{render_quarto_report}
\alias{render_quarto_report}
\title{Render a Quarto report}
\usage{
render_quarto_report(path, quarto = detect_quarto_info()$path)
}
\arguments{
\item{path}{Path to a \code{.qmd} file.}
\item{quarto}{Path to the Quarto executable.}
}
\value{
A list with render status and captured output.
}
\description{
Renders a Quarto report with the detected Quarto CLI.
}
