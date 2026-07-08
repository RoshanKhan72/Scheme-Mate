-- Up Migration: Initial Scheme Mate schema
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email ON users(email);

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

CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);

CREATE TABLE IF NOT EXISTS schemes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    state VARCHAR(100) NOT NULL,
    category VARCHAR(100) NOT NULL,
    eligibility_rules JSONB DEFAULT '{}',
    required_documents VARCHAR(100)[] DEFAULT '{}',
    benefits TEXT NOT NULL,
    official_website VARCHAR(255),
    application_link VARCHAR(255),
    pdf_notification_link VARCHAR(255),
    application_mode VARCHAR(20) DEFAULT 'Online' CHECK (application_mode IN ('Online', 'Offline', 'Both')),
    status VARCHAR(20) DEFAULT 'Open' CHECK (status IN ('Upcoming', 'Open', 'Closed', 'Suspended', 'Archived')),
    source_type VARCHAR(100) NOT NULL,
    official_department VARCHAR(100) NOT NULL,
    last_verified_date DATE,
    start_date DATE,
    end_date DATE,
    views_count INT DEFAULT 0,
    saves_count INT DEFAULT 0,
    beneficiary_types VARCHAR(50)[] DEFAULT '{}',
    tags VARCHAR(50)[] DEFAULT '{}',
    version_number INT DEFAULT 1,
    last_updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_schemes_state ON schemes(state);
CREATE INDEX IF NOT EXISTS idx_schemes_category ON schemes(category);
CREATE INDEX IF NOT EXISTS idx_schemes_status ON schemes(status);
CREATE INDEX IF NOT EXISTS idx_schemes_fts ON schemes USING gin(
    to_tsvector('english', name || ' ' || description || ' ' || benefits || ' ' || official_department)
);

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

CREATE INDEX IF NOT EXISTS idx_scheme_versions_scheme_id ON scheme_versions(scheme_id);
