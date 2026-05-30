default_provider_probe_http_get <- function(url, api_key = "", timeout_seconds = 10L) {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("httr2 is required for provider probing. Install httr2 first.", call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for provider probing. Install jsonlite first.", call. = FALSE)
  }

  req <- httr2::request(url)
  req <- httr2::req_headers(req, `Content-Type` = "application/json")
  if (is.character(api_key) && length(api_key) == 1L && nzchar(api_key)) {
    req <- httr2::req_headers(req, Authorization = paste("Bearer", api_key))
  }
  req <- httr2::req_timeout(req, timeout_seconds)
  response <- httr2::req_perform(req)
  text <- httr2::resp_body_string(response)
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

provider_probe_models_url <- function(provider, config) {
  provider <- assert_known_provider(provider)
  if (provider %in% c("openai_responses", "compatible_chat")) {
    return(paste0(sub("/+$", "", config$base_url), "/models"))
  }
  ""
}

extract_provider_model_ids <- function(response) {
  if (!is.list(response)) {
    return(character())
  }

  rows <- list()
  if (is.list(response$data)) {
    rows <- c(rows, response$data)
  }
  if (is.list(response$models)) {
    rows <- c(rows, response$models)
  }
  if (!length(rows)) {
    return(character())
  }

  ids <- unlist(lapply(rows, function(item) {
    if (!is.list(item)) {
      return(character())
    }
    candidates <- c(item$id, item$name, item$model)
    candidates <- candidates[is.character(candidates) & nzchar(candidates)]
    if (length(candidates)) candidates[[1L]] else character()
  }), use.names = FALSE)
  unique(ids[nzchar(ids)])
}

provider_probe_error <- function(provider, code, message, details = list()) {
  list(
    ok = FALSE,
    provider = provider,
    url = "",
    count = 0L,
    models = data.frame(model = character(), stringsAsFactors = FALSE),
    warnings = character(),
    error = list(code = code, message = message, details = details)
  )
}

empty_provider_probe_suggestions <- function() {
  data.frame(
    code = character(),
    message = character(),
    action = character(),
    stringsAsFactors = FALSE
  )
}

provider_probe_suggestion <- function(code, message, action) {
  data.frame(
    code = code,
    message = message,
    action = action,
    stringsAsFactors = FALSE
  )
}

suggest_provider_probe_actions <- function(probe) {
  if (!is.list(probe)) {
    return(empty_provider_probe_suggestions())
  }

  error_code <- if (is.list(probe$error) && !is.null(probe$error$code)) probe$error$code else ""
  error_message <- if (is.list(probe$error) && !is.null(probe$error$message)) probe$error$message else ""
  error_details <- if (is.list(probe$error) && !is.null(probe$error$details)) {
    paste(unlist(probe$error$details, use.names = FALSE), collapse = " ")
  } else {
    ""
  }
  warnings <- if (length(probe$warnings)) paste(probe$warnings, collapse = " ") else ""
  text <- tolower(paste(error_code, error_message, error_details, warnings, collapse = " "))

  rows <- list()
  add <- function(code, message, action) {
    rows[[length(rows) + 1L]] <<- provider_probe_suggestion(code, message, action)
  }

  if (!isTRUE(probe$ok)) {
    if (identical(error_code, "INVALID_CONFIG")) {
      if (grepl("model", text, fixed = TRUE)) {
        add(
          "SET_MODEL",
          "\u6a21\u578b\u540d\u672a\u914d\u7f6e\u3002",
          "\u5728 Addin \u914d\u7f6e\u9875\u586b\u5199\u6a21\u578b\u540d\uff0c\u6216\u5148\u7528\u63a2\u6d4b\u6a21\u578b\u5217\u8868\u9009\u4e00\u4e2a\u53ef\u7528\u6a21\u578b\u3002"
        )
      }
      if (grepl("base_url", text, fixed = TRUE) || grepl("base url", text, fixed = TRUE)) {
        add(
          "CHECK_BASE_URL",
          "\u7f51\u5173 base URL \u672a\u914d\u7f6e\u6216\u683c\u5f0f\u4e0d\u6b63\u786e\u3002",
          "\u672c\u5730\u7f51\u5173\u5e38\u89c1\u503c\u662f http://127.0.0.1:11434/v1\uff1b\u4f01\u4e1a\u7f51\u5173\u8bf7\u586b\u5185\u7f51 HTTPS base URL\u3002"
        )
      }
      if (grepl("api key", text, fixed = TRUE) || grepl("api_key", text, fixed = TRUE)) {
        add(
          "CHECK_API_KEY",
          "API key \u7f3a\u5931\u6216\u672a\u586b\u5199\u3002",
          "\u5982\u679c\u4f7f\u7528 OpenAI \u6216\u4f01\u4e1a\u7f51\u5173\uff0c\u5728\u914d\u7f6e\u9875\u586b\u5199 API key\uff1b\u672c\u5730 compatible chat \u7f51\u5173\u901a\u5e38\u53ef\u7559\u7a7a\u3002"
        )
      }
    }

    if (identical(error_code, "PROBE_FAILED")) {
      if (grepl("connection refused", text, fixed = TRUE) ||
          grepl("failed to connect", text, fixed = TRUE) ||
          grepl("could not connect", text, fixed = TRUE) ||
          grepl("cannot connect", text, fixed = TRUE)) {
        add(
          "START_GATEWAY",
          "\u672c\u5730\u6216\u4f01\u4e1a\u7f51\u5173\u6ca1\u6709\u54cd\u5e94\u3002",
          "\u5148\u542f\u52a8 Ollama/vLLM/LiteLLM \u6216\u8054\u7cfb\u7ba1\u7406\u5458\u786e\u8ba4\u4f01\u4e1a\u7f51\u5173\u5728\u8fd0\u884c\u3002"
        )
        add(
          "CHECK_BASE_URL",
          "\u53ef\u80fd\u586b\u9519\u4e86 base URL \u6216\u7aef\u53e3\u3002",
          "\u68c0\u67e5 base URL \u662f\u5426\u5305\u542b /v1\uff0c\u5e76\u786e\u8ba4\u7aef\u53e3\u4e0e\u7f51\u5173\u5b9e\u9645\u76d1\u542c\u7aef\u53e3\u4e00\u81f4\u3002"
        )
      }
      if (grepl("timeout", text, fixed = TRUE) || grepl("timed out", text, fixed = TRUE)) {
        add(
          "CHECK_TIMEOUT",
          "\u7f51\u5173\u54cd\u5e94\u8d85\u65f6\u3002",
          "\u786e\u8ba4\u7f51\u7edc\u53ef\u8fbe\uff0c\u5fc5\u8981\u65f6\u589e\u52a0 timeout_seconds \u6216\u68c0\u67e5\u4f01\u4e1a\u4ee3\u7406\u3002"
        )
      }
      if (grepl("401", text, fixed = TRUE) ||
          grepl("403", text, fixed = TRUE) ||
          grepl("unauthorized", text, fixed = TRUE) ||
          grepl("forbidden", text, fixed = TRUE)) {
        add(
          "CHECK_API_KEY",
          "\u7f51\u5173\u62d2\u7edd\u6388\u6743\u3002",
          "\u68c0\u67e5 API key \u662f\u5426\u6b63\u786e\u3001\u662f\u5426\u8fc7\u671f\uff0c\u4ee5\u53ca\u4f01\u4e1a\u7f51\u5173\u662f\u5426\u8981\u6c42 Bearer token\u3002"
        )
      }
      if (grepl("404", text, fixed = TRUE) || grepl("not found", text, fixed = TRUE)) {
        add(
          "CHECK_MODELS_ENDPOINT",
          "\u6a21\u578b\u5217\u8868\u7aef\u70b9\u4e0d\u5b58\u5728\u3002",
          "\u786e\u8ba4 base URL \u6307\u5411 OpenAI-compatible v1 \u6839\u8def\u5f84\uff1b\u63a2\u6d4b\u4f1a\u8bf7\u6c42 base_url + /models\u3002"
        )
      }
    }

    if (!length(rows)) {
      add(
        "CHECK_PROVIDER_LOGS",
        "\u672a\u80fd\u8bc6\u522b\u5177\u4f53\u5931\u8d25\u539f\u56e0\u3002",
        "\u67e5\u770b\u672c\u5730\u6a21\u578b\u670d\u52a1\u6216\u4f01\u4e1a\u7f51\u5173\u65e5\u5fd7\uff0c\u540c\u65f6\u6838\u5bf9 base URL\u3001\u6a21\u578b\u540d\u548c\u5bc6\u94a5\u3002"
      )
    }
  }

  if (isTRUE(probe$ok) && (!is.null(probe$count) && probe$count == 0L)) {
    add(
      "CHECK_MODEL_LIST",
      "\u7f51\u5173\u53ef\u8fde\u901a\uff0c\u4f46\u6ca1\u6709\u89e3\u6790\u5230\u6a21\u578b\u540d\u3002",
      "\u786e\u8ba4\u7f51\u5173\u7684 /models \u54cd\u5e94\u5305\u542b data[].id \u6216 models[].name/model\uff1b\u5982\u662f Ollama\uff0c\u5148\u786e\u8ba4\u5df2\u62c9\u53d6\u6a21\u578b\u3002"
    )
  }

  if (!length(rows)) {
    return(empty_provider_probe_suggestions())
  }

  suggestions <- do.call(rbind, rows)
  suggestions[!duplicated(suggestions$code), , drop = FALSE]
}

format_provider_probe_suggestions <- function(probe) {
  suggestions <- suggest_provider_probe_actions(probe)
  if (!NROW(suggestions)) {
    return(character())
  }
  lines <- apply(suggestions, 1L, function(row) {
    paste0("- ", row[["code"]], ": ", row[["message"]], " ", row[["action"]])
  })
  c("", "## \u4fee\u590d\u5efa\u8bae", lines)
}

provider_probe_config <- function(provider, config = NULL) {
  provider <- assert_known_provider(provider)
  if (!is.null(config)) {
    return(config)
  }
  if (identical(provider, "openai_responses")) {
    return(get_openai_config())
  }
  if (identical(provider, "compatible_chat")) {
    return(get_compatible_chat_config())
  }
  list()
}

validate_provider_probe_config <- function(provider, config) {
  if (identical(provider, "openai_responses")) {
    return(validate_openai_config(config))
  }
  if (identical(provider, "compatible_chat")) {
    return(validate_compatible_chat_config(config))
  }
  TRUE
}

probe_provider_models <- function(provider = "compatible_chat",
                                  config = NULL,
                                  http_get = default_provider_probe_http_get,
                                  timeout_seconds = 10L) {
  provider <- tryCatch(
    assert_known_provider(provider),
    error = function(e) {
      return(structure(list(message = conditionMessage(e)), class = "rstudiozhai_probe_error"))
    }
  )
  if (inherits(provider, "rstudiozhai_probe_error")) {
    return(provider_probe_error("", "UNKNOWN_PROVIDER", provider$message))
  }

  if (!provider %in% c("openai_responses", "compatible_chat")) {
    return(list(
      ok = TRUE,
      provider = provider,
      url = "",
      count = 0L,
      models = data.frame(model = character(), stringsAsFactors = FALSE),
      warnings = paste0("Provider does not expose a remote model list: ", provider),
      error = NULL
    ))
  }

  config <- provider_probe_config(provider, config = config)
  valid <- tryCatch(
    {
      validate_provider_probe_config(provider, config)
      TRUE
    },
    error = function(e) {
      e
    }
  )
  if (inherits(valid, "error")) {
    return(provider_probe_error(
      provider,
      "INVALID_CONFIG",
      conditionMessage(valid),
      list(provider = provider)
    ))
  }
  if (!is.function(http_get)) {
    return(provider_probe_error(provider, "VALIDATION_ERROR", "http_get must be a function"))
  }

  url <- provider_probe_models_url(provider, config)
  raw <- tryCatch(
    http_get(url = url, api_key = config$api_key, timeout_seconds = timeout_seconds),
    error = function(e) {
      e
    }
  )
  if (inherits(raw, "error")) {
    return(provider_probe_error(
      provider,
      "PROBE_FAILED",
      conditionMessage(raw),
      list(url = url)
    ))
  }

  ids <- extract_provider_model_ids(raw)
  list(
    ok = TRUE,
    provider = provider,
    url = url,
    count = length(ids),
    models = data.frame(model = ids, stringsAsFactors = FALSE),
    warnings = if (length(ids)) character() else "No model IDs were found in the provider response.",
    error = NULL
  )
}

format_provider_probe <- function(probe) {
  if (!is.list(probe)) {
    return("# Provider probe\n\n- Probe result unavailable.")
  }
  if (!isTRUE(probe$ok)) {
    return(paste(
      c(
        "# Provider probe",
        "",
        paste0("- Provider: ", probe$provider),
        paste0("- Status: FAILED"),
        paste0("- Code: ", probe$error$code),
        paste0("- Message: ", probe$error$message),
        format_provider_probe_suggestions(probe)
      ),
      collapse = "\n"
    ))
  }

  model_lines <- if (NROW(probe$models)) {
    paste0("- ", probe$models$model)
  } else {
    "- No models returned."
  }
  paste(
    c(
      "# Provider probe",
      "",
      paste0("- Provider: ", probe$provider),
      paste0("- Status: OK"),
      paste0("- URL: ", probe$url),
      paste0("- Model count: ", probe$count),
      "",
      "## Models",
      model_lines,
      if (length(probe$warnings)) c("", "## Warnings", paste0("- ", probe$warnings)) else character(),
      format_provider_probe_suggestions(probe)
    ),
    collapse = "\n"
  )
}

provider_model_choices <- function(probe) {
  if (!is.list(probe) || !isTRUE(probe$ok) || is.null(probe$models) || !NROW(probe$models)) {
    return(character())
  }
  models <- as.character(probe$models$model)
  models <- unique(models[nzchar(models)])
  stats::setNames(models, models)
}

apply_provider_model_choice <- function(provider, values, selected_model) {
  if (is.null(values) || !is.list(values)) {
    values <- list()
  }
  if (!is.character(selected_model) || length(selected_model) != 1L || !nzchar(trimws(selected_model))) {
    return(values)
  }
  selected_model <- trimws(selected_model)

  provider <- tryCatch(assert_known_provider(provider), error = function(e) "")
  if (identical(provider, "openai_responses")) {
    values$openai_model <- selected_model
  } else if (identical(provider, "compatible_chat")) {
    values$gateway_model <- selected_model
  }
  values
}
