# Task 6 — `/healthz` endpoint

Part of [Story 1.6](../1-6-mock-evisitor-server.md). Covers AC **#8**.

**Goal:** Dependency-free health probe consumed by Story 2.1's Docker Compose healthcheck.

**Load skill:** `rules/routes.md`, `rules/deployment.md`.

## Dependencies

- Task 1 (scaffold).

## Deliverables

### `test-infra/mock-evisitor/src/routes/health.ts`

```typescript
import type { FastifyPluginAsync } from 'fastify';

const healthRoutes: FastifyPluginAsync = async (app) => {
  app.get('/healthz', {
    logLevel: 'warn', // healthchecks fire every few seconds — quiet them
  }, async () => ({ status: 'ok' }));
};

export default healthRoutes;
```

### Wire into `buildApp()` — register BEFORE other routes

```typescript
import healthRoutes from './routes/health.ts';
await app.register(healthRoutes); // no session, no fixtures required
```

## Guardrails

- ❌ Importing `session.ts` or `fixtures.ts` into `health.ts` — health must remain standalone so a broken fixture file doesn't make the container "unhealthy" before you can see the boot error.
- ❌ Returning 204 or a string — compose `wget --spider` probes may pass, but AC #8 mandates `{"status":"ok"}` JSON body.
- ❌ Adding auth or rate limiting — docker healthchecks don't carry cookies.

## Acceptance checks

- [ ] `curl -i http://localhost:8080/healthz` → `200` + `application/json` + `{"status":"ok"}`
- [ ] Response latency <50ms cold (check `X-Response-Time` if enabled or `curl -w "%{time_total}\n"`)
- [ ] Works before `/Login` is ever called (no session required)

## Commit

`test-infra(mock-evisitor): /healthz endpoint`
