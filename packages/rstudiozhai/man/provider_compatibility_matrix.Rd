\name{provider_compatibility_matrix}
\alias{provider_compatibility_matrix}
\alias{filter_provider_compatibility_matrix}
\alias{format_provider_compatibility_matrix}
\title{Provider compatibility matrix}
\usage{
provider_compatibility_matrix(presets = provider_gateway_presets())

filter_provider_compatibility_matrix(matrix = provider_compatibility_matrix(),
  target_type = "")

format_provider_compatibility_matrix(matrix = provider_compatibility_matrix())
}
\arguments{
\item{presets}{Gateway presets returned by \code{provider_gateway_presets()}.}
\item{matrix}{Compatibility matrix returned by
\code{provider_compatibility_matrix()}.}
\item{target_type}{Optional target type filter: \code{offline},
\code{openai_api}, \code{local_gateway}, \code{cloud_gateway},
\code{enterprise_gateway}, or \code{all}.}
}
\description{
Returns a read-only matrix of AI provider and gateway compatibility targets for
the RStudio Chinese AI Workbench.
}
\details{
The matrix does not contact external services. It records the stable integration
surface for each target: provider adapter, preset id, base URL, endpoint, whether
an API key is normally required, whether model probing is supported, and the
recommended next step.
}
\value{
\code{provider_compatibility_matrix()} returns a data frame.
\code{filter_provider_compatibility_matrix()} returns a filtered data frame.
\code{format_provider_compatibility_matrix()} returns Markdown text.
}
\seealso{
\code{\link{provider_gateway_presets}},
\code{\link{collect_provider_integration_checklist}},
\code{\link{collect_provider_integration_report}}
}
