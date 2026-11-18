import { createProcessDocumentHandler, createScanner } from './handler.mjs';

const keys = JSON.parse(Deno.env.get('SUPABASE_PUBLISHABLE_KEYS') ?? '{}');
const key =
  Object.values(keys).find((value) => typeof value === 'string') ??
  Deno.env.get('SUPABASE_ANON_KEY');
const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
if (!key) throw new Error('Missing client API key configuration');
if (!serviceKey) throw new Error('Missing service role configuration');

// Runtime: solo escáneres reales (clamav/http). simulate queda bloqueado aquí.
let scannerMode = Deno.env.get('NIDO_DOCUMENT_SCANNER') ?? 'off';
if (scannerMode === 'simulate') {
  scannerMode = 'off';
}
const scannerUrl = Deno.env.get('NIDO_DOCUMENT_SCANNER_URL') ?? undefined;
const scannerToken = Deno.env.get('NIDO_DOCUMENT_SCANNER_TOKEN') ?? undefined;
const clamHost = Deno.env.get('NIDO_CLAMD_HOST') ?? '127.0.0.1';
const clamPort = Deno.env.get('NIDO_CLAMD_PORT') ?? '3310';

const connect =
  scannerMode === 'clamav' && typeof Deno !== 'undefined' && Deno.connect
    ? (opts) => Deno.connect({ hostname: opts.hostname, port: Number(opts.port) })
    : null;

Deno.serve(
  createProcessDocumentHandler({
    url: Deno.env.get('SUPABASE_URL'),
    key,
    serviceKey,
    scanner: createScanner({
      mode: scannerMode,
      url: scannerUrl,
      token: scannerToken,
      host: clamHost,
      port: clamPort,
      connect,
      allowSimulate: false,
    }),
  }),
);
