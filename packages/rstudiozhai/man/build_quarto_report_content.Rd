\name{build_quarto_report_content}
\alias{build_quarto_report_content}
\title{Build Quarto report content}
\usage{
build_quarto_report_content(title, task, ai_result, environment_report = NULL)
}
\arguments{
\item{title}{Report title.}
\item{task}{User task text.}
\item{ai_result}{AI workbench result text.}
\item{environment_report}{Optional environment report list.}
}
\value{
A character string containing a Quarto document.
}
\description{
Builds a minimal Quarto report document from a workbench task and result.
}
