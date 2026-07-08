CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(150) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('eligibility', 'saved_scheme', 'system', 'profile')),
    priority VARCHAR(20) DEFAULT 'Medium' CHECK (priority IN ('Low', 'Medium', 'High', 'Critical')),
    target_type VARCHAR(50) DEFAULT 'none' CHECK (target_type IN ('scheme', 'profile', 'none')),
    target_id UUID DEFAULT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    scheduled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications(scheduled_at);

CREATE TABLE IF NOT EXISTS notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    notify_new_matches BOOLEAN DEFAULT TRUE,
    notify_scheme_updates BOOLEAN DEFAULT TRUE,
    notify_closing_soon BOOLEAN DEFAULT TRUE,
    notify_profile_reminders BOOLEAN DEFAULT TRUE,
    notify_system BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
