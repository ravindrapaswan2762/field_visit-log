# Field Visit Log

A professional Android application for field employees to log customer visits offline-first, with automatic background synchronisation when connectivity returns.

---

## Requirements

| Tool              | Version      |
|-------------------|-------------|
| Flutter           | ≥ 3.10.0    |
| Dart              | ≥ 3.0.0     |
| Android SDK       | API 21+     |
| Node.js (mock)    | ≥ 18.x      |

---

## Setup & Build

```bash
# 1. Clone / unzip the project
cd field_visit_log

# 2. Get dependencies
flutter pub get

# 3. Run on a connected device or emulator
flutter run

# 4. Build a debug APK
flutter build apk --debug
```

The APK is output to `build/app/outputs/flutter-apk/app-debug.apk`.

---

## Mock Server

```bash
cd mock_server
npm install
npm start
# Server runs at http://localhost:3000
```

**Android emulator:** `http://10.0.2.2:3000`  
**Physical device:** replace `baseUrl` in `lib/core/constants/app_constants.dart` with your LAN IP.

To simulate server errors:
```bash
SERVER_ERROR_EVERY=3 npm start   # 500 every 3rd request
RATE_LIMIT_EVERY=5 npm start     # 429 every 5th request
```

---

## Architecture

```
UI → Provider → Use Case → Repository → Local SQLite
                                      ↘ Remote API (sync only)
```

- **Offline-first:** all writes go to SQLite first. The UI never waits for a network response.
- **Provider (ChangeNotifier):** single state-management solution for UI state.
- **Repository pattern:** domain layer depends on interfaces, not implementations.
- **WorkManager:** schedules background sync with network constraints.

### Folder structure

```
lib/
├── core/          # constants, errors, network, DB, theme, utils
├── features/
│   └── visits/
│       ├── data/         # models, datasources, repository impl
│       ├── domain/       # entities, repository interface, use cases
│       └── presentation/ # screens, widgets, provider
├── sync/          # sync_manager, sync_worker, retry_policy, sync_status
├── routing/       # app_router
├── app.dart       # dependency wiring + MaterialApp
└── main.dart      # entry point + WorkManager init
```

---

## Database Schema

Table: `visits`

| Column           | Type    | Notes                              |
|------------------|---------|------------------------------------|
| `id`             | TEXT PK | Client-generated UUID              |
| `customer_name`  | TEXT    | Required, 2–80 chars               |
| `notes`          | TEXT    | Required, 5–500 chars              |
| `created_at`     | TEXT    | UTC ISO-8601                       |
| `photo_path`     | TEXT?   | Local file path, nullable          |
| `sync_status`    | TEXT    | pending / syncing / synced / failed|
| `retry_count`    | INTEGER | Number of upload attempts          |
| `next_retry_at`  | TEXT?   | UTC, next eligible retry time      |
| `last_sync_error`| TEXT?   | Sanitised error message            |
| `synced_at`      | TEXT?   | UTC confirmation timestamp         |

Timestamps are stored in UTC and displayed in local time.

---

## API Contract

```
POST /api/v1/visits
Headers:
  Content-Type: application/json
  Idempotency-Key: <clientVisitId>
Body:
  {
    "clientVisitId": "uuid-v4",
    "customerName": "Jane Doe",
    "notes": "Visited and reviewed...",
    "visitedAt": "2026-01-15T10:00:00.000Z",
    "photoReference": null
  }

201 → { "serverId": "...", "clientVisitId": "...", "status": "synced" }
200 → same body (idempotent duplicate)
422 → { "message": "Validation failed.", "errors": { ... } }
429 → rate limited, respect Retry-After header
5xx → transient; retry with exponential backoff
401 → authentication required; do not retry automatically
```

---

## Offline Save Flow

1. User fills the form and taps **Save Visit**.
2. A UUID is generated client-side.
3. Visit is written to SQLite with `sync_status = pending`.
4. UI immediately shows the new visit.
5. If online, a foreground sync is triggered.
6. A background WorkManager task is also scheduled.

---

## Background Synchronisation

- **WorkManager** schedules a one-off task with `networkType = connected`.
- On startup, the app recovers any `syncing` records back to `pending` (handles process kills).
- `ConnectivityService` triggers foreground sync when the device comes back online.
- Foreground and background sync both use the same `SyncPendingVisits` use case.

---

## Retry / Backoff / Idempotency

- **Initial delay:** 10 seconds.
- **Backoff multiplier:** 2× (exponential).
- **Max delay:** 30 minutes.
- **Max retries:** 5.
- Transient errors (network, 5xx, 429): back off and retry.
- Validation errors (422): exhaust retry count immediately (will not improve).
- Auth errors (401): mark failed; require user action.
- The same UUID is reused on every retry. The server uses it as an idempotency key so duplicate uploads are safe.

---

## Permissions & Privacy

| Permission           | When requested        | Reason                   |
|----------------------|-----------------------|--------------------------|
| `INTERNET`           | Always (manifest)     | API sync                 |
| `CAMERA`             | Only when user taps   | Optional photo           |
| `READ_MEDIA_IMAGES`  | Only when user taps   | Gallery pick             |

- Customer notes and photo contents are **never logged**.
- No secrets are committed to the repository.
- The mock server does not log request bodies.

---

## Third-party Dependencies

| Package              | Purpose                    |
|----------------------|----------------------------|
| `provider`           | State management           |
| `sqflite`            | SQLite persistence         |
| `path_provider`      | App directories            |
| `http`               | REST API calls             |
| `connectivity_plus`  | Network change events      |
| `workmanager`        | Android background tasks   |
| `image_picker`       | Camera / gallery           |
| `uuid`               | Client-side ID generation  |
| `intl`               | Date formatting            |
| `mocktail`           | Test mocking               |

---

## Running Tests

```bash
# Unit and widget tests
flutter test

# Integration tests (requires emulator or device)
flutter test integration_test/app_flow_test.dart

# Mock server must be running for sync integration tests
```

---

## Assumptions & Known Limitations

1. **Photo upload** is not implemented in the mock server. Photos are stored locally and the `photoReference` field is always `null` in API requests. Full photo sync would require a separate multipart endpoint.
2. **WorkManager timing** is not deterministic. Background sync may run 15+ minutes late under Android battery optimisation. Foreground sync compensates for active users.
3. **Authentication** is not implemented. The mock server does not require tokens. A production deployment would add bearer token handling in `ApiClient`.
4. **Pagination** is not implemented. For large visit histories, a cursor-based pagination approach would be needed.
5. **Conflict resolution** is not implemented. The server is the source of truth for sync state; local edits to synced visits are not supported in this version.
