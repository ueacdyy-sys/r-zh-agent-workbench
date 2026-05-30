connection_template_catalog <- function() {
  data.frame(
    id = c("sqlite", "postgres", "odbc"),
    label = c("SQLite Local", "PostgreSQL DBI", "ODBC DSN"),
    package = c("RSQLite", "RPostgres", "odbc"),
    file = c("sqlite-local.R", "postgresql-dbi.R", "odbc-dsn.R"),
    stringsAsFactors = FALSE
  )
}

list_connection_templates <- function() {
  connection_template_catalog()
}

connection_snippet_dir <- function() {
  path <- system.file("rstudio", "connections", package = "rstudiozhai")
  if (!nzchar(path)) {
    local_path <- file.path("inst", "rstudio", "connections")
    if (dir.exists(local_path)) {
      return(normalizePath(local_path, winslash = "/", mustWork = TRUE))
    }
    stop("connection snippets directory not found", call. = FALSE)
  }
  path
}

connection_snippet_path <- function(id) {
  catalog <- connection_template_catalog()
  row <- catalog[tolower(catalog$id) == tolower(id), , drop = FALSE]
  if (!nrow(row)) {
    stop("unknown connection template id", call. = FALSE)
  }
  file.path(connection_snippet_dir(), row$file[[1]])
}

read_connection_snippet <- function(id) {
  path <- connection_snippet_path(id)
  paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
}

build_dbi_connection_code <- function(kind,
                                      variable = "con",
                                      use_password_prompt = TRUE) {
  kind <- tolower(kind)
  if (!kind %in% c("sqlite", "postgres", "odbc")) {
    stop("kind must be one of sqlite, postgres, odbc", call. = FALSE)
  }
  if (!is.character(variable) || length(variable) != 1L || !grepl("^[A-Za-z.][A-Za-z0-9._]*$", variable)) {
    stop("variable must be a valid R object name", call. = FALSE)
  }

  password <- if (isTRUE(use_password_prompt)) {
    'rstudioapi::askForPassword("Database password")'
  } else {
    'Sys.getenv("DB_PASSWORD")'
  }

  lines <- switch(
    kind,
    sqlite = c(
      "library(DBI)",
      "library(RSQLite)",
      "",
      paste0(variable, " <- DBI::dbConnect("),
      "  RSQLite::SQLite(),",
      "  dbname = \"local.sqlite\"",
      ")"
    ),
    postgres = c(
      "library(DBI)",
      "library(RPostgres)",
      "",
      paste0(variable, " <- DBI::dbConnect("),
      "  RPostgres::Postgres(),",
      "  host = Sys.getenv(\"DB_HOST\", \"localhost\"),",
      "  port = as.integer(Sys.getenv(\"DB_PORT\", \"5432\")),",
      "  dbname = Sys.getenv(\"DB_NAME\", \"postgres\"),",
      "  user = Sys.getenv(\"DB_USER\", \"postgres\"),",
      paste0("  password = ", password),
      ")"
    ),
    odbc = c(
      "library(DBI)",
      "library(odbc)",
      "",
      paste0(variable, " <- DBI::dbConnect("),
      "  odbc::odbc(),",
      "  dsn = Sys.getenv(\"ODBC_DSN\"),",
      "  uid = Sys.getenv(\"DB_USER\"),",
      paste0("  pwd = ", password),
      ")"
    )
  )

  paste(lines, collapse = "\n")
}

connection_dcf_path <- function() {
  path <- system.file("rstudio", "connections.dcf", package = "rstudiozhai")
  if (!nzchar(path)) {
    local_path <- file.path("inst", "rstudio", "connections.dcf")
    if (file.exists(local_path)) {
      return(normalizePath(local_path, winslash = "/", mustWork = TRUE))
    }
    stop("connections.dcf not found", call. = FALSE)
  }
  path
}
