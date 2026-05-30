\name{create_zh_ai_project}
\alias{create_zh_ai_project}
\title{Create an RStudio Chinese AI analysis project}
\usage{
create_zh_ai_project(path, project_name = basename(normalizePath(path,
  winslash = "/", mustWork = FALSE)), include_quarto = TRUE,
  include_renv_note = TRUE, ...)
}
\arguments{
\item{path}{Project directory to create.}
\item{project_name}{Project name used in generated files.}
\item{include_quarto}{Whether to create a starter Quarto report.}
\item{include_renv_note}{Whether to create dependency-locking notes.}
\item{...}{Reserved for future RStudio Project Template parameters.}
}
\value{
An invisible list with project path and generated file list.
}
\description{
Creates a reproducible starter RStudio project for the Chinese AI Workbench ecosystem.
}
