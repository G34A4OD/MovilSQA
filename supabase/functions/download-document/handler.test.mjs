import test from 'node:test';
import assert from 'node:assert/strict';
import { createDownloadDocumentHandler } from './handler.mjs';

const DOC = 'a1000000-0000-4000-8000-000000000001';
const PATH = 'b1000000-0000-4000-8000-000000000001';
const pdf = Uint8Array.from([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]);

const request = (authorization = 'Bearer user.jwt.token', payload = { document_id: DOC }) =>
  new Request('http://localhost/download-document', {
    method: 'POST',
    headers: { Authorization: authorization },
    body: JSON.stringify(payload),
  });

test('TC-DOC-04 HU-09: descarga Edge autorizada devuelve bytes sin URL firmada', async () => {
  let usedServiceOnAuthz = false;
  const handler = createDownloadDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    fetcher: async (url, options = {}) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_download')) {
        if ((options.headers?.Authorization || '').includes('service')) {
          usedServiceOnAuthz = true;
        }
        return Response.json({
          id: DOC,
          status: 'approved',
          published_path: PATH,
          detected_mime_type: 'application/pdf',
          size_bytes: pdf.length,
        });
      }
      if (url.includes('/storage/v1/object/nido-documents/')) {
        assert.match(options.headers.Authorization, /service/);
        return new Response(pdf, { status: 200 });
      }
      throw new Error(url);
    },
  });
  const result = await handler(request());
  assert.equal(result.status, 200);
  const body = await result.json();
  assert.equal(body.mime_type, 'application/pdf');
  assert.ok(body.content_base64);
  assert.equal(usedServiceOnAuthz, false);
  assert.equal('signed_url' in body, false);
});

test('TC-DOC-04 HU-09: forbidden no usa service_role en Storage', async () => {
  let storageCalls = 0;
  const handler = createDownloadDocumentHandler({
    url: 'http://local',
    key: 'anon',
    serviceKey: 'service',
    fetcher: async (url) => {
      if (url.endsWith('/auth/v1/user')) return Response.json({ id: 'actor' });
      if (url.includes('authorize_document_download')) {
        return Response.json({ message: 'forbidden' }, { status: 403 });
      }
      storageCalls += 1;
      throw new Error(url);
    },
  });
  assert.equal((await handler(request())).status, 403);
  assert.equal(storageCalls, 0);
});

test('TC-DOC-04 HU-09: sin JWT no descarga', async () => {
  const handler = createDownloadDocumentHandler({
    serviceKey: 'service',
    fetcher: () => {
      throw new Error('must not fetch');
    },
  });
  assert.equal((await handler(request(''))).status, 401);
});
