\name{search_rstudio_commands}
\alias{search_rstudio_commands}
\title{Search RStudio commands}
\usage{
search_rstudio_commands(query, max_results = 5L)
}
\arguments{
\item{query}{Search query.}
\item{max_results}{Maximum number of rows to return.}
}
\value{
A ranked data frame of command matches.
}
\description{
Searches local RStudio command entries by label, Chinese label, category, entry point, and description.
}
