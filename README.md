# Field Visit Log

A professional Android application for field employees to log customer visits offline-first, with automatic background synchronisation when connectivity returns.

---

## 📱 App Screenshots

| 1. Visit List | 2. Add Visit Form | 3. Visit Details |
| :---: | :---: | :---: |
| <img src="https://res.cloudinary.com/duylswwsj/image/upload/v1792233880/Screenshot_2026-10-17_at_4.09.27_PM_idwcr8.png" width="260" alt="Visit List Screen" /> | <img src="https://res.cloudinary.com/duylswwsj/image/upload/v1792233880/Screenshot_2026-10-17_at_4.09.59_PM_wtizbs.png" width="260" alt="Add Visit Form Screen" /> | <img src="https://res.cloudinary.com/duylswwsj/image/upload/v1792233880/Screenshot_2026-10-17_at_4.10.22_PM_oej5v6.png" width="260" alt="Visit Details Screen" /> |
| *Real-time sync summary, status badges & filters* | *Offline-first form, validation & photo capture* | *Detailed metadata, sync audit & retry controls* |

---

## ⚡ Quick Start Guide (Run in 2 Steps)

You need **two terminal windows**: one for the mock server, and one for the Flutter app.

### Step 1: Start the Mock Server (Terminal 1)
```bash
cd mock_server
npm install
npm start
```
> The mock server will run on `http://localhost:3001` and save data to `mock_server/data/visits.json`. Keep this terminal window open!

---

### Step 2: Run the App (Terminal 2)

Choose whichever method is most convenient for you:

#### 🌐 Option A: In Google Chrome (Fastest & Zero Setup — Recommended!)
```bash
flutter run -d chrome
```
*No emulator or phone needed. Runs immediately with persistent IndexedDB and full camera/gallery support.*

#### 📱 Option B: In Android Studio Emulator
```bash
flutter run
```
*The app automatically connects to the mock server at `http://10.0.2.2:3001` with zero configuration.*

#### 📲 Option C: On a Physical Android Phone
1. Install and run the app:
   ```bash
   flutter run
   # OR build debug APK: flutter build apk --debug
   # APK location: build/app/outputs/flutter-apk/app-debug.apk
   ```
2. **Connect the phone to the server**:
   * **Via Wi-Fi (No cables)**: Connect your phone to the same Wi-Fi as your computer. In the app header, **tap the `Online / Offline` pill**, enter your computer's local Wi-Fi IP (e.g. `http://192.168.1.15:3001`), and tap **Save & Sync**.
   * **Via USB Cable**: Plug in your phone with USB Debugging enabled, run `adb reverse tcp:3001 tcp:3001`, tap the `Online / Offline` pill, and pick **Localhost / USB**.

---

## 🧪 How to Test Offline-First Resilience

1. **Online Creation**: Add a visit with the mock server running. The visit saves to SQLite and syncs immediately (`Synced`).
2. **Offline Creation**: Stop the mock server (`Ctrl + C` in Terminal 1) or disable Wi-Fi. Add a visit. It saves to local SQLite instantly (`Pending`).
3. **App Restart**: Close and relaunch the app. All visits reload intact from local storage.
4. **Auto-Sync on Reconnect**: Restart the server (`npm start`) or reconnect Wi-Fi. All pending visits automatically synchronize and update to `Synced`!

---

## 🔧 Prerequisites

| Tool              | Version      | Purpose                          |
|-------------------|-------------|----------------------------------|
| Flutter           | ≥ 3.10.0    | UI and Application Framework     |
| Dart              | ≥ 3.0.0     | Programming Language             |
| Android SDK       | API 21+     | Mobile Target                    |
| Node.js           | ≥ 18.x      | Mock Server Execution            |

---

## 🛠️ Simulating Server Errors & Edge Cases

In the `mock_server` directory:
```bash
# Simulate a 500 server error on every 3rd request
SERVER_ERROR_EVERY=3 npm start

# Simulate a 429 rate limit with Retry-After header on every 5th request
RATE_LIMIT_EVERY=5 npm start
```

---

## 🏛️ Architecture & Clean Layering

```
UI → Provider (ChangeNotifier) → Use Cases → Repository → Local SQLite
                                                        ↘ Remote API (POST /api/v1/visits)
```

- **Offline-first:** SQLite writes always happen first; the UI never waits on network latency.
- **Single State Management:** Standard Provider with `ChangeNotifier`.
- **Repository Pattern:** Pure domain interfaces isolated from data and framework layers.
- **WorkManager & Connectivity Stream:** Multi-layer synchronization (foreground on reconnect + headless background workers).

### Project Folder Structure

