default_required_packages <- function() {
  c(
    "rstudioapi",
    "shiny",
    "miniUI",
    "testthat",
    "devtools",
    "usethis",
    "roxygen2",
    "knitr",
    "rmarkdown",
    "renv",
    "plumber",
    "rsconnect",
    "reticulate"
  )
}

detect_r_info <- function() {
  list(
    ok = TRUE,
    version = R.version.string,
    home = R.home(),
    platform = R.version$platform
  )
}

detect_rstudio_info <- function() {
  candidates <- c(
    Sys.getenv("RSTUDIO_DESKTOP_EXE", unset = ""),
    "C:/Program Files/RStudio/rstudio.exe",
    "C:/Program Files (x86)/RStudio/rstudio.exe"
  )
  path <- candidates[nzchar(candidates) & file.exists(candidates)]
  path <- if (length(path)) normalizePath(path[[1]], winslash = "/", mustWork = FALSE) else ""

  version <- ""
  if (nzchar(path)) {
    out <- tryCatch(
      system2(path, "--version", stdout = TRUE, stderr = TRUE),
      error = function(e) character()
    )
    version <- trimws(paste(out, collapse = "\n"))
  }

  list(
    ok = nzchar(path),
    path = path,
    version = version
  )
}

detect_quarto_info <- function() {
  candidates <- c(
    Sys.getenv("QUARTO_EXE", unset = ""),
    "C:/Program Files/RStudio/resources/app/bin/quarto/bin/quarto.exe",
    Sys.which("quarto")
  )
  path <- candidates[nzchar(candidates) & file.exists(candidates)]
  path <- if (length(path)) normalizePath(path[[1]], winslash = "/", mustWork = FALSE) else ""

  version <- ""
  if (nzchar(path)) {
    out <- tryCatch(
      system2(path, "--version", stdout = TRUE, stderr = TRUE),
      error = function(e) character()
    )
    version <- trimws(paste(out, collapse = "\n"))
  }

  list(
    ok = nzchar(path) && nzchar(version),
    path = path,
    version = version
  )
}

detect_package_status <- function(packages = default_required_packages()) {
  installed <- rownames(utils::installed.packages())
  lapply(packages, function(pkg) {
    list(
      name = pkg,
      installed = pkg %in% installed
    )
  })
}

suggest_environment_actions <- function(report) {
  suggestions <- list()

  missing <- vapply(report$packages, function(pkg) {
    !isTRUE(pkg$installed)
  }, logical(1))

  if (any(missing)) {
    names <- vapply(report$packages[missing], function(pkg) pkg$name, character(1))
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "INSTALL_R_PACKAGES",
      message = paste0("\u5efa\u8bae\u5b89\u88c5 RStudio \u63d2\u4ef6\u5f00\u53d1\u5305\uff1a", paste(names, collapse = ", "))
    )
  }

  if (!isTRUE(report$quarto$ok)) {
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "CHECK_QUARTO",
      message = "\u672a\u68c0\u6d4b\u5230\u53ef\u7528 Quarto CLI\uff0c\u62a5\u544a\u751f\u6210\u80fd\u529b\u4f1a\u53d7\u9650\u3002"
    )
  }

  if (!isTRUE(report$rstudio$ok)) {
    suggestions[[length(suggestions) + 1L]] <- list(
      code = "CHECK_RSTUDIO",
      message = "\u672a\u68c0\u6d4b\u5230 RStudio Desktop \u4e3b\u7a0b\u5e8f\uff0cAddin \u53ea\u80fd\u5728\u666e\u901a R \u73af\u5883\u4e2d\u505a\u6838\u5fc3\u6d4b\u8bd5\u3002"
    )
  }

  suggestions
}

collect_environment_report <- function(packages = default_required_packages()) {
  report <- list(
    generated_at = format(Sys.time(), "%Y-%m-%d %H:%M:%S %z"),
    r = detect_r_info(),
    rstudio = detect_rstudio_info(),
    quarto = detect_quarto_info(),
    packages = detect_package_status(packages)
  )
  report$suggestions <- suggest_environment_actions(report)
  report
}

format_environment_report <- function(report) {
  package_lines <- vapply(report$packages, function(pkg) {
    mark <- if (isTRUE(pkg$installed)) "OK" else "MISSING"
    paste0("- ", pkg$name, ": ", mark)
  }, character(1))

  suggestion_lines <- if (length(report$suggestions)) {
    vapply(report$suggestions, function(item) {
      paste0("- [", item$code, "] ", item$message)
    }, character(1))
  } else {
    "- \u6682\u65e0\u5efa\u8bae\u3002"
  }

  paste(
    "# RStudio \u4e2d\u6587 AI \u5de5\u4f5c\u53f0\u73af\u5883\u62a5\u544a",
    "",
    paste0("\u751f\u6210\u65f6\u95f4\uff1a", report$generated_at),
    "",
    "## R",
    paste0("- \u72b6\u6001\uff1a", if (isTRUE(report$r$ok)) "OK" else "MISSING"),
    paste0("- \u7248\u672c\uff1a", report$r$version),
    paste0("- \u8def\u5f84\uff1a", report$r$home),
    "",
    "## RStudio",
    paste0("- \u72b6\u6001\uff1a", if (isTRUE(report$rstudio$ok)) "OK" else "MISSING"),
    paste0("- \u7248\u672c\uff1a", report$rstudio$version),
    paste0("- \u8def\u5f84\uff1a", report$rstudio$path),
    "",
    "## Quarto",
    paste0("- \u72b6\u6001\uff1a", if (isTRUE(report$quarto$ok)) "OK" else "MISSING"),
    paste0("- \u7248\u672c\uff1a", report$quarto$version),
    paste0("- \u8def\u5f84\uff1a", report$quarto$path),
    "",
    "## R \u5305",
    paste(package_lines, collapse = "\n"),
    "",
    "## \u5efa\u8bae",
    paste(suggestion_lines, collapse = "\n"),
    sep = "\n"
  )
}
