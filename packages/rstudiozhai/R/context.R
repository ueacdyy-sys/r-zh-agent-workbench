limit_context_text <- function(text, max_chars = 12000L) {
  if (is.null(text)) {
    return("")
  }
  text <- paste(as.character(text), collapse = "\n")
  if (nchar(text, type = "chars") <= max_chars) {
    return(text)
  }
  paste0(substr(text, 1L, max_chars), "\n[context truncated]")
}

selection_text <- function(selection) {
  if (!length(selection)) {
    return("")
  }

  pieces <- vapply(selection, function(item) {
    text <- item$text
    if (is.null(text)) {
      ""
    } else {
      paste(as.character(text), collapse = "\n")
    }
  }, character(1))

  limit_context_text(paste(pieces[nzchar(pieces)], collapse = "\n\n"))
}

collect_rstudio_context <- function(max_chars = 12000L) {
  context <- list(
    available = FALSE,
    project_path = "",
    active_document = list(
      id = "",
      path = "",
      contents = "",
      selection = ""
    )
  )

  if (!requireNamespace("rstudioapi", quietly = TRUE)) {
    context$reason <- "rstudioapi package is not installed"
    return(context)
  }

  if (!isTRUE(rstudioapi::isAvailable())) {
    context$reason <- "RStudio API is not available in this session"
    return(context)
  }

  context$available <- TRUE
  context$project_path <- tryCatch(
    {
      project <- rstudioapi::getActiveProject()
      if (is.null(project)) "" else normalizePath(project, winslash = "/", mustWork = FALSE)
    },
    error = function(e) ""
  )

  document <- tryCatch(
    rstudioapi::getActiveDocumentContext(),
    error = function(e) NULL
  )

  if (!is.null(document)) {
    context$active_document <- list(
      id = if (is.null(document$id)) "" else as.character(document$id),
      path = if (is.null(document$path)) "" else normalizePath(document$path, winslash = "/", mustWork = FALSE),
      contents = limit_context_text(document$contents, max_chars = max_chars),
      selection = selection_text(document$selection)
    )
  }

  context
}
