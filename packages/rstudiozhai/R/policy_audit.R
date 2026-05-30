sensitive_audit_name <- function(name) {
  grepl("(^|_)(api[_-]?key|password|passwd|token|secret|authorization|bearer)($|_)", tolower(name))
}

large_text_audit_name <- function(name) {
  tolower(name) %in% c("task", "ai_result", "selection", "contents", "content", "error_message")
}

summarize_audit_value <- function(value, name = "") {
  if (sensitive_audit_name(name)) {
    return("[REDACTED]")
  }

  if (is.character(value) && length(value) == 1L) {
    if (large_text_audit_name(name)) {
      return(list(type = "character", nchar = nchar(value, type = "chars")))
    }
    if (nchar(value, type = "chars") > 160L) {
      return(list(type = "character", nchar = nchar(value, type = "chars")))
    }
    return(value)
  }

  if (is.atomic(value) && length(value) <= 8L) {
    return(value)
  }

  if (is.list(value)) {
    keys <- names(value)
    if (is.null(keys)) {
      keys <- paste0("item_", seq_along(value))
    }
    safe_keys <- keys[!vapply(keys, sensitive_audit_name, logical(1))]
    return(list(
      type = "list",
      keys = safe_keys,
      length = length(value)
    ))
  }

  list(type = class(value)[[1L]], length = length(value))
}

summarize_audit_params <- function(params) {
  if (is.null(params)) {
    return(list())
  }
  if (!is.list(params)) {
    return(list(type = class(params)[[1L]]))
  }

  params <- params[setdiff(names(params), "audit_path")]
  keys <- names(params)
  if (is.null(keys)) {
    keys <- paste0("item_", seq_along(params))
  }
  stats::setNames(
    lapply(seq_along(params), function(index) {
      summarize_audit_value(params[[index]], keys[[index]])
    }),
    keys
  )
}

check_workbench_policy <- function(command, params, catalog = available_workbench_commands()) {
  row <- catalog[match(command, catalog$command), , drop = FALSE]
  mutates_files <- NROW(row) == 1L && isTRUE(row$mutates_files[[1L]])
  allow_write <- if (is.list(params) && !is.null(params$allow_write)) {
    param_logical(params, "allow_write", default = FALSE)
  } else {
    FALSE
  }

  if (mutates_files && !isTRUE(allow_write)) {
    return(list(
      ok = FALSE,
      code = "WRITE_NOT_ALLOWED",
      message = paste0(command, " writes files and requires allow_write = TRUE"),
      details = list(command = command)
    ))
  }

  list(
    ok = TRUE,
    code = "",
    message = "",
    details = list(command = command, mutates_files = mutates_files, allow_write = allow_write)
  )
}

audit_path_from_params <- function(params) {
  if (is.list(params) && !is.null(params$audit_path)) {
    path <- unwrap_scalar(params$audit_path)
    if (is.character(path) && length(path) == 1L && nzchar(trimws(path))) {
      return(trimws(path))
    }
  }
  env_path <- Sys.getenv("RSTUDIOZHAI_AUDIT_LOG", unset = "")
  if (nzchar(env_path)) {
    return(env_path)
  }
  ""
}

audit_event_from_result <- function(command, params, result, catalog = available_workbench_commands()) {
  row <- catalog[match(command, catalog$command), , drop = FALSE]
  mutates_files <- NROW(row) == 1L && isTRUE(row$mutates_files[[1L]])

  list(
    created_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    event = "workbench_command",
    command = command,
    ok = isTRUE(result$ok),
    mutates_files = mutates_files,
    allow_write = if (is.list(params) && !is.null(params$allow_write)) {
      param_logical(params, "allow_write", default = FALSE)
    } else {
      FALSE
    },
    provider = if (is.list(params) && !is.null(params$provider)) as.character(unwrap_scalar(params$provider)) else "",
    mode = if (is.list(params) && !is.null(params$mode)) as.character(unwrap_scalar(params$mode)) else "",
    error_code = if (!isTRUE(result$ok) && is.list(result$error)) result$error$code else "",
    params = summarize_audit_params(params)
  )
}

append_workbench_audit_event <- function(path, event) {
  if (!nzchar(path)) {
    return(FALSE)
  }
  ensure_jsonlite()
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  line <- as.character(jsonlite::toJSON(
    event,
    auto_unbox = TRUE,
    null = "null",
    na = "null",
    dataframe = "rows"
  ))
  cat(line, "\n", file = path, append = TRUE, sep = "")
  TRUE
}

audit_workbench_result <- function(command, params, result, catalog = available_workbench_commands()) {
  path <- audit_path_from_params(params)
  if (!nzchar(path)) {
    return(result)
  }

  ok <- tryCatch(
    append_workbench_audit_event(path, audit_event_from_result(command, params, result, catalog = catalog)),
    error = function(e) {
      if (is.null(result$warnings)) {
        result$warnings <<- character()
      }
      result$warnings <<- c(result$warnings, paste0("Audit log failed: ", conditionMessage(e)))
      FALSE
    }
  )
  if (isTRUE(ok) && is.null(result$warnings)) {
    result$warnings <- character()
  }
  result
}

empty_audit_events <- function() {
  data.frame(
    created_at = character(),
    event = character(),
    command = character(),
    ok = logical(),
    mutates_files = logical(),
    allow_write = logical(),
    provider = character(),
    mode = character(),
    error_code = character(),
    stringsAsFactors = FALSE
  )
}

read_workbench_audit_log <- function(path, limit = 20L) {
  if (!is.character(path) || length(path) != 1L || !nzchar(path) || !file.exists(path)) {
    return(empty_audit_events())
  }
  ensure_jsonlite()
  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines)) {
    return(empty_audit_events())
  }
  if (length(lines) > limit) {
    lines <- utils::tail(lines, limit)
  }

  rows <- lapply(lines, function(line) {
    item <- jsonlite::fromJSON(line, simplifyVector = FALSE)
    data.frame(
      created_at = if (!is.null(item$created_at)) item$created_at else "",
      event = if (!is.null(item$event)) item$event else "",
      command = if (!is.null(item$command)) item$command else "",
      ok = isTRUE(item$ok),
      mutates_files = isTRUE(item$mutates_files),
      allow_write = isTRUE(item$allow_write),
      provider = if (!is.null(item$provider)) item$provider else "",
      mode = if (!is.null(item$mode)) item$mode else "",
      error_code = if (!is.null(item$error_code)) item$error_code else "",
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

format_workbench_audit_log <- function(events) {
  if (!NROW(events)) {
    return("# RStudioZH Audit Log\n\n- No audit events found.")
  }

  lines <- apply(events, 1L, function(row) {
    paste0(
      "- ", row[["created_at"]],
      " | ", row[["command"]],
      " | ok=", row[["ok"]],
      if (nzchar(row[["error_code"]])) paste0(" | error=", row[["error_code"]]) else "",
      if (nzchar(row[["provider"]])) paste0(" | provider=", row[["provider"]]) else "",
      if (nzchar(row[["mode"]])) paste0(" | mode=", row[["mode"]]) else ""
    )
  })
  paste("# RStudioZH Audit Log", "", paste(lines, collapse = "\n"), sep = "\n")
}
