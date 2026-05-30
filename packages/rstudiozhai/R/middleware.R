available_workbench_commands <- function() {
  data.frame(
    command = c(
      "list-commands",
      "diagnostics",
      "provider-status",
      "provider-probe",
      "provider-report",
      "provider-presets",
      "provider-checklist",
      "provider-compatibility",
      "rstudio-extension-status",
      "project-scan",
      "audit-log",
      "knowledge",
      "ai-task",
      "quarto-draft",
      "connection-template"
    ),
    description = c(
      "List stable workbench middleware commands.",
      "Collect R, RStudio, Quarto, and package diagnostics.",
      "Report AI provider readiness without making network calls.",
      "Read-only probe for AI provider gateway model listing.",
      "Collect a read-only AI provider integration report for local or enterprise gateways.",
      "List OpenAI-compatible provider gateway presets.",
      "Create a read-only manual integration checklist from a gateway preset.",
      "List provider and gateway compatibility targets.",
      "Validate installed RStudio Addin, templates, connections, and snippets.",
      "Summarize a local R/RStudio project without entering heavy directories.",
      "Read recent workbench audit events from a JSONL file.",
      "Search the bundled Chinese RStudio knowledge base.",
      "Run an AI task through a named provider contract.",
      "Create a Quarto report draft; requires allow_write = TRUE.",
      "List or render safe DBI connection templates."
    ),
    mutates_files = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, FALSE),
    long_running = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, FALSE),
    stringsAsFactors = FALSE
  )
}

workbench_package_version <- function() {
  version <- tryCatch(
    as.character(utils::packageVersion("rstudiozhai")),
    error = function(e) "0.0.0.9000"
  )
  version
}

workbench_error <- function(code, message, details = list()) {
  list(
    code = code,
    message = message,
    details = details
  )
}

workbench_error_result <- function(command,
                                   code,
                                   message,
                                   details = list(),
                                   warnings = character()) {
  workbench_result(
    command = command,
    ok = FALSE,
    data = list(),
    warnings = warnings,
    error = workbench_error(code, message, details)
  )
}

workbench_result <- function(command,
                             ok = TRUE,
                             data = list(),
                             warnings = character(),
                             error = NULL) {
  if (is.null(warnings)) {
    warnings <- character()
  }

  list(
    ok = isTRUE(ok),
    command = command,
    data = data,
    warnings = as.character(warnings),
    error = error,
    metadata = list(
      created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
      package_version = workbench_package_version()
    )
  )
}

stop_workbench_error <- function(code, message, details = list()) {
  stop(errorCondition(
    message = message,
    class = "rstudiozhai_workbench_error",
    code = code,
    details = details
  ))
}

normalize_workbench_params <- function(params) {
  if (is.null(params)) {
    return(list())
  }
  if (!is.list(params)) {
    stop_workbench_error(
      "VALIDATION_ERROR",
      "params must be a list or JSON object",
      list(param_type = class(params))
    )
  }
  params
}

unwrap_scalar <- function(value) {
  if (is.list(value) && length(value) == 1L && is.null(names(value))) {
    return(value[[1L]])
  }
  value
}

param_string <- function(params, name, default = NULL, required = FALSE) {
  value <- params[[name]]
  if (is.null(value)) {
    if (isTRUE(required)) {
      stop_workbench_error(
        "VALIDATION_ERROR",
        paste0("Missing required parameter: ", name),
        list(parameter = name)
      )
    }
    return(default)
  }

  value <- unwrap_scalar(value)
  if (!is.character(value) || length(value) != 1L) {
    stop_workbench_error(
      "VALIDATION_ERROR",
      paste0("Parameter must be a string: ", name),
      list(parameter = name)
    )
  }

  value <- trimws(value)
  if (isTRUE(required) && !nzchar(value)) {
    stop_workbench_error(
      "VALIDATION_ERROR",
      paste0("Parameter must be non-empty: ", name),
      list(parameter = name)
    )
  }
  value
}

param_character_vector <- function(params, name, default = character()) {
  value <- params[[name]]
  if (is.null(value)) {
    return(default)
  }
  value <- unlist(value, use.names = FALSE)
  if (!is.character(value)) {
    stop_workbench_error(
      "VALIDATION_ERROR",
      paste0("Parameter must be a character vector: ", name),
      list(parameter = name)
    )
  }
  value
}

