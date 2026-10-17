/**
 * Field Visit Log — Mock API Server
 * ==================================
 * FOR DEVELOPMENT/TESTING ONLY. Not a production backend.
 *
 * POST /api/v1/visits
 *   Headers: Idempotency-Key: <clientVisitId>
 *   Body: { clientVisitId, customerName, notes, visitedAt, photoReference }
 *
 * Responses:
 *   201  Created
 *   200  Duplicate idempotent request (already stored, safe to mark synced)
 *   422  Validation error
 *   429  Rate limit (simulated)
 *   500  Server error (simulated)
 *   401  Unauthorized (simulated)
 */

const express = require('express');
const app = express();

app.use(express.json());

// In-memory store — keyed by clientVisitId for idempotency.
const visits = new Map();

// Rate limit simulation counter.
let requestCount = 0;
const RATE_LIMIT_EVERY = parseInt(process.env.RATE_LIMIT_EVERY || '0', 10);
const SIMULATE_SERVER_ERROR_EVERY = parseInt(process.env.SERVER_ERROR_EVERY || '0', 10);

app.post('/api/v1/visits', (req, res) => {
  requestCount++;

  // Simulate periodic server error.
  if (SIMULATE_SERVER_ERROR_EVERY > 0 && requestCount % SIMULATE_SERVER_ERROR_EVERY === 0) {
    console.log('[mock] Simulating 500 server error');
    return res.status(500).json({ message: 'Simulated server error.' });
  }

  // Simulate rate limiting.
  if (RATE_LIMIT_EVERY > 0 && requestCount % RATE_LIMIT_EVERY === 0) {
    console.log('[mock] Simulating 429 rate limit');
    return res.status(429).json({ message: 'Too many requests.' })
              .set('Retry-After', '30');
  }

  const idempotencyKey = req.headers['idempotency-key'];
  const { clientVisitId, customerName, notes, visitedAt, photoReference } = req.body;

  // Validation.
  const errors = {};
  if (!customerName || customerName.trim().length < 2 || customerName.trim().length > 80) {
    errors.customerName = 'Customer name must be 2–80 characters.';
  }
  if (!notes || notes.trim().length < 5 || notes.trim().length > 500) {
    errors.notes = 'Notes must be 5–500 characters.';
  }
  if (!clientVisitId) {
    errors.clientVisitId = 'clientVisitId is required.';
  }
  if (Object.keys(errors).length > 0) {
    return res.status(422).json({ message: 'Validation failed.', errors });
  }

  // Idempotency check: use the idempotency key (or clientVisitId) as the deduplication key.
  const key = idempotencyKey || clientVisitId;
  if (visits.has(key)) {
    console.log(`[mock] Duplicate request for ${key} — returning 200 OK`);
    const existing = visits.get(key);
    return res.status(200).json({
      serverId: existing.serverId,
      clientVisitId: existing.clientVisitId,
      status: 'synced',
    });
  }

  // Store the visit.
  const serverId = `srv-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  const record = {
    serverId,
    clientVisitId,
    customerName: customerName.trim(),
    notes: notes.trim(),
    visitedAt,
    photoReference: photoReference || null,
    receivedAt: new Date().toISOString(),
  };
  visits.set(key, record);

  // NOTE: We do NOT log customerName or notes to avoid capturing PII.
  console.log(`[mock] Stored visit ${serverId} (client: ${clientVisitId})`);

  return res.status(201).json({
    serverId,
    clientVisitId,
    status: 'synced',
  });
});

// Health check
app.get('/health', (_, res) => res.json({ status: 'ok', visits: visits.size }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`[mock] Field Visit Log mock server running on http://localhost:${PORT}`);
  console.log(`[mock] Android emulator: use http://10.0.2.2:${PORT}`);
  console.log(`[mock] Physical device: use your LAN IP, e.g. http://192.168.x.x:${PORT}`);
  console.log('[mock] Set SERVER_ERROR_EVERY=N to simulate a 500 every Nth request.');
  console.log('[mock] Set RATE_LIMIT_EVERY=N to simulate a 429 every Nth request.');
});
