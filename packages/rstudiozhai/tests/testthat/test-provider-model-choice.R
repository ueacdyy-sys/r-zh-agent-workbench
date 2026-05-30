test_that("model choices are derived from successful probes", {
  probe <- list(
    ok = TRUE,
    models = data.frame(model = c("qwen-local", "llama-local"), stringsAsFactors = FALSE)
  )

  choices <- provider_model_choices(probe)

  expect_equal(unname(choices), c("qwen-local", "llama-local"))
  expect_equal(names(choices), c("qwen-local", "llama-local"))
  expect_equal(provider_model_choices(list(ok = FALSE)), character())
})

test_that("selected probe model updates the right provider value", {
  openai_values <- apply_provider_model_choice(
    "openai_responses",
    list(openai_model = "", gateway_model = "old-gateway"),
    "gpt-test"
  )
  expect_equal(openai_values$openai_model, "gpt-test")
  expect_equal(openai_values$gateway_model, "old-gateway")

  gateway_values <- apply_provider_model_choice(
    "compatible_chat",
    list(openai_model = "old-openai", gateway_model = ""),
    "qwen-local"
  )
  expect_equal(gateway_values$gateway_model, "qwen-local")
  expect_equal(gateway_values$openai_model, "old-openai")
})

test_that("selected probe model ignores unsupported providers and empty choices", {
  values <- list(openai_model = "gpt", gateway_model = "qwen")
  expect_equal(apply_provider_model_choice("local", values, "other"), values)
  expect_equal(apply_provider_model_choice("compatible_chat", values, ""), values)
})

test_that("workbench app exposes probe model selection controls", {
  app <- create_workbench_app()
  ui_text <- paste(utils::capture.output(print(app$ui)), collapse = "\n")

  expect_match(ui_text, "probe_model_choice", fixed = TRUE)
  expect_match(ui_text, "use_probe_model", fixed = TRUE)
})
