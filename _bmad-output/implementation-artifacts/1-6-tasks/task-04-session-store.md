# Task 4 — Session store + validation preHandler

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#6, #11**.

**Goal:** In-memory session store (token → expiresAt). Expose a `preHandler` hook used by submit routes to enforce cookie presence + expiry + scenario-header overrides.

**Load skill:** `rules/hooks.md`, `rules/decorators.md`, `rules/error-handling.md`.

## Dependencies

- Task 1, 2, 3.

## Deliverables

### `test-infra/mock-evisitor/src/session.ts`

```typescript
export interface SessionStore {
  issue(token: string, ttlSeconds: number): void;
  validate(token: string | undefined): SessionState;
  clear(): void; // for tests
}

export type SessionState =
  | { kind: 'valid' }
  | { kind: 'missing' }
  | { kind: 'expired' };

export function createSessionStore(now: () => number = Date.now): SessionStore {
  const expiries = new Map<string, number>();
  return {
    issue(token, ttlSeconds) {
      expiries.set(token, now() + ttlSeconds * 1000);
    },
    validate(token) {
      if (!token) return { kind: 'missing' };
      const exp = expiries.get(token);
      if (exp === undefined) return { kind: 'missing' };
      if (exp <= now()) {
        expiries.delete(token);
        return { kind: 'expired' };
      }
      return { kind: 'valid' };
    },
    clear() {
      expiries.clear();
    },
  };
}
```

### `test-infra/mock-evisitor/src/session-hook.ts`

Exports a preHandler that encodes the scenario-header precedence from the story:

```typescript
import type { FastifyRequest, FastifyReply } from 'fastify';

const COOKIE = 'ASP.NET_SessionId';

export async function requireSession(request: FastifyRequest, reply: FastifyReply): Promise<void> {
  const app = request.server;
  const scenario = request.headers['x-mock-scenario'];
  const scenarios = Array.isArray(scenario)
    ? scenario
    : (scenario ?? '').split(',').map((s) => s.trim()).filter(Boolean);

  // 1. Unavailable outranks everything
  if (scenarios.includes('unavailable')) {
    return reply.code(503).type('application/json').send(app.fixtures.submitErrorUnavailable);
  }

  // 2. Forced expiry or missing/expired real cookie
  const cookieToken = request.cookies[COOKIE];
  const state = scenarios.includes('expire-session')
    ? ({ kind: 'expired' } as const)
    : app.sessionStore.validate(cookieToken);

  if (state.kind !== 'valid') {
    if (scenarios.includes('redirect-login')) {
      return reply
        .code(302)
        .header('Location', '/Login')
        .type('text/html; charset=utf-8')
        .send(app.fixtures.redirectLoginHtml);
    }
    return reply.code(401).type('application/json').send(app.fixtures.submitErrorSession);
  }
}
```

### Wire into `buildApp()`

```typescript
import { createSessionStore, type SessionStore } from './session.ts';

const sessionStore = createSessionStore();
app.decorate('sessionStore', sessionStore);

declare module 'fastify' {
  interface FastifyInstance { sessionStore: SessionStore }
}
```

## Guardrails

- ❌ Global `onRequest` that rejects everywhere — `/Login` and `/healthz` must NOT require a session. Apply `requireSession` only on submit routes (task 5).
- ❌ Wall-clock `new Date()` in tests — inject `now` in `createSessionStore` so expiry is deterministic.
- ❌ Leaking tokens in logs — the session cookie is small and fixed (`testsession123`) but don't log `request.headers.cookie` verbatim. Fastify's default serializer already redacts cookies; don't override it.

## Acceptance checks

- [ ] `yarn typecheck` green
- [ ] Login → subsequent request with the cookie works (submit routes task 5 will verify end-to-end)
- [ ] `SESSION_TTL_SECONDS=1` → login, wait 2s, submit → 401 with `submitErrorSession` body
- [ ] `X-Mock-Scenario: expire-session, redirect-login` → 302 with `Content-Type: text/html`

## Commit

`test-infra(mock-evisitor): session store + requireSession preHandler with scenario precedence`
