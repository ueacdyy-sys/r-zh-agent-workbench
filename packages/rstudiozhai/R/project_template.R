write_file <- function(path, lines) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  writeLines(lines, path, useBytes = TRUE)
}

create_zh_ai_project <- function(path,
                                 project_name = basename(normalizePath(path, winslash = "/", mustWork = FALSE)),
                                 include_quarto = TRUE,
                                 include_renv_note = TRUE,
                                 ...) {
  if (!is.character(path) || length(path) != 1L || !nzchar(trimws(path))) {
    stop("path must be a non-empty string", call. = FALSE)
  }

  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(path)) {
    stop("project path could not be created", call. = FALSE)
  }

  dirs <- c("R", "data", "reports", "scripts")
  invisible(vapply(file.path(path, dirs), dir.create, logical(1), recursive = TRUE, showWarnings = FALSE))

  write_file(file.path(path, "README.md"), c(
    paste0("# ", project_name),
    "",
    "This project was created by rstudiozhai.",
    "",
    "## Suggested workflow",
    "",
    "1. Put raw data in `data/`.",
    "2. Write reusable R functions in `R/`.",
    "3. Use `reports/analysis.qmd` for reproducible reporting.",
    "4. Use the RStudio Chinese AI Workbench Addin for diagnostics and local guidance.",
    "",
    "## Safety",
    "",
    "- Review generated code before running it.",
    "- Do not store API keys in this project."
  ))

  write_file(file.path(path, "R", "analysis.R"), c(
    "# Reusable analysis functions live here.",
    "summarise_numeric <- function(x) {",
    "  stopifnot(is.numeric(x))",
    "  list(",
    "    mean = mean(x, na.rm = TRUE),",
    "    median = median(x, na.rm = TRUE),",
    "    missing = sum(is.na(x))",
    "  )",
    "}"
  ))

  write_file(file.path(path, "scripts", "setup.R"), c(
    "# Project setup helper.",
    "required <- c(\"ggplot2\", \"dplyr\", \"readr\")",
    "missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]",
    "if (length(missing)) {",
    "  message(\"Install missing packages: \", paste(missing, collapse = \", \"))",
    "} else {",
    "  message(\"Project packages are available.\")",
    "}"
  ))

  if (isTRUE(include_quarto)) {
    write_file(file.path(path, "reports", "analysis.qmd"), c(
      "---",
      paste0("title: \"", project_name, " Analysis\""),
      "format: html",
      "---",
      "",
      "## Goal",
      "",
      "Describe the analysis question here.",
      "",
      "## Setup",
      "",
      "```{r}",
      "source(\"../R/analysis.R\")",
      "summarise_numeric(c(1, 2, 3, NA))",
      "```"
    ))
  }

  if (isTRUE(include_renv_note)) {
    write_file(file.path(path, "renv-notes.md"), c(
      "# renv notes",
      "",
      "Run `renv::init()` when you are ready to lock project dependencies."
    ))
  }

  write_file(file.path(path, ".gitignore"), c(
    ".Rhistory",
    ".RData",
    ".Rproj.user",
    "data/*.csv",
    "data/*.xlsx",
    "!data/.gitkeep"
  ))
  write_file(file.path(path, "data", ".gitkeep"), "")

  invisible(list(
    ok = TRUE,
    path = normalizePath(path, winslash = "/", mustWork = TRUE),
    files = c(
      "README.md",
      "R/analysis.R",
      "scripts/setup.R",
      if (isTRUE(include_quarto)) "reports/analysis.qmd" else character(),
      if (isTRUE(include_renv_note)) "renv-notes.md" else character(),
      ".gitignore",
      "data/.gitkeep"
    )
  ))
}