param_integer <- function(params, name, default) {
  value <- params[[name]]
  if (is.null(value)) {
    return(as.integer(default))
  }
  value <- unwrap_scalar(value)
  if (is.character(value) && grepl("^[0-9]+$", value)) {
    value <- as.integer(value)
  }
  if (!is.numeric(value) || length(value) != 1L || is.na(value)) {
    stop_workbench_error(
      "VALIDATION_ERROR",
      paste0("Parameter must be an integer: ", name),
      list(parameter = name)
    )
  }
  as.integer(value)
}

param_logical <- function(params, name, default = FALSE) {
  value <- params[[name]]
  if (is.null(value)) {
    return(isTRUE(default))
  }

  value <- unwrap_scalar(value)
  if (is.logical(value) && length(value) == 1L) {
    return(isTRUE(value))
  }
  if (is.character(value) && length(value) == 1L) {
    return(tolower(value) %in% c("true", "1", "yes", "y"))
  }
  if (is.numeric(value) && length(value) == 1L) {
    return(!is.na(value) && value != 0)
  }

  stop_workbench_error(
    "VALIDATION_ERROR",
    paste0("Parameter must be logical: ", name),
    list(parameter = name)
  )
}

param_list <- function(params, name, default = list()) {
  value <- params[[name]]
  if (is.null(value)) {
    return(default)
  }
  if (!is.list(value)) {
    stop_workbench_error(
      "VALIDATION_ERROR",
      paste0("Parameter must be an object/list: ", name),
      list(parameter = name)
    )
  }
  value
}

provider_from_name <- function(provider = "local", provider_fun = NULL) {
  tryCatch(
    resolve_ai_provider(provider, provider_fun = provider_fun),
    error = function(e) {
      stop_workbench_error(
        "UNKNOWN_PROVIDER",
        conditionMessage(e),
        list(provider = provider, supported = list_ai_providers()$provider)
      )
    }
  )
}

run_workbench_command <- function(command = "list-commands",
                                  params = list(),
                                  provider_fun = NULL) {
  command <- if (missing(command) || is.null(command)) "list-commands" else as.character(command[[1L]])
  command <- trimws(tolower(command))
  if (!nzchar(command)) {
    command <- "list-commands"
  }

  params_for_audit <- params
  catalog_for_audit <- available_workbench_commands()
  result <- tryCatch(
    {
      params <- normalize_workbench_params(params)
      catalog <- available_workbench_commands()
      if (!command %in% catalog$command) {
        stop_workbench_error(
          "UNKNOWN_COMMAND",
          paste0("Unknown workbench command: ", command),
          list(command = command, supported = catalog$command)
        )
      }
      policy <- check_workbench_policy(command, params, catalog = catalog)
      if (!isTRUE(policy$ok)) {
        stop_workbench_error(
          policy$code,
          policy$message,
          policy$details
        )
      }

      data <- switch(
        command,
        "list-commands" = list(commands = catalog),
        diagnostics = run_diagnostics_command(params),
        "provider-status" = run_provider_status_command(params),
        "provider-probe" = run_provider_probe_command(params),
        "provider-report" = run_provider_report_command(params),
        "provider-presets" = run_provider_presets_command(params),
        "provider-checklist" = run_provider_checklist_command(params),
        "provider-compatibility" = run_provider_compatibility_command(params),
        "rstudio-extension-status" = run_rstudio_extension_status_command(params),
        "project-scan" = run_project_scan_command(params),
        "audit-log" = run_audit_log_command(params),
        knowledge = run_knowledge_command(params),
        "ai-task" = run_ai_task_command(params, provider_fun = provider_fun),
        "quarto-draft" = run_quarto_draft_command(params, provider_fun = provider_fun),
        "connection-template" = run_connection_template_command(params)
      )

      workbench_result(command = command, ok = TRUE, data = data)
    },
    rstudiozhai_workbench_error = function(e) {
      workbench_error_result(
        command = command,
        code = e$code,
        message = conditionMessage(e),
        details = e$details
      )
    },
    error = function(e) {
      workbench_error_result(
        command = command,
        code = "COMMAND_FAILED",
        message = conditionMessage(e),
        details = list(class = class(e))
      )
    }
  )
  audit_workbench_result(command, params_for_audit, result, catalog = catalog_for_audit)
}

