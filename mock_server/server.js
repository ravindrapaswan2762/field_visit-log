/**
 * Field Visit Log — Mock API Server
 * ==================================
 * FOR DEVELOPMENT/TESTING ONLY. Not a production backend.
 *
 * Saves data directly to mock_server/data/visits.json on your computer disk!
 *
 * POST /api/v1/visits
 *   Headers: Idempotency-Key: <clientVisitId>
 *   Body: { clientVisitId, customerName, notes, visitedAt, photoReference }
 *
 * GET /api/v1/visits
 *   Returns all visits saved to the server
 */

const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const DATA_FILE = path.join(__dirname, 'data', 'visits.json');

app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Idempotency-Key, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(204);
  }
  next();
});

app.use(express.json());

// Load existing visits from disk file on startup
const visits = new Map();

function loadVisitsFromDisk() {
  try {
    if (fs.existsSync(DATA_FILE)) {
      const data = fs.readFileSync(DATA_FILE, 'utf8');
      const array = JSON.parse(data || '[]');
      for (const item of array) {
        const key = item.clientVisitId;
        visits.set(key, item);
      }
      console.log(`[mock] Loaded ${visits.size} visits from disk (${DATA_FILE})`);
    }
  } catch (err) {
    console.error('[mock] Failed to read visits.json:', err.message);
  }
}

function saveVisitsToDisk() {
  try {
    const array = Array.from(visits.values());
    fs.writeFileSync(DATA_FILE, JSON.stringify(array, null, 2), 'utf8');
  } catch (err) {
    console.error('[mock] Failed to write visits.json:', err.message);
  }
}

loadVisitsFromDisk();

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
  saveVisitsToDisk();

  // NOTE: We do NOT log customerName or notes to avoid capturing PII in terminal.
  console.log(`[mock] Stored visit ${serverId} (client: ${clientVisitId}) -> saved to data/visits.json`);

  return res.status(201).json({
    serverId,
    clientVisitId,
    status: 'synced',
  });
});

// List all visits stored on the mock server
app.get('/api/v1/visits', (_, res) => {
  res.json({
    total: visits.size,
    visits: Array.from(visits.values()),
  });
});

// Health check
app.get('/health', (_, res) => res.json({ status: 'ok', visits: visits.size }));

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`[mock] Field Visit Log mock server running on http://localhost:${PORT}`);
  console.log(`[mock] Visits persisted to file: ${DATA_FILE}`);
  console.log(`[mock] Android emulator: use http://10.0.2.2:${PORT}`);
  console.log(`[mock] Physical device: use your LAN IP, e.g. http://192.168.x.x:${PORT}`);
});
