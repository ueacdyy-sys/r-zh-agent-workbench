default_project_scan_exclude_dirs <- function() {
  c(
    ".git",
    ".Rproj.user",
    "renv/library",
    "renv/staging",
    "packrat/lib",
    "node_modules",
    ".quarto",
    "_site",
    "rsconnect",
    "rstudiozhai.Rcheck"
  )
}

project_scan_normalize_slashes <- function(path) {
  gsub("\\\\", "/", path)
}

project_scan_relative_path <- function(path, root) {
  path <- project_scan_normalize_slashes(normalizePath(path, winslash = "/", mustWork = FALSE))
  root <- project_scan_normalize_slashes(normalizePath(root, winslash = "/", mustWork = FALSE))
  root_prefix <- paste0(sub("/+$", "", root), "/")
  if (startsWith(path, root_prefix)) {
    return(sub("^/+", "", substring(path, nchar(root_prefix) + 1L)))
  }
  basename(path)
}

project_scan_extension <- function(path) {
  base <- basename(path)
  if (!grepl("[.]", base, fixed = FALSE)) {
    return("[none]")
  }
  ext <- tolower(sub("^.*[.]", "", base))
  if (!nzchar(ext)) {
    return("[none]")
  }
  ext
}

project_scan_is_excluded_dir <- function(relative_dir, exclude_dirs) {
  relative_dir <- sub("^/+", "", sub("/+$", "", project_scan_normalize_slashes(relative_dir)))
  if (!nzchar(relative_dir)) {
    return(FALSE)
  }

  segments <- strsplit(relative_dir, "/", fixed = TRUE)[[1L]]
  any(vapply(exclude_dirs, function(pattern) {
    pattern <- sub("^/+", "", sub("/+$", "", project_scan_normalize_slashes(pattern)))
    if (!nzchar(pattern)) {
      return(FALSE)
    }
    if (!grepl("/", pattern, fixed = TRUE)) {
      return(any(segments == pattern))
    }
    identical(relative_dir, pattern) || startsWith(relative_dir, paste0(pattern, "/"))
  }, logical(1)))
}

project_scan_matches_include <- function(relative_path, include_patterns) {
  if (!length(include_patterns)) {
    return(TRUE)
  }
  any(vapply(include_patterns, function(pattern) {
    grepl(pattern, relative_path, ignore.case = TRUE)
  }, logical(1)))
}

project_scan_collect_paths <- function(root, max_files, include_patterns, exclude_dirs) {
  pending <- root
  files <- character()
  excluded_dirs <- 0L
  directories_scanned <- 0L
  truncated <- FALSE

  while (length(pending) && length(files) < max_files) {
    current <- pending[[1L]]
    pending <- pending[-1L]
    directories_scanned <- directories_scanned + 1L

    entries <- list.files(current, all.files = TRUE, no.. = TRUE, full.names = TRUE)
    if (!length(entries)) {
      next
    }

    info <- file.info(entries)
    entries <- rownames(info)[!is.na(info$isdir)]
    info <- info[entries, , drop = FALSE]
    dirs <- entries[isTRUE(length(entries) > 0L) & info$isdir]
    plain_files <- entries[isTRUE(length(entries) > 0L) & !info$isdir]

    for (dir in dirs) {
      relative_dir <- project_scan_relative_path(dir, root)
      if (project_scan_is_excluded_dir(relative_dir, exclude_dirs)) {
        excluded_dirs <- excluded_dirs + 1L
      } else {
        pending <- c(pending, dir)
      }
    }

    for (file in plain_files) {
      relative_path <- project_scan_relative_path(file, root)
      if (project_scan_matches_include(relative_path, include_patterns)) {
        files <- c(files, file)
      }
      if (length(files) >= max_files) {
        truncated <- TRUE
        break
      }
    }
  }

  if (length(pending)) {
    truncated <- TRUE
  }

  list(
    files = files,
    excluded_dirs = excluded_dirs,
    directories_scanned = directories_scanned,
    truncated = truncated
  )
}

project_scan_text_candidate <- function(path) {
  base <- basename(path)
  lower_base <- tolower(base)
  ext <- project_scan_extension(path)

  lower_base %in% c(
    "description",
    "namespace",
    "license",
    "news",
    "readme",
    "readme.md",
    ".rprofile",
    ".renviron",
    ".gitignore",
    ".rbuildignore",
    "renv.lock",
    "_quarto.yml"
  ) ||
    ext %in% c(
      "r", "rmd", "qmd", "md", "txt", "csv", "tsv",
      "json", "yaml", "yml", "toml", "dcf", "rproj",
      "sql", "sh", "ps1", "bat", "cmd", "py", "js",
      "ts", "html", "css", "scss", "xml"
    )
}

