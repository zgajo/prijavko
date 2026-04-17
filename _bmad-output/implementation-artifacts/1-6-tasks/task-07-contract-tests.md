# Task 7 — Contract tests (`node:test` + `app.inject()`)

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#12**.

**Goal:** Every AC 2–9 branch has at least one test asserting status, content-type, cookie/body shape. Tests exercise `app.inject()` — no network bind, no external HTTP.

**Load skill:** `rules/testing.md` (skill picks `node:test` + `inject()` — we follow it).

## Dependencies

- Tasks 1–6 merged.

## Test files (all under `test-infra/mock-evisitor/test/`)

### `login.test.ts`

Covers AC #2, #3.

```typescript
import { describe, it, before, after } from 'node:test';
import type { FastifyInstance } from 'fastify';
import { buildApp } from '../src/server.ts';

describe('POST /Login', () => {
  let app: FastifyInstance;
  before(async () => { app = await buildApp({ logger: false }); await app.ready(); });
  after(async () => { await app.close(); });

  it('200 + sets ASP.NET_SessionId cookie with Max-Age on valid creds', async (t) => {
    const res = await app.inject({
      method: 'POST',
      url: '/Login',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      payload: 'username=testuser&password=testpass',
    });
    t.assert.equal(res.statusCode, 200);
    const setCookie = res.headers['set-cookie'];
    t.assert.ok(setCookie, 'set-cookie header present');
    const cookieStr = Array.isArray(setCookie) ? setCookie.join(';') : String(setCookie);
    t.assert.match(cookieStr, /ASP\.NET_SessionId=testsession123/);
    t.assert.match(cookieStr, /Max-Age=\d+/);
    t.assert.match(cookieStr, /HttpOnly/);
  });

  it('401 on wrong password — no set-cookie', async (t) => {
    const res = await app.inject({
      method: 'POST', url: '/Login',
      headers: { 'content-type': 'application/x-www-form-urlencoded' },
      payload: 'username=testuser&password=WRONG',
    });
    t.assert.equal(res.statusCode, 401);
    t.assert.equal(res.headers['set-cookie'], undefined);
  });
});
```

### `session.test.ts`

Covers AC #6, #11.

Include a test that uses `SESSION_TTL_SECONDS=1` + a small `setTimeout` OR a test that builds the app with a fake-time session store (preferred — pass `createSessionStore(() => mockNow)` via a small `buildApp({ sessionStore })` override).

Cases to cover:
- No cookie → 401 + `SystemMessage: "Session expired"`
- `X-Mock-Scenario: expire-session` → 401
- `X-Mock-Scenario: expire-session, redirect-login` → 302 + `Location: /Login` + `Content-Type: text/html; charset=utf-8`
- Real cookie but past TTL → 401

### `submit.test.ts`

Covers AC #4, #5, #7, #9.

Use a helper that logs in once and reuses the cookie:

```typescript
async function login(app: FastifyInstance): Promise<string> {
  const res = await app.inject({
    method: 'POST', url: '/Login',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    payload: 'username=testuser&password=testpass',
  });
  const c = String(res.headers['set-cookie']);
  const match = c.match(/ASP\.NET_SessionId=([^;]+)/);
  if (!match) throw new Error('no cookie');
  return `ASP.NET_SessionId=${match[1]}`;
}
```

Cases:
- `/CheckInTourist` happy → 200 + `{SystemMessage:"",UserMessage:""}`
- `/CheckInTourist` with `ERR_VALIDATION_X` → 400 + `UserMessage: "Putovnica nije važeća."`
- `/CheckInTourist` with `ERR_DUPLICATE_X` → 409 + `UserMessage: "Gost je već prijavljen."`
- `/ImportTourists` with mixed batch (3 guests) → 200 + array length 3, `ID`s preserved, first entry clean / second validation / third duplicate
- Any submit with `X-Mock-Scenario: unavailable` → 503 + unavailable envelope

### `health.test.ts`

Covers AC #8.

- `GET /healthz` → 200, `application/json`, body `{status:"ok"}`
- Works without any prior login

## Running

```
yarn test
```

Should print all tests passing, zero output to stderr (logger is off in tests).

## Coverage (optional but recommended)

Use Node 22's built-in coverage:

```
node --experimental-strip-types --test --experimental-test-coverage test/**/*.test.ts
```

Target ≥85% on this package (small code surface; exclude fixtures JSON and `server.ts main()` entrypoint).

## Guardrails

- ❌ Starting the real HTTP server in tests (`app.listen`) — use `app.inject()` only.
- ❌ Sharing state between test files — each file creates a fresh `buildApp()` and closes it.
- ❌ `await app.close()` missing in `after` — leaks timer handles, CI hangs.
- ❌ Using `assert` from `node:assert` without `t.assert` — `t.assert` gives better diff output in `node:test`.

## Acceptance checks

- [ ] `yarn test` green
- [ ] Every AC branch from 2–9 has at least one test (traceability check)
- [ ] Tests complete in <5s locally

## Commit

`test-infra(mock-evisitor): contract tests (node:test + inject)`
