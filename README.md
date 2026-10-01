# RCCDAS — Climate Risk & Adaptation Platform

RCCDAS is an interactive R/Shiny decision-support platform for exploring climate conditions, sector-specific physical damages, economy-wide impacts, and adaptation pathways across Beijing, Tianjin, and Hebei under SSP climate scenarios.

**Live dashboard:** https://k12gy8-song-ariel0yu.shinyapps.io/multi_page/

## What the platform connects

`Climate scenarios → physical damage functions → regional economic impacts → adaptation strategies`

The public repository contains the application layer and database-access code. Full model outputs, intermediate GAMS files, private CSV datasets, and database credentials are intentionally excluded.

## Architecture

- **Frontend:** R Shiny
- **Scenarios:** SSP126, SSP245, SSP370, SSP585
- **Regions:** Beijing, Tianjin, Hebei
- **Impact layers:** climate conditions, sector damages, regional economic impacts, adaptation
- **Data access:** local CSV fallback or **private PostgreSQL**
- **Security model:** public code + private data + environment-based credentials

## Private PostgreSQL setup

1. Create a private PostgreSQL database.
2. Copy `.Renviron.example` to a secure local `.Renviron` and fill in credentials.
3. Keep the current dashboard CSV files under `data/` locally.
4. Run:

```r
source("sql/import_to_postgres.R")
```

5. Set `RCCDAS_DATA_BACKEND=postgres` before starting the app.

The importer creates one private table per dashboard CSV under the `rccdas` schema and records import metadata in `rccdas.dataset_registry`.

## Repository structure

```text
RCCDAS-Climate-Risk-Platform/
├── app.R
├── R/
│   └── data_access.R
├── sql/
│   ├── schema.sql
│   └── import_to_postgres.R
├── www/
│   └── aiam-modern.css
├── .Renviron.example
└── .gitignore
```

## Local run

Required packages include `shiny`, `ggplot2`, `dplyr`, `DBI`, and `RPostgres` when using PostgreSQL.

```r
shiny::runApp()
```

## Data privacy

The public repository does **not** contain the full climate/model data. Use a private PostgreSQL service for deployment data and a read-only application role for the Shiny app.
