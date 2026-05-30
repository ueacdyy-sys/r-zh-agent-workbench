\name{openai_responses_provider}
\alias{openai_responses_provider}
\title{OpenAI Responses API provider adapter}
\usage{
openai_responses_provider(request, api_key = Sys.getenv("OPENAI_API_KEY",
  unset = ""), model = Sys.getenv("RSTUDIOZHAI_OPENAI_MODEL", unset = ""),
  base_url = Sys.getenv("RSTUDIOZHAI_OPENAI_BASE_URL",
    unset = "https://api.openai.com/v1"),
  http_post = default_openai_http_post, max_output_tokens = 1200L,
  temperature = NULL, timeout_seconds = 60L)
}
\arguments{
\item{request}{AI task request created by \code{build_ai_task_request()}.}
\item{api_key}{API key. Defaults to \code{OPENAI_API_KEY}.}
\item{model}{Model name. Defaults to \code{RSTUDIOZHAI_OPENAI_MODEL}.}
\item{base_url}{Base API URL. Defaults to \code{https://api.openai.com/v1}.}
\item{http_post}{Injectable HTTP transport function.}
\item{max_output_tokens}{Maximum output tokens requested.}
\item{temperature}{Optional temperature.}
\item{timeout_seconds}{HTTP timeout.}
}
\value{
An \code{AiTaskResponse} list.
}
\description{
Adapts an \code{AiTaskRequest} to the OpenAI Responses API shape and converts the result back to the workbench provider contract. The HTTP transport is injectable so tests do not require network access or real credentials.
}
