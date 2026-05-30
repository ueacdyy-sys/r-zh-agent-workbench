test_that("RStudio extension status reports installed package resources", {
  status <- collect_rstudio_extension_status()

  expect_true(status$package$installed)
  expect_true(is.logical(status$rstudio$ok))
  expect_true(status$addin$ok)
  expect_true(status$project_template$ok)
  expect_true(status$connections$ok)
  expect_true(status$snippets$ok)
  expect_true(status$package_resources_ok)
  expect_identical(status$overall_ok, isTRUE(status$package_resources_ok) && isTRUE(status$rstudio$ok))
  expect_true(is.list(status$user_snippets))
  expect_true(is.list(status$startup_banner))
  expect_match(status$addin$binding, "run_workbench", fixed = TRUE)
  expect_true(status$addin$binding_exported)
  expect_true(status$project_template$binding_exported)
  expect_true(length(status$connection_snippets) >= 3L)
})

test_that("RStudio extension status has a readable Chinese report", {
  status <- collect_rstudio_extension_status()
  report <- format_rstudio_extension_status(status)

  expect_match(report, "RStudio 扩展安装验收报告", fixed = TRUE)
  expect_match(report, "包内扩展资源", fixed = TRUE)
  expect_match(report, "Addin", fixed = TRUE)
  expect_match(report, "Project Template", fixed = TRUE)
  expect_match(report, "Connections", fixed = TRUE)
  expect_match(report, "Snippets", fixed = TRUE)
  expect_match(report, "Visible Startup Entry", fixed = TRUE)
})

test_that("RStudio extension status command is available through middleware", {
  catalog <- available_workbench_commands()
  expect_true("rstudio-extension-status" %in% catalog$command)

  result <- run_workbench_command("rstudio-extension-status")
  expect_true(result$ok)
  expect_true(result$data$status$package_resources_ok)
  expect_match(result$data$markdown, "RStudio 扩展安装验收报告", fixed = TRUE)
})

test_that("RStudio extension status separates package resources from local RStudio installation", {
  status <- collect_rstudio_extension_status(rstudio = list(ok = FALSE, path = "", version = ""))

  expect_true(status$package_resources_ok)
  expect_false(status$overall_ok)
  expect_true(any(vapply(status$suggestions, function(item) identical(item$code, "CHECK_RSTUDIO"), logical(1))))
})
