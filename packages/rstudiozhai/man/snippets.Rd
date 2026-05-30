\name{rstudio_snippet_source_path}
\alias{rstudio_snippet_source_path}
\alias{rstudio_user_snippet_path}
\alias{read_bundled_rstudio_snippets}
\alias{install_rstudio_snippets}
\title{RStudio code snippet helpers}
\usage{
rstudio_snippet_source_path(language = "r")

rstudio_user_snippet_path(language = "r",
  appdata = Sys.getenv("APPDATA", unset = ""))

read_bundled_rstudio_snippets(language = "r")

install_rstudio_snippets(language = "r",
  target = rstudio_user_snippet_path(language), overwrite = FALSE,
  backup = TRUE)
}
\arguments{
\item{language}{Snippet language. Currently only \code{r} is bundled.}
\item{appdata}{Windows APPDATA path override.}
\item{target}{Target snippet file path.}
\item{overwrite}{Whether to overwrite an existing target file.}
\item{backup}{Whether to back up an existing target file before overwriting.}
}
\value{
Paths, snippet text, or an install result list.
}
\description{
Reads bundled RStudio snippets and explicitly installs them to a selected user snippet file.
}
