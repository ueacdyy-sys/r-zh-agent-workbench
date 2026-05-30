\name{connection_template_catalog}
\alias{connection_template_catalog}
\alias{list_connection_templates}
\alias{connection_snippet_dir}
\alias{connection_snippet_path}
\alias{read_connection_snippet}
\alias{build_dbi_connection_code}
\alias{connection_dcf_path}
\title{RStudio connection snippet helpers}
\usage{
connection_template_catalog()

list_connection_templates()

connection_snippet_dir()

connection_snippet_path(id)

read_connection_snippet(id)

build_dbi_connection_code(kind, variable = "con",
  use_password_prompt = TRUE)

connection_dcf_path()
}
\arguments{
\item{id}{Connection template id.}
\item{kind}{One of \code{sqlite}, \code{postgres}, or \code{odbc}.}
\item{variable}{R object name to assign the connection to.}
\item{use_password_prompt}{Whether to use \code{rstudioapi::askForPassword()} instead of \code{Sys.getenv("DB_PASSWORD")}.}
}
\value{
Data frames, paths, or generated R code.
}
\description{
Helpers for RStudio Connection Snippets and safe DBI connection code generation.
}
