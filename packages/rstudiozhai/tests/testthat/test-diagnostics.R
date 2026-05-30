test_that("environment report exposes core runtime sections", {
  report <- collect_environment_report(packages = c("stats"))

  expect_named(report, c("generated_at", "r", "rstudio", "quarto", "packages", "suggestions"))
  expect_true(report$r$ok)
  expect_true(report$packages[[1]]$installed)
})

test_that("missing packages produce actionable suggestions", {
  report <- collect_environment_report(packages = c("definitely_missing_pkg_zzzz"))
  suggestions <- suggest_environment_actions(report)

  expect_true(length(suggestions) >= 1L)
  expect_equal(suggestions[[1]]$code, "INSTALL_R_PACKAGES")
})

test_that("formatted diagnostics are markdown-like and stable", {
  report <- collect_environment_report(packages = c("stats"))
  markdown <- format_environment_report(report)

  expect_match(markdown, "# RStudio", fixed = TRUE)
  expect_match(markdown, "## R", fixed = TRUE)
  expect_match(markdown, "## RStudio", fixed = TRUE)
  expect_match(markdown, "## Quarto", fixed = TRUE)
})
