make_project_scan_fixture <- function() {
  root <- tempfile("rstudiozhai-scan-")
  dir.create(root)
  dir.create(file.path(root, "R"), recursive = TRUE)
  dir.create(file.path(root, "reports"), recursive = TRUE)
  dir.create(file.path(root, ".git"), recursive = TRUE)
  dir.create(file.path(root, ".Rproj.user"), recursive = TRUE)
  dir.create(file.path(root, "renv", "library"), recursive = TRUE)
  dir.create(file.path(root, "node_modules"), recursive = TRUE)

  writeLines("Package: demo\nVersion: 0.0.1", file.path(root, "DESCRIPTION"))
  writeLines("Version: 1.0", file.path(root, "demo.Rproj"))
  writeLines("important <- 42", file.path(root, "R", "analysis.R"))
  writeLines("---\ntitle: Report\n---\n\n```{r}\nsummary(cars)\n```", file.path(root, "reports", "report.qmd"))
  writeLines("do not scan", file.path(root, ".git", "ignored.R"))
  writeLines("do not scan", file.path(root, ".Rproj.user", "ignored"))
  writeLines("do not scan", file.path(root, "renv", "library", "ignored.R"))
  writeLines("do not scan", file.path(root, "node_modules", "ignored.js"))
  writeLines(paste(rep("large-text", 80), collapse = "\n"), file.path(root, "large.txt"))

  root
}

test_that("project scan summarizes project structure without heavy directories", {
  root <- make_project_scan_fixture()

  scan <- collect_project_scan(root, max_files = 20L, max_bytes = 80L, include_text = TRUE)

  expect_equal(scan$root, normalizePath(root, winslash = "/", mustWork = TRUE))
  expect_s3_class(scan$files, "data.frame")
  expect_true(all(c("path", "extension", "size", "category", "read_status", "text_preview") %in% names(scan$files)))
  expect_true(all(c("DESCRIPTION", "demo.Rproj", "R/analysis.R", "reports/report.qmd", "large.txt") %in% scan$files$path))
  expect_false(any(grepl("^\\.git|^\\.Rproj.user|^renv/library|^node_modules", scan$files$path)))
  expect_true(scan$summary$excluded_dirs >= 4L)
  expect_true(scan$summary$files_returned <= 20L)

  analysis <- scan$files[match("R/analysis.R", scan$files$path), ]
  expect_true(analysis$included_text)
  expect_equal(analysis$read_status, "read")
  expect_match(analysis$text_preview, "important <- 42", fixed = TRUE)

  large <- scan$files[match("large.txt", scan$files$path), ]
  expect_false(large$included_text)
  expect_equal(large$read_status, "skipped_large")

  expect_true(any(scan$markers$marker == "r_package" & scan$markers$present))
  expect_true(any(scan$markers$marker == "rstudio_project" & scan$markers$present))
  expect_match(scan$markdown, "项目扫描")
})

test_that("project scan defaults avoid reading file contents", {
  root <- make_project_scan_fixture()

  scan <- collect_project_scan(root, max_files = 20L)

  expect_true("R/analysis.R" %in% scan$files$path)
  expect_false(any(scan$files$included_text))
  expect_false(any(grepl("important <- 42", scan$files$text_preview, fixed = TRUE)))
})

test_that("project scan command and audit path do not record file contents", {
  root <- make_project_scan_fixture()
  audit_path <- tempfile("rstudiozhai-audit-", fileext = ".jsonl")
  catalog <- available_workbench_commands()

  expect_true("project-scan" %in% catalog$command)
  expect_false(catalog$mutates_files[match("project-scan", catalog$command)])

  result <- run_workbench_command(
    "project-scan",
    list(path = root, max_files = 20L, max_bytes = 80L, include_text = TRUE, audit_path = audit_path)
  )

  expect_true(result$ok)
  expect_true("scan" %in% names(result$data))
  expect_true("R/analysis.R" %in% result$data$scan$files$path)

  raw <- paste(readLines(audit_path, warn = FALSE), collapse = "\n")
  expect_match(raw, "project-scan", fixed = TRUE)
  expect_false(grepl("important <- 42", raw, fixed = TRUE))
  expect_false(grepl("summary(cars)", raw, fixed = TRUE))
})

test_that("project scan is exposed through MCP", {
  skip_if_not_installed("jsonlite")

  tools <- mcp_tool_definitions()
  names <- vapply(tools, function(tool) tool$name, character(1))
  expect_true("rstudiozhai_project_scan" %in% names)

  root <- make_project_scan_fixture()
  response <- mcp_handle_request(list(
    jsonrpc = "2.0",
    id = "scan",
    method = "tools/call",
    params = list(
      name = "rstudiozhai_project_scan",
      arguments = list(path = root, max_files = 20L, response_format = "markdown")
    )
  ))

  expect_equal(response$id, "scan")
  expect_false(response$result$isError)
  expect_match(response$result$content[[1L]]$text, "项目扫描")
})