project_scan_read_preview <- function(path, size, max_bytes, include_text) {
  if (!isTRUE(include_text)) {
    return(list(included_text = FALSE, read_status = "not_requested", text_preview = ""))
  }
  if (is.na(size)) {
    return(list(included_text = FALSE, read_status = "unknown_size", text_preview = ""))
  }
  if (size > max_bytes) {
    return(list(included_text = FALSE, read_status = "skipped_large", text_preview = ""))
  }
  if (!project_scan_text_candidate(path)) {
    return(list(included_text = FALSE, read_status = "skipped_non_text", text_preview = ""))
  }

  raw <- tryCatch(readBin(path, what = "raw", n = max(1L, as.integer(size))), error = function(e) raw())
  if (length(raw) && any(raw == as.raw(0))) {
    return(list(included_text = FALSE, read_status = "skipped_binary", text_preview = ""))
  }

  text <- tryCatch(
    readChar(path, nchars = max(0L, as.integer(size)), useBytes = TRUE),
    error = function(e) ""
  )
  text <- iconv(text, from = "", to = "UTF-8", sub = "byte")
  if (is.na(text)) {
    text <- ""
  }
  text <- gsub("\r\n?", "\n", text)

  list(included_text = TRUE, read_status = "read", text_preview = text)
}

project_scan_category <- function(relative_path) {
  lower <- tolower(relative_path)
  base <- basename(lower)
  ext <- project_scan_extension(lower)

  if (base == "description" || base == "namespace") {
    return("r_package")
  }
  if (ext == "rproj") {
    return("rstudio_project")
  }
  if (ext %in% c("qmd", "rmd") || base == "_quarto.yml") {
    return("quarto")
  }
  if (base %in% c("app.r", "ui.r", "server.r")) {
    return("shiny")
  }
  if (startsWith(lower, "tests/testthat/")) {
    return("testthat")
  }
  if (ext == "r") {
    return("r_script")
  }
  if (ext %in% c("csv", "tsv", "xlsx", "xls", "parquet", "rds")) {
    return("data")
  }
  if (ext %in% c("json", "yaml", "yml", "toml", "dcf")) {
    return("config")
  }
  "other"
}

project_scan_markers <- function(relative_paths) {
  lower <- tolower(relative_paths)
  base <- basename(lower)
  ext <- vapply(lower, project_scan_extension, character(1))

  marker_rows <- list(
    r_package = relative_paths[base %in% c("description", "namespace")],
    rstudio_project = relative_paths[ext == "rproj"],
    quarto = relative_paths[ext %in% c("qmd", "rmd") | base == "_quarto.yml"],
    shiny = relative_paths[base %in% c("app.r", "ui.r", "server.r")],
    testthat = relative_paths[startsWith(lower, "tests/testthat/")],
    renv = relative_paths[base == "renv.lock" | startsWith(lower, "renv/")],
    rstudio_extension = relative_paths[startsWith(lower, "inst/rstudio/")]
  )

  data.frame(
    marker = names(marker_rows),
    present = vapply(marker_rows, length, integer(1)) > 0L,
    paths = vapply(marker_rows, function(paths) {
      paste(utils::head(paths, 6L), collapse = ", ")
    }, character(1)),
    stringsAsFactors = FALSE
  )
}

project_scan_extension_summary <- function(files) {
  if (!NROW(files)) {
    return(data.frame(extension = character(), count = integer(), total_size = numeric()))
  }
  stats <- stats::aggregate(
    list(count = rep(1L, NROW(files)), total_size = files$size),
    by = list(extension = files$extension),
    FUN = sum,
    na.rm = TRUE
  )
  stats[order(stats$count, decreasing = TRUE), , drop = FALSE]
}

