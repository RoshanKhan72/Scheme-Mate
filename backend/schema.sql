-- PostgreSQL Schema for Scheme Mate (Complete Core Database)

-- Create Users Table with UUID Primary Key
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for fast user queries by email
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Create Profiles Table for eligibility matching
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dob DATE NOT NULL,
    gender VARCHAR(20) NOT NULL,
    state VARCHAR(100) NOT NULL,
    district VARCHAR(100) NOT NULL,
    taluk VARCHAR(100),
    village_city VARCHAR(100) NOT NULL,
    occupation VARCHAR(100) NOT NULL,
    education VARCHAR(100) NOT NULL,
    annual_income NUMERIC(12, 2) NOT NULL,
    marital_status VARCHAR(50) NOT NULL,
    category VARCHAR(50) NOT NULL,
    minority_status BOOLEAN DEFAULT FALSE,
    disability_status BOOLEAN DEFAULT FALSE,
    is_student BOOLEAN DEFAULT FALSE,
    is_farmer BOOLEAN DEFAULT FALSE,
    is_business_owner BOOLEAN DEFAULT FALSE,
    bpl_apl_status VARCHAR(20) DEFAULT 'None',
    documents JSONB DEFAULT '{}',
    extra_eligibility JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for profiles by user_id
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);

-- Create Schemes Table
CREATE TABLE IF NOT EXISTS schemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    state VARCHAR(100) NOT NULL, -- 'All India' or specific state name
    category VARCHAR(100) NOT NULL, -- e.g. 'Education', 'Agriculture', 'Healthcare', 'Welfare', 'Business'
    eligibility_rules JSONB DEFAULT '{}', -- structured eligibility matching conditions
    required_documents VARCHAR(100)[] DEFAULT '{}',
    benefits TEXT NOT NULL,
    official_website VARCHAR(255),
    application_link VARCHAR(255),
    pdf_notification_link VARCHAR(255),
    application_mode VARCHAR(20) DEFAULT 'Online' CHECK (application_mode IN ('Online', 'Offline', 'Both')),
    status VARCHAR(20) DEFAULT 'Open' CHECK (status IN ('Upcoming', 'Open', 'Closed', 'Suspended', 'Archived')),
    source_type VARCHAR(100) NOT NULL, -- 'Central Government' or 'State Government'
    official_department VARCHAR(100) NOT NULL,
    last_verified_date DATE,
    start_date DATE,
    end_date DATE,
    views_count INT DEFAULT 0,
    saves_count INT DEFAULT 0,
    beneficiary_types VARCHAR(50)[] DEFAULT '{}', -- e.g. {'Student', 'Farmer', 'Woman'}
    tags VARCHAR(50)[] DEFAULT '{}',
    version_number INT DEFAULT 1,
    last_updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexing for fast search and filter queries
CREATE INDEX IF NOT EXISTS idx_schemes_state ON schemes(state);
CREATE INDEX IF NOT EXISTS idx_schemes_category ON schemes(category);
CREATE INDEX IF NOT EXISTS idx_schemes_status ON schemes(status);

-- GIN Index for PostgreSQL Full-Text Search
CREATE INDEX IF NOT EXISTS idx_schemes_fts ON schemes USING gin(
    to_tsvector('english', name || ' ' || description || ' ' || benefits || ' ' || official_department)
);

-- Scheme Versions Table to preserve change histories
CREATE TABLE IF NOT EXISTS scheme_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    scheme_id UUID NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    version_number INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    eligibility_rules JSONB DEFAULT '{}',
    benefits TEXT NOT NULL,
    change_summary TEXT NOT NULL,
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for version lookup by scheme
CREATE INDEX IF NOT EXISTS idx_scheme_versions_scheme_id ON scheme_versions(scheme_id);

-- Create Saved Schemes Bookmarks Table
CREATE TABLE IF NOT EXISTS saved_schemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scheme_id UUID NOT NULL REFERENCES schemes(id) ON DELETE CASCADE,
    private_note TEXT,
    last_viewed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_user_scheme UNIQUE (user_id, scheme_id)
);

-- Index for fast bookmarks query lookup by user_id
CREATE INDEX IF NOT EXISTS idx_saved_schemes_user ON saved_schemes(user_id);

-- Create Notifications Table
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

-- Indexing for user read lookups and scheduled times
CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications(scheduled_at);

-- Create Notification Preferences Table
CREATE TABLE IF NOT EXISTS notification_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    notify_new_matches BOOLEAN DEFAULT TRUE,
    notify_scheme_updates BOOLEAN DEFAULT TRUE,
    notify_closing_soon BOOLEAN DEFAULT TRUE,
    notify_profile_reminders BOOLEAN DEFAULT TRUE,
    notify_system BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create User Feedback & Bug Reports Table
CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    screen VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('incorrect_scheme', 'bug', 'feature_request', 'missing_scheme')),
    details TEXT NOT NULL,
    target_id UUID DEFAULT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for feedback query lookups
CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(type);
