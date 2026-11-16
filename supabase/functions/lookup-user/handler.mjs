// No service key and no third-party dependencies. SQL owns authorization/rate limits.
export function createLookupHandler({ url, key, fetcher = fetch }) {
  const reply = (body, status = 200) => Response.json(body, { status, headers: { 'Cache-Control': 'no-store' } });
  return async (request) => {
    if (request.method !== 'POST') return reply({ error: 'method_not_allowed' }, 405);
    const authorization = request.headers.get('Authorization') ?? '';
    if (!/^Bearer [\w.-]+$/i.test(authorization)) return reply({ error: 'unauthorized' }, 401);
    try {
      const raw = await request.text();
      if (raw.length > 2048) return reply({ error: 'validation_error' }, 400);
      const body = JSON.parse(raw);
      if (!/^[0-9a-f-]{36}$/i.test(body.family_id ?? '') || !/^[0-9a-f]{32}$/i.test(body.public_id ?? '')) {
        return reply({ error: 'validation_error' }, 400);
      }
      const headers = { apikey: key, Authorization: authorization, 'Content-Type': 'application/json' };
      const user = await fetcher(`${url}/auth/v1/user`, { headers });
      if (!user.ok) return reply({ error: 'unauthorized' }, 401);
      const verified = await user.json();
      if (!verified.id) return reply({ error: 'unauthorized' }, 401);
      const result = await fetcher(`${url}/rest/v1/rpc/lookup_family_user`, {
        method: 'POST', headers, body: JSON.stringify({ p_family_id: body.family_id, p_public_id: body.public_id }),
      });
      const value = await result.json();
      if (!result.ok) return reply({ error: value.message === 'rate_limited' ? 'rate_limited' : 'forbidden' }, value.message === 'rate_limited' ? 429 : 403);
      // Explicit allowlist: never return UUID/CI/address/health from an upstream change.
      return reply(value == null ? null : { public_id: value.public_id, full_name: value.full_name });
    } catch {
      return reply({ error: 'request_failed' }, 400);
    }
  };
}
