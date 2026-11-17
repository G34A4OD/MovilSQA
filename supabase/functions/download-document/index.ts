import { createDownloadDocumentHandler } from './handler.mjs';

const keys = JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') ?? '{}');
const key =
  Object.values(keys).find((value) => typeof value === 'string') ??
  Deno.env.get('SUPABASE_ANON_KEY');
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!key) throw new Error('Missing client API key configuration');
if (!serviceKey) throw new Error('Missing service role configuration');

Deno.serve(
  createDownloadDocumentHandler({
    url: Deno.env.get('SUPABASE_URL'),
    key,
    serviceKey,
  }),
);
