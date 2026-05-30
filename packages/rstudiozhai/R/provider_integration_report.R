provider_registry_entry <- function(provider) {
  catalog <- list_ai_providers()
  row <- catalog[match(provider, catalog$provider), , drop = FALSE]
  if (!NROW(row)) {
    return(list(
      provider = provider,
      label = "",
      needs_network = NA,
      needs_config = NA,
      description = ""
    ))
  }

  list(
    provider = row$provider[[1L]],
    label = row$label[[1L]],
    needs_network = isTRUE(row$needs_network[[1L]]),
    needs_config = isTRUE(row$needs_config[[1L]]),
    description = row$description[[1L]]
  )
}

provider_config_string <- function(config, name) {
  value <- config[[name]]
  if (is.null(value) || length(value) < 1L) {
    return("")
  }
  value <- as.character(value[[1L]])
  if (is.na(value)) {
    return("")
  }
  value
}

provider_config_has_secret <- function(config) {
  value <- config[["api_key"]]
  is.character(value) && length(value) == 1L && nzchar(value)
}

provider_safe_config_summary <- function(provider, config) {
  list(
    provider = provider,
    has_api_key = provider_config_has_secret(config),
    model = provider_config_string(config, "model"),
    base_url = provider_config_string(config, "base_url"),
    endpoint = provider_config_string(config, "endpoint")
  )
}

provider_report_sensitive_name <- function(name) {
  nzchar(name) &&
    sensitive_audit_name(name) &&
    !tolower(name) %in% c("has_api_key")
}

redact_provider_report_names <- function(value, name = "") {
  if (provider_report_sensitive_name(name)) {
    return("[REDACTED]")
  }

  if (is.data.frame(value)) {
    for (column in names(value)) {
      if (provider_report_sensitive_name(column)) {
        value[[column]] <- "[REDACTED]"
      }
    }
    return(value)
  }

  if (is.list(value)) {
    keys <- names(value)
    if (is.null(keys)) {
      keys <- rep("", length(value))
    }
    for (index in seq_along(value)) {
      value[index] <- list(redact_provider_report_names(value[[index]], keys[[index]]))
    }
  }

  value
}

redact_provider_report_secrets <- function(value, secrets) {
  secrets <- unique(as.character(secrets))
  secrets <- secrets[nzchar(secrets)]

  if (!length(secrets)) {
    return(value)
  }

  if (is.character(value)) {
    for (secret in secrets) {
      value <- gsub(secret, "[REDACTED]", value, fixed = TRUE)
    }
    return(value)
  }

  if (is.data.frame(value)) {
    for (column in names(value)) {
      if (is.character(value[[column]])) {
        value[[column]] <- redact_provider_report_secrets(value[[column]], secrets)
      }
    }
    return(value)
  }

  if (is.list(value)) {
    for (index in seq_along(value)) {
      value[index] <- list(redact_provider_report_secrets(value[[index]], secrets))
    }
  }

  value
}

sanitize_provider_report_value <- function(value, secrets = character()) {
  value <- redact_provider_report_names(value)
  redact_provider_report_secrets(value, secrets)
}

provider_report_status <- function(provider, config) {
  tryCatch(
    provider_config_status(provider, config = config),
    error = function(e) {
      list(
        ok = FALSE,
        provider = provider,
        label = provider,
        needs_network = NA,
        needs_config = NA,
        missing = character(),
        has_api_key = FALSE,
        model = "",
        base_url = "",
        endpoint = "",
        message = conditionMessage(e)
      )
    }
  )
}

provider_report_probe <- function(provider, config, probe_fun, timeout_seconds) {
  if (!is.function(probe_fun)) {
    return(provider_probe_error(
      provider,
      "VALIDATION_ERROR",
      "probe_fun must be a function"
    ))
  }

  tryCatch(
    probe_fun(
      provider = provider,
      config = config,
      timeout_seconds = timeout_seconds
    ),
    error = function(e) {
      provider_probe_error(
        provider,
        "PROBE_FAILED",
        conditionMessage(e),
        details = list(provider = provider)
      )
    }
  )
}

