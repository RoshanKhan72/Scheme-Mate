# Deployment & Environment Setup - Scheme Mate

This document outlines deployment configurations, environment variables, database migrations setup, and docker container steps.

---

## 🚀 Docker Setup

Docker is the recommended option for local staging and production deployments.

### 1. Build and Run Container Services
Ensure Docker Desktop is running, then execute:
```bash
cd backend
docker-compose up --build
```
This builds the Express server container and launches a mapped PostgreSQL container database.

---

## 🗄️ Database Migrations

Scheme Mate manages schemas using a custom timestamp-based migration framework.

### 1. Apply Pending Migrations
```bash
npm run migrate
```
Executes any SQL migration files in `backend/src/migrations/` that have not been previously run.

### 2. Rollback Last Migration
```bash
npm run migrate:rollback
```
Rolls back the last applied migration by executing the corresponding `*_down.sql` file.

### 3. Load Seed Data (Development Only)
To seed mock schemes:
```bash
psql -U postgres -d schememate -f src/seeds/seed.sql
```

---

## 🧪 Testing

Execute backend test suites:
```bash
npm test
```
Runs unit and integration tests using Node's native built-in test runner (`node:test`).
