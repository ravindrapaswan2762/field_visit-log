# Technical Note — Field Visit Log

## What I prioritised

**Reliable offline persistence** was the top priority. Every visit is written to SQLite before any network call is attempted. The UI returns immediately after the local write; the user sees their visit instantly regardless of connectivity. Idempotency was treated as a first-class concern: each visit receives a stable UUID at creation, and that same ID is sent as the `Idempotency-Key` header on every upload attempt. This means a retry after a lost response will not create a duplicate server record.

Clean layering came second — domain entities have zero Flutter or persistence dependencies, which keeps the use-case logic testable without a real database or network.

## One important trade-off

**WorkManager vs. foreground sync.** WorkManager is the correct Android primitive for reliable background work, but it may run 15+ minutes late under Doze mode and battery optimisation. Foreground sync (triggered by the connectivity stream) fills this gap for active users, but the app does not keep a foreground service running permanently because that would drain battery and require a visible notification — disproportionate for occasional field logging. The trade-off: a user who creates a visit, locks the phone, and never opens the app again may wait longer than expected for the sync to complete.

## What I would improve with one additional day

1. **End-to-end integration test with a real SQLite database** — the current integration tests use `sqflite_common_ffi` (FFI-backed SQLite) which runs on desktop/CI without an emulator. I would add a proper `flutter test integration_test/app_flow_test.dart` test that runs the full stack on an emulator, including connectivity toggling and WorkManager scheduling.
2. **Photo upload** — the mock server currently ignores `photoReference`. I would add multipart upload support and a separate `/api/v1/visits/{id}/photo` endpoint so photo data can be streamed independently of the JSON payload.
3. **Background sync visibility** — expose sync progress via a persistent foreground notification during an active sync pass so users on slow connections can see work is happening without opening the app.

## Production Architecture Note: Authentication & Photo Storage

- **Authentication Tokens**: In production, credentials should never be stored in plain SQLite or shared preferences. Use `flutter_secure_storage` (backed by Android Keystore / `EncryptedSharedPreferences`). Access tokens should be short-lived JWTs attached via an HTTP interceptor as `Authorization: Bearer <token>`, with automatic refresh token rotation. On permanent `401 Unauthorized`, cached tokens are invalidated and the user is redirected to re-authenticate without deleting unsynced local drafts.
- **Photo Storage**: Photos should not be sent directly inside the JSON payload. Instead, implement a two-step upload: (1) request a pre-signed S3/GCS upload URL from the backend, (2) upload compressed WebP image bytes directly to cloud object storage, and (3) attach the resulting `photoReference` key to the visit JSON sync payload. Local images are stored in app-sandboxed storage (`getExternalFilesDir` / app documents) and cleaned up once cloud upload confirmation is received.
