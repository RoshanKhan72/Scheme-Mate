-- Down Migration: Rollback indexes
DROP INDEX IF EXISTS idx_saved_schemes_user;
DROP INDEX IF EXISTS idx_profiles_user;
DROP INDEX IF EXISTS idx_schemes_category;
DROP INDEX IF EXISTS idx_schemes_state;
