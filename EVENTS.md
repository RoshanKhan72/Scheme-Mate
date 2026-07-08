# Scheme Mate Event Specifications

This document outlines all system events, triggers, listener services, and payloads supported in **Scheme Mate**.

---

## 📣 Event Definitions Registry

| Event Identifier | Trigger Condition | Source Module | Registered Listeners | Payload Schema |
| :--- | :--- | :--- | :--- | :--- |
| **`PROFILE_UPDATED`** | User upserts or updates socioeconomic demographics parameters. | Profile Controller | Notification Service, Eligibility Engine | `{ userId }` |
| **`PROFILE_COMPLETED`** | Profile completion reaches 100%. | Profile Controller | Notification Service, Analytics | `{ userId }` |
| **`SCHEME_CREATED`** | Admin registers a new government scheme. | Admin Scheme Controller | Notification Service (Alerts matches) | `{ schemeId, state, category }` |
| **`SCHEME_UPDATED`** | Admin edits scheme description or eligibility criteria. | Admin Scheme Controller | Notification Service (Alerts bookmarks) | `{ schemeId, name, versionNumber }` |
| **`SCHEME_CLOSING_SOON`** | Scheme application deadline is within 7 days. | Cron Worker / Dashboard Service | Notification Service (Alerts bookmarks) | `{ schemeId, name, daysLeft }` |
| **`SCHEME_MATCH_FOUND`** | Eligibility solver finds a new 100% matched scheme. | Eligibility Engine | Notification Service (New match alert) | `{ userId, schemeId, schemeName }` |
| **`DOCUMENT_MISSING`** | User matches demographic rules but lacks a required document. | Eligibility Engine | Notification Service (Document reminder) | `{ userId, schemeId, docName }` |
| **`DOCUMENT_UPLOADED`** | User uploads/checks a document in their profile vault. | Profile Controller | Notification Service, Eligibility Engine | `{ userId, docName }` |
| **`SAVED_SCHEME_ADDED`** | User bookmarks a government scheme. | Saved Schemes Controller | Notification Service, Analytics | `{ userId, schemeId }` |
| **`SAVED_SCHEME_REMOVED`** | User removes a bookmarked scheme. | Saved Schemes Controller | Notification Service, Analytics | `{ userId, schemeId }` |

---

## 🛠️ Event Triggers Integration Example

Instead of coupling database insertions directly inside controllers, triggers invoke the `notificationService.triggerNotificationEvent(userId, eventId, data)` interface:

```javascript
// Inside profileController.js - when user completes profile updates
await notificationService.triggerNotificationEvent(req.user.id, 'PROFILE_UPDATED', {
  completionScore: completion,
  missingDocs: missing
});
```

This guarantees clean architectural decoupling across modules!
