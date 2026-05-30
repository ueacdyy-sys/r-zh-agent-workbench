\name{available_workbench_commands}
\alias{available_workbench_commands}
\alias{provider_from_name}
\alias{run_workbench_command}
\alias{parse_workbench_cli_args}
\alias{encode_workbench_json}
\alias{workbench_cli_main}
\title{Workbench middleware and CLI helpers}
\usage{
available_workbench_commands()

provider_from_name(provider = "local", provider_fun = NULL)

run_workbench_command(command = "list-commands", params = list(),
  provider_fun = NULL)

parse_workbench_cli_args(args = commandArgs(trailingOnly = TRUE))

encode_workbench_json(result, pretty = TRUE)

workbench_cli_main(args = commandArgs(trailingOnly = TRUE),
  output = stdout())
}
\arguments{
\item{provider}{Provider name: \code{local}, \code{mock}, or \code{openai_responses}.}
\item{provider_fun}{Optional provider function injected by tests or host applications.}
\item{command}{Workbench command name from \code{available_workbench_commands()}.}
\item{params}{Named list of command parameters.}
\item{args}{Command-line arguments.}
\item{result}{Workbench command result envelope.}
\item{pretty}{Whether JSON output should be pretty-printed.}
\item{output}{Connection used for CLI JSON output. Use \code{NULL} to suppress writing.}
}
\value{
Command catalog data frames, provider functions, command result envelopes, parsed CLI
arguments, or JSON strings.
}
\description{
Stable local middleware surface for RStudio Chinese AI Workbench automation. The
command runner uses an allowlist and returns a consistent envelope so RStudio Addins,
scripts, future MCP servers, and external agents can share the same contract.
}
\details{
Write-capable commands such as \code{quarto-draft} require \code{allow_write = TRUE}
in \code{params}. Recoverable failures return \code{ok = FALSE} with a structured
\code{error} object instead of leaking low-level exceptions.
}
