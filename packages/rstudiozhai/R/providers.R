compact_lines <- function(lines) {
  lines <- unlist(lines, use.names = FALSE)
  lines <- lines[!is.na(lines) & nzchar(trimws(lines))]
  paste(lines, collapse = "\n")
}

safe_context_value <- function(context, path, default = "") {
  value <- context
  for (name in path) {
    if (!is.list(value) || is.null(value[[name]])) {
      return(default)
    }
    value <- value[[name]]
  }
  if (is.null(value)) default else value
}

summarize_environment_for_provider <- function(environment) {
  if (!is.list(environment)) {
    return(character())
  }

  package_lines <- character()
  if (length(environment$packages)) {
    missing <- vapply(environment$packages, function(pkg) {
      !isTRUE(pkg$installed)
    }, logical(1))
    if (any(missing)) {
      names <- vapply(environment$packages[missing], function(pkg) pkg$name, character(1))
      package_lines <- paste0("- Missing R packages: ", paste(names, collapse = ", "))
    } else {
      package_lines <- "- Required R packages are installed."
    }
  }

  suggestion_lines <- character()
  if (length(environment$suggestions)) {
    suggestion_lines <- vapply(environment$suggestions, function(item) {
      paste0("- ", item$code, ": ", item$message)
    }, character(1))
  }

  compact_lines(c(
    "Environment:",
    paste0("- R: ", safe_context_value(environment, c("r", "version"))),
    paste0("- RStudio: ", safe_context_value(environment, c("rstudio", "version"))),
    paste0("- Quarto: ", safe_context_value(environment, c("quarto", "version"))),
    package_lines,
    "Suggestions:",
    suggestion_lines
  ))
}

summarize_rstudio_context_for_provider <- function(rstudio) {
  if (!is.list(rstudio)) {
    return("")
  }

  selection <- safe_context_value(rstudio, c("active_document", "selection"))
  document_path <- safe_context_value(rstudio, c("active_document", "path"))
  project_path <- safe_context_value(rstudio, c("project_path"))

  compact_lines(c(
    "RStudio context:",
    paste0("- Available: ", isTRUE(rstudio$available)),
    paste0("- Project: ", project_path),
    paste0("- Active file: ", document_path),
    if (nzchar(selection)) {
      c("Selected text:", limit_context_text(selection, max_chars = 2000L))
    } else {
      "- No selected text was provided."
    }
  ))
}

