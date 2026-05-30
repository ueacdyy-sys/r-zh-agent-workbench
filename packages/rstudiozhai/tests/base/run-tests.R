root <- normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  root <- normalizePath(file.path(getwd(), "rstudio-zh-ai-workbench"), winslash = "/", mustWork = TRUE)
}

source(file.path(root, "R", "diagnostics.R"), encoding = "UTF-8")
source(file.path(root, "R", "ai_contracts.R"), encoding = "UTF-8")

fail <- function(message) {
  stop(message, call. = FALSE)
}

assert_true <- function(value, message) {
  if (!isTRUE(value)) fail(message)
}

assert_named <- function(object, name) {
  assert_true(name %in% names(object), paste0("Expected name missing: ", name))
}

cat("Running base tests...\n")

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
assert_true(grepl("RStudio 中文 AI 工作台环境报告", markdown, fixed = TRUE), "report title missing")

request <- build_ai_task_request(
  task = "解释这个 R 报错",
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

response <- invoke_ai_provider(request, mock_ai_provider)
assert_true(isTRUE(response$ok), "mock provider should return ok")
assert_true(nzchar(response$content), "mock provider should return content")

bad_provider_failed <- FALSE
tryCatch(
  invoke_ai_provider(request, function(req) list(ok = TRUE, content = "")),
  error = function(e) bad_provider_failed <<- TRUE
)
assert_true(bad_provider_failed, "bad provider should fail contract validation")

cat("All base tests passed.\n")

