build_ai_task_request <- function(task,
                                  context = list(),
                                  mode = "diagnose",
                                  provider = "mock",
                                  allow_code_execution = FALSE,
                                  require_user_confirmation = TRUE) {
  if (!is.character(task) || length(task) != 1L || !nzchar(trimws(task))) {
    stop("task must be a non-empty string", call. = FALSE)
  }
  if (!is.list(context)) {
    stop("context must be a named list", call. = FALSE)
  }
  if (!mode %in% c("explain", "edit", "generate", "diagnose")) {
    stop("mode must be one of explain, edit, generate, diagnose", call. = FALSE)
  }

  list(
    task = trimws(task),
    mode = mode,
    provider = provider,
    context = context,
    safety = list(
      allow_code_execution = isTRUE(allow_code_execution),
      require_user_confirmation = isTRUE(require_user_confirmation)
    ),
    metadata = list(
      created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
      client = "rstudiozhai"
    )
  )
}

validate_ai_response <- function(response) {
  if (!is.list(response)) {
    stop("AI provider must return a list", call. = FALSE)
  }
  if (is.null(response$ok)) {
    stop("AI provider response must contain ok", call. = FALSE)
  }
  if (isTRUE(response$ok) && (!is.character(response$content) || !nzchar(response$content))) {
    stop("successful AI provider response must contain non-empty content", call. = FALSE)
  }
  TRUE
}

invoke_ai_provider <- function(request, provider_fun) {
  if (!is.list(request) || is.null(request$task)) {
    stop("request must be created by build_ai_task_request()", call. = FALSE)
  }
  if (!is.function(provider_fun)) {
    stop("provider_fun must be a function", call. = FALSE)
  }

  response <- provider_fun(request)
  validate_ai_response(response)

  if (is.null(response$proposed_files)) {
    response$proposed_files <- list()
  }
  if (is.null(response$warnings)) {
    response$warnings <- character()
  }
  if (is.null(response$raw)) {
    response$raw <- NULL
  }

  response
}

mock_ai_provider <- function(request) {
  list(
    ok = TRUE,
    content = paste0(
      "\u5df2\u6536\u5230\u4efb\u52a1\uff1a", request$task,
      "\n\u6a21\u5f0f\uff1a", request$mode,
      "\n\u8fd9\u662f mock provider\uff0c\u7528\u4e8e TDD \u548c\u79bb\u7ebf\u9a8c\u8bc1\u3002"
    ),
    proposed_files = list(),
    warnings = character(),
    raw = request
  )
}
