test_that("project template creates a reproducible starter project", {
  path <- tempfile("rstudiozhai-project-")
  result <- create_zh_ai_project(path, project_name = "Demo Project")

  expect_true(result$ok)
  expect_true(dir.exists(file.path(path, "R")))
  expect_true(dir.exists(file.path(path, "data")))
  expect_true(dir.exists(file.path(path, "reports")))
  expect_true(file.exists(file.path(path, "README.md")))
  expect_true(file.exists(file.path(path, "R", "analysis.R")))
  expect_true(file.exists(file.path(path, "reports", "analysis.qmd")))
  expect_match(paste(readLines(file.path(path, "README.md"), warn = FALSE), collapse = "\n"), "Demo Project")
})

test_that("project template metadata points to an exported binding", {
  dcf_path <- system.file(
    "rstudio",
    "templates",
    "project",
    "rstudiozhai-analysis.dcf",
    package = "rstudiozhai"
  )
  metadata <- read.dcf(dcf_path)

  binding <- unname(metadata[1, "Binding"])
  title <- unname(metadata[1, "Title"])

  expect_equal(binding, "create_zh_ai_project")
  expect_equal(title, "RStudio Chinese AI Analysis Project")
  expect_true(exists(binding, where = asNamespace("rstudiozhai")))
})
