test_that("RStudio terms and commands can be listed and searched", {
  terms <- list_rstudio_terms()
  commands <- list_rstudio_commands()

  expect_true(nrow(terms) >= 5L)
  expect_true(nrow(commands) >= 5L)
  expect_true("Console" %in% terms$term)
  expect_true("Render Quarto" %in% commands$label)

  term_hits <- lookup_rstudio_term("console")
  command_hits <- search_rstudio_commands("render")

  expect_equal(term_hits$term[[1]], "Console")
  expect_true(any(command_hits$id == "render-quarto"))
})

test_that("known R errors receive Chinese explanations", {
  hits <- explain_r_error("Error: object 'x' not found")

  expect_true(nrow(hits) >= 1L)
  expect_equal(hits$id[[1]], "object-not-found")
  expect_match(hits$zh_title[[1]], "找不到对象", fixed = TRUE)
})

test_that("knowledge summaries merge terms commands and errors", {
  summary <- summarize_knowledge_for_query("object not found in Console")

  expect_match(summary, "Term matches", fixed = TRUE)
  expect_match(summary, "Error matches", fixed = TRUE)
  expect_match(summary, "找不到对象", fixed = TRUE)
})

test_that("local provider includes knowledge base matches", {
  request <- build_ai_task_request(
    task = "object not found in Console",
    mode = "explain",
    provider = "local",
    context = list(error = "Error: object 'x' not found")
  )
  response <- local_chinese_provider(request)

  expect_true(response$ok)
  expect_match(response$content, "Knowledge base matches", fixed = TRUE)
  expect_match(response$content, "找不到对象", fixed = TRUE)
})
