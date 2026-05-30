test_that("provider integration report summarizes gateway config without leaking secrets", {
  seen <- new.env(parent = emptyenv())
  values <- list(
    gateway_api_key = "super-secret-key",
    gateway_model = "qwen-local",
    gateway_base_url = "http://127.0.0.1:11434/v1",
    gateway_endpoint = "/chat/completions"
  )

  report <- collect_provider_integration_report(
    "compatible_chat",
    values = values,
    include_environment = FALSE,
    include_extension = FALSE,
    timeout_seconds = 3L,
    probe_fun = function(provider, config, timeout_seconds) {
      seen$provider <- provider
      seen$api_key <- config$api_key
      seen$timeout_seconds <- timeout_seconds
      list(
        ok = TRUE,
        provider = provider,
        url = paste0(config$base_url, "/models"),
        count = 1L,
        models = data.frame(model = "qwen-local", stringsAsFactors = FALSE),
        warnings = character(),
        error = NULL
      )
    }
  )

  expect_true(report$overall_ok)
  expect_equal(seen$provider, "compatible_chat")
  expect_equal(seen$api_key, "super-secret-key")
  expect_equal(seen$timeout_seconds, 3L)
  expect_true(report$config$has_api_key)
  expect_false("api_key" %in% names(report$config))
  expect_equal(report$config$model, "qwen-local")
  expect_equal(report$probe$result$count, 1L)

  raw_text <- paste(utils::capture.output(str(report)), collapse = "\n")
  markdown <- format_provider_integration_report(report)
  expect_false(grepl("super-secret-key", raw_text, fixed = TRUE))
  expect_false(grepl("super-secret-key", markdown, fixed = TRUE))
  expect_match(markdown, "AI Provider", fixed = TRUE)
  expect_match(markdown, "qwen-local", fixed = TRUE)
})

test_that("provider integration report includes probe suggestions and optional local reports", {
  values <- list(
    gateway_model = "qwen-local",
    gateway_base_url = "http://127.0.0.1:11434/v1",
    gateway_endpoint = "/chat/completions"
  )

  report <- collect_provider_integration_report(
    "compatible_chat",
    values = values,
    include_environment = TRUE,
    include_extension = TRUE,
    packages = "stats",
    probe_fun = function(provider, config, timeout_seconds) {
      provider_probe_error(
        provider,
        "PROBE_FAILED",
        "connection refused",
        details = list(url = paste0(config$base_url, "/models"))
      )
    }
  )

  expect_false(report$overall_ok)
  expect_true(is.list(report$environment))
  expect_true(is.list(report$extension))
  expect_true("START_GATEWAY" %in% report$probe$suggestions$code)

  markdown <- format_provider_integration_report(report)
  expect_match(markdown, "FAILED", fixed = TRUE)
  expect_match(markdown, "START_GATEWAY", fixed = TRUE)
  expect_match(markdown, "RStudio", fixed = TRUE)
})

test_that("provider report is exposed through middleware and MCP", {
  catalog <- available_workbench_commands()
  expect_true("provider-report" %in% catalog$command)
  expect_false(catalog$mutates_files[match("provider-report", catalog$command)])

  result <- run_workbench_command(
    "provider-report",
    list(
      provider = "compatible_chat",
      model = "",
      base_url = "http://127.0.0.1:11434/v1",
      include_environment = FALSE,
      include_extension = FALSE
    )
  )

  expect_true(result$ok)
  expect_false(result$data$report$overall_ok)
  expect_equal(result$data$report$probe$result$error$code, "INVALID_CONFIG")
  expect_match(result$data$markdown, "AI Provider", fixed = TRUE)

  tools <- mcp_tool_definitions()
  names <- vapply(tools, function(tool) tool$name, character(1))
  expect_true("rstudiozhai_provider_report" %in% names)
})

test_that("workbench app exposes provider integration report controls", {
  app <- create_workbench_app()
  ui_text <- paste(utils::capture.output(print(app$ui)), collapse = "\n")

  expect_match(ui_text, "provider_report", fixed = TRUE)
  expect_match(ui_text, "provider_report_result", fixed = TRUE)
})
