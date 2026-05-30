safe_system_file <- function(...) {
  path <- system.file(..., package = "rstudiozhai")
  if (nzchar(path)) {
    return(normalizePath(path, winslash = "/", mustWork = FALSE))
  }

  local_path <- file.path("inst", ...)
  if (file.exists(local_path)) {
    return(normalizePath(local_path, winslash = "/", mustWork = FALSE))
  }
  ""
}

read_first_dcf_record <- function(path) {
  if (!nzchar(path) || !file.exists(path)) {
    return(list())
  }
  dcf <- read.dcf(path, all = TRUE)
  if (!NROW(dcf)) {
    return(list())
  }
  as.list(dcf[1L, , drop = TRUE])
}

is_exported_function <- function(name) {
  is.character(name) &&
    length(name) == 1L &&
    nzchar(name) &&
    exists(name, envir = asNamespace("rstudiozhai"), inherits = FALSE) &&
    is.function(get(name, envir = asNamespace("rstudiozhai"), inherits = FALSE))
}

installed_package_path <- function() {
  path <- system.file(package = "rstudiozhai")
  if (!nzchar(path) && dir.exists(".")) {
    path <- normalizePath(".", winslash = "/", mustWork = FALSE)
  }
  normalizePath(path, winslash = "/", mustWork = FALSE)
}

extension_file_status <- function(path) {
  list(
    ok = nzchar(path) && file.exists(path),
    path = path
  )
}

startup_banner_status <- function(path = rstudio_user_rprofile_path()) {
  path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  markers <- rstudio_startup_banner_markers()
  lines <- if (file.exists(path)) {
    readLines(path, warn = FALSE, encoding = "UTF-8")
  } else {
    character()
  }
  list(
    ok = markers$begin %in% lines && markers$end %in% lines,
    path = path
  )
}

collect_rstudio_extension_status <- function() {
  package_path <- installed_package_path()
  package_installed <- nzchar(package_path) && dir.exists(package_path)
  version <- tryCatch(as.character(utils::packageVersion("rstudiozhai")), error = function(e) "")

  rstudio <- detect_rstudio_info()

  addin_path <- safe_system_file("rstudio", "addins.dcf")
  addin_meta <- read_first_dcf_record(addin_path)
  addin_binding <- if (!is.null(addin_meta$Binding)) addin_meta$Binding else ""
  addin <- c(
    extension_file_status(addin_path),
    list(
      name = if (!is.null(addin_meta$Name)) addin_meta$Name else "",
      binding = addin_binding,
      binding_exported = is_exported_function(addin_binding),
      interactive = if (!is.null(addin_meta$Interactive)) addin_meta$Interactive else ""
    )
  )
  addin$ok <- isTRUE(addin$ok) && isTRUE(addin$binding_exported)

  template_path <- safe_system_file("rstudio", "templates", "project", "rstudiozhai-analysis.dcf")
  template_meta <- read_first_dcf_record(template_path)
  template_binding <- if (!is.null(template_meta$Binding)) template_meta$Binding else ""
  project_template <- c(
    extension_file_status(template_path),
    list(
      title = if (!is.null(template_meta$Title)) template_meta$Title else "",
      binding = template_binding,
      binding_exported = is_exported_function(template_binding)
    )
  )
  project_template$ok <- isTRUE(project_template$ok) && isTRUE(project_template$binding_exported)

  connections_path <- safe_system_file("rstudio", "connections.dcf")
  connections <- extension_file_status(connections_path)

  snippets_path <- safe_system_file("snippets", "r.snippets")
  snippets <- extension_file_status(snippets_path)
  user_snippets <- extension_file_status(rstudio_user_snippet_path())
  startup_banner <- startup_banner_status()

  connection_templates <- tryCatch(list_connection_templates(), error = function(e) data.frame())
  snippet_paths <- if (NROW(connection_templates) && "file" %in% names(connection_templates)) {
    vapply(connection_templates$id, connection_snippet_path, character(1))
  } else {
    character()
  }
  connection_snippets <- lapply(seq_along(snippet_paths), function(index) {
    list(
      id = connection_templates$id[[index]],
      path = snippet_paths[[index]],
      ok = file.exists(snippet_paths[[index]])
    )
  })

  suggestions <- list()
  if (!isTRUE(rstudio$ok)) {
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "CHECK_RSTUDIO",
      message = "\u672a\u68c0\u6d4b\u5230 RStudio Desktop \u4e3b\u7a0b\u5e8f\uff0c\u8bf7\u786e\u8ba4 RStudio \u5df2\u5b89\u88c5\u3002"
    )
  }
  if (!isTRUE(addin$ok)) {
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "CHECK_ADDIN_DCF",
      message = "\u672a\u901a\u8fc7 Addin DCF \u6216 Binding \u6821\u9a8c\uff0c\u8bf7\u91cd\u65b0\u5b89\u88c5\u5305\u5e76\u91cd\u542f RStudio\u3002"
    )
  }
  if (!isTRUE(project_template$ok)) {
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "CHECK_PROJECT_TEMPLATE",
      message = "\u9879\u76ee\u6a21\u677f DCF \u6216 Binding \u6821\u9a8c\u5931\u8d25\u3002"
    )
  }
  if (!isTRUE(connections$ok)) {
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "CHECK_CONNECTIONS",
      message = "\u672a\u627e\u5230 RStudio Connections DCF\u3002"
    )
  }
  if (!isTRUE(snippets$ok)) {
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "CHECK_SNIPPETS",
      message = "\u672a\u627e\u5230\u5305\u5185 R snippets\u3002"
    )
  }
  if (!isTRUE(startup_banner$ok)) {
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "INSTALL_VISIBLE_ENTRY",
      message = "\u672a\u68c0\u6d4b\u5230 RStudio \u542f\u52a8\u4e2d\u6587\u63d0\u793a\uff0c\u8bf7\u8fd0\u884c install_rstudio_visible_entry()\u3002"
    )
  }

  snippets_ok <- length(connection_snippets) >= 3L &&
    all(vapply(connection_snippets, function(item) isTRUE(item$ok), logical(1)))

  overall_ok <- isTRUE(package_installed) &&
    isTRUE(rstudio$ok) &&
    isTRUE(addin$ok) &&
    isTRUE(project_template$ok) &&
    isTRUE(connections$ok) &&
    isTRUE(snippets$ok) &&
    isTRUE(snippets_ok)

  list(
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    overall_ok = overall_ok,
    package = list(
      installed = package_installed,
      path = package_path,
      version = version
    ),
    rstudio = rstudio,
    addin = addin,
    project_template = project_template,
    connections = connections,
    snippets = snippets,
    user_snippets = user_snippets,
    startup_banner = startup_banner,
    connection_snippets = connection_snippets,
    suggestions = suggestions
  )
}