provider_values_from_params <- function(params) {
  list(
    openai_api_key = param_string(params, "openai_api_key", default = param_string(params, "api_key", default = Sys.getenv("OPENAI_API_KEY", unset = ""))),
    openai_model = param_string(params, "openai_model", default = param_string(params, "model", default = Sys.getenv("RSTUDIOZHAI_OPENAI_MODEL", unset = ""))),
    openai_base_url = param_string(params, "openai_base_url", default = param_string(params, "base_url", default = Sys.getenv("RSTUDIOZHAI_OPENAI_BASE_URL", unset = "https://api.openai.com/v1"))),
    gateway_api_key = param_string(params, "gateway_api_key", default = param_string(params, "api_key", default = Sys.getenv("RSTUDIOZHAI_GATEWAY_API_KEY", unset = ""))),
    gateway_model = param_string(params, "gateway_model", default = param_string(params, "model", default = Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = ""))),
    gateway_base_url = param_string(params, "gateway_base_url", default = param_string(params, "base_url", default = Sys.getenv("RSTUDIOZHAI_GATEWAY_BASE_URL", unset = "http://127.0.0.1:11434/v1"))),
    gateway_endpoint = param_string(params, "gateway_endpoint", default = param_string(params, "endpoint", default = Sys.getenv("RSTUDIOZHAI_GATEWAY_ENDPOINT", unset = "/chat/completions")))
  )
}

run_provider_probe_command <- function(params) {
  provider <- param_string(params, "provider", default = "compatible_chat")
  values <- provider_values_from_params(params)

  config <- tryCatch(
    build_provider_config(provider, values),
    error = function(e) list(.config_error = conditionMessage(e))
  )
  probe <- if (!is.null(config$.config_error)) {
    provider_probe_error(provider, "INVALID_CONFIG", config$.config_error)
  } else {
    probe_provider_models(
      provider,
      config = config,
      timeout_seconds = param_integer(params, "timeout_seconds", default = 10L)
    )
  }

  list(
    probe = probe,
    markdown = format_provider_probe(probe)
  )
}

run_provider_report_command <- function(params) {
  provider <- param_string(params, "provider", default = "compatible_chat")
  report <- collect_provider_integration_report(
    provider = provider,
    values = provider_values_from_params(params),
    include_environment = param_logical(params, "include_environment", default = TRUE),
    include_extension = param_logical(params, "include_extension", default = TRUE),
    packages = param_character_vector(params, "packages", default = "stats"),
    timeout_seconds = param_integer(params, "timeout_seconds", default = 10L)
  )

  list(
    report = report,
    markdown = report$markdown
  )
}

run_provider_presets_command <- function(params) {
  preset <- param_string(params, "preset", default = "")
  presets <- provider_gateway_presets()
  if (nzchar(preset)) {
    preset <- assert_provider_gateway_preset(preset)
    presets <- presets[match(preset, presets$preset), , drop = FALSE]
  }

  list(
    presets = presets,
    markdown = format_provider_gateway_presets(presets)
  )
}

run_provider_checklist_command <- function(params) {
  checklist <- collect_provider_integration_checklist(
    preset = param_string(params, "preset", default = "ollama"),
    model = param_string(params, "model", default = ""),
    base_url = param_string(params, "base_url", default = ""),
    endpoint = param_string(params, "endpoint", default = ""),
    api_key = param_string(params, "api_key", default = ""),
    include_report_command = param_logical(params, "include_report_command", default = TRUE)
  )

  list(
    checklist = checklist,
    markdown = checklist$markdown
  )
}

run_provider_compatibility_command <- function(params) {
  matrix <- provider_compatibility_matrix()
  matrix <- filter_provider_compatibility_matrix(
    matrix,
    target_type = param_string(params, "target_type", default = "")
  )

  list(
    matrix = matrix,
    markdown = format_provider_compatibility_matrix(matrix)
  )
}

