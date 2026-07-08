-- Up Migration: Create Feedback & Bug Reports tables
CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    screen VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('incorrect_scheme', 'bug', 'feature_request', 'missing_scheme')),
    details TEXT NOT NULL,
    target_id UUID DEFAULT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(type);
