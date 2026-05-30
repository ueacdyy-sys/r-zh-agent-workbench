test_that("AI task request keeps a stable safety contract", {
  request <- build_ai_task_request(
    task = "  explain the selected R code  ",
    mode = "explain",
    context = list(selection = "x <- 1")
  )

  expect_equal(request$task, "explain the selected R code")
  expect_equal(request$mode, "explain")
  expect_equal(request$provider, "mock")
  expect_false(request$safety$allow_code_execution)
  expect_true(request$safety$require_user_confirmation)
  expect_equal(request$metadata$client, "rstudiozhai")
})

test_that("AI task request rejects invalid input at the boundary", {
  expect_error(build_ai_task_request(""), "non-empty")
  expect_error(build_ai_task_request("task", context = "bad"), "named list|list")
  expect_error(build_ai_task_request("task", mode = "delete"), "mode")
})

test_that("provider responses are normalized and validated", {
  request <- build_ai_task_request("diagnose environment")
  response <- invoke_ai_provider(
    request,
    function(req) list(ok = TRUE, content = "done")
  )

  expect_true(response$ok)
  expect_equal(response$content, "done")
  expect_equal(response$warnings, character())
  expect_equal(response$proposed_files, list())

  expect_error(
    invoke_ai_provider(request, function(req) list(ok = TRUE, content = "")),
    "non-empty content"
  )
})
