-- Plantilla con PostGIS y extensiones habituales (locale es-CL, ICU).
CREATE DATABASE template_full_cl
    WITH
        OWNER = postgres
        TEMPLATE = template0
        ENCODING = 'UTF8'
        LOCALE_PROVIDER = icu
        ICU_LOCALE = 'es-CL'
        TABLESPACE = pg_default
        CONNECTION LIMIT = -1
        IS_TEMPLATE = true;

ALTER DATABASE template_full_cl SET default_text_search_config = 'pg_catalog.spanish';

\connect template_full_cl

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_raster;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
CREATE EXTENSION IF NOT EXISTS postgis_sfcgal;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS unaccent;
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch;
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS btree_gin;
CREATE EXTENSION IF NOT EXISTS hstore;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
