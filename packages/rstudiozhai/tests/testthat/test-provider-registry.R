test_that("provider catalog exposes stable provider metadata", {
  catalog <- list_ai_providers()

  expect_s3_class(catalog, "data.frame")
  expect_true(all(c("provider", "label", "needs_network", "needs_config", "description") %in% names(catalog)))
  expect_true(all(c("local", "mock", "openai_responses", "compatible_chat") %in% catalog$provider))
  expect_false(catalog$needs_network[match("local", catalog$provider)])
  expect_true(catalog$needs_config[match("openai_responses", catalog$provider)])
  expect_true(catalog$needs_config[match("compatible_chat", catalog$provider)])
})

test_that("provider config status does not leak secrets", {
  status <- provider_config_status(
    "openai_responses",
    config = get_openai_config(api_key = "secret-key", model = "test-model")
  )

  expect_true(status$ok)
  expect_equal(status$provider, "openai_responses")
  expect_equal(status$model, "test-model")
  expect_true(status$has_api_key)
  expect_false(grepl("secret-key", paste(unlist(status), collapse = " "), fixed = TRUE))

  missing <- provider_config_status(
    "openai_responses",
    config = get_openai_config(api_key = "", model = "")
  )
  expect_false(missing$ok)
  expect_true(any(missing$missing %in% c("OPENAI_API_KEY", "RSTUDIOZHAI_OPENAI_MODEL")))

  gateway <- provider_config_status(
    "compatible_chat",
    config = get_compatible_chat_config(api_key = "gateway-secret", model = "qwen-local")
  )
  expect_true(gateway$ok)
  expect_equal(gateway$provider, "compatible_chat")
  expect_equal(gateway$model, "qwen-local")
  expect_true(gateway$has_api_key)
  expect_false(grepl("gateway-secret", paste(unlist(gateway), collapse = " "), fixed = TRUE))
})

test_that("provider resolution is explicit and injectable", {
  expect_identical(resolve_ai_provider("local"), local_chinese_provider)
  expect_identical(resolve_ai_provider("mock"), mock_ai_provider)
  expect_true(is.function(resolve_ai_provider("openai_responses")))
  expect_true(is.function(resolve_ai_provider("compatible_chat")))

  custom <- function(request) list(ok = TRUE, content = "custom")
  expect_identical(resolve_ai_provider("custom", provider_fun = custom), custom)
  expect_error(resolve_ai_provider("missing"), "Unknown provider")
})

test_that("provider status command is available through middleware", {
  catalog <- available_workbench_commands()
  expect_true("provider-status" %in% catalog$command)

  result <- run_workbench_command("provider-status", list(provider = "local"))
  expect_true(result$ok)
  expect_true(result$data$status$ok)
  expect_equal(result$data$status$provider, "local")
})
