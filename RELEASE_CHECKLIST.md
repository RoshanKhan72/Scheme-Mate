# Release Checklist - Scheme Mate

This document outlines mandatory verification steps to audit and perform before tagging a version release.

---

## 📋 Pre-Release Checklist

- [ ] **Database Schema Status**
  - [ ] All database migrations are applied locally via `npm run migrate`.
  - [ ] Rollbacks have been verified with `npm run migrate:rollback`.
  - [ ] Schema diagrams in [docs/DATABASE.md](file:///d:/Projects/Scheme%20Mate/docs/DATABASE.md) align with active PostgreSQL structures.
- [ ] **Automated Testing Audit**
  - [ ] Run backend unit/integration tests with `npm test`. Verify all tests pass.
  - [ ] Run Flutter static code checks: `flutter analyze`.
- [ ] **Environment Verification**
  - [ ] Ensure [backend/.env.example](file:///d:/Projects/Scheme%20Mate/backend/.env.example) contains all active key mappings.
  - [ ] Confirm no production database passwords or JWT secrets are committed.
- [ ] **Docker Containers Staging**
  - [ ] Run `docker-compose up --build` and verify both backend and DB launch cleanly.
  - [ ] Access Swagger UI (`http://localhost:5000/api-docs`) inside docker to confirm endpoints.
- [ ] **Release Logs & versioning**
  - [ ] Log additions/fixes inside [CHANGELOG.md](file:///d:/Projects/Scheme%20Mate/CHANGELOG.md).
  - [ ] Verify version number matches semantic tags.
- [ ] **API Version Headers**
  - [ ] Verify curl requests returns header: `X-API-Version: 1.0.0`.
