// process-document: JWT de usuario + autorización RPC; service_role solo para
// Storage y complete_document_process. Sin escáner operativo → cuarentena.
const MAX_BYTES = 10 * 1024 * 1024;
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function detectMimeFromBytes(bytes) {
  if (!bytes || bytes.length < 1 || bytes.length > MAX_BYTES) return null;
  if (
    bytes.length >= 5 &&
    bytes[0] === 0x25 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x44 &&
    bytes[3] === 0x46 &&
    bytes[4] === 0x2d
  ) {
    return 'application/pdf';
  }
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return 'image/jpeg';
  }
  if (
    bytes.length >= 8 &&
    bytes[0] === 0x89 &&
    bytes[1] === 0x50 &&
    bytes[2] === 0x4e &&
    bytes[3] === 0x47 &&
    bytes[4] === 0x0d &&
    bytes[5] === 0x0a &&
    bytes[6] === 0x1a &&
    bytes[7] === 0x0a
  ) {
    return 'image/png';
  }
  return null;
}

export function validateDocumentBytes(bytes, declaredMime, expectedSize) {
  if (!bytes || !(bytes instanceof Uint8Array)) {
    return { ok: false, error: 'missing_bytes' };
  }
  if (expectedSize != null && bytes.length !== Number(expectedSize)) {
    return { ok: false, error: 'size_mismatch' };
  }
  if (bytes.length < 1 || bytes.length > MAX_BYTES) {
    return { ok: false, error: 'size_invalid' };
  }
  const detected = detectMimeFromBytes(bytes);
  if (!detected) {
    return { ok: false, error: 'signature_invalid' };
  }
  if (declaredMime && detected !== declaredMime) {
    return { ok: false, error: 'mime_mismatch' };
  }
  return { ok: true, mime: detected };
}

/**
 * Protocolo clamd INSTREAM (TCP). Escaneo real para pruebas locales / entorno confiable.
 * connect: inyectable en tests; por defecto Deno.connect o null → unavailable.
 */
export async function scanWithClamd(
  bytes,
  { host = '127.0.0.1', port = 3310, connect = null, chunkSize = 2048, timeoutMs = 10000 } = {},
) {
  if (typeof connect !== 'function' || !Number.isInteger(chunkSize) || chunkSize < 1) {
    return { status: 'unavailable', reason: 'scanner_unavailable' };
  }
  let conn;
  let reader;
  let timer;
  let timedOut = false;
  try {
    return await Promise.race([(async () => {
      const opened = await connect({ hostname: host, port: Number(port) });
      if (timedOut) { opened.close?.(); throw new Error('timeout'); }
      conn = opened;
      const encoder = new TextEncoder();
      const write = async (data) => {
        const buf = typeof data === 'string' ? encoder.encode(data) : data;
        let offset = 0;
        while (offset < buf.length) {
          const written = await conn.write(buf.subarray(offset));
          if (written == null || written <= 0) throw new Error('write_failed');
          offset += written;
        }
      };
      await write('zINSTREAM\0');
      for (let i = 0; i < bytes.length; i += chunkSize) {
        const chunk = bytes.subarray(i, Math.min(i + chunkSize, bytes.length));
        const header = new Uint8Array(4);
        new DataView(header.buffer).setUint32(0, chunk.length, false);
        await write(header);
        await write(chunk);
      }
      const end = new Uint8Array(4);
      await write(end);
      reader = typeof conn.readable?.getReader === 'function' ? conn.readable.getReader() : null;
      const replyBytes = [];
      let complete = false;
      while (!complete) {
        let chunk;
        if (reader) {
          const result = await reader.read();
          if (result.done) throw new Error('incomplete_reply');
          chunk = result.value;
        } else if (typeof conn.read === 'function') {
          const buf = new Uint8Array(512);
          const n = await conn.read(buf);
          if (!n) throw new Error('incomplete_reply');
          chunk = buf.subarray(0, n);
        } else throw new Error('read_unavailable');
        for (const byte of chunk) {
          if (complete) throw new Error('invalid_reply');
          if (byte === 0) complete = true;
          else if (replyBytes.push(byte) > 4096) throw new Error('reply_too_long');
        }
      }
      const reply = new TextDecoder('utf-8', { fatal: true }).decode(new Uint8Array(replyBytes));
      if (/^stream: [^\r\n\0]+ FOUND$/.test(reply)) {
        return { status: 'infected', reason: 'clamav_detected', evidence: 'clamav' };
      }
      if (reply === 'stream: OK') {
        return { status: 'clean', evidence: 'clamav' };
      }
      return { status: 'unavailable', reason: 'scanner_unavailable', evidence: 'clamav' };
    })(), new Promise((_, reject) => {
      timer = setTimeout(() => { timedOut = true; try { conn?.close?.(); } catch {} reject(new Error('timeout')); }, timeoutMs);
    })]);
  } catch {
    return { status: 'unavailable', reason: 'scanner_unavailable', evidence: 'clamav' };
  } finally {
    clearTimeout(timer);
    try { reader?.releaseLock(); } catch { /* pending read */ }
    try {
      conn?.close?.();
    } catch {
      /* ignore */
    }
  }
}

