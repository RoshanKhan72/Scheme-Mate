# System Architecture - Scheme Mate

This document outlines the high-level architecture design, decoupled modules, and state flows of **Scheme Mate**.

---

## 🏛️ System Design Overview

Scheme Mate is designed around a clean, layered service-oriented architecture:

```
                  ┌───────────────────────┐
                  │      Flutter App      │
                  │   (Riverpod State)    │
                  └───────────┬───────────┘
                              │ HTTPS / JSON
                              ▼
                  ┌───────────────────────┐
                  │    Express API app    │
                  │     (App.js V1)       │
                  └───────────┬───────────┘
                              │ Controller Call
                              ▼
                  ┌───────────────────────┐
                  │    Services Layer     │
                  │   (Business Logic)    │
                  └───────────┬───────────┘
                              │ Database queries
                              ▼
                  ┌───────────────────────┐
                  │    PostgreSQL DB      │
                  └───────────────────────┘
```

---

## 🛠️ Layered Responsibilities

### 1. Presentation (Flutter Client)
- **Features Modularization:** Divided into `auth`, `profile`, `dashboard`, `schemes`, and `notifications`.
- **State Management:** Riverpod notifier classes provide clean caching and database synchronization.
- **Offline Mode:** Uses `SharedPreferences` to cache dashboard feeds and notification alerts locally, showing offline status if networking fails.

### 2. Controllers (API Request Handlers)
- Thin wrappers parsing JSON request payloads, calling matching service layers, and returning HTTP responses.

### 3. Services (Decoupled Business Logic)
- **Eligibility Engine:** Evaluates demographic rules and required documents checker checklists.
- **Notification Event Service:** Decoupled event bus triggers. Emits events without blocking controllers.

### 4. Database Schema (PostgreSQL)
- Contains user accounts, profiles, notifications, feedback logs, indexes, and full-text searches.
- Managed using timestamped database migrations under `backend/src/migrations/`.
