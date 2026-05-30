\name{get_openai_config}
\alias{get_openai_config}
\alias{validate_openai_config}
\alias{build_openai_instructions}
\alias{build_openai_input}
\alias{build_openai_responses_payload}
\alias{extract_openai_response_text}
\title{OpenAI provider helper functions}
\usage{
get_openai_config(api_key = Sys.getenv("OPENAI_API_KEY", unset = ""),
  model = Sys.getenv("RSTUDIOZHAI_OPENAI_MODEL", unset = ""),
  base_url = Sys.getenv("RSTUDIOZHAI_OPENAI_BASE_URL",
    unset = "https://api.openai.com/v1"))

validate_openai_config(config)

build_openai_instructions(request)

build_openai_input(request, max_chars = 12000L)

build_openai_responses_payload(request, model, max_output_tokens = 1200L,
  temperature = NULL)

extract_openai_response_text(response)
}
\arguments{
\item{api_key}{API key.}
\item{model}{Model name.}
\item{base_url}{Base API URL.}
\item{config}{OpenAI provider config list.}
\item{request}{AI task request.}
\item{max_chars}{Maximum context characters.}
\item{max_output_tokens}{Maximum output tokens.}
\item{temperature}{Optional temperature.}
\item{response}{Provider response list.}
}
\value{
Configuration lists, request payloads, or extracted output text.
}
\description{
Helper functions for building and validating OpenAI Responses API provider calls.
}
