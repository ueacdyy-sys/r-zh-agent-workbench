test_that("gateway presets expose stable OpenAI-compatible options", {
  presets <- provider_gateway_presets()

  expect_s3_class(presets, "data.frame")
  expect_true(all(c(
    "preset",
    "label",
    "provider",
    "base_url",
    "endpoint",
    "requires_api_key",
    "default_model",
    "description"
  ) %in% names(presets)))
  expect_true(all(c("ollama", "vllm", "litellm", "enterprise_compatible") %in% presets$preset))
  expect_true(all(presets$provider == "compatible_chat"))
  expect_false(any(grepl("secret", paste(utils::capture.output(str(presets)), collapse = "\n"), fixed = TRUE)))

  text <- format_provider_gateway_presets(presets)
  expect_match(text, "ollama", fixed = TRUE)
  expect_match(text, "LiteLLM", fixed = TRUE)
})

test_that("gateway preset values can fill compatible chat config without writing secrets", {
  values <- provider_values_from_gateway_preset(
    "ollama",
    model = "qwen2.5",
    api_key = "local-secret"
  )

  expect_equal(values$gateway_model, "qwen2.5")
  expect_equal(values$gateway_base_url, "http://127.0.0.1:11434/v1")
  expect_equal(values$gateway_endpoint, "/chat/completions")
  expect_equal(values$gateway_api_key, "local-secret")

  checklist <- collect_provider_integration_checklist(
    preset = "ollama",
    model = "qwen2.5",
    api_key = "local-secret"
  )
  raw_text <- paste(utils::capture.output(str(checklist)), collapse = "\n")
  markdown <- format_provider_integration_checklist(checklist)

  expect_equal(checklist$provider, "compatible_chat")
  expect_equal(checklist$values$gateway_model, "qwen2.5")
  expect_false(grepl("local-secret", raw_text, fixed = TRUE))
  expect_false(grepl("local-secret", markdown, fixed = TRUE))
  expect_match(markdown, "provider-report", fixed = TRUE)
  expect_match(markdown, "Ollama", fixed = TRUE)
})

test_that("provider presets and checklist are exposed through middleware and MCP", {
  catalog <- available_workbench_commands()
  expect_true(all(c("provider-presets", "provider-checklist") %in% catalog$command))
  expect_false(catalog$mutates_files[match("provider-presets", catalog$command)])
  expect_false(catalog$mutates_files[match("provider-checklist", catalog$command)])

  presets <- run_workbench_command("provider-presets")
  expect_true(presets$ok)
  expect_true("ollama" %in% presets$data$presets$preset)

  checklist <- run_workbench_command(
    "provider-checklist",
    list(preset = "vllm", model = "qwen-local")
  )
  expect_true(checklist$ok)
  expect_equal(checklist$data$checklist$values$gateway_model, "qwen-local")
  expect_match(checklist$data$markdown, "vLLM", fixed = TRUE)

  tools <- mcp_tool_definitions()
  names <- vapply(tools, function(tool) tool$name, character(1))
  expect_true("rstudiozhai_provider_presets" %in% names)
  expect_true("rstudiozhai_provider_checklist" %in% names)
})

test_that("workbench app exposes gateway preset and checklist controls", {
  app <- create_workbench_app()
  ui_text <- paste(utils::capture.output(print(app$ui)), collapse = "\n")

  expect_match(ui_text, "gateway_preset", fixed = TRUE)
  expect_match(ui_text, "apply_gateway_preset", fixed = TRUE)
  expect_match(ui_text, "gateway_checklist", fixed = TRUE)
  expect_match(ui_text, "gateway_checklist_result", fixed = TRUE)
})