```
lib/
├── core/          # AppConstants, typed AppException, ApiClient, AppDatabase, theme, validators
├── features/
│   └── visits/
│       ├── data/         # VisitModel, VisitLocalDatasource, VisitRemoteDatasource, VisitRepositoryImpl
│       ├── domain/       # Visit entity, VisitRepository interface, 4 focused use cases
│       └── presentation/ # Screens (List, Add, Details), Widgets, VisitProvider
├── sync/          # SyncManager, SyncWorker, RetryPolicy, SyncStatus
├── routing/       # AppRouter
├── app.dart       # App initialization and theme setup
└── main.dart      # Entry point with WorkManager initialization
```

---

## 🗄️ Database Schema

SQLite Table: `visits`

| Column           | Type    | Description                                             |
|------------------|---------|---------------------------------------------------------|
| `id`             | TEXT PK | Stable client UUID (reused as Idempotency-Key)          |
| `customer_name`  | TEXT    | Required, 2–80 characters                               |
| `notes`          | TEXT    | Required, 5–500 characters                              |
| `created_at`     | TEXT    | UTC ISO-8601 creation timestamp                         |
| `photo_path`     | TEXT?   | Local file path or base64 photo data (nullable)        |
| `sync_status`    | TEXT    | `pending` / `syncing` / `synced` / `failed`             |
| `retry_count`    | INTEGER | Number of attempted synchronizations                    |
| `next_retry_at`  | TEXT?   | UTC timestamp indicating next eligible retry time       |
| `last_sync_error`| TEXT?   | Sanitized, user-friendly error message                  |
| `synced_at`      | TEXT?   | UTC confirmation timestamp from server                  |

*All timestamps are stored internally in UTC and displayed formatted in local time.*

---

## 📡 API Contract & Idempotency

```http
POST /api/v1/visits
Content-Type: application/json
Idempotency-Key: <clientVisitId>

{
  "clientVisitId": "uuid-v4",
  "customerName": "Jane Doe",
  "notes": "Visited and reviewed contract terms...",
  "visitedAt": "2026-01-15T10:00:00.000Z",
  "photoReference": null
}
```

* **201 Created**: Successful first-time upload (`status: synced`).
* **200 OK**: Duplicate idempotent request; server returns existing record without duplicating.
* **422 Unprocessable Entity**: Validation failure (exhausts retries immediately).
* **429 Too Many Requests**: Rate limiting (respects `Retry-After` header).
* **5xx / Timeout**: Transient error (triggers exponential backoff retry).
* **401 Unauthorized**: Authentication failure (stops retrying).

---

## 🔁 Retry Policy & Exponential Backoff

- **Initial delay:** 10 seconds.
- **Multiplier:** 2.0× exponential backoff.
- **Max retry delay:** 30 minutes.
- **Max retries:** 5 attempts.
- **Duplicate Prevention:** The same client UUID is preserved across all retries and transmitted in the `Idempotency-Key` header.

---

## 🔒 Permissions & Security

| Permission           | Triggered               | Justification                     |
|----------------------|-------------------------|-----------------------------------|
| `INTERNET`           | App launch              | REST API synchronization          |
| `CAMERA`             | Only upon user tap      | Optional in-app photo capture     |
| `READ_MEDIA_IMAGES`  | Only upon user tap      | Optional gallery photo selection  |

- Customer names, notes, and photos are **strictly excluded from all console logs**.
- SQL queries use **parameterized statements** to prevent injection.
- Zero credentials or API keys are committed.

### Production Note: Authentication Tokens & Photo Storage
- **Authentication Tokens**: In a production environment, user credentials should be stored securely using `flutter_secure_storage` (backed by Android Keystore and `EncryptedSharedPreferences`). API requests would transmit short-lived JWTs via `Authorization: Bearer <token>` headers with automatic refresh token rotation. If the server responds with `401 Unauthorized`, cached tokens are cleared and the user is prompted to re-authenticate without losing any unsynced local drafts.
- **Photo Storage**: Photos should be compressed (e.g. WebP/JPEG) and uploaded asynchronously to cloud object storage (AWS S3, Google Cloud Storage, or Cloudinary) using pre-signed upload URLs. Only the returned immutable asset reference key is stored in the local SQLite table and transmitted as `photoReference` in the visit sync payload, keeping the database lean and network payloads small.

---

## 🧪 Automated Test Suite

Run the full suite of **44 automated tests**:

```bash
# Run all unit, widget, and integration tests
flutter test

# Run device integration flow test
flutter test integration_test/app_flow_test.dart
```

---

## 📋 Assumptions & Limitations

1. **Photo Upload**: The mock server validates JSON visits and preserves local photo attachments. Remote binary photo synchronization is kept separate to prioritize core visit reliability.
2. **WorkManager Battery Optimization**: On Android 12+, WorkManager execution can be deferred up to 15 minutes by Android Doze mode. Real-time foreground sync on network return compensates for active sessions.
3. **Authentication**: The mock API operates in development mode without OAuth tokens; production deployments should integrate JWT headers in `ApiClient`.
