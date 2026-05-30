\name{compatible_chat_provider}
\alias{compatible_chat_provider}
\alias{get_compatible_chat_config}
\alias{validate_compatible_chat_config}
\alias{build_compatible_chat_payload}
\alias{extract_compatible_chat_response_text}
\title{OpenAI-compatible chat gateway provider}
\usage{
get_compatible_chat_config(
  api_key = Sys.getenv("RSTUDIOZHAI_GATEWAY_API_KEY", unset = ""),
  model = Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = ""),
  base_url = Sys.getenv("RSTUDIOZHAI_GATEWAY_BASE_URL",
    unset = "http://127.0.0.1:11434/v1"),
  endpoint = Sys.getenv("RSTUDIOZHAI_GATEWAY_ENDPOINT",
    unset = "/chat/completions")
)

validate_compatible_chat_config(config)

build_compatible_chat_payload(request, model, max_tokens = 1200L,
  temperature = NULL, stream = FALSE)

extract_compatible_chat_response_text(response)

compatible_chat_provider(
  request,
  api_key = Sys.getenv("RSTUDIOZHAI_GATEWAY_API_KEY", unset = ""),
  model = Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = ""),
  base_url = Sys.getenv("RSTUDIOZHAI_GATEWAY_BASE_URL",
    unset = "http://127.0.0.1:11434/v1"),
  endpoint = Sys.getenv("RSTUDIOZHAI_GATEWAY_ENDPOINT",
    unset = "/chat/completions"),
  http_post = default_compatible_chat_http_post,
  max_tokens = 1200L,
  temperature = NULL,
  timeout_seconds = 60L
)
}
\arguments{
\item{api_key}{Optional gateway API key. Local gateways may leave it empty.}
\item{model}{Gateway model name. This package does not hard-code a model.}
\item{base_url}{Base URL for an OpenAI-compatible gateway.}
\item{endpoint}{Chat completions endpoint path.}
\item{config}{Configuration list returned by \code{get_compatible_chat_config()}.}
\item{request}{An \code{AiTaskRequest} created by \code{build_ai_task_request()}.}
\item{max_tokens}{Maximum output tokens for chat completions.}
\item{temperature}{Optional sampling temperature.}
\item{stream}{Whether to request streaming. The provider uses \code{FALSE}.}
\item{response}{Decoded gateway response list.}
\item{http_post}{Injectable HTTP function for tests and enterprise middleware.}
\item{timeout_seconds}{HTTP timeout in seconds.}
}
\description{
Provider adapter for local or enterprise OpenAI-compatible Chat Completions
gateways such as Ollama, vLLM, LiteLLM, or an internal proxy. API keys are
optional because local gateways commonly do not require authentication.
}
\details{
The default base URL points at the common local Ollama OpenAI-compatible
endpoint. The model still must be configured through
\code{RSTUDIOZHAI_GATEWAY_MODEL} or an explicit argument. API keys are never
stored in the provider response raw metadata.
}
\value{
Configuration lists, payload lists, extracted text, or an \code{AiTaskResponse}
list.
}
\seealso{
\code{\link{build_ai_task_request}}, \code{\link{invoke_ai_provider}},
\code{\link{provider_config_status}}
}
