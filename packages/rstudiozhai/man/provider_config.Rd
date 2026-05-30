\name{provider_config_fields}
\alias{provider_config_fields}
\alias{build_provider_config}
\alias{provider_config_status_from_values}
\alias{provider_from_config}
\title{Provider configuration helpers}
\usage{
provider_config_fields()

build_provider_config(provider, values = list())

provider_config_status_from_values(provider, values = list())

provider_from_config(provider, config = list(), http_post = NULL)
}
\arguments{
\item{provider}{Provider name from \code{list_ai_providers()}.}
\item{values}{Named list of in-memory UI or host application values.}
\item{config}{Provider configuration list.}
\item{http_post}{Optional injectable HTTP transport for tests or host middleware.}
}
\description{
Builds provider configuration from in-memory values without writing project files
or environment files. These helpers are used by the Addin configuration tab and
can also be reused by host applications.
}
\details{
Secret fields are identified by \code{provider_config_fields()}. Status helpers
report whether a key is present but never return the key value in formatted
status output. \code{provider_from_config()} returns a provider function bound to
the supplied configuration for the current R session.
}
\value{
A data frame of configuration fields, provider configuration lists, provider
status lists, or provider functions.
}
\seealso{
\code{\link{list_ai_providers}}, \code{\link{provider_config_status}},
\code{\link{openai_responses_provider}}, \code{\link{compatible_chat_provider}}
}
