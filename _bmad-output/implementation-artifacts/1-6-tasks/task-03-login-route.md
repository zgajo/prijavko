# Task 3 — `/Login` route + cookie issuance

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#2, #3**.

**Goal:** Implement `POST /Login`. Success sets `ASP.NET_SessionId` cookie with configurable Max-Age; failure returns 401.

**Load skill:** `rules/routes.md`, `rules/plugins.md`, `rules/schemas.md`.

## Dependencies

- Task 1 (scaffold), task 2 (fixtures) must be merged.

## Deliverables

### `test-infra/mock-evisitor/src/config.ts`

```typescript
export interface ServerConfig {
  port: number;
  sessionTtlSeconds: number;
}

export function loadConfig(): ServerConfig {
  const ttl = Number(process.env.SESSION_TTL_SECONDS ?? '300');
  if (!Number.isFinite(ttl) || ttl < 1) {
    throw new Error(`[config] SESSION_TTL_SECONDS must be >= 1, got ${process.env.SESSION_TTL_SECONDS}`);
  }
  const port = Number(process.env.PORT ?? '8080');
  if (!Number.isFinite(port) || port < 1 || port > 65535) {
    throw new Error(`[config] PORT invalid: ${process.env.PORT}`);
  }
  return { port, sessionTtlSeconds: ttl };
}
```

### `test-infra/mock-evisitor/src/routes/login.ts`

```typescript
import type { FastifyPluginAsync } from 'fastify';

const SESSION_COOKIE_NAME = 'ASP.NET_SessionId' as const;

interface LoginBody {
  username?: string;
  password?: string;
}

const loginRoutes: FastifyPluginAsync = async (app) => {
  const { loginCredentials } = app.fixtures;
  const ttl = app.config.sessionTtlSeconds;

  app.post<{ Body: LoginBody }>('/Login', async (request, reply) => {
    const { username, password } = request.body ?? {};
    if (username !== loginCredentials.username || password !== loginCredentials.password) {
      return reply.code(401).send();
    }

    app.sessionStore.issue(loginCredentials.sessionToken, ttl);

    return reply
      .setCookie(SESSION_COOKIE_NAME, loginCredentials.sessionToken, {
        httpOnly: true,
        path: '/',
        maxAge: ttl,
      })
      .code(200)
      .send({ status: 'ok' });
  });
};

export default loginRoutes;
```

### Wire into `buildApp()`

```typescript
import { loadConfig, type ServerConfig } from './config.ts';
import loginRoutes from './routes/login.ts';

// Inside buildApp()
const config = loadConfig();
app.decorate('config', config);
// (sessionStore decorator added in task 4; login route consumes it — this task
//  lands together with task 4 if you want a clean compile, OR stub sessionStore
//  here and flesh out in task 4.)
await app.register(loginRoutes);

declare module 'fastify' {
  interface FastifyInstance { config: ServerConfig }
}
```

> **Sequencing note:** Task 3 and Task 4 are tightly coupled (login needs `sessionStore`). Two valid orders: (a) land both in one commit with task 3 driving, or (b) stub `sessionStore.issue()` as a no-op in task 3 and wire the real store in task 4. Prefer **(a)** — smaller seam, easier review.

## Guardrails (do not violate)

- ❌ Cookie name `ASP.NET_SessionID` / `asp.net_sessionid` / `AspNetSessionId` — must be exactly `ASP.NET_SessionId` (real eVisitor is case-sensitive; PersistCookieJar in Flutter will miss otherwise).
- ❌ Sending a response body on 401 — AC #3 says "no `Set-Cookie`" and expects bare 401. (Body is fine but not required; keep minimal.)
- ❌ `reply.send()` followed by another `reply.*` call — Fastify will warn about double-send. Always `return reply...`.

## Acceptance checks

- [ ] `yarn typecheck` green
- [ ] `curl -i -X POST http://localhost:8080/Login -d 'username=testuser&password=testpass' -H 'Content-Type: application/x-www-form-urlencoded'` → `200 OK` with header `Set-Cookie: ASP.NET_SessionId=testsession123; Max-Age=300; Path=/; HttpOnly`
- [ ] Same with wrong password → `401 Unauthorized`, **no** `Set-Cookie` header
- [ ] `SESSION_TTL_SECONDS=60 yarn dev` → cookie Max-Age is 60

## Commit

`test-infra(mock-evisitor): POST /Login with ASP.NET_SessionId cookie`