/**
 * Escáner: unavailable | clean | infected.
 * - off: sin escáner → cuarentena
 * - clamav / http: escaneo real (único camino a approved en runtime)
 * - simulate: SOLO evidencia de pruebas unitarias; no publica en producción
 */
export function createScanner({
  mode = 'off',
  fetcher = fetch,
  url,
  token,
  host = '127.0.0.1',
  port = 3310,
  connect = null,
  timeoutMs = 10000,
  allowSimulate = false,
} = {}) {
  return async (bytes) => {
    if (!mode || mode === 'off') {
      return { status: 'unavailable', reason: 'scanner_unavailable' };
    }
    if (mode === 'simulate') {
      if (!allowSimulate) {
        return { status: 'unavailable', reason: 'scanner_unavailable', evidence: 'simulate_blocked' };
      }
      const text = new TextDecoder('latin1').decode(
        bytes.subarray(0, Math.min(bytes.length, 256)),
      );
      if (text.includes('NIDO-SIMULATED-MALWARE')) {
        return { status: 'infected', reason: 'simulated_malware', evidence: 'simulate' };
      }
      return { status: 'clean', evidence: 'simulate' };
    }
    if (mode === 'clamav') {
      return scanWithClamd(bytes, { host, port, connect, timeoutMs });
    }
    if (mode === 'http' && url && token) {
      let timer;
      try {
        const endpoint = new URL(url);
        if (endpoint.protocol !== 'https:' || endpoint.username || endpoint.password) throw new Error('invalid_url');
        const controller = new AbortController();
        return await Promise.race([(async () => {
          const response = await fetcher(url, {
            method: 'POST',
            headers: { 'Content-Type': 'application/octet-stream', Authorization: `Bearer ${token}` },
            redirect: 'error',
            signal: controller.signal,
            body: bytes,
          });
          if (!response.ok) throw new Error('scanner_error');
          const verdict = await response.json();
          if (verdict?.status === 'clean') return { status: 'clean', evidence: 'http' };
          if (verdict?.status === 'infected') return { status: 'infected', reason: 'scanner_rejected', evidence: 'http' };
          throw new Error('invalid_verdict');
        })(), new Promise((_, reject) => {
          timer = setTimeout(() => { controller.abort(); reject(new Error('timeout')); }, timeoutMs);
        })]);
      } catch {
        return { status: 'unavailable', reason: 'scanner_unavailable', evidence: 'http' };
      } finally {
        clearTimeout(timer);
      }
    }
    return { status: 'unavailable', reason: 'scanner_unavailable' };
  };
}

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

