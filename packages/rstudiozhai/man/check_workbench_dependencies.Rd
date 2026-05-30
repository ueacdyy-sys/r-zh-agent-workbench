\name{check_workbench_dependencies}
\alias{check_workbench_dependencies}
\title{Check Addin runtime dependencies}
\usage{
check_workbench_dependencies(required = required_workbench_packages())
}
\arguments{
\item{required}{Character vector of package names to check.}
}
\value{
A list with \code{ok} and \code{missing}.
}
\description{
Checks whether packages required by the RStudio Addin UI are installed.
}
