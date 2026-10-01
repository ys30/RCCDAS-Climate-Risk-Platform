# RCCDAS data access layer
# Backend:
#   RCCDAS_DATA_BACKEND=csv       (default)
#   RCCDAS_DATA_BACKEND=postgres

rccdas_backend <- function() {
  tolower(Sys.getenv("RCCDAS_DATA_BACKEND", "csv"))
}

rccdas_table_name <- function(filename) {
  stem <- tools::file_path_sans_ext(basename(filename))
  tolower(gsub("[^A-Za-z0-9]+", "_", stem))
}

rccdas_db_connect <- function() {
  if (!requireNamespace("DBI", quietly = TRUE) ||
      !requireNamespace("RPostgres", quietly = TRUE)) {
    stop("PostgreSQL backend requires packages DBI and RPostgres.")
  }

  required <- c("DB_HOST", "DB_NAME", "DB_USER", "DB_PASSWORD")
  missing <- required[Sys.getenv(required) == ""]
  if (length(missing)) {
    stop("Missing database environment variable(s): ",
         paste(missing, collapse = ", "))
  }

  DBI::dbConnect(
    RPostgres::Postgres(),
    host = Sys.getenv("DB_HOST"),
    dbname = Sys.getenv("DB_NAME"),
    user = Sys.getenv("DB_USER"),
    password = Sys.getenv("DB_PASSWORD"),
    port = as.integer(Sys.getenv("DB_PORT", "5432")),
    sslmode = Sys.getenv("DB_SSLMODE", "require")
  )
}

read_dashboard_csv <- function(filename, ...) {
  if (rccdas_backend() != "postgres") {
    return(utils::read.csv(file.path("data", filename), ...))
  }

  con <- rccdas_db_connect()
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  schema <- Sys.getenv("DB_SCHEMA", "rccdas")
  table <- rccdas_table_name(filename)
  id <- DBI::Id(schema = schema, table = table)

  if (!DBI::dbExistsTable(con, id)) {
    stop("Database table not found: ", schema, ".", table)
  }

  DBI::dbReadTable(con, id)
}
