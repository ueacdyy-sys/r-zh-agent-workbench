\encoding{UTF-8}
\name{run_workbench}
\alias{run_workbench}
\title{Run the RStudio Chinese AI workbench addin}
\usage{
run_workbench(provider_fun = NULL, provider_name = "local")
}
\arguments{
\item{provider_fun}{Optional injected provider function for custom providers. Built-in providers are resolved from the provider registry.}
\item{provider_name}{Initial provider selected in the Addin UI and recorded in the AI task request.}
}
\description{
Starts the RStudio Addin UI when \code{rstudioapi}, \code{shiny}, and \code{miniUI} are available.
If UI dependencies are missing, a Chinese diagnostic report is printed before a clear error.
}
\value{
Invisible result from the Shiny gadget.
}
