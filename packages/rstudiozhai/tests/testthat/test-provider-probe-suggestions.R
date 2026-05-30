test_that("probe suggestions explain missing model configuration", {
  probe <- provider_probe_error(
    "compatible_chat",
    "INVALID_CONFIG",
    "Compatible chat model is missing. Set RSTUDIOZHAI_GATEWAY_MODEL or pass model."
  )

  suggestions <- suggest_provider_probe_actions(probe)

  expect_s3_class(suggestions, "data.frame")
  expect_true(all(c("code", "message", "action") %in% names(suggestions)))
  expect_true("SET_MODEL" %in% suggestions$code)
  expect_match(paste(suggestions$message, collapse = "\n"), "模型")
  expect_match(format_provider_probe(probe), "修复建议")
})

test_that("probe suggestions explain local gateway connection failures", {
  probe <- provider_probe_error(
    "compatible_chat",
    "PROBE_FAILED",
    "Failed to connect to 127.0.0.1 port 11434: Connection refused",
    details = list(url = "http://127.0.0.1:11434/v1/models")
  )

  suggestions <- suggest_provider_probe_actions(probe)

  expect_true("START_GATEWAY" %in% suggestions$code)
  expect_true("CHECK_BASE_URL" %in% suggestions$code)
  expect_match(paste(suggestions$action, collapse = "\n"), "Ollama|vLLM|LiteLLM")
})

test_that("probe suggestions explain auth and path failures", {
  auth <- provider_probe_error(
    "openai_responses",
    "PROBE_FAILED",
    "HTTP 401 Unauthorized"
  )
  path <- provider_probe_error(
    "compatible_chat",
    "PROBE_FAILED",
    "HTTP 404 Not Found"
  )

  expect_true("CHECK_API_KEY" %in% suggest_provider_probe_actions(auth)$code)
  expect_true("CHECK_MODELS_ENDPOINT" %in% suggest_provider_probe_actions(path)$code)
})

test_that("probe suggestions handle empty model lists", {
  probe <- list(
    ok = TRUE,
    provider = "compatible_chat",
    url = "http://127.0.0.1:11434/v1/models",
    count = 0L,
    models = data.frame(model = character(), stringsAsFactors = FALSE),
    warnings = "No model IDs were found in the provider response.",
    error = NULL
  )

  suggestions <- suggest_provider_probe_actions(probe)

  expect_true("CHECK_MODEL_LIST" %in% suggestions$code)
  expect_match(format_provider_probe(probe), "修复建议")
})
