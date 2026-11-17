import test from 'node:test';
import assert from 'node:assert/strict';
import {
  createProcessDocumentHandler,
  createScanner,
  detectMimeFromBytes,
  scanWithClamd,
  validateDocumentBytes,
} from './handler.mjs';

const DOC = 'a1000000-0000-4000-8000-000000000001';
const PATH = 'b1000000-0000-4000-8000-000000000001';
const pdf = Uint8Array.from([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]);
const htmlAsPdf = Uint8Array.from([0x3c, 0x68, 0x74, 0x6d, 0x6c, 0x3e]);

const request = (authorization = 'Bearer user.jwt.token', payload = { document_id: DOC }) =>
  new Request('http://localhost/process-document', {
    method: 'POST',
    headers: { Authorization: authorization },
    body: JSON.stringify(payload),
  });

/** Conexión clamd inyectable: evidencia de escaneo real (no simulate). */
function mockClamdConnect(reply) {
  return async () => ({
    write: async (buf) => buf.length,
    read: async (buf) => {
      const encoded = new TextEncoder().encode(reply);
      buf.set(encoded.subarray(0, Math.min(buf.length, encoded.length)));
      return encoded.length;
    },
    close() {},
  });
}

function quarantineAuthz(size = pdf.length) {
  return {
    id: DOC,
    status: 'quarantine',
    storage_path: PATH,
    declared_mime_type: 'application/pdf',
    size_bytes: size,
    version: 1,
    process_attempts: 0,
  };
}

test('TC-DOC-02 HU-09: detecta firma PDF/JPG/PNG y rechaza HTML', () => {
  assert.equal(detectMimeFromBytes(pdf), 'application/pdf');
  assert.equal(
    detectMimeFromBytes(Uint8Array.from([0xff, 0xd8, 0xff, 0xe0])),
    'image/jpeg',
  );
  assert.equal(
    detectMimeFromBytes(Uint8Array.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])),
    'image/png',
  );
  assert.equal(detectMimeFromBytes(htmlAsPdf), null);
  assert.equal(validateDocumentBytes(htmlAsPdf, 'application/pdf', htmlAsPdf.length).error, 'signature_invalid');
  assert.equal(validateDocumentBytes(pdf, 'image/png', pdf.length).error, 'mime_mismatch');
  assert.equal(validateDocumentBytes(pdf, 'application/pdf', 999).error, 'size_mismatch');
  assert.equal(validateDocumentBytes(pdf, 'application/pdf', pdf.length).ok, true);
});

test('TC-DOC-02 HU-09: sin JWT o document_id inválido no procesa', async () => {
  const handler = createProcessDocumentHandler({
    serviceKey: 'service',
    fetcher: () => {
      throw new Error('must not fetch');
    },
  });
  assert.equal((await handler(request(''))).status, 401);
  assert.equal(
    (await handler(request('Bearer user.jwt.token', { document_id: 'no-uuid' }))).status,
    400,
  );
});

test('TC-DOC-02 HU-09: bytes inválidos marcan rejected antes de consultar escáner', async () => {
  let completeBody;
  let scannerCalled = false;
  const handler = createProcessDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    scanner: async () => {
      scannerCalled = true;
      return { status: 'clean', evidence: 'clamav' };
    },
    fetcher: async (url, options = {}) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_process')) {
        return Response.json(quarantineAuthz(htmlAsPdf.length));
      }
      if (url.includes('/storage/v1/object/nido-quarantine/')) {
        return new Response(htmlAsPdf, { status: 200 });
      }
      if (url.includes('complete_document_process')) {
        completeBody = JSON.parse(options.body);
        return Response.json({
          id: DOC,
          status: 'rejected',
          version: 2,
          process_attempts: 1,
        });
      }
      throw new Error(url);
    },
  });
  const result = await handler(request());
  assert.equal(result.status, 422);
  assert.equal((await result.json()).status, 'rejected');
  assert.equal(completeBody.p_outcome, 'rejected');
  assert.equal(completeBody.p_error, 'signature_invalid');
  assert.equal(scannerCalled, false);
});

test('TC-DOC-02 HU-09: escáner no disponible conserva cuarentena e incrementa intentos', async () => {
  const completes = [];
  const handler = createProcessDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    scanner: createScanner({ mode: 'off' }),
    fetcher: async (url, options = {}) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_process')) {
        return Response.json(quarantineAuthz());
      }
      if (url.includes('/storage/v1/object/nido-quarantine/')) {
        return new Response(pdf, { status: 200 });
      }
      if (url.includes('complete_document_process')) {
        completes.push(JSON.parse(options.body));
        return Response.json({
          id: DOC,
          status: 'quarantine',
          version: 2,
          process_attempts: 1,
          last_process_error: 'scanner_unavailable',
        });
      }
      throw new Error(url);
    },
  });
  const first = await handler(request());
  assert.equal(first.status, 503);
  const body = await first.json();
  assert.equal(body.status, 'quarantine');
  assert.equal(body.error, 'scanner_unavailable');
  assert.equal(completes[0].p_outcome, 'quarantine');

  const second = await handler(request());
  assert.equal(second.status, 503);
  assert.equal(completes.length, 2);
});

test('TC-DOC-02 HU-09: simulate infectado rechaza (evidencia de prueba, no publica)', async () => {
  const infected = Uint8Array.from([...pdf, ...new TextEncoder().encode('NIDO-SIMULATED-MALWARE')]);
  const handler = createProcessDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    scanner: createScanner({ mode: 'simulate', allowSimulate: true }),
    fetcher: async (url, options = {}) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_process')) {
        return Response.json(quarantineAuthz(infected.length));
      }
      if (url.includes('/storage/v1/object/nido-quarantine/')) {
        return new Response(infected, { status: 200 });
      }
      if (url.includes('complete_document_process')) {
        assert.equal(JSON.parse(options.body).p_outcome, 'rejected');
        return Response.json({ id: DOC, status: 'rejected', version: 2 });
      }
      throw new Error(url);
    },
  });
  const result = await handler(request());
  assert.equal(result.status, 422);
  assert.equal((await result.json()).scan_evidence, 'simulate');
});

