list_ai_providers <- function() {
  data.frame(
    provider = c("local", "mock", "openai_responses", "compatible_chat"),
    label = c(
      "\u672c\u5730\u4e2d\u6587\u89c4\u5219",
      "Mock \u6d4b\u8bd5 Provider",
      "OpenAI Responses API",
      "OpenAI-compatible Chat Gateway"
    ),
    needs_network = c(FALSE, FALSE, TRUE, TRUE),
    needs_config = c(FALSE, FALSE, TRUE, TRUE),
    description = c(
      "\u79bb\u7ebf\u4e2d\u6587\u89e3\u91ca\u548c\u8bca\u65ad\uff0c\u4e0d\u4e0a\u4f20\u4ee3\u7801\uff0c\u9002\u5408\u515c\u5e95\u548c\u65b0\u624b\u5f15\u5bfc\u3002",
      "\u7a33\u5b9a\u6d4b\u8bd5\u66ff\u8eab\uff0c\u7528\u4e8e TDD \u548c\u79bb\u7ebf\u9a8c\u8bc1\u3002",
      "\u8c03\u7528 OpenAI Responses API\uff0c\u9700\u8981 OPENAI_API_KEY \u548c RSTUDIOZHAI_OPENAI_MODEL\u3002",
      "\u8c03\u7528\u672c\u5730\u6216\u4f01\u4e1a OpenAI-compatible Chat Completions \u7f51\u5173\uff0cAPI key \u53ef\u9009\uff0c\u6a21\u578b\u4e0d\u786c\u7f16\u7801\u3002"
    ),
    stringsAsFactors = FALSE
  )
}

provider_choice_labels <- function() {
  catalog <- list_ai_providers()
  stats::setNames(catalog$provider, paste0(catalog$label, " [", catalog$provider, "]"))
}

assert_known_provider <- function(provider) {
  providers <- list_ai_providers()$provider
  if (!is.character(provider) || length(provider) != 1L || !nzchar(trimws(provider))) {
    stop("provider must be a non-empty string", call. = FALSE)
  }
  provider <- trimws(provider)
  if (!provider %in% providers) {
    stop(
      "Unknown provider: ",
      provider,
      ". Supported providers: ",
      paste(providers, collapse = ", "),
      call. = FALSE
    )
  }
  provider
}

