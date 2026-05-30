rstudio_snippet_source_path <- function(language = "r") {
  if (!identical(tolower(language), "r")) {
    stop("only R snippets are bundled currently", call. = FALSE)
  }
  path <- system.file("snippets", "r.snippets", package = "rstudiozhai")
  if (!nzchar(path)) {
    local_path <- file.path("inst", "snippets", "r.snippets")
    if (file.exists(local_path)) {
      return(normalizePath(local_path, winslash = "/", mustWork = TRUE))
    }
    stop("bundled snippets file not found", call. = FALSE)
  }
  path
}

rstudio_user_snippet_path <- function(language = "r",
                                      appdata = Sys.getenv("APPDATA", unset = "")) {
  language <- tolower(language)
  if (!language %in% c("r", "c_cpp")) {
    stop("language must be r or c_cpp", call. = FALSE)
  }
  file <- paste0(language, ".snippets")

  if (.Platform$OS.type == "windows" && nzchar(appdata)) {
    return(normalizePath(file.path(appdata, "RStudio", "snippets", file), winslash = "/", mustWork = FALSE))
  }

  normalizePath(file.path("~", ".config", "rstudio", "snippets", file), winslash = "/", mustWork = FALSE)
}

read_bundled_rstudio_snippets <- function(language = "r") {
  paste(readLines(rstudio_snippet_source_path(language), warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

install_rstudio_snippets <- function(language = "r",
                                     target = rstudio_user_snippet_path(language),
                                     overwrite = FALSE,
                                     backup = TRUE) {
  source <- rstudio_snippet_source_path(language)
  target <- normalizePath(target, winslash = "/", mustWork = FALSE)
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(dirname(target))) {
    stop("snippet target directory could not be created", call. = FALSE)
  }

  backup_path <- ""
  if (file.exists(target) && !isTRUE(overwrite)) {
    stop("target snippet file already exists; set overwrite = TRUE to replace it", call. = FALSE)
  }
  if (file.exists(target) && isTRUE(backup)) {
    backup_path <- paste0(target, ".", format(Sys.time(), "%Y%m%d%H%M%S"), ".bak")
    file.copy(target, backup_path, overwrite = FALSE)
  }

  ok <- file.copy(source, target, overwrite = TRUE)
  list(
    ok = isTRUE(ok),
    target = target,
    backup = backup_path
  )
}
