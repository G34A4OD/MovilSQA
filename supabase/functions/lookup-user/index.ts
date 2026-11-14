import { createLookupHandler } from './handler.mjs';

const keys = JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') ?? '{}');
const key = Object.values(keys).find((value) => typeof value === 'string') ?? Deno.env.get('SUPABASE_ANON_KEY');
if (!key) throw new Error('Missing client API key configuration');
Deno.serve(createLookupHandler({ url: Deno.env.get('SUPABASE_URL'), key }));
