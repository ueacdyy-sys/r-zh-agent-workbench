\name{mcp_server_info}
\alias{mcp_server_info}
\alias{mcp_tool_definitions}
\alias{mcp_call_tool}
\alias{mcp_handle_request}
\alias{mcp_handle_json_line}
\alias{mcp_stdio_server}
\title{MCP server helpers for rstudiozhai}
\usage{
mcp_server_info()

mcp_tool_definitions()

mcp_call_tool(name, arguments = list())

mcp_handle_request(request)

mcp_handle_json_line(line)

mcp_stdio_server(input = NULL, output = stdout())
}
\arguments{
\item{name}{MCP tool name.}
\item{arguments}{Named list decoded from MCP tool arguments.}
\item{request}{JSON-RPC request list.}
\item{line}{One JSON-RPC request encoded as a single JSON line.}
\item{input}{Input connection for stdio transport. Defaults to \code{file("stdin", "r")} for Windows Rscript pipe compatibility.}
\item{output}{Output connection for stdio transport.}
}
\value{
Server metadata, MCP tool definitions, MCP tool results, JSON-RPC response lists,
JSON response lines, or invisible \code{TRUE} for the stdio server loop.
}
\description{
Minimal stdio MCP server surface for exposing RStudio Chinese AI Workbench commands
to external AI agents. The server implements \code{initialize}, \code{ping},
\code{tools/list}, and \code{tools/call}, and delegates tool execution to
\code{run_workbench_command()}.
}
\details{
Tool names are prefixed with \code{rstudiozhai_}. Tool errors are returned as MCP
tool results with \code{isError = TRUE}; JSON-RPC errors are reserved for protocol
and request-shape failures. The stdio server does not write logs to stdout.
}
