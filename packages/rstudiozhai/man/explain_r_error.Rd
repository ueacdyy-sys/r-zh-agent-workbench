\name{explain_r_error}
\alias{explain_r_error}
\title{Explain common R errors}
\usage{
explain_r_error(message, max_results = 3L)
}
\arguments{
\item{message}{R error message or text to inspect.}
\item{max_results}{Maximum number of rows to return.}
}
\value{
A data frame of matched error explanations.
}
\description{
Matches common R error patterns and returns Chinese explanations with suggested actions.
}
