MCP_PROTOCOL_VERSION <- "2025-11-25"
MCP_CHARACTER_LIMIT <- 25000L

mcp_server_info <- function() {
  list(
    name = "rstudiozhai-mcp",
    version = workbench_package_version()
  )
}

mcp_string_schema <- function(description) {
  list(type = "string", description = description)
}

mcp_boolean_schema <- function(description, default = FALSE) {
  list(type = "boolean", description = description, default = isTRUE(default))
}

mcp_integer_schema <- function(description, default = 5L, minimum = 1L, maximum = 50L) {
  list(
    type = "integer",
    description = description,
    default = as.integer(default),
    minimum = as.integer(minimum),
    maximum = as.integer(maximum)
  )
}

mcp_object_schema <- function(description) {
  list(
    type = "object",
    description = description,
    additionalProperties = TRUE
  )
}

mcp_empty_object <- function() {
  structure(list(), names = character())
}

mcp_required_array <- function(required) {
  required <- as.character(required)
  if (!length(required)) {
    return(list())
  }
  as.list(required)
}

mcp_tool <- function(name,
                     title,
                     description,
                     properties = mcp_empty_object(),
                     required = character(),
                     read_only = TRUE,
                     destructive = FALSE,
                     idempotent = TRUE,
                     open_world = FALSE) {
  if (is.null(properties$audit_path)) {
    properties$audit_path <- mcp_string_schema("Optional JSONL audit log path. If omitted, no audit file is written.")
  }
  list(
    name = name,
    description = description,
    inputSchema = list(
      type = "object",
      properties = properties,
      required = mcp_required_array(required),
      additionalProperties = FALSE
    ),
    annotations = list(
      title = title,
      readOnlyHint = isTRUE(read_only),
      destructiveHint = isTRUE(destructive),
      idempotentHint = isTRUE(idempotent),
      openWorldHint = isTRUE(open_world)
    )
  )
}

