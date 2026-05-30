test_that("compatible chat config supports local and enterprise gateways", {
  config <- get_compatible_chat_config(
    api_key = "secret-key",
    model = "local-model",
    base_url = "http://127.0.0.1:11434/v1/",
    endpoint = "/chat/completions"
  )

  expect_equal(config$api_key, "secret-key")
  expect_equal(config$model, "local-model")
  expect_equal(config$base_url, "http://127.0.0.1:11434/v1")
  expect_equal(config$endpoint, "/chat/completions")
  expect_true(validate_compatible_chat_config(config))
  expect_true(validate_compatible_chat_config(get_compatible_chat_config(api_key = "", model = "qwen")))
  expect_error(validate_compatible_chat_config(get_compatible_chat_config(model = "")), "model")
  expect_error(validate_compatible_chat_config(get_compatible_chat_config(model = "qwen", base_url = "")), "base_url")
})

test_that("compatible chat payload preserves the workbench safety contract", {
  request <- build_ai_task_request(
    task = "解释当前项目结构",
    mode = "explain",
    provider = "compatible_chat",
    context = list(project = list(files = c("R/analysis.R", "report.qmd")))
  )

  payload <- build_compatible_chat_payload(request, model = "qwen-local", max_tokens = 700L)

  expect_equal(payload$model, "qwen-local")
  expect_false(payload$stream)
  expect_equal(payload$messages[[1]]$role, "system")
  expect_equal(payload$messages[[2]]$role, "user")
  expect_match(payload$messages[[1]]$content, "Answer in Chinese", fixed = TRUE)
  expect_match(payload$messages[[1]]$content, "Require user confirmation: TRUE", fixed = TRUE)
  expect_match(payload$messages[[2]]$content, "R/analysis.R", fixed = TRUE)
  expect_equal(payload$max_tokens, 700L)
})

test_that("compatible chat response text can be extracted from common response shapes", {
  expect_equal(
    extract_compatible_chat_response_text(list(
      choices = list(list(message = list(content = "中文回答")))
    )),
    "中文回答"
  )
  expect_equal(
    extract_compatible_chat_response_text(list(
      choices = list(list(delta = list(content = "stream chunk")))
    )),
    "stream chunk"
  )
  expect_error(extract_compatible_chat_response_text(list(choices = list())), "content")
})

test_that("compatible chat provider uses injectable HTTP transport without requiring API keys", {
  request <- build_ai_task_request(
    task = "诊断项目",
    mode = "diagnose",
    provider = "compatible_chat",
    context = list(project = list(summary = "small project"))
  )

  seen <- new.env(parent = emptyenv())
  response <- compatible_chat_provider(
    request,
    api_key = "",
    model = "qwen-local",
    base_url = "http://127.0.0.1:11434/v1",
    http_post = function(url, api_key, payload, timeout_seconds) {
      seen$url <- url
      seen$api_key <- api_key
      seen$payload <- payload
      seen$timeout_seconds <- timeout_seconds
      list(choices = list(list(message = list(content = "本地模型回答"))))
    }
  )

  expect_true(response$ok)
  expect_equal(response$content, "本地模型回答")
  expect_equal(seen$url, "http://127.0.0.1:11434/v1/chat/completions")
  expect_equal(seen$api_key, "")
  expect_equal(seen$payload$model, "qwen-local")
  expect_equal(response$raw$provider, "compatible_chat")
})
