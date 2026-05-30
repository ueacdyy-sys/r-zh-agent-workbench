knowledge_file <- function(name) {
  path <- system.file("extdata", "knowledge", name, package = "rstudiozhai")
  if (!nzchar(path)) {
    local_path <- file.path("inst", "extdata", "knowledge", name)
    if (file.exists(local_path)) {
      return(normalizePath(local_path, winslash = "/", mustWork = TRUE))
    }
    stop("knowledge file not found: ", name, call. = FALSE)
  }
  path
}

read_knowledge_table <- function(name) {
  utils::read.csv(
    knowledge_file(name),
    stringsAsFactors = FALSE,
    fileEncoding = "UTF-8",
    check.names = FALSE
  )
}

list_rstudio_terms <- function(category = NULL) {
  terms <- read_knowledge_table("rstudio_terms.csv")
  if (!is.null(category)) {
    terms <- terms[tolower(terms$category) == tolower(category), , drop = FALSE]
  }
  terms
}

list_rstudio_commands <- function(category = NULL) {
  commands <- read_knowledge_table("rstudio_commands.csv")
  if (!is.null(category)) {
    commands <- commands[tolower(commands$category) == tolower(category), , drop = FALSE]
  }
  commands
}

text_match_score <- function(query, values) {
  query <- tolower(trimws(query))
  values <- tolower(paste(values, collapse = " "))
  if (!nzchar(query)) {
    return(0L)
  }
  words <- unique(strsplit(query, "\\s+")[[1]])
  sum(vapply(words, function(word) grepl(word, values, fixed = TRUE), logical(1)))
}

rank_table_by_query <- function(table, query, columns, max_results = 5L) {
  if (!is.character(query) || length(query) != 1L || !nzchar(trimws(query))) {
    stop("query must be a non-empty string", call. = FALSE)
  }

  scores <- apply(table[, columns, drop = FALSE], 1L, function(row) {
    text_match_score(query, row)
  })
  keep <- scores > 0L
  if (!any(keep)) {
    return(table[0L, , drop = FALSE])
  }

  ranked <- table[keep, , drop = FALSE]
  ranked$score <- scores[keep]
  ranked <- ranked[order(-ranked$score, ranked$id), , drop = FALSE]
  utils::head(ranked, max_results)
}

lookup_rstudio_term <- function(query, max_results = 5L) {
  rank_table_by_query(
    list_rstudio_terms(),
    query,
    columns = c("term", "zh", "category", "description", "action"),
    max_results = max_results
  )
}

search_rstudio_commands <- function(query, max_results = 5L) {
  rank_table_by_query(
    list_rstudio_commands(),
    query,
    columns = c("label", "zh_label", "category", "entrypoint", "description"),
    max_results = max_results
  )
}

explain_r_error <- function(message, max_results = 3L) {
  if (!is.character(message) || length(message) != 1L || !nzchar(trimws(message))) {
    stop("message must be a non-empty string", call. = FALSE)
  }

  patterns <- read_knowledge_table("r_error_patterns.csv")
  matched <- vapply(patterns$pattern, function(pattern) {
    grepl(pattern, message, ignore.case = TRUE, perl = TRUE)
  }, logical(1))

  utils::head(patterns[matched, , drop = FALSE], max_results)
}

format_term_hits <- function(hits) {
  if (!nrow(hits)) {
    return("")
  }
  compact_lines(apply(hits, 1L, function(row) {
    paste0("- ", row[["term"]], " / ", row[["zh"]], ": ", row[["description"]], " Action: ", row[["action"]])
  }))
}

format_command_hits <- function(hits) {
  if (!nrow(hits)) {
    return("")
  }
  compact_lines(apply(hits, 1L, function(row) {
    paste0("- ", row[["label"]], " / ", row[["zh_label"]], " (", row[["entrypoint"]], "): ", row[["description"]])
  }))
}

format_error_hits <- function(hits) {
  if (!nrow(hits)) {
    return("")
  }
  compact_lines(apply(hits, 1L, function(row) {
    paste0("- ", row[["zh_title"]], ": ", row[["explanation"]], " Suggestion: ", row[["suggested_action"]])
  }))
}

summarize_knowledge_for_query <- function(query, error_message = "") {
  term_hits <- lookup_rstudio_term(query, max_results = 3L)
  command_hits <- search_rstudio_commands(query, max_results = 3L)
  error_hits <- if (nzchar(error_message)) {
    explain_r_error(error_message, max_results = 3L)
  } else {
    explain_r_error(query, max_results = 3L)
  }

  sections <- c(
    if (nrow(term_hits)) c("Term matches:", format_term_hits(term_hits)) else character(),
    if (nrow(command_hits)) c("Command matches:", format_command_hits(command_hits)) else character(),
    if (nrow(error_hits)) c("Error matches:", format_error_hits(error_hits)) else character()
  )

  compact_lines(sections)
}