run_project_scan_command <- function(params) {
  path <- param_string(params, "path", default = getwd())
  max_files <- param_integer(params, "max_files", default = 200L)
  max_bytes <- param_integer(params, "max_bytes", default = 4096L)
  include_text <- param_logical(params, "include_text", default = FALSE)
  include_patterns <- param_character_vector(params, "include_patterns", default = character())
  exclude_dirs <- if (is.null(params$exclude_dirs)) {
    default_project_scan_exclude_dirs()
  } else {
    param_character_vector(params, "exclude_dirs", default = default_project_scan_exclude_dirs())
  }

  if (max_files < 1L) {
    stop_workbench_error(
      "VALIDATION_ERROR",
      "max_files must be a positive integer",
      list(parameter = "max_files")
    )
  }
  if (max_bytes < 0L) {
    stop_workbench_error(
      "VALIDATION_ERROR",
      "max_bytes must be a non-negative integer",
      list(parameter = "max_bytes")
    )
  }

  scan <- collect_project_scan(
    path = path,
    max_files = max_files,
    max_bytes = max_bytes,
    include_patterns = include_patterns,
    exclude_dirs = exclude_dirs,
    include_text = include_text
  )

  list(
    scan = scan,
    markdown = scan$markdown
  )
}

run_audit_log_command <- function(params) {
  path <- param_string(params, "path", required = TRUE)
  limit <- param_integer(params, "limit", default = 20L)
  events <- read_workbench_audit_log(path, limit = limit)
  list(
    path = normalizePath(path, winslash = "/", mustWork = FALSE),
    count = NROW(events),
    events = events,
    markdown = format_workbench_audit_log(events)
  )
}

run_rstudio_extension_status_command <- function(params) {
  status <- collect_rstudio_extension_status()
  list(
    status = status,
    markdown = format_rstudio_extension_status(status)
  )
}

run_provider_status_command <- function(params) {
  provider <- param_string(params, "provider", default = "local")
  status <- tryCatch(
    provider_config_status(provider),
    error = function(e) {
      stop_workbench_error(
        "UNKNOWN_PROVIDER",
        conditionMessage(e),
        list(provider = provider, supported = list_ai_providers()$provider)
      )
    }
  )

  list(
    providers = list_ai_providers(),
    status = status,
    markdown = format_provider_status(status)
  )
}

run_diagnostics_command <- function(params) {
  packages <- param_character_vector(params, "packages", default = default_required_packages())
  report <- collect_environment_report(packages = packages)
  list(
    report = report,
    markdown = format_environment_report(report),
    suggestions = report$suggestions
  )
}

run_knowledge_command <- function(params) {
  query <- param_string(params, "query", required = TRUE)
  error_message <- param_string(params, "error_message", default = "")
  max_results <- param_integer(params, "max_results", default = 5L)

  list(
    query = query,
    terms = lookup_rstudio_term(query, max_results = max_results),
    commands = search_rstudio_commands(query, max_results = max_results),
    errors = explain_r_error(
      if (nzchar(error_message)) error_message else query,
      max_results = max_results
    ),
    summary = summarize_knowledge_for_query(query, error_message = error_message)
  )
}

run_ai_task_command <- function(params, provider_fun = NULL) {
  task <- param_string(params, "task", required = TRUE)
  mode <- param_string(params, "mode", default = "diagnose")
  provider <- param_string(params, "provider", default = "local")
  context <- param_list(params, "context", default = list())

  request <- build_ai_task_request(
    task = task,
    mode = mode,
    provider = provider,
    context = context,
    allow_code_execution = param_logical(params, "allow_code_execution", default = FALSE),
    require_user_confirmation = param_logical(params, "require_user_confirmation", default = TRUE)
  )
  response <- invoke_ai_provider(request, provider_from_name(provider, provider_fun = provider_fun))

  list(
    request = request,
    response = response
  )
}

