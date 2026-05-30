library(rstudiozhai)

fail <- function(message) {
  stop(message, call. = FALSE)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) fail(message)
}

assert_named <- function(object, name) {
  assert_true(name %in% names(object), paste0("Expected name missing: ", name))
}

cat("Running installed package tests...\n")

report <- collect_environment_report(packages = c("stats", "definitely_missing_pkg_zzzz"))
assert_named(report, "r")
assert_named(report, "rstudio")
assert_named(report, "quarto")
assert_named(report, "packages")
assert_named(report, "suggestions")
assert_true(isTRUE(report$r$ok), "R should be available")

pkg_names <- vapply(report$packages, function(pkg) pkg$name, character(1))
pkg_status <- vapply(report$packages, function(pkg) pkg$installed, logical(1))
assert_true(pkg_status[match("stats", pkg_names)], "stats package should be installed")
assert_true(!pkg_status[match("definitely_missing_pkg_zzzz", pkg_names)], "fake package should be missing")
assert_true(length(report$suggestions) >= 1L, "missing package should produce suggestions")

markdown <- format_environment_report(report)
expected_title <- "RStudio \u4e2d\u6587 AI \u5de5\u4f5c\u53f0\u73af\u5883\u62a5\u544a"
assert_true(grepl(expected_title, markdown, fixed = TRUE), "report title missing")

request <- build_ai_task_request(
  task = "\u89e3\u91ca\u8fd9\u4e2a R \u62a5\u9519",
  mode = "explain",
  context = list(error = "object not found")
)
assert_true(identical(request$safety$require_user_confirmation, TRUE), "confirmation should default to TRUE")

empty_task_failed <- FALSE
tryCatch(
  build_ai_task_request(""),
  error = function(e) empty_task_failed <<- TRUE
)
assert_true(empty_task_failed, "empty task should fail")

mock_provider <- function(req) {
  list(
    ok = TRUE,
    content = paste("mock", req$task),
    proposed_files = list(),
    warnings = character(),
    raw = req
  )
}

response <- invoke_ai_provider(request, mock_provider)
assert_true(isTRUE(response$ok), "mock provider should return ok")
assert_true(nzchar(response$content), "mock provider should return content")

bad_provider_failed <- FALSE
tryCatch(
  invoke_ai_provider(request, function(req) list(ok = TRUE, content = "")),
  error = function(e) bad_provider_failed <<- TRUE
)
assert_true(bad_provider_failed, "bad provider should fail contract validation")

cat("Installed package tests passed.\n")
