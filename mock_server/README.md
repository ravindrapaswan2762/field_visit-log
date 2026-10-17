# Field Visit Log — Mock API Server

**FOR DEVELOPMENT/TESTING ONLY.**

## Setup

```bash
cd mock_server
npm install
npm start
```

## Connecting from Android

| Device                | Base URL                  |
|-----------------------|---------------------------|
| Android emulator      | `http://10.0.2.2:3001`    |
| Physical device (LAN) | `http://192.168.x.x:3001` |

Update `AppConstants.baseUrl` in `lib/core/constants/app_constants.dart`.

## API Contract

```
POST /api/v1/visits
Headers:
  Content-Type: application/json
  Idempotency-Key: <clientVisitId>
Body:
  {
    "clientVisitId": "<uuid>",
    "customerName": "Jane Doe",
    "notes": "Visited and reviewed...",
    "visitedAt": "2026-01-15T10:00:00.000Z",
    "photoReference": null
  }
```

### Responses

| Status | Meaning                                           |
|--------|---------------------------------------------------|
| 201    | Visit created successfully                        |
| 200    | Duplicate idempotent request — safe to mark synced|
| 422    | Validation error — do not retry                   |
| 429    | Rate limited — respect Retry-After header         |
| 500    | Server error — transient, retry with backoff      |
| 401    | Auth required — not retried automatically         |

## Simulating failures

```bash
# Simulate a 500 error every 3rd request:
SERVER_ERROR_EVERY=3 npm start

# Simulate a 429 every 5th request:
RATE_LIMIT_EVERY=5 npm start
```

## Photo upload

Photo upload is **not implemented** in this mock server.
`photoReference` is accepted but ignored.
Local photo attachments are preserved on device.