run_quarto_draft_command <- function(params, provider_fun = NULL) {
  if (!param_logical(params, "allow_write", default = FALSE)) {
    stop_workbench_error(
      "WRITE_NOT_ALLOWED",
      "quarto-draft writes a file and requires allow_write = TRUE",
      list(command = "quarto-draft")
    )
  }

  task <- param_string(params, "task", required = TRUE)
  ai_result <- param_string(params, "ai_result", default = "")
  if (!nzchar(ai_result)) {
    generated <- run_ai_task_command(
      list(task = task, mode = "generate", provider = "local"),
      provider_fun = provider_fun
    )
    ai_result <- generated$response$content
  }

  create_quarto_report(
    task = task,
    ai_result = ai_result,
    output_dir = param_string(params, "output_dir", default = getwd()),
    title = param_string(params, "title", default = "RStudio Chinese AI Workbench Report"),
    include_environment = param_logical(params, "include_environment", default = TRUE),
    overwrite = param_logical(params, "overwrite", default = FALSE)
  )
}

run_connection_template_command <- function(params) {
  kind <- param_string(params, "kind", default = "")
  if (!nzchar(kind)) {
    return(list(templates = list_connection_templates()))
  }

  list(
    kind = kind,
    variable = param_string(params, "variable", default = "con"),
    code = build_dbi_connection_code(
      kind = kind,
      variable = param_string(params, "variable", default = "con"),
      use_password_prompt = param_logical(params, "use_password_prompt", default = TRUE)
    )
  )
}

ensure_jsonlite <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop_workbench_error(
      "MISSING_PACKAGE",
      "jsonlite is required for Workbench CLI JSON input/output",
      list(package = "jsonlite")
    )
  }
  TRUE
}

read_workbench_json_object <- function(text) {
  ensure_jsonlite()
  parsed <- tryCatch(
    jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) {
      stop_workbench_error(
        "INVALID_JSON",
        conditionMessage(e),
        list(input = substr(text, 1L, 200L))
      )
    }
  )
  if (is.null(parsed)) {
    return(list())
  }
  if (!is.list(parsed)) {
    stop_workbench_error(
      "INVALID_JSON",
      "CLI params JSON must decode to an object",
      list(decoded_type = class(parsed))
    )
  }
  parsed
}

parse_workbench_cli_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  args <- as.character(args)
  if (!length(args)) {
    return(list(command = "list-commands", params = list()))
  }

  command <- args[[1L]]
  rest <- args[-1L]
  if (!length(rest)) {
    return(list(command = command, params = list()))
  }

  if (length(rest) == 2L && identical(rest[[1L]], "--params-json")) {
    return(list(command = command, params = read_workbench_json_object(rest[[2L]])))
  }

  if (length(rest) == 2L && identical(rest[[1L]], "--params-file")) {
    path <- rest[[2L]]
    if (!file.exists(path)) {
      stop_workbench_error(
        "PARAMS_FILE_NOT_FOUND",
        paste0("Params file not found: ", path),
        list(path = path)
      )
    }
    text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    return(list(command = command, params = read_workbench_json_object(text)))
  }

  if (length(rest) == 1L && grepl("^\\s*\\{", rest[[1L]])) {
    return(list(command = command, params = read_workbench_json_object(rest[[1L]])))
  }

  stop_workbench_error(
    "INVALID_CLI_ARGS",
    "Use: <command> [--params-json JSON | --params-file PATH]",
    list(args = args)
  )
}

encode_workbench_json <- function(result, pretty = TRUE) {
  ensure_jsonlite()
  jsonlite::toJSON(
    result,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    dataframe = "rows",
    pretty = isTRUE(pretty)
  )
}

workbench_cli_main <- function(args = commandArgs(trailingOnly = TRUE),
                               output = stdout()) {
  result <- tryCatch(
    {
      parsed <- parse_workbench_cli_args(args)
      run_workbench_command(parsed$command, parsed$params)
    },
    rstudiozhai_workbench_error = function(e) {
      workbench_error_result(
        command = "",
        code = e$code,
        message = conditionMessage(e),
        details = e$details
      )
    },
    error = function(e) {
      workbench_error_result(
        command = "",
        code = "CLI_FAILED",
        message = conditionMessage(e),
        details = list(class = class(e))
      )
    }
  )

  if (!is.null(output)) {
    writeLines(as.character(encode_workbench_json(result, pretty = TRUE)), con = output, useBytes = TRUE)
  }

  invisible(result)
}