format_rstudio_extension_status <- function(status) {
  if (!is.list(status)) {
    stop("status must be produced by collect_rstudio_extension_status()", call. = FALSE)
  }

  bool <- function(value) if (isTRUE(value)) "OK" else "MISSING"
  suggestion_lines <- if (length(status$suggestions)) {
    vapply(status$suggestions, function(item) {
      paste0("- [", item$code, "] ", item$message)
    }, character(1))
  } else {
    "- \u6682\u65e0\u5efa\u8bae\u3002"
  }

  connection_lines <- if (length(status$connection_snippets)) {
    vapply(status$connection_snippets, function(item) {
      paste0("- ", item$id, ": ", bool(item$ok), " - ", item$path)
    }, character(1))
  } else {
    "- \u672a\u627e\u5230 connection snippet\u3002"
  }

  paste(
    "# RStudio \u6269\u5c55\u5b89\u88c5\u9a8c\u6536\u62a5\u544a",
    "",
    paste0("\u751f\u6210\u65f6\u95f4\uff1a", status$generated_at),
    paste0("\u603b\u4f53\u72b6\u6001\uff1a", bool(status$overall_ok)),
    "",
    "## Package",
    paste0("- \u72b6\u6001\uff1a", bool(status$package$installed)),
    paste0("- \u7248\u672c\uff1a", status$package$version),
    paste0("- \u8def\u5f84\uff1a", status$package$path),
    "",
    "## RStudio",
    paste0("- \u72b6\u6001\uff1a", bool(status$rstudio$ok)),
    paste0("- \u7248\u672c\uff1a", status$rstudio$version),
    paste0("- \u8def\u5f84\uff1a", status$rstudio$path),
    "",
    "## Addin",
    paste0("- \u72b6\u6001\uff1a", bool(status$addin$ok)),
    paste0("- Binding\uff1a", status$addin$binding),
    paste0("- Binding exported\uff1a", isTRUE(status$addin$binding_exported)),
    paste0("- DCF\uff1a", status$addin$path),
    "",
    "## Project Template",
    paste0("- \u72b6\u6001\uff1a", bool(status$project_template$ok)),
    paste0("- Binding\uff1a", status$project_template$binding),
    paste0("- Binding exported\uff1a", isTRUE(status$project_template$binding_exported)),
    paste0("- DCF\uff1a", status$project_template$path),
    "",
    "## Connections",
    paste0("- \u72b6\u6001\uff1a", bool(status$connections$ok)),
    paste0("- DCF\uff1a", status$connections$path),
    paste(connection_lines, collapse = "\n"),
    "",
    "## Snippets",
    paste0("- \u5305\u5185 snippets \u72b6\u6001\uff1a", bool(status$snippets$ok)),
    paste0("- \u5305\u5185\u8def\u5f84\uff1a", status$snippets$path),
    paste0("- \u7528\u6237 snippets \u72b6\u6001\uff1a", bool(status$user_snippets$ok)),
    paste0("- \u7528\u6237\u8def\u5f84\uff1a", status$user_snippets$path),
    "",
    "## Visible Startup Entry",
    paste0("- \u72b6\u6001\uff1a", bool(status$startup_banner$ok)),
    paste0("- .Rprofile\uff1a", status$startup_banner$path),
    "",
    "## \u4eba\u5de5\u9a8c\u6536\u5efa\u8bae",
    "- \u91cd\u542f RStudio \u540e\uff0c\u5728 Addins \u83dc\u5355\u67e5\u627e\u201cRStudio \u4e2d\u6587 AI \u5de5\u4f5c\u53f0\u201d\u3002",
    "- \u91cd\u542f RStudio \u540e\uff0cConsole \u5e94\u51fa\u73b0\u201cRStudio \u4e2d\u6587 AI \u5de5\u4f5c\u53f0\u5df2\u5b89\u88c5\u201d\u63d0\u793a\u3002",
    "- \u5728 New Project \u4e2d\u67e5\u627e RStudio Chinese AI Analysis Project\u3002",
    "- \u5728 Connections \u9762\u677f\u68c0\u67e5\u8fde\u63a5\u7247\u6bb5\u662f\u5426\u53ef\u89c1\u3002",
    "",
    "## \u5efa\u8bae",
    paste(suggestion_lines, collapse = "\n"),
    sep = "\n"
  )
}
