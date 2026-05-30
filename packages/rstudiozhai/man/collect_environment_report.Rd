\encoding{UTF-8}
\name{collect_environment_report}
\alias{collect_environment_report}
\title{Collect an RStudio environment report}
\usage{
collect_environment_report(packages = default_required_packages())
}
\arguments{
\item{packages}{Character vector of package names to check.}
}
\description{
Collects lightweight diagnostics for R, RStudio, Quarto, and package availability.
}
\value{
A structured list containing environment status and suggestions.
}

