# Private PostgreSQL setup

RCCDAS can run from local CSVs or a private PostgreSQL database.

## 1. Create the schema

Run `sql/schema.sql` against the private database.

## 2. Set credentials

Copy `.Renviron.example` to `.Renviron` locally and fill in the real values. Never commit `.Renviron`.

## 3. Import the current dashboard datasets

Keep the private CSVs under `data/`, then run:

```r
source("sql/import_to_postgres.R")
```

Each source file becomes a table in the private `rccdas` schema.

Example:

`climate_conditions_Beijing.csv` → `rccdas.climate_conditions_beijing`

## 4. Switch the app to SQL

Set:

```text
RCCDAS_DATA_BACKEND=postgres
```

The app then reads the same logical datasets through `R/data_access.R`.

## 5. Production security

Use two roles:
- an import/admin role with write privileges;
- a deployed Shiny role with read-only access to the `rccdas` schema.

Require SSL and keep all credentials outside GitHub.
