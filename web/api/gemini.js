// Server-side Gemini proxy for the Delts iOS app.
//
// The Gemini API key lives ONLY here, as the Vercel environment variable
// GEMINI_API_KEY — it is never shipped inside the app binary. The app POSTs a
// Gemini `generateContent` body ({ contents, generationConfig }) and receives
// Gemini's response verbatim, so the client keeps its existing decoding.
//
// Set in Vercel: Project → Settings → Environment Variables → GEMINI_API_KEY
// (optional GEMINI_MODEL, defaults to gemini-2.5-flash).

const GEMINI_MODELS_ENDPOINT =
  "https://generativelanguage.googleapis.com/v1beta/models";

const MAX_BODY_BYTES = 6 * 1024 * 1024; // allow image attachments (base64)

// ------------------------------------------------------------------
// Abuse guard: requests must identify a device, and each device/IP is
// rate-limited. This is best-effort (in-memory, per warm instance) —
// it blocks casual drive-by abuse of the API key. Durable per-user
// metering + App Store receipt verification belongs in a KV store and
// is the next hardening step.
// ------------------------------------------------------------------
const WINDOW_MS = 60 * 60 * 1000; // 1 hour
const DEVICE_LIMIT_PER_WINDOW = 60;
const IP_LIMIT_PER_WINDOW = 180;
const buckets = new Map();

function allowRequest(key, limit) {
  const now = Date.now();
  let hits = buckets.get(key) || [];
  hits = hits.filter((t) => now - t < WINDOW_MS);
  if (hits.length >= limit) {
    buckets.set(key, hits);
    return false;
  }
  hits.push(now);
  buckets.set(key, hits);
  if (buckets.size > 20000) buckets.clear(); // crude memory bound
  return true;
}

module.exports = async (req, res) => {
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.setHeader("Cache-Control", "no-store");

  if (req.method === "OPTIONS") {
    res.setHeader("Allow", "POST, OPTIONS");
    return res.status(204).end();
  }
  if (req.method !== "POST") {
    res.setHeader("Allow", "POST, OPTIONS");
    return res.status(405).json({ error: "Method not allowed. Use POST." });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    return res
      .status(503)
      .json({ error: "GEMINI_API_KEY is not configured on the server." });
  }

  const device = req.headers["x-delts-device"];
  if (!device || typeof device !== "string" || device.length < 8 || device.length > 64) {
    return res.status(401).json({ error: "Missing device identity." });
  }
  const ip =
    (req.headers["x-forwarded-for"] || "").split(",")[0].trim() || "unknown";
  if (
    !allowRequest(`d:${device}`, DEVICE_LIMIT_PER_WINDOW) ||
    !allowRequest(`ip:${ip}`, IP_LIMIT_PER_WINDOW)
  ) {
    return res
      .status(429)
      .json({ error: "Too many requests. Try again later." });
  }

  const model = process.env.GEMINI_MODEL || "gemini-2.5-flash";

  // Vercel parses JSON bodies for application/json; fall back to manual parse.
  let body = req.body;
  if (typeof body === "string") {
    if (Buffer.byteLength(body, "utf8") > MAX_BODY_BYTES) {
      return res.status(413).json({ error: "Request body too large." });
    }
    try {
      body = JSON.parse(body);
    } catch {
      body = null;
    }
  }

  if (!body || typeof body !== "object" || !Array.isArray(body.contents)) {
    return res
      .status(400)
      .json({ error: "Request body must include a 'contents' array." });
  }

  // Forward only the fields Gemini needs — never trust extra client input.
  const payload = { contents: body.contents };
  if (body.generationConfig && typeof body.generationConfig === "object") {
    payload.generationConfig = body.generationConfig;
  }
  if (body.systemInstruction && typeof body.systemInstruction === "object") {
    payload.systemInstruction = body.systemInstruction;
  }
  if (Array.isArray(body.tools)) {
    payload.tools = body.tools;
  }
  if (body.toolConfig && typeof body.toolConfig === "object") {
    payload.toolConfig = body.toolConfig;
  }

  const url = `${GEMINI_MODELS_ENDPOINT}/${encodeURIComponent(
    model
  )}:generateContent?key=${encodeURIComponent(apiKey)}`;

  try {
    const upstream = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const text = await upstream.text();
    // Pass Gemini's status and JSON straight through to the client.
    return res.status(upstream.status).send(text);
  } catch (err) {
    return res
      .status(502)
      .json({ error: "Upstream request to Gemini failed." });
  }
};

// Gemini calls can take a few seconds; give the function headroom.
module.exports.config = { maxDuration: 30 };
