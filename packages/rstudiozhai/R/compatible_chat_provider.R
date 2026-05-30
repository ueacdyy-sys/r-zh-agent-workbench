get_compatible_chat_config <- function(api_key = Sys.getenv("RSTUDIOZHAI_GATEWAY_API_KEY", unset = ""),
                                       model = Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = ""),
                                       base_url = Sys.getenv(
                                         "RSTUDIOZHAI_GATEWAY_BASE_URL",
                                         unset = "http://127.0.0.1:11434/v1"
                                       ),
                                       endpoint = Sys.getenv(
                                         "RSTUDIOZHAI_GATEWAY_ENDPOINT",
                                         unset = "/chat/completions"
                                       )) {
  endpoint <- paste0("/", sub("^/+", "", endpoint))
  list(
    api_key = api_key,
    model = model,
    base_url = sub("/+$", "", base_url),
    endpoint = endpoint
  )
}

validate_compatible_chat_config <- function(config) {
  if (!is.list(config)) {
    stop("config must be a list", call. = FALSE)
  }
  if (!is.character(config$model) || length(config$model) != 1L || !nzchar(config$model)) {
    stop("Compatible chat model is missing. Set RSTUDIOZHAI_GATEWAY_MODEL or pass model.", call. = FALSE)
  }
  if (!is.character(config$base_url) || length(config$base_url) != 1L || !nzchar(config$base_url)) {
    stop("Compatible chat base_url is missing. Set RSTUDIOZHAI_GATEWAY_BASE_URL or pass base_url.", call. = FALSE)
  }
  if (!is.character(config$endpoint) || length(config$endpoint) != 1L || !nzchar(config$endpoint)) {
    stop("Compatible chat endpoint is missing. Set RSTUDIOZHAI_GATEWAY_ENDPOINT or pass endpoint.", call. = FALSE)
  }
  TRUE
}

build_compatible_chat_payload <- function(request,
                                          model,
                                          max_tokens = 1200L,
                                          temperature = NULL,
                                          stream = FALSE) {
  payload <- list(
    model = model,
    messages = list(
      list(role = "system", content = build_openai_instructions(request)),
      list(role = "user", content = build_openai_input(request))
    ),
    stream = isTRUE(stream),
    max_tokens = as.integer(max_tokens)
  )
  if (!is.null(temperature)) {
    payload$temperature <- temperature
  }
  payload
}

default_compatible_chat_http_post <- function(url, api_key, payload, timeout_seconds = 60L) {
  if (!requireNamespace("httr2", quietly = TRUE)) {
    stop("httr2 is required for the compatible chat provider. Install httr2 first.", call. = FALSE)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite is required for the compatible chat provider. Install jsonlite first.", call. = FALSE)
  }

  req <- httr2::request(url)
  req <- httr2::req_headers(req, `Content-Type` = "application/json")
  if (is.character(api_key) && length(api_key) == 1L && nzchar(api_key)) {
    req <- httr2::req_headers(req, Authorization = paste("Bearer", api_key))
  }
  req <- httr2::req_timeout(req, timeout_seconds)
  req <- httr2::req_body_json(req, payload, auto_unbox = TRUE)
  response <- httr2::req_perform(req)

  text <- httr2::resp_body_string(response)
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

extract_compatible_chat_response_text <- function(response) {
  if (!is.list(response)) {
    stop("Compatible chat response must be a list", call. = FALSE)
  }
  choices <- response$choices
  if (!is.list(choices) || !length(choices)) {
    stop("Compatible chat response did not contain content", call. = FALSE)
  }

  chunks <- unlist(lapply(choices, function(choice) {
    if (!is.list(choice)) {
      return(character())
    }
    message_content <- if (is.list(choice$message)) choice$message$content else character()
    delta_content <- if (is.list(choice$delta)) choice$delta$content else character()
    text_content <- choice$text
    c(message_content, delta_content, text_content)
  }), use.names = FALSE)
  chunks <- chunks[is.character(chunks) & nzchar(chunks)]
  if (length(chunks)) {
    return(paste(chunks, collapse = "\n"))
  }

  stop("Compatible chat response did not contain content", call. = FALSE)
}

compatible_chat_provider <- function(request,
                                     api_key = Sys.getenv("RSTUDIOZHAI_GATEWAY_API_KEY", unset = ""),
                                     model = Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = ""),
                                     base_url = Sys.getenv(
                                       "RSTUDIOZHAI_GATEWAY_BASE_URL",
                                       unset = "http://127.0.0.1:11434/v1"
                                     ),
                                     endpoint = Sys.getenv(
                                       "RSTUDIOZHAI_GATEWAY_ENDPOINT",
                                       unset = "/chat/completions"
                                     ),
                                     http_post = default_compatible_chat_http_post,
                                     max_tokens = 1200L,
                                     temperature = NULL,
                                     timeout_seconds = 60L) {
  if (!is.list(request) || is.null(request$task)) {
    stop("request must be created by build_ai_task_request()", call. = FALSE)
  }
  config <- get_compatible_chat_config(
    api_key = api_key,
    model = model,
    base_url = base_url,
    endpoint = endpoint
  )
  validate_compatible_chat_config(config)
  if (!is.function(http_post)) {
    stop("http_post must be a function", call. = FALSE)
  }

  payload <- build_compatible_chat_payload(
    request,
    model = config$model,
    max_tokens = max_tokens,
    temperature = temperature,
    stream = FALSE
  )
  url <- paste0(config$base_url, config$endpoint)
  raw <- http_post(url = url, api_key = config$api_key, payload = payload, timeout_seconds = timeout_seconds)
  content <- extract_compatible_chat_response_text(raw)

  list(
    ok = TRUE,
    content = content,
    proposed_files = list(),
    warnings = character(),
    raw = list(
      provider = "compatible_chat",
      url = url,
      model = config$model,
      endpoint = config$endpoint,
      response = raw
    )
  )
}
