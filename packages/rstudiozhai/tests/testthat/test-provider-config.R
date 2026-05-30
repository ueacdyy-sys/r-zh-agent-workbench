test_that("provider config fields define safe UI metadata", {
  fields <- provider_config_fields()

  expect_s3_class(fields, "data.frame")
  expect_true(all(c("provider", "field", "env_var", "secret", "required") %in% names(fields)))
  expect_true(all(c("openai_responses", "compatible_chat") %in% fields$provider))
  expect_true(fields$secret[match("api_key", fields$field)])
  expect_true(any(fields$env_var == "RSTUDIOZHAI_GATEWAY_MODEL"))
})

test_that("provider config can be built from in-memory UI values", {
  openai <- build_provider_config(
    "openai_responses",
    list(
      openai_api_key = "openai-secret",
      openai_model = "gpt-test",
      openai_base_url = "https://api.example.test/v1/"
    )
  )

  expect_equal(openai$model, "gpt-test")
  expect_equal(openai$base_url, "https://api.example.test/v1")
  expect_equal(openai$api_key, "openai-secret")

  gateway <- build_provider_config(
    "compatible_chat",
    list(
      gateway_api_key = "",
      gateway_model = "qwen-local",
      gateway_base_url = "http://127.0.0.1:11434/v1/",
      gateway_endpoint = "chat/completions"
    )
  )

  expect_equal(gateway$model, "qwen-local")
  expect_equal(gateway$base_url, "http://127.0.0.1:11434/v1")
  expect_equal(gateway$endpoint, "/chat/completions")
  expect_equal(gateway$api_key, "")
})

test_that("provider config status from values does not leak secrets", {
  status <- provider_config_status_from_values(
    "compatible_chat",
    list(
      gateway_api_key = "gateway-secret",
      gateway_model = "qwen-local",
      gateway_base_url = "http://127.0.0.1:11434/v1"
    )
  )

  expect_true(status$ok)
  expect_true(status$has_api_key)
  expect_false(grepl("gateway-secret", format_provider_status(status), fixed = TRUE))
})

test_that("provider factory uses in-memory config without writing environment variables", {
  old_model <- Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = NA_character_)
  on.exit({
    if (is.na(old_model)) {
      Sys.unsetenv("RSTUDIOZHAI_GATEWAY_MODEL")
    } else {
      Sys.setenv(RSTUDIOZHAI_GATEWAY_MODEL = old_model)
    }
  }, add = TRUE)
  Sys.unsetenv("RSTUDIOZHAI_GATEWAY_MODEL")

  seen <- new.env(parent = emptyenv())
  provider <- provider_from_config(
    "compatible_chat",
    build_provider_config(
      "compatible_chat",
      list(
        gateway_model = "qwen-local",
        gateway_base_url = "http://127.0.0.1:11434/v1"
      )
    ),
    http_post = function(url, api_key, payload, timeout_seconds) {
      seen$model <- payload$model
      list(choices = list(list(message = list(content = "ok"))))
    }
  )

  request <- build_ai_task_request("hello", provider = "compatible_chat")
  response <- provider(request)

  expect_true(response$ok)
  expect_equal(response$content, "ok")
  expect_equal(seen$model, "qwen-local")
  expect_equal(Sys.getenv("RSTUDIOZHAI_GATEWAY_MODEL", unset = ""), "")
})

test_that("workbench app exposes provider configuration controls", {
  app <- create_workbench_app()
  ui_text <- paste(utils::capture.output(print(app$ui)), collapse = "\n")

  expect_match(ui_text, "provider_config_provider", fixed = TRUE)
  expect_match(ui_text, "gateway_model", fixed = TRUE)
  expect_match(ui_text, "gateway_api_key", fixed = TRUE)
  expect_match(ui_text, "openai_model", fixed = TRUE)
  expect_match(ui_text, "provider_config_status", fixed = TRUE)
})
