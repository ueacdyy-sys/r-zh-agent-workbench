\name{local_chinese_provider}
\alias{local_chinese_provider}
\title{Local Chinese rule-based AI provider}
\usage{
local_chinese_provider(request)
}
\arguments{
\item{request}{AI task request created by \code{build_ai_task_request()}.}
}
\value{
An AI provider response list.
}
\description{
Returns a deterministic Chinese workbench response without calling an external model. This is useful as an offline baseline, a fallback provider, and a contract test target.
}
