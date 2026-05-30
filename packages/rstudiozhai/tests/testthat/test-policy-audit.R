test_that("audit parameter summary redacts secrets and avoids large payloads", {
  summary <- summarize_audit_params(list(
    task = paste(rep("secret task", 50), collapse = " "),
    api_key = "sk-secret",
    password = "db-password",
    context = list(selection = "x <- 1", token = "token-secret"),
    provider = "local",
    allow_write = FALSE
  ))

  text <- paste(utils::capture.output(str(summary)), collapse = "\n")
  expect_false(grepl("sk-secret", text, fixed = TRUE))
  expect_false(grepl("db-password", text, fixed = TRUE))
  expect_false(grepl("token-secret", text, fixed = TRUE))
  expect_equal(summary$task$type, "character")
  expect_true(summary$task$nchar > 100)
  expect_equal(summary$provider, "local")
})

test_that("write-capable commands are denied by central policy before writing", {
  output_dir <- tempfile("rstudiozhai-policy-")
  audit_path <- tempfile("rstudiozhai-audit-", fileext = ".jsonl")
  dir.create(output_dir)

  result <- run_workbench_command(
    "quarto-draft",
    list(
      task = "没有授权写文件",
      output_dir = output_dir,
      audit_path = audit_path
    )
  )

  expect_false(result$ok)
  expect_equal(result$error$code, "WRITE_NOT_ALLOWED")
  expect_equal(list.files(output_dir), character())

  events <- read_workbench_audit_log(audit_path)
  expect_equal(nrow(events), 1L)
  expect_equal(events$command[[1]], "quarto-draft")
  expect_false(events$ok[[1]])
  expect_equal(events$error_code[[1]], "WRITE_NOT_ALLOWED")
})

test_that("successful commands can be audited without leaking secrets", {
  audit_path <- tempfile("rstudiozhai-audit-", fileext = ".jsonl")

  result <- run_workbench_command(
    "ai-task",
    list(
      task = "解释这段代码",
      mode = "explain",
      provider = "local",
      context = list(api_key = "secret-key", selection = "mean(x)"),
      audit_path = audit_path
    )
  )

  expect_true(result$ok)
  raw <- paste(readLines(audit_path, warn = FALSE), collapse = "\n")
  expect_false(grepl("secret-key", raw, fixed = TRUE))
  expect_false(grepl("解释这段代码", raw, fixed = TRUE))

  events <- read_workbench_audit_log(audit_path)
  expect_equal(events$command[[1]], "ai-task")
  expect_true(events$ok[[1]])
})

test_that("audit-log command reads recent audit events", {
  audit_path <- tempfile("rstudiozhai-audit-", fileext = ".jsonl")
  invisible(run_workbench_command("provider-status", list(provider = "local", audit_path = audit_path)))

  result <- run_workbench_command("audit-log", list(path = audit_path, limit = 5L))

  expect_true(result$ok)
  expect_equal(result$data$count, 1L)
  expect_equal(result$data$events$command[[1]], "provider-status")
  expect_match(result$data$markdown, "provider-status", fixed = TRUE)
})
