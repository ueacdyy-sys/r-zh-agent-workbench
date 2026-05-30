\name{summarize_audit_params}
\alias{summarize_audit_params}
\alias{check_workbench_policy}
\alias{append_workbench_audit_event}
\alias{read_workbench_audit_log}
\alias{format_workbench_audit_log}
\title{Policy and audit helpers}
\usage{
summarize_audit_params(params)

check_workbench_policy(command, params, catalog = available_workbench_commands())

append_workbench_audit_event(path, event)

read_workbench_audit_log(path, limit = 20L)

format_workbench_audit_log(events)
}
\arguments{
\item{params}{Named command parameter list.}
\item{command}{Workbench command name.}
\item{catalog}{Command catalog from \code{available_workbench_commands()}.}
\item{path}{Audit JSONL file path.}
\item{event}{Audit event list.}
\item{limit}{Maximum events to read.}
\item{events}{Audit event data frame.}
}
\value{
Sanitized parameter summaries, policy result lists, logical append results, audit
event data frames, or Markdown-style summaries.
}
\description{
Secure-by-default policy and audit utilities for Workbench CLI/MCP commands.
}
\details{
Audit logging is opt-in through \code{audit_path} or \code{RSTUDIOZHAI_AUDIT_LOG}.
Sensitive names such as API keys, passwords, tokens, secrets, and authorization
headers are redacted. Large user payloads such as tasks, code selections, and AI
results are summarized by type and length instead of being copied into logs.
}