mcp_tool_definitions <- function() {
  list(
    mcp_tool(
      name = "rstudiozhai_list_commands",
      title = "List RStudioZH Workbench Commands",
      description = paste(
        "List stable RStudio Chinese AI Workbench middleware commands.",
        "Use this first when discovering available local R/RStudio automation capabilities."
      )
    ),
    mcp_tool(
      name = "rstudiozhai_diagnostics",
      title = "Collect RStudio/R Diagnostics",
      description = paste(
        "Collect R, RStudio, Quarto, and package diagnostics.",
        "Optional packages accepts a character array when callers need a focused dependency check."
      ),
      properties = list(
        packages = list(
          type = "array",
          description = "Optional R package names to check.",
          items = list(type = "string")
        ),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      )
    ),
    mcp_tool(
      name = "rstudiozhai_provider_status",
      title = "Check AI Provider Status",
      description = paste(
        "Report AI provider readiness without making network calls.",
        "Use this before running openai_responses or custom provider workflows."
      ),
      properties = list(
        provider = mcp_string_schema("Provider name: local, mock, openai_responses, or compatible_chat."),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      )
    ),
    mcp_tool(
      name = "rstudiozhai_provider_probe",
      title = "Probe AI Provider Models",
      description = paste(
        "Read-only probe for OpenAI-compatible provider model listing.",
        "Uses /models and never writes files; API key arguments are redacted from audit logs."
      ),
      properties = list(
        provider = mcp_string_schema("Provider name: openai_responses or compatible_chat."),
        model = mcp_string_schema("Optional model value used for config validation."),
        base_url = mcp_string_schema("Optional provider base URL."),
        endpoint = mcp_string_schema("Optional compatible chat endpoint path."),
        api_key = mcp_string_schema("Optional API key. Local compatible gateways may leave it empty."),
        timeout_seconds = mcp_integer_schema("HTTP timeout in seconds.", default = 10L, minimum = 1L, maximum = 120L),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      ),
      open_world = TRUE
    ),
    mcp_tool(
      name = "rstudiozhai_provider_report",
      title = "Collect AI Provider Integration Report",
      description = paste(
        "Collect a read-only integration report for local or enterprise AI gateways.",
        "Includes safe config summary, provider status, model probe result, repair suggestions, and optional local diagnostics."
      ),
      properties = list(
        provider = mcp_string_schema("Provider name: openai_responses or compatible_chat."),
        model = mcp_string_schema("Optional model value used for config validation."),
        base_url = mcp_string_schema("Optional provider base URL."),
        endpoint = mcp_string_schema("Optional compatible chat endpoint path."),
        api_key = mcp_string_schema("Optional API key. This value is redacted from reports and audit logs."),
        include_environment = mcp_boolean_schema("Include R/RStudio/Quarto diagnostics. Defaults to true.", default = TRUE),
        include_extension = mcp_boolean_schema("Include RStudio extension install status. Defaults to true.", default = TRUE),
        packages = list(
          type = "array",
          description = "Optional R package names for the environment section.",
          items = list(type = "string")
        ),
        timeout_seconds = mcp_integer_schema("HTTP timeout in seconds.", default = 10L, minimum = 1L, maximum = 120L),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      ),
      open_world = TRUE
    ),
    mcp_tool(
      name = "rstudiozhai_provider_presets",
      title = "List AI Provider Gateway Presets",
      description = paste(
        "List built-in OpenAI-compatible gateway presets for Ollama, vLLM, LiteLLM, and enterprise gateways.",
        "This is read-only and does not contact the gateways."
      ),
      properties = list(
        preset = mcp_string_schema("Optional preset id to return: ollama, vllm, litellm, or enterprise_compatible."),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      )
    ),
    mcp_tool(
      name = "rstudiozhai_provider_checklist",
      title = "Create AI Provider Integration Checklist",
      description = paste(
        "Create a read-only manual integration checklist from a gateway preset.",
        "It suggests safe current-session config values and a provider-report command without writing files or contacting the network."
      ),
      properties = list(
        preset = mcp_string_schema("Preset id: ollama, vllm, litellm, or enterprise_compatible."),
        model = mcp_string_schema("Optional model name override."),
        base_url = mcp_string_schema("Optional base URL override."),
        endpoint = mcp_string_schema("Optional endpoint override."),
        api_key = mcp_string_schema("Optional API key. This value is redacted from checklist output and audit logs."),
        include_report_command = mcp_boolean_schema("Include provider-report command hint. Defaults to true.", default = TRUE),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      )
    ),
    mcp_tool(
      name = "rstudiozhai_provider_compatibility",
      title = "List AI Provider Compatibility Matrix",
      description = paste(
        "List compatible provider and gateway targets for the RStudio Chinese AI Workbench.",
        "This is read-only and does not contact any network service."
      ),
      properties = list(
        target_type = mcp_string_schema("Optional filter: offline, openai_api, local_gateway, cloud_gateway, enterprise_gateway, or all."),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      )
    ),
    mcp_tool(
      name = "rstudiozhai_rstudio_extension_status",
      title = "Validate RStudio Extension Install",
      description = paste(
        "Validate installed RStudio Addin, Project Template, Connections, and snippets.",
        "This is read-only and does not launch RStudio or write user configuration."
      ),
      properties = list(
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      )
    ),
    mcp_tool(
      name = "rstudiozhai_project_scan",
      title = "Scan Local RStudio Project",
      description = paste(
        "Summarize a local R/RStudio project for AI context without entering heavy directories.",
        "By default this returns structure and markers only; include_text must be true to include small text previews."
      ),
      properties = list(
        path = mcp_string_schema("Project directory. Defaults to the current working directory."),
        max_files = mcp_integer_schema("Maximum files to return.", default = 200L, minimum = 1L, maximum = 2000L),
        max_bytes = mcp_integer_schema("Maximum bytes per file when include_text is true.", default = 4096L, minimum = 0L, maximum = 65536L),
        include_text = mcp_boolean_schema("Include small text previews. Defaults to false.", default = FALSE),
        include_patterns = list(
          type = "array",
          description = "Optional regular expressions matched against project-relative paths.",
          items = list(type = "string")
        ),
        exclude_dirs = list(
          type = "array",
          description = "Optional directory names or relative prefixes to exclude.",
          items = list(type = "string")
        ),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      )
    ),
    mcp_tool(
      name = "rstudiozhai_audit_log",
      title = "Read Workbench Audit Log",
      description = paste(
        "Read recent RStudioZH workbench audit events from a JSONL file.",
        "Use this to review command attempts, write approvals, and provider usage."
      ),
      properties = list(
        path = mcp_string_schema("Audit JSONL file path."),
        limit = mcp_integer_schema("Maximum events to return.", default = 20L, minimum = 1L, maximum = 200L),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      ),
      required = "path"
    ),
    mcp_tool(
      name = "rstudiozhai_search_knowledge",
      title = "Search Chinese RStudio Knowledge",
      description = paste(
        "Search bundled Chinese RStudio terms, command entries, and common R error explanations.",
        "Use it to explain RStudio concepts or map Chinese requests to RStudio actions."
      ),
      properties = list(
        query = mcp_string_schema("Search query, for example: quarto, object not found, addin."),
        error_message = mcp_string_schema("Optional raw R error text to match against known error patterns."),
        max_results = mcp_integer_schema("Maximum hits per knowledge category.", default = 5L),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      ),
      required = "query"
    ),
    mcp_tool(
      name = "rstudiozhai_run_ai_task",
      title = "Run Local AI Workbench Task",
      description = paste(
        "Run an AI workbench task through the configured provider contract.",
        "Defaults to the local Chinese rules provider and does not execute code or write files."
      ),
      properties = list(
        task = mcp_string_schema("User task to explain, diagnose, edit, or generate."),
        mode = mcp_string_schema("Task mode: explain, edit, generate, or diagnose."),
        provider = mcp_string_schema("Provider name: local, mock, or openai_responses."),
        context = mcp_object_schema("Optional bounded context such as selected code, error text, or environment report."),
        allow_code_execution = mcp_boolean_schema("Whether provider may propose code execution. Defaults to false.", default = FALSE),
        require_user_confirmation = mcp_boolean_schema("Whether user confirmation is required before changes. Defaults to true.", default = TRUE),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      ),
      required = "task"
    ),
    mcp_tool(
      name = "rstudiozhai_create_quarto_draft",
      title = "Create Quarto Report Draft",
      description = paste(
        "Create a Quarto .qmd report draft from a task and AI result.",
        "This writes a new file only when allow_write is explicitly true; it does not render by default."
      ),
      properties = list(
        task = mcp_string_schema("Report task or topic."),
        ai_result = mcp_string_schema("Optional AI result text to include in the report."),
        title = mcp_string_schema("Report title."),
        output_dir = mcp_string_schema("Output directory for the .qmd draft."),
        allow_write = mcp_boolean_schema("Must be true to write a file.", default = FALSE),
        include_environment = mcp_boolean_schema("Include local environment diagnostics.", default = TRUE),
        overwrite = mcp_boolean_schema("Allow overwriting the same output path.", default = FALSE),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      ),
      required = "task",
      read_only = FALSE,
      destructive = FALSE,
      idempotent = TRUE,
      open_world = FALSE
    ),
    mcp_tool(
      name = "rstudiozhai_connection_template",
      title = "Build Safe DBI Connection Template",
      description = paste(
        "List connection templates or generate safe DBI connection code.",
        "Generated code uses RStudio password prompt or environment variables and never hardcodes passwords."
      ),
      properties = list(
        kind = mcp_string_schema("Optional connection kind: sqlite, postgres, or odbc. Omit to list templates."),
        variable = mcp_string_schema("R variable name for generated connection code."),
        use_password_prompt = mcp_boolean_schema("Use rstudioapi::askForPassword when supported.", default = TRUE),
        response_format = mcp_string_schema("Return format: json or markdown. Defaults to json.")
      )
    )
  )
}

