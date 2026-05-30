library(DBI)
library(odbc)

con <- dbConnect(
  odbc::odbc(),
  dsn = "${0:DSN=}",
  uid = "${1:User=}",
  pwd = rstudioapi::askForPassword("ODBC password")
)

con
