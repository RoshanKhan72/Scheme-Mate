# Scheme Mate Security Policy

This document outlines the security architecture, configurations, and procedures for **Scheme Mate**.

---

## 1. Supported Environments & Software Versions

We actively support security updates for the following runtime and tool versions:

| Software | Version | Support Status |
| :--- | :--- | :--- |
| **Node.js** | `>= 20.x` | Supported (LTS) |
| **Flutter SDK** | `3.44.x` | Supported (Stable) |
| **PostgreSQL** | `>= 15.x` | Supported (Cloud/Neon) |

---

## 2. Secrets Management

All credentials, access keys, and passwords **MUST** be loaded strictly through environment variables.
- Secrets must never be hardcoded in codebase files.
- The Express backend loads variables from a local `.env` file (which is ignored by Git in `.gitignore`) and checks for presence during system startup.
- Key secrets include:
  - `DATABASE_URL`: Connection string containing cloud database credentials.
  - `JWT_SECRET`: Secret key for authentication token signatures.
  - `NODE_ENV`: Production mode switch controlling error trace exposure.

---

## 3. Threat Protections & Configuration

### A. Rate Limiting (IP-based)
To prevent brute-force attacks and denial-of-service, the Express gateway applies the following rules:
- **Login endpoint (`/api/v1/auth/login`)**: Max 5 requests per 15 minutes.
- **Registration endpoint (`/api/v1/auth/register`)**: Max 10 requests per 15 minutes.
- **General API endpoints (`/api/*`)**: Max 100 requests per 15 minutes.

### B. Payload Size Restraints
- Incoming request bodies parsed as JSON or URL-encoded are capped at **`10kb`** to avoid memory exhaustion attacks.

### C. SQL Injection Shielding
- All SQL transactions utilize **parameterized placeholder mappings** (e.g. `$1`, `$2`) to separate SQL execution structures from dynamic client parameters. String concatenation inside SQL strings is strictly prohibited.

### D. Input Validation & Password Complexity
Input checks are parsed prior to route execution using `express-validator`.
Registration passwords must satisfy the following rules:
- At least **8 characters** in length.
- At least **one uppercase letter** (`A-Z`).
- At least **one lowercase letter** (`a-z`).
- At least **one numeric digit** (`0-9`).

### E. Parameter Validation (UUIDs)
- Direct resource operations (e.g., scheme and profile details, bookmark saves, notifications) validate that path variables conform strictly to **UUID v4** layouts. Invalid UUID formats are rejected immediately with a `400 Bad Request` code before executing database queries.

---

## 4. Auth & Authorization Model

- **Authentication Protocol**: JWT Bearer Tokens in request authorization headers (`Authorization: Bearer <token>`). Tokens are signed using the explicit `HS256` hashing algorithm.
- **Expiry Guidelines**: Tokens are issued with a default expiration of **`24 hours`**.
- **Role-Based Controls**:
  - `user` role: Read-only access to schemes, CRUD access to personal bookmarks and profile details.
  - `admin` role: Guarded by `adminOnly` route modifiers, permitting CRUD access on schemes, versions, and general configurations.

---

## 5. Vulnerability Reporting Process

If you identify a security issue, please do not file a public issue. Follow this process:
1. Email your findings confidentially to the security contact email at **security@schememate.org**.
2. Include description details, endpoints, and steps or payloads to replicate the issue.
3. We will acknowledge receipt within 48 hours and coordinate a fix release window.
