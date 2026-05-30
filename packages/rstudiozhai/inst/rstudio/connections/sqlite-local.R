library(DBI)
library(RSQLite)

con <- dbConnect(
  RSQLite::SQLite(),
  dbname = "${0:SQLite file=:memory:}"
)

con
