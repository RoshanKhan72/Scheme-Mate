# Scheme Mate — Find. Apply. Benefit.

**Scheme Mate** is a smart, rules-driven government benefits assistant designed to bridge the information gap and help citizens find, evaluate eligibility, and apply for government social welfare schemes in India.

Instead of generic keyword matching or guess-work, Scheme Mate processes demographic and financial parameters against a structured eligibility database to accurately resolve eligibility matches.

---

## 🏛️ Project Architecture

```text
Scheme Mate/
├── LICENSE                    # MIT License
├── README.md                  # Complete setup guide
├── CHANGELOG.md               # Version release logs
├── CONTRIBUTING.md            # Coding standards
├── EVENTS.md                  # Notification events specifications
├── ROADMAP.md                 # Project timeline tracker
├── RELEASE_CHECKLIST.md       # Pre-release audit checks
│
├── docs/                      # Comprehensive Guides
│   ├── API.md                 # REST API endpoints & headers
│   ├── DATABASE.md            # Database schema & indexes
│   ├── ARCHITECTURE.md        # Architecture overview
│   └── DEPLOYMENT.md          # Docker staging & setups
│
├── backend/                   # Node.js / Express Service
│   ├── src/                   # Backend code
│   │   ├── migrations/        # SQL migration scripts
│   │   ├── seeds/             # Developer data seeds
│   │   └── utils/             # Services & logging helpers
│   ├── tests/                 # Native node:test suites
│   │   ├── unit/              # Eligibility unit tests
│   │   └── integration/       # Database & API mocks integration tests
│   ├── Dockerfile
│   └── docker-compose.yml
│
└── frontend/                  # Flutter Client App
```

---

## 🛠️ Technology Stack

* **Frontend:** Flutter & Dart, Riverpod State Management, SharedPreferences offline cache.
* **Backend:** Node.js, Express, Swagger/OpenAPI documentation.
* **Database:** PostgreSQL (GIN full-text search index, JSONB structures).
* **Testing:** Native Node.js `node:test` framework (zero external dependency).
* **Deployment:** Docker & Docker Compose.

---

## 🚀 Quick Start Guide

### 1. Database Setup & Migrations
Rename `backend/.env.example` to `backend/.env` and update the DB credentials, then run:
```bash
cd backend
npm install
npm run migrate
```

### 2. Launch Local Dev Servers
* **Backend:**
  ```bash
  cd backend
  npm run dev
  ```
  API Docs will be accessible at `http://localhost:5000/api-docs`.
* **Frontend:**
  ```bash
  cd frontend
  flutter run
  ```

### 3. Run Automated Tests
Execute backend unit and integration tests:
```bash
cd backend
npm test
```

### 4. Docker Staging Build
Launch the entire system inside Docker containers:
```bash
cd backend
docker-compose up --build
```
