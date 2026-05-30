\name{sanitize_report_slug}
\alias{sanitize_report_slug}
\title{Sanitize a report title for file names}
\usage{
sanitize_report_slug(text)
}
\arguments{
\item{text}{Text to convert into a file-name-safe slug.}
}
\value{
A file-name-safe slug.
}
\description{
Converts a report title into an ASCII slug for generated Quarto file names.
}
