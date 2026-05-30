provider_config_fields <- function() {
  data.frame(
    provider = c(
      "openai_responses",
      "openai_responses",
      "openai_responses",
      "compatible_chat",
      "compatible_chat",
      "compatible_chat",
      "compatible_chat"
    ),
    field = c(
      "api_key",
      "model",
      "base_url",
      "api_key",
      "model",
      "base_url",
      "endpoint"
    ),
    input_id = c(
      "openai_api_key",
      "openai_model",
      "openai_base_url",
      "gateway_api_key",
      "gateway_model",
      "gateway_base_url",
      "gateway_endpoint"
    ),
    env_var = c(
      "OPENAI_API_KEY",
      "RSTUDIOZHAI_OPENAI_MODEL",
      "RSTUDIOZHAI_OPENAI_BASE_URL",
      "RSTUDIOZHAI_GATEWAY_API_KEY",
      "RSTUDIOZHAI_GATEWAY_MODEL",
      "RSTUDIOZHAI_GATEWAY_BASE_URL",
      "RSTUDIOZHAI_GATEWAY_ENDPOINT"
    ),
    secret = c(TRUE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE),
    required = c(TRUE, TRUE, TRUE, FALSE, TRUE, TRUE, TRUE),
    stringsAsFactors = FALSE
  )
}

provider_config_value <- function(values, name, default = "") {
  if (is.null(values) || !is.list(values) || is.null(values[[name]])) {
    return(default)
  }
  value <- values[[name]]
  if (is.null(value) || length(value) < 1L) {
    return(default)
  }
  value <- as.character(value[[1L]])
  if (is.na(value)) {
    return(default)
  }
  trimws(value)
}

build_provider_config <- function(provider, values = list()) {
  provider <- assert_known_provider(provider)

  if (identical(provider, "openai_responses")) {
    return(get_openai_config(
      api_key = provider_config_value(values, "openai_api_key", Sys.getenv("OPENAI_API_KEY", unset = "")),
      model = provider_config_value(values, "openai_model", Sys.getenv("RSTUDIOZHAI_OPENAI_MODEL", unset = "")),
      base_url = provider_config_value(
        values,
        "openai_base_url",
        Sys.getenv("RSTUDIOZHAI_OPENAI_BASE_URL", unset = "https://api.openai.com/v1")
      )
    ))
  }

  if (identical(provider, "compatible_chat")) {
    return(get_compatible_chat_config(
      api_key = provider_config_value(values, "gateway_api_key", Sys.getenv("RSTUDIOZHAI_GATEWAY_API_KEY", unset = "")),
      model = provider_config_value(values, "gateway_model", Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = "")),
      base_url = provider_config_value(
        values,
        "gateway_base_url",
        Sys.getenv("RSTUDIOZHAI_GATEWAY_BASE_URL", unset = "http://127.0.0.1:11434/v1")
      ),
      endpoint = provider_config_value(
        values,
        "gateway_endpoint",
        Sys.getenv("RSTUDIOZHAI_GATEWAY_ENDPOINT", unset = "/chat/completions")
      )
    ))
  }

  list()
}

provider_config_status_from_values <- function(provider, values = list()) {
  provider <- assert_known_provider(provider)
  if (provider %in% c("openai_responses", "compatible_chat")) {
    return(provider_config_status(provider, config = build_provider_config(provider, values)))
  }
  provider_config_status(provider)
}

provider_from_config <- function(provider, config = list(), http_post = NULL) {
  provider <- assert_known_provider(provider)

  if (identical(provider, "openai_responses")) {
    validate_openai_config(config)
    return(function(request) {
      if (is.function(http_post)) {
        openai_responses_provider(
          request,
          api_key = config$api_key,
          model = config$model,
          base_url = config$base_url,
          http_post = http_post
        )
      } else {
        openai_responses_provider(
          request,
          api_key = config$api_key,
          model = config$model,
          base_url = config$base_url
        )
      }
    })
  }

  if (identical(provider, "compatible_chat")) {
    validate_compatible_chat_config(config)
    return(function(request) {
      if (is.function(http_post)) {
        compatible_chat_provider(
          request,
          api_key = config$api_key,
          model = config$model,
          base_url = config$base_url,
          endpoint = config$endpoint,
          http_post = http_post
        )
      } else {
        compatible_chat_provider(
          request,
          api_key = config$api_key,
          model = config$model,
          base_url = config$base_url,
          endpoint = config$endpoint
        )
      }
    })
  }

  resolve_ai_provider(provider)
}