format_project_scan <- function(scan, max_files = 20L) {
  if (!is.list(scan) || is.null(scan$files)) {
    return("# RStudioZH \u9879\u76ee\u626b\u63cf\n\n- \u626b\u63cf\u7ed3\u679c\u4e0d\u53ef\u7528\u3002")
  }

  marker_lines <- if (NROW(scan$markers)) {
    apply(scan$markers, 1L, function(row) {
      paste0(
        "- ", row[["marker"]],
        ": ", if (identical(row[["present"]], "TRUE")) "yes" else "no",
        if (nzchar(row[["paths"]])) paste0(" | ", row[["paths"]]) else ""
      )
    })
  } else {
    "- \u65e0\u5173\u952e\u6807\u8bb0\u3002"
  }

  shown <- utils::head(scan$files, max_files)
  file_lines <- if (NROW(shown)) {
    apply(shown, 1L, function(row) {
      paste0(
        "- ", row[["path"]],
        " | ", row[["category"]],
        " | ", row[["size"]], " bytes",
        if (identical(row[["read_status"]], "read")) paste0(" | text=", row[["text_nchar"]], " chars") else ""
      )
    })
  } else {
    "- \u672a\u53d1\u73b0\u5339\u914d\u6587\u4ef6\u3002"
  }

  paste(
    c(
      "# RStudioZH \u9879\u76ee\u626b\u63cf",
      "",
      paste0("- \u6839\u76ee\u5f55: ", scan$root),
      paste0("- \u8fd4\u56de\u6587\u4ef6\u6570: ", scan$summary$files_returned),
      paste0("- \u626b\u63cf\u76ee\u5f55\u6570: ", scan$summary$directories_scanned),
      paste0("- \u6392\u9664\u76ee\u5f55\u6570: ", scan$summary$excluded_dirs),
      paste0("- \u6587\u4ef6\u5217\u8868\u662f\u5426\u622a\u65ad: ", scan$summary$files_truncated),
      paste0("- \u5c0f\u6587\u672c\u9884\u89c8\u6570: ", scan$summary$text_files),
      paste0("- \u8df3\u8fc7\u5927\u6587\u4ef6\u6570: ", scan$summary$skipped_large),
      "",
      "## \u5173\u952e\u6807\u8bb0",
      marker_lines,
      "",
      "## \u6587\u4ef6\u6982\u89c8",
      file_lines
    ),
    collapse = "\n"
  )
}

collect_project_scan <- function(path = getwd(),
                                 max_files = 200L,
                                 max_bytes = 4096L,
                                 include_patterns = character(),
                                 exclude_dirs = default_project_scan_exclude_dirs(),
                                 include_text = FALSE) {
  if (!is.character(path) || length(path) != 1L || !nzchar(trimws(path))) {
    stop("path must be a non-empty string", call. = FALSE)
  }
  root <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!dir.exists(root)) {
    stop(paste0("Project path is not a directory: ", path), call. = FALSE)
  }
  max_files <- as.integer(max_files[[1L]])
  max_bytes <- as.integer(max_bytes[[1L]])
  if (is.na(max_files) || max_files < 1L) {
    stop("max_files must be a positive integer", call. = FALSE)
  }
  if (is.na(max_bytes) || max_bytes < 0L) {
    stop("max_bytes must be a non-negative integer", call. = FALSE)
  }

  include_patterns <- as.character(include_patterns)
  exclude_dirs <- as.character(exclude_dirs)
  traversal <- project_scan_collect_paths(
    root = root,
    max_files = max_files,
    include_patterns = include_patterns,
    exclude_dirs = exclude_dirs
  )

  paths <- traversal$files
  info <- if (length(paths)) file.info(paths) else data.frame(size = numeric())
  relative_paths <- vapply(paths, project_scan_relative_path, character(1), root = root)
  extensions <- vapply(relative_paths, project_scan_extension, character(1))
  categories <- vapply(relative_paths, project_scan_category, character(1))
  previews <- lapply(seq_along(paths), function(index) {
    project_scan_read_preview(paths[[index]], info$size[[index]], max_bytes, include_text = include_text)
  })

  files <- data.frame(
    path = relative_paths,
    extension = extensions,
    size = as.numeric(info$size),
    category = categories,
    included_text = vapply(previews, function(item) isTRUE(item$included_text), logical(1)),
    read_status = vapply(previews, function(item) item$read_status, character(1)),
    text_nchar = vapply(previews, function(item) nchar(item$text_preview, type = "chars"), integer(1)),
    text_preview = vapply(previews, function(item) item$text_preview, character(1)),
    stringsAsFactors = FALSE
  )

  if (NROW(files)) {
    files <- files[order(files$path), , drop = FALSE]
    rownames(files) <- NULL
  }

  summary <- list(
    files_returned = NROW(files),
    files_truncated = isTRUE(traversal$truncated),
    directories_scanned = traversal$directories_scanned,
    excluded_dirs = traversal$excluded_dirs,
    total_bytes = sum(files$size, na.rm = TRUE),
    text_files = sum(files$included_text),
    skipped_large = sum(files$read_status == "skipped_large"),
    skipped_binary = sum(files$read_status == "skipped_binary"),
    by_extension = project_scan_extension_summary(files)
  )

  scan <- list(
    root = root,
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    limits = list(
      max_files = max_files,
      max_bytes = max_bytes,
      include_text = isTRUE(include_text),
      include_patterns = include_patterns,
      exclude_dirs = exclude_dirs
    ),
    summary = summary,
    markers = project_scan_markers(files$path),
    files = files,
    warnings = if (isTRUE(traversal$truncated)) "File list was truncated by max_files." else character()
  )
  scan$markdown <- format_project_scan(scan)
  scan
}
