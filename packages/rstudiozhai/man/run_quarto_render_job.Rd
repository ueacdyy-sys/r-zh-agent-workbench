\name{run_quarto_render_job}
\alias{run_quarto_render_job}
\title{Render a Quarto report through Jobs or Rscript}
\usage{
run_quarto_render_job(report_path, name = "Render Quarto report",
  working_dir = dirname(report_path), script_path = NULL, runner = NULL)
}
\arguments{
\item{report_path}{Path to a Quarto \code{.qmd} report.}
\item{name}{Job name shown in RStudio.}
\item{working_dir}{Working directory for the job.}
\item{script_path}{Optional script path for the generated render script.}
\item{runner}{Optional test seam that receives \code{script}, \code{name}, and \code{working_dir}.}
}
\value{
A list describing execution mode, generated script path, output, and status.
}
\description{
Uses \code{rstudioapi::jobRunScript()} when available, otherwise falls back to \code{Rscript}. The optional \code{runner} argument keeps the adapter testable without launching RStudio.
}
