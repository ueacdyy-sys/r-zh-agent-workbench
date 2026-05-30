\encoding{UTF-8}
\name{build_ai_task_request}
\alias{build_ai_task_request}
\title{Build an AI task request}
\usage{
build_ai_task_request(task, context = list(), mode = "diagnose",
  provider = "mock", allow_code_execution = FALSE,
  require_user_confirmation = TRUE)
}
\arguments{
\item{task}{A non-empty user task string.}
\item{context}{A named list with document, error, project, or environment context.}
\item{mode}{One of explain, edit, generate, diagnose.}
\item{provider}{Provider identifier.}
\item{allow_code_execution}{Whether generated code may be executed automatically.}
\item{require_user_confirmation}{Whether user confirmation is required before applying changes.}
}
\description{
Creates the stable contract object used by the Chinese AI workbench before any provider is called.
}
\value{
A list representing an AI task request.
}

