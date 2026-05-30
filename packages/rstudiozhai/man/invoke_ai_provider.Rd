\encoding{UTF-8}
\name{invoke_ai_provider}
\alias{invoke_ai_provider}
\title{Invoke an AI provider}
\usage{
invoke_ai_provider(request, provider_fun)
}
\arguments{
\item{request}{A request returned by \code{build_ai_task_request()}.}
\item{provider_fun}{A function that accepts the request and returns an AI response list.}
}
\description{
Calls a pluggable provider function and validates the provider response contract.
}
\value{
A normalized provider response list.
}

