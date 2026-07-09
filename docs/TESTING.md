# Scheme Mate Testing Strategy & Guidelines

This document details the testing architecture, local execution commands, environment configurations, and CI pipelines for the **Scheme Mate** full-stack cross-platform ecosystem.

---

## 1. Testing Architecture

We divide our tests into three distinct layers to balance feedback speed with execution realism:

```mermaid
graph TD
    A[Unit Tests] -->|Focus| B(Business logic, Eligibility Engine, Request validators)
    C[Integration Tests] -->|Focus| D(API controllers + Database rollback, Widget builds + Mocked HTTP)
    E[End-to-End E2E Tests] -->|Focus| F(Flutter Web UI + Real Express backend + Test Database)
```

---

## 2. Express Backend Testing

### A. Environment Setup
Backend integration tests require an isolated PostgreSQL database to prevent test run overlaps from polluting development data.
1. Configure `DATABASE_URL_TEST` in your environment (or inside your local `.env` file):
   ```bash
   DATABASE_URL_TEST=postgresql://postgres:postgres@localhost:5432/scheme_mate_test
   ```
2. Execute initial database migrations to create the database schema:
   ```bash
   cd backend
   npm run migrate
   ```

### B. Running Tests
- **Run all tests (Unit + Integration)**:
   ```bash
   npm test
   ```
   *Note: Integration tests are executed sequentially (`--test-concurrency=1`) to prevent PostgreSQL locks and deadlocks during table truncations.*

- **Run tests with coverage**:
   ```bash
   npm run test -- --experimental-test-coverage
   ```

### C. Coverage Quality Goals for RC1
- Overall Backend Code: `≥80%`
- Eligibility Matching Engine: `≥95%`
- Request Validator Middlewares: `100%`
- Notification Dispatcher Service: `≥90%`

---

## 3. Flutter Frontend Testing

### A. Widget & Unit Tests
Widget tests execute locally on a headless test environment.
- Run tests:
  ```bash
  cd frontend
  flutter test
  ```

### B. Integration Tests (Mocked API)
Mocked integration tests use the `MockHttpClient` interceptor inside `integration_test/mock_api.dart` to simulate backend API responses without launching a real network server.
- Run integration tests:
  - **Windows Desktop**:
    ```bash
    flutter test -d windows integration_test/app_test.dart
    ```
  - **Mobile Target**:
    ```bash
    flutter test -d android integration_test/app_test.dart
    ```

### C. End-to-End (E2E) Tests (Real API)
E2E tests run the frontend code directly against a live running Express backend and the isolated test database.
1. Start the backend in test mode:
   ```bash
   cd backend
   NODE_ENV=test npm start
   ```
2. Run the integration test targeting your device/browser:
   ```bash
   cd frontend
   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome
   ```

---

## 4. CI/CD Workflows

We use **GitHub Actions** to automate pull request and push checks:

- **Fast Checks (Run on every Push/PR)**:
  - **Backend**: Launches a PostgreSQL service container, runs database migrations from scratch, installs dependencies, and runs `npm test`.
  - **Frontend**: Installs dependencies (`flutter pub get`), runs semantic check (`flutter analyze`), runs widget tests (`flutter test`), compiles Web release bundle (`flutter build web --release`), and compiles Android APK (`flutter build apk --debug`).
- **Scheduled Checks (Nightly / Release Pipelines)**:
  - Executes slower device-framed integration tests and Lighthouse performance audits.

---

## 5. Troubleshooting Common Issues

### 1. PostgreSQL Deadlocks (`code: 40P01`)
- **Reason**: Test files are running in parallel and trying to run table truncates concurrently.
- **Solution**: Enforce sequential test concurrency: `node --test --test-concurrency=1 tests/**/*.test.js`.

### 2. Missing SharedPreferences mock
- **Reason**: Flutter widget tests accessing disk storage throw missing initial values exceptions.
- **Solution**: Call `SharedPreferences.setMockInitialValues({});` before starting widget pumps.

### 3. Missing `JWT_SECRET` in Test Mode
- **Reason**: Backend throws a fatal startup crash if `JWT_SECRET` is not set in production/test configurations.
- **Solution**: Set a default placeholder secret (at least 32 characters) inside your local workflow configurations.
