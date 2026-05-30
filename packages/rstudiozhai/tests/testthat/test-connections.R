test_that("connection template catalog and snippets are bundled", {
  catalog <- list_connection_templates()

  expect_equal(catalog$id, c("sqlite", "postgres", "odbc"))
  expect_true(file.exists(connection_dcf_path()))
  expect_true(dir.exists(connection_snippet_dir()))
  expect_true(file.exists(connection_snippet_path("sqlite")))
  expect_match(read_connection_snippet("postgres"), "RPostgres", fixed = TRUE)
})

test_that("DBI connection code avoids hard-coded passwords", {
  postgres <- build_dbi_connection_code("postgres", variable = "db")
  odbc <- build_dbi_connection_code("odbc", use_password_prompt = FALSE)

  expect_match(postgres, "DBI::dbConnect", fixed = TRUE)
  expect_match(postgres, "rstudioapi::askForPassword", fixed = TRUE)
  expect_match(odbc, "Sys.getenv(\"DB_PASSWORD\")", fixed = TRUE)
  expect_error(build_dbi_connection_code("unknown"), "kind must")
  expect_error(build_dbi_connection_code("sqlite", variable = "bad-name"), "valid R object")
})
