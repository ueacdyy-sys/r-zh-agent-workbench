test_that("OpenAI config is explicit and does not require hard-coded models", {
  config <- get_openai_config(api_key = "key", model = "model", base_url = "https://example.test/v1/")

  expect_equal(config$api_key, "key")
  expect_equal(config$model, "model")
  expect_equal(config$base_url, "https://example.test/v1")
  expect_true(validate_openai_config(config))
  expect_error(validate_openai_config(get_openai_config(api_key = "", model = "model")), "API key")
  expect_error(validate_openai_config(get_openai_config(api_key = "key", model = "")), "model")
})

test_that("Responses payload keeps the workbench safety contract", {
  request <- build_ai_task_request(
    task = "Explain the selected code",
    mode = "explain",
    provider = "openai_responses",
    context = list(selection = "mean(x)")
  )
  payload <- build_openai_responses_payload(request, model = "test-model", max_output_tokens = 500L)

  expect_equal(payload$model, "test-model")
  expect_match(payload$instructions, "Answer in Chinese", fixed = TRUE)
  expect_match(payload$instructions, "Require user confirmation: TRUE", fixed = TRUE)
  expect_match(payload$input, "mean(x)", fixed = TRUE)
  expect_equal(payload$max_output_tokens, 500L)
})

test_that("OpenAI response text can be extracted from common response shapes", {
  expect_equal(
    extract_openai_response_text(list(output_text = "hello")),
    "hello"
  )
  expect_equal(
    extract_openai_response_text(list(
      output = list(
        list(content = list(list(type = "output_text", text = "part one"))),
        list(content = list(list(type = "output_text", text = "part two")))
      )
    )),
    "part one\npart two"
  )
  expect_error(extract_openai_response_text(list(output = list())), "output text")
})

test_that("OpenAI provider uses injectable HTTP transport", {
  request <- build_ai_task_request(
    task = "Diagnose setup",
    mode = "diagnose",
    provider = "openai_responses",
    context = list(environment = collect_environment_report(packages = c("stats")))
  )

  seen <- new.env(parent = emptyenv())
  response <- openai_responses_provider(
    request,
    api_key = "test-key",
    model = "test-model",
    base_url = "https://api.example.test/v1",
    http_post = function(url, api_key, payload, timeout_seconds) {
      seen$url <- url
      seen$api_key <- api_key
      seen$payload <- payload
      seen$timeout_seconds <- timeout_seconds
      list(output_text = "中文回答")
    }
  )

  expect_true(response$ok)
  expect_equal(response$content, "中文回答")
  expect_equal(seen$url, "https://api.example.test/v1/responses")
  expect_equal(seen$api_key, "test-key")
  expect_equal(seen$payload$model, "test-model")
  expect_equal(response$raw$provider, "openai_responses")
})
