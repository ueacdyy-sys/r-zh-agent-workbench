test_that("bundled R snippets are readable", {
  path <- rstudio_snippet_source_path("r")
  text <- read_bundled_rstudio_snippets("r")

  expect_true(file.exists(path))
  expect_match(text, "snippet rzdiag", fixed = TRUE)
  expect_match(text, "snippet rzreport", fixed = TRUE)
})

test_that("user snippet path follows platform conventions", {
  path <- rstudio_user_snippet_path("r", appdata = "C:/Users/example/AppData/Roaming")

  expect_match(path, "RStudio/snippets/r.snippets", fixed = TRUE)
  expect_error(rstudio_user_snippet_path("python"), "language must")
})

test_that("snippet installer writes explicitly selected target", {
  target <- file.path(tempdir(), "rstudiozhai-snippets", "r.snippets")
  result <- install_rstudio_snippets(target = target, overwrite = TRUE, backup = FALSE)

  expect_true(result$ok)
  expect_true(file.exists(target))
  expect_equal(result$backup, "")
  expect_match(paste(readLines(target, warn = FALSE), collapse = "\n"), "snippet rzexplain", fixed = TRUE)
  expect_error(install_rstudio_snippets(target = target, overwrite = FALSE), "already exists")
})
