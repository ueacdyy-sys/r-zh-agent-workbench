\name{list_ai_providers}
\alias{list_ai_providers}
\alias{provider_choice_labels}
\alias{provider_config_status}
\alias{format_provider_status}
\alias{resolve_ai_provider}
\title{AI provider registry}
\usage{
list_ai_providers()

provider_choice_labels()

provider_config_status(provider = "local", config = NULL)

format_provider_status(status)

resolve_ai_provider(provider = "local", provider_fun = NULL)
}
\arguments{
\item{provider}{Provider id such as \code{local}, \code{mock}, or \code{openai_responses}.}
\item{config}{Optional provider configuration list. OpenAI config follows \code{get_openai_config()}.}
\item{status}{Result from \code{provider_config_status()}.}
\item{provider_fun}{Optional explicitly injected custom provider function.}
}
\value{
Provider metadata, UI choice vectors, status lists, formatted status text, or provider functions.
}
\description{
Registry and configuration helpers for selecting AI providers across the Addin,
CLI, MCP server, and tests.
}
\details{
The registry never persists API keys. OpenAI readiness reports whether an API key
is present, but it does not echo the key value.
}
