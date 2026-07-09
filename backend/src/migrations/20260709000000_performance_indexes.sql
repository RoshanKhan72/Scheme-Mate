-- Up Migration: Add indexes for performance optimization
CREATE INDEX IF NOT EXISTS idx_saved_schemes_user ON saved_schemes(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_user ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_schemes_category ON schemes(category);
CREATE INDEX IF NOT EXISTS idx_schemes_state ON schemes(state);
