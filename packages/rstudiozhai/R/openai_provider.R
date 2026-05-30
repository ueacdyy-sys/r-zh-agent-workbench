get_openai_config <- function(api_key = Sys.getenv("OPENAI_API_KEY", unset = ""),
                              model = Sys.getenv("RSTUDIOZHAI_OPENAI_MODEL", unset = ""),
                              base_url = Sys.getenv(
                                "RSTUDIOZHAI_OPENAI_BASE_URL",
                                unset = "https://api.openai.com/v1"
                              )) {
  list(
    api_key = api_key,
    model = model,
    base_url = sub("/+$", "", base_url)
  )
}

validate_openai_config <- function(config) {
  if (!is.list(config)) {
    stop("config must be a list", call. = FALSE)
  }
  if (!is.character(config$api_key) || length(config$api_key) != 1L || !nzchar(config$api_key)) {
    stop("OpenAI API key is missing. Set OPENAI_API_KEY or pass api_key.", call. = FALSE)
  }
  if (!is.character(config$model) || length(config$model) != 1L || !nzchar(config$model)) {
    stop("OpenAI model is missing. Set RSTUDIOZHAI_OPENAI_MODEL or pass model.", call. = FALSE)
  }
  if (!is.character(config$base_url) || length(config$base_url) != 1L || !nzchar(config$base_url)) {
    stop("OpenAI base_url is missing", call. = FALSE)
  }
  TRUE
}

build_openai_instructions <- function(request) {
  paste(
    "You are the external AI provider for rstudiozhai, a Chinese AI Workbench for RStudio.",
    "Answer in Chinese unless the user explicitly asks otherwise.",
    "Do not claim that code has been executed.",
    "Do not ask to write files directly.",
    "If you propose file changes, describe them clearly for user confirmation.",
    paste0("Mode: ", request$mode),
    paste0("Allow code execution: ", isTRUE(request$safety$allow_code_execution)),
    paste0("Require user confirmation: ", isTRUE(request$safety$require_user_confirmation)),
    sep = "\n"
  )
}

build_openai_input <- function(request, max_chars = 12000L) {
  context_text <- paste(utils::capture.output(utils::str(request$context, max.level = 3L)), collapse = "\n")
  paste(
    "User task:",
    request$task,
    "",
    "Bounded context:",
    limit_context_text(context_text, max_chars = max_chars),
    sep = "\n"
  )
}

build_openai_responses_payload <- function(request,
                                           model,
                                           max_output_tokens = 1200L,
                                           temperature = NULL) {
  payload <- list(
    model = model,
    instructions = build_openai_instructions(request),
    input = build_openai_input(request),
    max_output_tokens = as.integer(max_output_tokens)
  )
  if (!is.null(temperature)) {
    payload$temperature <- temperature
  }
  payload
}

default_openai_http_post <- function(url, api_key, payload, timeout_seconds = 60L) {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("httr2 is required for the OpenAI provider. Install httr2 first.", call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for the OpenAI provider. Install jsonlite first.", call. = FALSE)
  }

  req <- httr2::request(url)
  req <- httr2::req_headers(
    req,
    Authorization = paste("Bearer", api_key),
    `Content-Type` = "application/json"
  )
  req <- httr2::req_timeout(req, timeout_seconds)
  req <- httr2::req_body_json(req, payload, auto_unbox = TRUE)
  response <- httr2::req_perform(req)

  text <- httr2::resp_body_string(response)
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

extract_openai_response_text <- function(response) {
  if (!is.list(response)) {
    stop("OpenAI response must be a list", call. = FALSE)
  }
  if (is.character(response$output_text) && nzchar(response$output_text)) {
    return(response$output_text)
  }

  output <- response$output
  if (is.list(output) && length(output)) {
    chunks <- unlist(lapply(output, function(item) {
      content <- item$content
      if (!is.list(content)) {
        return(character())
      }
      unlist(lapply(content, function(part) {
        text <- part$text
        if (is.character(text) && length(text)) text else character()
      }), use.names = FALSE)
    }), use.names = FALSE)
    chunks <- chunks[nzchar(chunks)]
    if (length(chunks)) {
      return(paste(chunks, collapse = "\n"))
    }
  }

  stop("OpenAI response did not contain output text", call. = FALSE)
}

openai_responses_provider <- function(request,
                                      api_key = Sys.getenv("OPENAI_API_KEY", unset = ""),
                                      model = Sys.getenv("RSTUDIOZHAI_OPENAI_MODEL", unset = ""),
                                      base_url = Sys.getenv(
                                        "RSTUDIOZHAI_OPENAI_BASE_URL",
                                        unset = "https://api.openai.com/v1"
                                      ),
                                      http_post = default_openai_http_post,
                                      max_output_tokens = 1200L,
                                      temperature = NULL,
                                      timeout_seconds = 60L) {
  if (!is.list(request) || is.null(request$task)) {
    stop("request must be created by build_ai_task_request()", call. = FALSE)
  }
  config <- get_openai_config(api_key = api_key, model = model, base_url = base_url)
  validate_openai_config(config)
  if (!is.function(http_post)) {
    stop("http_post must be a function", call. = FALSE)
  }

  payload <- build_openai_responses_payload(
    request,
    model = config$model,
    max_output_tokens = max_output_tokens,
    temperature = temperature
  )
  url <- paste0(config$base_url, "/responses")
  raw <- http_post(url = url, api_key = config$api_key, payload = payload, timeout_seconds = timeout_seconds)
  content <- extract_openai_response_text(raw)

  list(
    ok = TRUE,
    content = content,
    proposed_files = list(),
    warnings = character(),
    raw = list(
      provider = "openai_responses",
      url = url,
      model = config$model,
      response = raw
    )
  )
}
