\name{summarize_knowledge_for_query}
\alias{summarize_knowledge_for_query}
\title{Summarize knowledge-base matches for a query}
\usage{
summarize_knowledge_for_query(query, error_message = "")
}
\arguments{
\item{query}{Search query or task text.}
\item{error_message}{Optional explicit error message to match.}
}
\value{
A compact character summary of matched terms, commands, and errors.
}
\description{
Combines terminology lookup, command lookup, and common R error explanations for use by local providers and Addin UI.
}
