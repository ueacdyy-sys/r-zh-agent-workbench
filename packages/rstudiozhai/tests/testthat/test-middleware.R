test_that("workbench command catalog exposes a stable allowlist", {
  catalog <- available_workbench_commands()

  expect_s3_class(catalog, "data.frame")
  expect_true(all(c("command", "description", "mutates_files", "long_running") %in% names(catalog)))
  expect_true(all(c("list-commands", "diagnostics", "project-scan", "audit-log", "knowledge", "ai-task", "quarto-draft", "connection-template") %in% catalog$command))
  expect_true(catalog$mutates_files[match("quarto-draft", catalog$command)])
  expect_false(catalog$mutates_files[match("project-scan", catalog$command)])
  expect_false(catalog$mutates_files[match("knowledge", catalog$command)])
})

test_that("workbench commands return structured envelopes", {
  unknown <- run_workbench_command("not-a-command")
  expect_false(unknown$ok)
  expect_equal(unknown$error$code, "UNKNOWN_COMMAND")

  diagnostics <- run_workbench_command("diagnostics", list(packages = "stats"))
  expect_true(diagnostics$ok)
  expect_equal(diagnostics$command, "diagnostics")
  expect_match(diagnostics$data$markdown, "RStudio 中文 AI 工作台环境报告")

  knowledge <- run_workbench_command("knowledge", list(query = "quarto"))
  expect_true(knowledge$ok)
  expect_equal(knowledge$data$query, "quarto")
  expect_true("summary" %in% names(knowledge$data))

  ai <- run_workbench_command(
    "ai-task",
    list(
      task = "解释 object not found",
      mode = "explain",
      provider = "local",
      context = list(error = "object 'x' not found")
    )
  )
  expect_true(ai$ok)
  expect_match(ai$data$response$content, "任务")
})

test_that("write-capable commands require explicit write permission", {
  output_dir <- tempfile("rstudiozhai-cli-")
  dir.create(output_dir)

  blocked <- run_workbench_command(
    "quarto-draft",
    list(task = "生成一份中文分析报告", output_dir = output_dir)
  )
  expect_false(blocked$ok)
  expect_equal(blocked$error$code, "WRITE_NOT_ALLOWED")
  expect_equal(list.files(output_dir), character())

  written <- run_workbench_command(
    "quarto-draft",
    list(
      task = "生成一份中文分析报告",
      ai_result = "这是 AI 工作台结果。",
      title = "CLI Report",
      output_dir = output_dir,
      allow_write = TRUE
    )
  )
  expect_true(written$ok)
  expect_true(file.exists(written$data$path))
  expect_match(paste(readLines(written$data$path, warn = FALSE), collapse = "\n"), "AI Workbench Result")
})

test_that("connection-template command exposes safe DBI code", {
  result <- run_workbench_command(
    "connection-template",
    list(kind = "postgres", variable = "pg_con")
  )

  expect_true(result$ok)
  expect_match(result$data$code, "askForPassword", fixed = TRUE)
  expect_match(result$data$code, "pg_con", fixed = TRUE)
})

test_that("CLI JSON helpers preserve the command envelope", {
  skip_if_not_installed("jsonlite")

  parsed <- parse_workbench_cli_args(c("knowledge", "--params-json", "{\"query\":\"quarto\"}"))
  expect_equal(parsed$command, "knowledge")
  expect_equal(parsed$params$query, "quarto")

  result <- workbench_cli_main(
    c("knowledge", "--params-json", "{\"query\":\"quarto\"}"),
    output = NULL
  )
  expect_true(result$ok)

  json <- encode_workbench_json(result, pretty = FALSE)
  decoded <- jsonlite::fromJSON(json)
  expect_true(decoded$ok)
  expect_equal(decoded$command, "knowledge")
})
