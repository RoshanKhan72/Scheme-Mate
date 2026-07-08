# Changelog

All notable changes to **Scheme Mate** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-07-02

### Added
*   **Authentication Module:** JWT tokens creation, password bcrypt hashing, protected middleware routes, and Flutter user authentication/registration validation forms.
*   **User Profile Module:** demographic parameters (marital status, categories, occupations), DOB age solvers, cascading dropdown location assets, document checklists, and completion metric indicators.
*   **Scheme Database Module:** GIN index full-text search across names, descriptions, and benefits, transactional administrative CRUD snapshots, and view/save metrics increments.
*   **Rule-Based Eligibility Engine Module:** config-driven eligibility checks, match score metrics, confidence evaluations, duplicate suppressions, and structured checklist indicators mapping rule IDs.
*   **Personalized Dashboard Module:** action-oriented priority cards, lightweight feeds compilation (Recommended, New, Trending, Closing Soon), local SharedPreferences recently viewed caching, and foldout demographics panels.
*   **Saved Schemes Module:** transaction bookmark toggles, private save note parameters, save dates, sort/filter options, pull-to-refresh offline mode containers, and deadline alert warnings.
*   **Decoupled Notifications Module:** central notification event service, scheduled alert checks, priority flags, target deep links, user preference suppression tables, and read-all endpoints.
*   **Feedback & Bug Report Module:** user-initiated bug reporting, incorrect scheme alerts, structured error logging, and dialog overlay forms.
*   **Structured Logging System:** colorized standard output console logs and JSON-line local files logs with unhandled exceptions integrations.

### Changed
*   **API Versioning:** Upgraded all Express routes and Flutter Constant links to route under `/api/v1` prefixes.
*   **Architecture Pattern:** Migrated business logic out of controllers into a decoupled `/services` layer.

### Fixed
*   Resolved parameterized detail path route conflicts by placing static matching routes before parameterized lookups in scheme routing registers.
*   Optimized database query performance on the dashboard by combining profiles and schemes queries into exactly 2 lookups, resolving matches in-memory.