provider_config_status <- function(provider = "local", config = NULL) {
  provider <- assert_known_provider(provider)
  catalog <- list_ai_providers()
  meta <- catalog[match(provider, catalog$provider), , drop = FALSE]

  if (identical(provider, "local") || identical(provider, "mock")) {
    return(list(
      ok = TRUE,
      provider = provider,
      label = meta$label,
      needs_network = isTRUE(meta$needs_network),
      needs_config = isTRUE(meta$needs_config),
      missing = character(),
      has_api_key = FALSE,
      model = "",
      base_url = "",
      message = "\u5df2\u5c31\u7eea\uff1a\u8be5 Provider \u4e0d\u9700\u8981\u7f51\u7edc\u6216\u5bc6\u94a5\u914d\u7f6e\u3002"
    ))
  }

  if (identical(provider, "openai_responses")) {
    if (is.null(config)) {
      config <- get_openai_config()
    }
    if (!is.list(config)) {
      stop("config must be a list", call. = FALSE)
    }

    has_api_key <- is.character(config$api_key) && length(config$api_key) == 1L && nzchar(config$api_key)
    has_model <- is.character(config$model) && length(config$model) == 1L && nzchar(config$model)
    has_base_url <- is.character(config$base_url) && length(config$base_url) == 1L && nzchar(config$base_url)
    missing <- c(
      if (!has_api_key) "OPENAI_API_KEY" else character(),
      if (!has_model) "RSTUDIOZHAI_OPENAI_MODEL" else character(),
      if (!has_base_url) "RSTUDIOZHAI_OPENAI_BASE_URL" else character()
    )

    return(list(
      ok = length(missing) == 0L,
      provider = provider,
      label = meta$label,
      needs_network = TRUE,
      needs_config = TRUE,
      missing = missing,
      has_api_key = has_api_key,
      model = if (has_model) config$model else "",
      base_url = if (has_base_url) config$base_url else "",
      message = if (length(missing)) {
        paste0("\u5c1a\u672a\u5c31\u7eea\uff1a\u7f3a\u5c11 ", paste(missing, collapse = ", "), "\u3002")
      } else {
        "\u5df2\u5c31\u7eea\uff1aOpenAI Provider \u914d\u7f6e\u5b8c\u6574\u3002"
      }
    ))
  }

  if (identical(provider, "compatible_chat")) {
    if (is.null(config)) {
      config <- get_compatible_chat_config()
    }
    if (!is.list(config)) {
      stop("config must be a list", call. = FALSE)
    }

    has_api_key <- is.character(config$api_key) && length(config$api_key) == 1L && nzchar(config$api_key)
    has_model <- is.character(config$model) && length(config$model) == 1L && nzchar(config$model)
    has_base_url <- is.character(config$base_url) && length(config$base_url) == 1L && nzchar(config$base_url)
    has_endpoint <- is.character(config$endpoint) && length(config$endpoint) == 1L && nzchar(config$endpoint)
    missing <- c(
      if (!has_model) "RSTUDIOZHAI_GATEWAY_MODEL" else character(),
      if (!has_base_url) "RSTUDIOZHAI_GATEWAY_BASE_URL" else character(),
      if (!has_endpoint) "RSTUDIOZHAI_GATEWAY_ENDPOINT" else character()
    )

    return(list(
      ok = length(missing) == 0L,
      provider = provider,
      label = meta$label,
      needs_network = TRUE,
      needs_config = TRUE,
      missing = missing,
      has_api_key = has_api_key,
      model = if (has_model) config$model else "",
      base_url = if (has_base_url) config$base_url else "",
      endpoint = if (has_endpoint) config$endpoint else "",
      message = if (length(missing)) {
        paste0("\u5c1a\u672a\u5c31\u7eea\uff1a\u7f3a\u5c11 ", paste(missing, collapse = ", "), "\u3002API key \u5bf9\u672c\u5730\u7f51\u5173\u53ef\u4e3a\u7a7a\u3002")
      } else {
        "\u5df2\u5c31\u7eea\uff1aCompatible Chat Gateway \u914d\u7f6e\u5b8c\u6574\u3002"
      }
    ))
  }

  stop("Unhandled provider: ", provider, call. = FALSE)
}

format_provider_status <- function(status) {
  if (!is.list(status)) {
    stop("status must be a provider_config_status() result", call. = FALSE)
  }

  paste(
    paste0("Provider: ", status$provider, " / ", status$label),
    paste0("Status: ", if (isTRUE(status$ok)) "OK" else "MISSING_CONFIG"),
    paste0("Needs network: ", isTRUE(status$needs_network)),
    paste0("Needs config: ", isTRUE(status$needs_config)),
    paste0("Has API key: ", isTRUE(status$has_api_key)),
    if (nzchar(status$model)) paste0("Model: ", status$model) else "Model: ",
    if (nzchar(status$base_url)) paste0("Base URL: ", status$base_url) else "Base URL: ",
    if (length(status$missing)) paste0("Missing: ", paste(status$missing, collapse = ", ")) else "Missing: none",
    status$message,
    sep = "\n"
  )
}

resolve_ai_provider <- function(provider = "local", provider_fun = NULL) {
  if (is.function(provider_fun)) {
    return(provider_fun)
  }

  provider <- assert_known_provider(provider)
  switch(
    provider,
    local = local_chinese_provider,
    mock = mock_ai_provider,
    openai_responses = openai_responses_provider,
    compatible_chat = compatible_chat_provider,
    stop("Unhandled provider: ", provider, call. = FALSE)
  )
}
