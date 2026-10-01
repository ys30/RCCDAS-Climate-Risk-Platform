-- RCCDAS private PostgreSQL schema
CREATE SCHEMA IF NOT EXISTS rccdas;

CREATE TABLE IF NOT EXISTS rccdas.dataset_registry (
    table_name  text PRIMARY KEY,
    source_file text NOT NULL,
    imported_at timestamptz NOT NULL DEFAULT now(),
    row_count   bigint,
    notes       text
);

REVOKE ALL ON SCHEMA rccdas FROM PUBLIC;