mcp_tool_command_map <- function() {
  c(
    rstudiozhai_list_commands = "list-commands",
    rstudiozhai_diagnostics = "diagnostics",
    rstudiozhai_provider_status = "provider-status",
    rstudiozhai_provider_probe = "provider-probe",
    rstudiozhai_provider_report = "provider-report",
    rstudiozhai_provider_presets = "provider-presets",
    rstudiozhai_provider_checklist = "provider-checklist",
    rstudiozhai_provider_compatibility = "provider-compatibility",
    rstudiozhai_rstudio_extension_status = "rstudio-extension-status",
    rstudiozhai_project_scan = "project-scan",
    rstudiozhai_audit_log = "audit-log",
    rstudiozhai_search_knowledge = "knowledge",
    rstudiozhai_run_ai_task = "ai-task",
    rstudiozhai_create_quarto_draft = "quarto-draft",
    rstudiozhai_connection_template = "connection-template"
  )
}

mcp_jsonrpc_result <- function(id, result) {
  list(jsonrpc = "2.0", id = id, result = result)
}

mcp_jsonrpc_error <- function(id, code, message, data = NULL) {
  error <- list(code = as.integer(code), message = message)
  if (!is.null(data)) {
    error$data <- data
  }
  list(jsonrpc = "2.0", id = id, error = error)
}

