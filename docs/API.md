# API Documentation - Scheme Mate

This document outlines the versioned REST API endpoints for **Scheme Mate**. All endpoints are version-prefixed under `/api/v1` and returns the standard version metadata header: `X-API-Version: 1.0.0`.

---

## 🔒 Authentication `/api/v1/auth`

### POST `/register`
Creates a new user profile.
- **Request Body:**
  ```json
  {
    "name": "John Doe",
    "email": "johndoe@example.com",
    "password": "securepassword123"
  }
  ```
- **Response (201):** Returns JWT login token and user profile.

### POST `/login`
Authenticates credentials.
- **Request Body:**
  ```json
  {
    "email": "johndoe@example.com",
    "password": "securepassword123"
  }
  ```
- **Response (200):** Returns JWT auth token.

---

## 👤 Profiles `/api/v1/profile`

### GET `/` (Protected)
Retrieves the logged-in user profile details.

### POST `/` (Protected)
Updates or registers demographic parameters.
- **Request Body:**
  ```json
  {
    "dob": "1995-06-15",
    "gender": "Female",
    "state": "Karnataka",
    "district": "Bengaluru",
    "occupation": "Farmer",
    "education": "Undergraduate",
    "annual_income": 120000,
    "marital_status": "Single",
    "category": "OBC",
    "is_farmer": true
  }
  ```

---

## 📢 Government Schemes `/api/v1/schemes`

### GET `/`
Query and search schemes. Supports full-text search parameters.
- **Query Parameters:**
  - `search`: "scholarship"
  - `state`: "Karnataka"
  - `category`: "Education"
  - `limit`: 10

### GET `/:id`
Retrieves detailed parameters of a scheme.

---

## 🎯 Personalized Dashboard `/api/v1/dashboard`

### GET `/` (Protected)
Compiles aggregates completion metrics, recommended feed deck, trending schemes, and documents verification alerts.

---

## ⭐ Bookmarks / Saved Schemes `/api/v1/saved`

### GET `/` (Protected)
List all user bookmarked schemes.

### POST `/` (Protected)
Toggles bookmark status on/off.
- **Request Body:** `{"schemeId": "scheme-uuid"}`

---

## 🔔 Notifications `/api/v1/notifications`

### GET `/` (Protected)
Retrieves a paginated list of alerts.

### GET `/preferences` (Protected)
Retrieves user preferences config.

### PUT `/preferences` (Protected)
Updates notification preference toggles.

---

## 🐛 Feedback & Reports `/api/v1/feedback`

### POST `/` (Protected)
Submit user feedback.
- **Request Body:**
  ```json
  {
    "screen": "Scheme Detail Screen",
    "type": "incorrect_scheme",
    "details": "The maximum income rule shows ₹2.5 Lakhs but official is ₹5 Lakhs.",
    "targetId": "scheme-uuid"
  }
  ```
