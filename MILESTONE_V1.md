# Milestone Freeze - Scheme Mate v1.0

This document certifies the release of **Scheme Mate v1.0** and verifies the correctness, stability, and integration of all core modules implemented so far.

---

## 🏁 Verification Checklist

| Target Module | Verification Parameter | Status | Verification Detail |
| :--- | :--- | :--- | :--- |
| **Authentication** | JWT creation, hashing, password strength, login, logout. | **PASSED** ✅ | Session keys are securely generated via JSON Web Tokens, stored in SharedPreferences on client, and cleared upon logout. |
| **User Profile** | Socioeconomic demographic fields, age calculation from DOB, completion score metrics. | **PASSED** ✅ | Age is calculated dynamically on both front-end and backend. completion percentage warns of missing socioeconomic inputs. |
| **Scheme Database** | GIN index Full-Text search, admin CRUD validation, version logs transactions. | **PASSED** ✅ | transactional edits commit to both `schemes` and `scheme_versions` tables with change comments. |
| **Eligibility Engine** | Demographic/economic rule evaluation, matched statuses, mismatch explanations. | **PASSED** ✅ | Rule evaluation returns structured check outputs mapping rule IDs. Matches are categorized by status with confidence scores. |
| **Personalized Dashboard** | Action-oriented priority card, metric counts, lightweight feed slices, deadlines. | **PASSED** ✅ | Priority cards highlight next profile steps. Feeds retrieve up to 3 items sorted by nearest end-date. |
| **Search & Filters** | Category, state, and beneficiary filters. FTS keyword matches. | **PASSED** ✅ | Search filters operate both publicly (browse feed) and authenticated (matched feeds). |
| **API Documentation** | Swagger/OpenAPI specifications, JSDoc integration. | **PASSED** ✅ | Interactive Swagger documentation is hosted locally at `/api-docs` rendering structural schemas. |
| **Database Recovery** | Backup generation and restoration validation. | **PASSED** ✅ | Verified standard pg_dump backup extraction and psql migration execution. |

---

## 💾 Database Backup & Restoration Protocol

To verify the backup integrity, follow these standard PostgreSQL recovery console actions:

### 1. Generating V1.0 SQL Backup File
Run this command from your terminal to backup the entire `schememate` database (including profiles, schemes, and versions logs):
```bash
pg_dump -U postgres -d schememate -F p -b -v -f "d:/Projects/Scheme Mate/backend/schememate_v1.0_backup.sql"
```

### 2. Restoring from SQL Backup File
In case of server transfers or local system failures, follow these commands to rebuild the state:
```bash
# Log into PostgreSQL console
psql -U postgres

# Drop existing database to ensure clean recovery
DROP DATABASE IF EXISTS schememate;
CREATE DATABASE schememate;
\q

# Restore from backup file
psql -U postgres -d schememate -f "d:/Projects/Scheme Mate/backend/schememate_v1.0_backup.sql"
```

This procedure has been executed locally, and database consistency is verified. Scheme Mate v1.0 is officially frozen as a stable milestone baseline.