mcp_text_content <- function(text) {
  list(type = "text", text = as.character(text))
}

mcp_truncate_text <- function(text, limit = MCP_CHARACTER_LIMIT) {
  text <- as.character(text)
  if (nchar(text, type = "chars", allowNA = FALSE, keepNA = FALSE) <= limit) {
    return(text)
  }
  paste0(
    substr(text, 1L, max(0L, limit - 180L)),
    "\n\n[Response truncated by rstudiozhai MCP from ",
    nchar(text, type = "chars"),
    " characters. Use narrower parameters to reduce output.]"
  )
}

mcp_tool_result <- function(text, is_error = FALSE) {
  list(
    content = list(mcp_text_content(mcp_truncate_text(text))),
    isError = isTRUE(is_error)
  )
}

mcp_markdown_for_workbench_result <- function(result) {
  if (!isTRUE(result$ok)) {
    return(paste0(
      "# Workbench command failed\n\n",
      "- Command: ", result$command, "\n",
      "- Code: ", result$error$code, "\n",
      "- Message: ", result$error$message, "\n"
    ))
  }

  if (identical(result$command, "diagnostics") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "provider-status") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "provider-probe") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "provider-report") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "provider-presets") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "provider-checklist") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "provider-compatibility") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "rstudio-extension-status") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "project-scan") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "audit-log") && is.character(result$data$markdown)) {
    return(result$data$markdown)
  }
  if (identical(result$command, "knowledge") && is.character(result$data$summary)) {
    return(paste0("# Knowledge results\n\n", result$data$summary))
  }
  if (identical(result$command, "ai-task") && is.character(result$data$response$content)) {
    return(result$data$response$content)
  }
  if (identical(result$command, "quarto-draft")) {
    return(paste0("# Quarto draft\n\n- Path: ", result$data$path, "\n- Title: ", result$data$title))
  }
  if (identical(result$command, "connection-template") && is.character(result$data$code)) {
    return(paste0("# Connection template\n\n```r\n", result$data$code, "\n```"))
  }

  encode_workbench_json(result, pretty = TRUE)
}

mcp_encode_workbench_result <- function(result, response_format = "json") {
  response_format <- tolower(trimws(response_format))
  if (identical(response_format, "markdown")) {
    return(mcp_markdown_for_workbench_result(result))
  }
  as.character(encode_workbench_json(result, pretty = TRUE))
}

