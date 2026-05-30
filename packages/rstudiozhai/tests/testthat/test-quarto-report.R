test_that("report slugs are ASCII and stable", {
  expect_equal(sanitize_report_slug("My Report!"), "my-report")
  expect_equal(sanitize_report_slug(""), "rstudiozhai-report")
})

test_that("Quarto report content includes task and result", {
  content <- build_quarto_report_content(
    title = "Workbench Report",
    task = "Explain this code",
    ai_result = "Use mean(x) to calculate an average."
  )

  expect_match(content, "title: \"Workbench Report\"", fixed = TRUE)
  expect_match(content, "Explain this code", fixed = TRUE)
  expect_match(content, "Use mean\\(x\\)")
})

test_that("create_quarto_report writes a qmd without rendering", {
  dir <- tempfile("rstudiozhai-report-")
  result <- create_quarto_report(
    task = "Create a report",
    ai_result = "Report body",
    output_dir = dir,
    title = "Generated Report",
    include_environment = FALSE
  )

  expect_true(result$ok)
  expect_false(result$rendered)
  expect_true(file.exists(result$path))
  expect_match(paste(readLines(result$path, warn = FALSE), collapse = "\n"), "Generated Report")
})
