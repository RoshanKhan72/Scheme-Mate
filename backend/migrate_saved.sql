CREATE TABLE IF NOT EXISTS saved_schemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    private_note TEXT,
    last_viewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_scheme UNIQUE (user_id, scheme_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_schemes_user ON saved_schemes(user_id);