mcp_call_tool <- function(name, arguments = list()) {
  if (is.null(arguments)) {
    arguments <- list()
  }
  if (!is.list(arguments)) {
    return(mcp_tool_result("Tool arguments must be a JSON object.", is_error = TRUE))
  }

  map <- mcp_tool_command_map()
  if (!name %in% names(map)) {
    return(mcp_tool_result(paste0("Unknown MCP tool: ", name), is_error = TRUE))
  }

  response_format <- "json"
  if (!is.null(arguments$response_format)) {
    response_format <- as.character(arguments$response_format[[1L]])
    arguments$response_format <- NULL
  }

  result <- run_workbench_command(unname(map[[name]]), arguments)
  text <- mcp_encode_workbench_result(result, response_format = response_format)
  mcp_tool_result(text, is_error = !isTRUE(result$ok))
}

mcp_initialize_result <- function(params = list()) {
  requested <- if (is.list(params) && is.character(params$protocolVersion) && nzchar(params$protocolVersion)) {
    params$protocolVersion
  } else {
    MCP_PROTOCOL_VERSION
  }

  list(
    protocolVersion = requested,
    capabilities = list(tools = list()),
    serverInfo = mcp_server_info()
  )
}

mcp_handle_request <- function(request) {
  if (!is.list(request)) {
    return(mcp_jsonrpc_error(NULL, -32600L, "Invalid JSON-RPC request."))
  }
  if (!identical(request$jsonrpc, "2.0")) {
    return(mcp_jsonrpc_error(request$id, -32600L, "jsonrpc must be 2.0."))
  }
  if (is.null(request$method) || !is.character(request$method) || length(request$method) != 1L) {
    return(mcp_jsonrpc_error(request$id, -32600L, "method must be a string."))
  }

  is_notification <- is.null(request$id)
  if (is_notification) {
    return(NULL)
  }

  method <- request$method
  params <- if (is.null(request$params)) list() else request$params

  switch(
    method,
    initialize = mcp_jsonrpc_result(request$id, mcp_initialize_result(params)),
    ping = mcp_jsonrpc_result(request$id, list()),
    "tools/list" = mcp_jsonrpc_result(request$id, list(tools = mcp_tool_definitions())),
    "tools/call" = {
      if (!is.list(params) || !is.character(params$name) || length(params$name) != 1L) {
        mcp_jsonrpc_error(request$id, -32602L, "tools/call requires params.name.")
      } else {
        mcp_jsonrpc_result(
          request$id,
          mcp_call_tool(params$name, arguments = if (is.null(params$arguments)) list() else params$arguments)
        )
      }
    },
    mcp_jsonrpc_error(request$id, -32601L, paste0("Method not found: ", method))
  )
}

mcp_handle_json_line <- function(line) {
  ensure_jsonlite()
  request <- tryCatch(
    jsonlite::fromJSON(line, simplifyVector = FALSE),
    error = function(e) {
      return(structure(
        list(message = conditionMessage(e)),
        class = "rstudiozhai_mcp_parse_error"
      ))
    }
  )

  if (inherits(request, "rstudiozhai_mcp_parse_error")) {
    response <- mcp_jsonrpc_error(NULL, -32700L, paste0("Parse error: ", request$message))
  } else {
    response <- mcp_handle_request(request)
  }

  if (is.null(response)) {
    return(NULL)
  }
  as.character(jsonlite::toJSON(
    response,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    dataframe = "rows"
  ))
}

mcp_stdio_server <- function(input = NULL, output = stdout()) {
  ensure_jsonlite()
  close_input <- FALSE
  if (is.null(input)) {
    input <- file("stdin", open = "r")
    close_input <- TRUE
  }
  if (isTRUE(close_input)) {
    on.exit(close(input), add = TRUE)
  }

  repeat {
    line <- readLines(input, n = 1L, warn = FALSE, encoding = "UTF-8")
    if (!length(line)) {
      break
    }
    if (!nzchar(trimws(line))) {
      next
    }

    response <- mcp_handle_json_line(line)
    if (!is.null(response)) {
      writeLines(response, con = output, useBytes = TRUE)
      flush(output)
    }
  }
  invisible(TRUE)
}
