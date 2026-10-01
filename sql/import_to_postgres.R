# Import RCCDAS dashboard CSVs into private PostgreSQL.
# Run from the project root after setting DB_* environment variables.

if (!requireNamespace("DBI", quietly = TRUE) ||
    !requireNamespace("RPostgres", quietly = TRUE)) {
  stop("Install DBI and RPostgres first.")
}

source("R/data_access.R")
con <- rccdas_db_connect()
on.exit(DBI::dbDisconnect(con), add = TRUE)

schema <- Sys.getenv("DB_SCHEMA", "rccdas")
DBI::dbExecute(
  con,
  paste("CREATE SCHEMA IF NOT EXISTS",
        DBI::dbQuoteIdentifier(con, schema))
)

registry <- DBI::Id(schema = schema, table = "dataset_registry")
if (!DBI::dbExistsTable(con, registry)) {
  DBI::dbExecute(con, paste0(
    "CREATE TABLE ",
    DBI::dbQuoteIdentifier(con, registry),
    " (table_name text PRIMARY KEY, source_file text NOT NULL, ",
    "imported_at timestamptz NOT NULL DEFAULT now(), ",
    "row_count bigint, notes text)"
  ))
}

files <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
if (!length(files)) stop("No CSV files found under ./data")

for (path in files) {
  filename <- basename(path)
  table <- rccdas_table_name(filename)
  message("Importing ", filename, " -> ", schema, ".", table)

  x <- utils::read.csv(path, check.names = FALSE)
  if ("Unnamed: 0" %in% names(x)) x[["Unnamed: 0"]] <- NULL

  id <- DBI::Id(schema = schema, table = table)
  DBI::dbWriteTable(con, id, x, overwrite = TRUE, row.names = FALSE)

  sql <- paste0(
    "INSERT INTO ", DBI::dbQuoteIdentifier(con, registry),
    " (table_name, source_file, imported_at, row_count) ",
    "VALUES ($1,$2,now(),$3) ",
    "ON CONFLICT (table_name) DO UPDATE SET ",
    "source_file=EXCLUDED.source_file, imported_at=now(), ",
    "row_count=EXCLUDED.row_count"
  )
  DBI::dbExecute(con, sql, params = list(table, filename, nrow(x)))
}

message("RCCDAS import complete.")
