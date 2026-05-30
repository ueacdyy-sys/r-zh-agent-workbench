provider_gateway_presets <- function() {
  data.frame(
    preset = c(
      "ollama",
      "lmstudio",
      "xinference",
      "vllm",
      "litellm",
      "deepseek",
      "dashscope_qwen",
      "siliconflow",
      "zhipu_glm",
      "moonshot_kimi",
      "enterprise_compatible"
    ),
    label = c(
      "Ollama local gateway",
      "LM Studio local gateway",
      "Xinference local gateway",
      "vLLM OpenAI-compatible server",
      "LiteLLM proxy",
      "DeepSeek API",
      "DashScope Qwen compatible mode",
      "SiliconFlow API",
      "Zhipu GLM API",
      "Moonshot Kimi API",
      "Enterprise OpenAI-compatible gateway"
    ),
    provider = rep("compatible_chat", 11L),
    target_type = c(
      "local_gateway",
      "local_gateway",
      "local_gateway",
      "local_gateway",
      "local_gateway",
      "cloud_gateway",
      "cloud_gateway",
      "cloud_gateway",
      "cloud_gateway",
      "cloud_gateway",
      "enterprise_gateway"
    ),
    base_url = c(
      "http://127.0.0.1:11434/v1",
      "http://127.0.0.1:1234/v1",
      "http://127.0.0.1:9997/v1",
      "http://127.0.0.1:8000/v1",
      "http://127.0.0.1:4000/v1",
      "https://api.deepseek.com/v1",
      "https://dashscope.aliyuncs.com/compatible-mode/v1",
      "https://api.siliconflow.cn/v1",
      "https://open.bigmodel.cn/api/paas/v4",
      "https://api.moonshot.cn/v1",
      "https://gateway.example.com/v1"
    ),
    endpoint = rep("/chat/completions", 11L),
    requires_api_key = c(FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
    default_model = c(
      "llama3.1",
      "local-model",
      "qwen2.5-instruct",
      "served-model-name",
      "configured-model-alias",
      "deepseek-chat",
      "qwen-plus",
      "deepseek-ai/DeepSeek-V3",
      "glm-4.7",
      "kimi-latest",
      "enterprise-model"
    ),
    description = c(
      "Use when Ollama exposes an OpenAI-compatible /v1 endpoint on the local machine.",
      "Use when LM Studio exposes a local OpenAI-compatible server.",
      "Use when Xinference exposes an OpenAI-compatible /v1 endpoint.",
      "Use when vLLM serves a model through its OpenAI-compatible API server.",
      "Use when LiteLLM proxies local or remote models behind a single OpenAI-compatible endpoint.",
      "Use when DeepSeek's OpenAI-compatible API is the selected gateway.",
      "Use when Alibaba Cloud DashScope exposes Qwen through OpenAI-compatible mode.",
      "Use when SiliconFlow exposes model endpoints through an OpenAI-compatible API.",
      "Use when Zhipu GLM exposes OpenAI-compatible chat completions.",
      "Use when Moonshot Kimi exposes OpenAI-compatible chat completions.",
      "Use when an internal enterprise gateway exposes OpenAI-compatible chat completions."
    ),
    recommended_use = c(
      "Local offline-friendly experiments and demos.",
      "Local desktop model experiments with a GUI-managed model server.",
      "Local or LAN model serving with multiple model families.",
      "High-throughput local or server GPU inference.",
      "Unified proxy for multiple local, cloud, or enterprise providers.",
      "Cloud hosted DeepSeek chat models.",
      "Cloud hosted Qwen chat models through DashScope compatible mode.",
      "Cloud hosted model routing through SiliconFlow.",
      "Cloud hosted GLM chat models.",
      "Cloud hosted Kimi chat models.",
      "Internal model governance, audit, and proxy scenarios."
    ),
    docs_url = c(
      "https://ollama.com/blog/openai-compatibility",
      "https://lmstudio.ai/docs/app/api/endpoints/openai",
      "https://inference.readthedocs.io/",
      "https://docs.vllm.ai/",
      "https://docs.litellm.ai/",
      "https://api-docs.deepseek.com/",
      "https://help.aliyun.com/zh/model-studio/developer-reference/compatibility-of-openai-with-dashscope",
      "https://docs.siliconflow.cn/",
      "https://docs.bigmodel.cn/",
      "https://platform.moonshot.cn/docs/",
      ""
    ),
    stringsAsFactors = FALSE
  )
}

provider_gateway_preset_choices <- function() {
  presets <- provider_gateway_presets()
  stats::setNames(presets$preset, paste0(presets$label, " [", presets$preset, "]"))
}

assert_provider_gateway_preset <- function(preset) {
  presets <- provider_gateway_presets()
  if (!is.character(preset) || length(preset) != 1L || !nzchar(trimws(preset))) {
    stop("preset must be a non-empty string", call. = FALSE)
  }
  preset <- trimws(preset)
  if (!preset %in% presets$preset) {
    stop(
      "Unknown gateway preset: ",
      preset,
      ". Supported presets: ",
      paste(presets$preset, collapse = ", "),
      call. = FALSE
    )
  }
  preset
}

provider_gateway_preset_entry <- function(preset) {
  preset <- assert_provider_gateway_preset(preset)
  presets <- provider_gateway_presets()
  presets[match(preset, presets$preset), , drop = FALSE]
}

provider_values_from_gateway_preset <- function(preset = "ollama",
                                                model = "",
                                                base_url = "",
                                                endpoint = "",
                                                api_key = "") {
  row <- provider_gateway_preset_entry(preset)
  model <- trimws(as.character(model[[1L]]))
  base_url <- trimws(as.character(base_url[[1L]]))
  endpoint <- trimws(as.character(endpoint[[1L]]))
  api_key <- trimws(as.character(api_key[[1L]]))

  list(
    gateway_api_key = api_key,
    gateway_model = if (nzchar(model)) model else row$default_model[[1L]],
    gateway_base_url = if (nzchar(base_url)) base_url else row$base_url[[1L]],
    gateway_endpoint = if (nzchar(endpoint)) endpoint else row$endpoint[[1L]]
  )
}

safe_gateway_values <- function(values) {
  list(
    gateway_api_key = if (nzchar(provider_config_string(values, "gateway_api_key"))) "[REDACTED]" else "",
    has_api_key = nzchar(provider_config_string(values, "gateway_api_key")),
    gateway_model = provider_config_string(values, "gateway_model"),
    gateway_base_url = provider_config_string(values, "gateway_base_url"),
    gateway_endpoint = provider_config_string(values, "gateway_endpoint")
  )
}

provider_report_command_hint <- function(values) {
  paste0(
    "run_workbench_command(\"provider-report\", list(",
    "provider = \"compatible_chat\", ",
    "model = \"", provider_config_string(values, "gateway_model"), "\", ",
    "base_url = \"", provider_config_string(values, "gateway_base_url"), "\", ",
    "endpoint = \"", provider_config_string(values, "gateway_endpoint"), "\", ",
    "include_environment = TRUE, include_extension = TRUE))"
  )
}

provider_checklist_steps <- function(row, values) {
  service <- row$label[[1L]]
  data.frame(
    order = seq_len(6L),
    code = c(
      "VERIFY_SERVICE",
      "VERIFY_MODEL",
      "APPLY_PRESET",
      "PROBE_MODELS",
      "RUN_PROVIDER_REPORT",
      "RUN_SAFE_AI_TASK"
    ),
    title = c(
      "Confirm gateway service",
      "Confirm model name",
      "Apply current-session config",
      "Probe model list",
      "Generate integration report",
      "Run a safe AI task"
    ),
    action = c(
      paste0("Start or verify ", service, " and confirm the OpenAI-compatible /v1 endpoint is reachable."),
      paste0("Confirm the gateway exposes model: ", provider_config_string(values, "gateway_model"), "."),
      "Apply the preset values inside the Addin config page or pass them to provider-report.",
      "Use provider-probe to call base_url + /models without running an AI task.",
      "Use provider-report to combine config status, probe result, repair suggestions, and local diagnostics.",
      "After the report is OK, run ai-task with require_user_confirmation = TRUE and allow_code_execution = FALSE."
    ),
    expected = c(
      paste0("Base URL is ", provider_config_string(values, "gateway_base_url"), "."),
      "The model appears in /models or is accepted by the gateway.",
      "No environment variables or project files are written by the preset.",
      "Probe returns ok = TRUE and at least one model, or clear repair suggestions.",
      "Report overall_ok is TRUE before using the provider for real tasks.",
      "The provider returns Chinese content and does not claim to have executed code."
    ),
    automated = c(FALSE, FALSE, FALSE, TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )
}

collect_provider_integration_checklist <- function(preset = "ollama",
                                                   model = "",
                                                   base_url = "",
                                                   endpoint = "",
                                                   api_key = "",
                                                   include_report_command = TRUE) {
  row <- provider_gateway_preset_entry(preset)
  values <- provider_values_from_gateway_preset(
    preset = preset,
    model = model,
    base_url = base_url,
    endpoint = endpoint,
    api_key = api_key
  )

  checklist <- list(
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    preset = row$preset[[1L]],
    label = row$label[[1L]],
    provider = row$provider[[1L]],
    requires_api_key = isTRUE(row$requires_api_key[[1L]]),
    values = safe_gateway_values(values),
    steps = provider_checklist_steps(row, values),
    report_command = if (isTRUE(include_report_command)) provider_report_command_hint(values) else ""
  )
  checklist$markdown <- format_provider_integration_checklist(checklist)
  checklist
}

format_provider_gateway_presets <- function(presets = provider_gateway_presets()) {
  if (!is.data.frame(presets) || !NROW(presets)) {
    return("# Provider gateway presets\n\n- No presets available.")
  }

  lines <- apply(presets, 1L, function(row) {
    paste0(
      "- ", row[["preset"]], " / ", row[["label"]],
      " | base_url=", row[["base_url"]],
      " | endpoint=", row[["endpoint"]],
      " | requires_api_key=", row[["requires_api_key"]],
      " | default_model=", row[["default_model"]]
    )
  })
  paste("# Provider gateway presets", "", paste(lines, collapse = "\n"), sep = "\n")
}

format_provider_integration_checklist <- function(checklist) {
  if (!is.list(checklist)) {
    stop("checklist must be produced by collect_provider_integration_checklist()", call. = FALSE)
  }

  step_lines <- apply(checklist$steps, 1L, function(row) {
    paste0(
      row[["order"]], ". [", row[["code"]], "] ", row[["title"]],
      "\n   - Action: ", row[["action"]],
      "\n   - Expected: ", row[["expected"]]
    )
  })

  parts <- c(
    "# Provider \u7f51\u5173\u8054\u8c03\u6e05\u5355",
    "",
    paste0("\u751f\u6210\u65f6\u95f4\uff1a", checklist$generated_at),
    paste0("Preset: ", checklist$preset, " / ", checklist$label),
    paste0("Provider: ", checklist$provider),
    paste0("Requires API key: ", isTRUE(checklist$requires_api_key)),
    "",
    "## \u5f53\u524d\u4f1a\u8bdd\u914d\u7f6e\u6458\u8981",
    paste0("- Has API key: ", isTRUE(checklist$values$has_api_key)),
    paste0("- Model: ", checklist$values$gateway_model),
    paste0("- Base URL: ", checklist$values$gateway_base_url),
    paste0("- Endpoint: ", checklist$values$gateway_endpoint),
    "",
    "## \u8054\u8c03\u6b65\u9aa4",
    paste(step_lines, collapse = "\n")
  )

  if (nzchar(checklist$report_command)) {
    parts <- c(
      parts,
      "",
      "## provider-report \u547d\u4ee4\u63d0\u793a",
      "```r",
      checklist$report_command,
      "```"
    )
  }

  paste(parts, collapse = "\n")
}

provider_compatibility_provider_rows <- function() {
  catalog <- list_ai_providers()
  data.frame(
    target = c("local", "mock", "openai_responses"),
    target_type = c("offline", "offline", "openai_api"),
    provider = c("local", "mock", "openai_responses"),
    preset = c("", "", ""),
    label = c(
      catalog$label[match("local", catalog$provider)],
      catalog$label[match("mock", catalog$provider)],
      catalog$label[match("openai_responses", catalog$provider)]
    ),
    base_url = c("", "", "https://api.openai.com/v1"),
    endpoint = c("", "", "/responses"),
    requires_api_key = c(FALSE, FALSE, TRUE),
    needs_network = c(FALSE, FALSE, TRUE),
    supports_model_probe = c(FALSE, FALSE, TRUE),
    supports_chat_completions = c(FALSE, FALSE, FALSE),
    supports_responses = c(FALSE, FALSE, TRUE),
    default_model = c("", "", ""),
    recommended_use = c(
      "Offline Chinese diagnostics and fallback behavior.",
      "Deterministic tests and demos.",
      "OpenAI Responses API tasks when an official OpenAI model is configured."
    ),
    next_step = c(
      "Run ai-task with provider = local.",
      "Use mock only for tests or deterministic demos.",
      "Set OPENAI_API_KEY and RSTUDIOZHAI_OPENAI_MODEL, then run provider-status or provider-report."
    ),
    stringsAsFactors = FALSE
  )
}

provider_compatibility_gateway_rows <- function(presets = provider_gateway_presets()) {
  data.frame(
    target = presets$preset,
    target_type = presets$target_type,
    provider = presets$provider,
    preset = presets$preset,
    label = presets$label,
    base_url = presets$base_url,
    endpoint = presets$endpoint,
    requires_api_key = presets$requires_api_key,
    needs_network = TRUE,
    supports_model_probe = TRUE,
    supports_chat_completions = TRUE,
    supports_responses = FALSE,
    default_model = presets$default_model,
    recommended_use = presets$recommended_use,
    next_step = paste0(
      "Run provider-checklist with preset = ",
      presets$preset,
      ", then run provider-report."
    ),
    stringsAsFactors = FALSE
  )
}

provider_compatibility_matrix <- function(presets = provider_gateway_presets()) {
  rows <- rbind(
    provider_compatibility_provider_rows(),
    provider_compatibility_gateway_rows(presets)
  )
  rownames(rows) <- NULL
  rows
}

filter_provider_compatibility_matrix <- function(matrix = provider_compatibility_matrix(),
                                                 target_type = "") {
  if (!is.data.frame(matrix)) {
    stop("matrix must be a provider_compatibility_matrix() data frame", call. = FALSE)
  }
  if (is.null(target_type) || !length(target_type)) {
    return(matrix)
  }
  target_type <- trimws(as.character(target_type[[1L]]))
  if (!nzchar(target_type) || identical(tolower(target_type), "all")) {
    return(matrix)
  }
  matrix[matrix$target_type == target_type, , drop = FALSE]
}

format_provider_compatibility_matrix <- function(matrix = provider_compatibility_matrix()) {
  if (!is.data.frame(matrix) || !NROW(matrix)) {
    return("# Provider compatibility matrix\n\n- No compatible targets found.")
  }

  lines <- apply(matrix, 1L, function(row) {
    paste0(
      "- ", row[["target"]],
      " | type=", row[["target_type"]],
      " | provider=", row[["provider"]],
      " | base_url=", row[["base_url"]],
      " | endpoint=", row[["endpoint"]],
      " | api_key=", row[["requires_api_key"]],
      " | model_probe=", row[["supports_model_probe"]],
      " | chat=", row[["supports_chat_completions"]],
      " | responses=", row[["supports_responses"]],
      " | next=", row[["next_step"]]
    )
  })

  paste(
    "# Provider compatibility matrix",
    "",
    paste(lines, collapse = "\n"),
    "",
    "Use provider-checklist for gateway setup steps, then provider-report for a read-only integration report.",
    sep = "\n"
  )
}