export function createProcessDocumentHandler({
  url,
  key,
  serviceKey,
  fetcher = fetch,
  scanner = createScanner({ mode: 'off' }),
}) {
  async function complete(headers, params) {
    const response = await fetcher(`${url}/rest/v1/rpc/complete_document_process`, {
      method: 'POST',
      headers,
      body: JSON.stringify(params),
    });
    if (!response.ok) throw new Error('completion_failed');
    return readJson(response);
  }

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

      const authzResponse = await fetcher(`${url}/rest/v1/rpc/authorize_document_process`, {
        method: 'POST',
        headers: userHeaders,
        body: JSON.stringify({ p_document_id: documentId }),
      });
      const authz = await readJson(authzResponse);
      if (!authzResponse.ok) {
        return json(
          { error: authz?.message === 'version_conflict' ? 'version_conflict' : 'forbidden' },
          authz?.message === 'version_conflict' ? 409 : 403,
        );
      }

      if (authz.status === 'approved') {
        return json({
          id: authz.id,
          status: 'approved',
          version: authz.version,
          detected_mime_type: authz.detected_mime_type,
          published_path: authz.published_path,
          idempotent: true,
        });
      }
      if (authz.status === 'rejected') {
        return json({
          id: authz.id,
          status: 'rejected',
          version: authz.version,
          last_process_error: authz.last_process_error,
          idempotent: true,
        });
      }

      const serviceHeaders = {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        'Content-Type': 'application/json',
      };

      const download = await fetcher(
        `${url}/storage/v1/object/nido-quarantine/${encodeURIComponent(authz.storage_path)}`,
        { headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` } },
      );
      if (!download.ok) {
        await complete(serviceHeaders, {
          p_document_id: documentId,
          p_expected_version: authz.version,
          p_outcome: 'quarantine',
          p_detected_mime: null,
          p_error: 'bytes_missing',
          p_published_path: null,
        });
        return json({ error: 'bytes_missing', status: 'quarantine' }, 409);
      }
      const buffer = new Uint8Array(await download.arrayBuffer());
      const validation = validateDocumentBytes(
        buffer,
        authz.declared_mime_type,
        authz.size_bytes,
      );
      if (!validation.ok) {
        const done = await complete(serviceHeaders, {
          p_document_id: documentId,
          p_expected_version: authz.version,
          p_outcome: 'rejected',
          p_detected_mime: null,
          p_error: validation.error,
          p_published_path: null,
        });
        return json(
          { id: documentId, status: 'rejected', error: validation.error, result: done },
          422,
        );
      }

      // Escaneo solo tras validar bytes reales. approved exige evidencia clamav|http.
      const scan = await scanner(buffer);
      const realEvidence = scan?.evidence === 'clamav' || scan?.evidence === 'http';
      if (scan?.status !== 'infected' && (scan?.status !== 'clean' || !realEvidence)) {
        const done = await complete(serviceHeaders, {
          p_document_id: documentId,
          p_expected_version: authz.version,
          p_outcome: 'quarantine',
          p_detected_mime: validation.mime,
          p_error: scan?.reason || 'scanner_unavailable',
          p_published_path: null,
        });
        return json(
          {
            id: documentId,
            status: 'quarantine',
            error: 'scanner_unavailable',
            scan_evidence: scan?.evidence ?? null,
            process_attempts: done?.process_attempts,
            note: 'Bloqueo: no hay escáner acordado/operativo; el archivo permanece en cuarentena.',
          },
          503,
        );
      }
      if (scan.status === 'infected') {
        const done = await complete(serviceHeaders, {
          p_document_id: documentId,
          p_expected_version: authz.version,
          p_outcome: 'rejected',
          p_detected_mime: validation.mime,
          p_error: scan.reason || 'scanner_rejected',
          p_published_path: null,
        });
        return json(
          {
            id: documentId,
            status: 'rejected',
            error: scan.reason,
            scan_evidence: scan.evidence ?? null,
            result: done,
          },
          422,
        );
      }

      const publishedPath = authz.storage_path;
      const upload = await fetcher(
        `${url}/storage/v1/object/nido-documents/${encodeURIComponent(publishedPath)}`,
        {
          method: 'POST',
          headers: {
            apikey: serviceKey,
            Authorization: `Bearer ${serviceKey}`,
            'Content-Type': validation.mime,
            'x-upsert': 'false',
          },
          body: buffer,
        },
      );
      if (!upload.ok) {
        const done = await complete(serviceHeaders, {
          p_document_id: documentId,
          p_expected_version: authz.version,
          p_outcome: 'quarantine',
          p_detected_mime: validation.mime,
          p_error: 'publish_failed',
          p_published_path: null,
        });
        return json(
          { error: 'publish_failed', status: 'quarantine', result: done },
          500,
        );
      }

      let done;
      try {
        done = await complete(serviceHeaders, {
          p_document_id: documentId,
          p_expected_version: authz.version,
          p_outcome: 'approved',
          p_detected_mime: validation.mime,
          p_error: null,
          p_published_path: publishedPath,
        });
        if (done?.status !== 'approved') throw new Error('completion_unconfirmed');
      } catch {
        // La respuesta pudo perderse tras el commit: conservar ambas copias para reconciliación.
        return json({ error: 'publish_commit_unconfirmed' }, 503);
      }

      // Limpieza best-effort de cuarentena; fallo no revierte approved.
      try { await fetcher(
        `${url}/storage/v1/object/nido-quarantine`,
        {
          method: 'DELETE',
          headers: serviceHeaders,
          body: JSON.stringify({ prefixes: [authz.storage_path] }),
        },
      ); } catch { /* La copia en cuarentena queda pendiente de limpieza. */ }

      return json({
        id: documentId,
        status: 'approved',
        version: done?.version,
        detected_mime_type: validation.mime,
        published_path: publishedPath,
        idempotent: false,
      });
    } catch {
      return json({ error: 'request_failed' }, 400);
    }
  };
}
