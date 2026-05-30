test_that("MCP tool catalog wraps workbench commands with stable names", {
  tools <- mcp_tool_definitions()
  names <- vapply(tools, function(tool) tool$name, character(1))

  expect_true(all(c(
    "rstudiozhai_list_commands",
    "rstudiozhai_diagnostics",
    "rstudiozhai_provider_status",
    "rstudiozhai_rstudio_extension_status",
    "rstudiozhai_project_scan",
    "rstudiozhai_audit_log",
    "rstudiozhai_search_knowledge",
    "rstudiozhai_run_ai_task",
    "rstudiozhai_create_quarto_draft",
    "rstudiozhai_connection_template"
  ) %in% names))

  draft <- tools[[match("rstudiozhai_create_quarto_draft", names)]]
  expect_false(draft$annotations$readOnlyHint)
  expect_false(draft$annotations$destructiveHint)
  expect_true(draft$annotations$idempotentHint)
})

test_that("MCP initialize and tools/list return JSON-RPC responses", {
  init <- mcp_handle_request(list(
    jsonrpc = "2.0",
    id = 1,
    method = "initialize",
    params = list(protocolVersion = "2025-11-25")
  ))

  expect_equal(init$jsonrpc, "2.0")
  expect_equal(init$id, 1)
  expect_equal(init$result$protocolVersion, "2025-11-25")
  expect_true("tools" %in% names(init$result$capabilities))

  listed <- mcp_handle_request(list(
    jsonrpc = "2.0",
    id = "tools",
    method = "tools/list",
    params = list()
  ))
  expect_equal(listed$id, "tools")
  expect_true(length(listed$result$tools) >= 6L)
  expect_true("inputSchema" %in% names(listed$result$tools[[1L]]))
})

test_that("MCP tools/call invokes the middleware command layer", {
  skip_if_not_installed("jsonlite")

  response <- mcp_handle_request(list(
    jsonrpc = "2.0",
    id = 2,
    method = "tools/call",
    params = list(
      name = "rstudiozhai_search_knowledge",
      arguments = list(query = "quarto", response_format = "json")
    )
  ))

  expect_equal(response$id, 2)
  expect_false(response$result$isError)
  expect_equal(response$result$content[[1L]]$type, "text")

  decoded <- jsonlite::fromJSON(response$result$content[[1L]]$text)
  expect_true(decoded$ok)
  expect_equal(decoded$command, "knowledge")
})

test_that("MCP tool errors are reported as tool results", {
  response <- mcp_handle_request(list(
    jsonrpc = "2.0",
    id = 3,
    method = "tools/call",
    params = list(
      name = "rstudiozhai_create_quarto_draft",
      arguments = list(task = "写报告但没有授权写文件")
    )
  ))

  expect_equal(response$id, 3)
  expect_true(response$result$isError)
  expect_match(response$result$content[[1L]]$text, "WRITE_NOT_ALLOWED")
})

test_that("MCP protocol errors and notifications are handled", {
  missing <- mcp_handle_request(list(
    jsonrpc = "2.0",
    id = 4,
    method = "unknown/method",
    params = list()
  ))
  expect_equal(missing$error$code, -32601)

  notification <- mcp_handle_request(list(
    jsonrpc = "2.0",
    method = "notifications/initialized",
    params = list()
  ))
  expect_null(notification)
})

test_that("MCP JSON line helper processes one request", {
  skip_if_not_installed("jsonlite")

  input <- '{"jsonrpc":"2.0","id":5,"method":"tools/list","params":{}}'
  output <- mcp_handle_json_line(input)
  decoded <- jsonlite::fromJSON(output, simplifyVector = FALSE)

  expect_equal(decoded$id, 5)
  expect_true(length(decoded$result$tools) >= 6L)
  expect_match(output, '"audit_path"')
  expect_match(output, '"required":\\["query"\\]')
})

test_that("MCP stdio server reads JSON lines from an input connection", {
  skip_if_not_installed("jsonlite")

  input <- textConnection('{"jsonrpc":"2.0","id":6,"method":"ping","params":{}}')
  output_value <- character()
  output <- textConnection("output_value", "w", local = TRUE)
  on.exit(close(input), add = TRUE)

  expect_true(mcp_stdio_server(input = input, output = output))
  close(output)
  decoded <- jsonlite::fromJSON(output_value[[1L]], simplifyVector = FALSE)
  expect_equal(decoded$id, 6)
  expect_true(is.list(decoded$result))
})
