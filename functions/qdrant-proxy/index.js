/**
 * Qdrant Proxy — Appwrite Function
 *
 * Proxies search and point-lookup requests to Qdrant Cloud,
 * solving browser CORS restrictions for the Flutter web app.
 *
 * Environment variables (set in Appwrite console):
 *   QDRANT_URL        — e.g. https://xxx.europe-west3-0.gcp.cloud.qdrant.io:6333
 *   QDRANT_API_KEY    — Qdrant Cloud API key
 *   QDRANT_COLLECTION — collection name (default: pubmed_articles)
 *
 * Routes (called by FunctionsClient in the Flutter app):
 *   POST /search   → POST /collections/{col}/points/search  (vector search)
 *   POST /scroll   → POST /collections/{col}/points/scroll  (keyword scroll)
 *   POST /doc      → POST /collections/{col}/points         (get by ID)
 */

export default async ({ req, res, log, error }) => {
  const QDRANT_URL    = process.env.QDRANT_URL?.replace(/\/$/, '');
  const QDRANT_KEY    = process.env.QDRANT_API_KEY;
  const COLLECTION    = process.env.QDRANT_COLLECTION || 'pubmed_articles';

  if (!QDRANT_URL || !QDRANT_KEY) {
    return res.json({ error: 'Missing QDRANT_URL or QDRANT_API_KEY env vars' }, 500);
  }

  const path = req.path || '/';
  let qdrantPath;

  if (path === '/search') {
    qdrantPath = `/collections/${COLLECTION}/points/search`;
  } else if (path === '/scroll') {
    qdrantPath = `/collections/${COLLECTION}/points/scroll`;
  } else if (path === '/doc') {
    qdrantPath = `/collections/${COLLECTION}/points`;
  } else {
    return res.json({ error: `Unknown path: ${path}` }, 404);
  }

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch (e) {
    return res.json({ error: 'Invalid JSON body' }, 400);
  }

  try {
    const upstream = await fetch(`${QDRANT_URL}${qdrantPath}`, {
      method: 'POST',
      headers: {
        'api-key': QDRANT_KEY,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    const data = await upstream.json();
    return res.json(data, upstream.status);
  } catch (e) {
    error(`Qdrant upstream error: ${e.message}`);
    return res.json({ error: e.message }, 502);
  }
};
