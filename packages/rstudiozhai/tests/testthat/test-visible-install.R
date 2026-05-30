test_that("startup banner installer writes an idempotent marked block", {
  path <- file.path(tempdir(), "rstudiozhai-visible", ".Rprofile")

  first <- install_rstudio_startup_banner(path = path, backup = TRUE)
  second <- install_rstudio_startup_banner(path = path, backup = TRUE)
  text <- readLines(path, warn = FALSE)

  expect_true(first$ok)
  expect_true(second$ok)
  expect_true(file.exists(path))
  expect_equal(sum(text == "# >>> rstudiozhai startup banner >>>"), 1L)
  expect_equal(sum(text == "# <<< rstudiozhai startup banner <<<"), 1L)
  expect_match(paste(text, collapse = "\n"), "rstudiozhai::run_workbench", fixed = TRUE)
})

test_that("startup banner installer preserves existing Rprofile with backup", {
  dir <- file.path(tempdir(), "rstudiozhai-visible-existing")
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  path <- file.path(dir, ".Rprofile")
  writeLines("options(width = 120)", path)

  result <- install_rstudio_startup_banner(path = path, backup = TRUE)
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")

  expect_true(result$ok)
  expect_true(file.exists(result$backup))
  expect_match(text, "options(width = 120)", fixed = TRUE)
  expect_match(text, "rstudiozhai startup banner", fixed = TRUE)
})

test_that("startup banner can be removed cleanly", {
  path <- file.path(tempdir(), "rstudiozhai-visible-remove", ".Rprofile")
  install_rstudio_startup_banner(path = path, backup = FALSE)

  result <- remove_rstudio_startup_banner(path = path, backup = FALSE)
  text <- paste(readLines(path, warn = FALSE), collapse = "\n")

  expect_true(result$ok)
  expect_false(grepl("rstudiozhai startup banner", text, fixed = TRUE))
})

