test_that("Quarto render job scripts are generated for existing reports", {
  dir <- tempfile("rstudiozhai-job-")
  report <- create_quarto_report(
    task = "Render this later",
    ai_result = "Job body",
    output_dir = dir,
    title = "Job Report",
    include_environment = FALSE
  )

  script <- create_quarto_render_job_script(report$path)

  expect_true(file.exists(script))
  expect_match(paste(readLines(script, warn = FALSE), collapse = "\n"), "render_quarto_report")
})

test_that("Quarto render jobs can use a custom runner for tests", {
  dir <- tempfile("rstudiozhai-job-runner-")
  report <- create_quarto_report(
    task = "Render with custom runner",
    ai_result = "Body",
    output_dir = dir,
    title = "Runner Report",
    include_environment = FALSE
  )

  seen <- new.env(parent = emptyenv())
  result <- run_quarto_render_job(
    report$path,
    runner = function(script, name, working_dir) {
      seen$script <- script
      seen$name <- name
      seen$working_dir <- working_dir
      "job-id"
    }
  )

  expect_true(result$ok)
  expect_equal(result$mode, "custom_runner")
  expect_equal(result$value, "job-id")
  expect_true(file.exists(seen$script))
  expect_equal(seen$name, "Render Quarto report")
})
