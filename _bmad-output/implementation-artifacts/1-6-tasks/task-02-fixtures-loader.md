# Task 2 — Fixtures loader + types

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#10**.

**Goal:** All scripted responses live in JSON files; loader validates them at boot and crashes fast on malformed data. Adding a new error case = adding JSON, not editing code.

## Scope

- **In:** `fixtures/*.json`, `src/fixtures.ts` loader with runtime validation, typed exports consumed by later tasks.
- **Out:** Routes that consume fixtures (tasks 3, 5).

## Deliverables

### Fixture files under `test-infra/mock-evisitor/fixtures/`

**`login_success.json`** — metadata only (valid creds), used by login route
```json
{
  "username": "testuser",
  "password": "testpass",
  "sessionToken": "testsession123"
}
```

**`submit_success.json`**
```json
{ "SystemMessage": "", "UserMessage": "" }
```

**`submit_error_validation.json`**
```json
{ "SystemMessage": "Validation error: invalid document", "UserMessage": "Putovnica nije važeća." }
```

**`submit_error_duplicate.json`**
```json
{ "SystemMessage": "Duplicate guest", "UserMessage": "Gost je već prijavljen." }
```

**`submit_error_session.json`**
```json
{ "SystemMessage": "Session expired", "UserMessage": "" }
```

**`submit_error_unavailable.json`**
```json
{ "SystemMessage": "Service unavailable", "UserMessage": "" }
```

**`submit_redirect_login.html`** (HTML body for the 302 re-auth scenario — AC #6)
```html
<!doctype html><html><body><form action="/Login" method="post"><input name="username"><input name="password" type="password"><button>Login</button></form></body></html>
```

### `test-infra/mock-evisitor/src/fixtures.ts`

```typescript
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

export interface EvisitorEnvelope {
  SystemMessage: string;
  UserMessage: string;
}

export interface LoginCredentialsFixture {
  username: string;
  password: string;
  sessionToken: string;
}

export interface Fixtures {
  loginCredentials: LoginCredentialsFixture;
  submitSuccess: EvisitorEnvelope;
  submitErrorValidation: EvisitorEnvelope;
  submitErrorDuplicate: EvisitorEnvelope;
  submitErrorSession: EvisitorEnvelope;
  submitErrorUnavailable: EvisitorEnvelope;
  redirectLoginHtml: string;
}

const FIXTURE_DIR = resolve(dirname(fileURLToPath(import.meta.url)), '../fixtures');

function readJson<T>(relativePath: string, validator: (v: unknown) => v is T): T {
  const raw = readFileSync(resolve(FIXTURE_DIR, relativePath), 'utf8');
  const parsed: unknown = JSON.parse(raw);
  if (!validator(parsed)) {
    throw new Error(`[fixtures] Invalid shape in ${relativePath}`);
  }
  return parsed;
}

function isEnvelope(v: unknown): v is EvisitorEnvelope {
  return (
    typeof v === 'object' && v !== null &&
    typeof (v as { SystemMessage?: unknown }).SystemMessage === 'string' &&
    typeof (v as { UserMessage?: unknown }).UserMessage === 'string'
  );
}

function isLoginFixture(v: unknown): v is LoginCredentialsFixture {
  return (
    typeof v === 'object' && v !== null &&
    typeof (v as { username?: unknown }).username === 'string' &&
    typeof (v as { password?: unknown }).password === 'string' &&
    typeof (v as { sessionToken?: unknown }).sessionToken === 'string'
  );
}

export function loadFixtures(): Fixtures {
  return {
    loginCredentials: readJson('login_success.json', isLoginFixture),
    submitSuccess: readJson('submit_success.json', isEnvelope),
    submitErrorValidation: readJson('submit_error_validation.json', isEnvelope),
    submitErrorDuplicate: readJson('submit_error_duplicate.json', isEnvelope),
    submitErrorSession: readJson('submit_error_session.json', isEnvelope),
    submitErrorUnavailable: readJson('submit_error_unavailable.json', isEnvelope),
    redirectLoginHtml: readFileSync(resolve(FIXTURE_DIR, 'submit_redirect_login.html'), 'utf8'),
  };
}
```

### Wire into `buildApp()`

Add to `src/server.ts` after plugin registration:

```typescript
import { loadFixtures, type Fixtures } from './fixtures.ts';

// Inside buildApp() — fail-fast at boot if fixtures malformed
const fixtures = loadFixtures();
app.decorate('fixtures', fixtures);

// Augment types
declare module 'fastify' {
  interface FastifyInstance { fixtures: Fixtures }
}
```

(`decorate` is covered by `fastify` skill `rules/decorators.md`.)

## Acceptance checks

- [ ] `yarn typecheck` green
- [ ] `yarn dev` boots and logs normally; no fixture errors
- [ ] Mutate `submit_success.json` → `{ "Wrong": "shape" }` → `yarn dev` exits with `[fixtures] Invalid shape in submit_success.json` (revert after checking)
- [ ] `app.fixtures.submitSuccess` is visible in TS (no `any` cast needed in consumers)

## Commit

`test-infra(mock-evisitor): fixtures loader with runtime validation`
