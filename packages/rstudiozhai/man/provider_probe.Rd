\name{probe_provider_models}
\alias{probe_provider_models}
\alias{extract_provider_model_ids}
\alias{format_provider_probe}
\alias{provider_model_choices}
\alias{apply_provider_model_choice}
\alias{suggest_provider_probe_actions}
\title{Probe provider model lists}
\usage{
extract_provider_model_ids(response)

probe_provider_models(provider = "compatible_chat", config = NULL,
  http_get = default_provider_probe_http_get, timeout_seconds = 10L)

format_provider_probe(probe)

suggest_provider_probe_actions(probe)

provider_model_choices(probe)

apply_provider_model_choice(provider, values, selected_model)
}
\arguments{
\item{response}{Decoded provider response from a model listing endpoint.}
\item{provider}{Provider name.}
\item{config}{Provider configuration list.}
\item{http_get}{Injectable HTTP GET function.}
\item{timeout_seconds}{HTTP timeout in seconds.}
\item{probe}{Probe result returned by \code{probe_provider_models()}.}
\item{values}{In-memory provider configuration values.}
\item{selected_model}{Model selected from a probe result.}
}
\description{
Performs a read-only model listing probe against OpenAI-compatible provider
gateways. The probe calls the provider's \code{/models} endpoint and returns a
structured result without writing files or exposing API key values.
}
\details{
Local providers such as \code{local} and \code{mock} return an empty successful
probe because they do not expose remote model lists. OpenAI-compatible providers
return model IDs extracted from common \code{data} or \code{models} response
shapes.
}
\value{
\code{extract_provider_model_ids()} returns a character vector of model IDs.
\code{probe_provider_models()} returns a list containing \code{ok},
\code{provider}, \code{url}, \code{count}, \code{models}, \code{warnings}, and
\code{error}. \code{format_provider_probe()} returns Markdown text.
\code{provider_model_choices()} returns named Shiny choices. 
\code{apply_provider_model_choice()} returns updated in-memory config values.
\code{suggest_provider_probe_actions()} returns a data frame of repair suggestions.
}
\seealso{
\code{\link{provider_config_status}}, \code{\link{build_provider_config}},
\code{\link{compatible_chat_provider}}
}
