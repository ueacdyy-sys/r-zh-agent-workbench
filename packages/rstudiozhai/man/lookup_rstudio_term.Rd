\name{lookup_rstudio_term}
\alias{lookup_rstudio_term}
\title{Search RStudio terminology}
\usage{
lookup_rstudio_term(query, max_results = 5L)
}
\arguments{
\item{query}{Search query.}
\item{max_results}{Maximum number of rows to return.}
}
\value{
A ranked data frame of terminology matches.
}
\description{
Searches local Chinese RStudio terminology by English term, Chinese label, category, description, and action.
}
