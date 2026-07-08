# Contributing to Scheme Mate

This document outlines the coding standards, repository folder structure, branching strategies, naming conventions, and pull request workflows for **Scheme Mate**.

Adhering to these standards ensures our codebase remains clean, readable, and easy to maintain as the team and application scale.

---

## 📂 Project Folder Structure

We follow a clean, decoupled architecture on both backend and frontend layers:

### 1. Backend Structure (Node.js + Express)
```
backend/
├── src/
│   ├── config/       # Databases pools and Swagger configuration
│   ├── controllers/  # Request validation, response mapping (thin controllers)
│   ├── middleware/   # Authentication filters, role guards, error handlers
│   ├── models/       # Raw database access SQL queries (Repository layer)
│   ├── routes/       # Endpoint path registers (Versioned under /api/v1)
│   ├── services/     # Decoupled business logic service layers
│   ├── utils/        # Mathematical solvers, eligibility engine helper functions
│   ├── app.js        # Express middleware setup and router mount points
│   └── index.js      # Server entry point
```

### 2. Frontend Structure (Flutter Clean Architecture)
```
frontend/
├── assets/           # Location JSON cascades, fonts, local images
├── lib/
│   ├── core/         # Unified themes, HTTP clients, and base API constants
│   └── features/     # Feature-focused modules (Auth, Profile, Dashboard, Schemes)
│       ├── data/     # Datasources (API calls) and Repository implementations
│       ├── domain/   # Decoupled Entities and Repository contracts
│       └── presentation/
│           ├── providers/ # Riverpod state notifier graphs
│           └── screens/   # M3 widget pages and forms bottom sheets
```

---

## 🏷️ Naming Conventions

### 1. File and Folder Names
*   **Javascript (Backend):** Use `camelCase` for variables/functions and `camelCase` (e.g. `schemeController.js`) for filenames.
*   **Dart (Frontend):** Use `snake_case` (e.g. `scheme_detail_screen.dart`) for filenames and folders.

### 2. Database Columns
*   Use `snake_case` for all PostgreSQL table and column names (e.g. `user_id`, `saved_schemes`).

### 3. Classes and Types
*   Use `PascalCase` for Javascript classes and Dart classes/enums (e.g. `SchemeDetailScreen`, `SavedNotifier`).

---

## 🌿 Git Branching & Commit Guidelines

### 1. Branching Strategy
We use a lightweight feature-branch workflow. Merge target is always `main`.
*   `feature/feature-name` (e.g. `feature/saved-schemes`) for new modules.
*   `bugfix/issue-name` (e.g. `bugfix/auth-token-refresh`) for debugging patches.
*   `hotfix/issue-name` for direct production updates.

### 2. Commit Message Style
Commit messages should be descriptive, prefixing target feature scopes:
```text
feat(saved): add bookmarks notes and confirmation unsave modal triggers
fix(auth): resolve JWT expiration null pointer checks in remote datasource
docs(engine): create RULE_ENGINE.md detailing evaluation priorities
```

---

## 🔍 Pull Request & Code Review Checklist

Before submitting a Pull Request (PR) or merging changes, verify:

1.  **Code Compiles:** All files must compile without warnings or syntax errors.
2.  **API Versioning:** All newly created REST routes must route under `/api/v1`.
3.  **JSDoc Swagger Spec:** Every controller route must contain OpenAPI metadata.
4.  **Decoupled Services:** Business logic (like eligibility evaluations and dashboard metrics aggregation) must live in `services/`, not controllers or models.
5.  **Offline Compliance:** All matching frontend listing providers must support offline cache fallbacks using `SharedPreferences`.
