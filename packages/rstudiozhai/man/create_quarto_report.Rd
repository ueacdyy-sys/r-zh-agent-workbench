\name{create_quarto_report}
\alias{create_quarto_report}
\title{Create a Quarto report file}
\usage{
create_quarto_report(task, ai_result, output_dir = getwd(),
  title = "RStudio Chinese AI Workbench Report",
  include_environment = TRUE, overwrite = FALSE)
}
\arguments{
\item{task}{User task text.}
\item{ai_result}{AI workbench result text.}
\item{output_dir}{Directory where the \code{.qmd} file should be written.}
\item{title}{Report title.}
\item{include_environment}{Whether to include an environment diagnostics section.}
\item{overwrite}{Whether to overwrite the default output path.}
}
\value{
A list with \code{ok}, \code{path}, \code{title}, \code{rendered}, and \code{render_output}.
}
\description{
Creates a Quarto \code{.qmd} report without rendering it. Rendering is intentionally separate so long tasks can move to Jobs or an external process.
}
