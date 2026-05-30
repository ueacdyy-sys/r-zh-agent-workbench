\name{provider_integration_report}
\alias{collect_provider_integration_report}
\alias{format_provider_integration_report}
\title{Collect an AI provider integration report}
\usage{
collect_provider_integration_report(provider = "compatible_chat",
  values = list(), config = NULL, include_environment = TRUE,
  include_extension = TRUE, packages = "stats",
  probe_fun = probe_provider_models, timeout_seconds = 10L)

format_provider_integration_report(report)
}
\arguments{
\item{provider}{Provider name, such as \code{openai_responses} or
\code{compatible_chat}.}
\item{values}{In-memory provider configuration values from an Addin, CLI
caller, or host application.}
\item{config}{Optional provider configuration list. When supplied, this is
used instead of \code{values}.}
\item{include_environment}{Whether to include a local environment report.}
\item{include_extension}{Whether to include the RStudio extension install
status report.}
\item{packages}{R package names to check in the optional environment section.}
\item{probe_fun}{Injectable provider probe function. Tests can supply this to
avoid real network calls.}
\item{timeout_seconds}{Provider probe timeout in seconds.}
\item{report}{Report returned by \code{collect_provider_integration_report()}.}
}
\description{
Collects a read-only integration report for local or enterprise AI provider
gateways. The report combines provider registry metadata, readiness status, a
safe configuration summary, model probe results, repair suggestions, and
optional local environment and RStudio extension status.
}
\details{
The report never returns API key values. It exposes only whether a key is
present. The model probe is injectable, which keeps tests deterministic and
allows enterprise gateway adapters to reuse the same contract.
}
\value{
\code{collect_provider_integration_report()} returns a JSON-serializable list
containing \code{generated_at}, \code{provider}, \code{overall_ok},
\code{registry}, \code{status}, \code{config}, \code{probe},
\code{environment}, \code{extension}, and \code{markdown}.
\code{format_provider_integration_report()} returns Markdown text.
}
\seealso{
\code{\link{probe_provider_models}}, \code{\link{provider_config_status}},
\code{\link{collect_environment_report}},
\code{\link{collect_rstudio_extension_status}}
}
