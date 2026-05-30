\name{create_quarto_render_job_script}
\alias{create_quarto_render_job_script}
\title{Create a Quarto render job script}
\usage{
create_quarto_render_job_script(report_path,
  script_path = tempfile("rstudiozhai-render-", fileext = ".R"))
}
\arguments{
\item{report_path}{Path to a Quarto \code{.qmd} report.}
\item{script_path}{Path where the render script should be written.}
}
\value{
Normalized path to the generated R script.
}
\description{
Writes a small R script that renders a Quarto report through \code{render_quarto_report()}.
}
