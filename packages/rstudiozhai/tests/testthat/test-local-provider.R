test_that("local provider returns a deterministic workbench response", {
  request <- build_ai_task_request(
    task = "diagnose my RStudio project",
    mode = "diagnose",
    provider = "local",
    context = list(environment = collect_environment_report(packages = c("stats")))
  )

  response <- local_chinese_provider(request)

  expect_true(response$ok)
  expect_match(response$content, "diagnose my RStudio project", fixed = TRUE)
  expect_equal(response$warnings, character())
  expect_equal(response$raw$provider, "local")
})

test_that("local provider validates request shape", {
  expect_error(local_chinese_provider(list(task = NULL)), "request must be created")
})
