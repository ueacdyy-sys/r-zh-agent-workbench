test_that("workbench dependency check reports installed UI packages", {
  deps <- check_workbench_dependencies()

  expect_true(deps$ok)
  expect_equal(deps$missing, character())
})

test_that("RStudio context has a stable shape outside and inside RStudio", {
  context <- collect_rstudio_context(max_chars = 16L)

  expect_true(all(c("available", "project_path", "active_document") %in% names(context)))
  expect_type(context$available, "logical")
  expect_named(context$active_document, c("id", "path", "contents", "selection"))
})

test_that("workbench app can be constructed without launching RStudio", {
  app <- create_workbench_app()

  expect_type(app, "list")
  expect_named(app, c("ui", "server"))
  expect_true(inherits(app$ui, "shiny.tag.list") || inherits(app$ui, "shiny.tag"))
  expect_type(app$server, "closure")
})

test_that("workbench app exposes provider selection controls", {
  app <- create_workbench_app()
  ui_text <- paste(utils::capture.output(print(app$ui)), collapse = "\n")

  expect_match(ui_text, "provider", fixed = TRUE)
  expect_match(ui_text, "openai_responses", fixed = TRUE)
  expect_match(ui_text, "provider_status", fixed = TRUE)
})

test_that("workbench result formatting includes warnings and proposed files", {
  text <- format_workbench_result(list(
    ok = TRUE,
    content = "content",
    warnings = "review before writing",
    proposed_files = list("R/example.R" = "x <- 1")
  ))

  expect_match(text, "content", fixed = TRUE)
  expect_match(text, "Warnings", fixed = TRUE)
  expect_match(text, "R/example.R", fixed = TRUE)
})
