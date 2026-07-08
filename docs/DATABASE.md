# Database Design - Scheme Mate

This document outlines the relational database schema, indexes, key constraints, and extensible JSONB structures of **Scheme Mate — Your Smart Government Benefits Assistant**.

---

## 🗺️ Entity Relationship Overview

```mermaid
erDiagram
    users ||--o| profiles : "has eligibility profile"
    users ||--o{ schemes : "last updated by"
    users ||--o{ scheme_versions : "edited by"
    users ||--o{ saved_schemes : "saves bookmarks"
    users ||--o{ notifications : "receives alerts"
    users ||--o| notification_preferences : "configures preferences"
    users ||--o{ feedback : "submits bug report"
    schemes ||--o{ scheme_versions : "has change history log"

    users {
        uuid id PK
        varchar name
        varchar email UK
        varchar password_hash
        varchar role
        timestamp created_at
        timestamp updated_at
    }

    profiles {
        uuid id PK
        uuid user_id FK, UK
        date dob
        varchar gender
        varchar state
        varchar district
        varchar taluk
        varchar village_city
        varchar occupation
        varchar education
        numeric annual_income
        varchar marital_status
        varchar category
        boolean minority_status
        boolean disability_status
        boolean is_student
        boolean is_farmer
        boolean is_business_owner
        varchar bpl_apl_status
        jsonb documents
        jsonb extra_eligibility
        timestamp created_at
        timestamp updated_at
    }

    schemes {
        uuid id PK
        varchar name
        text description
        varchar state
        varchar category
        jsonb eligibility_rules
        varchar_array required_documents
        text benefits
        varchar official_website
        varchar application_link
        varchar pdf_notification_link
        varchar application_mode
        varchar status
        varchar sourceType
        varchar official_department
        date last_verified_date
        date start_date
        date end_date
        int views_count
        int saves_count
        varchar_array beneficiary_types
        varchar_array tags
        int version_number
        uuid last_updated_by FK
        timestamp created_at
        timestamp updated_at
    }

    saved_schemes {
        uuid id PK
        uuid user_id FK
        uuid scheme_id FK
        text private_note
        timestamp last_viewed_at
        timestamp created_at
    }

    notifications {
        uuid id PK
        uuid user_id FK
        varchar title
        text message
        varchar type
        varchar priority
        varchar target_type
        uuid target_id
        boolean is_read
        timestamp scheduled_at
        timestamp expires_at
        timestamp created_at
    }

    notification_preferences {
        uuid user_id PK, FK
        boolean notify_new_matches
        boolean notify_scheme_updates
        boolean notify_closing_soon
        boolean notify_profile_reminders
        boolean notify_system
        timestamp updated_at
    }

    feedback {
        uuid id PK
        uuid user_id FK
        varchar screen
        varchar type
        text details
        uuid target_id
        timestamp created_at
    }
```

---

## 1. Tables Specification

### A. `users` Table
Stores user account credentials.
* **id**: `UUID PRIMARY KEY DEFAULT gen_random_uuid()`
* **email**: `VARCHAR(255) UNIQUE` for authentication.
* **password_hash**: `VARCHAR(255)` hashed using bcryptjs.

### B. `profiles` Table
Stores user demographics and variables.
* **dob**: `DATE` (used to calculate age)
* **annual_income**: `NUMERIC(12, 2)` (precise exact values).
* **booleans**: `is_student`, `is_farmer`, `is_business_owner`, `disability_status`, `minority_status`.
* **documents**: `JSONB` checklist maps.

### C. `schemes` Table
Stores government benefit records.
* **eligibility_rules**: `JSONB` structured criteria mapping.
* **required_documents**: `VARCHAR(100)[]` checklist strings.

### D. `saved_schemes` Table
Stores bookmarks and private notes.
* **private_note**: `TEXT` optional user notes.

### E. `notifications` Table
Stores user alerts history records.
* **priority**: Low | Medium | High | Critical.
* **target_type**: scheme | profile | none.

### F. `feedback` Table
Stores bug reports and scheme corrections feedback.
* **type**: incorrect_scheme | bug | feature_request | missing_scheme.

---

## 2. Indexes and Optimization

1. **Email Lookup:** Unique B-Tree index on `users(email)`.
2. **Filtering Performance:** B-Tree indexes on `schemes(state)`, `schemes(category)`, and `schemes(status)`.
3. **Full-Text Search Index:** A GIN index on `schemes(name, description, benefits, department)`.
4. **Notifications Index:** B-Tree index on `notifications(user_id, is_read)` and `notifications(scheduled_at)`.
