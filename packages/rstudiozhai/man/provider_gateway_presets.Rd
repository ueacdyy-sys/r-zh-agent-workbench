\name{provider_gateway_presets}
\alias{provider_gateway_presets}
\alias{provider_gateway_preset_choices}
\alias{provider_values_from_gateway_preset}
\alias{collect_provider_integration_checklist}
\alias{format_provider_gateway_presets}
\alias{format_provider_integration_checklist}
\title{Gateway presets and provider integration checklists}
\usage{
provider_gateway_presets()

provider_gateway_preset_choices()

provider_values_from_gateway_preset(preset = "ollama", model = "",
  base_url = "", endpoint = "", api_key = "")

collect_provider_integration_checklist(preset = "ollama", model = "",
  base_url = "", endpoint = "", api_key = "",
  include_report_command = TRUE)

format_provider_gateway_presets(presets = provider_gateway_presets())

format_provider_integration_checklist(checklist)
}
\arguments{
\item{preset}{Gateway preset id, such as \code{ollama}, \code{vllm},
\code{litellm}, or \code{enterprise_compatible}.}
\item{model}{Optional model name override.}
\item{base_url}{Optional base URL override.}
\item{endpoint}{Optional endpoint path override.}
\item{api_key}{Optional API key used only in returned current-session values.
Checklist output redacts this value.}
\item{include_report_command}{Whether to include a \code{provider-report}
command hint in the checklist.}
\item{presets}{Preset data frame returned by \code{provider_gateway_presets()}.}
\item{checklist}{Checklist returned by
\code{collect_provider_integration_checklist()}.}
}
\description{
Provides built-in OpenAI-compatible gateway presets and read-only manual
integration checklists for local, cloud, or enterprise model gateways.
}
\details{
The presets cover Ollama, LM Studio, Xinference, vLLM, LiteLLM, DeepSeek,
DashScope Qwen compatible mode, SiliconFlow, Zhipu GLM, Moonshot Kimi, and an
enterprise-compatible gateway. Applying a preset only creates in-memory
configuration values; it does not write environment variables, project files, or
user settings. The checklist is a human-readable readiness guide and does not
contact the network.
}
\value{
\code{provider_gateway_presets()} returns a data frame.
\code{provider_gateway_preset_choices()} returns named Shiny choices.
\code{provider_values_from_gateway_preset()} returns compatible-chat config
values. \code{collect_provider_integration_checklist()} returns a
JSON-serializable list with safe values, steps, and Markdown.
}
\seealso{
\code{\link{collect_provider_integration_report}},
\code{\link{probe_provider_models}},
\code{\link{provider_config_status}}
}
