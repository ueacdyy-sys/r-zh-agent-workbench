is_rstudio_job_available <- function() {
  requireNamespace("rstudioapi", quietly = TRUE) &&
    isTRUE(rstudioapi::isAvailable()) &&
    exists("jobRunScript", where = asNamespace("rstudioapi"), inherits = FALSE)
}

r_string <- function(value) {
  paste0('"', gsub("\\", "\\\\", gsub('"', '\\"', value, fixed = TRUE), fixed = TRUE), '"')
}

create_quarto_render_job_script <- function(report_path,
                                            script_path = tempfile("rstudiozhai-render-", fileext = ".R")) {
  if (!file.exists(report_path)) {
    stop("report_path does not exist", call. = FALSE)
  }

  report_path <- normalizePath(report_path, winslash = "/", mustWork = TRUE)
  script_dir <- dirname(script_path)
  if (!dir.exists(script_dir)) {
    dir.create(script_dir, recursive = TRUE, showWarnings = FALSE)
  }

  lines <- c(
    "library(rstudiozhai)",
    paste0("result <- render_quarto_report(", r_string(report_path), ")"),
    "cat(result$render_output, sep = \"\\n\")",
    "if (!isTRUE(result$ok)) quit(status = 1L)"
  )
  writeLines(lines, script_path, useBytes = TRUE)
  normalizePath(script_path, winslash = "/", mustWork = TRUE)
}

run_quarto_render_job <- function(report_path,
                                  name = "Render Quarto report",
                                  working_dir = dirname(report_path),
                                  script_path = NULL,
                                  runner = NULL) {
  script <- create_quarto_render_job_script(
    report_path,
    script_path = if (is.null(script_path)) tempfile("rstudiozhai-render-", fileext = ".R") else script_path
  )
  working_dir <- normalizePath(working_dir, winslash = "/", mustWork = FALSE)

  if (is.function(runner)) {
    value <- runner(script = script, name = name, working_dir = working_dir)
    return(list(
      ok = TRUE,
      mode = "custom_runner",
      script = script,
      value = value,
      output = ""
    ))
  }

  if (is_rstudio_job_available()) {
    job <- rstudioapi::jobRunScript(
      path = script,
      name = name,
      workingDir = working_dir,
      importEnv = FALSE
    )
    return(list(
      ok = TRUE,
      mode = "rstudio_job",
      script = script,
      value = job,
      output = ""
    ))
  }

  output <- system2(
    file.path(R.home("bin"), "Rscript.exe"),
    script,
    stdout = TRUE,
    stderr = TRUE
  )
  status <- attr(output, "status")
  if (is.null(status)) {
    status <- 0L
  }

  list(
    ok = identical(as.integer(status), 0L),
    mode = "rscript",
    script = script,
    value = NULL,
    output = paste(output, collapse = "\n")
  )
}
