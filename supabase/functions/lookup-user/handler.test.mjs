import test from 'node:test';
import assert from 'node:assert/strict';
import { createLookupHandler } from './handler.mjs';

const body = { family_id: '30000000-0000-0000-0000-000000000001', public_id: 'a'.repeat(32) };
const request = (authorization = 'Bearer ficticio', payload = body) => new Request('http://localhost/lookup-user', { method: 'POST', headers: { Authorization: authorization }, body: JSON.stringify(payload) });
test('TC-FAM-02 HU-04: sin JWT o ID exacto no consulta datos', async () => {
  const handler = createLookupHandler({ fetcher: () => { throw new Error('must not fetch'); } });
  assert.equal((await handler(request(''))).status, 401);
  assert.equal((await handler(request('Bearer ficticio', { ...body, public_id: 'parcial' }))).status, 400);
});
test('TC-SEC-01 HU-04: comprueba Auth y limita respuesta a nombre/ID público', async () => {
  const calls = [];
  const handler = createLookupHandler({ url: 'https://ficticio.supabase.co', key: 'sb_publishable_ficticio', fetcher: async (url, options) => {
    calls.push([url, options]);
    return Response.json(calls.length === 1 ? { id: 'actor-ficticio' } : { public_id: body.public_id, full_name: 'Persona ficticia', identity_card: 'NO_DEBE_SALIR' });
  } });
  const result = await handler(request());
  assert.deepEqual(await result.json(), { public_id: body.public_id, full_name: 'Persona ficticia' });
  assert.equal(calls.length, 2);
  assert.equal(calls[1][1].headers.Authorization, 'Bearer ficticio');
});
test('TC-SEC-02/03 HU-04: Auth inválido, permisos y rate limit no exponen respuesta interna', async () => {
  const invalid = createLookupHandler({ fetcher: async () => Response.json({}, { status: 401 }) });
  assert.equal((await invalid(request())).status, 401);
  for (const [message, expected] of [['rate_limited',429],['forbidden',403]]) {
    let count=0;
    const handler=createLookupHandler({fetcher:async()=>++count===1?Response.json({id:'actor'}):Response.json({message,details:'sensible'},{status:400})});
    const result=await handler(request());assert.equal(result.status,expected);assert.equal((await result.text()).includes('sensible'),false);
  }
});
