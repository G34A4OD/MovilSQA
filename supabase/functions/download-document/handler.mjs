// download-document: JWT de usuario + authorize_document_download;
// service_role solo para leer bytes de nido-documents. Sin URLs firmadas.
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function json(body, status = 200) {
  return Response.json(body, { status, headers: { 'Cache-Control': 'no-store' } });
}

async function readJson(response) {
  const raw = await response.text();
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return { message: raw };
  }
}

function bytesToBase64(bytes) {
  let binary = '';
  const chunk = 0x8000;
  for (let i = 0; i < bytes.length; i += chunk) {
    binary += String.fromCharCode(...bytes.subarray(i, i + chunk));
  }
  return btoa(binary);
}

export function createDownloadDocumentHandler({
  url,
  key,
  serviceKey,
  fetcher = fetch,
}) {
  return async (request) => {
    if (request.method !== 'POST') return json({ error: 'method_not_allowed' }, 405);
    const authorization = request.headers.get('Authorization') ?? '';
    if (!/^Bearer [\w.-]+$/i.test(authorization)) return json({ error: 'unauthorized' }, 401);
    if (!serviceKey) return json({ error: 'request_failed' }, 500);

    try {
      const raw = await request.text();
      if (raw.length > 2048) return json({ error: 'validation_error' }, 400);
      const body = JSON.parse(raw);
      const documentId = body.document_id;
      if (!UUID_RE.test(documentId ?? '')) return json({ error: 'validation_error' }, 400);

      const userHeaders = {
        apikey: key,
        Authorization: authorization,
        'Content-Type': 'application/json',
      };
      const userResponse = await fetcher(`${url}/auth/v1/user`, { headers: userHeaders });
      if (!userResponse.ok) return json({ error: 'unauthorized' }, 401);
      const verified = await userResponse.json();
      if (!verified.id) return json({ error: 'unauthorized' }, 401);

      const authzResponse = await fetcher(`${url}/rest/v1/rpc/authorize_document_download`, {
        method: 'POST',
        headers: userHeaders,
        body: JSON.stringify({ p_document_id: documentId }),
      });
      const authz = await readJson(authzResponse);
      if (!authzResponse.ok) {
        return json({ error: 'forbidden' }, 403);
      }

      const publishedPath = authz.published_path;
      if (!publishedPath) return json({ error: 'forbidden' }, 403);

      const download = await fetcher(
        `${url}/storage/v1/object/nido-documents/${encodeURIComponent(publishedPath)}`,
        { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } },
      );
      if (!download.ok) {
        return json({ error: 'bytes_missing' }, 409);
      }
      const buffer = new Uint8Array(await download.arrayBuffer());
      return json({
        id: authz.id,
        mime_type: authz.detected_mime_type,
        size_bytes: buffer.length,
        content_base64: bytesToBase64(buffer),
      });
    } catch {
      return json({ error: 'request_failed' }, 400);
    }
  };
}
