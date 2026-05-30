\name{create_workbench_app}
\alias{create_workbench_app}
\title{Create the workbench Shiny gadget}
\usage{
create_workbench_app(provider_fun = NULL, provider_name = "local",
  context_collector = collect_rstudio_context)
}
\arguments{
\item{provider_fun}{Optional injected provider function for custom providers. Built-in providers are resolved from the provider registry.}
\item{provider_name}{Initial provider selected in the UI and recorded in the AI task request.}
\item{context_collector}{Function that returns the current RStudio context.}
}
\value{
A list with \code{ui} and \code{server}, suitable for \code{shiny::runGadget()}.
}
\description{
Builds the UI and server for the Chinese AI Workbench without launching it, so the Addin can be tested separately from RStudio.
}