local_chinese_provider <- function(request) {
  if (!is.list(request) || is.null(request$task)) {
    stop("request must be created by build_ai_task_request()", call. = FALSE)
  }

  environment <- safe_context_value(request, c("context", "environment"), default = list())
  rstudio <- safe_context_value(request, c("context", "rstudio"), default = list())
  error_message <- safe_context_value(request, c("context", "error"), default = "")
  env_summary <- summarize_environment_for_provider(environment)
  rstudio_summary <- summarize_rstudio_context_for_provider(rstudio)
  knowledge_summary <- summarize_knowledge_for_query(
    paste(request$task, safe_context_value(rstudio, c("active_document", "selection")), sep = "\n"),
    error_message = error_message
  )

  mode_intro <- switch(
    request$mode,
    diagnose = "\u8fd9\u662f\u672c\u5730\u89c4\u5219\u578b\u8bca\u65ad\u7ed3\u679c\uff0c\u4e0d\u9700\u8981\u4e0a\u4f20\u4ee3\u7801\u6216\u8c03\u7528\u5916\u90e8 AI\u3002",
    explain = "\u8fd9\u662f\u672c\u5730\u89c4\u5219\u578b\u89e3\u91ca\u7ed3\u679c\uff0c\u9002\u5408\u5148\u5feb\u901f\u7406\u89e3\u9009\u533a\u6216\u62a5\u9519\u3002",
    edit = "\u8fd9\u662f\u4fee\u6539\u5efa\u8bae\u8349\u6848\uff0c\u9ed8\u8ba4\u4e0d\u4f1a\u76f4\u63a5\u5199\u5165\u6587\u4ef6\u3002",
    generate = "\u8fd9\u662f\u751f\u6210\u4efb\u52a1\u7684\u672c\u5730\u89c4\u5219\u578b\u8ba1\u5212\uff0c\u53ef\u4ee5\u4f5c\u4e3a\u63a5\u5165\u771f\u5b9e AI Provider \u524d\u7684\u57fa\u7ebf\u3002",
    "\u8fd9\u662f\u672c\u5730\u89c4\u5219\u578b\u7ed3\u679c\u3002"
  )

  next_steps <- switch(
    request$mode,
    diagnose = c(
      "1. \u5148\u4fee\u590d\u7f3a\u5931\u7684 R \u5305\u6216\u5916\u90e8\u5de5\u5177\u3002",
      "2. \u518d\u6253\u5f00 RStudio Addin \u68c0\u67e5\u662f\u5426\u80fd\u8bfb\u53d6\u9879\u76ee\u548c\u9009\u533a\u3002",
      "3. \u957f\u4efb\u52a1\u5e94\u8fdb Jobs \u6216 Rscript \u5b50\u8fdb\u7a0b\u3002"
    ),
    explain = c(
      "1. \u5148\u786e\u8ba4\u9009\u533a\u662f\u6700\u5c0f\u53ef\u89e3\u91ca\u7247\u6bb5\u3002",
      "2. \u5982\u679c\u662f\u62a5\u9519\uff0c\u540c\u65f6\u63d0\u4f9b\u9519\u8bef\u6587\u672c\u548c\u76f8\u5173\u4ee3\u7801\u3002",
      "3. \u63a5\u5165\u771f\u5b9e AI Provider \u540e\uff0c\u4fdd\u7559\u672c\u5730\u89c4\u5219\u7ed3\u679c\u4f5c\u4e3a\u5feb\u901f\u515c\u5e95\u3002"
    ),
    edit = c(
      "1. \u5148\u751f\u6210 diff \u6216 proposed_files\uff0c\u4e0d\u8981\u76f4\u63a5\u6539\u7528\u6237\u6587\u4ef6\u3002",
      "2. \u5199\u5165\u524d\u4fdd\u6301 require_user_confirmation = TRUE\u3002",
      "3. \u6bcf\u4e2a\u4fee\u6539\u5e94\u6709\u5bf9\u5e94\u6d4b\u8bd5\u6216\u9a8c\u8bc1\u547d\u4ee4\u3002"
    ),
    generate = c(
      "1. \u5148\u751f\u6210 Quarto \u6216 R \u811a\u672c\u8349\u7a3f\u3002",
      "2. \u4e0d\u8986\u76d6\u73b0\u6709\u6587\u4ef6\uff0c\u4f7f\u7528\u65b0\u6587\u4ef6\u8f93\u51fa\u3002",
      "3. \u6e32\u67d3\u6216\u6267\u884c\u4efb\u52a1\u5e94\u8fdb\u957f\u4efb\u52a1\u901a\u9053\u3002"
    )
  )

  content <- compact_lines(c(
    "\u4efb\u52a1\uff1a",
    paste0("- ", request$task),
    "",
    "\u5224\u65ad\uff1a",
    paste0("- ", mode_intro),
    "",
    env_summary,
    "",
    rstudio_summary,
    "",
    if (nzchar(knowledge_summary)) c("Knowledge base matches:", knowledge_summary, "") else character(),
    "\u5efa\u8bae\u4e0b\u4e00\u6b65\uff1a",
    next_steps
  ))

  list(
    ok = TRUE,
    content = content,
    proposed_files = list(),
    warnings = if (identical(request$provider, "local")) {
      character()
    } else {
      "\u5f53\u524d\u4f7f\u7528\u672c\u5730\u89c4\u5219\u578b Provider\uff0c\u4e0d\u7b49\u540c\u4e8e\u771f\u5b9e\u5927\u6a21\u578b\u63a8\u7406\u3002"
    },
    raw = list(provider = "local", request = request)
  )
}
