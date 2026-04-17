# Task 5 — `/CheckInTourist` + `/ImportTourists` routes

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#4, #5, #6, #7, #9**.

**Goal:** XML-body endpoints that return per-guest `{SystemMessage, UserMessage}` envelopes based on `DocumentNumber` pattern matching.

**Load skill:** `rules/routes.md`, `rules/content-type.md`, `rules/error-handling.md`, `rules/schemas.md`.

## Dependencies

- Tasks 1, 2, 3, 4.

## Deliverables

### `test-infra/mock-evisitor/src/xml.ts`

```typescript
import { XMLParser } from 'fast-xml-parser';

export interface ParsedGuest {
  id: string;
  documentNumber: string;
}

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '',
  isArray: (name) => name === 'Tourist' || name === 'Guest',
});

export function parseGuestsXml(raw: string): ParsedGuest[] {
  const parsed = parser.parse(raw) as Record<string, unknown>;
  // Accept either <Root><Tourist .../></Root> or <Root><Guest .../></Root> — real
  // eVisitor uses <Tourist>. Tolerate both for robustness against schema drift.
  const root = (parsed.ImportTourists ?? parsed.CheckInTourist ?? parsed.Root ?? parsed) as Record<string, unknown>;
  const list = (root.Tourist ?? root.Guest ?? []) as Array<Record<string, unknown>>;
  const normalized = Array.isArray(list) ? list : [list];
  return normalized.map((item) => ({
    id: String(item.ID ?? ''),
    documentNumber: String(item.DocumentNumber ?? ''),
  }));
}
```

### `test-infra/mock-evisitor/src/routes/submit.ts`

```typescript
import type { FastifyPluginAsync } from 'fastify';
import { requireSession } from '../session-hook.ts';
import { parseGuestsXml, type ParsedGuest } from '../xml.ts';
import type { EvisitorEnvelope } from '../fixtures.ts';

const VALIDATION_RE = /^ERR_VALIDATION_/;
const DUPLICATE_RE = /^ERR_DUPLICATE_/;

function envelopeForGuest(guest: ParsedGuest, app: import('fastify').FastifyInstance): EvisitorEnvelope & { ID?: string } {
  if (VALIDATION_RE.test(guest.documentNumber)) {
    return { ID: guest.id, ...app.fixtures.submitErrorValidation };
  }
  if (DUPLICATE_RE.test(guest.documentNumber)) {
    return { ID: guest.id, ...app.fixtures.submitErrorDuplicate };
  }
  return { ID: guest.id, ...app.fixtures.submitSuccess };
}

const submitRoutes: FastifyPluginAsync = async (app) => {
  // Raw-body parser for XML — Fastify doesn't ship one.
  app.addContentTypeParser(
    ['application/xml', 'text/xml'],
    { parseAs: 'string' },
    (_req, body, done) => done(null, body),
  );

  const xmlOpts = {
    preHandler: requireSession,
    config: { rawBody: true },
  };

  app.post<{ Body: string }>('/CheckInTourist', xmlOpts, async (request, reply) => {
    const guests = parseGuestsXml(request.body);
    if (guests.length === 0) {
      return reply.code(400).send({ SystemMessage: 'Empty body', UserMessage: '' });
    }
    const result = envelopeForGuest(guests[0]!, app);
    const hasError = result.SystemMessage !== '';
    const status = VALIDATION_RE.test(guests[0]!.documentNumber)
      ? 400
      : DUPLICATE_RE.test(guests[0]!.documentNumber)
        ? 409
        : 200;
    return reply.code(status).send(hasError ? result : app.fixtures.submitSuccess);
  });

  app.post<{ Body: string }>('/ImportTourists', xmlOpts, async (request, reply) => {
    const guests = parseGuestsXml(request.body);
    if (guests.length === 0) {
      return reply.code(400).send([]);
    }
    const results = guests.map((g) => envelopeForGuest(g, app));
    // Per AC #9: partial success batches keep status 200 — per-guest errors
    // live in the array entries. Matches real eVisitor.
    return reply.code(200).send(results);
  });
};

export default submitRoutes;
```

### Wire into `buildApp()`

```typescript
import submitRoutes from './routes/submit.ts';
await app.register(submitRoutes);
```

## Scenario precedence (do NOT reorder — AC #6, #7)

The `requireSession` preHandler (task 4) handles #1 and #2 below; the route body handles #3 and #4:

1. `X-Mock-Scenario: unavailable` → 503 (handled in preHandler)
2. Session missing/expired OR `X-Mock-Scenario: expire-session` → 401 or 302+HTML (handled in preHandler)
3. Per-guest `ERR_VALIDATION_*` → 400 (CheckIn) or per-guest error in array (Import, status still 200)
4. Per-guest `ERR_DUPLICATE_*` → 409 (CheckIn) or per-guest error in array (Import, status still 200)
5. Default → success

**Document this order as a code comment at top of `submit.ts`.**

## Guardrails

- ❌ Rejecting the entire `/ImportTourists` batch on the first bad guest — must be per-guest partial success, batch returns 200 (AC #9).
- ❌ Returning `{errors: [...]}` or `{results: [...]}` wrapper — `/ImportTourists` body is a bare array.
- ❌ Trusting parsed XML without string coercion — `fast-xml-parser` sometimes infers numbers for `<ID>1234</ID>`; always `String(...)`.
- ❌ Using JSON.parse on the body — content-type parser returns a raw string that `parseGuestsXml` handles.

## Acceptance checks

- [ ] After login, `POST /CheckInTourist` with XML `<Root><Tourist><ID>a</ID><DocumentNumber>P123</DocumentNumber></Tourist></Root>` → 200 + `{SystemMessage:"",UserMessage:""}`
- [ ] Same with `DocumentNumber>ERR_VALIDATION_FOO<` → 400 + Croatian `UserMessage: "Putovnica nije važeća."`
- [ ] `ERR_DUPLICATE_FOO` → 409 + Croatian `UserMessage: "Gost je već prijavljen."`
- [ ] `POST /ImportTourists` with 3 guests (one `ERR_VALIDATION_*`, one `ERR_DUPLICATE_*`, one clean) → 200 + array of 3 entries with matching `ID`s
- [ ] Same submit without a session cookie → 401 + session error envelope
- [ ] `X-Mock-Scenario: unavailable` on any submit → 503 + unavailable envelope
- [ ] `X-Mock-Scenario: expire-session, redirect-login` → 302 + `text/html`

## Commit

`test-infra(mock-evisitor): CheckInTourist + ImportTourists with per-guest envelopes`