collect_provider_integration_report <- function(provider = "compatible_chat",
                                                values = list(),
                                                config = NULL,
                                                include_environment = TRUE,
                                                include_extension = TRUE,
                                                packages = "stats",
                                                probe_fun = probe_provider_models,
                                                timeout_seconds = 10L) {
  provider <- assert_known_provider(provider)
  if (is.null(values)) {
    values <- list()
  }
  if (!is.list(values)) {
    stop("values must be a list", call. = FALSE)
  }

  config <- if (is.null(config)) {
    build_provider_config(provider, values)
  } else {
    config
  }
  if (!is.list(config)) {
    stop("config must be a list", call. = FALSE)
  }

  secrets <- c(
    provider_config_string(config, "api_key"),
    provider_config_string(values, "api_key"),
    provider_config_string(values, "openai_api_key"),
    provider_config_string(values, "gateway_api_key")
  )

  status <- sanitize_provider_report_value(provider_report_status(provider, config), secrets = secrets)
  probe <- provider_report_probe(provider, config, probe_fun, as.integer(timeout_seconds))
  probe <- sanitize_provider_report_value(probe, secrets = secrets)
  suggestions <- suggest_provider_probe_actions(probe)

  report <- list(
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    provider = provider,
    overall_ok = isTRUE(status$ok) && isTRUE(probe$ok),
    registry = provider_registry_entry(provider),
    status = status,
    config = provider_safe_config_summary(provider, config),
    probe = list(
      result = probe,
      suggestions = suggestions
    ),
    environment = if (isTRUE(include_environment)) {
      collect_environment_report(packages = packages)
    } else {
      NULL
    },
    extension = if (isTRUE(include_extension)) {
      collect_rstudio_extension_status()
    } else {
      NULL
    }
  )
  report <- sanitize_provider_report_value(report, secrets = secrets)
  report$markdown <- format_provider_integration_report(report)
  report
}

format_provider_report_config <- function(config) {
  c(
    paste0("- Provider: ", config$provider),
    paste0("- Has API key: ", isTRUE(config$has_api_key)),
    paste0("- Model: ", config$model),
    paste0("- Base URL: ", config$base_url),
    paste0("- Endpoint: ", config$endpoint)
  )
}

format_provider_report_suggestions <- function(suggestions) {
  if (is.null(suggestions) || !NROW(suggestions)) {
    return("- \u6682\u65e0\u5efa\u8bae\u3002")
  }

  apply(suggestions, 1L, function(row) {
    paste0("- [", row[["code"]], "] ", row[["message"]], " ", row[["action"]])
  })
}

format_provider_integration_report <- function(report) {
  if (!is.list(report)) {
    stop("report must be produced by collect_provider_integration_report()", call. = FALSE)
  }

  missing <- if (length(report$status$missing)) {
    paste(report$status$missing, collapse = ", ")
  } else {
    "none"
  }

  parts <- c(
    "# AI Provider \u8054\u8c03\u62a5\u544a",
    "",
    paste0("\u751f\u6210\u65f6\u95f4\uff1a", report$generated_at),
    paste0("\u603b\u4f53\u72b6\u6001\uff1a", if (isTRUE(report$overall_ok)) "OK" else "FAILED"),
    "",
    "## Provider",
    paste0("- Provider: ", report$provider),
    paste0("- Label: ", report$registry$label),
    paste0("- Needs network: ", isTRUE(report$registry$needs_network)),
    paste0("- Needs config: ", isTRUE(report$registry$needs_config)),
    paste0("- Description: ", report$registry$description),
    "",
    "## \u5b89\u5168\u914d\u7f6e\u6458\u8981",
    format_provider_report_config(report$config),
    paste0("- Missing: ", missing),
    paste0("- Message: ", report$status$message),
    "",
    "## \u6a21\u578b\u63a2\u6d4b",
    format_provider_probe(report$probe$result),
    "",
    "## \u8054\u8c03\u4fee\u590d\u5efa\u8bae",
    format_provider_report_suggestions(report$probe$suggestions)
  )

  if (is.list(report$environment)) {
    parts <- c(
      parts,
      "",
      "## \u73af\u5883\u4f53\u68c0\u4e0a\u4e0b\u6587",
      format_environment_report(report$environment)
    )
  }

  if (is.list(report$extension)) {
    parts <- c(
      parts,
      "",
      "## RStudio \u6269\u5c55\u9a8c\u6536\u4e0a\u4e0b\u6587",
      format_rstudio_extension_status(report$extension)
    )
  }

  paste(parts, collapse = "\n")
}
