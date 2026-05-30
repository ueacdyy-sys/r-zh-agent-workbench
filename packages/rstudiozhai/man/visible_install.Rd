\name{visible_install}
\alias{rstudio_user_rprofile_path}
\alias{install_rstudio_startup_banner}
\alias{remove_rstudio_startup_banner}
\alias{install_rstudio_visible_entry}
\title{Install visible RStudio entry points}
\usage{
rstudio_user_rprofile_path(home = path.expand("~"))

install_rstudio_startup_banner(path = rstudio_user_rprofile_path(),
  backup = TRUE)

remove_rstudio_startup_banner(path = rstudio_user_rprofile_path(),
  backup = TRUE)

install_rstudio_visible_entry(rprofile = rstudio_user_rprofile_path(),
  install_snippets = TRUE, overwrite_snippets = FALSE)
}
\arguments{
\item{home}{User home directory.}
\item{path}{Target \code{.Rprofile} path.}
\item{backup}{Whether to create a timestamped backup before changing an existing file.}
\item{rprofile}{Target user \code{.Rprofile} path.}
\item{install_snippets}{Whether to install bundled RStudio snippets.}
\item{overwrite_snippets}{Whether to overwrite an existing user snippet file.}
}
\description{
Installs or removes a marked startup banner in the user \code{.Rprofile} so
RStudio visibly reports that the Chinese AI Workbench is installed. The
installer is idempotent and preserves existing content.
}
