\name{format_term_hits}
\alias{format_term_hits}
\alias{format_command_hits}
\alias{format_error_hits}
\title{Format knowledge-base matches}
\usage{
format_term_hits(hits)

format_command_hits(hits)

format_error_hits(hits)
}
\arguments{
\item{hits}{A data frame returned by a knowledge-base search function.}
}
\value{
A character string for display in the workbench UI.
}
\description{
Formats terminology, command, and error matches into compact text.
}
