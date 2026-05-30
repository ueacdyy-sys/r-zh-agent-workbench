rstudio_user_rprofile_path <- function(home = path.expand("~")) {
  normalizePath(file.path(home, ".Rprofile"), winslash = "/", mustWork = FALSE)
}

rstudio_startup_banner_markers <- function() {
  list(
    begin = "# >>> rstudiozhai startup banner >>>",
    end = "# <<< rstudiozhai startup banner <<<"
  )
}

rstudio_startup_banner_block <- function() {
  markers <- rstudio_startup_banner_markers()
  c(
    markers$begin,
    "try({",
    "  if (interactive() && nzchar(Sys.getenv(\"RSTUDIO\", unset = \"\")) &&",
    "      requireNamespace(\"rstudiozhai\", quietly = TRUE)) {",
    "    packageStartupMessage(",
    "      \"\\nRStudio \\u4e2d\\u6587 AI \\u5de5\\u4f5c\\u53f0\\u5df2\\u5b89\\u88c5\\n\",",
    "      \"\\u6253\\u5f00\\u65b9\\u5f0f\\uff1aAddins > RStudio \\u4e2d\\u6587 AI \\u5de5\\u4f5c\\u53f0\\n\",",
    "      \"\\u547d\\u4ee4\\u65b9\\u5f0f\\uff1arstudiozhai::run_workbench()\\n\"",
    "    )",
    "  }",
    "}, silent = TRUE)",
    markers$end
  )
}

replace_marked_block <- function(lines, block, markers) {
  begin <- which(lines == markers$begin)
  end <- which(lines == markers$end)

  if (length(begin) && length(end) && begin[[1L]] < end[[length(end)]]) {
    before <- if (begin[[1L]] > 1L) lines[seq_len(begin[[1L]] - 1L)] else character()
    after_index <- end[[length(end)]] + 1L
    after <- if (after_index <= length(lines)) lines[after_index:length(lines)] else character()
    return(c(before, block, after))
  }

  c(lines, if (length(lines)) "" else character(), block)
}

backup_text_file <- function(path) {
  if (!file.exists(path)) {
    return("")
  }
  backup <- paste0(path, ".", format(Sys.time(), "%Y%m%d%H%M%S"), ".bak")
  ok <- file.copy(path, backup, overwrite = FALSE)
  if (!isTRUE(ok)) {
    stop("failed to create backup file", call. = FALSE)
  }
  backup
}

install_rstudio_startup_banner <- function(path = rstudio_user_rprofile_path(),
                                           backup = TRUE) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(dirname(path))) {
    stop("Rprofile target directory could not be created", call. = FALSE)
  }

  old <- if (file.exists(path)) {
    readLines(path, warn = FALSE, encoding = "UTF-8")
  } else {
    character()
  }
  markers <- rstudio_startup_banner_markers()
  block <- rstudio_startup_banner_block()
  new <- replace_marked_block(old, block, markers)

  changed <- !identical(paste(old, collapse = "\n"), paste(new, collapse = "\n"))
  backup_path <- ""
  if (changed && isTRUE(backup) && file.exists(path)) {
    backup_path <- backup_text_file(path)
  }

  writeLines(new, con = path, useBytes = TRUE)
  list(
    ok = TRUE,
    path = path,
    backup = backup_path,
    changed = changed
  )
}

remove_rstudio_startup_banner <- function(path = rstudio_user_rprofile_path(),
                                          backup = TRUE) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  if (!file.exists(path)) {
    return(list(ok = TRUE, path = path, backup = "", changed = FALSE))
  }

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  markers <- rstudio_startup_banner_markers()
  begin <- which(lines == markers$begin)
  end <- which(lines == markers$end)
  if (!length(begin) || !length(end) || begin[[1L]] >= end[[length(end)]]) {
    return(list(ok = TRUE, path = path, backup = "", changed = FALSE))
  }

  keep <- rep(TRUE, length(lines))
  keep[begin[[1L]]:end[[length(end)]]] <- FALSE
  new <- lines[keep]
  if (length(new) && !nzchar(new[[length(new)]])) {
    new <- new[-length(new)]
  }

  backup_path <- if (isTRUE(backup)) backup_text_file(path) else ""
  writeLines(new, con = path, useBytes = TRUE)
  list(
    ok = TRUE,
    path = path,
    backup = backup_path,
    changed = TRUE
  )
}

install_rstudio_visible_entry <- function(rprofile = rstudio_user_rprofile_path(),
                                          install_snippets = TRUE,
                                          overwrite_snippets = FALSE) {
  banner <- install_rstudio_startup_banner(path = rprofile, backup = TRUE)
  snippets <- NULL
  if (isTRUE(install_snippets)) {
    snippets <- tryCatch(
      install_rstudio_snippets(overwrite = overwrite_snippets, backup = TRUE),
      error = function(e) list(ok = FALSE, error = conditionMessage(e))
    )
  }

  list(
    ok = isTRUE(banner$ok) && (is.null(snippets) || isTRUE(snippets$ok) || !isTRUE(overwrite_snippets)),
    startup_banner = banner,
    snippets = snippets,
    addin = collect_rstudio_extension_status()$addin
  )
}

