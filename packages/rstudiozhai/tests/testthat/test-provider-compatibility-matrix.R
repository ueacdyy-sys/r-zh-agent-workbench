test_that("provider compatibility matrix includes local, cloud, and gateway targets", {
  matrix <- provider_compatibility_matrix()

  expect_s3_class(matrix, "data.frame")
  expect_true(all(c(
    "target",
    "target_type",
    "provider",
    "preset",
    "label",
    "base_url",
    "endpoint",
    "requires_api_key",
    "needs_network",
    "supports_model_probe",
    "supports_chat_completions",
    "supports_responses",
    "default_model",
    "recommended_use",
    "next_step"
  ) %in% names(matrix)))

  expect_true(all(c(
    "local",
    "mock",
    "openai_responses",
    "ollama",
    "vllm",
    "litellm",
    "deepseek",
    "dashscope_qwen",
    "siliconflow",
    "zhipu_glm",
    "moonshot_kimi"
  ) %in% matrix$target))
  expect_true(matrix$supports_responses[match("openai_responses", matrix$target)])
  expect_true(matrix$supports_chat_completions[match("dashscope_qwen", matrix$target)])
  expect_false(matrix$requires_api_key[match("ollama", matrix$target)])
  expect_true(matrix$requires_api_key[match("deepseek", matrix$target)])
})

test_that("provider compatibility matrix can be formatted and filtered", {
  matrix <- provider_compatibility_matrix()
  cloud <- filter_provider_compatibility_matrix(matrix, target_type = "cloud_gateway")

  expect_true(NROW(cloud) >= 4L)
  expect_true(all(cloud$target_type == "cloud_gateway"))
  expect_false("ollama" %in% cloud$target)

  text <- format_provider_compatibility_matrix(cloud)
  expect_match(text, "Provider compatibility matrix", fixed = TRUE)
  expect_match(text, "dashscope_qwen", fixed = TRUE)
  expect_match(text, "provider-checklist", fixed = TRUE)
})

test_that("provider compatibility matrix is exposed through middleware and MCP", {
  catalog <- available_workbench_commands()
  expect_true("provider-compatibility" %in% catalog$command)
  expect_false(catalog$mutates_files[match("provider-compatibility", catalog$command)])

  result <- run_workbench_command("provider-compatibility", list(target_type = "local_gateway"))
  expect_true(result$ok)
  expect_true(all(result$data$matrix$target_type == "local_gateway"))
  expect_match(result$data$markdown, "ollama", fixed = TRUE)

  tools <- mcp_tool_definitions()
  names <- vapply(tools, function(tool) tool$name, character(1))
  expect_true("rstudiozhai_provider_compatibility" %in% names)
})

test_that("workbench app exposes provider compatibility matrix controls", {
  app <- create_workbench_app()
  ui_text <- paste(utils::capture.output(print(app$ui)), collapse = "\n")

  expect_match(ui_text, "provider_compatibility", fixed = TRUE)
  expect_match(ui_text, "provider_compatibility_target_type", fixed = TRUE)
  expect_match(ui_text, "provider_compatibility_result", fixed = TRUE)
})
