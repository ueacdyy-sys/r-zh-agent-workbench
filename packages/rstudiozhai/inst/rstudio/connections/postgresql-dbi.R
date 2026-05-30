library(DBI)
library(RPostgres)

con <- dbConnect(
  RPostgres::Postgres(),
  host = "${0:Host=localhost}",
  port = ${1:Port=5432},
  dbname = "${2:Database=postgres}",
  user = "${3:User=postgres}",
  password = rstudioapi::askForPassword("PostgreSQL password")
)

con