test('TC-DOC-02 HU-09: simulate limpio no publica (evidencia simulada ≠ escaneo real)', async () => {
  const completes = [];
  const handler = createProcessDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    scanner: createScanner({ mode: 'simulate', allowSimulate: true }),
    fetcher: async (url, options = {}) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_process')) {
        return Response.json(quarantineAuthz());
      }
      if (url.includes('/storage/v1/object/nido-quarantine/')) {
        return new Response(pdf, { status: 200 });
      }
      if (url.includes('complete_document_process')) {
        completes.push(JSON.parse(options.body));
        return Response.json({
          id: DOC,
          status: 'quarantine',
          version: 2,
          process_attempts: 1,
        });
      }
      if (url.includes('/storage/v1/object/nido-documents/')) {
        throw new Error('no debe publicar con evidencia simulate');
      }
      throw new Error(url);
    },
  });
  const result = await handler(request());
  assert.equal(result.status, 503);
  assert.equal((await result.json()).scan_evidence, 'simulate');
  assert.equal(completes[0].p_outcome, 'quarantine');
});

test('TC-DOC-02 HU-09: simulate bloqueado sin allowSimulate conserva cuarentena', async () => {
  const scan = await createScanner({ mode: 'simulate' })(pdf);
  assert.equal(scan.status, 'unavailable');
  assert.equal(scan.evidence, 'simulate_blocked');
});

test('TC-DOC-02 HU-09: ClamAV limpio publica y marca approved (evidencia real)', async () => {
  const completes = [];
  let published = false;
  const handler = createProcessDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    scanner: createScanner({
      mode: 'clamav',
      connect: mockClamdConnect('stream: OK\0'),
    }),
    fetcher: async (url, options = {}) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_process')) {
        return Response.json(quarantineAuthz());
      }
      if (url.includes('/storage/v1/object/nido-quarantine/') && (options.method ?? 'GET') === 'GET') {
        return new Response(pdf, { status: 200 });
      }
      if (url.includes('/storage/v1/object/nido-documents/')) {
        published = true;
        return new Response(null, { status: 200 });
      }
      if (url.includes('/storage/v1/object/nido-quarantine/') && options.method === 'DELETE') {
        return new Response(null, { status: 200 });
      }
      if (url.includes('complete_document_process')) {
        completes.push(JSON.parse(options.body));
        return Response.json({ id: DOC, status: 'approved', version: 2 });
      }
      throw new Error(url);
    },
  });
  const result = await handler(request());
  assert.equal(result.status, 200);
  const body = await result.json();
  assert.equal(body.status, 'approved');
  assert.equal(published, true);
  assert.equal(completes[0].p_outcome, 'approved');
});

test('TC-DOC-02 HU-09: ClamAV FOUND rechaza (evidencia real)', async () => {
  const handler = createProcessDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    scanner: createScanner({
      mode: 'clamav',
      connect: mockClamdConnect('stream: Eicar-Test-Signature FOUND\0'),
    }),
    fetcher: async (url, options = {}) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_process')) {
        return Response.json(quarantineAuthz());
      }
      if (url.includes('/storage/v1/object/nido-quarantine/')) {
        return new Response(pdf, { status: 200 });
      }
      if (url.includes('complete_document_process')) {
        assert.equal(JSON.parse(options.body).p_outcome, 'rejected');
        return Response.json({ id: DOC, status: 'rejected', version: 2 });
      }
      throw new Error(url);
    },
  });
  const result = await handler(request());
  assert.equal(result.status, 422);
  assert.equal((await result.json()).scan_evidence, 'clamav');
});

test('TC-DOC-02 HU-09: ClamAV sin daemon o error de red conserva cuarentena', async () => {
  const scan = await scanWithClamd(pdf, {
    connect: async () => {
      throw new Error('ECONNREFUSED');
    },
  });
  assert.equal(scan.status, 'unavailable');
  assert.equal(scan.evidence, 'clamav');

  const noConnect = await scanWithClamd(pdf, { connect: null });
  assert.equal(noConnect.status, 'unavailable');
});

test('TC-DOC-02 HU-09: reintento sobre approved es idempotente', async () => {
  let storageCalls = 0;
  const handler = createProcessDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    scanner: createScanner({ mode: 'off' }),
    fetcher: async (url) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_process')) {
        return Response.json({
          id: DOC,
          status: 'approved',
          storage_path: PATH,
          published_path: PATH,
          detected_mime_type: 'application/pdf',
          version: 3,
        });
      }
      storageCalls += 1;
      throw new Error('storage must not run on idempotent retry');
    },
  });
  const result = await handler(request());
  assert.equal(result.status, 200);
  assert.deepEqual(await result.json(), {
    id: DOC,
    status: 'approved',
    version: 3,
    detected_mime_type: 'application/pdf',
    published_path: PATH,
    idempotent: true,
  });
  assert.equal(storageCalls, 0);
});

test('TC-DOC-03 HU-09: autorización denegada no usa service_role', async () => {
  let usedService = false;
  const handler = createProcessDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    fetcher: async (url, options = {}) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_process')) {
        return Response.json({ message: 'forbidden' }, { status: 403 });
      }
      if ((options.headers?.Authorization || '').includes('service')) {
        usedService = true;
      }
      throw new Error(url);
    },
  });
  assert.equal((await handler(request())).status, 403);
  assert.equal(usedService, false);
});
