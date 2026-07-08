-- Down Migration: Drop initial schema tables
DROP TABLE IF EXISTS scheme_versions CASCADE;
DROP TABLE IF EXISTS schemes CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;
