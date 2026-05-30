test_that("provider model IDs can be extracted from common gateway shapes", {
  expect_equal(
    extract_provider_model_ids(list(data = list(list(id = "qwen"), list(id = "llama")))),
    c("qwen", "llama")
  )
  expect_equal(
    extract_provider_model_ids(list(models = list(list(name = "deepseek"), list(model = "glm")))),
    c("deepseek", "glm")
  )
  expect_equal(extract_provider_model_ids(list(data = list())), character())
})

test_that("provider probe lists compatible chat models without leaking secrets", {
  seen <- new.env(parent = emptyenv())
  config <- get_compatible_chat_config(
    api_key = "gateway-secret",
    model = "qwen-local",
    base_url = "http://127.0.0.1:11434/v1"
  )

  probe <- probe_provider_models(
    "compatible_chat",
    config = config,
    http_get = function(url, api_key, timeout_seconds) {
      seen$url <- url
      seen$api_key <- api_key
      seen$timeout_seconds <- timeout_seconds
      list(data = list(list(id = "qwen-local"), list(id = "llama-local")))
    },
    timeout_seconds = 3L
  )

  expect_true(probe$ok)
  expect_equal(probe$provider, "compatible_chat")
  expect_equal(seen$url, "http://127.0.0.1:11434/v1/models")
  expect_equal(seen$api_key, "gateway-secret")
  expect_equal(probe$count, 2L)
  expect_equal(probe$models$model, c("qwen-local", "llama-local"))
  expect_false(grepl("gateway-secret", paste(utils::capture.output(str(probe)), collapse = "\n"), fixed = TRUE))
  expect_match(format_provider_probe(probe), "qwen-local", fixed = TRUE)
})

test_that("provider probe returns structured failures", {
  probe <- probe_provider_models(
    "compatible_chat",
    config = get_compatible_chat_config(model = "qwen-local"),
    http_get = function(url, api_key, timeout_seconds) {
      stop("connection refused", call. = FALSE)
    }
  )

  expect_false(probe$ok)
  expect_equal(probe$error$code, "PROBE_FAILED")
  expect_match(probe$error$message, "connection refused", fixed = TRUE)
})

test_that("provider probe is exposed through middleware and MCP catalog", {
  catalog <- available_workbench_commands()
  expect_true("provider-probe" %in% catalog$command)
  expect_false(catalog$mutates_files[match("provider-probe", catalog$command)])

  result <- run_workbench_command(
    "provider-probe",
    list(provider = "compatible_chat", model = "", base_url = "http://127.0.0.1:11434/v1")
  )
  expect_true(result$ok)
  expect_false(result$data$probe$ok)
  expect_equal(result$data$probe$error$code, "INVALID_CONFIG")

  tools <- mcp_tool_definitions()
  names <- vapply(tools, function(tool) tool$name, character(1))
  expect_true("rstudiozhai_provider_probe" %in% names)
})

test_that("workbench app exposes provider probe controls", {
  app <- create_workbench_app()
  ui_text <- paste(utils::capture.output(print(app$ui)), collapse = "\n")

  expect_match(ui_text, "probe_provider_config", fixed = TRUE)
  expect_match(ui_text, "provider_probe_result", fixed = TRUE)
})
